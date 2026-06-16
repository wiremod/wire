-- Author: sk8 (& Divran)
local Obj = E2Lib.EGP.ObjectInherit("RoundedBoxOutline", "RoundedBox")
Obj.size = 1
Obj.filtering = nil

local base = Obj.BaseClass

Obj.Draw = function( self )
    self:Calculate()

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

return Obj