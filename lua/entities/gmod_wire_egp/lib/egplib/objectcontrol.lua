--------------------------------------------------------
-- Objects
--------------------------------------------------------
local EGP = EGP

EGP.Objects = {}
EGP.Objects.Names = {}
EGP.Objects.Names_Inverted = {}

-- This object is not used. It's only a base
local baseObj = {}
baseObj.ID = 0
baseObj.x = 0
baseObj.y = 0
baseObj.angle = 0
baseObj.w = 0
baseObj.h = 0
baseObj.r = 255
baseObj.g = 255
baseObj.b = 255
baseObj.a = 255
baseObj.filtering = TEXFILTER.ANISOTROPIC
baseObj.material = ""
if CLIENT then baseObj.material = false end
baseObj.parent = 0
baseObj.EGP = NULL -- EGP entity parent
function baseObj:Transmit()
	EGP:SendPosSize( self )
	EGP:SendColor( self )
	EGP:SendMaterial( self )
	net.WriteUInt(math.Clamp(self.filtering,0,3), 2)
	net.WriteInt( self.parent, 16 )
end
function baseObj:Receive()
	local tbl = {}
	EGP:ReceivePosSize( tbl )
	EGP:ReceiveColor( tbl, self )
	EGP:ReceiveMaterial( tbl )
	tbl.filtering = net.ReadUInt(2)
	tbl.parent = net.ReadInt(16)
	return tbl
end
function baseObj:DataStreamInfo()
	return { x = self.x, y = self.y, w = self.w, h = self.h, r = self.r, g = self.g, b = self.b, a = self.a, material = self.material, filtering = self.filtering, parent = self.parent }
end
function baseObj:Contains(x, y)
	return false
end
function baseObj:EditObject(args)
	local ret = false
	for k, v in pairs(args) do
		if self[k] ~= nil and self[k] ~= v then
			self[k] = v
			ret = true
		end
	end
	return ret
end
baseObj.Initialize = baseObj.EditObject
function baseObj:SetPos(x, y, angle)
	local ret = false
	if self.x ~= x then self.x, ret = x, true end
	if self.y ~= y then self.y, ret = y, true end
	if angle and self.angle ~= angle then self.angle, ret = angle, true end
	return ret
end
function baseObj:Set(member, value)
	if self[member] and self[member] ~= value then
		self[member] = value
		return true
	else
		return false
	end
end
local M_EGPObject = {__tostring = function(self) return "[EGPObject] ".. self.Name end}
setmetatable(baseObj, M_EGPObject)
EGP.Objects.Base = baseObj

local M_NULL_EGPOBJECT = { __tostring = function(self) return "[EGPObject] NULL" end, __eq = function(a, b) return getmetatable(a) == getmetatable(b) end }
local NULL_EGPOBJECT = setmetatable({}, M_NULL_EGPOBJECT)
EGP.NULL_EGPOBJECT = NULL_EGPOBJECT

----------------------------
-- Get Object
----------------------------

function EGP:GetObjectByID( ID )
	for _, v in pairs( EGP.Objects ) do
		if (v.ID == ID) then return table.Copy( v ) end
	end
	ErrorNoHalt( "[EGP] Error! Object with ID '" .. ID .. "' does not exist. Please post this bug message in the EGP thread on the wiremod forums.\n" )
end

----------------------------
-- Load all objects
----------------------------

function EGP:NewObject( Name )
	local lower = Name:lower() -- Makes my life easier
	if self.Objects[lower] then return self.Objects[lower] end

	-- Create table
	self.Objects[lower] = {}
	-- Set info
	self.Objects[lower].Name = Name
	table.Inherit(self.Objects[lower], self.Objects.Base)

	-- Create lookup table
	local ID = table.Count(self.Objects)
	self.Objects[lower].ID = ID
	self.Objects.Names[Name] = ID

	-- Inverted lookup table
	self.Objects.Names_Inverted[ID] = lower

	return setmetatable(self.Objects[lower], M_EGPObject)
end

local folder = "entities/gmod_wire_egp/lib/objects/"
local files = file.Find(folder.."*.lua", "LUA")
table.sort( files )
for _,v in pairs( files ) do
	include(folder..v)
	if (SERVER) then AddCSLuaFile(folder..v) end
end

----------------------------
-- Object existance check
----------------------------
function EGP:HasObject( Ent, index )
	if not EGP:ValidEGP(Ent) then return false end
	if SERVER then index = math.Round(math.Clamp(index or 1, 1, self.ConVars.MaxObjects:GetInt())) end
	if not Ent.RenderTable or #Ent.RenderTable == 0 then return false end
	for k,v in pairs( Ent.RenderTable ) do
		if (v.index == index) then
			return true, k, v
		end
	end
	return false
end

----------------------------
-- Object order changing
----------------------------
function EGP:SetOrder(ent, from, to, dir)
	if not ent.RenderTable or #ent.RenderTable == 0 then return false end
	dir = dir or 0

	if ent.RenderTable[from] then
		to = math.Clamp(math.Round(to or 1),1,#ent.RenderTable)
		if SERVER then ent.RenderTable[from].ChangeOrder = {target=to,dir=dir} end
		return true
	end
	return false
end

local already_reordered = {}
function EGP:PerformReorder_Ex(ent, originIdx, maxn)
	local obj = ent.RenderTable[originIdx]
	local idx = obj.index
	if obj then
		-- Check if this object has already been reordered
		if already_reordered[idx] then
			-- if yes, get its new position (or old position if it didn't change)
			return already_reordered[idx]
		end

		-- Set old position (to prevent recursive loops)
		already_reordered[idx] = originIdx

		if obj.ChangeOrder then
			local target = obj.ChangeOrder.target
			local dir = obj.ChangeOrder.dir

			local targetIdx = 0
			if dir == 0 then
				-- target is absolute position
				targetIdx = target
			else
				-- target is relative position
				local bool, k = self:HasObject(ent, target)
				if bool then
					-- Check for order dependencies
					k = self:PerformReorder_Ex(ent, k, maxn) or k

					targetIdx = k + dir
				else
					targetIdx = target
				end
			end

			if targetIdx > 0 then
				-- Make a copy of the object and insert it at the new position
				targetIdx = math.Clamp(targetIdx, 1, maxn)
				if originIdx ~= targetIdx then
					local ob = table.remove(ent.RenderTable, originIdx)
					table.insert(ent.RenderTable, targetIdx, ob)
				end

				obj.ChangeOrder = nil

				-- Update already reordered reference to new position
				already_reordered[idx] = targetIdx

				return targetIdx
			else
				return originIdx
			end
		end
	end
end

function EGP:PerformReorder(ent)
	-- Reset, just to be sure
	already_reordered = {}

	-- Now we remove and create at the same time!
	local maxn = #ent.RenderTable
	for i, _ in ipairs(ent.RenderTable) do
		self:PerformReorder_Ex(ent, i, maxn)
	end

	-- Clear some memory
	already_reordered = {}
end

----------------------------
-- Create / edit objects
----------------------------

function EGP:CreateObject( Ent, ObjID, Settings )
	if not self:ValidEGP(Ent) then return false, NULL_EGPOBJECT end

	if not self.Objects.Names_Inverted[ObjID] then
		ErrorNoHalt("Trying to create nonexistant object! Please report this error to Divran at wiremod.com. ObjID: " .. ObjID .. "\n")
		return false, NULL_EGPOBJECT
	end

	if SERVER then Settings.index = math.Round(math.Clamp(Settings.index or 1, 1, self.ConVars.MaxObjects:GetInt())) end
	Settings.EGP = Ent

	local bool, k, v = self:HasObject( Ent, Settings.index )
	if (bool) then -- Already exists. Change settings:
		if v.ID ~= ObjID then -- Not the same kind of object, create new
			local Obj = self:GetObjectByID( ObjID )
			Obj:Initialize(Settings)
			Obj.index = Settings.index
			Ent.RenderTable[k] = Obj
			return true, Obj
		else
			return v:EditObject(Settings), v
		end
	else -- Did not exist. Create:
		local Obj = self:GetObjectByID( ObjID )
		Obj:Initialize(Settings)
		Obj.index = Settings.index
		table.insert( Ent.RenderTable, Obj )
		return true, Obj
	end
end

function EGP:EditObject(obj, settings)
	return obj:EditObject(settings)
end



--------------------------------------------------------
--  Homescreen
--------------------------------------------------------

EGP.HomeScreen = {}

local mat
if CLIENT then mat = Material else mat = function( str ) return str end end

-- Create table
local tbl = {
	{ ID = EGP.Objects.Names["Box"], Settings = { x = 256, y = 256, h = 356, w = 356, material = mat("expression 2/cog"), r = 150, g = 34, b = 34, a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {x = 256, y = 256, text = "EGP 3", font = "WireGPU_ConsoleFont", valign = 1, halign = 1, size = 50, r = 135, g = 135, b = 135, a = 255 } }
}

--[[ Old homescreen (EGP v2 home screen design contest winner)
local tbl = {
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 362, h = 362, material = true, angle = 135, 					r = 75,  g = 75, b = 200, a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 340, h = 340, material = true, angle = 135, 					r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 229, y = 28,  text =   "E", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {	 	x = 50,  y = 200, text =   "G", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 400, y = 200, text =   "P", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 228, y = 375, text =   "2", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 256, h = 256, material = mat("expression 2/cog"), angle = 45, 		r = 255, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 128, y = 241, w = 256, h = 30, 	material = true, 									r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 241, y = 128, w = 30,  h = 256, material = true, 									r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Circle"], Settings = {	x = 256, y = 256, w = 70,  h = 70, 	material = true, 									r = 255, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {	 	x = 256, y = 256, w = 362, h = 362, material = mat("gui/center_gradient"), angle = 135, 	r = 75,  g = 75, b = 200, a = 75  } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 362, h = 362, material = mat("gui/center_gradient"), angle = 135, 	r = 75,  g = 75, b = 200, a = 75  } }
}
]]

-- Convert table
for k,v in pairs( tbl ) do
	local obj = EGP:GetObjectByID( v.ID )
	obj.index = k
	for k2,v2 in pairs( v.Settings ) do
		if obj[k2] ~= nil then obj[k2] = v2 end
	end
	table.insert( EGP.HomeScreen, obj )
end
