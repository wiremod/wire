--Wire graphics tablet  by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow

ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Graphics Tablet"
ENT.Author          = "greenarrow"
ENT.Contact         = "http://forums.facepunchstudios.com/greenarrow"
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:OnRemove()
end

function ENT:SetupParams()
	self.workingDistance = 64
end
