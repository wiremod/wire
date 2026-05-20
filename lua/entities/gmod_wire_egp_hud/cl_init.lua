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

function ENT:Draw(flags)
	self:DrawModel(flags)

	local is_depth_pass = (bit.band(flags, STUDIO_SSAODEPTHTEXTURE) ~= 0 or bit.band(flags, STUDIO_SHADOWDEPTHTEXTURE) ~= 0)

	if is_depth_pass then return end
	
	Wire_Render(self)
end
