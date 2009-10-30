--Wire text screen by greenarrow and wire team
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow

include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH


function ENT:Initialize()
	self:InitializeShared()

	self:ApplyProperties()
end

function ENT:Draw()
	self.Entity:DrawModel()
	--nighteagle screen vector rotation and positioning legacy code
	local OF = 0.3
	local OU = 11.8
	local OR = -2.35
	local Res = 0.12
	local RatioX = 1

	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), rot.x)
	ang:RotateAroundAxis(ang:Up(), rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)

	cam.Start3D2D(pos,ang,Res)
		local x = -112
		local y = -104
		local w = 296
		local h = 292

		--add changable backround colour some time.
		surface.SetDrawColor(self.bgcolor.r,self.bgcolor.g,self.bgcolor.b,255)
		surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

		local justOffset = (w / 3) + (self.textJust * (w / 3.5))
		if (self.chrPerLine ~= 0) then
			draw.DrawText(self.text, "textScreenfont"..tostring(self.chrPerLine), (x + justOffset - 92) / RatioX, y + 2, self.fgcolor, self.textJust)
		end
	cam.End3D2D()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end

function ENT:SetText(text)
	self.text = text
end

function ENT:ReceiveConfig(um)
	self.chrPerLine = um:ReadChar()
	self.textJust = um:ReadChar()

	local r = um:ReadChar()+128
	local g = um:ReadChar()+128
	local b = um:ReadChar()+128
	self.fgcolor = Color(r,g,b)

	local r = um:ReadChar()+128
	local g = um:ReadChar()+128
	local b = um:ReadChar()+128
	self.bgcolor = Color(r,g,b)
end

--------------------------------------------------------------------------------

local properties = {}

function ENT:ApplyProperties()
	local props = properties[self.Entity]
	if props then
		local text = props.text
		local config = props.config
		if props.text then self:SetText(text) end
		if props.config then table.Merge(self:GetTable(), config) end
		properties[self.Entity] = nil
	end
end

local ENT_ReceiveConfig = ENT.ReceiveConfig

usermessage.Hook("wire_textscreen_SetText", function(um)
	local ent = um:ReadEntity()
	local text = um:ReadString()
	if ent:GetTable() then
		if properties[ent] then properties[ent].text = nil end
		ent:SetText(text)
	else
		-- TODO: get rid of this
		properties[ent] = properties[ent] or {}
		properties[ent].text = text
	end
end)

usermessage.Hook("wire_textscreen_SendConfig", function(um)
	local ent = um:ReadEntity()
	if ent:GetTable() then
		if properties[ent] then properties[ent].config = nil end
		ent:ReceiveConfig(um)
	else
		-- TODO: get rid of this
		properties[ent] = properties[ent] or {}
		properties[ent].config = {}
		ENT_ReceiveConfig(properties[ent].config, um)
	end
end)

--------------------------------------------------------------------------------

if not wire_textscreen_FontsCreated then
	wire_textscreen_FontsCreated = true

	local fontSize = 380
	for i = 1,15 do
		surface.CreateFont( "coolvetica", fontSize / i, 400, false, false, "textScreenfont"..i )
	end
end
