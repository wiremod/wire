-- Author: Divran
local Obj = EGP:NewObject( "3DTracker" )
Obj.material = nil
Obj.w = nil
Obj.h = nil
Obj.target_x = 0
Obj.target_y = 0
Obj.target_z = 0
Obj.r = nil
Obj.g = nil
Obj.b = nil
Obj.a = nil
Obj.parent = nil
Obj.Is3DTracker = true
Obj.angle = 0
Obj.Draw = function( self )
	local pos = Vector( self.target_x, self.target_y, self.target_z ):ToScreen()
	self.x = pos.x
	self.y = pos.y
end
Obj.Transmit = function( self )
	EGP.umsg.Float( self.target_x )
	EGP.umsg.Float( self.target_y )
	EGP.umsg.Float( self.target_z )
	EGP.umsg.Short((self.angle%360)*20)
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.target_x = um:ReadFloat()
	tbl.target_y = um:ReadFloat()
	tbl.target_z = um:ReadFloat()
	tbl.angle = um:ReadShort()/20
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { target_x = self.target_x, target_y = self.target_y, target_z = self.target_z }
end
