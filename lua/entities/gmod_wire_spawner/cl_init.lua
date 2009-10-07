
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include('shared.lua')

function ENT:Draw()
	self.BaseClass.Draw(self)
	self.Entity:DrawModel()
end
