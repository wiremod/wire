--Wire text screen by greenarrow + wire team
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Text Screen"
ENT.initOn = true
ENT.firstConfig = true
ENT.clock = false
ENT.currentLine = 0
ENT.currentText = ""
ENT.currentTextnum = 0

wire_text_screen_lastCreated = nil

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
end

function ENT:Setup(TextList, chrPl, textJust, tRed, tGreen, tBlue, numInputs, defaultOn)
	self.TextList = TextList	--table of text lines
	self.TextList[0] = ""

	self.maxLineLen = math.abs(chrPl)
	self.maxLines = math.abs(chrPl) / 2
	self.chrPerLine = math.abs(chrPl)
	self.numInputs = math.abs(numInputs)
	self.textJust = textJust
	self.tRed = tRed
	self.tGreen = tGreen
	self.tBlue = tBlue
	self.currentLine = 0
	self.StringNum = 1
	self.String = self.TextList[1]
	self.StringClk = 0

	--setup input with required number of value inputs
	valInputs = {}
	self.Val = {}
	local SpecialInputs = {}
	SpecialInputTypes = {"NORMAL", "NORMAL", "NORMAL", "STRING", "NORMAL"}
	for n=1, numInputs do
		table.insert(self.Val, 0)
		table.insert(valInputs, "Value "..n)
		table.insert(SpecialInputTypes, "NORMAL")
	end
	inputTable = {"Clk", "Text", "StringNum", "String", "StringClk"}
	table.Add(inputTable, valInputs)
	self.Inputs = Wire_CreateInputs(self.Entity, inputTable)
	WireLib.AdjustSpecialInputs(self.Entity, inputTable, SpecialInputTypes)

	self.defaultOn = defaultOn

	--send config to client
	self:SetConfig()
	--format text and send to client
	self:UpdateScreen()

	--if option is selected, show text without the need for wire inputs
	if (defaultOn == 1) then
		self:TriggerInput("Clk", 1)	--make text on by default
		self:TriggerInput("Text", 1)
	else
		self:TriggerInput("Clk", 0)
		self:TriggerInput("Text", 0)
	end
end

local function UpdateValuesCheck(self)
	if (self.StringClk==1) then
		if (self.TextList[self.StringNum]!=self.String) then
			self.TextList[self.StringNum] = self.String
			if (self.StringNum==self.currentTextnum) then
			self:UpdateScreen()
			end
		end
	end
end

--wire input routine
function ENT:TriggerInput(iname, value)
	if (!iname) then
		//do nothing, this prevents the next line from erroring
	elseif (iname == "Text") then
		self.currentTextnum = math.abs(value)
		self:UpdateScreen()
	elseif (iname == "Clk") then
		if (math.abs(value) > 0) then
			self.clock = true
			self:UpdateScreen()
		else
			self.clock = false
		end
	elseif (iname == "StringNum") then
		if (value<=12 && value>=1) then
		value = value - value % 1
		end
		self.StringNum = value
		UpdateValuesCheck(self)
	elseif (iname == "String") then
		self.String = value
		UpdateValuesCheck(self)
	elseif (iname == "StringClk") then
		if (value==1) then
			self.StringClk=1
			UpdateValuesCheck(self)
		else
			self.StringClk=0
		end
	elseif (string.sub(iname, 1, 6) == "Value ") then
		self.Val[tonumber(string.sub(iname, 7, -1))] = math.abs(value)
		self:UpdateScreen()
	end
end

--format text and send it to the client(s)
function ENT:UpdateScreen()
	if (self.clock && (self.currentLine <= self.maxLines)) then
		local compstring = ""
		local outString = ""
		local intoText = false
		local basestring = self.TextList[self.currentTextnum]
		if (!basestring) then return false end

		for k,inp in ipairs(self.Val) do
			local nString = string.format("%G", inp)
			basestring = string.gsub(basestring, "<"..k..">", nString)
		end

		basestring = string.gsub(basestring, "<br>", "\n")
		compstring = basestring
		local outString = ""
		if (string.len(compstring) > self.maxLineLen) then
			local lastSpace = 0
			local lastBreak = 1
			local numLines = 1
			for chrNum = 1, string.len(compstring) do
				if (string.byte(string.sub(compstring, chrNum, chrNum)) == 10) && (numLines <= self.maxLines) then
					outString = outString..string.Left(string.sub(compstring, lastBreak, chrNum), self.chrPerLine)
					lastBreak = chrNum + 1
					lastSpace = 0
					numLines = numLines + 1
				end
				if (string.sub(compstring, chrNum, chrNum) == " ") then
					lastSpace = chrNum
				end
				if (chrNum >= lastBreak + self.maxLineLen) && (numLines <= self.maxLines) then	--if we've gone past a line length since the last break and line is still on screen
					if (lastSpace > 0) then
						outString = outString..string.Left(string.sub(compstring, lastBreak, lastSpace), self.chrPerLine).."\n"
						lastBreak = lastSpace + 1
						lastSpace = 0
						numLines = numLines + 1
					end
				end
			end
			if (numLines <= self.maxLines) then
				local foff = 0
				outString = outString..string.Left(string.sub(compstring, lastBreak + foff, string.len(compstring)), self.chrPerLine).."\n"
			end
		else
			outString = compstring
		end
		self:SetText (outString)
	end
end


function MakeWireTextScreen( pl, Pos, Ang, model, TextList, chrPerLine, textJust, tRed, tGreen, tBlue, numInputs, defaultOn, frozen)
	if ( !pl:CheckLimit( "wire_textscreens" ) ) then return false end
	local wire_textscreen = ents.Create( "gmod_wire_textscreen" )
	if (!wire_textscreen:IsValid()) then return false end
	wire_textscreen:SetModel(model)
	wire_textscreen:Setup(TextList, chrPerLine, textJust, tRed, tGreen, tBlue, numInputs, defaultOn)
	wire_textscreen:SetAngles( Ang )
	wire_textscreen:SetPos( Pos )
	wire_textscreen:Spawn()

	if wire_textscreen:GetPhysicsObject():IsValid() then
		local Phys = wire_textscreen:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_textscreen:SetPlayer(pl)
	wire_textscreen.pl = pl

	pl:AddCount( "wire_textscreens", wire_textscreen )
	return wire_textscreen
end
duplicator.RegisterEntityClass("gmod_wire_textscreen", MakeWireTextScreen, "Pos", "Ang", "Model", "TextList", "chrPerLine", "textJust", "tRed", "tGreen", "tBlue", "numInputs", "defaultOn", "frozen")
