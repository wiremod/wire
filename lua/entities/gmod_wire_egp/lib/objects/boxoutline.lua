-- Author: Divran
local Obj = EGP:NewObject( "BoxOutline" )
Obj.size = 1
Obj.angle = 0
Obj.CanTopLeft = true
local function rotate( x, y, a )
	local a = a * math.pi / 180
	local _x = math.cos(a) * x - math.sin(a) * y
	local _y = math.sin(a) * x + math.cos(a) * y
	return _x, _y
end

Obj.Draw = function( self, egp )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		local x, y, w, h, a, s = self.x, self.y, self.w, self.h, self.angle, self.size

		local x1, y1 = rotate( w / 2 - s / 2, 0, -a )
		local x2, y2 = rotate( -w / 2 + s / 2, 0, -a )
		local x3, y3 = rotate( 0, h / 2 - s / 2, -a )
		local x4, y4 = rotate( 0, -h / 2 + s / 2, -a )

		if egp.gmod_wire_egp_emitter then -- is emitter
			if (h - s*2 > 0) then
				-- Right
				surface.DrawTexturedRectRotated( x + math.ceil(x1), y + math.Round(y1), h - s*2, s, a - 90 )
				-- Left
				surface.DrawTexturedRectRotated( x + math.floor(x2), y + math.Round(y2), h - s*2, s, a + 90 )
			end
			-- Bottom
			surface.DrawTexturedRectRotated( x + math.Round(x3), y + math.floor(y3), w, s, a + 180 )
			-- Top
			surface.DrawTexturedRectRotated( x + math.Round(x4), y + math.ceil(y4), w, s, a )
		else -- is not emitter
			if (h - s*2 > 0) then
				-- Right
				surface.DrawTexturedRectRotated( x + math.ceil(x1), y + math.ceil(y1), h - s*2, s, a - 90 )
				-- Left
				surface.DrawTexturedRectRotated( x + math.ceil(x2), y + math.ceil(y2), h - s*2, s, a + 90 )
			end
			-- Bottom
			surface.DrawTexturedRectRotated( x + math.ceil(x3), y + math.ceil(y3), w, s, a + 180 )
			-- Top
			surface.DrawTexturedRectRotated( x + math.ceil(x4), y + math.ceil(y4), w, s, a )
		end
	end
end

Obj.Transmit = function( self )
	net.WriteInt( self.size, 16 )
	net.WriteInt( (self.angle%360)*20, 16 )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.size = net.ReadInt(16)
	tbl.angle = net.ReadInt(16)/20
	table.Merge( tbl, self.BaseClass.Receive( self ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	tbl.size = self.size
	tbl.angle = self.angle
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	return tbl
end
