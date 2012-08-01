--------------------------------------------------------
-- Materials (And fonts)
--------------------------------------------------------
local EGP = EGP

-- Valid fonts table
EGP.ValidFonts_Lookup = {}
EGP.ValidFonts = {}
EGP.ValidFonts[1] = "WireGPU_ConsoleFont"
EGP.ValidFonts[2] = "Coolvetica"
EGP.ValidFonts[3] = "Arial"
EGP.ValidFonts[4] = "Lucida Console"
EGP.ValidFonts[5] = "Trebuchet"
EGP.ValidFonts[6] = "Courier New"
EGP.ValidFonts[7] = "Times New Roman"
EGP.ValidFonts[8] = "ChatFont"
EGP.ValidFonts[9] = "Marlett"
if (CLIENT) then
	local new = {}
	for k,v in ipairs( EGP.ValidFonts ) do
		local font = "WireEGP_18_"..k
		surface.CreateFont(v,18,800,true,false,font)
		EGP.ValidFonts_Lookup[font] = true
		table.insert( new, font )
	end
	for k,v in ipairs( new ) do
		table.insert( EGP.ValidFonts, v )
	end

	local type = type
	local SetMaterial = surface.SetMaterial
	local SetTexture = surface.SetTexture
	local GetTextureID = surface.GetTextureID
	local NoTexture = draw.NoTexture

	function EGP:SetMaterial( Mat )
		if type(Mat) == "IMaterial" then
			SetMaterial( Mat )
		elseif type(Mat) == "Entity" then
			if (!Mat:IsValid() or !Mat.GPU or !Mat.GPU.RT) then NoTexture() return end
			local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
			WireGPU_matScreen:SetMaterialTexture("$basetexture", Mat.GPU.RT)
			SetTexture(GetTextureID( "GPURT" ))
			return OldTex
		else
			NoTexture()
		end
	end
	
	function EGP:FixMaterial( OldTex )
		if (!OldTex) then return end
		WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex)
	end
end