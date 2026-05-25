AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire FX Emitter"
ENT.WireDebugName	= "FX Emitter"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "On" )
	self:NetworkVar( "Int", 0, "Effect" )
	self:NetworkVar( "Float", 0, "Delay" )
	self:NetworkVar( "Vector", 0, "FXDir" )
end

function ENT:GetFXPos()
	return self:GetPos()
end

-- Effect registration

ENT.Effects				= {}
ENT.fxcount = 0
local fx_emitter = ENT

ComboBox_Wire_FX_Emitter_Options = {}

function AddFXEmitterEffect(name, func, nicename)
	fx_emitter.fxcount = fx_emitter.fxcount+1
	// Maintain a global reference for these effects
	ComboBox_Wire_FX_Emitter_Options[name] = fx_emitter.fxcount
	if CLIENT then
		fx_emitter.Effects[fx_emitter.fxcount] = func
		language.Add( "wire_fx_emitter_"..name, nicename )
	end
end

-- Modular effect adding.. stuff
include( "wire/fx_emitter_default.lua" )


if CLIENT then
	ENT.Delay = 0.05

	function ENT:Draw()
		// Don't draw if we are in camera mode
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()
		if ( wep:IsValid() ) then
			local weapon_name = wep:GetClass()
			if ( weapon_name == "gmod_camera" ) then return end
		end

		BaseClass.Draw( self )
	end

	function ENT:Think()
		if not self:GetOn() then return end

		if ( self.Delay > CurTime() ) then return end
		self.Delay = CurTime() + self:GetDelay()

		local Effect = self:GetEffect()

		// Missing effect... replace it if possible :/
		if ( not self.Effects[ Effect ] ) then if ( self.Effects[1] ) then Effect = 1 else return end end

		local Angle = self:GetAngles()

		local FXDir = self:GetFXDir()
		if FXDir and not FXDir:IsZero() then Angle = FXDir:Angle() else self:GetUp():Angle() end

		local FXPos = self:GetFXPos()
		if not FXPos or FXDir:IsZero() then FXPos=self:GetPos() + Angle:Forward() * 12 end

		local b, e = pcall( self.Effects[Effect], FXPos, Angle )

		if (not b) then
			// Report the error
			Print(self.Effects)
			Print(FXPos)
			Print(Angle)
			Msg("Error in Emitter "..tostring(Effect).."\n -> "..tostring(e).."\n")

			// Remove the naughty function
			self.Effects[ Effect ] = nil
		end
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:SetModel( "models/props_lab/tpplug.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	self.Inputs = WireLib.CreateInputs(self, {"On", "Effect", "Delay", "Direction [VECTOR]"})
end

function ENT:Setup(delay, effect)
	if delay then self:SetDelay(delay) end
	if effect then self:SetEffect(effect) end
end

function ENT:TriggerInput( inputname, value, iter )
	if inputname == "Direction" then
		self:SetFXDir(value:GetNormal())
	elseif inputname == "Effect" then
		self:SetEffect(math.Clamp(value - value % 1, 1, self.fxcount))
	elseif inputname == "On" then
		self:SetOn(value ~= 0)
	elseif inputname == "Delay" then
		self:SetDelay(math.Clamp(value, 0.05, 20))
	--elseif (inputname == "Position") then -- removed for excessive mingability
	--	self:SetFXPos(value)
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	-- Old dupes stored this info here rather than as RegisterEntityClass vars
	if info.Effect then self:SetEffect(info.Effect) end
	if info.Delay then self:SetDelay(info.Delay) end
end

duplicator.RegisterEntityClass("gmod_wire_fx_emitter", WireLib.MakeWireEnt, "Data", "delay", "effect" )
-- Note: delay and effect are here for backwards compatibility, they're now stored in the DataTable
