AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "EMarker"

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

function MakeWireEmarker( pl, Pos, Ang, model, nocollide )
	if (!pl:CheckLimit("wire_emarkers")) then return false end

	local wire_emarker = ents.Create("gmod_wire_emarker")
	wire_emarker:SetPos(Pos)
	wire_emarker:SetAngles(Ang)
	wire_emarker:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
	wire_emarker:Spawn()
	wire_emarker:Activate()

	wire_emarker:SetPlayer(pl)
	wire_emarker.pl = pl
	wire_emarker.nocollide = nocollide

	if ( nocollide == true ) then wire_emarker:GetPhysicsObject():EnableCollisions( false ) end

	pl:AddCount( "wire_emarkers", wire_emarker )

	return wire_emarker
end
duplicator.RegisterEntityClass( "gmod_wire_emarker", MakeWireEmarker, "Pos", "Ang", "Model", "nocollide" )
	

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
