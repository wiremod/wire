--------------------------------------------------------
-- Parenting functions
--------------------------------------------------------
local EGP = EGP
EGP.ParentingFuncs = {}

local function addUV( v, t ) -- Polygon u v fix
	if (v.verticesindex) then
		local t2 = v[v.verticesindex]
		for k,v in ipairs( t ) do
			t[k].u = t2[k].u
			t[k].v = t2[k].v
		end
	end
end
EGP.ParentingFuncs.addUV = addUV

local function makeArray( v, fakepos )
	local ret = {}
	if isstring(v.verticesindex) then
		if fakepos then
			if (not v["_"..v.verticesindex]) then EGP:AddParentIndexes( v ) end
			for k,v in ipairs( v["_"..v.verticesindex] ) do
				ret[#ret+1] = v.x
				ret[#ret+1] = v.y
			end
		else
			for k,v in ipairs( v[v.verticesindex] ) do
				ret[#ret+1] = v.x
				ret[#ret+1] = v.y
			end
		end
	else
		if fakepos then
			for k,v2 in ipairs( v.verticesindex ) do
				ret[#ret+1] = v["_"..v2[1]]
				ret[#ret+1] = v["_"..v2[2]]
			end
		else
			for k,v2 in ipairs( v.verticesindex ) do
				ret[#ret+1] = v[v2[1]]
				ret[#ret+1] = v[v2[2]]
			end
		end
	end
	return ret
end
EGP.ParentingFuncs.makeArray = makeArray

local function makeTable( v, data )
	local ret = {}
	if isstring(v.verticesindex) then
		for i=1,#data,2 do
			ret[#ret+1] = { x = data[i], y = data[i+1] }
		end
	else
		local n = 1
		for k,v in ipairs( v.verticesindex ) do
			ret[v[1]] = data[n]
			ret[v[2]] = data[n+1]
			n = n + 2
		end
	end
	return ret
end
EGP.ParentingFuncs.makeTable = makeTable

local function getCenter( data )
	local centerx, centery = 0, 0
	local n = #data
	for i=1, n, 2 do
		centerx = centerx + data[i]
		centery = centery + data[i+1]
	end
	return centerx / (n/2), centery / (n/2)
end
EGP.ParentingFuncs.getCenter = getCenter

-- Uses the output of GetGlobalPos instead.
local function getCenterFrom(data)
	local centerx, centery = 0, 0
	local vertices = data.vertices
	local n = #vertices
	for i, v in ipairs(vertices) do
		centerx = centerx + v.x
		centery = centery + v.y
	end
	return centerx / n, centery / n
end
EGP.getCenterFrom = getCenterFrom

-- (returns true if obj has vertices, false if not, followed by the new position data)
function EGP:GetGlobalPos( Ent, index )
	local bool, obj
	if istable(index) then
		obj = index
		bool = true
	else
		bool, _, obj = self:HasObject(Ent, index)
	end
	if bool then
		if obj.verticesindex then -- Object has vertices
			if obj.parent and obj.parent ~= 0 then -- Object is parented
				local data, ret
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
						local vec = LocalToWorld(Vector(x_, y_, 0), Angle(0, obj._angle or 0, 0), Vector(x, y, 0), angle_zero)
						r[i] = vec.x
						r[i + 1] = vec.y
					end

					if isstring(obj.verticesindex) then
						local temp = makeTable( obj, r )
						addUV( obj, temp )
						ret = { [obj.verticesindex] = temp }
					else ret = makeTable(obj, r) end
					local vec, ang = LocalToWorld(Vector(obj._x, obj._y, 0), Angle(0, obj._angle or 0, 0), Vector(x, y, 0), Angle(0, -data.angle or 0, 0))
					ret.x, ret.y, ret.angle = vec.x, vec.y, -ang.y
					return true, ret
				else
					local _, _, prnt = self:HasObject(Ent, obj.parent)
					local _, data = self:GetGlobalPos(Ent, prnt)
					local x, y, ang = data.x, data.y, data.angle or 0
					local objang = obj._angle or 0
					local temp = makeArray( obj )
					for i = 1, #temp, 2 do
						local x_ = temp[i]
						local y_ = temp[i + 1]
						local vec = LocalToWorld(Vector(x_, y_, 0), Angle(0, objang, 0), Vector(x, y, 0), Angle(0, -ang, 0))
						temp[i] = vec.x
						temp[i + 1] = vec.y
					end

					if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable(obj, temp) } else ret = makeTable(obj, temp) end
					local vec, ang = LocalToWorld(Vector(obj._x, obj._y, 0), Angle(0, objang, 0), Vector(x, y, 0), Angle(0, -ang, 0))
					ret.x, ret.y, ret.angle = vec.x, vec.y, -ang.y
					return true, ret
				end

				if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable(obj, makeArray(obj)) } else ret = makeTable(obj, makeArray(obj)) end
				local vec, ang = LocalToWorld(Vector(obj._x, obj._y, 0), Angle(0, obj._angle or 0, 0), Vector(data.x, data.y, 0), Angle(0, -data.angle, 0))
				ret.x, ret.y, ret.angle = vec.x, vec.y, -ang.y
				return true, ret
			end
			local ret
			if isstring(obj.verticesindex) then ret = { [obj.verticesindex] = makeTable( obj, makeArray( obj ) ) }	else ret = makeTable( obj, makeArray( obj ) ) end
			ret.x, ret.y, ret.angle = obj.x, obj.y, obj.angle
			return true, ret
		else -- Object does not have vertices
			if obj.parent and obj.parent ~= 0 then -- Object is parented
				if obj.parent == -1 then -- Object is parented to the cursor
					local xy = { 0, 0 }
					if (CLIENT) then
						xy = self:EGPCursor( Ent, LocalPlayer() )
					end
					local x, y = xy[1], xy[2]
					local vec, ang = LocalToWorld( Vector( obj._x, obj._y, 0 ), Angle( 0, obj._angle or 0, 0 ), Vector( x, y, 0 ), angle_zero )
					return false, { x = vec.x, y = vec.y, angle = -ang.y }
				else
					local _, _, prnt = self:HasObject(Ent, obj.parent)
					local _, data = self:GetGlobalPos(Ent, prnt)
					local vec, ang = LocalToWorld( Vector( obj._x, obj._y, 0 ), Angle( 0, obj._angle or 0, 0 ), Vector( data.x, data.y, 0 ), Angle( 0, -(data.angle or 0), 0 ) )
					return false, { x = vec.x, y = vec.y, angle = -ang.y }
				end
			end
			return false, { x = obj.x, y = obj.y, angle = obj.angle or 0 }
		end
	end

	return false, {x=0,y=0,angle=0}
end

--------------------------------------------------------
-- Parenting functions
--------------------------------------------------------

function EGP:AddParentIndexes( v )
	if (v.verticesindex) then
		-- Copy original positions
		if isstring(v.verticesindex) then
			v["_"..v.verticesindex] = table.Copy( v[v.verticesindex] )
		else
			for k,v2 in ipairs( v.verticesindex ) do
				v["_"..v2[1]] = v[v2[1]]
				v["_"..v2[2]] = v[v2[2]]
			end
		end
	end
	v._x = v.x
	v._y = v.y
	v._angle = v.angle
	v.IsParented = true
end

local function GetChildren( Ent, Obj )
	local ret = {}
	for k,v in ipairs( Ent.RenderTable ) do
		if (v.parent == Obj.index) then
			ret[#ret+1] = v
		end
	end
	return ret
end

local function CheckParents( Ent, Obj, parentindex, checked )
	if (Obj.index == parentindex) then
		return false
	end
	if (not checked[Obj.index]) then
		checked[Obj.index] = true
		local ret = true
		for k,v in ipairs( GetChildren( Ent, Obj )) do
			if (not CheckParents( Ent, v, parentindex, checked )) then
				ret = false
				break
			end
		end
		return ret
	end
	return false
end

function EGP:SetParent( Ent, index, parentindex )
	local bool, v
	if isnumber(index) then
		bool, _, v = self:HasObject(Ent, index)
	else
		bool, v = index ~= nil, index
	end
	if (bool) then
		if (parentindex == -1) then -- Parent to cursor?
			if (self:EditObject( v, { parent = parentindex } )) then return true, v end
		else
			if isnumber(parentindex) then
				bool = self:HasObject(Ent, parentindex)
			else
				bool, parentindex = parentindex ~= nil, parentindex.index
			end
			if (bool) then
				self:AddParentIndexes( v )

				if (SERVER) then parentindex = math.Clamp(parentindex,1,self.ConVars.MaxObjects:GetInt()) end

				-- If it's already parented to that object
				if (v.parent and v.parent == parentindex) then return false end
				-- If the user is trying to parent it to itself
				if (v.parent and v.parent == v.index) then return false end
				-- If the user is trying to create a circle of parents, causing an infinite loop
				if (not CheckParents( Ent, v, parentindex, {} )) then return false end

				if (self:EditObject( v, { parent = parentindex } )) then return true, v end
			end
		end
	end
end

function EGP:RemoveParentIndexes( v, hasVertices )
	if (hasVertices) then
		-- Remove original positions
		if isstring(v.verticesindex) then
			v["_"..v.verticesindex] = nil
		else
			for k,v2 in ipairs( v.verticesindex ) do
				v["_"..v2[1]] = nil
				v["_"..v2[2]] = nil
			end
		end
	end
	v._x = nil
	v._y = nil
	v._angle = nil
	v.IsParented = nil
end

function EGP:UnParent( Ent, index )
	local bool, v = false
	if isnumber(index) then
		bool, _, v = self:HasObject( Ent, index )
	else
		bool = istable(index)
		v = index
		index = v.index
	end
	if (bool) then
		local hasVertices, data = self:GetGlobalPos( Ent, index )
		self:RemoveParentIndexes( v, hasVertices )

		if (not v.parent or v.parent == 0) then return false end

		data.parent = 0

		if (self:EditObject( v, data, Ent:GetPlayer() )) then return true, v end
	end
end
