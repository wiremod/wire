-- Author: Divran
local Obj = EGP:NewObject( "BoxOutline" )
Obj.size = 1
Obj.angle = 0
local function rotate( v, a )
	local a = a * math.pi / 180
	local x = math.cos(a) * v[1] - math.sin(a) * v[2]
	local y = math.sin(a) * v[1] + math.cos(a) * v[2]
	return { x, y }
end

Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		local x, y, w, h, a, s = self.x, self.y, self.w, self.h, self.angle, self.size

		local vec1 = rotate( { w / 2 - s / 2, 0 }, -a )
		local vec2 = rotate( { -w / 2 + s / 2, 0 }, -a )
		local vec3 = rotate( { 0, h / 2 - s / 2 }, -a )
		local vec4 = rotate( { 0, -h / 2 + s / 2 }, -a )

		surface.DrawTexturedRectRotated( x + math.ceil(vec1[1]), y + math.ceil(vec1[2]), h, s, a + 90 )
		surface.DrawTexturedRectRotated( x + math.ceil(vec2[1]), y + math.ceil(vec2[2]), h, s, a + 90 )
		surface.DrawTexturedRectRotated( x + math.ceil(vec3[1]), y + math.ceil(vec3[2]), w, s, a )
		surface.DrawTexturedRectRotated( x + math.ceil(vec4[1]), y + math.ceil(vec4[2]), w, s, a )
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( self.size )
	EGP.umsg.Short( self.angle )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.size = um:ReadShort()
	tbl.angle = um:ReadShort()
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	tbl.size = self.size
	tbl.angle = self.angle
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	return tbl
end
