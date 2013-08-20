AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Text Screen"
ENT.WireDebugName	= "Text Screen"

function ENT:InitializeShared()
	self.text = ""
	self.chrPerLine = 5
	self.textJust = 0
	self.valign = 0
	self.tfont = "Arial"
	self.createdFonts = {}

	self.fgcolor = Color(255,255,255)
	self.bgcolor = Color(0,0,0)

	WireLib.umsgRegister(self)
end


if CLIENT then 
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
		self:CreateFont(self.tfont)
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

				surface.SetFont(self.tfont..self.chrPerLine)
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

	function ENT:SetText(text,font)
		self.text = text
		self.tfont = font
		self:CreateFont(font)
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
			self:SetText(um:ReadString(), um:ReadString()) -- text, font
		end
	end
	
	function ENT:CreateFont(font)
		if self.createdFonts[font] then return end

		local fontSize = 380
		for i = 1,15 do
			local fontData = 
			{
				font = font,
				size = fontSize / i,
				weight = 400,
				antialias = true,
				additive = false,
				
			}
			surface.CreateFont( font .. i, fontData)
		end
		self.createdFonts[font] = true
		self.NeedRefresh = true
	end
	
	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateSpecialInputs(self, { "String", "Font", "FGColor", "BGColor" }, { "STRING", "STRING", "VECTOR", "VECTOR" })
	self:InitializeShared()
end

function ENT:Setup(DefaultText, chrPerLine, textJust, valign, tfont, fgcolor, bgcolor)
	self.fgcolor = fgcolor or Color(255,255,255)
	self.bgcolor = bgcolor or Color(0,0,0)
	self.chrPerLine = math.Clamp(math.ceil(chrPerLine or 10), 1, 15)
	self.textJust = textJust or 1
	self.valign = valign or 0
	self.tfont = tfont or "Arial"
	self:SendConfig()
	
	self.text = DefaultText or ""
	self:TriggerInput("String", self.text)
end

function ENT:TriggerInput(iname, value)
	if iname == "String" then
		self.text = tostring(value)
		self:SetText(self.text, self.tfont)
	elseif iname == "Font" then
		self.tfont = tostring(value)
		if value ~= "" then self:SetText(self.text, self.tfont) end
	elseif iname == "FGColor" then
		self.fgcolor = Color(value.x, value.y, value.z)
		self.doSendConfig = true
	elseif iname == "BGColor" then
		self.bgcolor = Color(value.x, value.y, value.z)
		self.doSendConfig = true
	end
end

local function formatText(text)
	return text:gsub("<br>", "\n")
end

function ENT:SetText(text, font, ply)
	self:umsg(ply)
		self.umsg.Char(2) -- text

		self.umsg.String(formatText(text))
		self.umsg.String(font)
	self.umsg.End()
end

function ENT:Think()
	if self.doSendConfig then
		self:SendConfig()
	end
end

function ENT:SendConfig(ply)
	self.doSendConfig = nil
	self:umsg(ply)
		self.umsg.Char(1) -- config

		self.umsg.Char(self.chrPerLine)
		self.umsg.Char(self.textJust)
		self.umsg.Char(self.valign)

		self.umsg.Char(self.fgcolor.r-128)
		self.umsg.Char(self.fgcolor.g-128)
		self.umsg.Char(self.fgcolor.b-128)

		self.umsg.Char(self.bgcolor.r-128)
		self.umsg.Char(self.bgcolor.g-128)
		self.umsg.Char(self.bgcolor.b-128)
	self.umsg.End()
end

function ENT:Retransmit(ply)
	self:SetText(self.text, self.tfont, ply)
	self:SendConfig(ply)
end

duplicator.RegisterEntityClass("gmod_wire_textscreen", WireLib.MakeWireEnt, "Data", "text", "chrPerLine", "textJust", "valign", "tfont", "fgcolor", "bgcolor")
