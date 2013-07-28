AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Dynamic Button"
ENT.OutputEntID = false
ENT.EntToOutput = NULL

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
	self.Inputs = Wire_CreateInputs(self, { "Set" })
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
	if (self:IsOn()) then
		if (self.toggle) then self:Switch(false) end

		return
	end

	self:Switch(true)
	self.PrevUser = ply
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ( self:IsOn() ) then
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

		self:NextThink(CurTime()+0.05)
		return true
	end
end

function ENT:Setup(toggle, value_off, value_on, description, entityout, material_on, material_off, on_r, on_g, on_b, off_r, off_g, off_b )
	self.toggle = toggle
	self.value_off = value_off
	self.value_on = value_on
	self.Value = value_off
	self.entityout = entityout
    self.material_on = material_on
    self.material_off = material_off
	self:SetOn( false )
	self.on_r = on_r
	self.on_g = on_g
	self.on_b = on_b
	self.off_r = off_r
	self.off_g = off_g
	self.off_b = off_b

	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self, "Out", self.value_off)

    self:SetMaterial(self.material_off)
    self:SetColor(Color(self.off_r, self.off_g, self.off_b, 255))

	if entityout then
		WireLib.AdjustSpecialOutputs(self, { "Out", "EntID" , "Entity" }, { "NORMAL", "NORMAL" , "ENTITY" })
		Wire_TriggerOutput(self, "EntID", 0)
		Wire_TriggerOutput(self, "Entity", nil)
		self.OutputEntID=true
	else
		Wire_AdjustOutputs(self, { "Out" })
		self.OutputEntID=false
	end

	if toggle then
		Wire_AdjustInputs(self, { "Set" })
	else
		Wire_AdjustInputs(self, {})
	end
end

function ENT:Switch(on)
	if (not self:IsValid()) then return end

	self:SetOn( on )

	if (on) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
        self:SetMaterial(self.material_on)
		self:SetColor(Color(self.on_r, self.on_g, self.on_b, 255))

	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
		self:SetMaterial(self.material_off)
        self:SetColor(Color(self.off_r, self.off_g, self.off_b, 255))

		if self.OutputEntID then self.EntToOutput = NULL end
	end

	Wire_TriggerOutput(self, "Out", self.Value)
	if self.OutputEntID then
		Wire_TriggerOutput(self, "EntID", self.EntToOutput:EntIndex())
		Wire_TriggerOutput(self, "Entity", self.EntToOutput)
	end
	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.value_off .. " - " .. self.value_on .. ") = " .. value )
end


function MakeWireDynamicButton( pl, Pos, Ang, model, toggle, value_off, value_on, description, entityout, material_on, material_off, on_r, on_g, on_b, off_r, off_g, off_b, frozen )
	if ( !pl:CheckLimit( "wire_dynamic_buttons" ) ) then return false end

	local wire_dynamic_button = ents.Create( "gmod_wire_dynamic_button" )
	if (!wire_dynamic_button:IsValid()) then return false end

	wire_dynamic_button:SetModel(model)
	wire_dynamic_button:SetAngles(Ang)
	wire_dynamic_button:SetPos(Pos)
	wire_dynamic_button:Spawn()

	if wire_dynamic_button:GetPhysicsObject():IsValid() then
		local Phys = wire_dynamic_button:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_dynamic_button:Setup(toggle, value_off, value_on, description, entityout, material_on, material_off, on_r, on_g, on_b, off_r, off_g, off_b )
	wire_dynamic_button:SetPlayer(pl)
	wire_dynamic_button.pl = pl

	pl:AddCount( "wire_dynamic_buttons", wire_dynamic_button )

	return wire_dynamic_button
end

duplicator.RegisterEntityClass("gmod_wire_dynamic_button", MakeWireDynamicButton, "Pos", "Ang", "Model", "toggle", "value_off", "value_on", "description", "entityout", "material_on", "material_off", "on_r", "on_g", "on_b", "off_r", "off_g", "off_b", "frozen" )
