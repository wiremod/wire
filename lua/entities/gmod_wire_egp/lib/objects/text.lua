-- Author: Divran
local Obj = E2Lib.EGP.NewObject("Text")
Obj.material = nil
Obj.text = ""
Obj.font = "WireGPU_ConsoleFont"
Obj.size = 18
Obj.valign = 0
Obj.halign = 0

local surface_SetTextPos
local surface_DrawText
local surface_SetTextColor
local surface_SetFont
local surface_GetTextSize
local cam_PushModelMatrix
local cam_PopModelMatrix
local mat
local matAng

if CLIENT then
	surface_SetTextPos = surface.SetTextPos
	surface_DrawText = surface.DrawText
	surface_SetTextColor = surface.SetTextColor
	surface_CreateFont = surface.CreateFont
	surface_SetFont = surface.SetFont
	surface_GetTextSize = surface.GetTextSize


	-- Thanks to Wizard for this rotateable text code
	cam_PushModelMatrix = cam.PushModelMatrix
	cam_PopModelMatrix = cam.PopModelMatrix
	mat = Matrix()
	matAng = Angle(0, 0, 0)
end

function Obj:Draw(ent, drawMat)
	if (self.text and #self.text>0) then
		surface_SetTextColor( self.r, self.g, self.b, self.a )

		local font = EGP.CreateFont( self.font, self.size )
		surface_SetFont( font )

		if self.angle == 0 then
			local w,h
			local x, y = self.x, self.y
			if (self.halign ~= 0) then
				w,h = surface_GetTextSize( self.text )
				x = x - (w * ((self.halign%10)/2))
			end
			if (self.valign) then
				if (not h) then _,h = surface_GetTextSize( self.text ) end
				y = y - (h * ((self.valign%10)/2))
			end

			surface_SetTextPos( x, y )
			surface_DrawText( self.text )
		else
			local w,h
			local x, y = 0,0
			if (self.halign ~= 0) then
				w,h = surface_GetTextSize( self.text )
				x = (w * ((self.halign%10)/2))
			end
			if (self.valign) then
				if (not h) then _,h = surface_GetTextSize( self.text ) end
				y = (h * ((self.valign%10)/2))
			end

			mat:Set(drawMat)

			mat:Translate(Vector(self.x, self.y, 0))

			matAng.y = -self.angle
			mat:Rotate(matAng)

			surface_SetTextPos(-x, -y)
			cam_PushModelMatrix(mat, true)
				local clip = DisableClipping( true )
				surface_DrawText( self.text )
				DisableClipping( clip )
			cam_PopModelMatrix()
		end
	end
end
Obj.Transmit = function( self, Ent, ply )
	EGP.SendPosAng(self)
	local len = #self.text
	if len <= 1024 then
		net.WriteUInt(len + 1, 11)
		net.WriteData(self.text, len)
	else
		net.WriteUInt(0, 11)
		EGP:InsertQueue(Ent, ply, EGP._SetText, "SetText", self.index, self.text)
	end
	net.WriteString(self.font)
	net.WriteUInt(math.Clamp(self.size, 0, 255), 8)
	net.WriteUInt(math.Clamp(self.valign,0,2), 2)
	net.WriteUInt(math.Clamp(self.halign,0,2), 2)
	net.WriteInt(self.parent, 16)
	EGP:SendColor(self)
end
Obj.Receive = function( self )
	local tbl = {}
	EGP.ReceivePosAng(tbl)
	local len = net.ReadUInt(11)
	if len > 0 then
		tbl.text = net.ReadData(len - 1)
	end
	tbl.font = net.ReadString()
	tbl.size = net.ReadUInt(8)
	tbl.valign = net.ReadUInt(2)
	tbl.halign = net.ReadUInt(2)
	tbl.parent = net.ReadInt(16)
	EGP:ReceiveColor( tbl, self )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, angle = self.angle, valign = self.valign, halign = self.halign, size = self.size, r = self.r, g = self.g, b = self.b, a = self.a, text = self.text, font = self.font, parent = self.parent }
end
