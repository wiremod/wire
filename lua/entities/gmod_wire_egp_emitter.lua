AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_egp" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

if CLIENT then

	ENT.gmod_wire_egp_emitter = true

	ENT.DrawOffsetPos = Vector(0, 0, 71)
	ENT.DrawOffsetAng = Angle(0, 0, 90)
	ENT.DrawScale     = 0.25

	function ENT:Initialize()
		self.GPU = GPULib.WireGPU( self )
		self.GPU.texture_filtering = TEXFILTER.ANISOTROPIC
		self.GPU.GetInfo = function()
			local pos = self:LocalToWorld(self.DrawOffsetPos)
			local ang = self:LocalToWorldAngles(self.DrawOffsetAng)
			return {RS = self.DrawScale, RatioX = 1, translucent = true}, pos, ang
		end
		self.RenderTable = {}
		self:EGP_Update( EGP.HomeScreen )
	end

	function ENT:Think()
		local dist = Vector(1,0,1)
		self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
	end

	function ENT:DrawEntityOutline() end

end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
