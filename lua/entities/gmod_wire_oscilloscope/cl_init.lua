include('shared.lua')

ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:Initialize()
	self.RTTexture = WireGPU_NeedRenderTarget(self:EntIndex())
end

function ENT:OnRemove()
	WireGPU_ReturnRenderTarget(self:EntIndex())
end

function ENT:Draw()
	self.Entity:DrawModel()

	self.RTTexture = WireGPU_GetMyRenderTarget(self:EntIndex())

	local NewRT = self.RTTexture
	local OldRT = render.GetRenderTarget()

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture",self.RTTexture)

	if (true) then
		local oldw = ScrW()
		local oldh = ScrH()

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0,0,512,512)
		cam.Start2D()
			surface.SetDrawColor(10,20,5,255)
			surface.DrawRect(0,0,512,512)

			local nodes = self:GetNodeList()
			for i=1,39 do
				local i_next = i+1

				local nx1 = nodes[i].X*256+256
				local ny1 = -nodes[i].Y*256+256
				local nx2 = nodes[i_next].X*256+256
				local ny2 = -nodes[i_next].Y*256+256

				if ((nx1-nx2)*(nx1-nx2) + (ny1-ny2)*(ny1-ny2) < 256*256) then
					local b = math.max(0, math.min(i*i*0.16, 255))


					for i=-3,3 do
						surface.SetDrawColor(b/8, b/2, b/8, 255)
						surface.DrawLine(nx1, ny1+i, nx2, ny2+i)
						surface.SetDrawColor(b/8, b/2, b/8, 255)
						surface.DrawLine(nx1+i, ny1, nx2+i, ny2)
					end

					surface.SetDrawColor(b/4, b, b/4, 255)
					surface.DrawLine(nx1, ny1, nx2, ny2)
				end
			end

			surface.SetDrawColor(30, 120, 10, 255)
			surface.DrawLine(0, 128, 512, 128)
			surface.DrawLine(0, 384, 512, 384)
			surface.DrawLine(128, 0, 128, 512)
			surface.DrawLine(384, 0, 384, 512)

			surface.SetDrawColor(180, 200, 10, 255)
			surface.DrawLine(0, 256, 512, 256)
			surface.DrawLine(256, 0, 256, 512)
		cam.End2D()
		render.SetViewPort(0,0,oldw,oldh)
		render.SetRenderTarget(OldRT)
	end


	local model = self.Entity:GetModel()
	local OF, OU, OR, Res, RatioX, Rot90
	if (WireGPU_Monitors[model]) && (WireGPU_Monitors[model].OF) then
		OF = WireGPU_Monitors[model].OF
		OU = WireGPU_Monitors[model].OU
		OR = WireGPU_Monitors[model].OR
		Res = WireGPU_Monitors[model].RS
		RatioX = WireGPU_Monitors[model].RatioX
		Rot90 = WireGPU_Monitors[model].rot90
	else
		OF = 0
		OU = 0
		OR = 0
		Res = 1
		RatioX = 1
	end

	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	if Rot90 then
		rot = Angle(0,90,0)
	end

	ang:RotateAroundAxis(ang:Right(),   rot.x)
	ang:RotateAroundAxis(ang:Up(),      rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)

	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)

	cam.Start3D2D(pos,ang,Res)
		local w = 512
		local h = 512
		local x = -w/2
		local y = -h/2

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-256,-256,512/RatioX,512)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(WireGPU_texScreen)
		WireGPU_DrawScreen(x,y,w/RatioX,h,0,0)
	cam.End3D2D()

	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
