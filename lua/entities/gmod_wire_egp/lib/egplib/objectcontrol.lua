--------------------------------------------------------
-- Objects
--------------------------------------------------------
local EGP = EGP

EGP.Objects = {}
EGP.Objects.Names = {}
EGP.Objects.Names_Inverted = {}

-- This object is not used. It's only a base
EGP.Objects.Base = {}
EGP.Objects.Base.ID = 0
EGP.Objects.Base.x = 0
EGP.Objects.Base.y = 0
EGP.Objects.Base.w = 0
EGP.Objects.Base.h = 0
EGP.Objects.Base.r = 255
EGP.Objects.Base.g = 255
EGP.Objects.Base.b = 255
EGP.Objects.Base.a = 255
EGP.Objects.Base.filtering = TEXFILTER.ANISOTROPIC
EGP.Objects.Base.material = ""
if CLIENT then EGP.Objects.Base.material = false end
EGP.Objects.Base.parent = 0
EGP.Objects.Base.Transmit = function( self )
	EGP:SendPosSize( self )
	EGP:SendColor( self )
	EGP:SendMaterial( self )
	net.WriteUInt(math.Clamp(self.filtering,0,3), 2)
	net.WriteInt( self.parent, 16 )
end
EGP.Objects.Base.Receive = function( self )
	local tbl = {}
	EGP:ReceivePosSize( tbl )
	EGP:ReceiveColor( tbl, self )
	EGP:ReceiveMaterial( tbl )
	tbl.filtering = net.ReadUInt(2)
	tbl.parent = net.ReadInt(16)
	return tbl
end
EGP.Objects.Base.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, w = self.w, h = self.h, r = self.r, g = self.g, b = self.b, a = self.a, material = self.material, filtering = self.filtering, parent = self.parent }
end
function EGP.Objects.Base:Contains(point)
	return false
end

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
	if self.Objects[Name] then return self.Objects[Name] end

	-- Create table
	self.Objects[Name] = {}
	-- Set info
	self.Objects[Name].Name = Name
	table.Inherit( self.Objects[Name], self.Objects.Base )

	-- Create lookup table
	local ID = table.Count(self.Objects)
	self.Objects[Name].ID = ID
	self.Objects.Names[Name] = ID

	-- Inverted lookup table
	self.Objects.Names_Inverted[ID] = Name

	return self.Objects[Name]
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
	if not self:ValidEGP(Ent) then return false end

	if not self.Objects.Names_Inverted[ObjID] then
		ErrorNoHalt("Trying to create nonexistant object! Please report this error to Divran at wiremod.com. ObjID: " .. ObjID .. "\n")
		return false
	end

	if SERVER then Settings.index = math.Round(math.Clamp(Settings.index or 1, 1, self.ConVars.MaxObjects:GetInt())) end

	local bool, k, v = self:HasObject( Ent, Settings.index )
	if (bool) then -- Already exists. Change settings:
		if v.ID ~= ObjID then -- Not the same kind of object, create new
			local Obj = self:GetObjectByID( ObjID )
			self:EditObject( Obj, Settings )
			Obj.index = Settings.index
			Ent.RenderTable[k] = Obj
			return true, Obj
		else
			return self:EditObject( v, Settings ), v
		end
	else -- Did not exist. Create:
		local Obj = self:GetObjectByID( ObjID )
		self:EditObject( Obj, Settings )
		Obj.index = Settings.index
		table.insert( Ent.RenderTable, Obj )
		return true, Obj
	end
end

function EGP:EditObject( Obj, Settings )
	local ret = false
	for k,v in pairs( Settings ) do
		if (Obj[k] ~= nil and Obj[k] ~= v) then
			Obj[k] = v
			ret = true
		end
	end
	return ret
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
