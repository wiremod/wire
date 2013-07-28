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

	local nextx = self.x+width
	if nextx > self.x2 then return false end

	table.insert(self.drawlist, { s, self.x, self.y })

	self.x = nextx
	self.LineHeight = math.max(height, self.LineHeight)

	return true
end

function Layouter:NextLine()
	if self.LineHeight == 0 then
		self:AddString(" ")
	end

	local nexty = self.y+self.LineHeight

	if nexty > self.y2 then return false end

	local offsetx = (self.x2-self.x)*self.halign/2

	table.insert(self.lines, { offsetx, self.drawlist })

	self.y = nexty
	self:ResetLine()
	return true
end

function Layouter:ResetLine()
	self.LineHeight = 0
	self.x = self.x1
	self.drawlist = {}
end

function Layouter:ResetPage()
	self:ResetLine()
	self.y = self.y1
	self.lines = {}
end

-- valign is not supported yet
function Layouter:layout(text, x, y, w, h, halign)
	self.x1 = x
	self.y1 = y
	self.x2 = x+w
	self.y2 = y+h
	self.halign = halign

	self:ResetPage()

	for line,newlines in text:gmatch("([^\n]*)(\n*)") do
		for spaces,word in line:gmatch("( *)([^ ]*)") do
			if not self:AddString(spaces..word) then
				if not self:NextLine() then return false end
				self:AddString(word)
			end
		end
		for i = 1,#newlines do
			if not self:NextLine() then return false end
		end
	end
	if not self:NextLine() then return false end
	return true
end

function Layouter:DrawText(text, x, y, w, h, halign, valign)
	self:layout(text, x, y, w, h, halign, valign)

	local offsety = (self.y2-self.y)*valign/2

	for _,offsetx,drawlist in ipairs_map(self.lines,unpack) do
		for _,s,x,y in ipairs_map(drawlist,unpack) do
			surface.SetTextPos(x+offsetx, y+offsety)
			surface.DrawText(s)
		end
	end
end

function Layouter:GetTextSize(text, w, h)
	self:layout(text, 0, 0, w, h, 2, 0)

	local minoffset = nil

	for _, offsetx, drawlist in ipairs_map(self.lines, unpack) do
		if not minoffset then
			minoffset = offsetx
		else
			minoffset = math.min(minoffset, offsetx)
		end
	end

	return minoffset and self.x2 - minoffset or 0, self.y
end
--------------------------------------------------------------------------------

function ENT:Initialize()
	self:InitializeShared()

	self.GPU = WireGPU(self)
	self.layouter = MakeTextScreenLayouter()
	self.NeedRefresh = true
end

function ENT:OnRemove()
	self.GPU:Finalize()
	self.NeedRefresh = true
end
function ENT:Draw()
	self:DrawModel()

	if self.NeedRefresh then
		self.NeedRefresh = nil
		self.GPU:RenderToGPU(function()
			local w = 512
			local h = 512

			surface.SetDrawColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, 255)
			surface.DrawRect(0, 0, w, h)

			surface.SetFont("textScreenfont"..self.chrPerLine)
			surface.SetTextColor(self.fgcolor)
			self.layouter:DrawText(self.text, 0, 0, w, h, self.textJust, self.valign)
		end)
	end

	self.GPU:Render()
	--[[
	self.GPU:RenderToWorld(512, nil, function(x, y, w, h)

		surface.SetDrawColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, 255)
		surface.DrawRect(x, y, w, h)

		surface.SetFont("textScreenfont"..self.chrPerLine)
		surface.SetTextColor(self.fgcolor)
		self.layouter:DrawText(self.text, x, y, w, h, self.textJust, self.valign)
	end)
	]]
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end

function ENT:SetText(text)
	self.text = text
	self.NeedRefresh = true
end

function ENT:Receive(um)
	local what = um:ReadChar()
	if what == 1 then
		self.chrPerLine = um:ReadChar()
		self.textJust = um:ReadChar()
		self.valign = um:ReadChar()

		local r = um:ReadChar()+128
		local g = um:ReadChar()+128
		local b = um:ReadChar()+128
		self.fgcolor = Color(r,g,b)

		local r = um:ReadChar()+128
		local g = um:ReadChar()+128
		local b = um:ReadChar()+128
		self.bgcolor = Color(r,g,b)
		self.NeedRefresh = true
	elseif what == 2 then
		self:SetText(um:ReadString())
	end
end

if not wire_textscreen_FontsCreated then
	wire_textscreen_FontsCreated = true

	local fontSize = 380
	for i = 1,15 do
		local fontData = 
		{
			font = "Helvetica",
			size = fontSize / i,
			weight = 400,
			antialias = true,
			additive = false,
			
		}
		surface.CreateFont( "textScreenfont" .. i, fontData)
	end
end
