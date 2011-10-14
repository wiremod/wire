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
end

EGP.Materials = {}

function EGP:CacheMaterial( Mat )
	if (!Mat or #Mat == 0) then return end
	if (!self.Materials[Mat]) then
		local temp
		if (#file.Find("materials/"..Mat..".*",true) > 0) then
			 temp = surface.GetTextureID(Mat)
		end
		self.Materials[Mat] = temp
	end
	return self.Materials[Mat]
end

function EGP:SetMaterial( Mat )
	if (!Mat) then
		surface.SetTexture()
	elseif (type(Mat) == "string") then
		surface.SetTexture( self:CacheMaterial( Mat ) )
 	elseif (type(Mat) == "Entity") then
		if (!Mat:IsValid() or !Mat.GPU or !Mat.GPU.RT) then return end
		local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
		WireGPU_matScreen:SetMaterialTexture("$basetexture", Mat.GPU.RT)
		surface.SetTexture(surface.GetTextureID( "GPURT" ))
		return OldTex
 	end
 end

function EGP:FixMaterial( OldTex )
	if (!OldTex) then return end
	WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex)
end

--[[
if (CLIENT) then
	EGP.FakeMat = Material("egp_ignore_this_error")
	EGP.FakeTex = surface.GetTextureID("egp_ignore_this_error")
end

function EGP:SetMaterial( Mat )
	if (!Mat) then
		surface.SetTexture()
	elseif (type(Mat) == "string") then
		surface.SetTexture( self:CacheMaterial( Mat ) )
 	elseif (type(Mat) == "Entity") then
		if (!Mat:IsValid() or !Mat.GPU or !Mat.GPU.RT) then return end
		local OldTex = EGP.FakeMat:GetMaterialTexture("$basetexture")
		EGP.FakeMat:SetMaterialTexture("$basetexture", Mat.GPU.RT)
		surface.SetTexture(EGP.FakeTex)
		return OldTex
 	end
 end

function EGP:FixMaterial( OldTex )
	if (!OldTex) then return end
	EGP.FakeMat:SetMaterialTexture("$basetexture", OldTex)
end
]]
