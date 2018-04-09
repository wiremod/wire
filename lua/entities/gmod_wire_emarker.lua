AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Entity Marker"
ENT.WireDebugName = "EMarker"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Entity" }, { "ENTITY" })
	self:SetOverlayText( "No Mark selected" )
end

function ENT:LinkEMarker(mark)
	if mark then self.mark = mark end
	if not IsValid(self.mark) then self:SetOverlayText( "No Mark selected" ) return end
	self.mark:CallOnRemove("EMarker.UnLink", function(ent)
		if IsValid(self) and self.mark == ent then self:UnLinkEMarker() end
	end)
	Wire_TriggerOutput(self, "Entity", self.mark)
	self:SetOverlayText( "Linked - " .. self.mark:GetModel() )
end

function ENT:UnLinkEMarker()
	self.mark = NULL
	Wire_TriggerOutput(self, "Entity", NULL)
	self:SetOverlayText( "No Mark selected" )
end

duplicator.RegisterEntityClass( "gmod_wire_emarker", WireLib.MakeWireEnt, "Data" )

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	if ( self.mark ) and ( self.mark:IsValid() ) then
	    info.mark = self.mark:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:LinkEMarker(GetEntByID(info.mark))
end
