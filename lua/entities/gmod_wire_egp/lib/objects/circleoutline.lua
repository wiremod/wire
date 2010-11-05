-- Author: Divran
local Obj = EGP:NewObject( "CircleOutline" )
Obj.material = ""
Obj.angle = 0
Obj.size = 1
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		local vertices = {}
		local ang = -math.rad(self.angle)
		local c = math.cos(ang)
		local s = math.sin(ang)
		for i=0,360,10 do
			local rad = math.rad(i)
			local x = math.cos(rad)
			local y = math.sin(rad)

			local tempx = x * self.w * c - y * self.h * s + self.x
			y = x * self.w * s + y * self.h * c + self.y
			x = tempx

			vertices[#vertices+1] = { x = x, y = y, u = u, v = v }
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		for k,v in ipairs( vertices ) do
			if (k+1<=#vertices) then
				local x, y = v.x, v.y
				local x2, y2 = vertices[k+1].x, vertices[k+1].y
				EGP:DrawLine( x, y, x2, y2, self.size )
			end
		end

		EGP:DrawLine( vertices[#vertices].x, vertices[#vertices].y, vertices[1].x, vertices[1].y, self.size )
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( self.angle )
	EGP.umsg.Short( self.size )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.angle = um:ReadShort()
	tbl.size = um:ReadShort()
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle, size = self.size } )
	return tbl
end
