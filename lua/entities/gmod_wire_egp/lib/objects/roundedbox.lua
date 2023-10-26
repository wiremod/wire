-- Author: sk8 (& Divran)
local Obj = EGP.ObjectInherit("RoundedBox", "Box")
Obj.radius = 16
Obj.fidelity = 36

local base = Obj.BaseClass
local max, min, sin, cos, rad = math.max, math.min, math.sin, math.cos, math.rad

function Obj:Calculate()
	if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity", "radius"}) then
		local xs,ys , sx,sy = self.x,self.y , self.w, self.h
		local polys = {}
		local source = { {x=-1,y=-1} , {x=1,y=-1} , {x=1,y=1} , {x=-1,y=1} }
		local radius = max(0, min(min(sx, sy) / 2, self.radius))
		local div, angle = 360/self.fidelity, rad(-self.angle)
		for x=1,4 do
			for i = 0, (self.fidelity + 1) / 4 do
			local srx,sry = source[x].x,source[x].y
			local scx,scy = srx*(sx-(radius*2))/2 , sry*(sy-(radius*2))/2
			scx,scy = scx * cos(angle) - scy * sin(angle),
				scx * sin(angle) + scy * cos(angle)
			local a, r = rad(div*i+(x*90)), radius
			local dir = {x = sin(-(a + angle)),y = cos(-(a + angle))}
			local dirUV = {x = sin(-a),y = cos(-a)}
			local ru,rv = (radius/sx), (radius/sy)
			local u,v = 0.5 + (dirUV.x*ru) + (srx/2)*(1-(ru*2)),
					0.5 + (dirUV.y*rv) + (sry/2)*(1-(rv*2))
					polys[#polys+1] = {x=xs+scx+(dir.x*r),  y=ys+scy+(dir.y*r) , u=u,v=v}
	    end
	end
	self.vert_cache.verts = polys
    end
end

Obj.Draw = function( self )
    self:Calculate()

    surface.SetDrawColor(self.r,self.g,self.b,self.a)
    surface.DrawPoly(self.vert_cache.verts)
end
Obj.Transmit = function( self )
	net.WriteInt(self.radius, 16)
	net.WriteUInt(self.fidelity, 8)
	base.Transmit(self)
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.radius = net.ReadInt(16)
	tbl.fidelity = net.ReadUInt(8)
	table.Merge(tbl, base.Receive(self))
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, base.DataStreamInfo( self ) )
	table.Merge( tbl, { radius = self.radius, fidelity = self.fidelity } )
	return tbl
end
function Obj:Contains(x, y)
	x, y = EGP.WorldToLocal(self, x, y)

	local w, h = self.w / 2, self.h / 2
	if self.EGP.TopLeft then x, y = x - w, y - h end

	local r = min(min(w, h), self.radius)
	x, y = math.abs(x), math.abs(y)
	if x > w or y > h then return false end
	x, y = x - w + r, y - h + r
	if x < 0 or y < 0 then return true end
	x, y = x / h, y / h
	return x * x + y * y <= 1
end

return Obj