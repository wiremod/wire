--
--	File for EGP Object handling in E2.
--

-- Dumb but simple
local NULL_EGPOBJECT = EGP.NULL_EGPOBJECT
local M_NULL_EGPOBJECT = getmetatable(NULL_EGPOBJECT)
local M_EGPObject = getmetatable(EGP.Objects.Base)

local maxobjects = EGP.ConVars.MaxObjects

-- Table of allowed arguments and their types
local EGP_ALLOWED_ARGS =
	{
		x = "n",
		x2 = "n",
		y = "n",
		y2 = "n",
		z = "n",
		w = "n",
		h = "n",
		r = "n",
		g = "n",
		b = "n",
		a = "n",
		size = "n",
		angle = "n",
		fidelity = "n",
		radius = "n",
		valign = "n",
		halign = "n",
		text = "s",
		font = "s",
		material = "s",
	}

local function Update(self, this)
	self.data.EGP.UpdatesNeeded[this] = true
end

local function isValid(this)
	if this and getmetatable(this) ~= M_NULL_EGPOBJECT then return true else return false end
end

---- Type defintion

registerType("egpobject", "xeo", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if not istable(retval) then error("Return value is neither nil nor a table, but a " .. type(retval) .. "!", 0) end
		if not getmetatable(retval) == M_EGPObject then error("Return value is not an egpobject!", 0) end
	end,
	function(v)
		return not istable(v) or getmetatable(v) ~= M_EGPObject
	end
)

__e2setcost(2)

registerOperator("ass", "xeo", "xeo", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)
	if rhs == nil then return nil end

	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

e2function number operator_is(egpobject egpo)
	return (getmetatable(egpo) == M_EGPObject) and 1 or 0
end

e2function number operator==(egpobject lhs, egpobject rhs)
	return (lhs == rhs) and 1 or 0
end

e2function number operator!=(egpobject lhs, egpobject rhs)
	return (lhs ~= rhs) and 1 or 0
end

---- Functions

----------------------------
-- Table modification
----------------------------

__e2setcost(10)

e2function egpobject egpobject:modify(table arguments)
	local egp = this.EGP
	local converted = {}

	for k, v in pairs(arguments.s) do
		if EGP_ALLOWED_ARGS[k] == arguments.stypes[k] or false then converted[k] = v end
	end

	if this:EditObject(converted) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) return this end
end

--------------------------------------------------------
-- Order
--------------------------------------------------------

__e2setcost(15)

e2function void egpobject:egpOrder(order)
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	local bool, k = EGP:HasObject(egp, this.index)
	if (bool) then
		if EGP:SetOrder(egp, k, order) then
			EGP:DoAction(egp, self, "SendObject", this)
			Update(self, egp)
		end
	end
end

e2function number egpobject:egpOrder()
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	local bool, k = EGP:HasObject(egp, this.index)
	return bool and k or -1
end

e2function void egpobject:egpOrderAbove(egpobject abovethis)
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if not (isValid(this) or isValid(abovethis)) then self:throw("Invalid EGP Object") end
	local bool, k = EGP:HasObject(egp, this.index)
	if bool then
		if EGP:HasObject(egp, abovethis.index) then
			if EGP:SetOrder(egp, k, abovethis.index, 1) then
				EGP:DoAction(egp, self, "SendObject", this)
				Update(self, egp)
			end
		end
	end
end

e2function void egpobject:egpOrderBelow(egpobject belowthis)
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if not (isValid(this) or isValid(belowthis)) then self:throw("Invalid EGP Object") end
	local bool, k = EGP:HasObject(egp, this.index)
	if bool then
		if EGP:HasObject(egp, belowthis.index) then
			if EGP:SetOrder(egp, k, belowthis.index, -1) then
				EGP:DoAction(egp, self, "SendObject", this)
				Update(self, egp)
			end
		end
	end
end

----------------------------
-- Set Text
----------------------------

__e2setcost(7)

e2function void egpobject:egpSetText(string text)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("text", text) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpSetText(string text, string font, number size)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ text = text, font = font, size = size }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Alignment
----------------------------
e2function void egpobject:egpAlign(number halign)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("halign", math.Clamp(halign, 0, 2)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpAlign(number halign, number valign)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ valign = math.Clamp(valign, 0, 2), halign = math.Clamp(halign, 0, 2) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Filtering
----------------------------
e2function void egpobject:egpFiltering(number filtering)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("filtering", math.Clamp(filtering, 0, 3)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Font
----------------------------
e2function void egpobject:egpFont(string font)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if #font > 30 then return self:throw("Font string is too long!", nil) end
	if this:Set("font", font) then EGP:DoAction(egp, self, "SendObject", obj) Update(self, this) end
end

e2function void egpobject:egpFont(string font, number size)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if #font > 30 then return self:throw("Font string is too long!", nil) end
	if this:EditObject({ font = font, size = size }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

--------------------------------------------------------
-- 3DTracker
--------------------------------------------------------
__e2setcost(10)

e2function void egpobject:egpPos(vector pos)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ target_x = pos[1], target_y = pos[2], target_z = pos[3] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

--------------------------------------------------------
-- Set functions
--------------------------------------------------------

__e2setcost(7)
[nodiscard]
e2function number egpobject:egpIndex(index)
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	if this.index == index then return -1 end
	local egp = this.EGP
	local ret = 0

	local bool, k = EGP:HasObject(egp, index)
	if bool then table.remove(egp.RenderTable, k) ret = 1 end

	this.index = index

	EGP:DoAction(egp, self, "SendObject", this)
	Update(self, egp)
	return ret
end

----------------------------
-- Size
----------------------------
e2function void egpobject:egpSize(vector2 size)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ w = size[1], h = size[2] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpSize(width, height)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ w = width, h = height }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpSize(number size)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("size", size) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Position
----------------------------
e2function void egpobject:egpPos(vector2 pos)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(pos[1], pos[2]) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpPos(x, y)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpPos(x, y, x2, y2)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y, nil, x2, y2) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Angle
----------------------------
e2function void egpobject:egpAngle(number angle)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("angle", angle) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

-------------
-- Position & Angle
-------------
e2function void egpobject:egpPos(x, y, angle)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y, angle) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpAngle(vector2 worldpos, vector2 axispos, number angle)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this.x and this.y then
		local vec, ang = LocalToWorld(Vector(axispos[1], axispos[2], 0), angle_origin, Vector(worldpos[1], worldpos[2], 0), Angle(0, -angle, 0))

		local x = vec.x
		local y = vec.y

		angle = -ang.yaw

		local t = { x = x, _x = x, y = y, _y = y }
		if this.angle then t.angle, t._angle = angle, angle end

		if this:EditObject(t) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
	end
end

----------------------------
-- Polys
----------------------------

local maxVertices = EGP.ConVars.MaxVertices

e2function void egpobject:egpSetVertices(array verts)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	if not this.vertices then return end
	if #verts < 3 then return end
	local max = maxVertices:GetInt()

	local vertices = {}
	for _, v in ipairs(verts) do
		if istable(v) then
			local n = #vertices
			if n > max then
				break
			elseif #v == 2 then
				vertices[n + 1] = { x = v[1], y = v[2] }
			elseif #v == 4 then
				vertices[n + 1]  = { x= v[1], y = v[2], u = v[3], v = v[4] }
			end
		end
	end

	if this:Set("vertices", vertices) then
		local egp = this.EGP
		EGP:InsertQueue(egp, self.player, EGP._SetVertex, "SetVertex", this.index, vertices, true) -- wtf?
		Update(self, egp)
	end
end

e2function void egpobject:egpSetVertices(...args)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	if not this.vertices then return end
	if #args < 3 then return end
	local max = maxVertices:GetInt()

	local vertices = {}
	for k, v in ipairs(args) do
		if istable(v) then
			local n = #vertices
			if n > max then
				break
			elseif typeids[k] == "xv2" then
				vertices[n + 1]  = { x= v[1], y = v[2] }
			elseif typeids[k] == "xv4" then
				vertices[n + 1]  = { x= v[1], y = v[2], u = v[3], v = v[4] }
			end
		end
	end

	if this:Set("vertices", vertices) then
		local egp = this.EGP
		EGP:InsertQueue(egp, self.player, EGP._SetVertex, "SetVertex", this.index, vertices, true)
		Update(self, egp)
	end
end



----------------------------
-- Color
----------------------------
e2function void egpobject:egpColor(vector4 color)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3], a = color[4] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpColor(vector color)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpColor(r, g, b, a)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = r, g = g, b = b, a = a }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpAlpha(number a)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("a", a) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Material
----------------------------
e2function void egpobject:egpMaterial(string material)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	material = WireLib.IsValidMaterial(material)
	if this:Set("material", material) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpMaterialFromScreen(entity gpu)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if gpu and gpu:IsValid() then
		if this:Set("material", gpu) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
	end
end

----------------------------
-- Fidelity (number of corners for circles and wedges)
----------------------------
e2function void egpobject:egpFidelity(number fidelity)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ fidelity = math.Clamp(fidelity, 3, 180) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

[nodiscard]
e2function number egpobject:egpFidelity()
	return this.fidelity or -1
end

----------------------------
-- Parenting
----------------------------
e2function void egpobject:egpParent(egpobject parent)
	if not isValid(this) or not isValid(parent) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if egp ~= parent.EGP then return self:throw("Invalid EGP Object", nil) end
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parent) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpParent(number parentindex)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parentindex) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void wirelink:egpParent(egpobject child, egpobject parent)
	if not (isValid(child) or  isValid(parent) or child.EGP == this or parent.EGP == this) then return self:throw("Invalid EGP Object", nil) end
	if not EGP:IsAllowed(self, this) then return end
	if EGP:SetParent(this, child, parent) then EGP:DoAction(this, self, "SendObject", child) Update(self, this) end
end

-- Entity parenting (only for 3Dtracker - does nothing for any other object)
e2function void egpobject:egpParent(entity parent)
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not parent or not parent:IsValid() then return end
	if not EGP:IsAllowed(self, egp) then return end

	if this.NeedsConstantUpdate and this.parententity ~= parent then
		this.parententity = parent

		EGP:DoAction(egp, self, "SendObject", this)
		Update(self, egp)
	end
end

-- Returns the entity a tracker is parented to
[nodiscard]
e2function entity egpobject:egpTrackerParent()
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	return IsValid(this.parententity) and this.parententity or NULL
end

e2function void egpobject:egpParentToCursor()
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, -1) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpUnParent()
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:UnParent(egp, this) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

[nodiscard]
e2function number egpobject:egpParentIndex()
	if not isValid(this) then return self:throw("Invalid EGP Object", nil) end
	return this.parent or nil
end

--------------------------------------------------------
-- Remove
--------------------------------------------------------
e2function void wirelink:egpRemove(egpobject obj)
	if not EGP:IsAllowed(self, this) then return end
	if isValid(obj) then
		EGP:DoAction(this, self, "RemoveObject", obj.index)
		table.Empty(obj)
		setmetatable(obj, M_NULL_EGPOBJECT)
		Update(self, this)
	end
end

e2function void egpobject:egpRemove()
	if not isValid(this) then return end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	
	EGP:DoAction(egp, self, "RemoveObject", this.index)
	table.Empty(this)
	setmetatable(this, M_NULL_EGPOBJECT) -- In an ideal scenario we would probably want this = NULL_EGPOBJECT instead
	Update(self, egp)
end

e2function void egpobject:draw()
	if not this._nodraw then return end
	local egp = this.EGP
	this._nodraw = nil
	if not EGP:IsAllowed(self, egp) then return end

	if EGP:CreateObject(egp, this.ID, this) then
		EGP:DoAction(egp, self, "SendObject", this)
		Update(self, egp)
	end
end

e2function void egpobject:hide()
	if not isValid(this) or this._nodraw then return end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end

	EGP:DoAction(egp, self, "RemoveObject", this.index)
	this._nodraw = true
	Update(self, egp)
end

[nodiscard]
e2function number egpobject:isVisible()
	return isValid(this) and not this._nodraw and 1 or 0
end

--------------------------------------------------------
-- Get functions
--------------------------------------------------------
__e2setcost(20)

[nodiscard]
e2function vector egpobject:egpGlobalPos()
	if not isValid(this) then return self:throw("Invalid EGP Object", vector_origin) end
	local _, posang = EGP:GetGlobalPos(this.EGP, this)
	return Vector(posang.x, posang.y, posang.angle)
end

[nodiscard]
e2function array egpobject:egpGlobalVertices()
	if not isValid(this) then return self:throw("Invalid EGP Object", {}) end
	local hasvertices, data = EGP:GetGlobalPos(this.EGP, this)
	if hasvertices then
		if data.vertices then
			local ret = {}
			for i = 1, #data.vertices do
				local v = data.vertices[i]
				ret[i] = {v.x, v.y}
				self.prf = self.prf + 0.1
			end
			return ret
		elseif data.x and data.y and data.x2 and data.y2 and data.x3 and data.y3 then
			return { { data.x, data.y }, { data.x2, data.y2 }, { data.x3, data.y3 } }
		elseif data.x and data.y and data.x2 and data.y2 then
			return { {data.x, data.y}, {data.x2, data.y2} }
		end
	else
		return {}
	end
end

[nodiscard]
e2function number wirelink:egpHasObject(egpobject object)
	return this == object.EGP and 1 or 0
end


__e2setcost(3)

[nodiscard]
e2function vector2 egpobject:egpPos()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.x and this.y and { this.x, this.y }) or { -1, -1 }
end


[nodiscard]
e2function vector egpobject:egpPosAng()
	if not isValid(this) then return self:throw("Invalid EGP Object", Vector(-1, -1, -1)) end
	return (this.x and this.y and this.angle and Vector(this.x, this.y, this.angle)) or Vector(-1, -1, -1)
end

[nodiscard]
e2function vector2 egpobject:egpSize()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.w and this.h and { this.w, this.h }) or { -1, -1 }
end

[nodiscard]
e2function number egpobject:egpSizeNum()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.size or -1
end

[nodiscard]
e2function vector4 egpobject:egpColor4()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1, -1, -1 }) end
	return (this.r and this.g and this.b and this.a and { this.r, this.g, this.b, this.a }) or { -1, -1, -1, -1 }
end

[nodiscard]
e2function vector egpobject:egpColor()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return (this.r and this.g and this.b and Vector(this.r, this.g, this.b)) or Vector(-1, -1, -1)
end

[nodiscard]
e2function number egpobject:egpAlpha()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.a or -1
end

[nodiscard]
e2function number egpobject:egpAngle()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.angle or -1
end

[nodiscard]
e2function string egpobject:egpMaterial()
	if not isValid(this) then return self:throw("Invalid EGP Object", "") end
	return this.material or ""
end

[nodiscard]
e2function number egpobject:egpRadius()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.radius or -1
end

__e2setcost(10)

[nodiscard]
e2function array egpobject:egpVertices()
	if this.vertices then
		local ret = {}
		for k, v in ipairs(this.vertices) do
			ret[k] = { v.x, v.y }
		end
		return ret
	elseif v.x and v.y and v.x2 and v.y2 and v.x3 and v.y3 then
		return { {v.x, v.y}, {v.x2, v.y2 }, { v.x3, v.y3 } }
	elseif v.x and v.y and v.x2 and v.y2 then
		return { {v.x, v.y}, { v.x2, v.y2 } }
	else
		return {}
	end
end

--------------------------------------------------------
-- Object Type
--------------------------------------------------------
__e2setcost(4)

[nodiscard]
e2function string egpobject:egpObjectType()
	return this.Name or "Unknown"
end

--------------------------------------------------------
-- Additional Functions
--------------------------------------------------------

__e2setcost(15)

[nodiscard]
e2function egpobject wirelink:egpCopy(number index, egpobject from)
	if not EGP:IsAllowed(self, this) then return end
	if not isValid(from) then return self:throw("Invalid EGPObject", NULL_EGPOBJECT) end
	if from then
		local copy = table.Copy(from)
		copy.index = index
		local bool, obj = EGP:CreateObject(this, from.ID, copy, self.player)
		if bool then EGP:DoAction(this, self, "SendObject", obj) Update(self, this) return obj end
	end
end

e2function void egpobject:egpCopy(egpobject from)
	if not EGP:IsAllowed(self, this) then return end
	if not isValid(from) then return self:throw("Invalid EGPObject") end
	if from then
		local copy = table.Copy(from)
		copy.index = this.index
		copy.EGP = this.EGP
		local bool, obj = EGP:CreateObject(copy.EGP, from.ID, copy, self.player)
		if bool then EGP:DoAction(this, self, "SendObject", obj) Update(self, this) return end
	end
end

__e2setcost(10)

[nodiscard]
e2function number egpobject:containsPoint(vector2 point)
	return isValid(this) and this:Contains(point[1], point[2]) and 1 or 0
end

__e2setcost(5)

[nodiscard]
e2function egpobject wirelink:egpobject(number index)
	if not EGP:IsAllowed(self, this) then return end
	local _, _, obj = EGP:HasObject(this, index)
	return obj or NULL_EGPOBJECT
end

__e2setcost(2)

[nodiscard]
e2function string egpobject:egpObjectType()
	return isValid(this) and EGP.Objects.Names_Inverted[this.ID] or "Unknown"
end

__e2setcost(1)

[nodiscard]
e2function egpobject noegpobject()
	return NULL_EGPOBJECT
end

[nodiscard]
e2function string toString(egpobject egpo)
	return tostring(egpo)
end	

[nodiscard]
e2function string egpobject:toString() = e2function string toString(egpobject egpo)

--------------------------------------------------------
-- Array Index Operators
--------------------------------------------------------

registerCallback("postinit", function()
	E2Lib.currentextension = "egpobjects"
	local fixDefault = E2Lib.fixDefault
	for _, v in pairs(wire_expression_types) do
		local id = v[1]
		local default = v[2]
		local typecheck = v[6]

		__e2setcost(5)

		-- Getter
		registerOperator("idx", id .. "=xeos", id, function(self, args)
			local op1, op2 = args[2], args[3]
			local this, index = op1[1](self, op1), op2[1](self, op2)
			local indexType = EGP_ALLOWED_ARGS[index]

			if not indexType then return fixDefault(default) end

			local obj = this[index]

			if not obj or id ~= indexType then return fixDefault(default) end
			if typecheck and typecheck(obj) then return fixDefault(default) end -- Type check

			return obj
		end)

		-- Setter
		registerOperator("idx", id .. "=xeos" .. id, id, function(self, args)
			local op1, op2, op3, scope = args[2], args[3], args[4], args[5]
			local this, index, value = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

			if not EGP_ALLOWED_ARGS[index] then return fixDefault(default) end

			if not isValid(this) then return self:throw("Tried to acces invalid EGP Object", nil) end
			local egp = this.EGP
			if not EGP:IsAllowed(self, egp) then return fixDefault(default) end
			if this:Set(index, value) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) self.GlobalScope.vclk[this] = true end
			return value
		end)

		-- Implicitly typed setter
		registerOperator("idx", "xeos" .. id, id, function(self, args)
			local op1, op2, op3, scope = args[2], args[3], args[4], args[5]
			local this, index, value = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			local indexType = EGP_ALLOWED_ARGS[index]

			if not indexType then return end
			if indexType ~= id then self:throw(string.format("EGP Object expected '%s' type but got '%s'!", indexType, id)) end
			
			if not isValid(this) then return self:throw("Tried to acces invalid EGP Object") end
			local egp = this.EGP
			if not EGP:IsAllowed(self, egp) then return end
			if this:Set(index, value) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) self.GlobalScope.vclk[this] = true end
			return
		end)
	end

	local egpCreate = EGP.CreateObject
	for name, id in pairs(EGP.Objects.Names) do
		-- Indexed table "constructor"
		registerFunction("egp" .. name, "xwl:nt", "xeo", function(self, args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local this, index, args = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if not EGP:IsAllowed(self, this) then return NULL_EGPOBJECT end

			local converted = {}

			for k, v in pairs(args.s) do
				if EGP_ALLOWED_ARGS[k] == args.stypes[k] or false then converted[k] = v end
			end

			converted.index = index

			local bool, obj = egpCreate(EGP, this, id, converted)
			if bool then
				EGP:DoAction(this, self, "SendObject", obj)
				Update(self, this)
			end
			return obj
		end, 10, { "index", "args" })

		--[[
		-- Unindexed table constructor
		registerFunction("egp" .. name, "xwl:t", "xeo", function(self, args)
			local op1, op2 = args[2], args[3]
			local this, args = op1[1](self, op1), op2[1](self, op2)

			local converted = {}

			for k, v in pairs(args.s) do
				if EGP_ALLOWED_ARGS[k] == args.stypes[k] or false then converted[k] = v end
			end

			converted.index = EGP.GetNextIndex(this)

			local bool, obj = egpCreate(this, id, converted)
			if bool then
				EGP:DoAction(this, self, "SendObject", obj)
				Update(self, this)
				return obj
			end
		end, 10, { "this", "args" }, { "nodiscard" })
		]]
	end
end)
