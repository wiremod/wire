-- Author: Divran
local Obj = EGP:NewObject( "TextLayout" )
Obj.h = 512
Obj.w = 512
Obj.text = ""
Obj.fontid = 1
Obj.size = 18
Obj.valign = 0
Obj.halign = 0
Obj.angle = 0

if CLIENT then
	-- Thanks to Wizard for this rotateable text code
	cam_PushModelMatrix = cam.PushModelMatrix
	cam_PopModelMatrix = cam.PopModelMatrix
	mat = Matrix()
	mat:Scale(Vector(1, 1, 1))
	matAng = Angle(0, 0, 0)
	matTrans = Vector(0, 0, 0)
end

Obj.Draw = function( self )
	if (self.text and #self.text>0) then
		surface.SetTextColor( self.r, self.g, self.b, self.a )

		if (!EGP.ValidFonts[self.fontid]) then self.fontid = 1 end
		local font = "WireEGP_" .. self.size .. "_" .. self.fontid
		if (!EGP.ValidFonts_Lookup[font]) then
			local fontTable =
			{
				font=EGP.ValidFonts[self.fontid],
				size = self.size,
				weight = 800,
				antialias = true,
				additive = false
			}
			surface.CreateFont( font, fontTable )
			table.insert( EGP.ValidFonts, font )
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
			matAng.y = -self.angle
			mat:SetAngles(matAng)
			matTrans.x = x
			matTrans.y = y
			matTrans:Rotate(matAng)
			mat:SetTranslation(Vector(self.x,self.y,0)-matTrans)
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
	net.WriteUInt(self.fontid, 8)
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
	tbl.fontid = net.ReadUInt(8)
	tbl.size = net.ReadUInt(8)
	tbl.valign = net.ReadUInt(2)
	tbl.halign = net.ReadUInt(2)
	tbl.parent = net.ReadInt(16)
	EGP:ReceiveColor( tbl, self )
	tbl.angle = net.ReadInt(16)/20
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, w = self.w, h = self.h, valign = self.valign, halign = self.halign, size = self.size, r = self.r, g = self.g, b = self.b, a = self.a, text = self.text, fontid = self.fontid, parent = self.parent, angle = self.angle }
end
