-- Author: Divran
local Obj = EGP:NewObject( "Line" )
Obj.w = nil
Obj.h = nil
Obj.angle = 0
Obj.x2 = 0
Obj.y2 = 0
Obj.size = 1
Obj.verticesindex = { { "x", "y" }, { "x2", "y2" } }
Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawLine( self.x, self.y, self.x2, self.y2, self.size )
	end
end
Obj.Transmit = function( self )
	net.WriteInt( self.x, 16 )
	net.WriteInt( self.y, 16 )
	net.WriteInt( self.x2, 16 )
	net.WriteInt( self.y2, 16 )
	net.WriteInt( self.size, 16 )
	net.WriteInt( self.parent, 16 )
	net.WriteInt(self.angle, 10)
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.x = net.ReadInt(16)
	tbl.y = net.ReadInt(16)
	tbl.x2 = net.ReadInt(16)
	tbl.y2 = net.ReadInt(16)
	tbl.size = net.ReadInt(16)
	tbl.parent = net.ReadInt(16)
	tbl.angle = net.ReadInt(10)
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, x2 = self.x2, y2 = self.y2, angle = self.angle, r = self.r, g = self.g, b = self.b, a = self.a, size = self.size, parent = self.parent }
end

function Obj:EditObject(args)
	local ret = false
	if args.x or args.y or args.angle or args.x2 or args.y2 then
		ret = self:SetPos(args.x or self.x, args.y or self.y, args.angle or self.angle, args.x2 or self.x2, args.y2 or self.y2)
		args.x = nil
		args.x2 = nil
		args.y = nil
		args.y2 = nil
		args.angle = nil
		if args._x then args._x, args._x2, args._y, args._y2, args._angle = nil, nil, nil, nil, nil end
	end
	for k, v in pairs(args) do
		if self[k] ~= nil and self[k] ~= v then
			self[k] = v
			ret = true
		end
	end
	return ret
end

function Obj:SetPos(x, y, angle, x2, y2)
	local sx, sx2, sy, sy2, sa = self.x, self.x2, self.y, self.y2, self.angle
	if not angle then angle = sa end
	if sx == x and sy == y and sa == angle and sx2 == x2 and sy2 == y2 then return false end
	local vec = LocalToWorld(Vector(sx2 - sx, sy2 - sy, 0), angle_zero, Vector(x, y, 0), Angle(0, sa - angle, 0))

	self.x, self.y, self.angle = x, y, angle
	self.x2, self.y2 = vec.x, vec.y
	if self._x then self._x, self._y, self._angle, self._x2, self._y2 = x, y, angle, x2, y2 end
	return true
end