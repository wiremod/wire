
include('shared.lua')
CreateClientConVar( "wire_panel_chan", 1, true, true )  --client variable to server goodness

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
	self.menu = nil
	self.click = 0
	self.chan = 1
	self.disp1 = 0

	//Edit the menu here. Maximum of 10 lines.
	self.menus = {"","", //Do not use these. The menus start at 3.
	"Ch. 1|Channel 1",
	"Ch. 2|Channel 2",
	"Ch. 3|Channel 3",
	"Ch. 4|Channel 4",
	"Ch. 5|Channel 5",
	"Ch. 6|Channel 6",
	"Ch. 7|Channel 7",
	"Ch. 8|Channel 8"
	}

	surface.CreateFont( "coolvetica", 80, 400, false, false, "panel_font" )

end

function ENT:Draw()
	self.Entity:DrawModel()

	local OF = 0
	local OU = 0
	local OR = 0
	local Res = 0.1
	local RatioX = 1

	if self.Entity:GetModel() == "models/props_lab/monitor01b.mdl" then
		OF = 6.53
		OU = 0
		OR = 0
		Res = 0.05
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorsmall.mdl" then
		OF = 0.2
		OU = 4.5
		OR = -0.85
		Res = 0.045
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorbig.mdl" then
		OF = 0.3
		OU = 11.8
		OR = -2.35
		Res = 0.12
	elseif self.Entity:GetModel() == "models/props/cs_office/computer_monitor.mdl" then
		OF = 3.25
		OU = 15.85
		OR = -2.2
		Res = 0.085
		RatioX = 0.75
	elseif self.Entity:GetModel() == "models/props/cs_office/TV_plasma.mdl" then
		OF = 6.1
		OU = 17.05
		OR = -5.99
		Res = 0.175
		RatioX = 0.57
	end

	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)

	local pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)

	cam.Start3D2D(pos,ang,Res)
		local clicker = LocalPlayer():GetNetworkedInt(self.Entity:EntIndex().."click")
		local click = false
		if clicker >= 8 and self.click ~= 0 then
			self.click = 0
			click = true
		elseif clicker < 8 then
			if clicker > self.click then
				self.click = clicker
				click = true
			end
		end

		local x = -112
		local y = -104
		local w = 296
		local h = 292

		local x1 = -5.535
		local x2 = 3.5
		local y1 = 5.091
		local y2 = -4.1

		local ox = 5
		local oy = 5

		local pos
		local cx
		local cy
		local onscreen = false

		local trace = {}
			trace.start = LocalPlayer():GetShootPos()
			trace.endpos = LocalPlayer():GetAimVector() * 64 + trace.start
			trace.filter = LocalPlayer()
		local trace = util.TraceLine(trace)

		local control = LocalPlayer():GetNetworkedBool(self.Entity:EntIndex().."control")
		if control then
			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

			pos = self.Entity:WorldToLocal(trace.HitPos)
--			pos = self.Entity:GetPos() + (self.Entity:GetForward() * OF) + (self.Entity:GetUp() * OU) + (self.Entity:GetRight() * OR)
			local posfix_x
			local posfix_y
			if (OR == 0) then
				posfix_x = 1
			else
				posfix_x = math.abs(OR)
			end
			if (OU == 0) then
				posfix_y = 1
			else
				posfix_y = math.abs(OU)
			end
--			cx = (pos.y - x1) / (math.abs(x1) + math.abs(x2))
			cx = (((pos.y + OR)/math.abs(posfix_x)) - x1) / (math.abs(x1) + math.abs(x2))
--			cy = 1 - ((pos.z + y1) / (math.abs(y1) + math.abs(y2)))
--			cy = 1 - (((pos.z + (OU / 2)) + (y1 - OU)) / (math.abs(y1 - OU) + math.abs(y2 - OU)))
			cy = 1 - (((pos.z - OU) + y1)) / (math.abs(y1) + math.abs(y2))
			if trace.Entity == self.Entity and cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
				onscreen = true
			end
		else
			self.menu = nil

			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(x/RatioX,y,(x+w)/RatioX,y+h)

			surface.SetDrawColor(255,255,255,255)
			surface.SetTexture(surface.GetTextureID("gui/info"))
			surface.DrawTexturedRect((x+(w*.4*.621))/RatioX,y + h*.4*.621,w*.2*.621,w*.2*.621)
		end


		if control then
			surface.SetDrawColor(100,100,100,255)
			surface.DrawRect((x+(w*0*.621))/RatioX,y+(h*0*.621),w*.3*.621,h*1*.621)
			if self.menu then
				if ((self.menu-2) == self.chan) then
					surface.SetDrawColor(0,100,0,255)
				else
					surface.SetDrawColor(100,0,0,255)
				end
				surface.DrawRect((x+(w*.3*.621))/RatioX,y+(h*.5*.621),w*.7*.621,h*.5*.621)
				draw.DrawText("SET","panel_font",(x+(w*.32*.621))/RatioX,(y+(h*.55*.621)),Color(255,255,255,255),0)
			end
		end
		if control and onscreen then
			if (math.abs(pos.x - OF) < 1.0) then
				if cx <= .3 then
					for i = 3,10 do
						if cy >= .1*i-.1 and cy < .1*i then
							surface.SetDrawColor(30,144,255,100)
							surface.DrawRect((x+(w*0*.621))/RatioX,y+(h*(.1*i-.1)*.621),w*.3*.621,h*.1*.621)
							if click then
								self.menu = i
							end
						end
					end
				else
					if cy >= 0.5 then
						if self.menu then
							if ((self.menu-2) == self.chan) then
								surface.SetDrawColor(0,150,0,255)
							else
								surface.SetDrawColor(150,0,0,255)
							end
							surface.DrawRect((x+(w*.3*.621))/RatioX,y+(h*.5*.621),w*.7*.621,h*.5*.621)
							draw.DrawText("SET","panel_font",(x+(w*.32*.621))/RatioX,(y+(h*.55*.621)),Color(255,255,255,255),0)
							if click then
								self.chan = self.menu-2
								LocalPlayer():ConCommand("wire_panel_chan "..self.chan.."\n")
							end
						end
					end
				end
			end
		end
		if control then
			local out = "Channel\nIndex\n"
			for i = 3, 10 do
				local disp = self.menus[i]
				local loc = string.find(disp,"|", 1, true)
				if loc then
					out = out..string.sub(disp,1,loc-1).."\n"
				else
					out = out.."\n"
				end
			end
			draw.DrawText(out,"Trebuchet18",(x+2)/RatioX,y,Color(255,255,255,255))
			if self.menu then
				local ChannelValue = self:GetChannelValue( self.menu-2 )
				local disp = self.menus[self.menu].."\n\n"..string.format("%.2f", ChannelValue)
				local loc = string.find(disp,"|", 1, true)
				if loc then
					local disp = string.sub(disp,loc+1)
					draw.DrawText(disp,"Trebuchet18",(x+2+(w*.3*.621))/RatioX,y,Color(255,255,255,255))
				end
			end
		end
		if control and onscreen then
			if (math.abs(pos.x - OF) < 1.0) then
				surface.SetDrawColor(255,255,255,255)
				surface.SetTexture(surface.GetTextureID("gui/arrow"))
				surface.DrawTexturedRectRotated((x+(w*cx*.621)+ox)/RatioX,y+(h*cy*.621)+oy,16,16,45)
			end
		else
		end


	cam.End3D2D()

	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
