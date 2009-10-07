ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Socket"
ENT.Author          = "UnDeR_SEEG"
ENT.Contact         = "facepunch forums"
ENT.Purpose         = "socket receives plug"
ENT.Instructions    = "move a plug close to a socket to plug it in, and the signal will be carried through!"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:GetOffset( vec )
	local offset = vec

	local ang = self.Entity:GetAngles()
	local stackdir = ang:Up()
	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return self.Entity:GetPos() + stackdir * 2 + offset
end
