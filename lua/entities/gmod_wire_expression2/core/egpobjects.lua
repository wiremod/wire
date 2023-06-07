--
--	File for EGP Object handling in E2.
--

local function Update(self, this)
	self.data.EGP.UpdatesNeeded[this] = true
end

local getCenter = EGP.ParentingFuncs.getCenter
local getCenterFromPos = EGP.ParentingFuncs.getCenterFromPos
local makeArray = EGP.ParentingFuncs.makeArray

---- Type defintion

registerType("egpobject", "xeo", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if not istable(retval) then error("Return value is neither nil nor a table, but a " .. type(retval) .. "!", 0) end
	end,
	function(v)
		return not istable(v)
	end
)

__e2setcost(2)

registerOperator("ass", "xeo", "xeo", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)
	if rhs == nil then return nil end
	
	local Scope = self.Scopes[scope]
	local lookup = Scope.lookup
	if not lookup then lookup = {} Scope.lookup = lookup end
	if lookup[rhs] then lookup[rhs][lhs] = true else lookup[rhs] = {[lhs] = true} end

	Scope[lhs] = rhs
	Scope.vclk[lhs] = true
	return rhs
end)

e2function number operator_is(egpobject egpo)
	return (egpo ~= nil and isfunction(egpo.DataStreamInfo)) and 1 or 0
end

e2function number operator==(egpobject lhs, egpobject rhs)
	return (lhs == rhs) and 1 or 0
end

e2function number operator!=(egpobject lhs, egpobject rhs)
	return (lhs ~= rhs) and 1 or 0
end

---- Functions

__e2setcost(7)

----------------------------
-- Set Text
----------------------------
e2function void egpobject:egpSetText(string text)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("text", text) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpSetText(string text, string font, number size)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ text = text, font = font, size = size }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Alignment
----------------------------
e2function void egpobject:egpAlign(number halign)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("halign", math.Clamp(halign, 0, 2)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpAlign(number halign, number valign)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ valign = math.Clamp(valign, 0, 2), halign = math.Clamp(halign, 0, 2) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Filtering
----------------------------
e2function void egpobject:egpFiltering(number filtering)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("filtering", math.Clamp(filtering, 0, 3)) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Font
----------------------------
e2function void egpobject:egpFont(string font)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if #font > 30 then return self:throw("Font string is too long!", nil) end
	if this:Set("font", font) then EGP:DoAction(egp, self, "SendObject", obj) Update(self, this) end
end

e2function void egpobject:egpFont(string font, number size)
	if not this then return self:throw("Invalid EGP Object", nil) end
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
	if not this then return self:throw("Invalid EGP Object", nil) end
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
e2function void egpobject:egpSize(vector2 size)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ w = size[1], h = size[2] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpSize(number size)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("size", size) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Position
----------------------------
e2function void egpobject:egpPos(vector2 pos)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:SetPos(pos[1], pos[2]) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Angle
----------------------------
e2function void egpobject:egpAngle(number angle)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ angle = angle, _angle = angle }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

-------------
-- Position & Angle
-------------
e2function void egpobject:egpAngle(vector2 worldpos, vector2 axispos, number angle)
	if not this then return self:throw("Invalid EGP Object", nil) end
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
-- Color
----------------------------
e2function void egpobject:egpColor(vector4 color)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3], a = color[4] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpColor(vector color)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = color[1], g = color[2], b = color[3] }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpColor(r, g, b, a)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ r = r, g = g, b = b, a = a }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpAlpha(number a)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:Set("a", a) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

----------------------------
-- Material
----------------------------
e2function void egpobject:egpMaterial(string material)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	material = WireLib.IsValidMaterial(material)
	if this:Set("material", material) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpMaterialFromScreen(entity gpu)
	if not this then return self:throw("Invalid EGP Object", nil) end
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
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if this:EditObject({ fidelity = math.Clamp(fidelity, 3, 180) }) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function number egpobject:egpFidelity()
	return this.fidelity or -1
end

----------------------------
-- Parenting
----------------------------
e2function void egpobject:egpParent(egpobject parent)
	if not this or not parent then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if egp ~= parent.EGP then return self:throw("Invalid EGP Object", nil) end
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parent) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpParent(number parentindex)
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, parentindex) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void wirelink:egpParent(egpobject child, egpobject parent)
	if not child or not parent then return self:throw("Invalid EGP Object", nil) end	
	if not EGP:IsAllowed(self, this) then return end
	if EGP:SetParent(this, child, parent) then EGP:DoAction(this, self, "SendObject", child) Update(self, this) end
end

-- Entity parenting (only for 3Dtracker - does nothing for any other object)
e2function void egpobject:egpParent(entity parent)
	if not this then return self:throw("Invalid EGP Object", nil) end
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
e2function entity egpobject:egpTrackerParent()
	if not this then return self:throw("Invalid EGP Object", nil) end
	return IsValid(this.parententity) and this.parententity or NULL
end

e2function void egpobject:egpParentToCursor()
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:SetParent(egp, this, -1) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function void egpobject:egpUnParent()
	if not this then return self:throw("Invalid EGP Object", nil) end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	if EGP:UnParent(egp, this) then EGP:DoAction(egp, self, "SendObject", this) Update(self, egp) end
end

e2function number egpobject:egpParentIndex()
	if not this then return self:throw("Invalid EGP Object", nil) end
	return this.parent or nil
end

--------------------------------------------------------
-- Remove
--------------------------------------------------------
e2function void wirelink:egpRemove(egpobject obj)
	if not EGP:IsAllowed(self, this) then return end
	if obj then
		EGP:DoAction(this, self, "RemoveObject", obj.index)
		Update(self, this)
	end
end

e2function void egpobject:egpRemove()
	if not this then return end
	local egp = this.EGP
	if not EGP:IsAllowed(self, egp) then return end
	
	EGP:DoAction(egp, self, "RemoveObject", this.index)
	Update(self, egp)
end

--------------------------------------------------------
-- Get functions
--------------------------------------------------------
__e2setcost(20)

e2function vector egpobject:egpGlobalPos()
	if not this then return self:throw("Invalid EGP Object", vector_origin) end
	local hasvertices, posang = EGP:GetGlobalPos(this.EGP, this)
	if hasvertices then
		local x, y = getCenterFromPos(posang)
		return Vector(x, y, 0)
	end
	return Vector(posang.x, posang.y, posang.angle)
end

e2function array egpobject:egpGlobalVertices()
	if not this then return self:throw("Invalid EGP Object", {}) end
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


__e2setcost(3)

e2function vector2 egpobject:egpPos()
	if not this then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.x and this.y and { this.x, this.y }) or { -1, -1 }
end

e2function vector2 egpobject:egpSize()
	if not this then return self:throw("Invalid EGP Object", { -1, -1 }) end
	return (this.w and this.h and { this.w, this.h }) or { -1, -1 }
end

e2function number egpobject:egpSizeNum()
	if not this then return self:throw("Invalid EGP Object", -1) end
	return this.size or -1
end

e2function vector4 egpobject:egpColor4()
	if not this then return self:throw("Invalid EGP Object", { -1, -1, -1, -1 }) end
	return (this.r and this.g and this.b and this.a and { this.r, this.g, this.b, this.a }) or { -1, -1, -1, -1 }
end

e2function vector egpobject:egpColor()
	if not this then return self:throw("Invalid EGP Object", -1) end
	return (this.r and this.g and this.b and Vector(this.r, this.g, this.b)) or Vector(-1, -1, -1)
end

e2function number egpobject:egpAlpha()
	if not this then return self:throw("Invalid EGP Object", -1) end
	return this.a or -1
end

e2function number egpobject:egpAngle()
	if not this then return self:throw("Invalid EGP Object", -1) end
	return this.angle or -1
end

e2function string egpobject:egpMaterial()
	if not this then return self:throw("Invalid EGP Object", "") end
	return this.material or ""
end

e2function number egpobject:egpRadius()
	if not this then return self:throw("Invalid EGP Object", -1) end
	return this.radius or -1
end

__e2setcost(10)

e2function array egpobject:egpVertices()
	if (this.vertices) then
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

e2function string egpobject:egpObjectType()
	return EGP.Objects.Names_Inverted[this.ID] or ""
end

--------------------------------------------------------
-- Additional Functions
--------------------------------------------------------

__e2setcost(15)

e2function egpobject wirelink:egpCopy(number index, egpobject from)
	if not EGP:IsAllowed(self, this) then return end
	if from then
		local copy = table.Copy(from)
		copy.index = index
		local bool, obj = EGP:CreateObject(this, from.ID, copy, self.player)
		if bool then EGP:DoAction(this, self, "SendObject", obj) Update(self, this) return obj end
	end
end

__e2setcost(10)

e2function number egpobject:egpObjectContainsPoint(vector2 point)
	return this and this:Contains(point[1], point[2]) and 1 or 0
end

__e2setcost(5)

e2function egpobject wirelink:egpobject(number index)
	if not EGP:IsAllowed(self, this) then return end
	local _, _, obj = EGP:HasObject(this, index)
	return obj
end

__e2setcost(2)

e2function string egpobject:egpObjectType()
	return this and EGP.Objects.Names_Inverted[this.ID] or ""
end

__e2setcost(1)

e2function egpobject noegpobject()
	return nil
end