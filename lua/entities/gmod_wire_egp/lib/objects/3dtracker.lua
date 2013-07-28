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
Obj.parententity = NULL
Obj.Is3DTracker = true
Obj.angle = 0

function Obj:Draw(egp)
	if egp.gmod_wire_egp_emitter then
		local objectPosition
		if self.parententity and self.parententity:IsValid() then
			objectPosition = self.parententity:LocalToWorld(Vector(self.target_x,self.target_y,self.target_z))
		else
			objectPosition = Vector(self.target_x,self.target_y,self.target_z)
		end

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

		if fraction < 0 then -- hide for fraction < 0 (maybe for > 1 too?)
			self.x = math.huge
			self.y = math.huge
		else
			self.x = screenPosition.x
			self.y = -screenPosition.z
		end

		-- fraction < 0: object-player-screen: player is between object and screen; object is not seen at all when facing the screen
		-- fraction 0-1: object-screen-player: screen is between object and player; object is seen behind the screen
		-- fraction > 1: screen-object-player: object is between screen and player; object is seen in front of the screen
	elseif egp.gmod_wire_egp_hud then
		local pos
		if self.parententity and self.parententity:IsValid() then
			pos = self.parententity:LocalToWorld(Vector(self.target_x,self.target_y,self.target_z))
		else
			pos = Vector(self.target_x,self.target_y,self.target_z)
		end

		local pos = pos:ToScreen()
		self.x = pos.x
		self.y = pos.y
	elseif egp.gmod_wire_egp then
	end
end

function Obj:Transmit()
	net.WriteFloat( self.target_x )
	net.WriteFloat( self.target_y )
	net.WriteFloat( self.target_z )
	net.WriteEntity( self.parententity )
	net.WriteInt((self.angle%360)*64, 16)
end

function Obj:Receive()
	local tbl = {}
	tbl.target_x = net.ReadFloat()
	tbl.target_y = net.ReadFloat()
	tbl.target_z = net.ReadFloat()
	local parententity = net.ReadEntity()
	if parententity and parententity:IsValid() then tbl.parententity = parententity end
	tbl.angle = net.ReadInt(16)/64
	return tbl
end

function Obj:DataStreamInfo()
	return { target_x = self.target_x, target_y = self.target_y, target_z = self.target_z, parententity = self.parententity }
end
