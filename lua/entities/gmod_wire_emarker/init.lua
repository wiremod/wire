
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "EMarker"
ENT.OverlayDelay = 0

local MODEL = Model( "models/jaanus/wiretool/wiretool_siren.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	Add_EntityMarker(self.Entity)

	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Entity" }, { "ENTITY" })
	self:SetOverlayText( "No Mark selected" )
end

function ENT:LinkEMarker(mark)
	if mark then self.mark = mark end
	if (!self.mark || !self.mark:IsValid()) then self:SetOverlayText( "No Mark selected" ) return end
	Wire_TriggerOutput(self.Entity, "Entity", self.mark)
	self:SetOverlayText( "Linked - " .. self.mark:GetModel() )
end

function ENT:UnLinkEMarker()
	self.mark = null
	Wire_TriggerOutput(self.Entity, "Entity", null)
	self:SetOverlayText( "No Mark selected" )
end

// Advanced Duplicator Support

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if ( self.mark ) and ( self.mark:IsValid() ) then
	    info.mark = self.mark:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.mark) then
		self.mark = GetEntByID(info.mark)
		if (!self.mark) then
			self.mark = ents.GetByIndex(info.mark)
		end
	end
	self:LinkEMarker()
end
