
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Satellite Dish"


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:ShowOutput()
end


function ENT:ShowOutput()
	if IsValid(self.Transmitter) then
		self:SetOverlayText( "Linked" )
	else
		self:SetOverlayText( "Unlinked" )
	end
end

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
