AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_egp" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

if CLIENT then

	ENT.gmod_wire_egp_emitter = true

	ENT.DrawOffsetPos = Vector(-64, 0, 135)
	ENT.DrawOffsetAng = Angle(0, 0, 90)
	ENT.DrawScale     = 0.25

	local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)

	function ENT:Think()
		local dist = Vector(1,0,1)*wire_egp_emitter_drawdist:GetInt()
		self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
	end

	local wire_egp_drawemitters = CreateClientConVar("wire_egp_drawemitters", "1")

	function ENT:Draw()
			if wire_egp_drawemitters:GetBool() == true then

				if self.UpdateConstantly or self.NeedsUpdate then
					self:_EGP_Update()
				end

				local pos = self:LocalToWorld(self.DrawOffsetPos)
				local ang = self:LocalToWorldAngles(self.DrawOffsetAng)

				local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
				WireGPU_matScreen:SetTexture("$basetexture", self.GPU.RT)

				cam.Start3D2D(pos, ang, self.DrawScale)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(WireGPU_matScreen)
					surface.DrawTexturedRect(0, 0, 512, 512)
				cam.End3D2D()

				WireGPU_matScreen:SetTexture("$basetexture", OldTex)
		end

		self:DrawModel()

		Wire_Render(self)
	end

	function ENT:DrawEntityOutline() end

end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
