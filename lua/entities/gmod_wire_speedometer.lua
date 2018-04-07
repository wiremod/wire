AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Speedometer"
ENT.WireDebugName	= "Speedo"

function ENT:GetXYZMode()
	return self:GetNWBool( 0 )
end

function ENT:GetAngVel()
	return self:GetNWBool( 1 )
end

function ENT:SetModes( XYZMode, AngVel )
	self:SetNWBool( 0, XYZMode )
	self:SetNWBool( 1, AngVel )
end

if CLIENT then
	function ENT:Think()
		BaseClass.Think(self)

		local txt
		if (self:GetXYZMode()) then
			local vel = self:WorldToLocal(self:GetVelocity()+self:GetPos())
			txt =  "Velocity = " .. math.Round((-vel.y or 0)*1000)/1000 .. "," .. math.Round((vel.x or 0)*1000)/1000 .. "," .. math.Round((vel.z or 0)*1000)/1000
		else
			local vel = self:GetVelocity():Length()
			txt =  "Speed = " .. math.Round((vel or 0)*1000)/1000
		end

		--sadly self:GetPhysicsObject():GetAngleVelocity() does work client side, so read out is unlikely
		/*if (self:GetAngVel()) then
			local ang = self:GetPhysicsObject():GetAngleVelocity()
			txt = txt .. "\nAngVel = P " .. math.Round((ang.y or 0)*1000)/1000 .. ", Y " .. math.Round((ang.z or 0)*1000) /1000 .. ", R " .. math.Round((ang.x or 0)*1000)/1000
		end*/

		self:SetOverlayText( txt )

		self:NextThink(CurTime()+0.04)
		return true
	end

	return  -- No more client
end

local MODEL = Model("models/jaanus/wiretool/wiretool_speed.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out", "MPH", "KPH" })
end

function ENT:Setup( xyz_mode, AngVel )
	self.z_only = xyz_mode --was renamed but kept for dupesaves
	self.XYZMode = xyz_mode
	self.AngVel = AngVel
	self:SetModes( xyz_mode,AngVel )

	local outs = {}
	if (xyz_mode) then
		outs = { "X", "Y", "Z" }
	else
		outs = { "Out", "MPH",  "KPH", }
	end
	if (AngVel) then
		table.Add(outs, {"AngVel_P", "AngVel_Y", "AngVel_R" } )
	end
	Wire_AdjustOutputs(self, outs)
end

function ENT:Think()
	BaseClass.Think(self)

	if (self.XYZMode) then
		local vel = self:WorldToLocal(self:GetVelocity()+self:GetPos())
		if (COLOSSAL_SANDBOX) then vel = vel * 6.25 end
		Wire_TriggerOutput(self, "X", -vel.y)
		Wire_TriggerOutput(self, "Y", vel.x)
		Wire_TriggerOutput(self, "Z", vel.z)
	else
		local vel = self:GetVelocity():Length()
		if (COLOSSAL_SANDBOX) then vel = vel * 6.25 end
		Wire_TriggerOutput(self, "Out", vel) // vel = Source Units / sec, Source Units = Inch * 0.75 , more info here: http://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference
		Wire_TriggerOutput(self, "MPH", vel * 3600 / 63360 * 0.75)
		Wire_TriggerOutput(self, "KPH", vel * 3600 * 0.0000254 * 0.75)
	end

	if (self.AngVel) then
		local ang = self:GetPhysicsObject():GetAngleVelocity()
		Wire_TriggerOutput(self, "AngVel_P", ang.y)
		Wire_TriggerOutput(self, "AngVel_Y", ang.z)
		Wire_TriggerOutput(self, "AngVel_R", ang.x)
	end

	self:NextThink(CurTime()+0.04)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_speedometer", WireLib.MakeWireEnt, "Data", "z_only", "AngVel")
