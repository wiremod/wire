--Wire graphics tablet  by greenarrow

include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
	self.GPU = WireGPU(self, true)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	self.Entity:DrawModel()

	self.GPU:RenderToWorld(nil, 512, function(x, y, w, h, monitor, pos, ang, res)
		if self:GetNetworkedBeamBool("draw_background", true) then
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
					surface.DrawRect(midX - curSize, midY - curWidth, curSize * 2, curWidth * 2)
					surface.DrawRect(midX - curWidth, midY - curSize, curWidth * 2, curSize * 2)
				end
			end
		end
	end)
	Wire_Render(self.Entity)
end
