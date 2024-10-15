local EGP = E2Lib.EGP
---@type { [string]: EGPObject, [integer]: EGPObject }
local objects = {}
--- All implemented objects. The array part represents EGP Object IDs. The table part represents EGP Object names.
EGP.Objects = objects

local validEGP
local maxObjects
EGP.HookPostInit(function()
	validEGP = EGP.ValidEGP
	maxObjects = EGP.ConVars.MaxObjects
end)

---@class EGPObject
---@field ID integer? nil when NULL
---@field index integer
local baseObj = {
	ID = 0,
	x = 0,
	y = 0,
	angle = 0,
	r = 255,
	g = 255,
	b = 255,
	a = 255,
	filtering = TEXFILTER.ANISOTROPIC,
	parent = 0
}
if SERVER then
	baseObj.material = ""
	baseObj.EGP = NULL --[[@as Entity]] -- EGP entity parent
else
	baseObj.material = false
end

--- Used in a net writing context to transmit the object's entire data.
---@see EGPObject.Receive
function baseObj:Transmit()
	EGP.SendPosAng(self)
	EGP.SendColor(nil, self)
	EGP.SendMaterial(nil, self)
	if self.filtering then net.WriteUInt(math.Clamp(self.filtering, 0, 3), 2) end
	net.WriteInt(self.parent, 16)
end
--- Used in a net reading context to read the object's entire data.
---@see EGPObject.Transmit
function baseObj:Receive()
	local tbl = {}
	EGP.ReceivePosAng(tbl)
	EGP.ReceiveColor(nil, tbl, self)
	EGP.ReceiveMaterial(nil, tbl)
	if self.filtering then tbl.filtering = net.ReadUInt(2) end
	tbl.parent = net.ReadInt(16)
	return tbl
end

--- Returns a table of data that needs to be transferred in EGP messages.
function baseObj:DataStreamInfo()
	return { x = self.x, y = self.y, angle = self.angle, r = self.r, g = self.g, b = self.b, a = self.a, material = self.material, parent = self.parent }
end
--- Returns `true` if the object contains the point.
---@param x number
---@param y number
---@return boolean
function baseObj:Contains(x, y)
	return false
end

if false then
	--- Called when the object is removed.
	function baseObj:OnRemove() end
end

--- Edits the fields of the EGPObject with the given table. Returns `true` if a field changed.
--- Use `SetPos` for setting position directly. Use `Set` to set a single field.
---@param args { [string]: any } The fields to edit on the object. Values are *not* guaranteed to be type checked or sanity checked!
---@return boolean # Whether the object changed
---@see EGPObject.SetPos
---@see EGPObject.Set
function baseObj:EditObject(args)
	local ret = false
	if args.x or args.y or args.angle then
		ret = self:SetPos(args.x or self.x, args.y or self.y, args.angle or self.angle)
		args.x, args.y, args.angle = nil, nil, nil
	end
	for k, v in pairs(args) do
		if self[k] ~= nil and self[k] ~= v then
			if CLIENT and k == "material" and isstring(v) then
				self[k] = Material(v)
			else
				self[k] = v
			end
			ret = true
		end
	end
	return ret
end

--- A helper method for objects that may need to do something on initialization. Calls `EditObject` by default.
---@param args { [string]: any }
---@see EGPObject.EditObject
function baseObj:Initialize(args) self:EditObject(args) end

--- Sets the position of the EGPObject directly. This method should be overridden if special behavior is needed.
--- Call this method when you need to change position.
---@param x number
---@param y number
---@param angle number In degrees
---@return boolean # Whether the position changed
---@see EGPObject.EditObject
function baseObj:SetPos(x, y, angle)
	local ret = false
	if x and self.x ~= x then self.x, ret = x, true end
	if y and self.y ~= y then self.y, ret = y, true end
	if angle then
		angle = angle % 360
		if self.angle ~= angle then self.angle, ret = angle, true end
	end
	if SERVER and self._x then
		if x then self._x = x end
		if y then self._y = y end
		if angle then self._angle = angle end
	end
	return ret
end

--- Sets a single field of the EGP Object. Do **not** use this for position. Use `SetPos` instead.
---@param k string
---@param v any
---@return boolean # Whether the field changed
function baseObj:Set(k, v)
	local kx, ky, ka = k == "x", k == "y", k == "angle"
	if kx or ky or ka then
		return self:SetPos(kx and v or self.x, ky and v or self.y, ka and v or self.angle)
	end
	if self[k] and self[k] ~= v then
		self[k] = v
		return true
	else
		return false
	end
end

local EGPObject = {}
EGPObject.__index = EGPObject
function EGPObject:__tostring()
	return "[EGPObject] ".. (self.Name or "NULL")
end
function EGPObject:__eq(a, b)
	return  a and b and a.ID == b.ID
end
function EGPObject:IsValid()
	return self and self.ID ~= nil
end

-- The EGPObject metatable
EGP.EGPObject = EGPObject
setmetatable(baseObj, EGPObject)
objects.Base = baseObj

---@type EGPObject
local NULL_EGPOBJECT = setmetatable({}, EGPObject)
--- An invalid EGPObject
EGP.Objects.NULL_EGPOBJECT = NULL_EGPOBJECT

--- Returns true if the input is an EGP Object
local function isEGPObject(obj)
	return istable(obj) and getmetatable(obj) == EGPObject
end
EGP.IsEGPObject = isEGPObject

----------------------------
-- Load all objects
----------------------------
do
	local yielded = {}

	---@generic NewEGPObject:EGPObject
	--- Creates a new EGPObject class and returns it reference. If you want to inherit from another class, see `EGP.ObjectInherit`, which properly handles out-of-order loading.
	---@param name string The name of the class. Case sensitive.
	---@param super EGPObject? The superclass of the class. If nil, defaults to base object.
	---@return  NewEGPObject # The EGPObject class
	---@see EGP.ObjectInherit
	local function newObject(name, super)
		if objects[name] then return objects[name] end

		if not super then super = baseObj end

		local newObj = {}

		newObj.Name = name
		table.Inherit(newObj, super)

		local ID = #objects + 1
		newObj.ID = ID

		newObj = setmetatable(newObj, EGPObject)

		objects[name] = newObj
		objects[ID] = newObj

		return newObj
	end
	EGP.NewObject = newObject

	---@generic NewEGPObject:EGPObject
	--- Used to inherit from another EGPObject class. This uses EGP.NewObject internally, so you should not call that.
	---@param to string The new class name
	---@param from string The superclass name
	---@return NewEGPObject # The EGPObject class with inheritance
	function EGP.ObjectInherit(to, from)
		local super = objects[from]
		if super then
			return newObject(to, super)
		else
			error({ from })
		end
	end

	local FOLDER = "entities/gmod_wire_egp/lib/objects/"
	local files = file.Find(FOLDER .. "*.lua", "LUA")
	for _, v in ipairs(files) do
		local p = FOLDER .. v
		local fn = CompileFile(p)
		local wrap = function()
			local ok, super = pcall(fn)
			if ok then
				AddCSLuaFile(p)
				return
			elseif istable(super) then
				return super[1]
			else
				ErrorNoHalt(super .. "\n") -- Rethrow the error
			end
		end
		local ret = wrap()
		if ret ~= nil then
			local t = yielded[ret]
			if not t then
				t = {}
				yielded[ret] = t
			end
			table.insert(t, wrap)
		end
	end

	for name, t in pairs(yielded) do
		if objects[name] then
			for _, v in ipairs(t) do
				if yielded[name] then
					v()
				end
			end
		else
			ErrorNoHalt("EGP Error: Missing dependency " .. name .. ". " .. #t .. " objects will not be loaded.\n")
		end
	end
end

--- Checks if the object exists on the screen.
---@param egp Entity
---@param index EGPObject|integer The EGPObject or EGP index to find
---@return boolean found Whether the object exists
---@return integer? index The Render Table index if it exists
---@return EGPObject? object The found EGPObject if it exists
local function hasObject(egp, index)
	if not validEGP(nil, egp) then return false end
	local renderTable = egp.RenderTable
	if not renderTable or #renderTable == 0 then return false end

	if isEGPObject(index) then
		if index.EGP == egp then
			index = index.index
		else
			return false
		end
	end
	---@cast index -EGPObject

	if SERVER then index = math.Round(math.Clamp(index or 1, 1, maxObjects:GetInt())) end

	for k, v in ipairs(renderTable) do
		if v.index == index then
			return true, k, v
		end
	end
	return false
end
EGP.HasObject = hasObject

----------------------------
-- Object order changing
----------------------------

function EGP.SetOrder(ent, from, to, dir)
	if not ent.RenderTable or #ent.RenderTable == 0 then return false end
	dir = dir or 0

	if ent.RenderTable[from] then
		to = math.Clamp(math.Round(to or 1), 1, #ent.RenderTable)
		if SERVER then ent.RenderTable[from].ChangeOrder = { target = to, dir = dir } end
		return true
	end
	return false
end

local already_reordered = {}
local function performReorder_ex(ent, originIdx, maxn)
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
				local bool, k = hasObject(ent, target)
				if bool then
					-- Check for order dependencies
					k = performReorder_ex(ent, k, maxn) or k

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

function EGP.PerformReorder(ent)
	-- Reset, just to be sure
	already_reordered = {}

	-- Now we remove and create at the same time!
	local maxn = #ent.RenderTable
	for i, _ in ipairs(ent.RenderTable) do
		performReorder_ex(ent, i, maxn)
	end

	-- Clear some memory
	already_reordered = {}
end

----------------------------
-- Create / edit objects
----------------------------

--- Attempts to create an instance of an EGPObject. Returns `true` and the object if the operation succeeded.
---@param id string|integer The EGPObject class name or ID
---@param settings { [string]: any } The data to initialize the object with
---@param egp Entity The EGP to create the object on
---@return boolean
---@return EGPObject
local function create(id, settings, egp)
	if not validEGP(nil, egp) then return false, NULL_EGPOBJECT end

	local class = objects[id]
	if not class then
		ErrorNoHalt(string.format("Trying to create nonexistant object! Object %s: %s\n", isnumber(id) and "ID" or "name",
			isnumber(id) and tostring(id) or id))
		return false, NULL_EGPOBJECT
	end

	if SERVER then settings.index = math.Round(math.Clamp(settings.index or 1, 1, maxObjects:GetInt())) end
	settings.EGP = egp

	local index = settings.index
	settings.index = nil

	local bool, k, obj = hasObject(egp, index)
	if bool then -- Already exists. Change settings:
		---@cast obj -?
		if obj.ID ~= class.ID  then -- Not the same kind of object, create new
			obj = table.Copy(class)
			obj:Initialize(settings)
			obj.index = index
			egp.RenderTable[k] = obj
			return true, obj
		else
			return obj:EditObject(settings), obj
		end
	else -- Did not exist. Create:
		---@type EGPObject
		obj = table.Copy(class)
		obj:Initialize(settings)
		obj.index = index
		table.insert(egp.RenderTable, obj)
		return true, obj
	end
end
EGP.Create = create

--------------------------------------------------------
--  Homescreen
--------------------------------------------------------

--- The EGP homescreen that appears when you first create an EGP
---@type EGPObject[]
EGP.HomeScreen = {}

local mat
if CLIENT then mat = Material else mat = function( str ) return str end end

-- Create table
local tbl = {
	{ objects.Box, { x = 256, y = 256, h = 356, w = 356, material = mat("expression 2/cog"), r = 150, g = 34, b = 34, a = 255 } },
	{ objects.Text, {x = 256, y = 256, text = "EGP 3", font = "WireGPU_ConsoleFont", valign = 1, halign = 1, size = 50, r = 135, g = 135, b = 135, a = 255 } }
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
for k, v in ipairs(tbl) do
	local obj = table.Copy(v[1])
	obj.index = k
	for k2, v2 in pairs(v[2]) do
		if obj[k2] ~= nil then obj[k2] = v2 end
	end
	table.insert(EGP.HomeScreen, obj)
end