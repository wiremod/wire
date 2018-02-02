-- Wire Trigger created by mitterdoo
AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Trigger"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Trigger"

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "TriggerSize" )
	self:NetworkVar( "Vector", 1, "TriggerOffset" )
	self:NetworkVar( "Entity", 0, "TriggerEntity" )
	self:NetworkVar( "Int", 0, "Filter" )
	self:NetworkVar( "Bool", 0, "OwnerOnly" )
end

if CLIENT then
	function ENT:GetOverlayData()
		local size = self:GetTriggerSize()
		local offset = self:GetTriggerOffset()

		local txt = "Size: " .. string.format( "(%.2f,%.2f,%.2f)", size.x, size.y, size.z ) .. "\n"
		txt = txt .. "Offset: " .. string.format( "(%.2f,%.2f,%.2f)", offset.x, offset.y, offset.z ) .. "\n"
		txt = txt .. "Triggered by: " .. (
			self:GetFilter() == 0 and "All Entities" or
			self:GetFilter() == 1 and "Only Players" or
			self:GetFilter() == 2 and "Only Props"
		)

		return {txt=txt}
	end

	return -- No more client
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject() if (phys:IsValid()) then phys:Wake() end

	self.Outputs = WireLib.CreateOutputs(self, { "EntCount", "Entities [ARRAY]" })
end

function ENT:Setup( model, filter, owneronly, sizex, sizey, sizez, offsetx, offsety, offsetz )

	filter = math.Clamp( filter, 0, 2 )
	sizex = math.Clamp( sizex, -1000, 1000 )
	sizey = math.Clamp( sizey, -1000, 1000 )
	sizez = math.Clamp( sizez, -1000, 1000 )
	offsetx = math.Clamp( offsetx, -1000, 1000 )
	offsety = math.Clamp( offsety, -1000, 1000 )
	offsetz = math.Clamp( offsetz, -1000, 1000 )
	self.model = model
	self.filter = filter
	self.owneronly = owneronly
	self.sizex = sizex
	self.sizey = sizey
	self.sizez = sizez
	self.offsetx = offsetx
	self.offsety = offsety
	self.offsetz = offsetz

	self:SetOwnerOnly( tobool( owneronly ) )
	self:SetModel( model )
	self:SetFilter( filter )
	self:SetTriggerSize( Vector( sizex, sizey, sizez ) )
	self:SetTriggerOffset( Vector( offsetx, offsety, offsetz ) )


	local mins = self:GetTriggerSize() / -2
	local maxs = self:GetTriggerSize() / 2

	local oldtrig = self:GetTriggerEntity()
	if IsValid( oldtrig ) then
		oldtrig:SetCollisionBounds( mins, maxs )
		oldtrig:SetPos( self:LocalToWorld( self:GetTriggerOffset() ) )
		oldtrig:Reset()
	else
		local trig = ents.Create( "gmod_wire_trigger_entity" )
		trig:SetPos( self:LocalToWorld( self:GetTriggerOffset() ) )
		trig:SetAngles( self:GetAngles() )
		trig:PhysicsInit( SOLID_BBOX )
		trig:SetMoveType( MOVETYPE_VPHYSICS )
		trig:SetSolid( SOLID_BBOX )
		trig:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
		trig:SetParent( self )
		trig:Spawn()

		trig:SetCollisionBounds( mins, maxs )
		trig:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
		trig:SetNoDraw( true )
		trig:SetTrigger( true )
		self:SetTriggerEntity( trig )
		trig:SetTriggerEntity( self )
		self:DeleteOnRemove( trig )
	end
end

duplicator.RegisterEntityClass("gmod_wire_trigger", WireLib.MakeWireEnt, "Data", "model", "filter", "owneronly", "sizex", "sizey", "sizez", "offsetx", "offsety", "offsetz" )
