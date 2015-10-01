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
		if (!fakepos) then
			if (!v["_"..v.verticesindex]) then EGP:AddParentIndexes( v ) end
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
		if (!fakepos) then
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

-- (returns true if obj has vertices, false if not, followed by the new position data)
function EGP:GetGlobalPos( Ent, index )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		if (v.verticesindex) then -- Object has vertices
			if (v.parent and v.parent != 0) then -- Object is parented
				if (v.parent == -1) then -- object is parented to the cursor
					local xy = {0,0}
					if (CLIENT) then
						xy = self:EGPCursor( Ent, LocalPlayer() )
					end
					local x, y = xy[1], xy[2]
					local r = makeArray( v )
					for i=1,#r,2 do
						local x_ = r[i]
						local y_ = r[i+1]
						local vec, ang = LocalToWorld( Vector( x_, y_, 0 ), Angle(), Vector( x, y, 0 ), Angle() )
						r[i] = vec.x
						r[i+1] = vec.y
					end
					local ret = {}
					if isstring(v.verticesindex) then
						local temp = makeTable( v, r )
						addUV( v, temp )
						ret = { [v.verticesindex] = temp }
					else ret = makeTable( v, r ) end
					return true, ret
				else
					local hasVertices, data = self:GetGlobalPos( Ent, v.parent )
					if (hasVertices) then -- obj and parent have vertices
						local _, _, prnt = self:HasObject( Ent, v.parent )
						local centerx, centery = getCenter( makeArray( prnt, true ) )
						local temp = makeArray( v )
						for i=1,#temp,2 do
							temp[i] = centerx + temp[i]
							temp[i+1] = centery + temp[i+1]
						end
						local ret = {}
						if isstring(v.verticesindex) then ret = { [v.verticesindex] = makeTable( v, temp ) } else ret = makeTable( v, temp ) end
						return true, ret
					else -- obj has vertices, parent does not
						local x, y, ang = data.x, data.y, data.angle
						local r = makeArray( v )
						for i=1,#r,2 do
							local x_ = r[i]
							local y_ = r[i+1]
							local vec, ang = LocalToWorld( Vector( x_, y_, 0 ), Angle( 0, 0, 0 ), Vector( x, y, 0 ), Angle( 0, -ang, 0 ) )
							r[i] = vec.x
							r[i+1] = vec.y
						end
						local ret = {}
						if isstring(v.verticesindex) then
							local temp = makeTable( v, r )
							addUV( v, temp )
							ret = { [v.verticesindex] = temp }
						else ret = makeTable( v, r ) end
						return true, ret
					end
				end
				local ret = {}
				if isstring(v.verticesindex) then ret = { [v.verticesindex] = makeTable( v, makeArray( v ) ) } else ret = makeTable( v, makeArray( v ) ) end
				return true, ret
			end
			local ret = {}
			if isstring(v.verticesindex) then ret = { [v.verticesindex] = makeTable( v, makeArray( v ) ) }	else ret = makeTable( v, makeArray( v ) ) end
			return true, ret
		else -- Object does not have vertices, parent does not
			if (v.parent and v.parent != 0) then -- Object is parented
				if (v.parent == -1) then -- Object is parented to the cursor
					local xy = {0,0}
					if (CLIENT) then
						xy = self:EGPCursor( Ent, LocalPlayer() )
					end
					local x, y = xy[1], xy[2]
					local vec, ang = LocalToWorld( Vector( v._x, v._y, 0 ), Angle( 0, v._angle or 0, 0 ), Vector( x, y, 0 ), Angle() )
					return false, { x = vec.x, y = vec.y, angle = -ang.y }
				else
					local hasVertices, data = self:GetGlobalPos( Ent, v.parent )
					if (hasVertices) then -- obj does not have vertices, parent does
						local _, _, prnt = self:HasObject( Ent, v.parent )
						local centerx, centery = getCenter( makeArray( prnt, true ) )
						return false, { x = (v._x or v.x) + centerx, y = (v._y or v.y) + centery, angle = -(v._angle or v.angle) }
					else -- Niether have vertices
						local x, y, ang = data.x, data.y, data.angle
						local vec, ang = LocalToWorld( Vector( v._x, v._y, 0 ), Angle( 0, v._angle or 0, 0 ), Vector( x, y, 0 ), Angle( 0, -(ang or 0), 0 ) )
						return false, { x = vec.x, y = vec.y, angle = -ang.y }
					end
				end
			end
			return false, { x = v.x, y = v.y, angle = v.angle or 0 }
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
	else
		v._x = v.x
		v._y = v.y
		v._angle = v.angle
	end
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
	if (!checked[Obj.index]) then
		checked[Obj.index] = true
		local ret = true
		for k,v in ipairs( GetChildren( Ent, Obj )) do
			if (!CheckParents( Ent, v, parentindex, checked )) then
				ret = false
				break
			end
		end
		return ret
	end
	return false
end

function EGP:SetParent( Ent, index, parentindex )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		if (parentindex == -1) then -- Parent to cursor?
			if (self:EditObject( v, { parent = parentindex } )) then return true, v end
		else
			local bool2, k2, v2 = self:HasObject( Ent, parentindex )
			if (bool2) then
				self:AddParentIndexes( v )

				if (SERVER) then parentindex = math.Clamp(parentindex,1,self.ConVars.MaxObjects:GetInt()) end

				-- If it's already parented to that object
				if (v.parent and v.parent == parentindex) then return false end
				-- If the user is trying to parent it to itself
				if (v.parent and v.parent == v.index) then return false end
				-- If the user is trying to create a circle of parents, causing an infinite loop
				if (!CheckParents( Ent, v, parentindex, {} )) then return false end

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
	else
		v._x = nil
		v._y = nil
		v._angle = nil
	end
	v.IsParented = nil
end

function EGP:UnParent( Ent, index )
	local bool, k, v = false
	if isnumber(index) then
		bool, k, v = self:HasObject( Ent, index )
	elseif istable(index) then
		bool = true
		v = index
		index = v.index
	end
	if (bool) then
		local hasVertices, data = self:GetGlobalPos( Ent, index )
		self:RemoveParentIndexes( v, hasVertices )

		if (!v.parent or v.parent == 0) then return false end

		data.parent = 0

		if (self:EditObject( v, data, Ent:GetPlayer() )) then return true, v end
	end
end
