-- Author: Divran
local Obj = EGP:NewObject( "Poly" )
Obj.w = nil
Obj.h = nil
Obj.x = nil
Obj.y = nil
Obj.vertices = {}
Obj.verticesindex = "vertices"
Obj.HasUV = true

-- Returns whether c is to the left of the line from a to b.
local function counterclockwise( a, b, c )
	local area = (a.x - c.x) * (b.y - c.y) - (b.x - c.x) * (a.y - c.y)
	return area > 0
end

Obj.Draw = function( self )
	if (self.a>0 and #self.vertices>2) then
		render.CullMode(counterclockwise(unpack(self.vertices)) and MATERIAL_CULLMODE_CCW or MATERIAL_CULLMODE_CW)
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawPoly( self.vertices )
		render.CullMode(MATERIAL_CULLMODE_CCW)
	end
end
Obj.Transmit = function( self, Ent, ply )
	if (#self.vertices <= 28) then
		net.WriteUInt( #self.vertices, 8 )
		for i=1,#self.vertices do
			net.WriteInt( self.vertices[i].x, 16 )
			net.WriteInt( self.vertices[i].y, 16 )
			net.WriteFloat( self.vertices[i].u or 0 )
			net.WriteFloat( self.vertices[i].v or 0 )
		end
	else
		net.WriteUInt( 0, 8 )
		EGP:InsertQueue( Ent, ply, EGP._SetVertex, "SetVertex", self.index, self.vertices )
	end
	net.WriteInt( self.parent, 16 )
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.vertices = {}
	for i=1,net.ReadUInt(8) do
		tbl.vertices[ #tbl.vertices+1 ] = { x = net.ReadInt(16), y = net.ReadInt(16), u = net.ReadFloat(), v = net.ReadFloat() }
	end
	tbl.parent = net.ReadInt(16)
	EGP:ReceiveMaterial( tbl )
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { vertices = self.vertices, material = self.material, r = self.r, g = self.g, b = self.b, a = self.a, parent = self.parent }
end
