-- Author: Divran

local Obj = E2Lib.EGP.NewObject("3DTracker")
Obj.material = nil
Obj.filtering = nil
Obj.target_x = 0
Obj.target_y = 0
Obj.target_z = 0
Obj.r = nil
Obj.g = nil
Obj.b = nil
Obj.a = nil
Obj.parententity = NULL
Obj.NeedsConstantUpdate = true
Obj.directionality = 0

function Obj:Draw(egp)
	local objectPosition
	if self.parententity and self.parententity:IsValid() then
		objectPosition = self.parententity:LocalToWorld(Vector(self.target_x,self.target_y,self.target_z))
	else
		objectPosition = Vector(self.target_x,self.target_y,self.target_z)
	end

	if egp.gmod_wire_egp_hud then
		local pos = objectPosition:ToScreen()
		self.x = pos.x
		self.y = pos.y
		return
	end

	local eyePosition = EyePos()

	local direction = objectPosition-eyePosition

	local ratioX, ratioY
	if egp.gmod_wire_egp_emitter then
		ratioX = 4
		ratioY = 4
		-- localise the positions
		eyePosition = egp:WorldToLocal(eyePosition) - Vector( -64, 0, 135 )
		direction = egp:WorldToLocal(direction + egp:GetPos())
	elseif egp.gmod_wire_egp then
		local monitor = WireGPU_Monitors[ egp:GetModel() ]
		if not monitor then self.x = math.huge self.y = math.huge return end
		local Ang = egp:LocalToWorldAngles( monitor.rot )
		local Pos = egp:LocalToWorld( monitor.offset )

		ratioY = 1 / monitor.RS
		ratioX = monitor.RatioX * ratioY

		eyePosition = WorldToLocal(eyePosition, Angle(), Pos, Ang)
		eyePosition:Rotate(Angle(0,0,90))
		eyePosition = eyePosition + Vector(256/ratioX, 0, -256/ratioY)

		direction = WorldToLocal(direction, Angle(), Vector(), Ang)
		direction:Rotate(Angle(0,0,90))
	end

	-- plane/ray intersection:
	--[[
	screenPosition = eyePosition+direction*fraction | screenPosition.y = 0
	0 = eyePosition.y+direction.y*fraction          | - eyePosition.y
	-eyePosition.y = direction.y*fraction           | / direction.y
	-eyePosition.y / direction.y = fraction         | swap sides
	]]

	local fraction = -eyePosition.y / direction.y
	local screenPosition = eyePosition+direction*fraction

	if fraction < 0 then -- hide for fraction < 0
		self.x = math.huge
		self.y = math.huge
	elseif (fraction - 1) * self.directionality < 0 then -- hide for fraction > 1 if directionality < 0 and for fraction < 1 if directionality > 0
		self.x = math.huge
		self.y = math.huge
	else
		self.x = screenPosition.x * ratioX
		self.y = -screenPosition.z * ratioY
	end

	-- fraction < 0: object-player-screen: player is between object and screen; object is not seen at all when facing the screen
	-- fraction 0-1: object-screen-player: screen is between object and player; object is seen behind the screen
	-- fraction > 1: screen-object-player: object is between screen and player; object is seen in front of the screen
end

function Obj:Transmit()
	net.WriteFloat( self.target_x )
	net.WriteFloat( self.target_y )
	net.WriteFloat( self.target_z )
	net.WriteEntity( self.parententity )
	net.WriteInt(self.angle * 64, 16)
	net.WriteInt( self.directionality, 2 )
end

function Obj:Receive()
	local tbl = {}
	tbl.target_x = net.ReadFloat()
	tbl.target_y = net.ReadFloat()
	tbl.target_z = net.ReadFloat()
	local parententity = net.ReadEntity()
	if parententity and parententity:IsValid() then tbl.parententity = parententity end
	tbl.angle = net.ReadInt(16)/64
	tbl.directionality = net.ReadInt(2)
	return tbl
end

function Obj:DataStreamInfo()
	return { target_x = self.target_x, target_y = self.target_y, target_z = self.target_z, parententity = self.parententity, directionality = self.directionality }
end

return Obj