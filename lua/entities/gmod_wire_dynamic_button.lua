AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Dynamic Button"
ENT.WireDebugName	= "Dynamic Button"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "On" )
end


if CLIENT then
	local halo_ent, halo_blur

	function ENT:Draw()
		self:DoNormalDraw(true,false)
		if LocalPlayer():GetEyeTrace().Entity == self and EyePos():Distance( self:GetPos() ) < 512 then
			if self:GetOn() then
				halo_ent = self
				halo_blur = 4 + math.sin(CurTime()*20)*2
			else
				self:DrawEntityOutline()
			end
		end
		Wire_Render(self)
	end

	hook.Add("PreDrawHalos", "Wiremod_dynbutton_overlay_halos", function()
		if halo_ent then
			halo.Add({halo_ent}, Color(255,100,100), halo_blur, halo_blur, 1, true, true)
			halo_ent = nil
		end
	end)

	return  -- No more client
end

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
		if self.toggle then
			self:Switch(value ~= 0)
			self.PrevUser = nil
			self.podpress = nil
		end
	end
end

function ENT:Use(ply, caller)
	if not ply:IsPlayer() then return end
	if self.PrevUser and self.PrevUser:IsValid() then return end
	if self.OutputEntID then
		self.EntToOutput = ply
	end
	if self:GetOn() then
		if self.toggle then self:Switch(false) end

		return
	end
	if IsValid(caller) and caller:GetClass() == "gmod_wire_pod" then
		self.podpress = true
	end

	self:Switch(true)
	self.PrevUser = ply
end

function ENT:Think()
	BaseClass.Think(self)

	if self:GetOn() then
		if not self.PrevUser
		or not self.PrevUser:IsValid()
		or not self.podpress and not self.PrevUser:KeyDown(IN_USE)
		or self.podpress and not self.PrevUser:KeyDown( IN_ATTACK ) then
		    if not self.toggle then
				self:Switch(false)
			end

			self.PrevUser = nil
			self.podpress = nil
		end

		self:NextThink(CurTime()+0.05)
		return true
	end
end

function ENT:Setup(toggle, value_on, value_off, description, entityout, material_on, material_off, on_r, on_g, on_b, off_r, off_g, off_b )
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
		WireLib.AdjustOutputs(self, {
			"Out (The button's main output) [NORMAL]",
			"EntID (The entity ID of the player who pressed the button) [NORMAL]" ,
			"Entity (The player who pressed the button) [ENTITY]"
		})
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
	if not self:IsValid() then return end

	self:SetOn( on )

	if on then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
        if self.material_on ~= "" then self:SetMaterial(self.material_on) end
		self:SetColor(Color(self.on_r, self.on_g, self.on_b, 255))
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
		if self.material_off ~= "" then self:SetMaterial(self.material_off) end
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

duplicator.RegisterEntityClass("gmod_wire_dynamic_button", WireLib.MakeWireEnt, "Data", "toggle", "value_on", "value_off", "description", "entityout", "material_on", "material_off", "on_r", "on_g", "on_b", "off_r", "off_g", "off_b" )
