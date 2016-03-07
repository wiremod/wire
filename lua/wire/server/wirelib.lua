-- Compatibility Global

if not WireLib then return end

WireAddon = 1

local ents = ents
local timer = timer
local string = string
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
local Material = Material

local HasPorts = WireLib.HasPorts -- Very important for checks!


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

hook.Add("Think", "WireLib_Think", function()
	for idx,port in pairs(Outputs) do
		port.TriggerLimit = 4
	end
end)

-- helper function that pcalls an input
function WireLib.TriggerInput(ent, name, value, ...)
	if (not IsValid(ent) or not HasPorts(ent) or not ent.Inputs or not ent.Inputs[name]) then return end
	ent.Inputs[name].Value = value

	if (not ent.TriggerInput) then return end
	local ok, ret = xpcall(ent.TriggerInput, debug.traceback, ent, name, value, ...)
	if not ok then
		local message = string.format("Wire error (%s):\n%s\n", tostring(ent), ret)
		WireLib.ErrorNoHalt(message)
		local ply = WireLib.GetOwner(ent)
		if IsValid(ply) then WireLib.ClientError(message, ply) end
	end
end

-- an array of data types
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
	ARRAY = {
		Zero = {}
	},
	BIDIRARRAY = {
		Zero = {},
		BiDir = true
	},
}

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
			Value = WireLib.DT[ tp ].Zero,
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

	WireLib.SetPathNames(ent, names)
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
			Value = WireLib.DT[ tp ].Zero,
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
				ent_ports[name].Value = WireLib.DT[tp].Zero
				ent_ports[name].Type = tp
			end
			ent_ports[name].Keep = true
			ent_ports[name].Num = n
			ent_ports[name].Desc = descs[n]
		else
			local port = {
				Entity = ent,
				Name = name,
				Desc = desc,
				Type = tp,
				Value = WireLib.DT[ tp ].Zero,
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

	WireLib.SetPathNames(ent, names)
	WireLib._SetInputs(ent)

	return ent_ports
end


function WireLib.AdjustSpecialOutputs(ent, names, types, descs)
	types = types or {}
	descs = descs or {}
	local ent_ports = ent.Outputs or {}
	for n,v in ipairs(names) do
		local name, desc, tp = ParsePortName(v, types[n] or "NORMAL", descs and descs[n])

		if (ent_ports[name]) then
			if tp ~= ent_ports[name].Type then
				WireLib.DisconnectOutput(ent, name)
				ent_ports[name].Type = tp
			end
			ent_ports[name].Keep = true
			ent_ports[name].Num = n
			ent_ports[name].Desc = descs[n]
		else
			local port = {
				Keep = true,
				Name = name,
				Desc = descs[n],
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
	ent_ports[iname].Value = WireLib.DT[itype].Zero

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
	ent_ports[oname].Value = WireLib.DT[otype].Zero

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
			if (port.Src) and (not port.Path) then
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

local function ClearPorts(ports, ConnectEnt, DontSendToCL)
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
						WireLib.Link_Clear(Ent, Name, DontSendToCL)
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
						ClearPorts(outport.Connected, ent, true)
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
	if not IsValid(ent) then return end
	if not HasPorts(ent) then return end
	if (not ent.Outputs) then return end

	local output = ent.Outputs[oname]
	if (output) and (value ~= output.Value or output.Type == "ARRAY" or output.Type == "TABLE") then
		if (output.TriggerLimit <= 0) then return end
		output.TriggerLimit = output.TriggerLimit - 1

		output.Value = value

		if (iter) then
			for _,dst in ipairs(output.Connected) do
				if (IsValid(dst.Entity)) then
					iter:Add(dst.Entity, dst.Name, value)
				end
			end
			return
		end

		iter = WireLib.CreateOutputIterator()

		for _,dst in ipairs(output.Connected) do
			if (IsValid(dst.Entity)) then
				WireLib.TriggerInput(dst.Entity, dst.Name, value, iter)
			end
		end

		iter:Process()

	end
end

local function Wire_Unlink(ent, iname, DontSendToCL)
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

		WireLib.TriggerInput(ent, iname, WireLib.DT[input.Type].Zero, nil)

		if (DontSendToCL) then return end
		WireLib._SetLink(input)
	end
end

function WireLib.Link_Start(idx, ent, pos, iname, material, color, width)
	if not IsValid(ent) then return end
	if not HasPorts(ent) then return end
	if (not ent.Inputs or not ent.Inputs[iname]) then return end

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


function WireLib.Link_Node(idx, ent, pos)
	if not CurLink[idx] then return end
	if not IsValid(CurLink[idx].Dst) then return end
	if not IsValid(ent) then return end -- its the world, give up

	local net_name = "wp_" .. CurLink[idx].DstId
	local node_idx = CurLink[idx].Dst:GetNetworkedBeamInt(net_name)+1
	CurLink[idx].Dst:SetNetworkedBeamEntity(net_name .. "_" .. node_idx .. "_ent", ent)
	CurLink[idx].Dst:SetNetworkedBeamVector(net_name .. "_" .. node_idx .. "_pos", pos)
	CurLink[idx].Dst:SetNetworkedBeamInt(net_name, node_idx)

	--RDbeamlib.AddWireBeamNode( CurLink[idx].Dst, CurLink[idx].DstId, ent, pos )

	table.insert(CurLink[idx].Path, { Entity = ent, Pos = pos })
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


function WireLib.Link_Cancel(idx)
	if not CurLink[idx] then return end
	if not IsValid(CurLink[idx].Dst) then return end

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


function WireLib.Link_Clear(ent, iname, DontSendToCL)
	local net_name = "wp_" .. iname
	ent:SetNetworkedBeamInt(net_name, 0)
	--RDbeamlib.ClearWireBeam( ent, iname )

	Wire_Unlink(ent, iname, DontSendToCL)
end

function WireLib.SetPathNames(ent, names)
	for k,v in pairs(names) do
		ent:SetNetworkedBeamString("wpn_" .. k, v)
	end
	ent:SetNetworkedBeamInt("wpn_count", #names)
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
		local const = constraint.Weld( ent, traceEntity, 0, tracePhysicsBone, 0, (not collision), DOR )
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
Wire_SetPathNames				= WireLib.SetPathNames
Wire_CreateOutputIterator		= WireLib.CreateOutputIterator
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
	local unique = "WireLib_PostDupe_"..tostring({})
	timer.Create(unique, 1, 240, function()
		local ent = CreatedEntities[entid]
		if ent then
			timer.Remove(unique)

			-- and call the callback
			func(ent)
		end
	end)
end

function WireLib.GetOwner(ent)
	return E2Lib.getOwner({}, ent)
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

function WireLib.MakeWireEnt( pl, Data, ... )
	Data.Class = scripted_ents.Get(Data.Class).ClassName
	if IsValid(pl) and not pl:CheckLimit(Data.Class:sub(6).."s") then return false end

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

function WireLib.CalcElasticConsts(Ent1, Ent2)
	if not IsValid(Ent1:GetPhysicsObject()) or not IsValid(Ent2:GetPhysicsObject()) then return 100, 20 end
	local minMass = math.min(Ent1:IsWorld() and 99999 or Ent1:GetPhysicsObject():GetMass(), Ent2:IsWorld() and 99999 or Ent2:GetPhysicsObject():GetMass())
	local const = minMass * 100
	local damp = minMass * 20

	return const, damp
end


-- Returns a string like "Git f3a4ac3" or "SVN 2703" or "Workshop" or "Extracted"
-- The partial git hash can be plugged into https://github.com/wiremod/wire/commit/f3a4ac3 to show the actual commit
local cachedversion
function WireLib.GetVersion()
	-- If we've already found our version just return that again
	if cachedversion then return cachedversion end

	-- Check if we're Workshop version first
	for k, addon in pairs(engine.GetAddons()) do
		if addon.wsid == "160250458" then
			cachedversion = "Workshop"
			return cachedversion
		end
	end

	-- Find what our legacy folder is called
	local wirefolder = "addons/wire"
	if not file.Exists(wirefolder, "GAME") then
		for k, folder in pairs(({file.Find("addons/*", "GAME")})[2]) do
			if folder:find("wire") and not folder:find("extra") then
				wirefolder = "addons/"..folder
				break
			end
		end
	end

	if file.Exists(wirefolder, "GAME") then
		if file.Exists(wirefolder.."/.git", "GAME") then
			cachedversion = "Git "..(file.Read(wirefolder.."/.git/refs/heads/master", "GAME") or "Unknown"):sub(1,7)
		elseif file.Exists(wirefolder.."/.svn", "GAME") then
			-- Note: This method will likely only detect TortoiseSVN installs
			local wcdb = file.Read(wirefolder.."/.svn/wc.db", "GAME") or ""
			local start = wcdb:find("/wiremod/wire/!svn/ver/%d+/branches%)")
			if start then
				cachedversion = "SVN "..wcdb:sub(start+23, start+26)
			else
				cachedversion = "SVN Unknown"
			end
		else
			cachedversion = "Extracted"
		end
	end

	if not cachedversion then cachedversion = "Unknown" end

	return cachedversion
end
concommand.Add("wireversion", function(ply,cmd,args)
	local text = "Wiremod's version: '"..WireLib.GetVersion().."'"
	if IsValid(ply) then
		ply:ChatPrint(text)
	else
		print(text)
	end
end, nil, "Prints the server's Wiremod version")
