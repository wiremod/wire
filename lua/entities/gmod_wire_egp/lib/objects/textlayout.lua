-- Author: Divran
local Obj = EGP:NewObject( "TextLayout" )
Obj.h = 512
Obj.w = 512
Obj.text = ""
Obj.font = "WireGPU_ConsoleFont"
Obj.size = 18
Obj.valign = 0
Obj.halign = 0
Obj.angle = 0

local cam_PushModelMatrix
local cam_PopModelMatrix
local mat
local matAng

if CLIENT then
	-- Thanks to Wizard for this rotateable text code
	cam_PushModelMatrix = cam.PushModelMatrix
	cam_PopModelMatrix = cam.PopModelMatrix
	mat = Matrix()
	matAng = Angle(0, 0, 0)
end

function Obj:Draw(ent, drawMat)
	if (self.text and #self.text>0) then
		surface.SetTextColor( self.r, self.g, self.b, self.a )

		local font = "WireEGP_" .. self.size .. "_" .. self.font
		if (!EGP.ValidFonts_Lookup[font]) then
			local fontTable =
			{
				font=self.font,
				size = self.size,
				weight = 800,
				antialias = true,
				additive = false
			}
			surface.CreateFont( font, fontTable )
			EGP.ValidFonts_Lookup[font] = true
		end
		surface.SetFont( font )

		--if (!self.layouter) then self.layouter = EGP:MakeTextLayouter() end -- Trying to make my own layouter...
		--self.layouter:SetText( self.text, self.x, self.y, self.w, self.h, self.halign, self.valign, (self.fontid != self.oldfontid) )
		--self.layouter:DrawText()
		--self.oldfontid = self.fontid

		if (!self.layouter) then self.layouter = MakeTextScreenLayouter() end

		if self.angle == 0 then
			self.layouter:DrawText(self.text, self.x, self.y, self.w, self.h, self.halign, self.valign)
		else
			mat:Set(drawMat)

			mat:Translate(Vector(self.x, self.y, 0))

			matAng.y = -self.angle
			mat:Rotate(matAng)

			cam_PushModelMatrix(mat)
				self.layouter:DrawText(self.text, 0, 0, self.w, self.h, self.halign, self.valign)
			cam_PopModelMatrix()
		end

		--[[
		if (!self.layouter) then
			self.layouter = EGP:TextLayouter( font )
			self.layouter:SetJustify( false )
			self.layouter:SetJustifyLast( false )
			self.layouter:SetTabWidth( 4 )
			self.layouter:SetLimitHeight( true )
			self.oldvalues = {}
		end
		if (self.oldvalues.x != self.x or
			self.oldvalues.y != self.y or
			self.oldvalues.w != self.w or
			self.oldvalues.h != self.h or
			self.oldvalues.text != self.text or
			self.oldvalues.size != self.size or
			self.oldvalues.halign != self.halign or
			self.oldvalues.valign != self.valign or
			self.oldvalues.fontid != self.fontid) then
			self.layouter:SetSize( self.w, self.h )
			self.layouter:SetPos( self.x, self.y )
			self.layouter:SetText( self.text )
			self.layouter:SetFont( font )
			self.layouter:Reset()
			self.oldvalues = table.Copy( self )
		end
		self.layouter:Draw()
		]]
	end
end
Obj.Transmit = function( self, Ent, ply )
	EGP:SendPosSize( self )
	EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", self.index, self.text )
	net.WriteString(self.font)
	net.WriteUInt(math.Clamp(self.size,0,256), 8)
	net.WriteUInt(math.Clamp(self.valign,0,2), 2)
	net.WriteUInt(math.Clamp(self.halign,0,2), 2)
	net.WriteInt( self.parent, 16 )
	EGP:SendColor( self )
	net.WriteInt((self.angle%360)*20, 16)
end
Obj.Receive = function( self )
	local tbl = {}
	EGP:ReceivePosSize( tbl )
	tbl.font = net.ReadString(8)
	tbl.size = net.ReadUInt(8)
	tbl.valign = net.ReadUInt(2)
	tbl.halign = net.ReadUInt(2)
	tbl.parent = net.ReadInt(16)
	EGP:ReceiveColor( tbl, self )
	tbl.angle = net.ReadInt(16)/20
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, w = self.w, h = self.h, valign = self.valign, halign = self.halign, size = self.size, r = self.r, g = self.g, b = self.b, a = self.a, text = self.text, font = self.font, parent = self.parent, angle = self.angle }
end
