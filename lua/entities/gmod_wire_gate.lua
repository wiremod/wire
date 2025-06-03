AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Gate"
ENT.WireDebugName = "Gate"

if CLIENT then return end -- No more client

local Wire_EnableGateInputValues = CreateConVar("Wire_EnableGateInputValues", 1, FCVAR_ARCHIVE)

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self.Inputs = {}
	self.Outputs = {}
end

function ENT:Setup(action, noclip)
	local gate = GateActions[action]
	if not gate or gate.is_banned then return end

	self.Updating = true
	self.action = action
	self.WireDebugName = gate.name

	WireLib.AdjustSpecialInputs(self, gate.inputs, gate.inputtypes)

	if gate.outputs then
		WireLib.AdjustSpecialOutputs(self, gate.outputs, gate.outputtypes)
	else
		WireLib.AdjustSpecialOutputs(self, { "Out" }, gate.outputtypes)
	end

	if gate.reset then
		gate.reset(self)
	end

	local ReadCell = gate.ReadCell

	if ReadCell then
		function self:ReadCell(address)
			return ReadCell(gate, self, address)
		end
	else
		self.ReadCell = nil
	end

	local WriteCell = gate.WriteCell

	if WriteCell then
		function self:WriteCell(address, value)
			return WriteCell(gate, self, address, value)
		end
	else
		self.WriteCell = nil
	end

	if noclip then
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	self.noclip = noclip
	self.Action = gate
	self.PrevValue = nil
	self.Updating = nil

	self:CalcOutput()
	self:ShowOutput()
end


function ENT:OnInputWireLink(iname, itype, src, oname, otype)
	local action = self.Action

	if action and action.OnInputWireLink then
		action.OnInputWireLink(self, iname, itype, src, oname, otype)
	end
end

function ENT:OnOutputWireLink(oname, otype, dst, iname, itype)
	local action = self.Action

	if action and action.OnOutputWireLink then
		action.OnOutputWireLink(self, oname, otype, dst, iname, itype)
	end
end

function ENT:TriggerInput(iname, value, iter)
	local selfTbl = self:GetTable()
	if selfTbl.Updating then return end

	local action = selfTbl.Action
	if not action or action.timed then return end

	selfTbl.CalcOutput(self, iter, selfTbl)
	selfTbl.ShowOutput(self, selfTbl)
end

function ENT:Think()
	BaseClass.Think(self)

	local selfTbl = self:GetTable()
	local action = selfTbl.Action

	if action and action.timed then
		selfTbl.CalcOutput(self, nil, selfTbl)
		selfTbl.ShowOutput(self, selfTbl)
		self:NextThink(CurTime() + 0.02)

		return true
	end
end

function ENT:CalcOutput(iter, selfTbl)
	selfTbl = selfTbl or self:GetTable()
	local action = selfTbl.Action

	if action and action.output then
		local entOutputs = selfTbl.Outputs

		if action.outputs then
			local result = { action.output(self, unpack(selfTbl.GetActionInputs(self, nil, selfTbl), 1, #action.inputs)) }

			for k, v in ipairs(action.outputs) do
				WireLib.TriggerOutput(self, v, result[k] or WireLib.GetDefaultForType(entOutputs[v].Type), iter)
			end
		else
			local value = action.output(self, unpack(selfTbl.GetActionInputs(self, nil, selfTbl), 1, #action.inputs)) or WireLib.GetDefaultForType(entOutputs.Out.Type)

			WireLib.TriggerOutput(self, "Out", value, iter)
		end
	end
end

function ENT:ShowOutput(selfTbl)
	selfTbl = selfTbl or self:GetTable()
	local action = selfTbl.Action
	local txt

	if action then
		txt = (action.name or "No Name")

		if action.label then
			txt = txt .. "\n" .. action.label(selfTbl.GetActionOutputs(self, selfTbl), unpack(selfTbl.GetActionInputs(self, Wire_EnableGateInputValues:GetBool(), selfTbl), 1, #action.inputs))
		end
	else
		txt = "Invalid gate!"
	end

	self:SetOverlayText(txt)
end

function ENT:OnRestore()
	self.Action = GateActions[self.action]
	BaseClass.OnRestore(self)
end

function ENT:GetActionInputs(as_names, selfTbl)
	selfTbl = selfTbl or self:GetTable()

	local args = {}
	local action = selfTbl.Action
	local entInputs = selfTbl.Inputs

	if action.compact_inputs then
		local action_inputs = action.inputs

		-- If a gate has compact inputs (like Arithmetic - Add), nil inputs are truncated so {0, nil, nil, 5, nil, 1} becomes {0, 5, 1}
		for k, v in ipairs(action_inputs) do
			local input = entInputs[v]

			if not input then
				ErrorNoHalt("Wire Gate (" .. action .. ") error: Missing input! (" .. k .. "," .. v .. ")\n")
				return {}
			end

			if IsValid(input.Src) then
				if as_names then
					table.insert(args, input.Src.WireName or input.Src.WireDebugName or v)
				else
					table.insert(args, input.Value)
				end
			end
		end

		for i = #args + 1, action.compact_inputs do
			if as_names then
				args[i] = action_inputs[i] or "*Not enough inputs*"
			else
				args[i] = WireLib.GetDefaultForType(entInputs[action_inputs[i]].Type)
			end
		end
	else
		for k, v in ipairs(action.inputs) do
			local input = entInputs[v]

			if not input then
				ErrorNoHalt("Wire Gate (" .. action .. ") error: Missing input! (" .. k .. "," .. v .. ")\n")
				return {}
			end

			if as_names then
				args[k] = IsValid(input.Src) and (input.Src.WireName or input.Src.WireDebugName) or v
			else
				args[k] = IsValid(input.Src) and input.Value or WireLib.GetDefaultForType(entInputs[v].Type)
			end
		end
	end

	return args
end

function ENT:GetActionOutputs(selfTbl)
	selfTbl = selfTbl or self:GetTable()
	local outputs = selfTbl.Outputs
	local action_outputs = selfTbl.Action.outputs

	if action_outputs then
		local result = {}

		for _, v in ipairs(action_outputs) do
			result[v] = outputs[v].Value or WireLib.GetDefaultForType(outputs[v].Type)
		end

		return result
	end

	return outputs.Out.Value or WireLib.GetDefaultForType(outputs.Out.Type)
end

function WireLib.MakeWireGate(ply, pos, ang, model, action, noclip)
	local gate = GateActions[action]
	if not gate or gate.is_banned then return end

	return WireLib.MakeWireEnt(ply, { Class = "gmod_wire_gate", Pos = pos, Angle = ang, Model = model }, action, noclip)
end

duplicator.RegisterEntityClass("gmod_wire_gate", WireLib.MakeWireGate, "Pos", "Ang", "Model", "action", "noclip")
