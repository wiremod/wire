--------------------------------------------------------
-- Parenting functions
--------------------------------------------------------
local EGP = EGP
EGP.ParentingFuncs = {}

local function addUV(obj, t) -- Polygon u v fix
	if obj.verticesindex then
		local t2 = obj[obj.verticesindex]
		for k, v in ipairs(t) do
			t[k].u = t2[k].u
			t[k].v = t2[k].v
		end
	end
end
EGP.ParentingFuncs.addUV = addUV

local function makeArray(obj, fakepos)
	local ret = {}
	if isstring(obj.verticesindex) then
		if not fakepos then
			if not obj["_" .. obj.verticesindex] then EGP:AddParentIndexes(obj) end
			for _, v in ipairs(obj["_" .. obj.verticesindex]) do
				ret[#ret+1] = v.x
				ret[#ret+1] = v.y
			end
		else
			for _, v in ipairs(obj[obj.verticesindex]) do
				ret[#ret+1] = v.x
				ret[#ret+1] = v.y
			end
		end
	else
		if not fakepos then
			for _, v in ipairs(obj.verticesindex) do
				ret[#ret+1] = obj["_" .. v[1]]
				ret[#ret+1] = obj["_" .. v[2]]
			end
		else
			for _, v in ipairs(obj.verticesindex) do
				ret[#ret+1] = obj[v[1]]
				ret[#ret+1] = obj[v[2]]
			end
		end
	end
	return ret
end
EGP.ParentingFuncs.makeArray = makeArray

local function makeTable(obj, data)
	local ret = {}
	if isstring(obj.verticesindex) then
		for i = 1, #data, 2 do
			ret[#ret+1] = { x = data[i], y = data[i+1] }
		end
	else
		local n = 1
		for _, v in ipairs(obj.verticesindex) do
			ret[v[1]] = data[n]
			ret[v[2]] = data[n + 1]
			n = n + 2
		end
	end
	return ret
end
EGP.ParentingFuncs.makeTable = makeTable

local function getCenter(data)
	local centerx, centery = 0, 0
	for i = 1, #data, 2 do
		centerx = centerx + data[i]
		centery = centery + data[i + 1]
	end
	return centerx / (n / 2), centery / (n / 2)
end
EGP.ParentingFuncs.getCenter = getCenter

-- (returns true if obj has vertices, false if not, followed by the new position data)
function EGP:GetGlobalPos(Ent, index)
	local bool, _, obj = self:HasObject(Ent, index)
	if bool then
		if obj.verticesindex then -- Object has vertices
			if obj.parent and obj.parent ~= 0 then -- Object is parented
				if obj.parent == -1 then -- object is parented to the cursor
					local xy = { 0, 0 }
					if CLIENT then
						xy = self:EGPCursor(Ent, LocalPlayer())
					end
					local x, y = xy[1], xy[2]
					local r = makeArray(obj)
					for i = 1, #r, 2 do
						local x_ = r[i]
						local y_ = r[i + 1]
						local vec, ang = LocalToWorld(Vector(x_, y_, 0), Angle(), Vector(x, y, 0), Angle())
						r[i] = vec.x
						r[i + 1] = vec.y
					end
					local ret = {}
					if isstring(obj.verticesindex) then
						local temp = makeTable(obj, r)
						addUV(obj, temp)
						ret = { [obj.verticesindex] = temp }
					else ret = makeTable(obj, r) end
					return true, ret
				else
					local hasVertices, data = self:GetGlobalPos(Ent, obj.parent)
					if hasVertices then -- obj and parent have vertices
						local _, _, prnt = self:HasObject(Ent, obj.parent)
						local centerx, centery = getCenter(makeArray(prnt, true))
						local temp = makeArray(obj)
						for i = 1, #temp, 2 do
							temp[i] = centerx + temp[i]
							temp[i + 1] = centery + temp[i + 1]
						end
						local ret = {}
						if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable(obj, temp) } else ret = makeTable(obj, temp) end
						return true, ret
					else -- obj has vertices, parent does not
						local x, y, ang = data.x, data.y, data.angle
						local r = makeArray(obj)
						for i = 1, #r, 2 do
							local x_ = r[i]
							local y_ = r[i + 1]
							local vec, ang = LocalToWorld(Vector(x_, y_, 0), Angle(0, 0, 0), Vector(x, y, 0), Angle(0, -ang, 0))
							r[i] = vec.x
							r[i + 1] = vec.y
						end
						local ret = {}
						if isstring(obj.verticesindex) then
							local temp = makeTable(obj, r)
							addUV(obj, temp)
							ret = { [obj.verticesindex] = temp }
						else ret = makeTable(obj, r) end
						return true, ret
					end
				end
				local ret = {}
				if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable(obj, makeArray(obj)) } else ret = makeTable(obj, makeArray(obj)) end
				return true, ret
			end
			local ret = {}
			if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable(obj, makeArray(obj)) }	else ret = makeTable(obj, makeArray(obj)) end
			return true, ret
		else -- Object does not have vertices
			if obj.parent and obj.parent ~= 0 then -- Object is parented
				if obj.parent == -1 then -- Object is parented to the cursor
					local xy = { 0, 0 }
					if CLIENT then
						xy = self:EGPCursor(Ent, LocalPlayer())
					end
					local x, y = xy[1], xy[2]
					local vec, ang = LocalToWorld(Vector(obj._x, obj._y, 0), Angle(0, obj._angle or 0, 0), Vector(x, y, 0), Angle())
					return false, { x = vec.x, y = vec.y, angle = -ang.y }
				else
					local hasVertices, data = self:GetGlobalPos(Ent, obj.parent)
					if hasVertices then -- obj does not have vertices, parent does
						local _, _, prnt = self:HasObject(Ent, obj.parent)
						local centerx, centery = getCenter(makeArray( prnt, true ))
						return false, { x = (obj._x or obj.x) + centerx, y = (obj._y or obj.y) + centery, angle = -(obj._angle or obj.angle) }
					else -- Neither have vertices
						local x, y, ang = data.x, data.y, data.angle
						local vec, ang = LocalToWorld(Vector(obj._x, obj._y, 0), Angle(0, obj._angle or 0, 0), Vector(x, y, 0), Angle(0, -(ang or 0), 0))
						return false, { x = vec.x, y = vec.y, angle = -ang.y }
					end
				end
			end
			return false, { x = obj.x, y = obj.y, angle = obj.angle or 0 }
		end
	end

	return false, { x = 0, y = 0, angle = 0 }
end

--------------------------------------------------------
-- Parenting functions
--------------------------------------------------------

function EGP:AddParentIndexes(obj)
	if obj.verticesindex then
		-- Copy original positions
		if isstring(obj.verticesindex) then
			obj["_" .. obj.verticesindex] = table.Copy(obj[obj.verticesindex])
		else
			for _, v in ipairs(obj.verticesindex) do
				obj["_" .. v[1]] = obj[v[1]]
				obj["_" .. v[2]] = obj[v[2]]
			end
		end
	else
		obj._x = obj.x
		obj._y = obj.y
		obj._angle = obj.angle
	end
	obj.IsParented = true
end

local function GetChildren(Ent, Obj)
	local ret = {}
	for _, v in ipairs(Ent.RenderTable) do
		if v.parent == Obj.index then
			ret[#ret + 1] = v
		end
	end
	return ret
end

local function CheckParents(Ent, Obj, parentindex, checked)
	if Obj.index == parentindex then return false end
	if not checked[Obj.index] then
		checked[Obj.index] = true
		local ret = true
		for _, v in ipairs(GetChildren(Ent, Obj)) do
			if not CheckParents(Ent, v, parentindex, checked) then
				ret = false
				break
			end
		end
		return ret
	end
	return false
end

function EGP:SetParent(Ent, index, parentindex)
	local bool, _, obj = self:HasObject(Ent, index)
	if bool then
		if parentindex == -1 then -- Parent to cursor?
			if self:EditObject(obj, { parent = parentindex }) then return true, obj end
		else
			local bool2, k2, v2 = self:HasObject(Ent, parentindex)
			if bool2 then
				self:AddParentIndexes(obj)

				if SERVER then parentindex = math.Clamp(parentindex, 1, self.ConVars.MaxObjects:GetInt()) end

				-- If it's already parented to that object
				if obj.parent and obj.parent == parentindex then return false end
				-- If the user is trying to parent it to itself
				if obj.parent and obj.parent == obj.index then return false end
				-- If the user is trying to create a circle of parents, causing an infinite loop
				if not CheckParents(Ent, obj, parentindex, {}) then return false end

				if self:EditObject(obj, { parent = parentindex }) then return true, obj end
			end
		end
	end
end

function EGP:RemoveParentIndexes(obj, hasVertices)
	if hasVertices then
		-- Remove original positions
		if isstring(obj.verticesindex) then
			obj["_" .. obj.verticesindex] = nil
		else
			for _, v in ipairs(obj.verticesindex) do
				obj["_" .. v[1]] = nil
				obj["_" .. v[2]] = nil
			end
		end
	else
		obj._x = nil
		obj._y = nil
		obj._angle = nil
	end
	obj.IsParented = nil
end

function EGP:UnParent(Ent, index)
	local bool, obj = false
	if isnumber(index) then
		bool, _, obj = self:HasObject(Ent, index)
	elseif istable(index) then
		bool = true
		obj = index
		index = obj.index
	end
	if bool then
		local hasVertices, data = self:GetGlobalPos(Ent, index)
		self:RemoveParentIndexes(obj, hasVertices)

		if not obj.parent or obj.parent == 0 then return false end

		data.parent = 0

		if self:EditObject(obj, data, Ent:GetPlayer()) then return true, obj end
	end
end
