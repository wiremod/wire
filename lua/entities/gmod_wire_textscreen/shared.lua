--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Text Screen"
ENT.Author          = "greenarrow"
ENT.Contact         = "http://forums.facepunchstudios.com/greenarrow"
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetText(text)
	self.Entity:SetNetworkedString("TLine", text)
end

function ENT:GetText()
	return self.Entity:GetNetworkedString("TLine")
end


function ENT:GetConfig()
	self.chrPerLine = self.Entity:GetNetworkedInt("chrpl")
	self.textJust = self.Entity:GetNetworkedInt("textjust")
	self.tRed = self.Entity:GetNetworkedInt("colourr")
	self.tGreen = self.Entity:GetNetworkedInt("colourg")
	self.tBlue = self.Entity:GetNetworkedInt("colourb")
	return
end

function ENT:SetConfig()
	self.Entity:SetNetworkedInt("chrpl", self.chrPerLine)
	self.Entity:SetNetworkedInt("textjust", self.textJust)
	self.Entity:SetNetworkedInt("colourr", self.tRed)
	self.Entity:SetNetworkedInt("colourg", self.tGreen)
	self.Entity:SetNetworkedInt("colourb", self.tBlue)
end
