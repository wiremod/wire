WireToolSetup.setCategory("Chips, Gates", "Advanced")
WireToolSetup.open("fpga", "FPGA", "gmod_wire_fpga", nil, "FPGAs")

if CLIENT then
	language.Add("Tool.wire_fpga.name", "FPGA Tool (Wire)")
	language.Add("Tool.wire_fpga.desc", "Spawns a field programmable gate array for use with the wire system.")
	language.Add("ToolWirecpu_Model",  "Model:" )
	TOOL.Information = {
		{ name = "left", text = "Upload program to FPGA" },
		{ name = "right", text = "Open editor" },
		{ name = "reload", text = "Reset" }
	}

	WireToolSetup.setToolMenuIcon("icon16/application_view_icons.png")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(40)

TOOL.ClientConVar = {
	model             = "models/bull/gates/processor.mdl",
	filename          = "",
}

if CLIENT then
	------------------------------------------------------------------------------
	-- Make sure firing animation is displayed clientside
	------------------------------------------------------------------------------
	function TOOL:LeftClick()  return true end
	function TOOL:Reload()     return true end
	function TOOL:RightClick() return false end
end

if SERVER then
	util.AddNetworkString("FPGA_Upload")
	util.AddNetworkString("FPGA_Download")
	util.AddNetworkString("FPGA_OpenEditor")
	util.AddNetworkString("wire_fpga_editor_status")

	-- Reset
	function TOOL:Reload(trace)
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_fpga" then
			trace.Entity:Reset()
			return true
		else
			return false
		end
	end

	-- Spawn or upload
	function TOOL:CheckHitOwnClass(trace)
		return trace.Entity:IsValid() and (trace.Entity:GetClass() == "gmod_wire_fpga")
	end
	function TOOL:LeftClick_Update(trace)
		self:Upload(trace.Entity)
	end
	function TOOL:MakeEnt(ply, model, Ang, trace)
		local ent = WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model})
		return ent
	end
	function TOOL:PostMake(ent)
		self:Upload(ent)
	end

	-- Open editor
	function TOOL:RightClick(trace)
		if trace.Entity:IsPlayer() then return false end

		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_fpga" then
			self:Download(trace.Entity)
			return true
		end

		net.Start("FPGA_OpenEditor") net.Send(self:GetOwner())
		return false
	end



	------------------------------------------------------------------------------
	-- Uploading (Server -> Client -> Server)
	------------------------------------------------------------------------------
	-- Send request to client for FPGA data
	function TOOL:Upload(ent)
		net.Start("FPGA_Upload")
			net.WriteInt(ent:EntIndex(), 32)
		net.Send(self:GetOwner())
	end
	------------------------------------------------------------------------------
	-- Downloading (Server -> Client)
	------------------------------------------------------------------------------
	-- Send FPGA data to client
	function TOOL:Download(ent)
		local player = self:GetOwner()

		if not WireLib.CanTool(player, ent, "wire_fpga") then
			WireLib.AddNotify(player, "You're not allowed to download from this FPGA (ent index: " .. ent:EntIndex() .. ").", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		local data = util.Compress(ent:GetOriginal())

		net.Start("FPGA_Download")
			net.WriteUInt(#data, 16)
			net.WriteData(data, #data)
		net.Send(player)
	end
end
if CLIENT then
	--------------------------------------------------------------
	-- Clientside Send
	--------------------------------------------------------------
	function WireLib.FPGAUpload(targetEnt, data)
		if type(targetEnt) == "number" then targetEnt = Entity(targetEnt) end
		targetEnt = targetEnt or LocalPlayer():GetEyeTrace().Entity

		if (not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_fpga") then
			WireLib.AddNotify("FPGA: Invalid FPGA entity specified!", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		if not data and not FPGA_Editor then
			return
		end
		data = data or FPGA_Editor:GetData()

		local data = util.Compress(data)

		if #data > 65500 then
			WireLib.AddNotify("FPGA: Code too large (exceeds 64kB)!", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		net.Start("FPGA_Upload")
			net.WriteEntity(targetEnt)
			net.WriteUInt(#data, 16)
			net.WriteData(data, #data)
		net.SendToServer()
	end

	-- Received request to upload
	net.Receive("FPGA_Upload", function(len, ply)
		local entid = net.ReadInt(32)
		timer.Create("FPGA_Upload_Delay", 0.03, 30, function()
			if IsValid(Entity(entid)) then
				WireLib.FPGAUpload(entid)
				timer.Remove("FPGA_Upload_Delay")
				timer.Remove("FPGA_Upload_Delay_Error")
			end
		end)
		timer.Create("FPGA_Upload_Delay_Error", 0.03*31, 1, function() WireLib.AddNotify("FPGA: Invalid FPGA entity specified!", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1) end)
	end)

	--------------------------------------------------------------
	-- Clientside Receive
	--------------------------------------------------------------
	-- Received download data
	net.Receive("FPGA_Download", function(len, ply)
		if not FPGA_Editor then
			FPGA_Editor = vgui.Create("FPGAEditorFrame")
			FPGA_Editor:Setup("FPGA Editor", "fpgachip")
		end

		local dataLength = net.ReadUInt(16)
		local data = net.ReadData(dataLength)
		local ok, data = pcall(util.Decompress, data)

		if ok then
			FPGA_Editor:Open(nil, data, true)
		end
	end)
end

if SERVER then
	--------------------------------------------------------------
	-- Serverside Receive
	--------------------------------------------------------------
	-- Receive FPGA data from client
	net.Receive("FPGA_Upload",function(len, ply)
		local chip = net.ReadEntity()

		if not IsValid(chip) or chip:GetClass() ~= "gmod_wire_fpga" then
			WireLib.AddNotify(ply, "FPGA: Invalid FPGA chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		if not WireLib.CanTool(ply, chip, "wire_fpga") then
			WireLib.AddNotify(ply, "FPGA: You are not allowed to upload to the target FPGA chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			return
		end

		local dataLength = net.ReadUInt(16)
		local data = net.ReadData(dataLength)

		local ok, data = pcall(util.Decompress, data)
		if not ok then return end

		ok, data = pcall(WireLib.von.deserialize, data)
		if ok then
			chip:Upload(data)
		else
			WireLib.AddNotify(ply, "FPGA: Upload failed! Error message:\n" .. data, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
		end
	end)

	local wire_fpga_event = {}

	concommand.Add("wire_fpga_event", function(ply, command, args)
		local handler = wire_fpga_event[args[1]]
		if not handler then return end
		return handler(ply, args)
	end)

	-- actual editor open/close handlers

	function wire_fpga_event.editor_open(ply, args)
		net.Start("wire_fpga_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(true)
		net.Broadcast()
	end

	function wire_fpga_event.editor_close(ply, args)
		net.Start("wire_fpga_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(false)
		net.Broadcast()
	end

end



if CLIENT then
	------------------------------------------------------------------------------
	-- Open FPGA editor
	------------------------------------------------------------------------------
	function FPGA_OpenEditor()
		if not FPGA_Editor then
			FPGA_Editor = vgui.Create("FPGAEditorFrame")
			FPGA_Editor:Setup("FPGA Editor", "fpgachip")
		end
		FPGA_Editor:Open()
	end
	net.Receive("FPGA_OpenEditor", FPGA_OpenEditor)

	------------------------------------------------------------------------------
	-- Build tool control panel
	------------------------------------------------------------------------------
	function TOOL.BuildCPanel(panel)
		local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("fpgachip")
		FileBrowser:SetSize(235,400)
		function FileBrowser:OnFileOpen(filepath, newtab)
			if not FPGA_Editor then
				FPGA_Editor = vgui.Create("FPGAEditorFrame")
				FPGA_Editor:Setup("FPGA Editor", "fpgachip")
			end
			FPGA_Editor:Open(filepath, nil, newtab)
		end


		----------------------------------------------------------------------------
		local New = vgui.Create("DButton" , panel)
		panel:AddPanel(New)
		New:SetText("New file")
		New.DoClick = function(button)
			FPGA_OpenEditor()
			FPGA_Editor:AutoSave()
			FPGA_Editor:NewChip(false)
		end
		panel:AddControl("Label", {Text = ""})

		----------------------------------------------------------------------------
		local OpenEditor = vgui.Create("DButton", panel)
		panel:AddPanel(OpenEditor)
		OpenEditor:SetText("Open Editor")
		OpenEditor.DoClick = FPGA_OpenEditor


		----------------------------------------------------------------------------
		panel:AddControl("Label", {Text = ""})
		panel:AddControl("Label", {Text = "FPGA settings:"})


		----------------------------------------------------------------------------
		WireDermaExts.ModelSelect(panel, "wire_fpga_model", list.Get("Wire_gate_Models"), 5)
		panel:AddControl("Label", {Text = ""})
	end

	------------------------------------------------------------------------------
	-- Tool screen
	------------------------------------------------------------------------------
	tool_program_name = ""
	tool_program_start = 0
	tool_program_size = 0
	tool_program_bytes = ""
	function FPGASetToolInfo(name, size, last_bytes)
		if #name > 18 then
			tool_program_name = name:sub(1,15) .. "..."
		else
			tool_program_name = name
		end
		tool_program_start = math.max(size - 64, 0)
		tool_program_start = tool_program_start - tool_program_start % 8 + 8
		tool_program_size = size
		tool_program_bytes = last_bytes
	end

	local fontTable = {
		font = "Tahoma",
		size = 20,
		weight = 1000,
		antialias = true,
		additive = false,
	}
	surface.CreateFont("FPGAToolScreenAppFont", fontTable)
	fontTable.size = 20
	fontTable.font = "Courier New"
	surface.CreateFont("FPGAToolScreenHexFont", fontTable)
	fontTable.size = 14
	surface.CreateFont("FPGAToolScreenSmallHexFont", fontTable)

	local function drawButton(x, y)
		surface.SetDrawColor(100, 100, 100, 255)
		surface.DrawRect(x, y, 20, 20)
		surface.SetDrawColor(200, 200, 200, 255)
		surface.DrawRect(x, y, 18, 18)
		surface.SetDrawColor(185, 180, 175, 255)
		surface.DrawRect(x+2, y, 16, 18)
	end

	function TOOL:DrawToolScreen(width, height)
		--Background
		surface.SetDrawColor(185, 180, 175, 255)
		surface.DrawRect(0, 0, 256, 256)

		--Top bar
		surface.SetDrawColor(156, 180, 225, 255)
		surface.DrawRect(5, 5, 256-10, 30)
		surface.SetTexture(surface.GetTextureID("gui/gradient"))
		surface.SetDrawColor(31, 45, 130, 255)
		surface.DrawTexturedRect(5, 5, 256-10, 30)

		--App name
		draw.SimpleText("FPGA Editor", "FPGAToolScreenAppFont", 13, 10, Color(255,255,255,255), 0, 0)

		--Buttons
		drawButton(184, 10)
		draw.SimpleText("_", "FPGAToolScreenAppFont", 188, 6, Color(10,10,10,255), 0, 0)
		drawButton(204, 10)
		draw.SimpleText("☐", "FPGAToolScreenAppFont", 205, 8, Color(10,10,10,255), 0, 0)
		drawButton(226, 10)
		draw.SimpleText("x", "FPGAToolScreenAppFont", 231, 7, Color(10,10,10,255), 0, 0)

		--Program name
		draw.SimpleText(tool_program_name, "FPGAToolScreenHexFont", 10, 38, Color(10,10,10,255), 0, 0)
		--Program size
		if tool_program_size < 1024 then
			draw.SimpleText(tool_program_size.."B", "FPGAToolScreenHexFont", 246, 38, Color(50,50,50,255), 2, 0)
		else
			draw.SimpleText(math.floor(tool_program_size/1024).."kB", "FPGAToolScreenHexFont", 246, 38, Color(50,50,50,255), 2, 0)
		end


		--Hex panel
		surface.SetDrawColor(200, 200, 200, 255)
		surface.DrawRect(5, 60, 256-10, 256-65)

		--Hex address
		draw.SimpleText("Offset", "FPGAToolScreenSmallHexFont", 15, 65, Color(0,0,191,255), 0, 0)
		draw.SimpleText("00 01 02 03 04 05 06 07", "FPGAToolScreenSmallHexFont", 75, 65, Color(0,0,191,255), 0, 0)
		local y = 0
		for i=tool_program_start, tool_program_size, 8 do
			draw.SimpleText(string.format(" %04X", i), "FPGAToolScreenSmallHexFont", 15, 82 + y * 20, Color(0,0,191,255), 0, 0)
			y = y + 1
		end

		--Hex data
		for line = 0, 7 do
			local text = ""
			for i=1, 8 do
				local c = string.byte(tool_program_bytes, line * 8 + i)
				if c then
					text = text .. string.format("%02X", c) .. " "
				end
			end
			draw.SimpleText(text, "FPGAToolScreenSmallHexFont", 75, 82 + line * 20, Color(0,0,0,255), 0, 0)
		end

	end

	local min = math.min
	local surface_DrawPoly = surface.DrawPoly
	local surface_SetDrawColor = surface.SetDrawColor

	local function tableValue(t, v)
		local keys = {}
		for k in pairs(t) do
			keys[#keys+1] = k
		end
		return t[keys[(v - 1) % #keys + 1]]
	end

	local nodeColor = Color(100, 100, 100, 255)

	local size = 100
	local padding = 100

	local node1x, node1y = -padding * 1.5, padding
	local node2x, node2y =  padding * 1.5, -padding

	local springStrength = 40
	local damping = 3
	local impulsePower = 200

	local radialSpringStrength = 16
	local radialDamping = 6

	local curveSegments = 30
	local thickness = 10
	local half = thickness * 0.5

	local function UpdateSpring(node, ft)
		local force = -(springStrength * node.offset + damping * node.vel)
		node.vel = node.vel + force * ft
		node.offset = node.offset + node.vel * ft
	end

	local function BuildBaseCurve(state, dir)
		state.baseCurve = {}

		local startX, startY, endX, endY
		local cx1, cy1, cx2, cy2

		if dir == 1 then
			startX = node1x + size * 0.5
			startY = node1y
			endX   = node2x - size * 0.5
			endY   = node2y

			cx1, cy1 = 0, startY
			cx2, cy2 = 0, endY

			state.reversed = false
		else
			startX = node2x + size * 0.5
			startY = node2y
			endX   = node1x - size * 0.5
			endY   = node1y

			cx1, cy1 = startX + size * 2, startY + size * 2
			cx2, cy2 = endX - size * 2, endY - size * 2

			state.reversed = true
		end

		local prevX, prevY

		for i = 0, curveSegments do
			local t = i / curveSegments

			local it = 1 - t
			local it2 = it * it
			local it3 = it2 * it
			local t2 = t * t
			local t3 = t2 * t

			local x =
				it3 * startX +
				3 * it2 * t * cx1 +
				3 * it * t2 * cx2 +
				t3 * endX

			local y =
				it3 * startY +
				3 * it2 * t * cy1 +
				3 * it * t2 * cy2 +
				t3 * endY

			if prevX then
				state.baseCurve[#state.baseCurve + 1] = {
					x1 = prevX,
					y1 = prevY,
					x2 = x,
					y2 = y,
					t1 = (i - 1) / curveSegments,
					t2 = i / curveSegments
				}
			end

			prevX, prevY = x, y
		end
	end

	local function NewAnimState()
		local state = {
			tStart = 0,
			tEnd = 0,
			dir = 1,
			phase = 1,
			speed = 2.5,
			holdTime = 1,
			holdTimer = 0,
			reversed = false,
			baseCurve = {},
			node1 = { offset = 0, vel = 0 },
			node2 = { offset = 0, vel = 0 },
			lastFrame = 0,
			color = 1,
			swapSpringPos = 0,
			swapSpringVel = 0,
			lastUpdateTime = 0
		}
		BuildBaseCurve(state, 1)
		return state
	end

	local busy_players = WireLib.RegisterPlayerTable()
	net.Receive("wire_fpga_editor_status", function(len)
		local ply = net.ReadEntity()
		local status = net.ReadBit() ~= 0
		if not IsValid(ply) then return end

		busy_players[ply] = status and NewAnimState() or nil
	end)

	local function DrawCachedCurve(state)
		surface_SetDrawColor(tableValue(FPGATypeColor, state.color))

		local tStart = state.tStart
		local tEnd   = state.tEnd
		local node1  = state.node1
		local node2  = state.node2

		local startIndex = math.floor(tStart * curveSegments)
		local endIndex   = math.floor(tEnd   * curveSegments)

		for i = startIndex + 1, endIndex do
			local seg = state.baseCurve[i]
			if seg then
				local t1 = seg.t1
				local t2 = seg.t2

				if state.reversed then
					t1 = 1 - t1
					t2 = 1 - t2
				end

				local offset1 = node1.offset * (1 - t1) + node2.offset * t1
				local offset2 = node1.offset * (1 - t2) + node2.offset * t2

				local y1 = seg.y1 + offset1
				local y2 = seg.y2 + offset2

				local dx = seg.x2 - seg.x1
				local dy = y2 - y1

				local nx = dy
				local ny = -dx

				local len = (nx * nx + ny * ny) ^ 0.5
				if len > 0 then
					nx = nx / len * half
					ny = ny / len * half
				end

				surface_DrawPoly({
					{ x = seg.x1 - nx, y = y1 - ny },
					{ x = seg.x1 + nx, y = y1 + ny },
					{ x = seg.x2 + nx, y = y2 + ny },
					{ x = seg.x2 - nx, y = y2 - ny }
				})
			end
		end
	end

	local pi = math.pi
	local function ArcPos(t, cx, cy, r, a0, a1)
		local a = a0 + (a1 - pi - a0) * t
		return cx + math.cos(a) * r, cy + math.sin(a) * r
	end

	local function UpdateAnim(state, ft)
		local anim = state

		UpdateSpring(anim.node1, ft)
		UpdateSpring(anim.node2, ft)

		if anim.phase == 1 then
			anim.tEnd = min(1, anim.tEnd + anim.speed * ft)
			if anim.tEnd >= 1 then
				anim.phase = 2
				anim.holdTimer = 0

				if anim.dir == 1 then
					anim.node2.vel = anim.node2.vel - impulsePower
				else
					anim.node1.vel = anim.node1.vel - impulsePower
				end
			end

		elseif anim.phase == 2 then
			anim.holdTimer = anim.holdTimer + ft
			if anim.holdTimer >= anim.holdTime then
				anim.phase = 3
			end

		elseif anim.phase == 3 then
			anim.tStart = min(1, anim.tStart + anim.speed * ft)
			if anim.tStart >= 1 then
				anim.tStart = 0
				anim.tEnd = 0
				anim.phase = anim.dir == -1 and 4 or 1
				anim.swapTimer = 0
				anim.dir = -anim.dir
				anim.color = anim.color + 1
				BuildBaseCurve(anim, anim.dir)

			end

		elseif anim.phase == 4 then

			local force = -(radialSpringStrength * (anim.swapSpringPos - 1) + radialDamping * anim.swapSpringVel)
			anim.swapSpringVel = anim.swapSpringVel + force * ft
			anim.swapSpringPos = anim.swapSpringPos + anim.swapSpringVel * ft

			if math.abs(anim.swapSpringPos - 1) < 0.01 and math.abs(anim.swapSpringVel) < 0.02 then
				anim.phase = 1
				anim.swapSpringPos = 0
			end
		end
	end

	local cx = (node1x + node2x) * 0.5
	local cy = (node1y + node2y) * 0.5

	local dx = node1x - cx
	local dy = node1y - cy
	local r = math.sqrt(dx * dx + dy * dy)

	local a1 = math.atan2(node1y - cy, node1x - cx)
	local a2 = math.atan2(node2y - cy, node2x - cx)

	local FPS_LIMIT = 1 / 60

	hook.Add("PostPlayerDraw", "wire_fpga_editor_status", function(ply)
		local state = busy_players[ply]
		if not state then return end

		local lastUpdate = state.lastUpdateTime
		local now = RealTime()
		if now - lastUpdate >= FPS_LIMIT then
			UpdateAnim(state, now - lastUpdate)
			state.lastUpdateTime = now
		end

		local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1") or ply:LookupBone("ValveBiped.HC_Head_Bone") or 0
		local BonePos, _BoneAng = ply:GetBonePosition(BoneIndx)

		local pos = BonePos + ply:GetUp() * (16 + state.swapSpringVel * 4)

		local angle = (pos - EyePos()):GetNormalized():Angle()
		angle = Angle(0, angle.y, 0)
		angle:RotateAroundAxis(angle:Up(), -90)
		angle:RotateAroundAxis(angle:Forward(), 90)

		cam.Start3D2D(pos, angle, 0.05)

			local n1x = node1x
			local n1y = node1y - size * 0.5 + state.node1.offset
			local n2x = node2x
			local n2y = node2y - size * 0.5 + state.node2.offset

			if state.phase == 4 then

				local t = state.swapSpringPos

				local an1x, an1y = ArcPos(t, cx, cy, r, a1, a1)
				local an2x, an2y = ArcPos(t, cx, cy, r, a2, a2)

				n1x = an1x
				n1y = an1y - size * 0.5
				n2x = an2x
				n2y = an2y - size * 0.5
			end

			if state.phase ~= 4 then
				DrawCachedCurve(state)
			end

			draw.RoundedBox(12,
				n1x - size * 0.5,
				n1y,
				size, size,
				nodeColor
			)

			draw.RoundedBox(12,
				n2x - size * 0.5,
				n2y,
				size, size,
				nodeColor
			)

		cam.End3D2D()
	end)

end