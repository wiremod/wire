include("shared.lua")
include("huddraw.lua")

ENT.gmod_wire_egp_hud = true

function ENT:GetEGPMatrix()
	return Matrix()
end


function ENT:Initialize()
	self.RenderTable = {}
end

function ENT:GetEGPMatrix()
	return Matrix()
end

function ENT:EGP_Update() end

function ENT:DrawEntityOutline() end

function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)
end
