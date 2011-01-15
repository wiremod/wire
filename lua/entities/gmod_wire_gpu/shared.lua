ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire GPU"
ENT.Author          = "Black Phoenix"
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:InitGraphicTablet()
	local model = tostring(self:GetModel())

	if WireGPU_Monitors[model] then
		self.x1 = WireGPU_Monitors[model].x1
		self.x2 = WireGPU_Monitors[model].x2
		self.y1 = WireGPU_Monitors[model].y1
		self.y2 = WireGPU_Monitors[model].y2
		self.z  = WireGPU_Monitors[model].z
	else
		self.x1 = 0
		self.x2 = 1
		self.y1 = 0
		self.y2 = 1
		self.z  = 0
	end

	self.res = 0.05
	self.workingDistance = 64

	self.x = self.x1 / self.res
	self.y = -self.y1 / self.res
	self.x0 = self.x + (self.x2 / self.res) - self.x * 2
	self.y0 = self.y + (-self.y2 / self.res) - self.y * 2
	self.w = (self.x2 / self.res) - self.x
	self.h = math.abs((self.y2 / self.res) + self.y)

	self.ox = 5
	self.oy = 5
end
