include("shared.lua")

ENT.RenderGroup = RENDERGROUP_OPAQUE//RENDERGROUP_TRANSLUCENT//RENDERGROUP_BOTH

local wire_drawoutline = CreateClientConVar("wire_drawoutline", 1, true, false)
local wire_drawoutline_bool = wire_drawoutline:GetBool()

cvars.AddChangeCallback("wire_drawoutline", function(...) return wire_changey(...) end)

function wire_changey(cvar, prev, new)
	if prev == new then return end
	wire_drawoutline_bool = wire_drawoutline:GetBool()
end

function ENT:Draw()
	self:DoNormalDraw()
	Wire_Render(self)
end

function ENT:DoNormalDraw()
	local trace = LocalPlayer():GetEyeTrace()
	local looked_at = trace.Entity == self and trace.Fraction*16384 < 256
	if wire_drawoutline_bool and looked_at then
		if self.RenderGroup == RENDERGROUP_OPAQUE then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		self:DrawEntityOutline(1.0)
		self:DrawModel()
	else
		if self.OldRenderGroup then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		self:DrawModel()
	end
	if looked_at then
		if self:GetOverlayText() ~= "" then
			AddWorldTip(self:EntIndex(),self:GetOverlayText(),0.5,self:GetPos(),e)
		end
	end
end

function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
		self.NextRBUpdate = CurTime() + math.random(30,100)/10 --update renderbounds every 3 to 10 seconds
		Wire_UpdateRenderBounds(self)
	end
end

if VERSION >= 150 then
	-- gmod 13 seems to lack this method. TODO: find a replacement
	function ENT:DrawEntityOutline() end
end
