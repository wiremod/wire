-- Author: Divran
local Obj = EGP:NewObject( "Triangle" )
Obj.x2 = 0
Obj.y2 = 0
Obj.x3 = 0
Obj.y3 = 0
Obj.verticesindex = { { "x", "y" }, { "x2", "y2" }, { "x3", "y3" } }
Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawPoly( { { x = self.x, y = self.y, u = 0, v = 0 }, { x = self.x2, y = self.y2, u = 0, v = 1 }, { x = self.x3, y = self.y3, u = 1, v = 0 } } )
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( self.x )
	EGP.umsg.Short( self.y )
	EGP.umsg.Short( self.x2 )
	EGP.umsg.Short( self.y2 )
	EGP.umsg.Short( self.x3 )
	EGP.umsg.Short( self.y3 )
	EGP.umsg.Short( self.parent )
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.x = um:ReadShort()
	tbl.y = um:ReadShort()
	tbl.x2 = um:ReadShort()
	tbl.y2 = um:ReadShort()
	tbl.x3 = um:ReadShort()
	tbl.y3 = um:ReadShort()
	tbl.parent = um:ReadShort()
	EGP:ReceiveMaterial( tbl, um )
	EGP:ReceiveColor( tbl, self, um )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { material = self.material, x = self.x, y = self.y, x2 = self.x2, y2 = self.y2, x3 = self.x3, y3 = self.y3, r = self.r, g = self.g, b = self.b, a = self.a, parent = self.parent }
end
