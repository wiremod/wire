TOOL.Category		= "Tools"
TOOL.Name			= "Debugger"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.wire_debugger.name", "Debugging Tool" )
	language.Add( "Tool.wire_debugger.desc", "Shows selected components info on the HUD." )
	language.Add( "Tool.wire_debugger.left", "Add component to HUD" )
	language.Add( "Tool.wire_debugger.right", "Remove component from HUD" )
	language.Add( "Tool.wire_debugger.reload", "Clear HUD" )
	language.Add( "Tool_wire_debugger_showports", "Show overlay of ports in HUD" )
	language.Add( "Tool_wire_debugger_orientvertical", "Orient the Inputs/Outputs Vertically" )
	TOOL.Information = { "left", "right", "reload" }
end
if SERVER then
	util.AddNetworkString("WireDbgCount")
	util.AddNetworkString("WireDbg")
end

TOOL.ClientConVar[ "showports" ] = "1"
TOOL.ClientConVar[ "orientvertical" ] = "1"

local Components = {}
local UpdateLineCount
local dbg_line_cache

local function IsWire(entity) --try to find out if the entity is wire
	if (WireLib.HasPorts(entity)) then return true end
	--if entity.IsWire == true then return true end --this shold always be true if the ent is wire compatible, but only is if the base of the entity is "base_wire_entity" THIS NEEDS TO BE FIXED <-- CHALLENGE ACCEPTED! -Grocel
	--if entity.Inputs or entity.Outputs then return true end --this is how the wire STool gun does it
	return false
end

local function stopDebuggingEntity(ply, ent)
	for k,cmp in ipairs(Components[ply]) do
		if (cmp == ent) then
			table.remove(Components[ply], k)
			if SERVER then
				dbg_line_cache[ply] = nil
			end
			return true
		end
	end
	if not next(Components[ply]) then
		if SERVER then
			UpdateLineCount(ply, 0)
		end
		Components[ply] = nil
	end
end

properties.Add("wire_debugger_start", {
	MenuLabel = "Debug",
	MenuIcon  = "icon16/bug.png",
	Order = 500,

	Filter = function(self,ent,ply)
		if not IsValid(ent) then return false end
		if not IsWire(ent) then return false end
		if Components[ply] then
			for _, cmp in ipairs(Components[ply]) do
				if (cmp == ent) then return false end
			end
		end
		return true
	end,

	Action = function(self,ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
		local ply = LocalPlayer()
		Components[ply] = Components[ply] or {}
		table.insert(Components[ply], ent)
	end,

	Receive = function(self,len,ply)
		local ent = net.ReadEntity()
		if not self:Filter(ent,ply) then return end

		Components[ply] = Components[ply] or {}
		table.insert(Components[ply], ent)
	end,
})
properties.Add("wire_debugger_stop", {
	MenuLabel = "Stop Debugging",
	MenuIcon  = "icon16/bug.png",
	Order = 500,

	Filter = function(self,ent,ply)
		if not IsValid(ent) then return false end
		if not IsWire(ent) then return false end
		if Components[ply] then
			for _, cmp in ipairs(Components[ply]) do
				if (cmp == ent) then return true end
			end
		end
		return false
	end,

	Action = function(self,ent)
		self:MsgStart()
		net.WriteEntity(ent)
		self:MsgEnd()
		local ply = LocalPlayer()
		stopDebuggingEntity(ply, ent)
	end,

	Receive = function(self,len,ply)
		local ent = net.ReadEntity()
		if not self:Filter(ent,ply) then return end

		stopDebuggingEntity(ply, ent)
	end,
})

function TOOL:LeftClick(trace)
	if not trace.Entity:IsValid() then return end
	if not IsWire(trace.Entity) then return end

	local ply = self:GetOwner()
	Components[ply] = Components[ply] or {}

	for _, cmp in ipairs(Components[ply]) do
		if (cmp == trace.Entity) then return end
	end

	table.insert(Components[ply], trace.Entity)

	return true
end

if SERVER then
	local dbg_linecount_cache = {}
	function UpdateLineCount(ply, count)
		if dbg_linecount_cache[ply] ~= count then
			dbg_linecount_cache[ply] = count
			net.Start("WireDbgCount") net.WriteUInt(count,16) net.Send(ply)
		end
	end
end


function TOOL:RightClick(trace)
	if not trace.Entity:IsValid() then return end
	if not IsWire(trace.Entity) then return end

	local ply = self:GetOwner()
	if not Components[ply] then return end

	return stopDebuggingEntity(ply, trace.Entity)
end

if CLIENT then
	function TOOL:DrawHUD()
		if self:GetClientNumber("showports") == 0 then return end
		local ent = LocalPlayer():GetEyeTraceNoCursor().Entity
		if not ent:IsValid() then return end

		local inputs, outputs = WireLib.GetPorts(ent)

		if inputs and #inputs ~= 0 then
			surface.SetFont("Trebuchet24")
			local boxh, boxw = 0,0
			for _, port in ipairs(inputs) do
				local name, tp = unpack(port)
				local text = tp == "NORMAL" and name or string.format("%s [%s]", name, tp)
				port.text = text
				port.y = boxh
				local textw,texth = surface.GetTextSize(text)
				if textw > boxw then boxw = textw end
				boxh = boxh + texth
			end

			local boxx, boxy = ScrW()/2-boxw-32, ScrH()/2-boxh/2
			draw.RoundedBox(8,
				boxx-8, boxy-8,
				boxw+16, boxh+16,
				Color(109,146,129,192)
			)

			for _, port in ipairs(inputs) do
				surface.SetTextPos(boxx,boxy+port.y)
				if port[4] then
					surface.SetTextColor(255, 0, 0)
				else
					surface.SetTextColor(255, 255, 255)
				end
				surface.DrawText(port.text)
				port.text = nil
				port.y = nil
			end
		end

		if outputs and #outputs ~= 0 then
			surface.SetFont("Trebuchet24")
			local boxh, boxw = 0,0
			for _, port in ipairs(outputs) do
				local name, tp = unpack(port)
				local text = tp == "NORMAL" and name or string.format("%s [%s]", name, tp)
				port.text = text
				port.y = boxh
				local textw,texth = surface.GetTextSize(text)
				if textw > boxw then boxw = textw end
				boxh = boxh + texth
			end

			local boxx, boxy = ScrW()/2+32, ScrH()/2-boxh/2
			draw.RoundedBox(8,
				boxx-8, boxy-8,
				boxw+16, boxh+16,
				Color(109,146,129,192)
			)

			for _, port in ipairs(outputs) do
				surface.SetTextPos(boxx,boxy+port.y)
				surface.SetTextColor(255, 255, 255)
				surface.DrawText(port.text)
				port.text = nil
				port.y = nil
			end
		end
	end
end

function TOOL:Reload(trace)
	Components[self:GetOwner()] = nil
	if (CLIENT) then return end
	UpdateLineCount(self:GetOwner(), 0)
	dbg_line_cache[self:GetOwner()] = nil
end


if (SERVER) then
	WireToolHelpers.SetupSingleplayerClickHacks(TOOL)

	dbg_line_cache = {}

	local formatPort = WireLib.Debugger.formatPort

	local function updateForPlayer(ply, cmps)
		if not (IsValid(ply) and ply:IsPlayer()) then -- if player has left, clear the hud
			Components[ply] = nil
			return
		end

		local OrientVertical = ply:GetInfoNum("wire_debugger_orientvertical", 0) ~= 0

		-- TODO: Add EntityRemoved hook to clean up Components array.
		table.Compact(cmps, function(cmp) return cmp:IsValid() and IsWire(cmp) end)

		UpdateLineCount(ply, #cmps)

		if #cmps == 0 then Components[ply] = nil return end

		for l,cmp in ipairs(cmps) do
			local dbginfo = cmp.WireDebugName
			if not dbginfo or dbginfo == "No Name" then
				dbginfo = cmp:GetClass()
			end
			dbginfo = dbginfo .. " (" ..cmp:EntIndex() .. ") - "

			if (cmp.Inputs and not table.IsEmpty(cmp.Inputs)) then
				if OrientVertical then
					dbginfo = dbginfo .. "\n"
				end
				dbginfo = dbginfo .. "IN: "
				if OrientVertical then
					dbginfo = dbginfo .. "\n"
				end
				for k, Input in pairs_sortvalues(cmp.Inputs, WireLib.PortComparator) do
					if formatPort[Input.Type] then
						dbginfo = dbginfo .. k .. ":" .. formatPort[Input.Type](Input.Value or WireLib.GetDefaultForType(Input.Type), OrientVertical)
						if OrientVertical then
							dbginfo = dbginfo .. "\n"
						else
							dbginfo = dbginfo .. "  "
						end
					end
				end
			end

			if (cmp.Outputs and not table.IsEmpty(cmp.Outputs)) then
				if(cmp.Inputs and not table.IsEmpty(cmp.Inputs)) then
					dbginfo = dbginfo .. "\n "
				end
				if not cmp.Inputs and OrientVertical then
					dbginfo = dbginfo .. "\n"
				end
				dbginfo = dbginfo .. "OUT: "
				if OrientVertical then
					dbginfo = dbginfo .. "\n"
				end
				for k, Output in pairs_sortvalues(cmp.Outputs, WireLib.PortComparator) do
					if formatPort[Output.Type] then
						dbginfo = dbginfo .. k .. ":" .. formatPort[Output.Type](Output.Value or WireLib.GetDefaultForType(Output.Type), OrientVertical)
						if OrientVertical then
							dbginfo = dbginfo .. "\n"
						else
							dbginfo = dbginfo .. " "
						end
					end
				end
			end

			if (not cmp.Inputs) and (not cmp.Outputs) then
				dbginfo = dbginfo .. "No info"
			end

			dbg_line_cache[ply] = dbg_line_cache[ply] or {}
			if (dbg_line_cache[ply][l] ~= dbginfo) then
				--split the message up into managable chuncks and send them
				net.Start("WireDbg")
					net.WriteBit(OrientVertical)
					net.WriteUInt(l,16)
					net.WriteString(dbginfo)
				net.Send(ply)

				dbg_line_cache[ply][l] = dbginfo
			end
		end
	end

	local function Wire_DebuggerThink()
		for ply,cmps in pairs(Components) do
			updateForPlayer(ply, cmps)
		end
	end

	timer.Create("Wire_DebuggerThink", game.SinglePlayer() and 0.05 or 0.1, 0, Wire_DebuggerThink)
	-- hook.Add("Think", "Wire_DebuggerThink", Wire_DebuggerThink)

end


if (CLIENT) then

	local dbg_lines = {}
	local dgb_orient_vert = false
	local BoxWidth = 300
	local LastBoxUpdate = 0

	local function DebuggerDrawHUD()
		if not next(dbg_lines) then return end

		--setup the font
		surface.SetFont("Default")

		--buid the table of entries
		local Line_Count = 0
		local ColorType = 0
		local Entries = {}
		for _, Line in pairs(dbg_lines) do
			local CurEntry = {}
			CurEntry.Lines = {}

			local ExplodeLines = string.Explode("\n", Line)

			for Index, ExplodeLine in ipairs(ExplodeLines) do --break it into multible lines for 1 entry
				if string.Trim(ExplodeLine) ~= "" then

					local XPos = 0
					if(Index > 1) then
						if dgb_orient_vert then --if the string is not the first and it is vertical, line it up acordingly
							if(string.Trim(ExplodeLine) == "OUT:" or string.Trim(ExplodeLine) == "IN:") then
								XPos = 17
							else
								XPos = 42
							end
						else --if the string is not the first and it is not vertical, line it up with the IN on the first line
							if(CurEntry.Lines[1].LineText and string.find(CurEntry.Lines[1].LineText,"IN:")) then
								local TextPos = string.find(CurEntry.Lines[1].LineText,"IN:")-1
								XPos = surface.GetTextSize( string.Left(CurEntry.Lines[1].LineText, TextPos) )
							end
						end

					end

					local TrimLine = {
						LineText = string.Trim(ExplodeLine),
						OffsetPos = { XPos, Line_Count*14 } --move the next text down some for each line
					}
					table.insert(CurEntry.Lines, TrimLine )
					Line_Count = Line_Count+1

				end
			end

			--set the color
			if(ColorType == 0) then
				CurEntry.TextColor = Color(255,255,255)
			else
				CurEntry.TextColor = Color(130,255,158)
			end

			--put it in the table
			table.insert(Entries, CurEntry)

			--switch the color
			ColorType = 1-ColorType
		end



		--determine the box width every second
		if(LastBoxUpdate < CurTime()) then
			local LongestWidth = 0
			local TextWidth
			for _, Entry in ipairs(Entries) do
				for _, Line in ipairs(Entry.Lines) do
					TextWidth = surface.GetTextSize(string.Trim(Line.LineText))
					TextWidth = TextWidth+Line.OffsetPos[1] --offset it with the text's offset

					if(TextWidth > LongestWidth) then
						LongestWidth = TextWidth
					end
				end
			end
			BoxWidth = LongestWidth+16
			LastBoxUpdate = CurTime()+1
		end


		--move the box down if the active weapon is the tool gun
		local MoveBox = 0
		if(LocalPlayer():IsValid() and LocalPlayer():IsPlayer()) then
			if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" then
				MoveBox = 1
			end
		else --return if the player is dead or non-existant
			return
		end


		-- TODO: account for larger usage info boxes.
		--draw the box
		draw.RoundedBox(8, 2, 2+250*MoveBox, BoxWidth, Line_Count*14+16, Color(50, 50, 50, 128))

		--step through all of the entries and their text to print them
		for _, Entry in ipairs(Entries) do
			for _, Line in ipairs(Entry.Lines) do
				draw.Text({
					text = string.Trim(Line.LineText) or "",
					font = "Default",
					pos = { Line.OffsetPos[1]+10, 250*MoveBox+10+Line.OffsetPos[2] },
					color = Entry.TextColor
					})

			end
		end

	end
	hook.Add("HUDPaint", "DebuggerDrawHUD", DebuggerDrawHUD)

	net.Receive("WireDbgCount", function(netlen)
		for k=net.ReadUInt(16)+1, #dbg_lines do
			dbg_lines[k] = nil
		end
	end)
	net.Receive("WireDbg", function(netlen)
		dgb_orient_vert = net.ReadBit() ~= 0
		dbg_lines[net.ReadUInt(16)] = net.ReadString()
	end)

end

function TOOL.BuildCPanel(panel)
	panel:Help("#Tool.wire_debugger.desc")
	panel:CheckBox("#Tool_wire_debugger_showports", "wire_debugger_showports")
	panel:CheckBox("#Tool_wire_debugger_orientvertical", "wire_debugger_orientvertical")
end
