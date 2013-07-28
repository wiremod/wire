ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Wire Entity"
ENT.Author = "Erkle"
ENT.Contact = "ErkleMad@gmail.com"
ENT.Purpose = "Base for all wired SEnts"
ENT.Instructions = ""

ENT.Spawnable = false
ENT.AdminOnly = false

ENT.IsWire = true
ENT.OverlayText = ""

function ENT:GetOverlayText()
	return self.OverlayText
end

function ENT:SetOverlayText( txt )
	self.OverlayText = txt
end
