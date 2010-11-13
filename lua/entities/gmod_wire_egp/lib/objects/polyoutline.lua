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
		for i=1,n do
			local p1,p2 = self.vertices[i],self.vertices[1+i%n]
			EGP:DrawLine( p1.x, p1.y, p2.x, p2.y, self.size )
		end
	end
end
Obj.Transmit = function( self, Ent, ply )
	if (#self.vertices <= 56) then
		EGP.umsg.Char(#self.vertices)
		for i=1,#self.vertices do
			EGP.umsg.Short( self.vertices[i].x )
			EGP.umsg.Short( self.vertices[i].y )
		end
	else
		EGP.umsg.Char(-1)
		EGP:InsertQueue( Ent, ply, EGP._SetVertex, "SetVertex", self.index, self.vertices )
	end
	EGP.umsg.Short( self.parent )
	EGP.umsg.Short( self.size )
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	local nr = um:ReadChar()
	tbl.vertices = {}
	for i=1,nr do
		tbl.vertices[ #tbl.vertices+1 ] = { x = um:ReadShort(), y = um:ReadShort() }
	end
	tbl.parent = um:ReadShort()
	tbl.size = um:ReadShort()
	EGP:ReceiveMaterial( tbl, um )
	EGP:ReceiveColor( tbl, self, um )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { vertices = self.vertices, material = self.material, r = self.r, g = self.g, b = self.b, a = self.a, parent = self.parent }
end
