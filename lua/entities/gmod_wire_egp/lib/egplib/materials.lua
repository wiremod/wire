--------------------------------------------------------
-- Materials (And fonts)
--------------------------------------------------------
local EGP = EGP

if CLIENT then
	-- Valid fonts table
	local MAX_EGP_FONTS = 150
	EGP.ValidFonts_Lookup = EGP.ValidFonts_Lookup or {}
	EGP.ValidFonts_Count = EGP.ValidFonts_Count or 0

	function EGP.CreateFont( font, size )
		local fontName = "WireEGP_" .. size .. "_" .. font
		if not EGP.ValidFonts_Lookup[fontName] and EGP.ValidFonts_Count < MAX_EGP_FONTS then
			local fontTable =
			{
				font=font,
				size = size,
				weight = 800,
				antialias = true,
				additive = false
			}
			surface.CreateFont( fontName, fontTable )
			EGP.ValidFonts_Lookup[fontName] = true
			EGP.ValidFonts_Count = EGP.ValidFonts_Count + 1
		else
			fontName = "WireEGP_18_WireGPU_ConsoleFont"
		end

		return fontName
	end

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
