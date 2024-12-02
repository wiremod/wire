--
--	File for EGP Object handling in E2.
--

local EGP = E2Lib.EGP

local NULL_EGPOBJECT = EGP.Objects.NULL_EGPOBJECT
local isValid = EGP.EGPObject.IsValid
local hasObject = EGP.HasObject
local egp_create = EGP.Create
local isAllowed = EGP.IsAllowed
local isEGPObject = EGP.IsEGPObject

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

---- Type defintion

registerType("egpobject", "xeo", NULL_EGPOBJECT,
	nil,
	nil,
	nil,
	function(v)
		return not isEGPObject(v)
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
	return isValid(egpo) and 1 or 0
end

e2function number operator==(egpobject lhs, egpobject rhs)
	return (lhs == rhs) and 1 or 0
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

	if this:EditObject(converted) then EGP:DoAction(egp, self, "Update", this) Update(self, egp) end
	return this
end

--------------------------------------------------------
-- Order
--------------------------------------------------------

__e2setcost(15)

e2function void egpobject:setOrder(order)
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	local bool, k = hasObject(egp, this.index)
	if (bool) then
		if EGP:SetOrder(egp, k, order) then
			EGP:DoAction(egp, self, "SendObject", this)
			Update(self, egp)
		end
	end
end

e2function number egpobject:getOrder()
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return -1 end
	local bool, k = hasObject(egp, this.index)
	return bool and k or -1
end

e2function void egpobject:setOrderAbove(egpobject abovethis)
	local egp = this.EGP
	if not isAllowed(nil, self, egp) then return end
	if not (isValid(this) or isValid(abovethis)) then self:throw("Invalid EGP Object") end
	local bool, k = hasObject(egp, this.index)
	if bool then
		if hasObject(egp, abovethis.index) then
			if EGP.SetOrder(egp, k, abovethis.index, 1) then
				EGP:DoAction(egp, self, "SendObject", this)
				Update(self, egp)
			end
		end
	end
end

e2function void egpobject:setOrderBelow(egpobject belowthis)
	local egp = this.EGP
	if not isAllowed(self, egp) then return end
	if not (isValid(this) or isValid(belowthis)) then self:throw("Invalid EGP Object") end
	local bool, k = hasObject(egp, this.index)
	if bool then
		if hasObject(egp, belowthis.index) then
			if EGP.SetOrder(egp, k, belowthis.index, -1) then
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

e2function void egpobject:setText(string text)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("text", text) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setText(string text, string font, number size)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ text = text, font = font, size = size }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Alignment
----------------------------
e2function void egpobject:setAlign(number halign)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("halign", math.Clamp(halign, 0, 2)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setAlign(number halign, number valign)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ valign = math.Clamp(valign, 0, 2), halign = math.Clamp(halign, 0, 2) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Filtering
----------------------------
e2function void egpobject:setFiltering(number filtering)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("filtering", math.Clamp(filtering, 0, 3)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Font
----------------------------
e2function void egpobject:setFont(string font)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if #font > 30 then return self:throw("Font string is too long!") end
	if this:Set("font", font) then EGP:DoAction(egp, self, "SendObject", obj) Update(self, this) end
end

e2function void egpobject:setFont(string font, number size)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if #font > 30 then return self:throw("Font string is too long!") end
	if this:EditObject({ font = font, size = size }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

--------------------------------------------------------
-- 3DTracker
--------------------------------------------------------
__e2setcost(10)

e2function void egpobject:setPos(vector pos)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ target_x = pos[1], target_y = pos[2], target_z = pos[3] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

--------------------------------------------------------
-- Set functions
--------------------------------------------------------

__e2setcost(7)

----------------------------
-- Size
----------------------------
e2function void egpobject:setSize(vector2 size)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ w = size[1], h = size[2] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setSize(width, height)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ w = width, h = height }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setSize(number size)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("size", size) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Position
----------------------------
e2function void egpobject:setPos(vector2 pos)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(pos[1], pos[2]) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setPos(x, y)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setPos(x, y, x2, y2)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y, nil, x2, y2) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Angle
----------------------------
e2function void egpobject:setAngle(number angle)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("angle", angle) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

-------------
-- Position & Angle
-------------
e2function void egpobject:setPos(x, y, angle)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(x, y, angle) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:rotateAroundAxis(vector2 worldpos, vector2 axispos, number angle)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this.x and this.y then
		local vec, ang = LocalToWorld(Vector(axispos[1], axispos[2], 0), angle_origin, Vector(worldpos[1], worldpos[2], 0), Angle(0, -angle, 0))

		local x = vec.x
		local y = vec.y

		angle = -ang.yaw

		if this:SetPos(x, y, angle) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
	end
end

----------------------------
-- Polys
----------------------------

local maxVertices = EGP.ConVars.MaxVertices

e2function void egpobject:setVertices(array verts)
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

e2function void egpobject:setVertices(...args)
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
e2function void egpobject:setColor(vector4 color)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3], a = color[4] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setColor(vector color)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setColor(r, g, b, a)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = r, g = g, b = b, a = a }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setAlpha(number a)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("a", a) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Material
----------------------------
e2function void egpobject:setMaterial(string material)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	material = WireLib.IsValidMaterial(material)
	if this:Set("material", material) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:setMaterialFromScreen(entity gpu)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if gpu and gpu:IsValid() then
		if this:Set("material", gpu) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
	end
end

----------------------------
-- Fidelity (number of corners for circles and wedges)
----------------------------
e2function void egpobject:setFidelity(number fidelity)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ fidelity = math.Clamp(fidelity, 3, 180) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

[nodiscard]
e2function number egpobject:getFidelity()
	return this.fidelity or -1
end

----------------------------
-- Parenting
----------------------------
e2function void egpobject:parentTo(egpobject parent)
	if not isValid(this) or not isValid(parent) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if egp ~= parent.EGP then return self:throw("Invalid EGP Object", nil) end
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parent) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:parentTo(number parentindex)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parentindex) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void wirelink:egpParent(egpobject child, egpobject parent)
	if not EGP:IsAllowed(self, this) then return end
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!") end
	if not (isValid(child) or  isValid(parent) or child.EGP == this or parent.EGP == this) then return self:throw("Invalid EGP Object", nil) end
	if EGP:SetParent(this, child, parent) then EGP:DoAction(this, self, "SendObject", child) Update(self, this) end
end

-- Entity parenting (only for 3Dtracker - does nothing for any other object)
e2function void egpobject:trackerParent(entity parent)
	if not isValid(this) then return self:throw("Invalid EGP Object") end
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
e2function entity egpobject:trackerParent()
	if not isValid(this) then return self:throw("Invalid EGP Object", NULL) end
	return IsValid(this.parententity) and this.parententity or NULL
end

e2function void egpobject:parentToCursor()
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, -1) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:unparent()
	if not isValid(this) then return self:throw("Invalid EGP Object") end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:UnParent(egp, this) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

[nodiscard]
e2function number egpobject:parentIndex()
	if not isValid(this) then return self:throw("Invalid EGP Object", 0) end
	return this.parent or 0
end

[nodiscard]
e2function egpobject egpobject:parent()
	if not isValid(this) then return self:throw("Invalid EGP Object", NULL_EGPOBJECT) end
	local _, _, v = hasObject(this.EGP, this.parent)
	return v or NULL_EGPOBJECT
end

--------------------------------------------------------
-- Remove
--------------------------------------------------------
e2function void wirelink:egpRemove(egpobject obj)
	if not EGP:IsAllowed(self, this) then return end
	if not EGP:ValidEGP(this) then return end
	if isValid(obj) then
		EGP:DoAction(this, self, "RemoveObject", obj.index)
		table.Empty(obj)
		Update(self, this)
	end
end

e2function void egpobject:remove()
	if not isValid(this) then return end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end

	EGP:DoAction(egp, self, "RemoveObject", this.index)
	table.Empty(this) -- In an ideal scenario we would probably want this = NULL_EGPOBJECT instead
	Update(self, egp)
end

e2function void egpobject:draw()
	if not this._nodraw then return end
	local egp = this.EGP
	this._nodraw = nil
	if not EGP:IsAllowed(self, egp) then return end

	local args = {}
	for k, v in pairs(this) do
		args[k] = v
	end

	if egp_create(this.ID, args, egp) then
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
e2function vector egpobject:globalPos()
	if not isValid(this) then return self:throw("Invalid EGP Object", Vector(0, 0, 0)) end
	local _, posang = EGP:GetGlobalPos(this.EGP, this)
	return Vector(posang.x, posang.y, posang.angle)
end

[nodiscard]
e2function array egpobject:globalVertices()
	if not isValid(this) then return self:throw("Invalid EGP Object", {}) end
	if this.verticesindex then
		local data = EGP:GetGlobalVertices(this.EGP, this)
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
	end
	return {}
end

[nodiscard]
e2function number wirelink:egpHasObject(egpobject object)
	return this == object.EGP and 1 or 0
end


__e2setcost(3)

[nodiscard]
e2function vector2 egpobject:getPos()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.x and this.y and { this.x, this.y }) or { -1, -1 }
end


[nodiscard]
e2function vector egpobject:getPosAng()
	if not isValid(this) then return self:throw("Invalid EGP Object", Vector(-1, -1, -1)) end
	return (this.x and this.y and this.angle and Vector(this.x, this.y, this.angle)) or Vector(-1, -1, -1)
end

[nodiscard]
e2function vector2 egpobject:getSize()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.w and this.h and { this.w, this.h }) or { -1, -1 }
end

[nodiscard]
e2function number egpobject:getSizeNum()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.size or -1
end

[nodiscard]
e2function vector4 egpobject:getColor4()
	if not isValid(this) then return self:throw("Invalid EGP Object", { -1, -1, -1, -1 }) end
	return (this.r and this.g and this.b and this.a and { this.r, this.g, this.b, this.a }) or { -1, -1, -1, -1 }
end

[nodiscard]
e2function vector egpobject:getColor()
	if not isValid(this) then return self:throw("Invalid EGP Object", Vector(-1, -1, -1)) end
	return (this.r and this.g and this.b and Vector(this.r, this.g, this.b)) or Vector(-1, -1, -1)
end

[nodiscard]
e2function number egpobject:getAlpha()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.a or -1
end

[nodiscard]
e2function number egpobject:getAngle()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.angle or -1
end

[nodiscard]
e2function string egpobject:getMaterial()
	if not isValid(this) then return self:throw("Invalid EGP Object", "") end
	return tostring(this.material) or ""
end

[nodiscard]
e2function number egpobject:getRadius()
	if not isValid(this) then return self:throw("Invalid EGP Object", -1) end
	return this.radius or -1
end

__e2setcost(10)

[nodiscard]
e2function array egpobject:getVertices()
	if this.vertices then
		local ret = {}
		for k, v in ipairs(this.vertices) do
			ret[k] = { v.x, v.y }
		end
		return ret
	elseif this.x and this.y and this.x2 and this.y2 and this.x3 and this.y3 then
		return { {this.x, this.y}, {this.x2, this.y2 }, { this.x3, this.y3 } }
	elseif this.x and this.y and this.x2 and this.y2 then
		return { {this.x, this.y}, { this.x2, this.y2 } }
	else
		return {}
	end
end

--------------------------------------------------------
-- Object Type
--------------------------------------------------------
__e2setcost(4)

[nodiscard]
e2function string egpobject:getObjectType()
	return this.Name or "Unknown"
end

--------------------------------------------------------
-- Additional Functions
--------------------------------------------------------

__e2setcost(15)

[nodiscard]
e2function egpobject wirelink:egpCopy(number index, egpobject from)
	if not EGP:IsAllowed(self, this) then return NULL_EGPOBJECT end
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if not isValid(from) then return self:throw("Invalid EGPObject", NULL_EGPOBJECT) end
	if from then
		local copy = table.Copy(from)
		copy.index = index
		local bool, obj = egp_create(from.ID, copy, this)
		if bool then EGP:DoAction(this, self, "SendObject", obj) Update(self, this) return obj end
	end
end

e2function void egpobject:copyFrom(egpobject from)
	if not EGP:IsAllowed(self, this) then return end
	if not isValid(from) then return self:throw("Invalid EGPObject") end
	if from then
		local copy = table.Copy(from)
		copy.index = this.index
		copy.EGP = this.EGP
		local bool, obj = egp_create(from.ID, copy, copy.EGP)
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
	if not isAllowed(nil, self, this) then return NULL_EGPOBJECT end
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	local _, _, obj = hasObject(this, index)
	return obj or NULL_EGPOBJECT
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
		registerOperator("indexget", "xeos" .. id, id, function(self, this, index)
			local indexType = EGP_ALLOWED_ARGS[index]

			if not indexType then return fixDefault(default) end

			local obj = this[index]

			if not obj or id ~= indexType then return fixDefault(default) end
			if typecheck and typecheck(obj) then return fixDefault(default) end -- Type check

			return obj
		end)

		-- Setter
		registerOperator("indexset", "xeos" .. id, id, function(self, this, index, value)
			if not EGP_ALLOWED_ARGS[index] then return fixDefault(default) end

			if not isValid(this) then return self:throw("Tried to acces invalid EGP Object", nil) end
			local egp = this.EGP
			if not EGP:IsAllowed(self, egp) then return fixDefault(default) end
			if this:Set(index, value) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) self.GlobalScope.vclk[this] = true end
			return value
		end)

		-- Implicitly typed setter
		registerOperator("indexset", "xeos", id, function(self, this, index, value)
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

	for _, v in ipairs(EGP.Objects) do
		local name = v.Name
		-- Indexed table "constructor"
		registerFunction("egp" .. name, "xwl:nt", "xeo", function(self, args)
			local this, index, args = args[1], args[2], args[3]
			if not EGP:IsAllowed(self, this) then return NULL_EGPOBJECT end

			local converted = {}

			for k, v in pairs(args.s) do
				if EGP_ALLOWED_ARGS[k] == args.stypes[k] or false then converted[k] = v end
			end

			converted.index = index

			local bool, obj = egp_create(name, converted, this)
			if bool then
				EGP:DoAction(this, self, "SendObject", obj)
				Update(self, this)
			end
			return obj
		end, 10, { "index", "args" }, { legacy = false })

		--[[
		-- Unindexed table constructor
		registerFunction("egp" .. name, "xwl:t", "xeo", function(self, args)
			local this, index, args = args[1], args[2], args[3]

			local converted = {}

			for k, v in pairs(args.s) do
				if EGP_ALLOWED_ARGS[k] == args.stypes[k] or false then converted[k] = v end
			end

			converted.index = EGP.GetNextIndex(this)

			local bool, obj = egp_create(name, converted, this)
			if bool then
				EGP:DoAction(this, self, "SendObject", obj)
				Update(self, this)
				return obj
			end
		end, 10, { "this", "args" }, { nodiscard = true, legacy = false })
		]]
	end
end)
