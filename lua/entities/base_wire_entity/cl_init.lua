include("shared.lua")

ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT//RENDERGROUP_OPAQUE//RENDERGROUP_BOTH

local wire_drawoutline = CreateClientConVar("wire_drawoutline", 1, true, false)

function ENT:Draw()
	self:DoNormalDraw()
	Wire_Render(self.Entity)
end

function ENT:DoNormalDraw()
	local looked_at = LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self:GetPos()) < 256
	if wire_drawoutline:GetBool() and looked_at then
		if ( self.RenderGroup == RENDERGROUP_OPAQUE) then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		if wire_drawoutline:GetBool() then self:DrawEntityOutline(1.0) end
		self:DrawModel()
	else
		if(self.OldRenderGroup) then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		self:DrawModel()
	end
	if looked_at then
		if(self:GetOverlayText() ~= "") then
			AddWorldTip(self:EntIndex(),self:GetOverlayText(),0.5,self:GetPos(),e)
		end
	end
end

function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
		self.NextRBUpdate = CurTime() + math.random(30,100)/10 --update renderbounds every 3 to 10 seconds
		Wire_UpdateRenderBounds(self.Entity)
	end
end
