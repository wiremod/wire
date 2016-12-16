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
EGP.Objects.Base.material = ""
if CLIENT then EGP.Objects.Base.material = false end
EGP.Objects.Base.parent = 0
EGP.Objects.Base.Transmit = function( self )
	EGP:SendPosSize( self )
	EGP:SendColor( self )
	EGP:SendMaterial( self )
	net.WriteInt( self.parent, 16 )
end
EGP.Objects.Base.Receive = function( self )
	local tbl = {}
	EGP:ReceivePosSize( tbl )
	EGP:ReceiveColor( tbl, self )
	EGP:ReceiveMaterial( tbl )
	tbl.parent = net.ReadInt(16)
	return tbl
end
EGP.Objects.Base.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, w = self.w, h = self.h, r = self.r, g = self.g, b = self.b, a = self.a, material = self.material, parent = self.parent }
end

----------------------------
-- Get Object
----------------------------

function EGP:GetObjectByID( ID )
	for k,v in pairs( EGP.Objects ) do
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
	if (!EGP:ValidEGP( Ent )) then return false end
	if SERVER then index = math.Round(math.Clamp(index or 1, 1, self.ConVars.MaxObjects:GetInt())) end
	if (!Ent.RenderTable or #Ent.RenderTable == 0) then return false end
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
function EGP:SetOrder( Ent, from, to, dir )
	if not Ent.RenderTable or #Ent.RenderTable == 0 then return false end
	dir = dir or 0

	if Ent.RenderTable[from] then
		to = math.Clamp(math.Round(to or 1),1,#Ent.RenderTable)
		if SERVER then Ent.RenderTable[from].ChangeOrder = {target=to,dir=dir} end
		return true
	end
	return false
end

local already_reordered = {}
function EGP:PerformReorder_Ex( Ent, i )
	local obj = Ent.RenderTable[i]
	if obj then
		-- Check if this object has already been reordered
		if already_reordered[obj.index] then
			-- if yes, get its new position (or old position if it didn't change)
			return already_reordered[obj.index]
		end

		-- Set old position (to prevent recursive loops)
		already_reordered[obj.index] = i

		if obj.ChangeOrder then
			local target = obj.ChangeOrder.target
			local dir = obj.ChangeOrder.dir

			local target_idx = 0
			if dir == 0 then
				-- target is absolute position
				target_idx = target
			else
				-- target is relative position
				local bool, k, v = self:HasObject( Ent, target )
				if bool then
					-- Check for order dependencies
					k = self:PerformReorder_Ex( Ent, k ) or k

					target_idx = k + dir
				end
			end

			if target_idx ~= 0 then
				-- Make a copy of the object and insert it at the new position
				local copy = table.Copy(obj)
				copy.ChangeOrder = nil
				table.insert( Ent.RenderTable, target_idx, copy )

				-- Update already reordered reference to new position
				already_reordered[obj.index] = target_idx

				return target_idx
			else
				return i
			end
		end
	end
end

function EGP:PerformReorder( Ent )
	-- Reset, just to be sure
	already_reordered = {}

	-- First pass, insert objects at their wanted position
	for i=1,#Ent.RenderTable do
		self:PerformReorder_Ex( Ent, i )
	end

	-- Second pass, remove objects from their original positions
	for i=#Ent.RenderTable,1,-1 do
		local obj = Ent.RenderTable[i]
		if obj.ChangeOrder then
			table.remove( Ent.RenderTable, i )
		end
	end

	-- Clear some memory
	already_reordered = {}
end

----------------------------
-- Create / edit objects
----------------------------

function EGP:CreateObject( Ent, ObjID, Settings )
	if (!self:ValidEGP( Ent )) then return false end

	if (!self.Objects.Names_Inverted[ObjID]) then
		ErrorNoHalt("Trying to create nonexistant object! Please report this error to Divran at wiremod.com. ObjID: " .. ObjID .. "\n")
		return false
	end

	if SERVER then Settings.index = math.Round(math.Clamp(Settings.index or 1, 1, self.ConVars.MaxObjects:GetInt())) end

	local bool, k, v = self:HasObject( Ent, Settings.index )
	if (bool) then -- Already exists. Change settings:
		if (v.ID != ObjID) then -- Not the same kind of object, create new
			local Obj = {}
			Obj = self:GetObjectByID( ObjID )
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
	{ ID = EGP.Objects.Names["Text"], Settings = {x = 256, y = 256, text = "EGP 3", fontid = 1, valign = 1, halign = 1, size = 50, r = 135, g = 135, b = 135, a = 255 } }
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
