--------------------------------------------------------
-- Materials (And fonts)
--------------------------------------------------------
local EGP = EGP

-- Valid fonts table
EGP.ValidFonts = {}
EGP.ValidFonts[0] = "Lucida Console"
EGP.ValidFonts[1] = "Courier New"
EGP.ValidFonts[2] = "Trebuchet"
EGP.ValidFonts[3] = "Arial"
EGP.ValidFonts[4] = "Times New Roman"
EGP.ValidFonts[5] = "Coolvetica"
EGP.ValidFonts[6] = "Akbar"
EGP.ValidFonts[7] = "csd"
EGP.ValidFonts[8] = "Roboto"
EGP.ValidFonts[9] = "Marlett"
EGP.ValidFonts[10] = "ChatFont"
EGP.ValidFonts[11] = "WireGPU_ConsoleFont"

if (CLIENT) then
	
	for k,v in ipairs( EGP.ValidFonts ) do
		local font = WireLib.LoadFont( v, 18 )
	end

	local type = type
	local SetMaterial = surface.SetMaterial
	local SetTexture = surface.SetTexture
	local GetTextureID = surface.GetTextureID
	local NoTexture = draw.NoTexture

	function EGP:SetMaterial( Mat )
		if type(Mat) == "IMaterial" then
			SetMaterial( Mat )
		elseif isentity(Mat) then
			if (!Mat:IsValid() or !Mat.GPU or !Mat.GPU.RT) then NoTexture() return end
			local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
			WireGPU_matScreen:SetTexture("$basetexture", Mat.GPU.RT)
			SetTexture(GetTextureID( "GPURT" ))
			return OldTex
		else
			NoTexture()
		end
	end
	
	function EGP:FixMaterial( OldTex )
		if (!OldTex) then return end
		WireGPU_matScreen:SetTexture("$basetexture", OldTex)
	end
end
