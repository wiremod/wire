-- Author: sk8 (& Divran)
local Obj = EGP.ObjectInherit("RoundedBoxOutline", "RoundedBox")
Obj.size = 1

local base = Obj.BaseClass

Obj.Draw = function( self )
    if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity", "radius"}) then
	local xs,ys , sx,sy = self.x,self.y , self.w, self.h
	local polys = {}
	local source = { {x=-1,y=-1} , {x=1,y=-1} , {x=1,y=1} , {x=-1,y=1} }
	local radius = math.max(0,math.min((math.min(sx,sy)/2), self.radius ))
	local div,angle = 360/self.fidelity, -self.angle
	for x=1,4 do
	    for i=0,(self.fidelity+1)/4 do
		local srx,sry = source[x].x,source[x].y
		local scx,scy = srx*(sx-(radius*2))/2 , sry*(sy-(radius*2))/2
		scx,scy = scx*math.cos(math.rad(angle)) - scy*math.sin(math.rad(angle)),
			  scx*math.sin(math.rad(angle)) + scy*math.cos(math.rad(angle))
		local a,r = math.rad(div*i+(x*90)), radius
		local dir = {x=math.sin(-(a+math.rad(angle))),y=math.cos(-(a+math.rad(angle)))}
		polys[#polys+1] = {x=xs+scx+(dir.x*r),  y=ys+scy+(dir.y*r)}
	    end
	end
	self.vert_cache.verts = polys
    end
    surface.SetDrawColor(self.r,self.g,self.b,self.a)
    EGP:DrawPath(self.vert_cache.verts, self.size, true)
end
Obj.Transmit = function( self )
	net.WriteInt(self.size, 16)
	base.Transmit(self)
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.size = net.ReadInt(16)
	table.Merge(tbl, base.Receive(self))
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = { size = self.size }
	table.Merge(tbl, base.DataStreamInfo(self))
	return tbl
end

Obj.Contains = nil

return Obj