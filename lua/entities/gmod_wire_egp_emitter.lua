AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_egp" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

ENT.gmod_wire_egp_emitter = true

local DrawOffsetPos = Vector(0, 0, 71)
local DrawOffsetAng = Angle(0, 0, 90)
local DrawScale     = 0.25

if SERVER then

	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:SetDrawOffsetPos(DrawOffsetPos)
		self:SetDrawOffsetAng(DrawOffsetAng)
		self:SetDrawScale(DrawScale)

		self.Inputs = WireLib.CreateSpecialInputs(self, { "Scale", "Position", "Angle" }, {"NORMAL", "VECTOR", "ANGLE"})
	end

	function ENT:TriggerInput(iname, value)
			if iname == "Scale" then
				self:SetDrawScale( math.Clamp(value * 0.25, 0.01, 0.5) )

			elseif iname == "Position" then
				local x = math.Clamp(value.x, -150, 150)
				local y = math.Clamp(value.y, -150, 150)
				local z = math.Clamp(value.z, -150, 150)

				self:SetDrawOffsetPos(Vector(x, y, z))
			elseif iname == "Angle" then
				self:SetDrawOffsetAng(value)
			end
	end

end

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "DrawScale" )
	self:NetworkVar( "Vector", 0, "DrawOffsetPos" )
	self:NetworkVar( "Angle", 0, "DrawOffsetAng" )
end

if CLIENT then

	function ENT:Initialize()
		self.GPU = GPULib.WireGPU( self )
		self.GPU.texture_filtering = TEXFILTER.ANISOTROPIC
		self.GPU.GetInfo = function()
			local pos = self:LocalToWorld(self:GetDrawOffsetPos())
			local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng())
			return {RS = self:GetDrawScale(), RatioX = 1, translucent = true}, pos, ang
		end
		self.RenderTable = {}
		self:EGP_Update( EGP.HomeScreen )
	end

	function ENT:DrawEntityOutline() end

	local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)

	function ENT:Think()
		local dist = Vector(1,0,1)*wire_egp_emitter_drawdist:GetInt()
		self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
	end
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end