ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire EGP HUD"
ENT.Author         = "Divran"
ENT.Contact        = "Divran @ Wiremod"
ENT.Purpose        = "EGP Hud"
ENT.Instructions   = "WireLink To E2"

ENT.Spawnable      = false
ENT.IsEGP = true


function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Resolution")
end