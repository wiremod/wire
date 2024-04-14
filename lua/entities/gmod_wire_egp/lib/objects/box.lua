-- Author: Divran

local Obj = E2Lib.EGP.NewObject("Box")
Obj.CanTopLeft = true
Obj.w = 0
Obj.h = 0

local base = Obj.BaseClass

Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawTexturedRectRotated( self.x, self.y, self.w, self.h, self.angle )
	end
end

Obj.Transmit = function( self )
	EGP.SendSize(self)
	base.Transmit(self)
end

Obj.Receive = function( self )
	local tbl = {}
	EGP.ReceiveSize(tbl)
	table.Merge(tbl, base.Receive(self))
	return tbl
end

function Obj:DataStreamInfo()
	local tbl = { w = self.w, h = self.h }
	table.Merge(tbl, base.DataStreamInfo(self))
	return tbl
end

function Obj:Contains(x, y)
	x, y = EGP.WorldToLocal(self, x, y)

	local w, h = self.w / 2, self.h / 2
	if self.EGP.TopLeft then x, y = x - w, y - h end

	return -w <= x and x <= w and
		-h <= y and y <= h
end

return Obj