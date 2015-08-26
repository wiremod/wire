-- Wire Trigger created by mitterdoo
AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Name = "Wire Trigger Entity"
ENT.Author = "mitterdoo"

function ENT:Initialize()

	if SERVER then
		self.EntsLookup = {}
		self.EntsInside = {}
	end

end
function ENT:SetupDataTables()

	self:NetworkVar( "Entity", 0, "TriggerEntity" )

end

function ENT:Reset()
	self.EntsInside = {}
	self.EntsLookup = {}

	local owner = self:GetTriggerEntity()
	if not IsValid( owner ) then return end
	WireLib.TriggerOutput( owner, "EntCount", 0 )
	WireLib.TriggerOutput( owner, "Entities", self.EntsInside )
end

function ENT:StartTouch( ent )

	local owner = self:GetTriggerEntity()
	if not IsValid( owner ) then return end
	if ent == owner then return end -- this never happens but just in case...
	if owner:GetFilter() == 1 and not ent:IsPlayer() or owner:GetFilter() == 2 and ent:IsPlayer() then return end
	local ply = ent:IsPlayer() and ent
	if owner:GetOwnerOnly() and ( WireLib.GetOwner( ent ) or ply ) ~= WireLib.GetOwner( owner ) then return end

	self.EntsInside[ #self.EntsInside+1 ] = ent
	self.EntsLookup[ ent ] = true

	WireLib.TriggerOutput( owner, "EntCount", #self.EntsInside )
	WireLib.TriggerOutput( owner, "Entities", self.EntsInside )

end
function ENT:EndTouch( ent )

	local owner = self:GetTriggerEntity()
	if not IsValid( owner ) then return end
	if not self.EntsLookup[ ent ] then return end

	for i = 1, #self.EntsInside do 
		if self.EntsInside[ i ] == ent then
			table.remove( self.EntsInside, i ) 
			self.EntsLookup[ ent ] = nil
		end 
	end
	
	WireLib.TriggerOutput( owner, "EntCount", #self.EntsInside )
	WireLib.TriggerOutput( owner, "Entities", self.EntsInside )

end
