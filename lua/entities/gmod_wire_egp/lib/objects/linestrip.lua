-- Author: sk8 (& Divran)
local Obj = EGP:NewObject( "LineStrip" )
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
		for i=1,(n-1) do
			local p1,p2 = self.vertices[i],self.vertices[1+i]
			EGP:DrawLine( p1.x, p1.y, p2.x, p2.y, self.size )
		end
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
		tbl.vertices[ #tbl.vertices+1 ] = { x = net.ReadInt(16), y = net.ReadInt(16) }
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
