--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Text Screen"
ENT.Author          = "greenarrow"
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:InitializeShared()
	self.text = ""
	self.chrPerLine = 5
	self.textJust = 0
	self.valign = 0

	self.fgcolor = Color(255,255,255)
	self.bgcolor = Color(0,0,0)

	WireLib.umsgRegister(self)
end
