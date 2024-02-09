AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Graphics Tablet"
ENT.WireDebugName	= "Graphics Tablet"
ENT.Author = "greenarrow"
ENT.Editable = true

ENT.workingDistance = 64

local SCREEN_CURSOR = false -- (0, 0) is top left, (1, 1) is bottom right
local GRAPH_CURSOR = true -- (0, 0) is center, (1, 1) is top right

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "DrawBackground", { KeyName = "DrawBackground",
		Edit = { type = "Boolean", title = "#Tool_wire_graphics_tablet_mode", order = 1 } })
	self:NetworkVar("Bool", 1, "CursorMode", { KeyName = "CursorMode",
		Edit = { type = "Boolean", title = "#Tool_wire_graphics_tablet_draw_background", order = 2 } })
end

if CLIENT then
	function ENT:Initialize()
		self.GPU = WireGPU(self, true)
	end

	function ENT:OnRemove()
		self.GPU:Finalize()
	end

	local function cut_rect(x1,y1,w1,h1,x2,y2,w2,h2)
		local x,y = x1>x2 and x1 or x2, y1>y2 and y1 or y2
		local right1,bottom1,right2,bottom2 = x1+w1,y1+h1, x2+w2,y2+h2
		local w,h = (right1<right2 and right1 or right2)-x, (bottom1<bottom2 and bottom1 or bottom2)-y
		return x,y,w,h
	end

	function ENT:Draw()
		self:DrawModel()

		local draw_background = self:GetDrawBackground()
		self.GPU:RenderToWorld(nil, 512, function(x, y, w, h, monitor, pos, ang, res)
			if draw_background then
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(x, y, w, h)
			end

			local ply = LocalPlayer()
			local trace = ply:GetEyeTraceNoCursor()
			local ent = trace.Entity
			if ent:IsValid() then
				local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
				dist = math.max(dist, trace.Fraction*16384-ent:BoundingRadius())
				--WireLib.hud_debug(""..dist, true)

				if dist < self.workingDistance and ent == self.GPU.Entity then
					local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)

					local cx = 0.5+cpos.x/(res*w)
					local cy = 0.5-cpos.y/(res*h)

					if cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
						surface.SetDrawColor(255, 255, 255, 255)
						--surface.SetTexture(surface.GetTextureID("gui/arrow"))
						--surface.DrawTexturedRectRotated(x+cx*w+11,y+cy*h+11,32,32,45)

						local curSize = 16
						local curWidth = 2
						local midX, midY = x+cx*w,y+cy*h

						local x1,y1,w1,h1 = cut_rect(midX - curSize, midY - curWidth, curSize * 2, curWidth * 2,x,y,w,h)
						local x2,y2,w2,h2 = cut_rect(midX - curWidth, midY - curSize, curWidth * 2, curSize * 2,x,y,w,h)
						surface.DrawRect(x1,y1,w1,h1)
						surface.DrawRect(x2,y2,w2,h2)
					end
				end
			end
		end, draw_background and nil or 0.1)
		Wire_Render(self)
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, { "X", "Y", "Use (Outputs 1 as long as any player is holding the use key while aiming at the screen.)", "OnScreen (Outputs 1 as long as any player is aiming at the screen)" })

	Wire_TriggerOutput(self, "X", 0)
	Wire_TriggerOutput(self, "Y", 0)
	Wire_TriggerOutput(self, "Use", 0)
	Wire_TriggerOutput(self, "OnScreen", 0)

	self.lastOnscreen = 0
	self.lastX = 0
	self.lastY = 0
	self.lastClick = 0
end

function ENT:Think()
	BaseClass.Think(self)
	local onScreen = 0
	local clickActive = 0

	local GPUEntity = self.GPUEntity or self
	local model = GPUEntity:GetModel()
	local monitor = WireGPU_Monitors[model]
	local ang = GPUEntity:LocalToWorldAngles(monitor.rot)
	local pos = GPUEntity:LocalToWorld(monitor.offset)
	local h = 1024
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
						if self:GetCursorMode() == GRAPH_CURSOR then
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
	BaseClass.OnRestore(self)
	Wire_AdjustOutputs(self, { "X", "Y", "Use", "OnScreen" })
end

-- only needed for legacy dupes
function ENT:Setup(gmode, draw_background)
	if gmode ~= nil then self:SetCursorMode(gmode) end
	if draw_background ~= nil then self:SetDrawBackground(draw_background) end
end

duplicator.RegisterEntityClass("gmod_wire_graphics_tablet", WireLib.MakeWireEnt, "Data", "gmode", "draw_background")
