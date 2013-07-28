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
