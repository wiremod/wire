--Wire graphics tablet  by greenarrow

include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
	self.GPU = WireGPU(self, true)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:DrawEntityOutline()
	if (GetConVar("wire_graphics_tablet_drawoutline"):GetBool()) then
		self.BaseClass.DrawEntityOutline( self )
	end
end

local function cut_rect(x1,y1,w1,h1,x2,y2,w2,h2)
	local x,y = x1>x2 and x1 or x2, y1>y2 and y1 or y2
	local right1,bottom1,right2,bottom2 = x1+w1,y1+h1, x2+w2,y2+h2
	local w,h = (right1<right2 and right1 or right2)-x, (bottom1<bottom2 and bottom1 or bottom2)-y
	return x,y,w,h
end

function ENT:Draw()
	self:DrawModel()

	local draw_background = self:GetNetworkedBeamBool("draw_background", true)
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
