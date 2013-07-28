
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local halo_ent, halo_blur

function ENT:Draw()
	self:DoNormalDraw(true,false)
	if LocalPlayer():GetEyeTrace().Entity == self and EyePos():Distance( self:GetPos() ) < 512 then
		if self:IsOn() then
			halo_ent = self
			halo_blur = 4 + math.sin(CurTime()*20)*2
		else
			self:DrawEntityOutline()
		end
	end
	Wire_Render(self)
end

hook.Add("PreDrawHalos", "Wiremod_dynbutton_overlay_halos", function()
	if halo_ent then
		halo.Add({halo_ent}, Color(255,100,100), halo_blur, halo_blur, 1, true, true)
		halo_ent = nil
	end
end)
