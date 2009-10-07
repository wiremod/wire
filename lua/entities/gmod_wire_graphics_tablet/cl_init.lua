--Wire graphics tablet  by greenarrow

include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.paramSetup = false

function ENT:Initialize()
	self:SetupParams()
	self.allowDraw = true
end

function ENT:Draw()
	if !self.allowDraw then return true end

	if !self.paramsSetup then
		self:SetupParams()
	end

	self.Entity:DrawModel()
	--begin adapted nighteagle code (amazing work with vectors!!!):  --Nighteagles has put a lot of work into refining the use of cam3d2d and traces to create cursor screen systems.
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), rot.x)
	ang:RotateAroundAxis(ang:Up(), rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * self.z)

	cam.Start3D2D(pos, ang, self.res)
		local trace = {}
			trace.start = LocalPlayer():GetShootPos()
			trace.endpos = (LocalPlayer():GetAimVector() * self.workingDistance) + trace.start
			trace.filter = LocalPlayer()
		local trace = util.TraceLine(trace)

		if (trace.Entity == self.Entity) then
			local pos = self.Entity:WorldToLocal(trace.HitPos)
			local cx = (self.x1 - pos.y) / (self.x1 - self.x2)
			local cy = (self.y1 - pos.z) / (self.y1 - self.y2)

			--surface.SetDrawColor(0,0,255,255)
			--surface.DrawRect(self.x ,self.y, self.w, self.h)

			if (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
				surface.SetDrawColor (255, 255, 255, 255)
				--surface.SetTexture (surface.GetTextureID ("gui/arrow"))
				--surface.DrawTexturedRectRotated (self.x + (self.w * cx) + self.ox, self.y + (self.h * cy) + self.oy, 16, 16, 45)
				local curSize = 16
				local curWidth = 2
				local midX = self.x + (self.w * cx)
				local midY = self.y + (self.h * cy)
				surface.DrawRect (midX - curSize, midY - curWidth, curSize * 2, curWidth * 2)
				surface.DrawRect (midX - curWidth, midY - curSize, curWidth * 2, curSize * 2)
			end
		end
	cam.End3D2D()
	--end adapted nighteagle code
	Wire_Render(self.Entity)
end
