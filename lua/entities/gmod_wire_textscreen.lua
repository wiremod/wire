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

	self.fgcolor = Color(255,255,255)
	self.bgcolor = Color(0,0,0)
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
		self:CreateFont(self.tfont, self.chrPerLine)

		WireLib.netRegister(self)
	end

	function ENT:OnRemove( fullUpdate )
		self.NeedRefresh = true
		if fullUpdate then return end
		self.GPU:Finalize()
	end
	function ENT:Draw()
		self:DrawModel()

		if self.NeedRefresh then
			self.NeedRefresh = nil
			self.GPU:RenderToGPU(function()
				local w = 1024
				local h = 1024

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

	function ENT:SetText(text)
		self.text = text
		self.NeedRefresh = true
	end

	function ENT:Receive()
		if net.ReadBit() ~= 0 then
			self.chrPerLine = net.ReadUInt(4)
			self.textJust = net.ReadUInt(2)
			self.valign = net.ReadUInt(2)

			self.fgcolor = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
			self.bgcolor = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
			self.tfont = net.ReadString()
			self:CreateFont(self.tfont, self.chrPerLine)

			self.NeedRefresh = true
		else
			self:SetText(net.ReadString())
		end
	end

	local createdFonts = {}
	function ENT:CreateFont(font, chrPerLine)
		if createdFonts[font .. chrPerLine] then return end

		local fontData = {
			font = font,
			size = 760 / chrPerLine,
			weight = 400,
			antialias = true,
			additive = false
		}
		surface.CreateFont(font .. chrPerLine, fontData)
		createdFonts[font .. chrPerLine] = true
		self.NeedRefresh = true
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.doSendText = false
	self.doSendConfig = false
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

	self:TriggerInput("String", DefaultText or "")
end

function ENT:TriggerInput(iname, value)
	if iname == "String" then
		self.text = string.sub(tostring(value), 1, 1024)
		self.doSendText = true
	elseif iname == "Font" then
		self.tfont = tostring(value)
		self.doSendConfig = true
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

function ENT:SendText(ply)
	self.doSendText = false
	WireLib.netStart(self)
		net.WriteBit(false) -- Sending Text
		net.WriteString(formatText(self.text))
	WireLib.netEnd(ply)
end

function ENT:Think()
	if self.doSendConfig then
		self:SendConfig()
	end
	if self.doSendText then
		self:SendText()
	end
end

function ENT:SendConfig(ply)
	self.doSendConfig = false
	WireLib.netStart(self)
		net.WriteBit(true) -- Sending Config
		net.WriteUInt(self.chrPerLine, 4)
		net.WriteUInt(self.textJust, 2)
		net.WriteUInt(self.valign, 2)

		net.WriteUInt(self.fgcolor.r, 8)
		net.WriteUInt(self.fgcolor.g, 8)
		net.WriteUInt(self.fgcolor.b, 8)

		net.WriteUInt(self.bgcolor.r, 8)
		net.WriteUInt(self.bgcolor.g, 8)
		net.WriteUInt(self.bgcolor.b, 8)
		net.WriteString(string.sub(self.tfont,0,31))
	WireLib.netEnd(ply)
end

function ENT:Retransmit(ply)
	self:SendText(ply)
	self:SendConfig(ply)
end

duplicator.RegisterEntityClass("gmod_wire_textscreen", WireLib.MakeWireEnt, "Data", "text", "chrPerLine", "textJust", "valign", "tfont", "fgcolor", "bgcolor")
