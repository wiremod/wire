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
	local name = EGP.Objects.Names_Inverted[ID]
	if name then return table.Copy(EGP.Objects[name]) end
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
function EGP:HasObject( Ent, indexObj )
	if not EGP:ValidEGP(Ent) then return false end
	if not Ent.RenderTable or #Ent.RenderTable == 0 then return false end
	
	local needle = Ent.RenderTable_Indices[indexObj]
	if needle then return true, needle, Ent.RenderTable[needle] end
	
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
local makeTable = {}
function EGP:PerformReorder_Ex(Ent, i, maxn)
	local obj = Ent.RenderTable[i]
	local idx = obj.index
	if obj then
		-- Check if this object has already been reordered
		if already_reordered[idx] then
			-- if yes, get its new position (or old position if it didn't change)
			return already_reordered[idx]
		end

		-- Set old position (to prevent recursive loops)
		already_reordered[idx] = i

		if obj.ChangeOrder then
			local target = obj.ChangeOrder.target
			local dir = obj.ChangeOrder.dir

			local target_idx = 0
			if dir == 0 then
				-- target is absolute position
				target_idx = target
			else
				-- target is relative position
				local bool, k = self:HasObject( Ent, target )
				if bool then
					-- Check for order dependencies
					k = self:PerformReorder_Ex( Ent, k, maxn ) or k

					target_idx = k + dir
				else
					target_idx = target
				end
			end

			if target_idx > 0 then
				-- Make a copy of the object and insert it at the new position
				target_idx = math.Clamp(target_idx, 1, maxn)
				local idxRT = Ent.RenderTable_Indices[idx]
				if idxRT ~= target_idx then
					EGP:_MoveObject(Ent, idxRT, target_idx, idx)
				end
				
				obj.ChangeOrder = nil

				-- Update already reordered reference to new position
				already_reordered[idx] = target_idx

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
	makeTable = {}

	-- Now we remove at first and create later, how fun
	local maxn = #Ent.RenderTable
	for i, _ in pairs(Ent.RenderTable) do
		self:PerformReorder_Ex( Ent, i , maxn)
	end
	
	for target_idx, v in pairs(makeTable) do
		EGP:_InsertObject(Ent, v[1], v[2], target_idx)
	end

	-- Clear some memory
	already_reordered = {}
	makeTable = {}
end

----------------------------
-- Create / edit objects
----------------------------

function EGP:CreateObject( Ent, ObjID, Settings )
	if not self:ValidEGP(Ent) then return false end

	if not EGP.Objects.Names_Inverted[ObjID] then
		ErrorNoHalt("Trying to create nonexistant object! Please report this error to the Wiremod team. ObjID: " .. ObjID .. "\n")
		return false
	end

	if Settings.index < 1 or #Ent.RenderTable >= self.ConVars.MaxObjects:GetInt() then return false end

	local bool, k, v = self:HasObject(Ent, Settings.index)
	if bool then -- Already exists. Change settings:
		if v.ID ~= ObjID then -- Not the same kind of object, create new
			local Obj = self:GetObjectByID( ObjID )
			self:EditObject( Obj, Settings )
			Obj.index = Settings.index
			Ent.RenderTable[k] = Obj
			Ent.RenderTable_Indices[Settings.index] = k
			return true, Obj
		else
			return self:EditObject( v, Settings ), v
		end
	else -- Did not exist. Create:
		local Obj = self:GetObjectByID( ObjID )
		self:EditObject( Obj, Settings )
		Obj.index = Settings.index
		EGP:_InsertObject(Ent, Obj, Settings.index)
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

--Helper function just because now we need to keep track of indices
function EGP:_RemoveObject(ent, indexRT, indexObj)
	if not indexObj then
		indexObj = table.remove(ent.RenderTable, indexRT).index
	else
		table.remove(ent.RenderTable, indexRT)
	end
	
	ent.RenderTable_Indices[indexObj] = nil
	
	-- Shift all the values down one.
	for i, v in pairs(ent.RenderTable_Indices) do
		if v > indexRT then ent.RenderTable_Indices[i] = v - 1 end
	end
end

function EGP:_InsertObject(ent, obj, indexObj, indexRT)
	if not indexRT then indexRT = #ent.RenderTable + 1 end
	
	ent.RenderTable_Indices[indexObj or obj.index] = table.insert(ent.RenderTable, indexRT, obj)
	
	for i, v in pairs(ent.RenderTable_Indices) do
		if v > indexRT then ent.RenderTable_Indices[i] = v + 1 end
	end
end

function EGP:_MoveObject(ent, indexRTFrom, indexRTTo, indexObj)
	local obj = table.remove(ent.RenderTable, indexRTFrom)
	
	if ent.RenderTable_Indices[indexObj or obj.index]  == indexRTTo then return end
	
	ent.RenderTable_Indices[indexObj or obj.index] = table.insert(ent.RenderTable, indexRTTo, obj)
	
	-- Shift values such that only values between indexRTFrom and indexRTTo are modified
	for i, v in pairs(ent.RenderTable_Indices) do
		if i ~= indexObj then
			if v >= indexRTTo and v < indexRTFrom then ent.RenderTable_Indices[i] = v + 1
			elseif v > indexRTFrom and v <= indexRTTo then ent.RenderTable_Indices[i] = v - 1 end
		end
	end
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
