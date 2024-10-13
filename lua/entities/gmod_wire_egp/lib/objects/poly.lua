-- Author: Divran
local Obj = E2Lib.EGP.NewObject("Poly")
Obj.vertices = {}
Obj.verticesindex = "vertices"
Obj.HasUV = true
if SERVER then Obj.VerticesUpdate = true end

local base = Obj.BaseClass
local clamp = math.Clamp

-- Returns whether c is to the left of the line from a to b.
local function counterclockwise( a, b, c )
	return (a.x - c.x) * (b.y - c.y) - (b.x - c.x) * (a.y - c.y) > 0
end

Obj.Draw = function( self )
	if (self.a>0 and #self.vertices>2) then
		render.CullMode(counterclockwise(unpack(self.vertices)) and MATERIAL_CULLMODE_CCW or MATERIAL_CULLMODE_CW)
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawPoly( self.vertices )
		render.CullMode(MATERIAL_CULLMODE_CCW)
	end
end
Obj.Transmit = function( self, Ent, ply )
	net.WriteBool(self.VerticesUpdate)
	if self.VerticesUpdate then
		if (#self.vertices <= 255) then
			net.WriteUInt( #self.vertices, 8 )
			for i=1,#self.vertices do
				net.WriteInt( self.vertices[i].x, 16 )
				net.WriteInt( self.vertices[i].y, 16 )
				net.WriteFloat( self.vertices[i].u or 0 )
				net.WriteFloat( self.vertices[i].v or 0 )
			end
			self.VerticesUpdate = false
		else
			net.WriteUInt( 0, 8 )
			EGP:InsertQueue( Ent, ply, EGP._SetVertex, "SetVertex", self.index, self.vertices )
		end
	end
	base.Transmit(self)
end

Obj.Receive = function( self )
	local tbl = {}
	if net.ReadBool() then
		tbl.vertices = {}
		for i = 1, net.ReadUInt(8) do
			tbl.vertices[ i ] = { x = net.ReadInt(16), y = net.ReadInt(16), u = net.ReadFloat(), v = net.ReadFloat() }
		end
	end
	table.Merge(tbl, base.Receive(self))
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { material = self.material, r = self.r, g = self.g, b = self.b, a = self.a, filtering = self.filtering, parent = self.parent, x = self.x, y = self.y, angle = self.angle, vertices = self.vertices }
end

function Obj:Contains(x, y)
	if #self.vertices < 3 then return false end
	-- Convert into {x,y} format that poly uses.
	local point = { x = x, y = y }
	local realpos = EGP.GetGlobalVertices(self.EGP, self)
	local vertices = realpos.vertices

	-- To check whether a point is in the polygon, we check whether it's to the
	-- 'inside' side of each edge. (If the polygon is counterclockwise then the
	-- inside is the left side; otherwise it's the right side.) This only works
	-- for convex polygons, but so does `surface.drawPoly`.
	local inside
	if counterclockwise(vertices[1], vertices[2], vertices[3]) then
		inside = counterclockwise
	else
		inside = function(a, b, c) return counterclockwise(b, a, c) end
	end

	for i = 1, #vertices - 1 do
		if not inside(vertices[i], vertices[i + 1], point) then return false end
	end
	return inside(vertices[#vertices], vertices[1], point)
end

function Obj:EditObject(args)
	local ret = false
	if args.vertices then
		self.vertices = args.vertices
		self.x, self.y = EGP.getCenterFrom(self)
		if self.IsParented then
			self._x, self._y = self.x, self.y
		end
		args.vertices = nil
		self.angle = 0
		if SERVER then self.VerticesUpdate = true end
		ret = true
	end
	if args.x or args.y or args.angle then
		ret = ret or self:SetPos(args.x or self.x, args.y or self.y, args.angle or self.angle)
		args.x = nil
		args.y = nil
		args.angle = nil
		if self._x then args._x, args._y, args._angle = nil, nil, nil end
	end
	for k, v in pairs(args) do
		if self[k] ~= nil and self[k] ~= v then
			self[k] = v
			ret = true
		end
	end
	return ret
end

Obj.Initialize = Obj.EditObject

function Obj:SetPos(x, y, angle)
	local sx, sy, sa = self.x, self.y, self.angle
	if not x then x = sx end
	if not y then y = sy end
	if not angle then angle = sa else angle = angle % 360 end
	if sx == x and sy == y and sa == angle then return false end

	x = clamp(x, -32768, 32767) -- Simple clamp to avoid moving to huge numbers and invoking NaN. Transmit size is u16
	y = clamp(y, -32768, 32767)

	local delta_ang = Angle(0, sa - angle, 0)
	local pos = Vector(x, y, 0)

	for _, v in ipairs(self.vertices) do
		local vec = LocalToWorld(Vector(v.x - sx, v.y - sy, 0), angle_zero, pos, delta_ang)
		v.x, v.y = vec[1], vec[2]
	end
	self.x, self.y, self.angle = x, y, angle
	if SERVER and self._x then self._x, self._y, self._angle = x, y, angle end
	return true
end

function Obj:Set(key, value)
	if key == "vertices" then
		self.vertices = value
		self.x, self.y = EGP.getCenterFrom(self)
		if self.IsParented then
			self._x, self._y = self.x, self.y
		end
		self.angle = 0
		if SERVER then self.VerticesUpdate = true end
		return true
	elseif key == "x" then
		return self:SetPos(value, self.y, self.angle)
	elseif key == "y" then
		return self:SetPos(self.x, value, self.angle)
	elseif key == "angle" then
		return self:SetPos(self.x, self.y, value)
	else
		if self[key] ~= nil and self[key] ~= value then
			self[key] = value
			return true
		end
	end
	return false
end

return Obj