AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Speedo"

local MODEL = Model("models/jaanus/wiretool/wiretool_speed.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out", "MPH", "KPH" })
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
	Wire_AdjustOutputs(self.Entity, outs)
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (self.XYZMode) then
		local vel = self.Entity:WorldToLocal(self.Entity:GetVelocity()+self.Entity:GetPos())
		if (COLOSSAL_SANDBOX) then vel = vel * 6.25 end
		Wire_TriggerOutput(self.Entity, "X", -vel.y)
		Wire_TriggerOutput(self.Entity, "Y", vel.x)
		Wire_TriggerOutput(self.Entity, "Z", vel.z)
	else
		local vel = self.Entity:GetVelocity():Length()
		if (COLOSSAL_SANDBOX) then vel = vel * 6.25 end
		Wire_TriggerOutput(self.Entity, "Out", vel)
		Wire_TriggerOutput(self.Entity, "MPH", vel / 17.6)
		Wire_TriggerOutput(self.Entity, "KPH", vel * 0.09144)
	end

	if (self.AngVel) then
		local ang = self.Entity:GetPhysicsObject():GetAngleVelocity()
		Wire_TriggerOutput(self.Entity, "AngVel_P", ang.y)
		Wire_TriggerOutput(self.Entity, "AngVel_Y", ang.z)
		Wire_TriggerOutput(self.Entity, "AngVel_R", ang.x)
	end

	self.Entity:NextThink(CurTime()+0.04)
	return true
end


function MakeWireSpeedometer( pl, Pos, Ang, model, xyz_mode, AngVel, nocollide, frozen )
	if !pl:CheckLimit( "wire_speedometers" ) then return false end

	local wire_speedometer = ents.Create("gmod_wire_speedometer")
	if !wire_speedometer:IsValid() then return false end
		wire_speedometer:SetAngles(Ang)
		wire_speedometer:SetPos(Pos)
		wire_speedometer:SetModel(model or MODEL)
	wire_speedometer:Spawn()

	wire_speedometer:Setup(xyz_mode, AngVel)
	wire_speedometer:SetPlayer(pl)
	wire_speedometer.pl = pl

	if wire_speedometer:GetPhysicsObject():IsValid() then
		wire_speedometer:GetPhysicsObject():EnableMotion(!frozen)
		if nocollide == true then wire_speedometer:GetPhysicsObject():EnableCollisions(false) end
	end

	pl:AddCount( "wire_speedometers", wire_speedometer )
	pl:AddCleanup( "gmod_wire_speedometer", wire_speedometer )

	return wire_speedometer
end
duplicator.RegisterEntityClass("gmod_wire_speedometer", MakeWireSpeedometer, "Pos", "Ang", "Model", "z_only", "AngVel", "nocollide", "frozen")
