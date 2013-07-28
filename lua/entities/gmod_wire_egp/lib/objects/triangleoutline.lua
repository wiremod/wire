-- Author: Divran
local Obj = EGP:NewObject( "TriangleOutline" )
Obj.x2 = 0
Obj.y2 = 0
Obj.x3 = 0
Obj.y3 = 0
Obj.verticesindex = { { "x", "y" }, { "x2", "y2" }, { "x3", "y3" } }
Obj.size = 1
Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawLine( self.x, self.y, self.x2, self.y2, self.size )
		EGP:DrawLine( self.x2, self.y2, self.x3, self.y3, self.size )
		EGP:DrawLine( self.x3, self.y3, self.x, self.y, self.size )
	end
end
Obj.Transmit = function( self )
	net.WriteInt( self.x, 16 )
	net.WriteInt( self.y, 16 )
	net.WriteInt( self.x2, 16 )
	net.WriteInt( self.y2, 16 )
	net.WriteInt( self.x3, 16 )
	net.WriteInt( self.y3, 16 )
	net.WriteInt( self.size, 16 )
	net.WriteInt( self.parent, 16 )
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.x = net.ReadInt(16)
	tbl.y = net.ReadInt(16)
	tbl.x2 = net.ReadInt(16)
	tbl.y2 = net.ReadInt(16)
	tbl.x3 = net.ReadInt(16)
	tbl.y3 = net.ReadInt(16)
	tbl.size = net.ReadInt(16)
	tbl.parent = net.ReadInt(16)
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { material = self.material, x = self.x, y = self.y, x2 = self.x2, y2 = self.y2, x3 = self.x3, y3 = self.y3, r = self.r, g = self.g, b = self.b, a = self.a, size = self.size, parent = self.parent }
end
