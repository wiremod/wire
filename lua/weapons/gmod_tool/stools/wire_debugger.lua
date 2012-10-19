TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Debugger"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.wire_debugger.name", "Debugging Tool" )
	language.Add( "Tool.wire_debugger.desc", "Shows selected components info on the HUD." )
	language.Add( "Tool.wire_debugger.0", "Primary: Add component to HUD, Secondary: Remove component from HUD, Reload: Clear HUD" )
	language.Add( "Tool_wire_debugger_showports", "Show overlay of ports in HUD" )
	language.Add( "Tool_wire_debugger_orientvertical", "Orient the Inputs/Outputs Vertically" )
end
if SERVER then
	util.AddNetworkString("WireDbgCount")
	util.AddNetworkString("WireDbg")
end

TOOL.ClientConVar[ "showports" ] = "1"
TOOL.ClientConVar[ "orientvertical" ] = "1"

local Components = {}

local function IsWire(entity) --try to find out if the entity is wire
	if (WireLib.HasPorts(entity)) then return true end
	--if entity.IsWire == true then return true end --this shold always be true if the ent is wire compatible, but only is if the base of the entity is "base_wire_entity" THIS NEEDS TO BE FIXED <-- CHALLENGE ACCEPTED! -Grocel
	--if entity.Inputs or entity.Outputs then return true end --this is how the wire STool gun does it
	return false
end

function TOOL:LeftClick(trace)
	if (!trace.Entity:IsValid()) then return end
	if (!IsWire(trace.Entity)) then return end
	if (CLIENT) then return true end

	ply_idx = self:GetOwner()
	Components[ply_idx] = Components[ply_idx] or {}

	for k,cmp in ipairs(Components[ply_idx]) do
		if (cmp == trace.Entity) then return end
	end

	table.insert(Components[ply_idx], trace.Entity)

	return true
end


function TOOL:RightClick(trace)
	if (!trace.Entity:IsValid()) then return end
	if (!IsWire(trace.Entity)) then return end
	if (CLIENT) then return true end

	ply_idx = self:GetOwner()
	if not Components[ply_idx] then return end

	for k,cmp in ipairs(Components[ply_idx]) do
		if (cmp == trace.Entity) then
			table.remove(Components[ply_idx], k)
			return true
		end
	end
	if not next(Components[ply_idx]) then
		net.Start("WireDbgCount")
			net.WriteUInt(0,16)
		net.Send(ply_idx)
		Components[ply_idx] = nil
	end
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
			for num,port in ipairs(inputs) do
				local name,tp,desc,connected = unpack(port)
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

			for num,port in ipairs(inputs) do
				surface.SetTextPos(boxx,boxy+port.y)
				if port[4] then
					surface.SetTextColor(Color(255,0,0,255))
				else
					surface.SetTextColor(Color(255,255,255,255))
				end
				surface.DrawText(port.text)
				port.text = nil
				port.y = nil
			end
		end

		if outputs and #outputs ~= 0 then
			surface.SetFont("Trebuchet24")
			local boxh, boxw = 0,0
			for num,port in ipairs(outputs) do
				local name,tp,desc = unpack(port)
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

			for num,port in ipairs(outputs) do
				surface.SetTextPos(boxx,boxy+port.y)
				surface.SetTextColor(Color(255,255,255,255))
				surface.DrawText(port.text)
				port.text = nil
				port.y = nil
			end
		end
	end
end

function TOOL:Reload(trace)
	if (CLIENT) then return end
	net.Start("WireDbgCount")
		net.WriteUInt(0,16)
	net.Send(self:GetOwner())
	Components[self:GetOwner()] = nil
end


if (SERVER) then

	local dbg_line_cache = {}
	local dbg_line_time = {}

	local formatPort = {}
	WireLib.Debugger = { formatPort = formatPort } -- Make it global
	function formatPort.NORMAL(value)
		return string.format("%.3f",value)
	end

	function formatPort.STRING(value)
		return '"' .. value .. '"'
	end

	function formatPort.VECTOR(value)
		return string.format("(%.1f,%.1f,%.1f)", value[1], value[2], value[3])
	end

	function formatPort.ANGLE(value)
		return string.format("(%.1f,%.1f,%.1f)", value.p, value.y, value.r)
	end

	formatPort.ENTITY = function(ent)
		if not IsValid(ent) then return "(null)" end -- this uses IsValid from E2, which is faster, but maybe we shouldn't use it.
		return tostring(ent)
	end
	formatPort.BONE = e2_tostring_bone

	function formatPort.MATRIX(value)
		local RetText = "[11="..value[1]..",12="..value[2]..",13="..value[3]
			  RetText = RetText..",21="..value[4]..",22="..value[5]..",23="..value[6]
			  RetText = RetText..",31="..value[7]..",32="..value[8]..",33="..value[9].."]"
		return RetText
	end

	function formatPort.MATRIX2(value)
		local RetText = "[11="..value[1]..",12="..value[2]
			  RetText = RetText..",21="..value[3]..",22="..value[4].."]"
		return RetText
	end

	function formatPort.MATRIX4(value)
		local RetText = "[11="..value[1]..",12="..value[2]..",13="..value[3]..",14="..value[4]
			  RetText = RetText..",21="..value[5]..",22="..value[6]..",23="..value[7]..",24="..value[8]
			  RetText = RetText..",31="..value[9]..",32="..value[10]..",33="..value[11]..",34="..value[12]
			  RetText = RetText..",41="..value[13]..",42="..value[14]..",43="..value[15]..",44="..value[16].."]"
		return RetText
	end

	function formatPort.ARRAY(value, OrientVertical)
		local RetText = ""
		local ElementCount = 0
		for Index, Element in ipairs(value) do
			ElementCount = ElementCount+1
			if(ElementCount > 10) then
				break
			end
			RetText = RetText..Index.."="
			--Check for array element type
			if(type(Element) == "number") then --number
				RetText = RetText..formatPort.NORMAL(Element)
			elseif((type(Element) == "table" and #Element == 3) or type(Element) == "Vector") then --vector
				RetText = RetText..formatPort.VECTOR(Element)
			elseif(type(Element) == "table" and #Element == 2) then --vector2
				RetText = RetText..formatPort.VECTOR2(Element)
			elseif(type(Element) == "table" and #Element == 4) then --vector4
				RetText = RetText..formatPort.VECTOR4(Element)
			elseif((type(Element) == "table" and #Element == 3) or type(Element) == "Angle") then --angle
				if(type(Element) == "Angle") then
					RetText = RetText..formatPort.ANGLE(Element)
				else
					RetText = RetText.."(" .. math.Round(Element[1]*10)/10 .. "," .. math.Round(Element[2]*10)/10 .. "," .. math.Round(Element[3]*10)/10 .. ")"
				end
			elseif(type(Element) == "table" and #Element == 9) then --matrix
				RetText = RetText..formatPort.MATRIX(Element)
			elseif(type(Element) == "table" and #Element == 16) then --matrix4
				RetText = RetText..formatPort.MATRIX4(Element)
			elseif(type(Element) == "string") then --string
				RetText = RetText..formatPort.STRING(Element)
			elseif(type(Element) == "Entity") then --entity
				RetText = RetText..formatPort.ENTITY(Element)
			elseif(type(Element) == "Player") then --player
				RetText = RetText..tostring(Element)
			elseif(type(Element) == "Weapon") then --weapon
				RetText = RetText..tostring(Element)..Element:GetClass()
			elseif(type(Element) == "PhysObj" and e2_tostring_bone(Element) != "(null)") then --Bone
				RetText = RetText..formatPort.BONE(Element)
			else
				RetText = RetText.."No Display for "..type(Element)
			end
			--TODO: add matrix 2
			if OrientVertical then
				RetText = RetText..",\n"
			else
				RetText = RetText..", "
			end
		end
		RetText = string.sub(RetText,1,-3)
		return "{"..RetText.."}"
	end

	function formatPort.TABLE(value, OrientVertical)
		local RetText = ""
		local ElementCount = 0
		for Index, Element in pairs(value) do
			ElementCount = ElementCount+1
			if(ElementCount > 7) then
				break
			end

			local long_typeid = string.sub(Index,1,1) == "x"
			local typeid = string.sub(Index,1,long_typeid and 3 or 1)
			local IdxID = string.sub(Index,(long_typeid and 3 or 1)+1)

			RetText = RetText..IdxID.."="
			--Check for array element type
			if(typeid == "n") then --number
				RetText = RetText..formatPort.NORMAL(Element)
			elseif((type(Element) == "table" and #Element == 3) or type(Element) == "Vector") then --vector
				RetText = RetText..formatPort.VECTOR(Element)
			elseif(type(Element) == "table" and #Element == 2) then --vector2
				RetText = RetText..formatPort.VECTOR2(Element)
			elseif(type(Element) == "table" and #Element == 4 and typeid == "v4") then --vector4
				RetText = RetText..formatPort.VECTOR4(Element)
			elseif((type(Element) == "table" and #Element == 3) or type(Element) == "Angle") then --angle
				if(type(Element) == "Angle") then
					RetText = RetText..formatPort.ANGLE(Element)
				else
					RetText = RetText.."(" .. math.Round(Element[1]*10)/10 .. "," .. math.Round(Element[2]*10)/10 .. "," .. math.Round(Element[3]*10)/10 .. ")"
				end
			elseif(type(Element) == "table" and #Element == 9) then --matrix
				RetText = RetText..formatPort.MATRIX(Element)
			elseif(type(Element) == "table" and #Element == 16) then --matrix4
				RetText = RetText..formatPort.MATRIX4(Element)
			elseif(typeid == "s") then --string
				RetText = RetText..formatPort.STRING(Element)
			elseif(type(Element) == "Entity" and typeid == "e") then --entity
				RetText = RetText..formatPort.ENTITY(Element)
			elseif(type(Element) == "Player") then --player
				RetText = RetText..tostring(Element)
			elseif(type(Element) == "Weapon") then --weapon
				RetText = RetText..tostring(Element)..Element:GetClass()
			elseif(typeid == "b") then
				RetText = RetText..formatPort.BONE(Element)
			else
				RetText = RetText.."No Display for "..type(Element)
			end
			--TODO: add matrix 2
			if OrientVertical then
				RetText = RetText..",\n"
			else
				RetText = RetText..", "
			end
		end
		RetText = string.sub(RetText,1,-3)
		return "{"..RetText.."}"
	end

	-- Shouldn't this be in WireLib instead???
	function WireLib.registerDebuggerFormat(typename, func)
		formatPort[typename:upper()] = func
	end

	local function Wire_DebuggerThink()
		for ply,cmps in pairs(Components) do

			if ( !ply ) or ( !ply:IsValid() ) or ( !ply:IsPlayer() ) then -- if player has left, clear the hud

				Components[ply] = nil

			else

				OrientVertical = ply:GetInfoNum("wire_debugger_orientvertical", 0) ~= 0

				-- TODO: Add EntityRemoved hook to clean up Components array.
				table.Compact(cmps, function(cmp) return cmp:IsValid() and IsWire(cmp) end)

				-- TODO: only send in TOOL:*Click/Reload hooks maybe.
				net.Start("WireDbgCount")
					net.WriteUInt(#cmps,16)
				net.Send(ply)

				if #cmps == 0 then Components[ply] = nil end

				for l,cmp in ipairs(cmps) do
					local dbginfo = cmp.WireDebugName
					if not dbginfo or dbginfo == "No Name" then
						dbginfo = cmp:GetClass()
					end
					dbginfo = dbginfo .. " (" ..cmp:EntIndex() .. ") - "

					if (cmp.Inputs and table.Count(cmp.Inputs) > 0) then
						if OrientVertical then
							dbginfo = dbginfo .. "\n"
						end
						dbginfo = dbginfo .. "IN: "
						if OrientVertical then
							dbginfo = dbginfo .. "\n"
						end
						for k, Input in pairs_sortvalues(cmp.Inputs, WireLib.PortComparator) do
							if formatPort[Input.Type] then
								dbginfo = dbginfo .. k .. ":" .. formatPort[Input.Type](Input.Value, OrientVertical)
								if OrientVertical then
									dbginfo = dbginfo .. "\n"
								else
									dbginfo = dbginfo .. "  "
								end
							end
						end
					end

					if (cmp.Outputs and table.Count(cmp.Outputs) > 0) then
						if(cmp.Inputs and table.Count(cmp.Inputs) > 0) then
							dbginfo = dbginfo .. "\n "
						end
						if(!cmp.Inputs and OrientVertical) then
							dbginfo = dbginfo .. "\n"
						end
						dbginfo = dbginfo .. "OUT: "
						if OrientVertical then
							dbginfo = dbginfo .. "\n"
						end
						for k, Output in pairs_sortvalues(cmp.Outputs, WireLib.PortComparator) do
							if formatPort[Output.Type] then
								dbginfo = dbginfo .. k .. ":" .. formatPort[Output.Type](Output.Value, OrientVertical)
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
					dbg_line_time[ply] = dbg_line_time[ply] or {}
					if (dbg_line_cache[ply][l] ~= dbginfo) then
						if (not dbg_line_time[ply][l]) or (CurTime() > dbg_line_time[ply][l]) then
							--split the message up into managable chuncks and send them
							net.Start("WireDbg")
								net.WriteBit(OrientVertical)
								net.WriteUInt(l,16)
								net.WriteString(dbginfo)
							net.Send(ply)

							dbg_line_cache[ply][l] = dbginfo
							if (game.SinglePlayer()) then
								dbg_line_time[ply][l] = CurTime() + 0.05
							else
								dbg_line_time[ply][l] = CurTime() + 0.2
							end
						end
					end
				end

			end

		end
	end
	hook.Add("Think", "Wire_DebuggerThink", Wire_DebuggerThink)

end


if (CLIENT) then

	local dbg_line_count = 0
	local dbg_lines = {}
	local dgb_orient_vert = false
	local BoxWidth = 300
	local LastBoxUpdate = CurTime()-5

	local function DebuggerDrawHUD()
		local dbginfo = ""
		if (dbg_line_count <= 0) then return end

		--setup the font
		surface.SetFont("Default")

		--buid the table of entries
		local Entry_Count = dbg_line_count
		local Line_Count = 0
		local ColorType = 0
		local Entries = {}
		for i = 1,dbg_line_count do
			local Line = dbg_lines[i]
			if(Line) then
				local CurEntry = {}
				CurEntry.Lines = {}

				local ExplodeLines = string.Explode("\n", Line)

				for Index, ExplodeLine in ipairs(ExplodeLines) do --break it into multible lines for 1 entry
					if(string.Trim(ExplodeLine) != "") then

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
		end



		--determine the box width every second
		if(LastBoxUpdate < CurTime()-1) then
			local LongestWidth = 0
			local TextWidth, TextHeight
			for EntryIndex, Entry in ipairs(Entries) do
				for LineIndex, Line in ipairs(Entry.Lines) do
					TextWidth, TextHeight = surface.GetTextSize(string.Trim(Line.LineText))
					TextWidth = TextWidth+Line.OffsetPos[1] --offset it with the text's offset

					if(TextWidth > LongestWidth) then
						LongestWidth = TextWidth
					end
				end
			end
			BoxWidth = LongestWidth+16
			LastBoxUpdate = CurTime()
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
		draw.RoundedBox(8, 2, 2+143*MoveBox, BoxWidth, Line_Count*14+16, Color(50, 50, 50, 128))

		--step through all of the entries and their text to print them
		for EntryIndex, Entry in ipairs(Entries) do
			for LineIndex, Line in ipairs(Entry.Lines) do
				draw.Text({
					text = string.Trim(Line.LineText) or "",
					font = "Default",
					pos = { Line.OffsetPos[1]+10, 143*MoveBox+10+Line.OffsetPos[2] },
					color = Entry.TextColor
					})

			end
		end

	end
	hook.Add("HUDPaint", "DebuggerDrawHUD", DebuggerDrawHUD)

	net.Receive("WireDbgCount", function(len)
		dbg_line_count = net.ReadUInt(16)
	end)
	net.Receive("WireDbg", function(len)
		dgb_orient_vert = net.ReadBit() != 0
		dbg_lines[net.ReadUInt(16)] = net.ReadString()
	end)
	
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_debugger.name", Description = "#Tool.wire_debugger.desc" })

	panel:AddControl("CheckBox", {
			Label = "#Tool_wire_debugger_showports",
			Command = "wire_debugger_showports"
		})

	panel:AddControl("CheckBox", {
			Label = "#Tool_wire_debugger_orientvertical",
			Command = "wire_debugger_orientvertical"
		})

end
