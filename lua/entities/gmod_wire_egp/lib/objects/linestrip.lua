-- Author: sk8 (& Divran)
local Obj = EGP:NewObject( "LineStrip" )
Obj.w = nil
Obj.h = nil
Obj.angle = 0
Obj.vertices = {}
Obj.verticesindex = "vertices"
Obj.size = 1
Obj.Draw = function( self )
	local n = #self.vertices
	if (self.a>0 and n>0 and self.size>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		EGP:DrawPath(self.vertices, self.size, false)
	end
end
Obj.Transmit = function( self, Ent, ply )
	net.WriteUInt( #self.vertices, 16 )
	for i=1,#self.vertices do
		net.WriteInt( self.vertices[i].x, 16 )
		net.WriteInt( self.vertices[i].y, 16 )
	end
	net.WriteInt(self.angle, 10)
	net.WriteInt(self.parent, 16)
	net.WriteInt(self.size, 16)
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.vertices = {}
	for i=1,net.ReadUInt(16) do
		tbl.vertices[ i ] = { x = net.ReadInt(16), y = net.ReadInt(16) }
	end
	tbl.angle = net.ReadInt(10)
	tbl.parent = net.ReadInt(16)
	tbl.size = net.ReadInt(16)
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { vertices = self.vertices, material = self.material, r = self.r, g = self.g, b = self.b, a = self.a, parent = self.parent, angle = self.angle }
end

function Obj:Initialize(args)
	self:EditObject(args)
	self.x, self.y = EGP.getCenterFrom(self)
end

function Obj:EditObject(args)
	local ret = false
	if args.vertices then
		self.vertices = args.vertices
		self.x, self.y = EGP.getCenterFrom(self)
		args.vertices = nil
	end
	if args.x or args.y or args.angle then
		ret = self:SetPos(args.x or self.x, args.y or self.y, args.angle or self.angle)
		args.x = nil
		args.y = nil
		args.angle = nil
		if args._x then args._x = nil args._y = nil args._angle = nil end
	end
	for k, v in pairs(args) do
		if self[k] ~= nil and self[k] ~= v then
			self[k] = v
			ret = true
		end
	end
	return ret
end

function Obj:SetPos(x, y, angle)
	local sx, sy, sa = self.x, self.y, self.angle
	if not angle then angle = sa end
	if sx == x and sy == y and sa == angle then return false end
	for i, v in ipairs(self.vertices) do
		local vec = LocalToWorld(Vector(v.x - sx, v.y - sy, 0), angle_zero, Vector(x, y, 0), Angle(0, sa - angle, 0))
		v.x = vec.x
		v.y = vec.y
	end
	self.x, self.y, self.angle = x, y, angle
	if self._x then self._x, self._y, self._angle = x, y, angle end
	return true
end

function Obj:Set(key, value)
	if key == "vertices" then
		self.vertices = value
		self.x, self.y = EGP.getCenterFrom(self)
		return true
	elseif key == "x" then
		ret = self:SetPos(value, self.y, self.angle)
		return true
	elseif key == "y" then
		ret = self:SetPos(self.x, value, self.angle)
		return true
	elseif key == "angle" then
		ret = self:SetPos(self.x, self.y, value)
		return true
	else
		if self[key] ~= nil and self[key] ~= value then
			self[key] = value
			return true
		end
	end
	return false
end