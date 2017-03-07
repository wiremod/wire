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
	
	self.action = action

	self.WireDebugName = gate.name

	WireLib.AdjustSpecialInputs(self, gate.inputs, gate.inputtypes )
	if (gate.outputs) then
		WireLib.AdjustSpecialOutputs(self, gate.outputs, gate.outputtypes)
	else
		--Wire_AdjustOutputs(self, { "Out" })
		WireLib.AdjustSpecialOutputs(self, { "Out" }, gate.outputtypes)
	end

	if (gate.reset) then
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

	if (noclip) then
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
	self.noclip = noclip

	self.Action = gate
	self.PrevValue = nil

	--self.Action.inputtypes = self.Action.inputtypes or {}

	self:CalcOutput()
	self:ShowOutput()
end


function ENT:OnInputWireLink(iname, itype, src, oname, otype)
	if (self.Action) and (self.Action.OnInputWireLink) then
		self.Action.OnInputWireLink(self, iname, itype, src, oname, otype)
	end
end

function ENT:OnOutputWireLink(oname, otype, dst, iname, itype)
	if (self.Action) and (self.Action.OnOutputWireLink) then
		self.Action.OnOutputWireLink(self, oname, otype, dst, iname, itype)
	end
end

function ENT:TriggerInput(iname, value, iter)
	if (self.Action) and (not self.Action.timed) then
		self:CalcOutput(iter)
		self:ShowOutput()
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Action) and (self.Action.timed) then
		self:CalcOutput()
		self:ShowOutput()

		self:NextThink(CurTime()+0.02)
		return true
	end
end


function ENT:CalcOutput(iter)
	if (self.Action) and (self.Action.output) then
		if (self.Action.outputs) then
			local result = { self.Action.output(self, unpack(self:GetActionInputs())) }

			for k,v in ipairs(self.Action.outputs) do
				Wire_TriggerOutput(self, v, result[k] or WireLib.DT[ self.Outputs[v].Type ].Zero, iter)
			end
		else
			local value = self.Action.output(self, unpack(self:GetActionInputs())) or WireLib.DT[ self.Outputs.Out.Type ].Zero

			Wire_TriggerOutput(self, "Out", value, iter)
		end
	end
end

function ENT:ShowOutput()
	local txt = ""

	if (self.Action) then
		txt = (self.Action.name or "No Name")
		if (self.Action.label) then
			txt = txt.."\n"..self.Action.label(self:GetActionOutputs(), unpack(self:GetActionInputs(Wire_EnableGateInputValues:GetBool())))
		end
	else
		txt = "Invalid gate!"
	end

	self:SetOverlayText(txt)
end


function ENT:OnRestore()
	self.Action = GateActions[self.action]

	self.BaseClass.OnRestore(self)
end


function ENT:GetActionInputs(as_names)
	local Args = {}

	if (self.Action.compact_inputs) then
		-- If a gate has compact inputs (like Arithmetic - Add), nil inputs are truncated so {0, nil, nil, 5, nil, 1} becomes {0, 5, 1}
		for k,v in ipairs(self.Action.inputs) do
		    local input = self.Inputs[v]
			if (not input) then
				ErrorNoHalt("Wire Gate ("..self.action..") error: Missing input! ("..k..","..v..")")
				return {}
			end

			if IsValid(input.Src) then
				if (as_names) then
					table.insert(Args, input.Src.WireName or input.Src.WireDebugName or v)
				else
					table.insert(Args, input.Value)
				end
			end
		end

		while (#Args < self.Action.compact_inputs) do
			if (as_names) then
				table.insert(Args, self.Action.inputs[#Args+1] or "*Not enough inputs*")
			else
				--table.insert( Args, WireLib.DT[ (self.Action.inputtypes[#Args+1] or "NORMAL") ].Zero )
				table.insert( Args, WireLib.DT[ self.Inputs[ self.Action.inputs[#Args+1] ].Type ].Zero )
			end
		end
	else
		for k,v in ipairs(self.Action.inputs) do
		    local input = self.Inputs[v]
			if (not input) then
				ErrorNoHalt("Wire Gate ("..self.action..") error: Missing input! ("..k..","..v..")")
				return {}
			end

			if (as_names) then
				Args[k] = IsValid(input.Src) and (input.Src.WireName or input.Src.WireDebugName) or v
			else
				Args[k] = IsValid(input.Src) and input.Value or WireLib.DT[ self.Inputs[v].Type ].Zero
			end
		end
	end

	return Args
end

function ENT:GetActionOutputs()
	if (self.Action.outputs) then
		local result = {}
		for _,v in ipairs(self.Action.outputs) do
		    result[v] = self.Outputs[v].Value or WireLib.DT[ self.Outputs[v].Type ].Zero
		end

		return result
	end

	return self.Outputs.Out.Value or WireLib.DT[ self.Outputs.Out.Type ].Zero
end

function MakeWireGate(pl, Pos, Ang, model, action, noclip, frozen, nocollide)
	if not GateActions[action] then return end
	if GateActions[action].is_banned then return end

	return WireLib.MakeWireEnt(pl, { Class = "gmod_wire_gate", Pos=Pos, Angle=Ang, Model=model }, action, noclip)
end
duplicator.RegisterEntityClass("gmod_wire_gate", MakeWireGate, "Pos", "Ang", "Model", "action", "noclip")
