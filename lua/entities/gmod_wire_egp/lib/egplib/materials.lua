--------------------------------------------------------
-- Materials (And fonts)
--------------------------------------------------------
local EGP = EGP

-- Valid fonts table
EGP.ValidFonts_Lookup = {}
if (CLIENT) then

	local type = type
	local SetMaterial = surface.SetMaterial
	local NoTexture = draw.NoTexture

	function EGP:SetMaterial( Mat )
		if type(Mat) == "IMaterial" then
			SetMaterial( Mat )
		elseif isentity(Mat) then
			if (not Mat:IsValid() or not Mat.GPU or not Mat.GPU.RT) then NoTexture() return end
			local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
			WireGPU_matScreen:SetTexture("$basetexture", Mat.GPU.RT)
			SetMaterial(WireGPU_matScreen)
			return OldTex
		else
			NoTexture()
		end
	end

	function EGP:FixMaterial( OldTex )
		if (not OldTex) then return end
		WireGPU_matScreen:SetTexture("$basetexture", OldTex)
	end
end
