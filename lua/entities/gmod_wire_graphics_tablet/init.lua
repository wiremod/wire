--Wire graphics tablet  by greenarrow
--http://forums.facepunchstudios.com/greenarrow

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Graphics Tablet"
ENT.outputMode = false

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, { "X", "Y", "Use", "OnScreen" })

	Wire_TriggerOutput(self, "X", 0)
	Wire_TriggerOutput(self, "Y", 0)
	Wire_TriggerOutput(self, "Use", 0)
	Wire_TriggerOutput(self, "OnScreen", 0)

	self.lastOnscreen = 0
	self.lastX = 0
	self.lastY = 0
	self.lastClick = 0
end

function ENT:Setup(gmode, draw_background)
	self.outputMode = gmode
	self.draw_background = draw_background
	self:SetNetworkedBeamBool("draw_background", draw_background, true)
end

function ENT:Think()
	self.BaseClass.Think(self)
	local onScreen = 0
	local clickActive = 0

	local GPUEntity = self.GPUEntity or self
	local model = GPUEntity:GetModel()
	local monitor = WireGPU_Monitors[model]
	local ang = GPUEntity:LocalToWorldAngles(monitor.rot)
	local pos = GPUEntity:LocalToWorld(monitor.offset)
	local h = 512
	local w = h/monitor.RatioX
	local x = -w/2
	local y = -h/2

	for _,ply in pairs(player.GetAll()) do
		local trace = ply:GetEyeTraceNoCursor()
		local ent = trace.Entity
		if ent:IsValid() then
			local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
			dist = math.max(dist, trace.Fraction*16384-ent:BoundingRadius())

			if dist < 64 and ent == GPUEntity then
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
						Wire_TriggerOutput(self, "X", cx)
						Wire_TriggerOutput(self, "Y", cy)
						self:ShowOutput(cx, cy, clickActive, 1)
					end
				end
			end
		end
	end

	if (onScreen ~= self.lastOnScreen) then
		Wire_TriggerOutput(self, "OnScreen", onScreen)
		self:ShowOutput(self.lastX, self.lastY, self.lastClick, onScreen)
		self.lastOnScreen = onScreen
	end

	if (clickActive ~= self.lastClick) then
		Wire_TriggerOutput(self, "Use", clickActive)
		self:ShowOutput(self.lastX, self.lastY, clickActive, self.lastOnScreen)
		self.lastClick = clickActive
	end

	self:NextThink(CurTime()+0.08)
	return true
end

function ENT:ShowOutput(cx, cy, activeval, osval)
	self:SetOverlayText(string.format("X = %f, Y = %f, Use = %d, On Screen = %d\n", cx, cy, activeval, osval))
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
	Wire_AdjustOutputs(self, { "X", "Y", "Use", "OnScreen" })
end
