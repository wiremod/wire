AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

local max_umsgs_per_tick = 8

function ENT:Initialize()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self, { "PixelX", "PixelY", "PixelG", "Clk", "FillColor", "ClearRow", "ClearCol" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })

	self.Memory = {}

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Memory[1048575] = 1

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	self.ChangedCellRanges = {}
end

function ENT:SetDigitalSize(ScreenWidth, ScreenHeight)
	self:WriteCell(1048572, ScreenHeight)
	self:WriteCell(1048573, ScreenWidth)
end

function ENT:SendPixel()
	if self.Memory[1048575] == 0 then return end -- why?
	if self.PixelX < 0 then return end
	if self.PixelY < 0 then return end
	if self.PixelX >= self.ScreenWidth then return end
	if self.PixelY >= self.ScreenHeight then return end

	local address = self.PixelY*self.ScreenWidth + self.PixelX
	self:WriteCell(address, self.PixelG)
end

function ENT:ReadCell(Address)
	if Address < 0 then return nil end
	if Address >= 1048576 then return nil end

	return self.Memory[Address] or 0
end

local per_tick = max_umsgs_per_tick
hook.Add("Think", "resetdigitickrate", function()
	per_tick = math.min(per_tick+2,max_umsgs_per_tick)
end)

function ENT:MarkCellChanged(Address)
	local lastrange = self.ChangedCellRanges[#self.ChangedCellRanges]
	if lastrange then
		if Address == lastrange.start + lastrange.length then
			-- wrote just after the end of the range, append
			lastrange.length = lastrange.length + 1
		elseif Address == lastrange.start - 1 then
			-- wrote just before the start of the range, prepend
			lastrange.start = lastrange.start - 1
			lastrange.length = lastrange.length + 1
		elseif Address < lastrange.start - 1 or Address > lastrange.start + lastrange.length then
			-- wrote outside the range
			lastrange = nil
		end
	end
	if not lastrange then
		lastrange = {
			start = Address,
			length = 1
		}
		self.ChangedCellRanges[#self.ChangedCellRanges + 1] = lastrange
	end
end

function ENT:FlushCache()
	while per_tick > 0 and
		  #self.ChangedCellRanges > 0 do
		per_tick = per_tick - 1

		local bytesleft = 249
		umsg.Start("hispeed_digiscreen")
			umsg.Short(self:EntIndex())
			while #self.ChangedCellRanges > 0 do
				local range = self.ChangedCellRanges[1]
				local datasize = math.min(range.length, math.floor((bytesleft - 5) * 0.25))
				if datasize < 1 then
					break
				end
				umsg.Char(datasize)
				umsg.Long(range.start)
				bytesleft = bytesleft - 5 - datasize * 4
				for i = range.start,range.start + datasize - 1 do
					umsg.Long(self.Memory[i])
				end
				range.start = range.start + datasize
				range.length = range.length - datasize
				if range.length == 0 then
					table.remove(self.ChangedCellRanges, 1)
				end
			end
			umsg.Char(-1)
		umsg.End()
	end
end

function ENT:ClearPixel(i)
	if self.Memory[1048569] == 1 then
		-- R G B mode
		self.Memory[i*3] = 0
		self.Memory[i*3+1] = 0
		self.Memory[i*3+2] = 0
		return
	end

	-- other modes
	self.Memory[i] = 0
end

function ENT:ClearCellRange(start, length)
	for i = start, start + length - 1 do
		self.Memory[i] = 0
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor (Address)
	if Address < 0 then return false end
	if Address >= 1048576 then return false end

	if Address < 1048500 then -- RGB data
		if self.Memory[Address] == value or
		   (value == 0 and self.Memory[Address] == nil) then
			return true
		end
	else
		if Address == 1048569 then -- Color mode (0: RGBXXX; 1: R G B; 2: 24 bit RGB; 3: RRRGGGBBB)
			-- not needed (yet)
		elseif Address == 1048570 then -- Clear row
			local row = math.Clamp(math.floor(value), 0, self.ScreenHeight-1)
			if self.Memory[1048569] == 1 then
				self:ClearCellRange(row*self.ScreenWidth*3, self.ScreenWidth*3)
			else
				self:ClearCellRange(row*self.ScreenWidth, self.ScreenWidth)
			end
		elseif Address == 1048571 then -- Clear column
			local col = math.Clamp(math.floor(value), 0, self.ScreenWidth-1)
			for i = col,col+self.ScreenWidth*(self.ScreenHeight-1),self.ScreenWidth do
				self:ClearPixel(i)
			end
		elseif Address == 1048572 then -- Height
			self.ScreenHeight = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048573 then -- Width
			self.ScreenWidth  = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048574 then -- Hardware Clear Screen
			local mem = {}
			for addr = 1048500,1048575 do
				mem[addr] = self.Memory[addr]
			end
			self.Memory = mem
			-- clear pixel data from usermessage queue
			while #self.ChangedCellRanges > 0 and
				  self.ChangedCellRanges[1].start + self.ChangedCellRanges[1].length < 1048500 do
				table.remove(self.ChangedCellRanges, 1)
			end
		elseif Address == 1048575 then -- CLK
			-- not needed atm
		end
	end

	self.Memory[Address] = value

	self:MarkCellChanged(Address)

	return true
end

function ENT:Think()
	self:FlushCache()
	self:NextThink(CurTime()+0.2)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "PixelX") then
		self.PixelX = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelY") then
		self.PixelY = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelG") then
		self.PixelG = math.floor(value)
		self:SendPixel()
	elseif (iname == "Clk") then
		self:WriteCell(1048575, value)
		self:SendPixel()
	elseif (iname == "FillColor") then
		self:WriteCell(1048574,value)
	elseif (iname == "ClearCol") then
		self:WriteCell(1048571,math.Clamp( value, 0, 31 ))
	elseif (iname == "ClearRow") then
		self:WriteCell(1048570,math.Clamp( value, 0, 31 ))
	end
end


function MakeWireDigitalScreen( pl, Pos, Ang, model, ScreenWidth, ScreenHeight )

	if (pl!=nil) then if ( !pl:CheckLimit( "wire_digitalscreens" ) ) then return false end end

	local wire_digitalscreen = ents.Create( "gmod_wire_digitalscreen" )
	if (!wire_digitalscreen:IsValid()) then return false end
	wire_digitalscreen:SetModel(model)

	if (not ScreenWidth) then ScreenWidth = 32 end
	if (not ScreenHeight) then ScreenHeight = 32 end

	wire_digitalscreen:SetAngles( Ang )
	wire_digitalscreen:SetPos( Pos )
	wire_digitalscreen:Spawn()
	wire_digitalscreen:SetDigitalSize(ScreenWidth,ScreenHeight)

	wire_digitalscreen:SetPlayer(pl)

	if (pl!=nil) then pl:AddCount( "wire_digitalscreens", wire_digitalscreen ) end

	return wire_digitalscreen
end

duplicator.RegisterEntityClass("gmod_wire_digitalscreen", MakeWireDigitalScreen, "Pos", "Ang", "Model", "ScreenWidth", "ScreenHeight")
