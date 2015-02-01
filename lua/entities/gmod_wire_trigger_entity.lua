// Wire Trigger created by mitterdoo
AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Name = "Wire Trigger Entity"
ENT.Author = "mitterdoo"

function ENT:Initialize()

	if SERVER then
		self.EntsInside = {}
	end

end
function ENT:SetupDataTables()

	self:NetworkVar( "Entity", 0, "TriggerEntity" )

end
function ENT:StartTouch( ent )

	local owner = self:GetTriggerEntity()
	if ent == owner then return end // this never happens but just in case...
	if owner:GetFilter() == 1 and !ent:IsPlayer() or owner:GetFilter() == 2 and ent:IsPlayer() then return end
	if owner:GetOwnerOnly() and WireLib.GetOwner( ent ) != WireLib.GetOwner( owner ) then return end
	table.insert( self.EntsInside, ent )
	Wire_TriggerOutput( self:GetTriggerEntity(), "EntCount", #self.EntsInside )
	Wire_TriggerOutput( self:GetTriggerEntity(), "Entities", self.EntsInside )

end
function ENT:EndTouch( ent )

	if !table.HasValue( self.EntsInside, ent ) then return end
	table.remove( self.EntsInside, table.KeyFromValue( self.EntsInside, ent ) )
	Wire_TriggerOutput( self:GetTriggerEntity(), "EntCount", #self.EntsInside )
	Wire_TriggerOutput( self:GetTriggerEntity(), "Entities", self.EntsInside )

end
