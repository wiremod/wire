/******************************************************************************\
  Tool Screen rendering hook for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

hook.Add("InitPostEntity", "RenderToolScreenInitialize", function()
	local SWEP
	for _,weapon in pairs(weapons.GetList()) do
		if weapon.Classname == "gmod_tool" then
			SWEP = weapon
			break
		end
	end
	if not SWEP then return end

	local ToolGunMaterial = Material("models/weapons/v_toolgun/screen")
	local NewRT = GetRenderTarget("GModToolgunScreen", 256, 256)

	local _ViewModelDrawn = SWEP.ViewModelDrawn
	function SWEP:ViewModelDrawn()
		local tool = self.Tool[gmod_toolmode:GetString()]
		if not tool then return _ViewModelDrawn(self) end
		if not tool.RenderToolScreen then return _ViewModelDrawn(self) end

		local ToolGunRT = render.GetRenderTarget()

		ToolGunMaterial:SetMaterialTexture("$basetexture", NewRT)

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0, 0, 256, 256)

		tool:RenderToolScreen()

		render.SetRenderTarget(ToolGunRT)
	end
end)
