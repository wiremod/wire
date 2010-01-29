TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Expression 2"
TOOL.Command 		= nil
TOOL.ConfigName 	= ""
TOOL.Tab			= "Wire"

TOOL.ClientConVar = {
	model       = "models/beer/wiremod/gate_e2.mdl",
	scriptmodel = "",
	size        = "",
	select      = "",
	autoindent  = 1,
}

if CLIENT then
	language.Add("Tool_wire_expression2_name", "Expression 2 Tool (Wire)")
	language.Add("Tool_wire_expression2_desc", "Spawns an Expression 2 chip for use with the wire system.")
	language.Add("Tool_wire_expression2_0",    "Primary: Create/Update Expression, Secondary: Open Expression in Editor")
	language.Add("sboxlimit_wire_expression",  "You've hit the Expression limit!")
	language.Add("Undone_wire_expression2",    "Undone Expression 2")
	language.Add("Cleanup_wire_expressions",   "Expression 1+2" )
	language.Add("Cleaned_wire_expressions",   "Cleaned up all Wire Expressions" )
end

cleanup.Register("wire_expressions")

if CLIENT then
	if CanRunConsoleCommand() then
		CreateClientConVar("wire_expression2_friendwrite", 0, false, true)
	else
		hook.Add("OnEntityCreated", "wire_expression2_console", function(ent)
			if not ValidEntity(ent) then return end
			if ent ~= LocalPlayer() then return end

			CreateClientConVar("wire_expression2_friendwrite", 0, false, true)
		end)
	end
end

if SERVER then
	CreateConVar('sbox_maxwire_expressions', 20)

	function TOOL:LeftClick(trace)
		if trace.Entity:IsPlayer() then return false end

		local player = self:GetOwner()
		local model = self:GetModel()
		local pos = trace.HitPos
		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& (trace.Entity.player == player || trace.Entity.player:GetInfoNum("wire_expression2_friendwrite") != 0)
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			trace.Entity:Prepare(player)
			player:SendLua("wire_expression2_upload()")
			return true
		end

		if !self:GetSWEP():CheckLimit("wire_expressions") then return false end

		local entity = ents.Create("gmod_wire_expression2")
		if !entity:IsValid() then return false end

		player:AddCount("wire_expressions", entity)

		entity:SetModel(model)
		entity:SetAngles(ang)
		entity:SetPos(pos)
		entity:Spawn()
		entity:SetPlayer(player)
		entity.player = player

		if !entity then return false end

		entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
		local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)

		undo.Create("wire_expression2")
			undo.AddEntity(entity)
			undo.SetPlayer(player)
			undo.AddEntity(constraint)
		undo.Finish()

		player:AddCleanup("wire_expressions", entity)

		entity:Prepare(player)
		player:SendLua("wire_expression2_upload()")
		return true
	end

	function TOOL:Reload(trace)
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local player = self:GetOwner()

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& (trace.Entity.player == player || trace.Entity.player:GetInfoNum("wire_expression2_friendwrite") != 0)
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			trace.Entity:Reset()
			return true
		else
			return false
		end
	end

	function MakeWireExpression2(player, Pos, Ang, model, buffer, name, inputs, outputs, vars)
		if !player:CheckLimit("wire_expressions") then return false end

		local self = ents.Create("gmod_wire_expression2")
		if !self:IsValid() then return false end

		self:SetModel(model)
		self:SetAngles(Ang)
		self:SetPos(Pos)
		self:Spawn()
		self:SetPlayer(player)
		self.player = player

		buffer = string.Replace(string.Replace(buffer,"£","\""),"€","\n")

		self:SetOverlayText("Expression 2\n" .. name)
		self.buffer = buffer

		self.Inputs = WireLib.AdjustSpecialInputs(self, inputs[1], inputs[2])
		self.Outputs = WireLib.AdjustSpecialOutputs(self, outputs[1], outputs[2])

		self.dupevars = vars

		player:AddCount("wire_expressions", self)
		player:AddCleanup("wire_expressions", self)
		return self
	end

	duplicator.RegisterEntityClass("gmod_wire_expression2", MakeWireExpression2, "Pos", "Ang", "Model", "_original", "_name", "_inputs", "_outputs", "_vars")

	function TOOL:RightClick(trace)
		if trace.Entity:IsPlayer() then return false end

		local player = self:GetOwner()

		if  trace.Entity:IsValid()
		    && trace.Entity:GetClass() == "gmod_wire_expression2"
			&& E2Lib.isFriend(trace.Entity.player, player)
		then
			trace.Entity:SendCode(player)
			trace.Entity:Prepare(player)
			return true
		end

		player:SendLua("openE2Editor()")
		return false
	end

	function TOOL:Think()
		local model = self:GetModel()
		if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() || self.GhostEntity:GetModel() != model then
			self:MakeGhostEntity(model, Vector(0, 0, 0), Angle(0, 0, 0))
		end
		self:UpdateGhostWireExpression2(self.GhostEntity, self:GetOwner())
	end

	function TOOL:UpdateGhostWireExpression2(entity, ply)
		if !entity or !entity:IsValid() then return end

		local trace = util.TraceLine(utilx.GetPlayerTrace(ply, ply:GetCursorAimVector()))
		if !trace.Hit then return end

		if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_expression2" || trace.Entity:IsPlayer()) then
			entity:SetNoDraw(true)
		else
			local ang = trace.HitNormal:Angle()
			ang.pitch = ang.pitch + 90

			entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
			entity:SetAngles(ang)
			entity:SetNoDraw(false)
		end
	end

	local prevmodel,prevvalid
	function validModelCached(model)
		if model ~= prevmodel then
			prevmodel = model
			prevvalid = util.IsValidModel(model)
		end
		return prevvalid
	end

	function TOOL:GetModel()
		local scriptmodel = self:GetClientInfo("scriptmodel")
		if scriptmodel and scriptmodel ~= "" and validModelCached(scriptmodel) then return scriptmodel end

		local model = self:GetClientInfo("model")
		local size = self:GetClientInfo("size")

		if model and size then
			local modelname, modelext = model:match("(.*)(%..*)")
			if not modelext then return model end
			local newmodel = modelname .. size .. modelext
			if validModelCached(newmodel) then
				return Model(newmodel)
			else
				return Model(model)
			end
		end
	end

elseif CLIENT then

	local dir
	local lastclick = CurTime()
	local download = {}
	local Validation

	function wire_expression2_upload()
		if( wire_expression2_editor == nil ) then initE2Editor() end
		local result = wire_expression2_validate(wire_expression2_editor:GetCode())
		if result then
			WireLib.AddNotify(result, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		transfer(wire_expression2_editor:GetCode())
	end

	function wire_expression2_download(um)
		if(!um) then return end
		local chunks = um:ReadShort()
		if(!download.downloading) then
			download.downloading = true
			download.chunks = chunks
			download.current = -1
			download.code = ""
			download.name = um:ReadString()
			return
		end

		if( download.current + 1 == chunks ) then
			download.current = chunks
			download.code = download.code .. um:ReadString()
		else
			download = {}
		end

		if( download.downloading && download.chunks == chunks) then
			if( wire_expression2_editor == nil ) then initE2Editor() end
			wire_expression2_editor:Open(download.name, download.code)
			wire_expression2_editor.chip = true
			download = {}
			return
		end

	end

	usermessage.Hook("wire_expression2_download", wire_expression2_download)

	function TOOL.BuildCPanel(panel)
		panel:ClearControls()
		panel:AddControl("Header", { Text = "#Tool_wire_expression2_name", Description = "#Tool_wire_expression2_desc" })

		//ModelPlug_AddToCPanel(panel, "expr2", "wire_expression2", nil, nil, nil, 2)

		panel:AddControl("ComboBox", {
			MenuButton = "0",
			Options = {
				["Normal"] = { wire_expression2_size = "" },
				["Mini"] = { wire_expression2_size = "_mini" },
				["Nano"] = { wire_expression2_size = "_nano" },
			}
		})

		panel:AddControl("MaterialGallery", {
			Height = "100",
			Width = "100",
			Rows = 2,
			Stretch = false,
			ConVar = "wire_expression2_select",
			Options = {
				["Modern"] =     { wire_expression2_select = "Modern",     Value = "Modern",     Material = "beer/wiremod/gate_e2",        wire_expression2_model = "models/beer/wiremod/gate_e2.mdl" },
				["Expression"] = { wire_expression2_select = "Expression", Value = "Expression", Material = "models/expression 2/exprssn", wire_expression2_model = "models/expression 2/cpu_expression.mdl" },
				["Microchip"] =  { wire_expression2_select = "Microchip",  Value = "Microchip",  Material = "models/expression 2/mcrochp", wire_expression2_model = "models/expression 2/cpu_microchip.mdl" },
				["Interface"] =  { wire_expression2_select = "Interface",  Value = "Interface",  Material = "models/expression 2/intrfce", wire_expression2_model = "models/expression 2/cpu_interface.mdl" },
				["Controller"] = { wire_expression2_select = "Controller", Value = "Controller", Material = "models/expression 2/cntrllr", wire_expression2_model = "models/expression 2/cpu_controller.mdl" },
				["Processor"] =  { wire_expression2_select = "Processor",  Value = "Processor",  Material = "models/expression 2/prcssor", wire_expression2_model = "models/expression 2/cpu_processor.mdl" },
			}
		})

		if( wire_expression2_editor == nil ) then initE2Editor() end

		local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
		panel:AddPanel(FileBrowser)
		FileBrowser:Setup("Expression2")
		FileBrowser:SetSize(235,400)
		function FileBrowser:OnFileClick()
			if( wire_expression2_editor == nil ) then initE2Editor() end

			if(dir == self.File.FileDir and CurTime() - lastclick < 1) then
				wire_expression2_editor:Open(dir)
			else
				lastclick = CurTime()
				dir = self.File.FileDir
				wire_expression2_editor:LoadFile(dir)
				Validation:Validate()
			end
		end

		Validation = vgui.Create("Label" , panel)
		panel:AddPanel(Validation)
		Validation.OnMousePressed = function(panel) panel:Validate() end
		Validation.Validate = function(panel)
			local errors = wire_expression2_validate(wire_expression2_editor:GetCode())
			if(!errors) then
				panel:SetText("Validation Successful")
			else
				panel:SetText("Error in file")
			end
		end
		Validation:SetText("Click to validate...")
		local OpenEditor = vgui.Create("DButton" , panel)
		panel:AddPanel(OpenEditor)
		OpenEditor:SetTall(30)
		OpenEditor:SetText("Open Editor")
		OpenEditor.DoClick = function(button)
			wire_expression2_editor:Open()
		end

		local NewExpression = vgui.Create("DButton" , panel)
		panel:AddPanel(NewExpression)
		NewExpression:SetTall(30)
		NewExpression:SetText("New Expression")
		NewExpression.DoClick = function(button)
			wire_expression2_editor:Open()
			wire_expression2_editor:NewScript()
		end

	end

	function initE2Editor()
		wire_expression2_editor = vgui.Create( "Expression2EditorFrame")
		wire_expression2_editor:Setup("Expression 2 Editor","Expression2","E2")
	end

	function openE2Editor()
		if( wire_expression2_editor == nil ) then initE2Editor() end
		wire_expression2_editor:Open()
	end

	function transfer(code)
		local encoded = E2Lib.encode(code)
		local length = encoded:len()
		local chunks = math.ceil(length / 480)

		Expression2SetProgress(0)
		RunConsoleCommand("wire_expression_upload_begin", code:len(), chunks)

		timer.Create("wire_expression_upload", 1/60, chunks, transfer_callback, { encoded, 1, chunks })
	end

	function transfer_callback(state)
		local i = state[2] - 1

		Expression2SetProgress(math.Round((state[2] / state[3]) * 100))
		RunConsoleCommand("wire_expression_upload_data", state[1]:sub(i * 480 + 1, (i + 1) * 480))

		if state[2] == state[3] then
			timer.Create("wire_expression_upload_reset", 0.5, 1, function() Expression2SetProgress(nil) end )

			timer.Destroy("wire_expression_upload")
			RunConsoleCommand("wire_expression_upload_end")
		end

		state[2] = state[2] + 1
	end

	/******************************************************************************\
	  Expression 2 Tool Screen for Garry's Mod
	  Andreas "Syranide" Svensson, me@syranide.com
	\******************************************************************************/

	surface.CreateFont("Arial", 40, 1000, true, false, "Expression2ToolScreenFont")
	surface.CreateFont("Arial", 30, 1000, true, false, "Expression2ToolScreenSubFont")

	local percent = nil
	local name = "Unnamed"

	function Expression2SetName(n)
		name = n
		if !name then
			name = "Unnamed"
			return
		end

		surface.SetFont("Expression2ToolScreenSubFont")
		local ww = surface.GetTextSize("...")

		local w, h = surface.GetTextSize(name)
		if w < 240 then return end

		while true do
			local w, h = surface.GetTextSize(name)
			if w < 240 - ww then break end
			name = string.sub(name, 1, -2)
		end

		name = string.Trim(name) .. "..."
	end

	function Expression2SetProgress(p)
		percent = p
	end

	function DrawTextOutline(text, font, x, y, color, xalign, yalign, bordercolor, border)
		for i=0,8 do
			draw.SimpleText(text, font, x + border * math.sin(i * math.pi / 4), y + border * math.cos(i * math.pi / 4), bordercolor, xalign, yalign)
		end

		draw.SimpleText(text, font, x, y, color, xalign, yalign)
	end

	local CogColor = Color(150, 34, 34, 255)
	local CogTexture = surface.GetTextureID("expression 2/cog")
	if CogTexture == surface.GetTextureID("texturemissing") then CogTexture = nil end

	function TOOL:RenderToolScreen()
		cam.Start2D()

			surface.SetDrawColor(32, 32, 32, 255)
			surface.DrawRect(0, 0, 256, 256)

			if CogTexture then
				if percent then
					ToColor = Color(34, 150, 34, 255)
				else
					ToColor = Color(150, 34, 34, 255)
				end

				CogDelta = 750 * FrameTime()

				CogColor.r = CogColor.r + math.max(-CogDelta, math.min(CogDelta, ToColor.r - CogColor.r))
				CogColor.g = CogColor.g + math.max(-CogDelta, math.min(CogDelta, ToColor.g - CogColor.g))
				CogColor.b = CogColor.b + math.max(-CogDelta, math.min(CogDelta, ToColor.b - CogColor.b))

				surface.SetTexture(CogTexture)
				surface.SetDrawColor(CogColor.r, CogColor.g, CogColor.b, 255)
				surface.DrawTexturedRectRotated(256, 256, 455, 455, RealTime() * 10)
				surface.DrawTexturedRectRotated(30, 30, 227.5, 227.5, RealTime() * -20 + 12.5)
			end

			surface.SetFont("Expression2ToolScreenFont")
			local w, h = surface.GetTextSize(" ")
			surface.SetFont("Expression2ToolScreenSubFont")
			local w2, h2 = surface.GetTextSize(" ")

			if percent then
				surface.SetFont("Expression2ToolScreenFont")
				local w, h = surface.GetTextSize("Uploading")
				DrawTextOutline("Uploading", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
				draw.RoundedBox(4, 128 - w/2 - 2, 128 + h / 2 - 0, (w*percent)/100 + 4, h2 - 4, Color(0, 0, 0, 255))
				draw.RoundedBox(2, 128 - w/2 + 2, 128 + h / 2 + 4, (w*percent)/100 - 4, h2 - 12, Color(224, 224, 224, 255))
			elseif name then
				DrawTextOutline("Expression 2", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
				DrawTextOutline(name, "Expression2ToolScreenSubFont", 128, 128 + (h+h2) / 2 - 4, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
			end

		cam.End2D()
	end
end

/*************************** 'in editor' animation ****************************/

if SERVER then

	/************************* client-side event handling *************************/
	-- this might fit better elsewhere

	local wire_expression2_event = {}

	concommand.Add("wire_expression2_event", function(ply, command, args)
		local handler = wire_expression2_event[args[1]]
		if not handler then return end
		return handler(ply, args)
	end)

	-- actual editor open/close handlers

	function wire_expression2_event.editor_open(ply, args)
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("wire_expression2_editor_status", rp)
			umsg.Entity(ply)
			umsg.Bool(true)
		umsg.End()
	end

	function wire_expression2_event.editor_close(ply, args)
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("wire_expression2_editor_status", rp)
			umsg.Entity(ply)
			umsg.Bool(false)
		umsg.End()
	end

elseif CLIENT then

	local busy_players = {}
	hook.Add("EntityRemoved", "wire_expression2_busy_animation", function(ply)
		busy_players[ply] = nil
	end)

	local emitter = ParticleEmitter(Vector(0,0,0))

	usermessage.Hook("wire_expression2_editor_status", function(um)
		local ply = um:ReadEntity()
		local status = um:ReadBool()

		if not ply:IsValid() then return end
		if ply == LocalPlayer() then return end

		busy_players[ply] = status or nil
	end)

	local rolldelta = math.rad(80)
	timer.Create("wire_expression2_editor_status", 1, 0, function()
		rolldelta = -rolldelta
		for ply,_ in pairs(busy_players) do
			local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1")
			local BonePos, BoneAng = ply:GetBonePosition( BoneIndx )
			local particle = emitter:Add("expression 2/cog_world", BonePos+Vector(0,0,16))
			if particle then
				particle:SetColor(150,34,34,255)
				particle:SetVelocity(Vector(0,0,17))

				particle:SetDieTime(3)
				particle:SetLifeTime(0)

				particle:SetStartSize(10)
				particle:SetEndSize(10)

				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)

				particle:SetRollDelta(rolldelta)
			end
		end
	end)

end
