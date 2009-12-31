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

function ENT:OnRemove()
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

	local ent = self.GPUEntity or self
	local model = ent:GetModel()
	local monitor = WireGPU_Monitors[model]
	local ang = ent:LocalToWorldAngles(monitor.rot)
	local pos = ent:LocalToWorld(monitor.offset)
	local h = 512
	local w = h/monitor.RatioX
	local x = -w/2
	local y = -h/2

	for _,ply in pairs(player.GetAll()) do
		local trace = ply:GetEyeTraceNoCursor()
		if trace.Entity:IsValid() then
			local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
			dist = math.max(dist, trace.Fraction*16384-trace.Entity:BoundingRadius())

			if dist < 64 and trace.Entity == ent then
				if ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_USE) then
					clickActive = 1
				end
				local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)

				local cx = 0.5+cpos.x/(monitor.RS*w)
				local cy = 0.5-cpos.y/(monitor.RS*h)

				if (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
					onScreen = 1
					if (cx ~= self.lastX or cy ~= self.lastY) then
						self.lastX = cx
						self.lastY = cy
						if (self.outputMode) then
							cx = cx * 2 - 1
							cy = -(cy * 2 - 1)
						end
						Wire_TriggerOutput(self.Entity, "X", cx)
						Wire_TriggerOutput(self.Entity, "Y", cy)
						self:ShowOutput(cx, cy, clickActive, 1)
					end
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

function ENT:ShowOutput(cx, cy, activeval, osval)
	self:SetOverlayText(string.format("X = %f, Y = %f, Use = %d, On Screen = %d\n", cx, cy, activeval, osval))
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
	Wire_AdjustOutputs(self.Entity, { "X", "Y", "Use", "OnScreen" })
end
