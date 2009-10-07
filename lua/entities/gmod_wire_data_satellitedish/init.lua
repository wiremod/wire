
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Satellite Dish"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self:ShowOutput()
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:ShowOutput()
	if IsValid(self.Transmitter) then
		self:SetOverlayText( "Satellite Dish: Linked" )
	else
		self:SetOverlayText( "Satellite Dish: Unlinked" )
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

// Advanced Duplicator Support

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if ( self.Transmitter ) and ( self.Transmitter:IsValid() ) then
	    info.Transmitter = self.Transmitter:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Transmitter) then
		self.Transmitter = GetEntByID(info.Transmitter)
		if (!self.Transmitter) then
			self.Transmitter = ents.GetByIndex(info.Transmitter)
		end
	end
	self:ShowOutput()
end
