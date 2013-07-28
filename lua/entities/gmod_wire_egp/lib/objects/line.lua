-- Author: Divran
local Obj = EGP:NewObject( "Line" )
Obj.w = nil
Obj.h = nil
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
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, x2 = self.x2, y2 = self.y2, r = self.r, g = self.g, b = self.b, a = self.a, size = self.size, parent = self.parent }
end
