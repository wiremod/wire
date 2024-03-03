AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Gate"
ENT.WireDebugName = "Gate"

if CLIENT then return end -- No more client

local Wire_EnableGateInputValues = CreateConVar("Wire_EnableGateInputValues", 1, FCVAR_ARCHIVE)

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = {}
	self.Outputs = {}
end

function ENT:Setup( action, noclip )
	local gate = GateActions[action]
	if not gate then return end
	if GateActions[action].is_banned then return end

	self.Updating = true

	self.action = action

	self.WireDebugName = gate.name

	WireLib.AdjustSpecialInputs(self, gate.inputs, gate.inputtypes )
	if gate.outputs then
		WireLib.AdjustSpecialOutputs(self, gate.outputs, gate.outputtypes)
	else
		--Wire_AdjustOutputs(self, { "Out" })
		WireLib.AdjustSpecialOutputs(self, { "Out" }, gate.outputtypes)
	end

	if gate.reset then
		gate.reset(self)
	end

	local ReadCell = gate.ReadCell
	if ReadCell then
		function self:ReadCell(Address)
			return ReadCell(gate,self,Address)
		end
	else
		self.ReadCell = nil
	end

	local WriteCell = gate.WriteCell
	if WriteCell then
		function self:WriteCell(Address,value)
			return WriteCell(gate,self,Address,value)
		end
	else
		self.WriteCell = nil
	end

	if noclip then
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
	self.noclip = noclip

	self.Action = gate
	self.PrevValue = nil

	--self.Action.inputtypes = self.Action.inputtypes or {}

	self.Updating = nil

	self:CalcOutput()
	self:ShowOutput()
end


function ENT:OnInputWireLink(iname, itype, src, oname, otype)
	if self.Action and self.Action.OnInputWireLink then
		self.Action.OnInputWireLink(self, iname, itype, src, oname, otype)
	end
end

function ENT:OnOutputWireLink(oname, otype, dst, iname, itype)
	if self.Action and self.Action.OnOutputWireLink then
		self.Action.OnOutputWireLink(self, oname, otype, dst, iname, itype)
	end
end

function ENT:TriggerInput(iname, value, iter)
	if self.Updating then return end
	if self.Action and not self.Action.timed then
		self:CalcOutput(iter)
		self:ShowOutput()
	end
end

function ENT:Think()
	BaseClass.Think(self)

	local selfTbl = self:GetTable()
	local action = selfTbl.Action

	if action and action.timed then
		self:CalcOutput()
		self:ShowOutput()

		self:NextThink(CurTime() + 0.02)
		return true
	end
end


function ENT:CalcOutput(iter)
	local selfTbl = self:GetTable()
	local action = selfTbl.Action
	local entOutputs = selfTbl.Outputs

	if action and action.output then
		if action.outputs then
			local result = { action.output(self, unpack(self:GetActionInputs(), 1, #action.inputs)) }

			for k, v in ipairs(action.outputs) do
				Wire_TriggerOutput(self, v, result[k] or WireLib.GetDefaultForType(entOutputs[v].Type), iter)
			end
		else
			local value = action.output(self, unpack(self:GetActionInputs(), 1, #action.inputs)) or WireLib.GetDefaultForType(entOutputs.Out.Type)

			Wire_TriggerOutput(self, "Out", value, iter)
		end
	end
end

function ENT:ShowOutput()
	local txt
	local action = self.Action

	if action then
		txt = (action.name or "No Name")
		if action.label then
			txt = txt .. "\n" .. action.label(self:GetActionOutputs(), unpack(self:GetActionInputs(Wire_EnableGateInputValues:GetBool()), 1, #action.inputs))
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


function ENT:GetActionInputs(as_names)
	local Args = {}
	local selfTbl = self:GetTable()
	local action = selfTbl.Action
	local entInputs = selfTbl.Inputs

	if action.compact_inputs then
		-- If a gate has compact inputs (like Arithmetic - Add), nil inputs are truncated so {0, nil, nil, 5, nil, 1} becomes {0, 5, 1}
		for k,v in ipairs(action.inputs) do
			local input = entInputs[v]
			if not input then
				ErrorNoHalt("Wire Gate (" .. selfTbl.action .. ") error: Missing input! (" .. k .. "," .. v .. ")\n")
				return {}
			end

			if IsValid(input.Src) then
				if as_names then
					table.insert(Args, input.Src.WireName or input.Src.WireDebugName or v)
				else
					table.insert(Args, input.Value)
				end
			end
		end

		while #Args < action.compact_inputs do
			if as_names then
				table.insert(Args, action.inputs[#Args + 1] or "*Not enough inputs*")
			else
				table.insert(Args, WireLib.GetDefaultForType(entInputs[action.inputs[#Args + 1]].Type))
			end
		end
	else
		for k,v in ipairs(action.inputs) do
			local input = entInputs[v]
			if not input then
				ErrorNoHalt("Wire Gate (" .. selfTbl.action .. ") error: Missing input! (" .. k .. "," .. v .. ")\n")
				return {}
			end

			if as_names then
				Args[k] = IsValid(input.Src) and (input.Src.WireName or input.Src.WireDebugName) or v
			else
				Args[k] = IsValid(input.Src) and input.Value or WireLib.GetDefaultForType(entInputs[v].Type)
			end
		end
	end

	return Args
end

function ENT:GetActionOutputs()
	if self.Action.outputs then
		local result = {}
		for _,v in ipairs(self.Action.outputs) do
			result[v] = self.Outputs[v].Value or WireLib.GetDefaultForType(self.Outputs[v].Type)
		end

		return result
	end

	return self.Outputs.Out.Value or WireLib.GetDefaultForType(self.Outputs.Out.Type)
end

function WireLib.MakeWireGate(pl, Pos, Ang, model, action, noclip, frozen, nocollide)
	if not GateActions[action] then return end
	if GateActions[action].is_banned then return end

	return WireLib.MakeWireEnt(pl, { Class = "gmod_wire_gate", Pos=Pos, Angle=Ang, Model=model }, action, noclip)
end
duplicator.RegisterEntityClass("gmod_wire_gate", WireLib.MakeWireGate, "Pos", "Ang", "Model", "action", "noclip")
