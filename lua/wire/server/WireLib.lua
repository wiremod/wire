-- $Rev: 1753 $
-- $LastChangedDate: 2009-09-29 18:34:43 -0700 (Tue, 29 Sep 2009) $
-- $LastChangedBy: TomyLobo $

-- Compatibility Global
WireAddon = 1


function WireLib.PortComparator(a,b)
	return a.Num < b.Num
end


local Inputs = {}
local Outputs = {}
local CurLink = {}

hook.Add("Think", "WireLib_Think", function()
	for idx, output in pairs(Outputs) do
		output.TriggerLimit = 4
	end
end)

-- helper function that pcalls an input
function WireLib.TriggerInput(ent, name, value, ...)
	ent.Inputs[name].Value = value
	if not ent.TriggerInput then return end
	local ok, ret = pcall(ent.TriggerInput, ent, name, value, ...)
	if not ok then
		local message = string.format("Wire error (%s): %s", tostring(ent), ret)
		ErrorNoHalt(message .. "\n")
		local ply = E2Lib and E2Lib.getOwner and E2Lib.getOwner(ent)
		if ValidEntity(ply) then WireLib.ClientError(message, ply) end
	end
end

function Wire_CreateInputs(ent, names)
	local ent_Inputs = {}
	ent.Inputs = ent_Inputs
	for n,v in pairs(names) do
		-- Allow to specify the type in square brackets, like "Name [TYPE]"
		local name, tp = v:match("^(.+) %[(.+)%]$")
		if not name then
			name = v
			tp = "NORMAL"
		end

		local input = {
			Entity = ent,
			Name = name,
			Value = 0,
			Type = tp,
			Material = "tripmine_laser",
			Color = Color(255, 255, 255, 255),
			Width = 1,
			Num = n,
		}

		local idx = 1
		while (Inputs[idx]) do
			idx = idx+1
		end
		input.Idx = idx

		ent_Inputs[name] = input
		Inputs[idx] = input
	end

	Wire_SetPathNames(ent, names)
	WireLib._SetInputs(ent)

	return ent_Inputs
end


function Wire_CreateOutputs(ent, names, desc)
	local ent_Outputs = {}
	ent.Outputs = ent_Outputs
	for n,v in pairs(names) do
		-- Allow to specify the type in square brackets, like "Name [TYPE]"
		local name, tp = v:match("^(.+) %[(.+)%]$")
		if not name then
			name = v
			tp = "NORMAL"
		end

		local output = {
			Entity = ent,
			Name = name,
			Value = 0,
			Type = tp,
			Connected = {},
			TriggerLimit = 8,
			Num = n,
			Desc = desc and desc[n],
		}

		local idx = 1
		while (Outputs[idx]) do
			idx = idx+1
		end
		output.Idx = idx

		ent_Outputs[name] = output
		Outputs[idx] = output
	end

	WireLib._SetOutputs(ent)

	return ent_Outputs
end


function Wire_AdjustInputs(ent, names)
	local ent_Inputs = ent.Inputs
	for n,v in pairs(names) do
		-- Allow to specify the type in square brackets, like "Name [TYPE]"
		local name, tp = v:match("^(.+) %[(.+)%]$")
		if not name then
			name = v
			tp = "NORMAL"
		end

		if (ent_Inputs[name]) then
			ent_Inputs[name].Keep = true
			ent_Inputs[name].Num = n
		else
			local input = {
				Entity = ent,
				Name = name,
				Value = 0,
				Type = "NORMAL",
				Material = "tripmine_laser",
				Color = Color(255, 255, 255, 255),
				Width = 1,
				Keep = true,
				Num = n,
			}

			local idx = 1
			while (Inputs[idx]) do
				idx = idx+1
			end
			input.Idx = idx

			ent_Inputs[name] = input
			Inputs[idx] = input
		end
	end

	for portname,port in pairs(ent_Inputs) do
		if (port.Keep) then
			port.Keep = nil
		else
			Wire_Link_Clear(ent, portname)

			ent_Inputs[portname] = nil
		end
	end

	Wire_SetPathNames(ent, names)
	WireLib._SetInputs(ent)
end


function Wire_AdjustOutputs(ent, names, desc)
	local ent_Outputs = ent.Outputs
	for n,v in pairs(names) do
		-- Allow to specify the type in square brackets, like "Name [TYPE]"
		local name, tp = v:match("^(.+) %[(.+)%]$")
		if not name then
			name = v
			tp = "NORMAL"
		end

		if (ent_Outputs[name]) then
			ent_Outputs[name].Keep = true
			ent_Outputs[name].Num = n
			if (desc) and (desc[n]) then
				ent_Outputs[name].Desc = desc[n]
			end
		else
			local output = {
				Keep = true,
				Name = name,
				Value = 0,
				Type = "NORMAL",
				Connected = {},
				TriggerLimit = 8,
				Num = n,
			}

			if (desc) and (desc[n]) then
				output.Desc = desc[n]
			end

			local idx = 1
			while (Outputs[idx]) do
				idx = idx+1
			end
			output.Idx = idx

			ent_Outputs[name] = output
			Outputs[idx] = output
		end
	end

	for portname,port in pairs(ent_Outputs) do
		if (port.Keep) then
			port.Keep = nil
		else
			-- fix by Syranide: unlinks wires of removed outputs
			for i,port in ipairs(port.Connected) do
				if (port.Entity:IsValid()) then
					Wire_Link_Clear(port.Entity, port.Name)
				end
			end
			ent_Outputs[portname] = nil
		end
	end

	WireLib._SetOutputs(ent)
end


-- and array of data types
WireLib.DT = {
	NORMAL = {
		Zero = 0
	},	-- Numbers
	VECTOR = {
		Zero = Vector(0, 0, 0)
	},
	ANGLE = {
		Zero = Angle(0, 0, 0)
	},
	COLOR = {
		Zero = Color(0, 0, 0)
	},
	ENTITY = {
		Zero = NULL
	},
	STRING = {
		Zero = ""
	},
	TABLE = {
		Zero = {}
	},
	BIDIRTABLE = {
		Zero = {},
		BiDir = true
	},
	ANY = {
		Zero = 0
	},
	HOVERDATAPORT = {
		Zero = 0
	},
	ARRAY = {
		Zero = {}
	},
	BIDIRARRAY = {
		Zero = {},
		BiDir = true
	},
}

function WireLib.CreateSpecialInputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local ent_Inputs = {}
	ent.Inputs = ent_Inputs
	for n,v in pairs(names) do
		local input = {
			Entity = ent,
			Name = v,
			Desc = desc[n],
			Type = types[n] or "NORMAL",
			Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
			Material = "tripmine_laser",
			Color = Color(255, 255, 255, 255),
			Width = 1,
			Num = n,
		}

		local idx = 1
		while (Inputs[idx]) do
			idx = idx+1
		end
		input.Idx = idx

		ent_Inputs[v] = input
		Inputs[idx] = input
	end

	WireLib.SetPathNames(ent, names)
	WireLib._SetInputs(ent)

	return ent_Inputs
end


function WireLib.CreateSpecialOutputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local ent_Outputs = {}
	ent.Outputs = ent_Outputs
	for n,v in pairs(names) do
		local output = {
			Entity = ent,
			Name = v,
			Desc = desc[n],
			Type = types[n] or "NORMAL",
			Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
			Connected = {},
			TriggerLimit = 8,
			Num = n,
		}

		local idx = 1
		while (Outputs[idx]) do
			idx = idx+1
		end
		output.Idx = idx

		ent_Outputs[v] = output
		Outputs[idx] = output
	end

	WireLib._SetOutputs(ent)

	return ent_Outputs
end



function WireLib.AdjustSpecialInputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local ent_Inputs = ent.Inputs
	for n,v in ipairs(names) do
		if (ent_Inputs[v]) then
			local newtype = types[n] or "NORMAL"
			if newtype ~= ent_Inputs[v].Type then
				timer.Simple(0, Wire_Link_Clear, ent, v) -- TODO: Think of a non-triggering way to clear a link. But delayed triggering will do for now.
				ent_Inputs[v].Value = WireLib.DT[newtype].Zero
			end
			ent_Inputs[v].Keep = true
			ent_Inputs[v].Num = n
			ent_Inputs[v].Desc = desc[n]
			ent_Inputs[v].Type = newtype
		else
			local input = {
				Entity = ent,
				Name = v,
				Desc = desc[n],
				Type = types[n] or "NORMAL",
				Value = WireLib.DT[ types[n] or "NORMAL" ].Zero,
				Material = "tripmine_laser",
				Color = Color(255, 255, 255, 255),
				Width = 1,
				Keep = true,
				Num = n,
			}

			local idx = 1
			while (Inputs[idx]) do
				idx = idx+1
			end
			input.Idx = idx

			ent_Inputs[v] = input
			Inputs[idx] = input
		end
	end

	for portname,port in pairs(ent_Inputs) do
		if (port.Keep) then
			port.Keep = nil
		else
			Wire_Link_Clear(ent, portname)

			ent_Inputs[portname] = nil
		end
	end

	WireLib.SetPathNames(ent, names)
	WireLib._SetInputs(ent)

	return ent_Inputs
end


function WireLib.AdjustSpecialOutputs(ent, names, types, desc)
	types = types or {}
	desc = desc or {}
	local ent_Outputs = ent.Outputs
	for n,v in ipairs(names) do
		if (ent_Outputs[v]) then
			local newtype = types[n] or "NORMAL"
			if newtype ~= ent_Outputs[v].Type then
				for i,inp in ipairs(ent_Outputs[v].Connected) do
					if (inp.Entity:IsValid()) then
						Wire_Link_Clear(inp.Entity, inp.Name)
					end
				end
			end
			ent_Outputs[v].Keep = true
			ent_Outputs[v].Num = n
			ent_Outputs[v].Desc = desc[n]
			ent_Outputs[v].Type = newtype
		else
			local output = {
				Keep = true,
				Name = v,
				Desc = desc[n],
				Type = types[n] or "NORMAL",
				Value = WireLib.DT[ (types[n] or "NORMAL") ].Zero,
				Connected = {},
				TriggerLimit = 8,
				Num = n,
			}

			local idx = 1
			while (Outputs[idx]) do
				idx = idx+1
			end
			output.Idx = idx

			ent_Outputs[v] = output
			Outputs[idx] = output
		end
	end

	for portname,port in pairs(ent_Outputs) do
		if (port.Keep) then
			port.Keep = nil
		else
			-- fix by Syranide: unlinks wires of removed outputs
			for i,port in ipairs(ent_Outputs[portname].Connected) do
				if (port.Entity:IsValid()) then
					Wire_Link_Clear(port.Entity, port.Name)
				end
			end
			ent_Outputs[portname] = nil
		end
	end

	WireLib._SetOutputs(ent)

	return ent_Outputs
end


function WireLib.RetypeInputs(ent, iname, itype, desc)
	local ent_Inputs = ent.Inputs
	if (!ent_Inputs[iname]) or (!itype) then return end
	ent_Inputs[iname].Desc = desc
	ent_Inputs[iname].Type = itype
	ent_Inputs[iname].Value = WireLib.DT[itype].Zero

	WireLib._SetInputs(ent)
end


function WireLib.RetypeOutputs(ent, oname, otype, desc)
	local ent_Outputs = ent.Outputs
	if (!ent_Outputs[oname]) or (!otype) then return end
	ent_Outputs[oname].Desc = desc
	ent_Outputs[oname].Type = otype
	ent_Outputs[oname].Value = WireLib.DT[otype].Zero

	WireLib._SetOutputs(ent)
end


-- force_outputs is only needed for existing components to allow them to be updated
function Wire_Restored(ent, force_outputs)
	local ent_Inputs = ent.Inputs
	if (ent_Inputs) then
		for name,input in pairs(ent_Inputs) do
			if (not input.Material) then  -- Must be an old save
				input.Name = name

				if (input.Ropes) then
					for _,rope in pairs(input.Ropes) do
						rope:Remove()
					end
					input.Ropes = nil
				end
			end

			input.Entity = ent
			input.Type = input.Type or "NORMAL"
			input.Material = input.Material or "cable/blue_elec"
			input.Color = input.Color or Color(255, 255, 255, 255)
			input.Width = input.Width or 2
			input.StartPos = input.StartPos or Vector(0, 0, 0)
			if (input.Src) and (not input.Path) then
				input.Path = { { Entity = input.Src, Pos = Vector(0, 0, 0) } }
			end

			local idx = 1
			while (Inputs[idx]) do
				idx = idx+1
			end
			input.Idx = idx

			Inputs[idx] = input
		end
	end

	local ent_Outputs = ent.Outputs
	if (ent_Outputs) then
		for _,output in pairs(ent_Outputs) do
			output.Entity = ent
			output.Type = output.Type or "NORMAL"

			local idx = 1
			while (Outputs[idx]) do
				idx = idx+1
			end
			output.Idx = idx

			Outputs[idx] = output
		end
	elseif (force_outputs) then
		ent.Outputs = Wire_CreateOutputs(ent, force_outputs)
	end
end


function Wire_Remove(ent)
	local ent_Inputs = ent.Inputs
	if (ent_Inputs) then
		for _,input in pairs(ent_Inputs) do
			if (input.Src) and (input.Src:IsValid()) then
				local output = input.Src.Outputs[input.SrcId]
				if (output) then
					for k,v in ipairs(output.Connected) do
						if (v.Entity == dst) and (v.Name == dstid) then
							table.remove(output.Connected, k)
							break
						end
					end
				end
			end

			Inputs[input.Idx] = nil
		end
	end

	local ent_Outputs = ent.Outputs
	if (ent_Outputs) then
		for _,output in pairs(ent_Outputs) do
			for _,v in ipairs(output.Connected) do
				if (v.Entity:IsValid()) then
					local input = v.Entity.Inputs[v.Name]
					local zero = WireLib.DT[input.Type].Zero

					WireLib.TriggerInput(v.Entity, v.Name, zero)
					-- disable for beamlib
					Wire_Link_Clear(v.Entity, v.Name)
				end
			end

			Outputs[output.Idx] = nil
		end
	end
end


local function Wire_Link(dst, dstid, src, srcid, path)
	if (not dst) or (not dst.Inputs) or (not dst.Inputs[dstid]) then
		Msg("Wire_link: Invalid destination!\n")
		return
	end
	if (not src) or (not src.Outputs) or (not src.Outputs[srcid]) then
		Msg("Wire_link: Invalid source!\n")
		return
	end

	local input = dst.Inputs[dstid]
	local output = src.Outputs[srcid]

	if (input.Src) and (input.Src:IsValid()) then
		if (input.Src.Outputs) then
			local oldOutput = input.Src.Outputs[input.SrcId]
			if (oldOutput) then
				for k,v in ipairs(oldOutput.Connected) do
					if (v.Entity == dst) and (v.Name == dstid) then
						table.remove(oldOutput.Connected, k)
					end
				end
			end
		end
	end

	input.Src = src
	input.SrcId = srcid
	input.Path = path

	WireLib._SetLink(input)

	table.insert(output.Connected, { Entity = dst, Name = dstid })

	if dst.OnInputWireLink then
		-- ENT:OnInputWireLink(iName, iType, oEnt, oName, oType)
		dst:OnInputWireLink(dstid, input.Type, src, srcid, output.Type)
	end

	if src.OnOutputWireLink then
		-- ENT:OnOutputWireLink(oName, oType, iEnt, iName, iType)
		src:OnOutputWireLink(srcid, output.Type, dst, dstid, input.Type)
	end

	WireLib.TriggerInput(dst, dstid, output.Value)
end

function Wire_TriggerOutput(ent, oname, value, iter)
	if (not ent) or (not ent:IsValid()) or (not ent.Outputs) or (not ent.Outputs[oname]) then return end

	local output = ent.Outputs[oname]
	if (output) and (value ~= output.Value or output.Type == "ARRAY" or output.Type == "TABLE") then
		if (output.TriggerLimit <= 0) then return end
		output.TriggerLimit = output.TriggerLimit - 1

		output.Value = value

		if (iter) then
			for _,dst in ipairs(output.Connected) do
				if (dst.Entity:IsValid()) then
					iter:Add(dst.Entity, dst.Name, value)
				end
			end
			return
		end

		iter = Wire_CreateOutputIterator()

		for _,dst in ipairs(output.Connected) do
			if (dst.Entity:IsValid()) then
				WireLib.TriggerInput(dst.Entity, dst.Name, value, iter)
			end
		end

		iter:Process()
	end
end

local function Wire_Unlink(ent, iname)
	local input = ent.Inputs[iname]
	if (input) then
		if (input.Src) and (input.Src:IsValid()) then
			local output = input.Src.Outputs[input.SrcId]
			if (output) then
				for k,v in ipairs(output.Connected) do
					if (v.Entity == ent) and (v.Name == iname) then
						table.remove(output.Connected, k)
					end
				end
				-- untested
				if input.Src.OnOutputWireLink then
					-- ENT:OnOutputWireLink(oName, oType, iEnt, iName, iType)
					input.Src:OnOutputWireLink(input.SrcId, input.Src.Outputs[input.SrcId].Type, ent, iname, input.Type)
				end
			end
			-- untested
			if ent.OnInputWireUnlink then
				-- ENT:OnInputWireUnlink(iName, iType, oEnt, oName, oType)
				ent:OnInputWireUnlink(iname, input.Type, input.Src, input.SrcId, input.Src.Outputs[input.SrcId].Type)
			end
		end

		input.Src = nil
		input.SrcId = nil
		input.Path = nil

		WireLib.TriggerInput(ent, iname, WireLib.DT[input.Type].Zero)

		WireLib._SetLink(input)
	end
end

function Wire_Link_Start(idx, ent, pos, iname, material, color, width)
	if (not ent) or (not ent:IsValid()) or (not ent.Inputs) or (not ent.Inputs[iname]) then return end

	local input = ent.Inputs[iname]

	CurLink[idx] = {
		Dst = ent,
		DstId = iname,
		Path = {},
		OldPath = input.Path,
		}

	CurLink[idx].OldPath             = CurLink[idx].OldPath or {}
	CurLink[idx].OldPath[0]          = {}
	CurLink[idx].OldPath[0].pos      = input.StartPos
	CurLink[idx].OldPath[0].material = input.Material
	CurLink[idx].OldPath[0].color    = input.Color
	CurLink[idx].OldPath[0].width    = input.Width

	local net_name = "wp_" .. iname
	ent:SetNetworkedBeamInt(net_name, 0)
	ent:SetNetworkedBeamVector(net_name .. "_start", pos)
	ent:SetNetworkedBeamString(net_name .. "_mat", material)
	ent:SetNetworkedBeamVector(net_name .. "_col", Vector(color.r, color.g, color.b))
	ent:SetNetworkedBeamFloat(net_name .. "_width", width)

	--RDbeamlib.StartWireBeam( ent, iname, pos, material, color, width )

	input.StartPos = pos
	input.Material = material
	input.Color = color
	input.Width = width

	return true
end


function Wire_Link_Node(idx, ent, pos)
	if not CurLink[idx] then return end
	if not CurLink[idx].Dst then return end
	if not ent:IsValid() then return end -- its the world, give up

	local net_name = "wp_" .. CurLink[idx].DstId
	local node_idx = CurLink[idx].Dst:GetNetworkedBeamInt(net_name)+1
	CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. node_idx .. "_ent", ent)
	CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. node_idx .. "_pos", pos)
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, node_idx)

	--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, ent, pos )

	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })
end


function Wire_Link_End(idx, ent, pos, oname, pl)
	if not CurLink[idx] then return end
	if not CurLink[idx].Dst then return end
	if not ent.Outputs then return end

	if (CurLink[idx].Dst:GetClass() == "gmod_wire_sensor") and (ent:GetClass() != "gmod_wire_target_finder") then
		MsgN("Wire_link: Beacon Sensor can only be wired to a Target Finder!")
		if pl then
			WireLib.AddNotify(pl, "Beacon Sensor can only be wired to a Target Finder!", NOTIFY_GENERIC, 7)
		end
		Wire_Link_Cancel(idx)
		return
	end

	local input = CurLink[idx].Dst.Inputs[CurLink[idx].DstId]
	local output = ent.Outputs[oname]
	if not output then
		--output = { Type = "NORMAL" }
		local text = "Selected output not found or no output present."
		MsgN(text)
		if pl then WireLib.AddNotify(pl, text, NOTIFY_GENERIC, 7) end
		Wire_Link_Cancel(idx)
		return
	end
	--Msg("input type= " .. input.Type .. "  output type= " .. (output.Type or "NIL") .. "\n")	-- I bet that was getting anoying (TAD2020)
	if (input.Type != output.Type) and (input.Type != "ANY") and (output.Type != "ANY") then
		local text = "Data Type Mismatch! Input takes "..input.Type.." and Output gives "..output.Type
		MsgN(text)
		if pl then WireLib.AddNotify(pl, text, NOTIFY_GENERIC, 7) end
		Wire_Link_Cancel(idx)
		return
	end

	local net_name = "wp_" .. CurLink[idx].DstId
	local node_idx = CurLink[idx].Dst:GetNetworkedBeamInt(net_name)+1
	CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. node_idx .. "_ent", ent)
	CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. node_idx .. "_pos", pos)
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, node_idx)

	--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, ent, pos )

	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })

	Wire_Link(CurLink[idx].Dst, CurLink[idx].DstId, ent, oname, CurLink[idx].Path)

	if (WireLib.DT[input.Type].BiDir) then
		Wire_Link(ent, oname, CurLink[idx].Dst, CurLink[idx].DstId, {})
	end

	CurLink[idx] = nil
end


function Wire_Link_Cancel(idx)
	if not CurLink[idx] then return end
	if not CurLink[idx].Dst then return end

	--local orig = CurLink[idx].OldPath[0]
	--RDbeamlib.StartWireBeam( CurLink[idx].Dst, CurLink[idx].DstId, orig.pos, orig.material, orig.color, orig.width )

	local path_len = 0
	if (CurLink[idx].OldPath) then path_len = #CurLink[idx].OldPath end

	local net_name = "wp_" .. CurLink[idx].DstId
	for i=1,path_len do
		CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. i, CurLink[idx].OldPath[i].Entity)
		CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. i, CurLink[idx].OldPath[i].Pos)
		--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, CurLink[idx].OldPath[i].Entity, CurLink[idx].OldPath[i].Pos )
	end
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, path_len)

	CurLink[idx] = nil
end


function Wire_Link_Clear(ent, iname)
	local net_name = "wp_" .. iname
	ent:SetNetworkedBeamInt(net_name, 0)
	--RDbeamlib.ClearWireBeam( ent, iname )

	Wire_Unlink(ent, iname)
end

function Wire_SetPathNames(ent, names)
	for k,v in pairs(names) do
		ent:SetNetworkedBeamString("wpn_" .. k, v)
	end
	ent:SetNetworkedBeamInt("wpn_count", #names)
end

do -- class OutputIterator
	local OutputIterator = {}
	OutputIterator.__index = OutputIterator

	function OutputIterator:Add(ent, iname, value)
		table.insert(self, { Entity = ent, IName = iname, Value = value })
	end

	function OutputIterator:Process()
		if self.Processing then return end -- should not occur
		self.Processing = true

		while #self > 0 do
			local nextelement = self[1]
			table.remove(self, 1)

			WireLib.TriggerInput(nextelement.Entity, nextelement.IName, nextelement.Value, self)
		end

		self.Processing = nil
	end

	function Wire_CreateOutputIterator()
		return setmetatable({}, OutputIterator)
	end
end -- class OutputIterator


duplicator.RegisterEntityModifier("WireDupeInfo", function(ply, Ent, DupeInfo)
	-- this does nothing for now, we need the blank function to get the duplicator to copy the WireDupeInfo into the pasted ent
end)


-- used for welding wired stuff, if trace is world, the ent is not welded and is frozen instead
function WireLib.Weld(ent, traceEntity, tracePhysicsBone, DOR, collision, AllowWorldWeld)
	if (!ent or !traceEntity or traceEntity:IsNPC() or traceEntity:IsPlayer()) then return end
	local phys = ent:GetPhysicsObject()
	if ( traceEntity:IsValid() ) or ( traceEntity:IsWorld() and AllowWorldWeld ) then
		local const = constraint.Weld( ent, traceEntity, 0, tracePhysicsBone, 0, (not collision), DOR )
		-- Don't disable collision if it's not attached to anything
		if (!collision) then
			if phys:IsValid() then phys:EnableCollisions( false ) end
			ent.nocollide = true
		end
		return const
	else
		if phys:IsValid() then ent:GetPhysicsObject():EnableMotion( false ) end
		return nil
	end
end


function WireLib.BuildDupeInfo( Ent )
	if (not Ent.Inputs) then return end

	local info = { Wires = {} }
	for portname,input in pairs(Ent.Inputs) do
		if (input.Src) and (input.Src:IsValid()) then
			info.Wires[portname] = {
				StartPos = input.StartPos,
				Material = input.Material,
				Color = input.Color,
				Width = input.Width,
				Src = input.Src:EntIndex(),
				SrcId = input.SrcId,
				SrcPos = Vector(0, 0, 0),
			}

			if (input.Path) then
				info.Wires[portname].Path = {}

				for _,v in ipairs(input.Path) do
					if (v.Entity) and (v.Entity:IsValid()) then
						table.insert(info.Wires[portname].Path, { Entity = v.Entity:EntIndex(), Pos = v.Pos })
					end
				end

				local n = #info.Wires[portname].Path
				if (n > 0) and (info.Wires[portname].Path[n].Entity == info.Wires[portname].Src) then
					info.Wires[portname].SrcPos = info.Wires[portname].Path[n].Pos
					table.remove(info.Wires[portname].Path, n)
				end
			end
		end
	end

	return info
end

function WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
	if (info.Wires) then
		for k,input in pairs(info.Wires) do

			Wire_Link_Start(ply:UniqueID(), ent, input.StartPos, k, input.Material, input.Color, input.Width)

			if (input.Path) then
				for _,v in ipairs(input.Path) do

					local ent2 = GetEntByID(v.Entity)
					if (!ent2) or (!ent2:IsValid()) then
						local EntityList = GetEntByID("EntityList")
						if (!EntityList) or (!EntityList[v.Entity]) then
							ent2 = ents.GetByIndex(v.Entity)
						end
					end
					if (ent2) or (ent2:IsValid()) then
						Wire_Link_Node(ply:UniqueID(), ent2, v.Pos)
					else
						Msg("ApplyDupeInfo: Error, Could not find the entity for wire path\n")
					end
				end
			end

			local ent2 = GetEntByID(input.Src)
			if (!ent2) or (!ent2:IsValid()) then
				local EntityList = GetEntByID("EntityList")
				if (!EntityList) or (!EntityList[input.Src]) then
					ent2 = ents.GetByIndex(input.Src)
				end
			end
			if (ent2) or (ent2:IsValid()) then
				Wire_Link_End(ply:UniqueID(), ent2, input.SrcPos, input.SrcId)
			else
				Msg("ApplyDupeInfo: Error, Could not find the output entity\n")
			end
		end
	end
end



WireLib.CreateInputs			= Wire_CreateInputs
WireLib.CreateOutputs			= Wire_CreateOutputs
WireLib.AdjustInputs			= Wire_AdjustInputs
WireLib.AdjustOutputs			= Wire_AdjustOutputs
WireLib.Restored				= Wire_Restored
WireLib.Remove					= Wire_Remove
WireLib.TriggerOutput			= Wire_TriggerOutput
WireLib.Link_Start				= Wire_Link_Start
WireLib.Link_Node				= Wire_Link_Node
WireLib.Link_End				= Wire_Link_End
WireLib.Link_Cancel				= Wire_Link_Cancel
WireLib.Link_Clear				= Wire_Link_Clear
WireLib.SetPathNames			= Wire_SetPathNames
WireLib.CreateOutputIterator	= Wire_CreateOutputIterator
Wire_BuildDupeInfo				= WireLib.BuildDupeInfo
Wire_ApplyDupeInfo				= WireLib.ApplyDupeInfo

--backwards logic: set enable to false to show show values on gates instead
Wire_EnableGateInputValues = true
local function WireEnableInputValues(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_EnableGateInputValues = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_EnableGateInputValues = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_EnableGateInputValues = "..tostring(Wire_EnableGateInputValues).."\n")
end
concommand.Add( "Wire_EnableGateInputValues", WireEnableInputValues )

Wire_FastOverlayTextUpdate = false
local function WireFastOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_FastOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_FastOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_FastOverlayTextUpdate = "..tostring(Wire_FastOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_FastOverlayTextUpdate", WireFastOverlayTextUpdate )

Wire_SlowerOverlayTextUpdate = false
local function WireSlowerOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_SlowerOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_SlowerOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_SlowerOverlayTextUpdate = "..tostring(Wire_SlowerOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_SlowerOverlayTextUpdate", WireSlowerOverlayTextUpdate )

Wire_DisableOverlayTextUpdate = false
local function WireDisableOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_DisableOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_DisableOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_DisableOverlayTextUpdate = "..tostring(Wire_DisableOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_DisableOverlayTextUpdate", WireDisableOverlayTextUpdate )

Wire_ForceDelayOverlayTextUpdate = false
local function WireForceDelayOverlayTextUpdate(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_ForceDelayOverlayTextUpdate = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_ForceDelayOverlayTextUpdate = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_ForceDelayOverlayTextUpdate = "..tostring(Wire_ForceDelayOverlayTextUpdate).."\n")
end
concommand.Add( "Wire_ForceDelayOverlayTextUpdate", WireForceDelayOverlayTextUpdate )


--[[Wire_UseOldGateOutputLables = false
local function WireUseOldGateOutputLables(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then
			Wire_UseOldGateOutputLables = true
		elseif args[1] == "0" or args[1] == 0 then
			Wire_UseOldGateOutputLables = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\nWire_UseOldGateOutputLables = "..tostring(Wire_UseOldGateOutputLables).."\n")
end
concommand.Add( "Wire_UseOldGateOutputLables", WireUseOldGateOutputLables )]]



-- add wiresvn tag

-- add wiresvn_rev tag (doesn't work like it should)
--RunConsoleCommand("sv_tags", (GetConVarString("sv_tags") or "")..",wiresvn"..WireVersion)

-- this still doesn't quiet work like it looks like it should, must be some issues with setting sv_tags (long tags, similar tags might be ignored/removed while duplicates might get though)

local tags = string.Explode(",", GetConVarString("sv_tags") or "")
-- remove old tags
for i = #tags,1,-1 do
	local tag = tags[i]
	if tag:find("wiresvn") then table.remove(tags,i) end
	if tag == "e2_restricted" then table.remove(tags,i) end
end

-- insert new ones
table.insert(tags, "wiresvn")
if SVNver then
	table.insert(tags, "wiresvn" .. SVNver)
end

-- sort and update tags
table.sort(tags)
RunConsoleCommand("sv_tags", table.concat(tags, ","))

-- prevent applyForce+Anti-noclip-based killing contraptions
hook.Add("InitPostEntity", "antiantinoclip", function()
	local ENT = scripted_ents.GetList().rt_antinoclip_handler
	if not ENT then return end
	ENT = ENT.t

	local rt_antinoclip_handler_StartTouch = ENT.StartTouch
	function ENT:StartTouch(...)
		if self.speed >= 20 then return end

		local phys = self.Ent:GetPhysicsObject()
		if phys:IsValid() and phys:GetAngleVelocity():Length() > 20 then return end

		rt_antinoclip_handler_StartTouch(self, ...)
	end

	--local rt_antinoclip_handler_Think = ENT.Think
	function ENT:Think()

		local t = CurTime()
		local dt = t-self.lastt
		self.lastt = t

		local phys = self.Ent:GetPhysicsObject()
		local pos
		if phys:IsValid() then
			pos = phys:LocalToWorld(phys:GetMassCenter())
		else
			pos = self.Ent:GetPos()
		end
		self.speed = pos:Distance(self.oldpos)/dt
		self.oldpos = pos
		--rt_antinoclip_handler_Think(self, ...)
	end

	ENT.speed = 20
	ENT.lastt = 0
	ENT.oldpos = Vector(0,0,0)
end)

-- Calls "func", once (Advanced) Duplicator has finished spawning the entity that was copied with the entity id "entid".
-- Must be called from an duplicator.RegisterEntityClass or duplicator.RegisterEntityModifier handler.
-- Usage: WireLib.PostDupe(entid, function(ent) ... end)
function WireLib.PostDupe(entid, func)
	local CreatedEntities

	local paste_functions = {
		[duplicator.Paste] = true,
		[AdvDupe.Paste] = true,
		[AdvDupe.OverTimePasteProcess] = true,
	}

	-- Go through the call stack to find someone who has a CreatedEntities table for us.
	local i,info = 1,debug.getinfo(1)
	while info do
		if paste_functions[info.func] then
			for j = 1,20 do
				local name, value = debug.getlocal(i, j)
				if name == "CreatedEntities" then
					CreatedEntities = value
					break
				end
			end
			break
		end
		i = i+1
		info = debug.getinfo(i)
	end

	-- Nothing found? Too bad...
	if not CreatedEntities then return end

	-- Wait until the selected entity has been spawned...
	local unique = {}
	timer.Create(unique, 1, 240, function(CreatedEntities, entid, unique, func)
		local ent = CreatedEntities[entid]
		if ent then
			timer.Remove(unique)

			-- and call the callback
			func(ent)
		end
	end, CreatedEntities, entid, unique, func)
end

function WireLib.dummytrace(ent)
	local pos = ent:GetPos()
	return {
		FractionLeftSolid = 0,
		HitNonWorld       = true,
		Fraction          = 0,
		Entity            = ent,
		HitPos            = pos,
		HitNormal         = Vector(0,0,0),
		HitBox            = 0,
		Normal            = Vector(1,0,0),
		Hit               = true,
		HitGroup          = 0,
		MatType           = 0,
		StartPos          = pos,
		PhysicsBone       = 0,
		WorldToLocal      = Vector(0,0,0),
	}
end
