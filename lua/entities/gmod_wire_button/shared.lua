ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Button"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "On", { KeyName = "on", Edit = { type = "Bool" } } )
end
