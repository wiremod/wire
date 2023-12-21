-- Author: Divran
local Obj = EGP.ObjectInherit("Circle", "Box")
Obj.angle = 0
Obj.fidelity = 180
Obj.CanTopLeft = nil

local base = Obj.BaseClass

local cos, sin, rad, floor = math.cos, math.sin, math.rad, math.floor
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity"}) then
			local vertices = {}
			local ang = -rad(self.angle)
			local c = cos(ang)
			local s = sin(ang)
			for i=0,360,floor(360/self.fidelity) do
				local radd = rad(i)
				local x = cos(radd)
				local u = (x+1)/2
				local y = sin(radd)
				local v = (y+1)/2

				local tempx = x * self.w * c - y * self.h * s + self.x
				y = x * self.w * s + y * self.h * c + self.y
				x = tempx

				vertices[#vertices+1] = { x = x, y = y, u = u, v = v }
			end
			self.vert_cache.verts = vertices
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawPoly( self.vert_cache.verts )
	end
end

Obj.Transmit = function(self)
	if not self then self = this end
	net.WriteUInt(self.fidelity, 8)
	base.Transmit(self)
end

Obj.Receive = function( self )
	local tbl = {}
	tbl.fidelity = net.ReadUInt(8)
	table.Merge(tbl, base.Receive(self))
	return tbl
end

Obj.DataStreamInfo = function( self )
	local tbl = { fidelity = self.fidelity }
	table.Merge(tbl, base.DataStreamInfo(self))
	return tbl
end

function Obj:Contains(x, y)
	-- Just do this directly since angle doesn't affect circles
	local _, realpos = EGP:GetGlobalPos(self.EGP, self)
	x, y = (x - realpos.x) / self.w, (y - realpos.y) / self.h
	return x * x + y * y <= 1
end

return Obj