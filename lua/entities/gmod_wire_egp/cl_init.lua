include('shared.lua')

ENT.gmod_wire_egp = true

function ENT:Initialize()
	self.GPU = GPULib.WireGPU( self )
	self.GPU.texture_filtering = TEXFILTER.ANISOTROPIC
	self.GPU.translucent = self:GetTranslucent()

	self.RenderTable = table.Copy(EGP.HomeScreen)
	self:_EGP_Update()
	self.RenderTable = {}
end

function ENT:EGP_Update()
	self.NeedsUpdate = true
end

local egpDraw = EGP.Draw
function ENT:_EGP_Update()
	self.NeedsUpdate = false

	self.GPU:RenderToGPU( function()
		render.Clear( 0, 0, 0, 0, true )
		egpDraw(self)
	end)
end

function ENT:GetEGPMatrix()
	return Matrix()
end

function ENT:DrawEntityOutline() end

local VECTOR_1_1_1 = Vector(1, 1, 1)
function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)

	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(VECTOR_1_1_1)
	if self.NeedsUpdate then
		self:_EGP_Update()
	end

	self.GPU:Render(0,0,1024,1024,nil,-0.5,-0.5)
	render.SetToneMappingScaleLinear(tone)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end
