include("shared.lua")

ENT.RenderGroup = RENDERGROUP_OPAQUE//RENDERGROUP_TRANSLUCENT//RENDERGROUP_BOTH

local wire_drawoutline = CreateClientConVar("wire_drawoutline", 1, true, false)

function ENT:Draw()
	self:DoNormalDraw()
	Wire_Render(self)
end

function ENT:DoNormalDraw(nohalo, notip)
	local trace = LocalPlayer():GetEyeTrace()
	local looked_at = trace.Entity == self and trace.Fraction * 16384 < 256
	if not nohalo and wire_drawoutline:GetBool() and looked_at then
		if self.RenderGroup == RENDERGROUP_OPAQUE then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		self:DrawEntityOutline()
		self:DrawModel()
	else
		if self.OldRenderGroup then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		self:DrawModel()
	end
	if not notip and looked_at then
		self:DrawTip()
	end
end

function ENT:DrawTip(text)
	text = text or self:GetOverlayText()
	local name = self:GetNetworkedString("WireName")
	local plyname = self:GetNetworkedString("FounderName")
	
	text = string.format("- %s -\n%s\n(%s)", name ~= "" and name or self.PrintName, text, plyname)
	AddWorldTip(nil,text,nil,self:GetPos(),nil)
end

function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
		self.NextRBUpdate = CurTime() + math.random(30,100)/10 --update renderbounds every 3 to 10 seconds
		Wire_UpdateRenderBounds(self)
	end
end

local halos = {}
local halos_inv = {}

function ENT:DrawEntityOutline()
	if halos_inv[self] then return end
	halos[#halos+1] = self
	halos_inv[self] = true
end

hook.Add("PreDrawHalos", "Wiremod_overlay_halos", function()
	if #halos == 0 then return end
	halo.Add(halos, Color(100,100,255), 3, 3, 1, true, true)
	halos = {}
	halos_inv = {}
end)

net.Receive( "WireOverlay", function(length)
	local ent = net.ReadEntity()
	ent.OverlayText = net.ReadString()
end)
