include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

--------------------------------------------------------------------------------
local Layouter = {}
Layouter.__index = Layouter

function MakeTextScreenLayouter()
	return setmetatable({}, Layouter)
end

function Layouter:AddString(s)
	local width, height = surface.GetTextSize(s)
	if self.LineWidth+width >= self.w then return false end

	table.insert(self.drawlist, { surface.DrawText, s, self.LineWidth, self.y })

	self.LineWidth = self.LineWidth+width
	self.LineHeight = math.max(height, self.LineHeight)

	return true
end

function Layouter:NextLine()
	if self.LineHeight == 0 then
		self:AddString(" ")
	end

	local offsetx = self.x+(self.w-self.LineWidth)*self.justify/2

	for _,entry in ipairs(self.drawlist) do
		surface.SetTextPos(entry[3]+offsetx, entry[4])
		entry[1](entry[2], entry)
	end
	self.y = self.y+self.LineHeight
	self:ResetLine()
end

function Layouter:ResetLine()
	self.LineHeight = 0
	self.LineWidth = 0
	self.drawlist = {}
end

function Layouter:layout(text, x, y, w, h, justify)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.justify = justify
	self:ResetLine()

	for line,newlines in text:gmatch("([^\n]*)(\n*)") do
		for spaces,word in line:gmatch("( *)([^ ]*)") do
			if not self:AddString(spaces..word) then
				self:NextLine()
				self:AddString(word)
			end
		end
		for i = 1,#newlines do
			self:NextLine()
		end
	end
	self:NextLine()
end
--------------------------------------------------------------------------------

function ENT:Initialize()
	self:InitializeShared()

	self.GPU = WireGPU(self.Entity)
	self.layouter = MakeTextScreenLayouter()
	self.NeedRefresh = true

	self:ApplyProperties()
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	self.Entity:DrawModel()

	if self.NeedRefresh then
		self.NeedRefresh = nil
		self.GPU:RenderToGPU(function()
			local RatioX = 1
			local w = 512
			local h = 512

			--add changable backround colour some time.
			surface.SetDrawColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, 255)
			surface.DrawRect(0, 0, w, h)

			surface.SetFont("textScreenfont"..self.chrPerLine)
			surface.SetTextColor(self.fgcolor)
			self.layouter = MakeTextScreenLayouter()
			self.layouter:layout(self.text, 0, 0, w, h, self.textJust)

			--draw.DrawText(self.text, "textScreenfont"..self.chrPerLine, self.textJust/2*w, 2, self.fgcolor, self.textJust)
		end)
	end

	self.GPU:Render()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end

function ENT:SetText(text)
	self.text = text
	self.NeedRefresh = true
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
	self.NeedRefresh = true
end

--------------------------------------------------------------------------------

local properties = {}

function ENT:ApplyProperties()
	local props = properties[self:EntIndex()]
	if props then
		if props then table.Merge(self:GetTable(), props) end
		properties[self:EntIndex()] = nil
	end
end

local ENT_SetText = ENT.SetText
usermessage.Hook("wire_textscreen_SetText", function(um)
	local entid = um:ReadShort()
	local ent = Entity(entid)

	local text = um:ReadString()
	if ent:IsValid() and ent:GetTable() then
		if properties[entid] then properties[entid] = nil end
		ent:SetText(text)
	else
		-- TODO: get rid of this
		properties[entid] = properties[entid] or {}
		ENT_SetText(properties[entid], text)
	end
end)

local ENT_ReceiveConfig = ENT.ReceiveConfig
usermessage.Hook("wire_textscreen_SendConfig", function(um)
	local entid = um:ReadShort()
	local ent = Entity(entid)

	if ent:IsValid() and ent:GetTable() then
		if properties[entid] then properties[entid] = nil end
		ent:ReceiveConfig(um)
	else
		-- TODO: get rid of this
		properties[entid] = properties[entid] or {}
		ENT_ReceiveConfig(properties[entid], um)
	end
end)

--------------------------------------------------------------------------------

if not wire_textscreen_FontsCreated then
	wire_textscreen_FontsCreated = true

	local fontSize = 380
	for i = 1,15 do
		surface.CreateFont( "coolvetica", fontSize / i, 400, true, false, "textScreenfont"..i )
	end
end
