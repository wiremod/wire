include('shared.lua')
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:Initialize()
	self.menu = nil
	self.chan = 1
	self.disp1 = 0

	local font = "panel_font"
	local fontTable =
	{
		font="Coolvetica",
		size = 80,
		weight = 400,
		antialias = false,
		additive = false
	}
	surface.CreateFont( font, fontTable )

	self.GPU = WireGPU(self, true)
	self.workingDistance = 64

	self:InitializeShared()
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Think()
	local ply = LocalPlayer()
	if ply:KeyDown(IN_USE) and not ply:KeyDownLast(IN_USE) and ply:GetEyeTraceNoCursor().Entity == self.GPU.Entity then self:Use() end
end

function ENT:Use()
	if self.lasthovermenu then
		self.menu = self.lasthovermenu
	end
	if self.lasthoverchan then
		self:ChangeChannelNumber(self.lasthoverchan)
	end
end

function ENT:Draw()
	self:DrawModel()

	self.GPU:RenderToWorld(nil, 184, function(x, y, w, h, monitor, pos, ang, res)
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(x,y,w,h)
		local ply = LocalPlayer()
		local trace = ply:GetEyeTraceNoCursor()
		local ent = trace.Entity
		local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
		dist = math.max(dist, trace.Fraction*16384-self.GPU.Entity:BoundingRadius())

		local onscreen = false

		if dist < self.workingDistance and ent == self.GPU.Entity then
			local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)

			local cx = 0.5+cpos.x/(res*w)
			local cy = 0.5-cpos.y/(res*h)

			if cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
				onscreen = true
			end

			local cxp, cyp = x+cx*w, y+cy*h

			if self.menu then
				-- "SET" button
				local onbutton = onscreen and cxp>=x+50 and cy>=0.5
				self.lasthoverchan = onbutton and self.menu or nil
				local intensity = onbutton and 150 or 100

				if self.menu == self.chan then
					surface.SetDrawColor(0,intensity,0,255)
				else
					surface.SetDrawColor(intensity,0,0,255)
				end
				surface.DrawRect(x+50,y+h/2,w-50,h/2)

				surface.SetFont("panel_font")
				surface.SetTextColor(Color(255,255,255,255))

				local textw, texth = surface.GetTextSize("SET")
				surface.SetTextPos(x+25+w/2-textw/2, y+h*3/4-texth/2)

				surface.DrawText("SET")
			end

			-- selection bar on the left
			surface.SetDrawColor(100,100,100,255)
			surface.DrawRect(x, y, 50, h)

			do
				local onbar = cxp >= x and cxp < x+50
				-- menu text
				surface.SetFont("Trebuchet18")
				surface.SetTextColor(Color(255,255,255,255))
				local yp = y
				self.lasthovermenu = nil
				for i = -1,8 do
					local disp = self.menus[i][1]
					local textw, texth = surface.GetTextSize(disp)

					if self.menus[i][2] then
						if onbar and cyp >= yp and cyp < yp+texth then
							surface.SetDrawColor(80,120,180,255)
							surface.DrawRect(x,yp,50,texth)
							self.lasthovermenu = i
						elseif self.chan == i then
							surface.SetDrawColor(60,160,60,255)
							surface.DrawRect(x,yp,50,texth)
						elseif self.menu == i then
							surface.SetDrawColor(48,48,48,255)
							surface.DrawRect(x,yp,50,texth)
						end
					end
					surface.SetTextPos(x+2, yp)
					surface.DrawText(disp)

					yp = yp+texth
				end
			end
			--draw.DrawText(out,"Trebuchet18",x+2,y,Color(255,255,255,255))
			if self.menu then
				local ChannelValue = self:GetChannelValue( self.menu )
				local disp = self.menus[self.menu][2].."\n\n"..string.format("%.2f", ChannelValue)
				draw.DrawText(disp,"Trebuchet18",x+54,y,Color(255,255,255,255))
			end
			if onscreen then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetTexture(surface.GetTextureID("gui/arrow"))
				surface.DrawTexturedRectRotated(x+cx*w+11,y+cy*h+11,32,32,45)
			end
		else
			surface.SetDrawColor(255,255,255,255)
			surface.SetTexture(surface.GetTextureID("gui/info"))

			local infow, infoh = h*0.2,h*0.2
			surface.DrawTexturedRect(x+(w-infow)/2, y+(h-infoh)/2, infow, infoh)
		end
	end)

	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end
