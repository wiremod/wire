--Wire graphics tablet  by greenarrow

include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.paramSetup = false

function ENT:Initialize()
	self:SetupParams()
	self.allowDraw = true

	self.GPU = WireGPU(self, true)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	if !self.allowDraw then return true end

	if !self.paramsSetup then
		self:SetupParams()
	end

	self.Entity:DrawModel()

	self.GPU:RenderToWorld(nil, 512, function(x, y, w, h, monitor, pos, ang)
		-- only draw the background when not drawing on another GPU
		if self.GPU.Entity == self or not self.GPU.Entity.GPU then
			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(x,y,w,h)
		end

		local ply = LocalPlayer()
		local trace = ply:GetEyeTraceNoCursor()
		if trace.Entity:IsValid() then
			local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
			dist = math.max(dist, trace.Fraction*16384-trace.Entity:BoundingRadius())
			WireLib.hud_debug(""..dist, true)

			if dist < self.workingDistance and trace.Entity == self.GPU.Entity then
				local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)

				local cx = 0.5+cpos.x/(monitor.RS*w)
				local cy = 0.5-cpos.y/(monitor.RS*h)

				if cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
					surface.SetDrawColor(255, 255, 255, 255)
					--surface.SetTexture(surface.GetTextureID("gui/arrow"))
					--surface.DrawTexturedRectRotated(x+cx*w+11,y+cy*w+11,32,32,45)

					local curSize = 16
					local curWidth = 2
					local midX, midY = x+cx*w,y+cy*h
					surface.DrawRect(midX - curSize, midY - curWidth, curSize * 2, curWidth * 2)
					surface.DrawRect(midX - curWidth, midY - curSize, curWidth * 2, curSize * 2)
				end
			end
		end
	end)
	Wire_Render(self.Entity)
end
