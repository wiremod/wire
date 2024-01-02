-- Author: sk8 (& Divran)
local Obj = EGP.ObjectInherit("PolyOutline", "Poly")
Obj.size = 1
Obj.HasUV = nil

local base = Obj.BaseClass

Obj.Draw = function( self )
	local n = #self.vertices
	if (self.a>0 and n>0 and self.size>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawPath(self.vertices, self.size, true)
	end
end

Obj.Transmit = function( self, Ent, ply )
	net.WriteInt(self.size, 16)
	base.Transmit(self)
end

Obj.Receive = function( self )
	local tbl = { size = net.ReadInt(16) }
	table.Merge(tbl, base.Receive(self))
	return tbl
end

Obj.DataStreamInfo = function( self )
	return table.Merge({ size = self.size }, base.DataStreamInfo(self))
end

Obj.Contains = EGP.Objects.Base.Contains

return Obj