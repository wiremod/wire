--Wire graphics tablet  by greenarrow
--http://forums.facepunchstudios.com/greenarrow

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Graphics Tablet"
ENT.outputMode = false

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self.Entity, { "X", "Y", "Use", "OnScreen" })

	Wire_TriggerOutput(self.Entity, "X", 0)
	Wire_TriggerOutput(self.Entity, "Y", 0)
	Wire_TriggerOutput(self.Entity, "Use", 0)
	Wire_TriggerOutput(self.Entity, "OnScreen", 0)

	self.lastOnscreen = 0
	self.lastX = 0
	self.lastY = 0
	self.lastClick = 0
	self:SetupParams()
end

function ENT:Setup(gmode)
	self.outputMode = gmode
end

function ENT:Use()
end

function ENT:Think()
	self.BaseClass.Think(self)
	local onScreen = 0
	local clickActive = 0

	for i, player in pairs(player.GetAll()) do
		local trace = {}
			trace.start = player:GetShootPos()
			trace.endpos = (player:GetAimVector() * self.workingDistance) + trace.start
			trace.filter = player
		local trace = util.TraceLine(trace)

		if (trace.Entity == self.Entity) then
			if (player:KeyDown (IN_ATTACK) or player:KeyDown (IN_USE)) then
				clickActive = 1
			end
			local pos = self.Entity:WorldToLocal(trace.HitPos)
			local xval = (self.x1 - pos.y) / (self.x1 - self.x2)
			local yval = (self.y1 - pos.z) / (self.y1 - self.y2)

			if (xval >= 0 and yval >= 0 and xval <= 1 and yval <= 1) then
				onScreen = 1
				if (xval ~= self.lastX or yval ~= self.lastY) then
					if (self.outputMode) then
						xval = (xval * 2) - 1
						yval = (-yval * 2) + 1
					end
					Wire_TriggerOutput(self.Entity, "X", xval)
					Wire_TriggerOutput(self.Entity, "Y", yval)
					self:ShowOutput(xval, yval, self.lastClick, self.lastOnScreen)
					self.lastX = xval
					self.lastY = yval
				end
			end
		end
	end

	if (onScreen ~= self.lastOnScreen) then
		Wire_TriggerOutput(self.Entity, "OnScreen", onScreen)
		self:ShowOutput(self.lastX, self.lastY, self.lastClick, onScreen)
		self.lastOnScreen = onScreen
	end

	if (clickActive ~= self.lastClick) then
		Wire_TriggerOutput(self.Entity, "Use", clickActive)
		self:ShowOutput(self.lastX, self.lastY, clickActive, self.lastOnScreen)
		self.lastClick = clickActive
	end

	self.Entity:NextThink(CurTime()+0.08)
	return true
end

function ENT:ShowOutput(xval, yval, activeval, osval)
	self:SetOverlayText(string.format("X = %f, Y = %f, Use = %d, On Screen = %d\n", xval, yval, activeval, osval))
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
	Wire_AdjustOutputs(self.Entity, { "X", "Y", "Use", "OnScreen" })
end
