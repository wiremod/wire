-- Author: sk8 (& Divran)
local Obj = EGP:NewObject( "PolyOutline" )
Obj.w = nil
Obj.h = nil
Obj.x = nil
Obj.y = nil
Obj.vertices = {}
Obj.verticesindex = "vertices"
Obj.size = 1
Obj.Draw = function( self )
	local n = #self.vertices
	if (self.a>0 and n>0 and self.size>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawPath(self.vertices, self.size, true)
	end
end
Obj.Transmit = function( self, Ent, ply )
	net.WriteUInt( #self.vertices, 16 )
	for i=1,#self.vertices do
		net.WriteInt( self.vertices[i].x, 16 )
		net.WriteInt( self.vertices[i].y, 16 )
	end
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
	tbl.parent = net.ReadInt(16)
	tbl.size = net.ReadInt(16)
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { vertices = self.vertices, material = self.material, r = self.r, g = self.g, b = self.b, a = self.a, parent = self.parent }
end
