AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Button"
ENT.OutputEntID = false
ENT.EntToOutput = NULL

local anims = {
	-- ["model"] = { on_anim, off_anim }
	["models/props/switch001.mdl"] = { 2, 1 },
	["models/props_combine/combinebutton.mdl"] = { 3, 2 },
	["models/props_mining/control_lever01.mdl"] = { 1, 4 },
	["models/props_mining/freightelevatorbutton01.mdl"] = { 1, 2 },
	["models/props_mining/freightelevatorbutton02.mdl"] = { 1, 2 },
	["models/props_mining/switch01.mdl"] = { 1, 2 },
	["models/bull/buttons/rocker_switch.mdl"] = { 1, 2 },
	["models/bull/buttons/toggle_switch.mdl"] = { 1, 2 },
	["models/bull/buttons/key_switch.mdl"] = { 1, 2 },
	["models/props_mining/switch_updown01.mdl"] = { 2, 3 },
}

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
	self.Inputs = Wire_CreateInputs(self.Entity, { "Set" })
	local anim = anims[self:GetModel()]
	if anim then self:SetSequence(anim[2]) end
end

function ENT:TriggerInput(iname, value)
	if iname == "Set" then
		if (self.toggle) then
			self:Switch(value ~= 0)
		end
	end
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	if (self.PrevUser) and (self.PrevUser:IsValid()) then return end
	if self.OutputEntID then
		self.EntToOutput = ply
	end
	if (self:GetOn()) then
		if (self.toggle) then self:Switch(false) end

		return
	end

	self:Switch(true)
	self.PrevUser = ply
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ( self:GetOn() ) then
		if (not self.PrevUser)
		or (not self.PrevUser:IsValid())
		or (not self.podpress and not self.PrevUser:KeyDown(IN_USE))
		or (self.podpress and not self.PrevUser:KeyDown( IN_ATTACK )) then
		    if (not self.toggle) then
				self:Switch(false)
			end

			self.PrevUser = nil
			self.podpress = nil
		end

		self.Entity:NextThink(CurTime()+0.05)
		return true
	end
end

function ENT:Setup(toggle, value_off, value_on, description, entityout)
	self.toggle = toggle
	self.value_off = value_off
	self.value_on = value_on
	self.Value = value_off
	self.entityout = entityout
	self:SetOn( false )

	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self.Entity, "Out", self.value_off)

	if entityout then
		WireLib.AdjustSpecialOutputs(self.Entity, { "Out", "EntID" , "Entity" }, { "NORMAL", "NORMAL" , "ENTITY" })
		Wire_TriggerOutput(self.Entity, "EntID", 0)
		Wire_TriggerOutput(self.Entity, "Entity", nil)
		self.OutputEntID=true
	else
		Wire_AdjustOutputs(self.Entity, { "Out" })
		self.OutputEntID=false
	end

	if toggle then
		Wire_AdjustInputs(self.Entity, { "Set" })
	else
		Wire_AdjustInputs(self.Entity, {})
	end
end

function ENT:Switch(on)
	if (not self.Entity:IsValid()) then return end

	self:SetOn( on )

	if (on) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on

		local anim = anims[self:GetModel()]
		if anim then self:SetSequence(anim[1]) end
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off

		local anim = anims[self:GetModel()]
		if anim then self:SetSequence(anim[2]) end

		if self.OutputEntID then self.EntToOutput = NULL end
	end

	Wire_TriggerOutput(self.Entity, "Out", self.Value)
	if self.OutputEntID then
		Wire_TriggerOutput(self.Entity, "EntID", self.EntToOutput:EntIndex())
		Wire_TriggerOutput(self.Entity, "Entity", self.EntToOutput)
	end
	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.value_off .. " - " .. self.value_on .. ") = " .. value )
end


function MakeWireButton( pl, Pos, Ang, model, toggle, value_off, value_on, description, entityout, frozen )
	if ( !pl:CheckLimit( "wire_buttons" ) ) then return false end

	local wire_button = ents.Create( "gmod_wire_button" )
	if (!wire_button:IsValid()) then return false end

	wire_button:SetModel(model)
	wire_button:SetAngles(Ang)
	wire_button:SetPos(Pos)
	wire_button:Spawn()

	if wire_button:GetPhysicsObject():IsValid() then
		local Phys = wire_button:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_button:Setup(toggle, value_off, value_on, description, entityout )
	wire_button:SetPlayer(pl)
	wire_button.pl = pl

	pl:AddCount( "wire_buttons", wire_button )

	return wire_button
end

duplicator.RegisterEntityClass("gmod_wire_button", MakeWireButton, "Pos", "Ang", "Model", "toggle", "value_off", "value_on", "description", "entityout", "frozen" )
