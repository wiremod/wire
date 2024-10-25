-- Compatibility Global

if not WireLib then return end

WireAddon = 1

local ents = ents
local timer = timer
local string = string
local math_clamp = math.Clamp
local table = table
local hook = hook
local concommand = concommand
local Msg = Msg
local MsgN = MsgN
local pairs = pairs
local ipairs = ipairs
local IsValid = IsValid
local tostring = tostring
local Vector = Vector
local Color = Color

local isvector, isnumber, istable, isstring, isangle, IsEntity, IsColor = isvector, isnumber, istable, isstring, isangle, IsEntity, IsColor

local HasPorts = WireLib.HasPorts -- Very important for checks!
local entIsValid = FindMetaTable("Entity").IsValid
local entGetTable = FindMetaTable("Entity").GetTable

function WireLib.PortComparator(a,b)
	return a.Num < b.Num
end

-- Allow to specify the description and type, like "Name (Description) [TYPE]"
local function ParsePortName(namedesctype, fbtype, fbdesc)
	local namedesc, tp = namedesctype:match("^(.+) %[(.+)%]$")
	if not namedesc then
		namedesc = namedesctype
		tp = fbtype
	end

	local name, desc = namedesc:match("^(.+) %((.*)%)$")
	if not name then
		name = namedesc
		desc = fbdesc
	end
	return name, desc, tp
end

local Inputs = {}
local Outputs = {}
local CurLink = {}
local CurTime = CurTime

-- helper function that pcalls an input
function WireLib.TriggerInput(ent, name, value, ...)
	if not entIsValid(ent) or not HasPorts(ent) then return end

	local entTbl = entGetTable(ent)
	local inputs = entTbl.Inputs

	if not inputs then return end

	local input = inputs[name]
	if not input then return end

	local ty = WireLib.DT[input.Type]
	if ty and not ty.Validator(value) then
		-- Not copying here is fine since data types are immutable outside E2.
		value = ty.Zero()
	end

	input.Value = value
	local triggerInput = entTbl.TriggerInput
	if not triggerInput then return end

	-- Limit inputs the same way outputs are limited.
	-- This is in case a wire input would somehow trigger itself and stack overflow.
	-- Notably this happens with E2 (postexecute hook), but adding this here in case other wire components do it in the future.
	local now = CurTime()
	if input.TriggerTime ~= now then
		input.TriggerTime = now
		input.TriggerLimit = 8
	elseif input.TriggerLimit <= 0 then
		return
	else
		input.TriggerLimit = input.TriggerLimit - 1
	end

	local ok, ret = xpcall(triggerInput, debug.traceback, ent, name, value, ...)
	if not ok then
		local ply = WireLib.GetOwner(ent)
		local validPly = IsValid(ply)
		local owner_msg = validPly and (" by %s"):format(tostring(ply)) or ""
		local message = ("Wire error (%s%s):\n%s\n"):format(tostring(ent), owner_msg, ret)
		WireLib.ErrorNoHalt(message)
		if validPly then WireLib.ClientError(message, ply) end
	end
end

--- Array of data types for Wiremod.
---@type table<string, { Zero: (fun(): any), Validator: (fun(val: any): boolean) }>
WireLib.DT = {
	NORMAL = {
		Zero = function()
			return 0
		end,
		Validator = isnumber
	},	-- Numbers
	VECTOR = {
		Zero = Vector,
		Validator = isvector
	},
	VECTOR2 = {
		Zero = function()
			return { 0, 0 }
		end,
		Validator = function(v2)
			return istable(v2)
				and isnumber(v2[1])
				and isnumber(v2[2])
		end
	},
	VECTOR4 = {
		Zero = function()
			return { 0, 0, 0, 0 }
		end,
		Validator = function(v4)
			return istable(v4)
				and isnumber(v4[1])
				and isnumber(v4[2])
				and isnumber(v4[3])
				and isnumber(v4[4])
		end
	},
	ANGLE = {
		Zero = Angle,
		Validator = isangle
	},
	COLOR = {
		Zero = function()
			return Color(0, 0, 0)
		end,
		Validator = IsColor
	},
	ENTITY = {
		Zero = function()
			return NULL
		end,
		Validator = IsEntity
	},
	STRING = {
		Zero = function()
			return ""
		end,
		Validator = isstring
	},
	TABLE = {
		Zero = function()
			return { n = {}, ntypes = {}, s = {}, stypes = {}, size = 0 }
		end,
		Validator = function(t)
			return istable(t)
				and istable(t.n)
				and istable(t.ntypes)
				and istable(t.s)
				and istable(t.stypes)
				and isnumber(t.size)
		end
	},
	BIDIRTABLE = {
		Zero = function()
			return { n = {}, ntypes = {}, s = {}, stypes = {}, size = 0 }
		end,
		Validator = function(t)
			return istable(t)
				and istable(t.n)
				and istable(t.ntypes)
				and istable(t.s)
				and istable(t.stypes)
				and isnumber(t.size)
		end,
		BiDir = true
	},
	ANY = {
		Zero = function()
			return 0
		end,
		Validator = function()
			return true
		end
	},
	ARRAY = {
		Zero = function()
			return {}
		end,
		Validator = istable
	},
	BIDIRARRAY = {
		Zero = function()
			return {}
		end,
		Validator = istable,
		BiDir = true
	},
}

--- Gets default value of a WireLib type.
--- Assumes `type` is a valid string type in the WireLib.DT table.
--- For example `VECTOR` / `NORMAL` / `ARRAY`
---@param type string
function WireLib.GetDefaultForType(type)
	return WireLib.DT[type].Zero()
end

function WireLib.CreateSpecialInputs(ent, names, types, descs)
	types = types or {}
	descs = descs or {}
	local ent_ports = {}
	ent.Inputs = ent_ports
	for n,v in pairs(names) do
		local name, desc, tp = ParsePortName(v, types[n] or "NORMAL", descs and descs[n])

		local port = {
			Entity = ent,
			Name = name,
			Desc = desc,
			Type = tp,
			Value = WireLib.GetDefaultForType(tp),
			Material = "tripmine_laser",
			Color = Color(255, 255, 255, 255),
			Width = 1,
			Num = n,
		}

		local idx = 1
		while (Inputs[idx]) do
			idx = idx+1
		end
		port.Idx = idx

		ent_ports[name] = port
		Inputs[idx] = port
	end

	WireLib._SetInputs(ent)

	return ent_ports
end

function WireLib.CreateSpecialOutputs(ent, names, types, descs)
	types = types or {}
	descs = descs or {}
	local ent_ports = {}
	ent.Outputs = ent_ports
	for n,v in pairs(names) do
		local name, desc, tp = ParsePortName(v, types[n] or "NORMAL", descs and descs[n])

		local port = {
			Entity = ent,
			Name = name,
			Desc = desc,
			Type = tp,
			Value = WireLib.GetDefaultForType(tp),
			Connected = {},
			TriggerLimit = 8,
			Num = n,
		}

		local idx = 1
		while (Outputs[idx]) do
			idx = idx+1
		end
		port.Idx = idx


		ent_ports[name] = port
		Outputs[idx] = port
	end

	WireLib._SetOutputs(ent)

	return ent_ports
end

function WireLib.AdjustSpecialInputs(ent, names, types, descs)
	types = types or {}
	descs = descs or {}
	local ent_ports = ent.Inputs or {}
	for n,v in ipairs(names) do
		local name, desc, tp = ParsePortName(v, types[n] or "NORMAL", descs and descs[n])

		if (ent_ports[name]) then
			if tp ~= ent_ports[name].Type then
				timer.Simple(0, function() WireLib.Link_Clear(ent, name) end)
				ent_ports[name].Value = WireLib.GetDefaultForType(tp)
				ent_ports[name].Type = tp
			end
			ent_ports[name].Keep = true
			ent_ports[name].Num = n
			ent_ports[name].Desc = desc
		else
			local port = {
				Entity = ent,
				Name = name,
				Desc = desc,
				Type = tp,
				Value = WireLib.GetDefaultForType(tp),
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
			port.Idx = idx

			ent_ports[name] = port
			Inputs[idx] = port
		end
	end

	for portname,port in pairs(ent_ports) do
		if (port.Keep) then
			port.Keep = nil
		else
			WireLib.Link_Clear(ent, portname)

			ent_ports[portname] = nil
		end
	end

	WireLib._SetInputs(ent)

	return ent_ports
end


function WireLib.AdjustSpecialOutputs(ent, names, types, descs)
	types = types or {}
	descs = descs or {}

	local ent_ports = ent.Outputs or {}

	local ent_mods = ent.EntityMods
	if ent_mods then
		local n = #names
		if ent_mods.CreateEntityOutput then
			n = n + 1

			names[n] = "entity"
			types[n] = "ENTITY"
		end
		if ent_mods.CreateWirelinkOutput then
			n = n + 1

			names[n] = "wirelink"
			types[n] = "WIRELINK"
		end
	end


	local i = 0
	for n,v in ipairs(names) do
		local name, desc, tp = ParsePortName(v, types[n] or "NORMAL", descs and descs[n])

		if (ent_ports[name]) then
			if tp ~= ent_ports[name].Type then
				WireLib.DisconnectOutput(ent, name)
				ent_ports[name].Type = tp
			end
			WireLib.RemoveOutPort(ent, name)
			ent_ports[name].Keep = true
			ent_ports[name].Desc = desc
		else
			i = i + 1
			local port = {
				Keep = true,
				Name = name,
				Desc = desc,
				Type = tp,
				Value = WireLib.GetDefaultForType(tp),
				Connected = {},
				TriggerLimit = 8,
				Num = i,
			}

			local idx = 1
			while (Outputs[idx]) do
				idx = idx+1
			end
			port.Idx = idx

			ent_ports[name] = port
			Outputs[idx] = port
		end
	end

	for portname,port in pairs(ent_ports) do
		if (port.Keep) then
			port.Keep = nil
		else
			WireLib.DisconnectOutput(ent, portname)
			WireLib.RemoveOutPort(ent, portname)
			ent_ports[portname] = nil
		end
	end

	WireLib._SetOutputs(ent)

	return ent_ports
end

--- Disconnects all wires from the given output.
function WireLib.DisconnectOutput(entity, output_name)
	local output = entity.Outputs[output_name]
	if output == nil then return end
	for _, input in pairs_consume(output.Connected) do
		if IsValid(input.Entity) then
			WireLib.Link_Clear(input.Entity, input.Name)
		end
	end
end

function WireLib.RetypeInputs(ent, iname, itype, descs)
	if not HasPorts(ent) then return end

	local ent_ports = ent.Inputs
	if (not ent_ports[iname]) or (not itype) then return end
	if itype ~= ent_ports[iname].Type then
		WireLib.Link_Clear(ent, iname)
		ent_ports[iname].Type = itype
	end
	ent_ports[iname].Desc = descs
	ent_ports[iname].Value = WireLib.GetDefaultForType(itype)

	WireLib._SetInputs(ent)
end


function WireLib.RetypeOutputs(ent, oname, otype, descs)
	if not HasPorts(ent) then return end

	local ent_ports = ent.Outputs
	if (not ent_ports[oname]) or (not otype) then return end
	if otype ~= ent_ports[oname].Type then
		WireLib.DisconnectOutput(ent, oname)
		ent_ports[oname].Type = otype
	end
	ent_ports[oname].Desc = descs
	ent_ports[oname].Value = WireLib.GetDefaultForType(otype)

	WireLib._SetOutputs(ent)
end


-- force_outputs is only needed for existing components to allow them to be updated
function WireLib.Restored(ent, force_outputs)
	if not HasPorts(ent) then return end

	local ent_ports = ent.Inputs
	if (ent_ports) then
		for name,port in pairs(ent_ports) do
			if (not port.Material) then  -- Must be an old save
				port.Name = name

				if (port.Ropes) then
					for _,rope in pairs(port.Ropes) do
						rope:Remove()
					end
					port.Ropes = nil
				end
			end

			port.Entity = ent
			port.Type = port.Type or "NORMAL"
			port.Material = port.Material or "cable/blue_elec"
			port.Color = port.Color or Color(255, 255, 255, 255)
			port.Width = port.Width or 2
			port.StartPos = port.StartPos or Vector(0, 0, 0)
			if port.Src and (not port.Path) then
				port.Path = { { Entity = port.Src, Pos = Vector(0, 0, 0) } }
			end

			local idx = 1
			while (Inputs[idx]) do
				idx = idx+1
			end
			port.Idx = idx

			Inputs[idx] = port
		end
	end

	local ent_ports = ent.Outputs
	if (ent_ports) then
		for _,port in pairs(ent_ports) do
			port.Entity = ent
			port.Type = port.Type or "NORMAL"

			local idx = 1
			while (Outputs[idx]) do
				idx = idx+1
			end
			port.Idx = idx

			Outputs[idx] = port
		end
	elseif (force_outputs) then
		ent.Outputs = WireLib.CreateOutputs(ent, force_outputs)
	end
end

local function ClearPorts(ports, ConnectEnt, DontSendToCL, Removing)
	local Valid, EmergencyBreak = true, 0

	-- There is a strange bug, not all the links get removed at once.
	-- It works when you run it multiple times.
	while (Valid and (EmergencyBreak < 32)) do
		local newValid = nil

		for k,v in ipairs(ports) do
			local Ent, Name = v.Entity, v.Name
			if (IsValid(Ent) and (not ConnectEnt or (ConnectEnt == Ent))) then
				local ports = Ent.Inputs
				if (ports) then
					local port = ports[Name]
					if (port) then
						WireLib.Link_Clear(Ent, Name, DontSendToCL, Removing)
						newValid = true
					end
				end
			end
		end

		Valid = newValid
		EmergencyBreak = EmergencyBreak + 1 -- Prevents infinite loops if something goes wrong.
	end
end

-- Set DontUnList to true, if you want to call WireLib._RemoveWire(eid) manually.
function WireLib.Remove(ent, DontUnList)
	--Clear the inputs
	local ent_ports = ent.Inputs
	if (ent_ports) then
		for _,inport in pairs(ent_ports) do
			local Source = inport.Src
			if (IsValid(Source)) then
				local Outports = Source.Outputs
				if (Outports) then
					local outport = Outports[inport.SrcId]
					if (outport) then
						ClearPorts(outport.Connected, ent, true, true)
					end
				end
			end
			Inputs[inport.Idx] = nil
		end
	end

	--Clear the outputs
	local ent_ports = ent.Outputs
	if (ent_ports) then
		for _,outport in pairs(ent_ports) do
			ClearPorts(outport.Connected)
			Outputs[outport.Idx] = nil
		end
	end

	ent.Inputs = nil -- Remove the inputs
	ent.Outputs = nil -- Remove the outputs
	ent.IsWire = nil -- Remove the wire mark

	if (DontUnList) then return end -- Set DontUnList to true if you want to remove ent from the list manually.
	WireLib._RemoveWire(ent:EntIndex()) -- Remove entity from the list, so it doesn't count as a wire able entity anymore. Very important for IsWire checks!
end


local function Wire_Link(dst, dstid, src, srcid, path)
	if (not IsValid(dst) or not HasPorts(dst) or not dst.Inputs or not dst.Inputs[dstid]) then
		Msg("Wire_link: Invalid destination!\n")
		return
	end
	if (not IsValid(src) or not HasPorts(src) or not src.Outputs or not src.Outputs[srcid]) then
		Msg("Wire_link: Invalid source!\n")
		return
	end

	local input = dst.Inputs[dstid]
	local output = src.Outputs[srcid]

	if (IsValid(input.Src)) then
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

	WireLib.Paths.Add(input)
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

function WireLib.TriggerOutput(ent, oname, value, iter)
	if not entIsValid(ent) then return end
	if not HasPorts(ent) then return end

	local entTbl = entGetTable(ent)
	if not entTbl.Outputs then return end

	local output = entTbl.Outputs[oname]
	if not output then return end

	local ty = WireLib.DT[output.Type]
	if ty and not ty.Validator(value) then
		-- Not copying here is fine since data types are immutable outside E2.
		value = ty.Zero()
	end

	if value ~= output.Value or output.Type == "ARRAY" or output.Type == "TABLE" or (output.Type == "ENTITY" and not rawequal(value, output.Value) --[[Covers the NULL==NULL case]]) then
		local timeOfFrame = CurTime()
		if timeOfFrame ~= output.TriggerTime then
			-- Reset the TriggerLimit every frame
			output.TriggerLimit = 8
			output.TriggerTime = timeOfFrame
		elseif output.TriggerLimit <= 0 then
			return
		end
		output.TriggerLimit = output.TriggerLimit - 1

		output.Value = value
		local outputConnected = output.Connected

		if iter then
			for _, dst in ipairs(outputConnected) do
				local dstEnt = dst.Entity
				if entIsValid(dstEnt) then
					iter:Add(dstEnt, dst.Name, value)
				end
			end
			return
		end

		iter = WireLib.CreateOutputIterator()

		for _, dst in ipairs(outputConnected) do
			local dstEnt = dst.Entity
			if entIsValid(dstEnt) then
				WireLib.TriggerInput(dstEnt, dst.Name, value, iter)
			end
		end

		iter:Process()
	end
end

local function Wire_Unlink(ent, iname, DontSendToCL, Removing)
	if not HasPorts(ent) then return end

	local input = ent.Inputs[iname]
	if (input) then
		if (IsValid(input.Src)) then
			local outputs = input.Src.Outputs or {}
			local output = outputs[input.SrcId]
			if (output) then
				for k,v in ipairs(output.Connected) do
					if (v.Entity == ent) and (v.Name == iname) then
						table.remove(output.Connected, k)
					end
				end
				-- untested
				if input.Src.OnOutputWireLink then
					-- ENT:OnOutputWireLink(oName, oType, iEnt, iName, iType)
					input.Src:OnOutputWireLink(input.SrcId, outputs[input.SrcId].Type, ent, iname, input.Type)
				end
			end
			-- untested
			if ent.OnInputWireUnlink then
				-- ENT:OnInputWireUnlink(iName, iType, oEnt, oName, oType)
				ent:OnInputWireUnlink(iname, input.Type, input.Src, input.SrcId, outputs[input.SrcId].Type)
			end
		end

		input.Src = nil
		input.SrcId = nil
		input.Path = nil

		if (Removing) then return end
		WireLib.TriggerInput(ent, iname, WireLib.GetDefaultForType(input.Type), nil)

		if (DontSendToCL) then return end
		WireLib._SetLink(input)
	end
end

function WireLib.Link_Start(idx, ent, pos, iname, material, color, width)
	if not IsValid(ent) then return end
	if not HasPorts(ent) then return end
	if (not ent.Inputs or not ent.Inputs[iname]) then return end

	local input = ent.Inputs[iname]

	if not input.Path then input.Path = {} end

	CurLink[idx] = {
		Dst = ent,
		DstId = iname,
		Path = input.Path,
		OldPath = {}
	}
	for i=1, #input.Path do
		CurLink[idx].OldPath[i] = input.Path[i]
		input.Path[i] = nil
	end

	input.StartPos = pos
	input.Material = material
	input.Color = color
	input.Width = math_clamp(width, 0, 5)

	return true
end


function WireLib.Link_Node(idx, ent, pos)
	if not CurLink[idx] then return end
	if not IsValid(CurLink[idx].Dst) then return end
	if not IsValid(ent) then return end -- its the world, give up

	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })
	WireLib.Paths.Add(CurLink[idx].Dst.Inputs[CurLink[idx].DstId])
end


function WireLib.Link_End(idx, ent, pos, oname, pl)
	if not CurLink[idx] then return end

	if not IsValid(CurLink[idx].Dst) then return end
	if not HasPorts(CurLink[idx].Dst) then return end

	if not IsValid(ent) then return end
	if not HasPorts(ent) then return end
	if not ent.Outputs then return end

	if (CurLink[idx].Dst:GetClass() == "gmod_wire_sensor") and (ent:GetClass() ~= "gmod_wire_target_finder") then
		MsgN("Wire_link: Beacon Sensor can only be wired to a Target Finder!")
		if pl then
			WireLib.AddNotify(pl, "Beacon Sensor can only be wired to a Target Finder!", NOTIFY_GENERIC, 7)
		end
		WireLib.Link_Cancel(idx)
		return
	end

	local input = CurLink[idx].Dst.Inputs[CurLink[idx].DstId]
	local output = ent.Outputs[oname]
	if not output then
		--output = { Type = "NORMAL" }
		local text = "Selected output not found or no output present."
		MsgN(text)
		if pl then WireLib.AddNotify(pl, text, NOTIFY_GENERIC, 7) end
		WireLib.Link_Cancel(idx)
		return
	end
	--Msg("input type= " .. input.Type .. "  output type= " .. (output.Type or "NIL") .. "\n")	-- I bet that was getting anoying (TAD2020)
	if (input.Type ~= output.Type) and (input.Type ~= "ANY") and (output.Type ~= "ANY") then
		local text = "Data Type Mismatch! Input takes "..input.Type.." and Output gives "..output.Type
		MsgN(text)
		if pl then WireLib.AddNotify(pl, text, NOTIFY_GENERIC, 7) end
		WireLib.Link_Cancel(idx)
		return
	end

	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })
	Wire_Link(CurLink[idx].Dst, CurLink[idx].DstId, ent, oname, CurLink[idx].Path)

	if (WireLib.DT[input.Type].BiDir) then
		Wire_Link(ent, oname, CurLink[idx].Dst, CurLink[idx].DstId, {})
	end

	CurLink[idx] = nil
end


function WireLib.Link_Cancel(idx)
	if not CurLink[idx] then return end
	if not IsValid(CurLink[idx].Dst) then return end

	if CurLink[idx].input then
		CurLink[idx].Path = CurLink[idx].input.Path
	else
		WireLib.Paths.Add({Entity = CurLink[idx].Dst, Name = CurLink[idx].DstId, Width = 0})
	end
	CurLink[idx] = nil
end


function WireLib.Link_Clear(ent, iname, DontSendToCL, Removing)
	WireLib.Paths.Add({Entity = ent, Name = iname, Width = 0})
	Wire_Unlink(ent, iname, DontSendToCL, Removing)
end

function WireLib.WireAll(ply, ient, oent, ipos, opos, material, color, width)
	if not IsValid(ient) or not IsValid(oent) or not ient.Inputs or not oent.Outputs then return false end

	for iname, _ in pairs(ient.Inputs) do
		if oent.Outputs[iname] then
			WireLib.Link_Start(ply:UniqueID(), ient, ipos, iname, material or "arrowire/arrowire2", color or Color(255,255,255), width or 0)
			WireLib.Link_End(ply:UniqueID(), oent, opos, iname, ply)
		end
	end
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

	function WireLib.CreateOutputIterator()
		return setmetatable({}, OutputIterator)
	end
end -- class OutputIterator


duplicator.RegisterEntityModifier("WireDupeInfo", function(ply, Ent, DupeInfo)
	-- this does nothing for now, we need the blank function to get the duplicator to copy the WireDupeInfo into the pasted ent
end)


-- used for welding wired stuff, if trace is world, the ent is not welded and is frozen instead
function WireLib.Weld(ent, traceEntity, tracePhysicsBone, DOR, collision, AllowWorldWeld)
	if (not ent or not traceEntity or traceEntity:IsNPC() or traceEntity:IsPlayer()) then return end
	local phys = ent:GetPhysicsObject()
	if ( traceEntity:IsValid() ) or ( traceEntity:IsWorld() and AllowWorldWeld ) then
		local const = constraint.Weld( ent, traceEntity, 0, tracePhysicsBone, 0, not collision, DOR )
		-- Don't disable collision if it's not attached to anything
		if (not collision) then
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
	if not Ent.Inputs then return {} end

	local info = { Wires = {} }
	for portname,input in pairs(Ent.Inputs) do
		if (IsValid(input.Src)) then
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
					if (IsValid(v.Entity)) then
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
	if info.extended and not ent.extended then
		WireLib.CreateWirelinkOutput( ply, ent, {true} ) -- old dupe compatibility; use the new function
	end

	local idx = 0
	if IsValid(ply) then idx = ply:UniqueID() end -- Map Save loading does not have a ply
	if (info.Wires) then
		for k,input in pairs(info.Wires) do
			k=tostring(k) -- For some reason duplicator will parse strings containing numbers as numbers?
			local ent2 = GetEntByID(input.Src)

			-- Input alias
			if ent.Inputs and not ent.Inputs[k] then -- if the entity has any inputs and the input 'k' is not one of them...
				if ent.InputAliases and ent.InputAliases[k] then
					k = ent.InputAliases[k]
				else
					Msg("ApplyDupeInfo: Error, Could not find input '" .. k .. "' on entity type: '" .. ent:GetClass() .. "'\n")
					continue
				end
			end

			if IsValid( ent2 ) then
				-- Wirelink and entity outputs

				-- These are required if whichever duplicator you're using does not do entity modifiers before it runs PostEntityPaste
				-- because if so, the wirelink and entity outputs may not have been created yet

				if input.SrcId == "link" or input.SrcId == "wirelink" then -- If the target entity has no wirelink output, create one (& more old dupe compatibility)
					input.SrcId = "wirelink"
					if not ent2.extended then
						WireLib.CreateWirelinkOutput( ply, ent2, {true} )
					end
				elseif input.SrcId == "entity" and ((ent2.Outputs and not ent2.Outputs.entity) or not ent2.Outputs) then -- if the input name is 'entity', and the target entity doesn't have that output...
					WireLib.CreateEntityOutput( ply, ent2, {true} )
				end

				-- Output alias
				if ent2.Outputs and not ent2.Outputs[input.SrcId] then -- if the target entity has any outputs and the output 'input.SrcId' is not one of them...
					if ent2.OutputAliases and ent2.OutputAliases[input.SrcId] then
						input.SrcId = ent2.OutputAliases[input.SrcId]
					else
						Msg("ApplyDupeInfo: Error, Could not find output '" .. input.SrcId .. "' on entity type: '" .. ent2:GetClass() .. "'\n")
						continue
					end
				end
			end

			WireLib.Link_Start(idx, ent, input.StartPos, k, input.Material, input.Color, input.Width)

			if input.Path then
				for _,v in ipairs(input.Path) do
					local ent2 = GetEntByID(v.Entity)
					if IsValid(ent2) then
						WireLib.Link_Node(idx, ent2, v.Pos)
					else
						Msg("ApplyDupeInfo: Error, Could not find the entity for wire path\n")
					end
				end
			end

			if IsValid(ent2) then
				WireLib.Link_End(idx, ent2, input.SrcPos, input.SrcId)
			else
				Msg("ApplyDupeInfo: Error, Could not find the output entity\n")
			end
		end
	end
end

function WireLib.RefreshSpecialOutputs(ent)
	local names = {}
	local types = {}
	local descs = {}

	if ent.Outputs then
		for _,output in pairs(ent.Outputs) do
			local index = output.Num
			names[index] = output.Name
			types[index] = output.Type
			descs[index] = output.Desc
		end

		ent.Outputs = WireLib.AdjustSpecialOutputs(ent, names, types, descs)
	else
		ent.Outputs = WireLib.CreateSpecialOutputs(ent, names, types, descs)
	end

	WireLib.TriggerOutput(ent, "link", ent)
end

function WireLib.CreateInputs(ent, names, descs)
	return WireLib.CreateSpecialInputs(ent, names, {}, descs)
end


function WireLib.CreateOutputs(ent, names, descs)
	return WireLib.CreateSpecialOutputs(ent, names, {}, descs)
end


function WireLib.AdjustInputs(ent, names, descs)
	return WireLib.AdjustSpecialInputs(ent, names, {}, descs)
end


function WireLib.AdjustOutputs(ent, names, descs)
	return WireLib.AdjustSpecialOutputs(ent, names, {}, descs)
end

-- Backwards compatibility
Wire_CreateInputs				= WireLib.CreateInputs
Wire_CreateOutputs				= WireLib.CreateOutputs
Wire_AdjustInputs				= WireLib.AdjustInputs
Wire_AdjustOutputs				= WireLib.AdjustOutputs
Wire_Restored					= WireLib.Restored
Wire_Remove						= WireLib.Remove
Wire_TriggerOutput				= WireLib.TriggerOutput
Wire_Link_Start					= WireLib.Link_Start
Wire_Link_Node					= WireLib.Link_Node
Wire_Link_End					= WireLib.Link_End
Wire_Link_Cancel				= WireLib.Link_Cancel
Wire_Link_Clear					= WireLib.Link_Clear
Wire_CreateOutputIterator		= WireLib.CreateOutputIterator
Wire_BuildDupeInfo				= WireLib.BuildDupeInfo
Wire_ApplyDupeInfo				= WireLib.ApplyDupeInfo

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

function WireLib.GetOwner(ent)
	return E2Lib.getOwner({}, ent)
end

function WireLib.NumModelSkins(model)
	if NumModelSkins then
		return NumModelSkins(model)
	end
	local info = util.GetModelInfo(model)
	return info and info.SkinCount
end

--- @return whether the given player can spawn an object with the given model and skin
function WireLib.CanModel(player, model, skin)
	if not util.IsValidModel(model) then return false end
	if skin ~= nil then
		local count = WireLib.NumModelSkins(model)
		if skin < 0 or (count and skin >= count) then return false end
	end
	if IsValid(player) and player:IsPlayer() and not hook.Run("PlayerSpawnObject", player, model, skin) then return false end
	return true
end

function WireLib.MakeWireEnt( pl, Data, ... )
	Data.Class = scripted_ents.Get(Data.Class).ClassName
	if IsValid(pl) and not pl:CheckLimit(Data.Class:sub(6).."s") then return false end
	if Data.Model and not WireLib.CanModel(pl, Data.Model, Data.Skin) then return false end

	local ent = ents.Create( Data.Class )
	if not IsValid(ent) then return false end

	duplicator.DoGeneric( ent, Data )
	ent:Spawn()
	ent:Activate()
	duplicator.DoGenericPhysics( ent, pl, Data ) -- Is deprecated, but is the only way to access duplicator.EntityPhysics.Load (its local)

	ent:SetPlayer(pl)
	if ent.Setup then ent:Setup(...) end

	if IsValid(pl) then pl:AddCount( Data.Class:sub(6).."s", ent ) end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		if Data.frozen then phys:EnableMotion(false) end
		if Data.nocollide then phys:EnableCollisions(false) end
	end

	return ent
end

-- Adds an input alias so that we can rename inputs on entities without breaking old dupes
-- Usage: WireLib.AddInputAlias( old, new ) works if used in the entity's file
-- or WireLib.AddInputAlias( class, old, new ) if used elsewhere
-- or WireLib.AddInputAlias( entity, old, new ) for a specific entity
function WireLib.AddInputAlias( class, old, new )
	if not new then
		new = old
		old = class
		class = nil
	end

	local ENT_table

	if not class and ENT then
		ENT_table = ENT
	elseif isstring( class ) then
		ENT_table = scripted_ents.GetStored( class )
	elseif isentity( class ) and IsValid( class ) then
		ENT_table = class
	else
		error( "Invalid class or entity specified" )
		return
	end

	if not ENT_table.InputAliases then ENT_table.InputAliases = {} end
	ENT_table.InputAliases[old] = new
end

-- Adds an output alias so that we can rename outputs on entities without breaking old dupes
-- Usage: WireLib.AddOutputAlias( old, new ) works if used in the entity's file
-- or WireLib.AddOutputAlias( class, old, new ) if used elsewhere
-- or WireLib.AddOutputAlias( entity, old, new ) for a specific entity
function WireLib.AddOutputAlias( class, old, new )
	if not new then
		new = old
		old = class
		class = nil
	end

	local ENT_table

	if not class and ENT then
		ENT_table = ENT
	elseif isstring( class ) then
		ENT_table = scripted_ents.GetStored( class )
	elseif isentity( class ) and IsValid( class ) then
		ENT_table = class
	else
		error( "Invalid class or entity specified" )
		return
	end

	if not ENT_table.OutputAliases then ENT_table.OutputAliases = {} end
	ENT_table.OutputAliases[old] = new
end

local function effectiveMass(ent)
	if not isentity(ent) then return 1 end
	if ent:IsWorld() then return 99999 end
	if not IsValid(ent) or not IsValid(ent:GetPhysicsObject()) then return 1 end
	return ent:GetPhysicsObject():GetMass()
end

function WireLib.CalcElasticConsts(Ent1, Ent2)
	local minMass = math.min(effectiveMass(Ent1), effectiveMass(Ent2))
	local const = minMass * 100
	local damp = minMass * 20

	return const, damp
end


local version
local version_string
--- Returns the current Wiremod version
---@return number version The version as a number formatted YYMMDD
---@return string version_string A verbose version for printing
function WireLib.GetVersion()
	-- If we've already found our version just return that again
	if version then return version, version_string end

	local wirefolder = "addons/wire"
	-- Brute force find the wire folder if it's not named wire
	if not file.Exists(wirefolder, "GAME") then
		for _, folder in pairs(({file.Find("addons/*", "GAME")})[2]) do
			if folder:find("wire") and not folder:find("extra") then
				wirefolder = "addons/"..folder
				break
			end
		end
	end

	if file.Exists(wirefolder, "GAME") then
		wirefolder = wirefolder .. "/.git"
		if file.Exists(wirefolder, "GAME") then
			-- Find where git HEAD is
			local head = file.Open(wirefolder .. "/HEAD", "r", "GAME")
			if head then
				local ref
				while not head:EndOfFile() do
					local line = head:ReadLine()
					if line:StartsWith("ref: ") then
						ref = line:sub(6, -2)
					end
				end
				head:Close()
				if ref then
					-- Generate version string
					local path = wirefolder .. "/" .. ref
					local name = ref:StartsWith("refs/heads/") and ref:sub(12) or ref
					local time = -1
					local time_str = "Unknown"
					local hash = ""
					if file.Exists(path, "GAME") then
						local t = file.Time(path, "GAME")
						time =  tonumber(os.date("%y%m%d", t))
						time_str = os.date("%Y.%m.%d", t)
						hash = file.Read(path, "GAME"):sub(1, 7)
					end

					version_string = string.format("Local %s (%s:%s)", time_str, name, hash)
					version = time
				end
			end
		end
	end

	if not version then
		version = -1
		version_string = "Unknown"
	end

	return version, version_string
end
concommand.Add("wireversion", function(ply)
	local text = "Wiremod version: " .. select(2, WireLib.GetVersion())
	if IsValid(ply) then
		ply:ChatPrint(text)
	else
		print(text)
	end
end, nil, "Prints the server's Wiremod version")

function WireLib.CheckRegex(data, pattern)
	local limits = {[0] = 50000000, 15000, 500, 150, 70, 40} -- Worst case is about 200ms
	local stripped, nrepl, nrepl2
	-- strip escaped things
	stripped, nrepl = string.gsub(pattern, "%%.", "")
	-- strip bracketed things
	stripped, nrepl2 = string.gsub(stripped, "%[.-%]", "")
	-- strip captures
	stripped = string.gsub(stripped, "[()]", "")
	-- Find extenders
	local n = 0 for i in string.gmatch(stripped, "[%+%-%*]") do n = n + 1 end
	local msg
	if n<=#limits then
		if #data*(#stripped + nrepl - n + nrepl2)>limits[n] then msg = n.." ext search length too long ("..limits[n].." max)" else return end
	else
		msg = "too many extenders"
	end
	error("Regex is too complex! " .. msg)
end

local material_blacklist = {
	["pp/copy"] = true,
	["engine/writez"] = true,
	["debug/debugluxels"] = true, -- Crashes linux client
	["effects/ar2_altfire1"] = true
}
function WireLib.IsValidMaterial(material)
	material = string.sub(material, 1, 260)
	local path = string.StripExtension(string.GetNormalizedFilepath(string.lower(material)))
	if material_blacklist[path] then return "" end
	return material
end

local ENTITY = FindMetaTable("Entity")

if CPPI and ENTITY.CPPICanTool then
	--- Returns if given player can tool the given entity.
	---@param player Player
	---@param entity Entity
	---@param toolname string
	function WireLib.CanTool(player, entity, toolname) ---@return boolean
		return entity:CPPICanTool(player, toolname)
	end
else
	local zero = Vector(0, 0, 0)
	local norm = Vector(1, 0, 0)

	local tr = { ---@type TraceResult
		Hit = true, HitNonWorld = true, HitNoDraw = false, HitSky = false, AllSolid = true,
		HitNormal = zero, Normal = norm,

		Fraction = 1, FractionLeftSolid = 0,
		HitBox = 0, HitGroup = 0, HitTexture = "**studio**",
		MatType = 0, PhysicsBone = 0, SurfaceProps = 0, DispFlags = 0, Contents = 0,

		Entity = NULL, HitPos = zero, StartPos = zero,
	}

	--- Returns if given player can tool the given entity.
	---@param player Player
	---@param entity Entity
	---@param toolname string
	function WireLib.CanTool(player, entity, toolname) ---@return boolean
		local pos = entity:GetPos()
		tr.Entity, tr.HitPos, tr.StartPos = entity, pos, pos
		return hook.Run("CanTool", player, tr, toolname) ~= false
	end
end

if CPPI and ENTITY.CPPICanPhysgun then
	--- Returns if given player can physgun the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPhysgun(player, target) ---@return boolean
		return target:CPPICanPhysgun(player)
	end
else
	--- Returns if given player can physgun the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPhysgun(player, target) ---@return boolean
		return hook.Run("PhysgunPickup", player, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanPickup then
	--- Returns if given player can pickup the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPickup(player, target) ---@return boolean
		return target:CPPICanPickup(player)
	end
else
	--- Returns if given player can pickup the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPickup(player, target) ---@return boolean
		return hook.Run("GravGunPickupAllowed", player, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanPunt then
	--- Returns if given player can punt the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPunt(player, target) ---@return boolean
		return target:CPPICanPunt(player)
	end
else
	--- Returns if given player can punt the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanPunt(player, target) ---@return boolean
		return hook.Run("GravGunPunt", player, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanUse then
	--- Returns if given player can use the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanUse(player, target) ---@return boolean
		return target:CPPICanUse(player)
	end
else
	--- Returns if given player can use the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanUse(player, target) ---@return boolean
		return hook.Run("PlayerUse", player, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanDamage then
	--- Returns if given player can damage the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanDamage(player, target) ---@return boolean
		return target:CPPICanDamage(player)
	end
else
	--- Returns if given player can damage the given entity.
	--- Uses PlayerShouldTakeDamage for players, CanTool for entities.
	---@param player Player
	---@param target Entity
	function WireLib.CanDamage(player, target) ---@return boolean
		if target:IsPlayer() then
			return hook.Run("PlayerShouldTakeDamage", target, player) ~= false
		else
			return WireLib.CanTool(player, target, "")
		end
	end
end

if CPPI and ENTITY.CPPIDrive then -- why is this not CPPICanDrive?
	--- Returns if given player can prop drive the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanDrive(player, target) ---@return boolean
		return target:CPPIDrive(player)
	end
else
	--- Returns if given player can prop drive the given entity.
	---@param player Player
	---@param target Entity
	function WireLib.CanDrive(player, target) ---@return boolean
		return hook.Run("CanDrive", player, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanProperty then
	--- Returns if the player can apply the given property to the target.
	---@param player Player
	---@param target Entity
	---@param property string
	function WireLib.CanProperty(player, target, property) ---@return boolean
		return target:CPPICanProperty(player, property)
	end
else
	--- Returns if the player can apply the given property to the target.
	---@param player Player
	---@param target Entity
	---@param property string
	function WireLib.CanProperty(player, target, property) ---@return boolean
		return hook.Run("CanProperty", player, property, target) ~= false
	end
end

if CPPI and ENTITY.CPPICanEditVariable then
	--- Returns if the player can modify the target's editable values.
	---@param self Entity
	---@param ply Player
	---@param key string
	---@param val string
	---@param editor table
	WireLib.CanEditVariable = ENTITY.CPPICanEditVariable ---@return boolean
else
	--- Returns if the player can modify the target's editable values.
	---@param self Entity
	---@param ply Player
	---@param key string
	---@param val string
	---@param editor table
	function WireLib.CanEditVariable(self, ply, key, val, editor) ---@return boolean
		return hook.Run("CanEditVariable", self, ply, key, val, editor) ~= false
	end
end

function WireLib.SetColor(ent, color)
	color.r = math_clamp(color.r, 0, 255)
	color.g = math_clamp(color.g, 0, 255)
	color.b = math_clamp(color.b, 0, 255)
	color.a = ent:IsPlayer() and ent:GetColor().a or math_clamp(color.a, 0, 255)

	local rendermode = ent:GetRenderMode()
	if rendermode == RENDERMODE_NORMAL or rendermode == RENDERMODE_TRANSALPHA then
		rendermode = color.a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA
		ent:SetRenderMode(rendermode)
	else
		rendermode = nil -- Don't modify the current stored modifier
	end

	ent:SetColor(color)
	duplicator.StoreEntityModifier(ent, "colour", { Color = color, RenderMode = rendermode })
end

if not WireLib.PatchedDuplicator then
	WireLib.PatchedDuplicator = true

	local localPos

	local oldSetLocalPos = duplicator.SetLocalPos
	function duplicator.SetLocalPos(pos, ...)
		localPos = pos
		return oldSetLocalPos(pos, ...)
	end

	local oldPaste = duplicator.Paste
	function duplicator.Paste(player, entityList, constraintList, ...)
		local result = { oldPaste(player, entityList, constraintList, ...) }
		local createdEntities, createdConstraints = result[1], result[2]
		local data = {
			EntityList = entityList, ConstraintList = constraintList,
			CreatedEntities = createdEntities, CreatedConstraints = createdConstraints,
			Player = player, HitPos = localPos,
		}
		hook.Run("AdvDupe_FinishPasting", {data}, 1)
		return unpack(result)
	end
end

local uniqueSoundsTbl = setmetatable({}, {__index=function(t,k) local r={[1]=0} t[k]=r return r end})
local maxUniqueSounds = CreateConVar("wire_sounds_unique_max", "200", FCVAR_ARCHIVE, "The maximum number of sound paths a player is allowed to cache")

function WireLib.SoundExists(path, ply)
	-- Limit length and remove invalid chars
	path = string.GetNormalizedFilepath(string.gsub(string.sub(path, 1, 260), "[\"?']", ""))

	-- Extract sound flags. See https://developer.valvesoftware.com/wiki/Soundscripts#Sound_characters
	local flags, checkpath = string.match(path, "^([^%w_/%.]*)(.*)")
	if #flags > 2 or string.match(flags, "[^#@<>%^%)}]") then
		path = checkpath
	end

	if ply then
		-- A player can only use a certain number of unique sound paths
		local playerSounds = uniqueSoundsTbl[ply:SteamID()]
		if not playerSounds[checkpath] then
			if playerSounds[1] >= maxUniqueSounds:GetInt() then return end
			playerSounds[checkpath] = true
			playerSounds[1] = playerSounds[1] + 1
		end
	elseif not (istable(sound.GetProperties(checkpath)) or file.Exists("sound/" .. checkpath, "GAME")) then
		return
	end

	return path
end

-- Notify --

local triv_start = WireLib.Net.Trivial.Start

--- Sends a colored message to the player's chat.
--- When used serverside, setting the player as nil will only inform the server.
--- When used clientside, the first argument is ignored and only the local player is informed.
---@param ply Player | Player[]?
---@param msg string
---@param severity WireLib.NotifySeverity?
---@param chatprint boolean?
---@param color Color?
local function notify(ply, msg, severity, chatprint, color)
	if not severity then severity = 1 end
	if chatprint == nil then chatprint = severity < 2 end

	if not ply or severity > 2 then
		if game.SinglePlayer() then
			ply = Entity(1)
		else
			local arg = WireLib.NotifyBuilder(msg, severity, color)
			if isentity(ply) then
				table.insert(arg, 2, ": ")
				table.insert(arg, 2, ply)
			end
			MsgC(unpack(arg))
		end
	end
	if ply then
		triv_start("notify")
			net.WriteUInt(severity, 4)
			net.WriteBool(color ~= nil)
			if color ~= nil then net.WriteColor(color, false) end
			local data = util.Compress(string.sub(msg, 1, 2048))
			local datal = #data
			net.WriteUInt(datal, 11)
			net.WriteData(data, datal)
			net.WriteBool(chatprint)
		net.Send(ply)
	end
end
WireLib.Notify = notify

--- Sends a colored message to all players in a usergroup.
---@param group string | string[]
---@param msg string
---@param severity WireLib.NotifySeverity? A value from WireLib.NotifySeverity
---@param chatprint boolean?
---@param color Color?
function WireLib.NotifyGroup(group, msg, severity, chatprint, color)
	local plys = {}

	if isstring(group) then
		for _, p in ipairs(player.GetAll()) do
			if p:GetUserGroup() == group then
				plys[#plys + 1] = p
			end
		end
	else
		for _, p in ipairs(player.GetAll()) do
			if table.HasValue(group, p:GetUserGroup()) then
				plys[#plys + 1] = p
			end
		end
	end

	notify(plys, msg, severity, chatprint, color)
end

--- Sends a colored message to all players' chats. Equivalent to the first argument of WireLib.Notify being nil
---@param msg string
---@param severity WireLib.NotifySeverity? A value from WireLib.NotifySeverity
---@param chatprint boolean?
---@param color Color?
function WireLib.NotifyAll(msg, severity, chatprint, color)
	notify(player.GetAll(), msg, severity, chatprint, color)
end
