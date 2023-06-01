-- Author: Divran
local Obj = EGP:NewObject( "Box" )
Obj.angle = 0
Obj.CanTopLeft = true
Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawTexturedRectRotated( self.x, self.y, self.w, self.h, self.angle )
	end
end
Obj.Transmit = function( self )
	net.WriteInt((self.angle%360)*20, 16)
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.angle = net.ReadInt(16)/20
	table.Merge( tbl, self.BaseClass.Receive( self ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle } )
	return tbl
end
function Obj:Contains(point)
	local theta = math.rad(point.angle + self.angle)
	if theta ~= 0 then
		local cos_theta, sin_theta = math.cos(theta), math.sin(theta)
		point.x, point.y =
			point.x * cos_theta - point.y * sin_theta,
			point.y * cos_theta + point.x * sin_theta
	end
	
	local w, h = self.w / 2, self.h / 2
	return -w <= point.x and point.x <= w and
	       -h <= point.y and point.y <= h
end
