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
function Obj:Contains(egp, x, y)
	x, y = EGP.WorldToLocal(egp, self, x, y)
	
	local w, h = self.w / 2, self.h / 2
	if egp.TopLeft then x, y = x - w, y - h end
	
	return -w <= x and x <= w and
	       -h <= y and y <= h
end
