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

function Obj:Draw(egp)
	if egp.gmod_wire_egp_emitter then
		local objectPosition = Vector(self.target_x, self.target_y, self.target_z)
		local eyePosition = EyePos()

		local direction = objectPosition-eyePosition

		-- localise the positions
		eyePosition = egp:WorldToLocal(eyePosition)
		direction = egp:WorldToLocal(direction + egp:GetPos())

		-- plane/ray intersection:
		--[[
		screenPosition = eyePosition+direction*fraction | screenPosition.y = 0
		0 = eyePosition.y+direction.y*fraction          | - eyePosition.y
		-eyePosition.y = direction.y*fraction           | / direction.y
		-eyePosition.y / direction.y = fraction         | swap sides
		]]

		local fraction = -eyePosition.y / direction.y
		local screenPosition = eyePosition+direction*fraction

		screenPosition = (screenPosition - Vector( -64, 0, 135 )) / 0.25

		self.x = screenPosition.x
		self.y = -screenPosition.z

		-- fraction < 0: object-player-screen: player is between object and screen; object is not seen at all when facing the screen
		-- fraction 0-1: object-screen-player: screen is between object and player; object is seen behind the screen
		-- fraction > 1: screen-object-player: object is between screen and player; object is seen in front of the screen
		-- TODO: hide for fraction < 0 (maybe for > 1 too?)
	elseif egp.gmod_wire_egp_hud then
		local pos = Vector( self.target_x, self.target_y, self.target_z ):ToScreen()
		self.x = pos.x
		self.y = pos.y
	elseif egp.gmod_wire_egp then
	end
end

function Obj:Transmit()
	EGP.umsg.Float( self.target_x )
	EGP.umsg.Float( self.target_y )
	EGP.umsg.Float( self.target_z )
	EGP.umsg.Short((self.angle%360)*64)
end

function Obj:Receive( um )
	local tbl = {}
	tbl.target_x = um:ReadFloat()
	tbl.target_y = um:ReadFloat()
	tbl.target_z = um:ReadFloat()
	tbl.angle = um:ReadShort()/64
	return tbl
end

function Obj:DataStreamInfo()
	return { target_x = self.target_x, target_y = self.target_y, target_z = self.target_z }
end
