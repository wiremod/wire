AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

function ENT:Initialize()

	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "PixelX", "PixelY", "PixelG", "Clk", "FillColor", "ClearRow", "ClearCol" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" })

	self.Memory = {}

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Memory[1048575] = 1

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	self.DataCache = WireLib.containers.new(WireLib.containers.deque)

	self.IgnoreDataTransfer = false
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

local per_tick = 8
hook.Add("Think", "resetdigitickrate", function()
	per_tick = math.min(per_tick+2,8)
end)

function ENT:FlushCache()
	if per_tick <= 0 then return end
	if self.DataCache:size() == 0 then return end

	per_tick = per_tick - 1
	umsg.Start("hispeed_datamessage")
		umsg.Short(self:EntIndex())
		local bytes = math.min(self.DataCache:size(), 31)
		umsg.Char(bytes)
		for i = 1,bytes do
			local element = self.DataCache:shift()
			umsg.Long(element[1])
			umsg.Long(element[2])
		end

	umsg.End()
	self:FlushCache() -- re-flush until the quota is used up or the cache is empty
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

function ENT:WriteCell(Address, value)
	if Address < 0 then return false end
	if Address >= 1048576 then return false end

	if Address < 1048500 then -- RGB data
		if self.Memory[Address] == value then return true end
	else
		if Address == 1048569 then -- Color mode (0: RGBXXX; 1: R G B; 2: 24 bit RGB; 3: RRRGGGBBB)
			-- not needed (yet)
		elseif Address == 1048570 then -- Clear row
			local row = math.Clamp(value, 0, self.ScreenHeight-1)
			for i = row*self.ScreenWidth,(row+1)*self.ScreenWidth-1 do
				self:ClearPixel(i)
			end
		elseif Address == 1048571 then -- Clear column
			local col = math.Clamp(value, 0, self.ScreenWidth-1)
			for i = col,col+self.ScreenWidth*(self.ScreenHeight-1),self.ScreenWidth do
				self:ClearPixel(i)
			end
		elseif Address == 1048572 then -- Height
			self.ScreenHeight = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048573 then -- Width
			self.ScreenWidth  = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048574 then -- Hardware Clear Screen
			for i = 0,self.ScreenWidth*self.ScreenHeight-1 do
				self:ClearPixel(i)
			end
		elseif Address == 1048575 then -- CLK
			-- not needed atm
		end
	end

	self.Memory[Address] = value

	self.DataCache:push({ Address, value })

	if per_tick > 0 and self.DataCache:size() >= 31 then
		self:FlushCache()
		self.IgnoreDataTransfer = true
	end
	return true
end

function ENT:Think()
	if (self.IgnoreDataTransfer == true) then
		self.IgnoreDataTransfer = false
		self.Entity:NextThink(CurTime()+0.2)
	else
		self:FlushCache()
		self.Entity:NextThink(CurTime()+0.1)
	end
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

	if ( !pl:CheckLimit( "wire_digitalscreens" ) ) then return false end

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

	pl:AddCount( "wire_digitalscreens", wire_digitalscreen )

	return wire_digitalscreen
end

duplicator.RegisterEntityClass("gmod_wire_digitalscreen", MakeWireDigitalScreen, "Pos", "Ang", "Model", "ScreenWidth", "ScreenHeight")
