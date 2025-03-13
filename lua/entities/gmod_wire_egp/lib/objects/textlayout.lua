-- Author: Divran
local Obj = E2Lib.EGP.ObjectInherit("TextLayout", "Text")
Obj.h = 512
Obj.w = 512
Obj.CanTopLeft = true

local base = Obj.BaseClass

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

		local font = EGP.CreateFont( self.font, self.size )
		surface.SetFont( font )

		--if (not self.layouter) then self.layouter = EGP:MakeTextLayouter() end -- Trying to make my own layouter...
		--self.layouter:SetText( self.text, self.x, self.y, self.w, self.h, self.halign, self.valign, (self.fontid ~= self.oldfontid) )
		--self.layouter:DrawText()
		--self.oldfontid = self.fontid

		if (not self.layouter) then self.layouter = MakeTextScreenLayouter() end

		local w, h = self.w, self.h
		local x, y = self.x - w / 2, self.y - h / 2

		if self.angle == 0 then
			self.layouter:DrawText(self.text, x, y, w, h, self.halign, self.valign)
		else
			mat:Set(drawMat)

			mat:Translate(Vector(x, y, 0))

			matAng.y = -self.angle
			mat:Rotate(matAng)

			cam_PushModelMatrix(mat, true)
				self.layouter:DrawText(self.text, 0, 0, w, h, self.halign, self.valign)
			cam_PopModelMatrix()
		end

		--[[
		if (not self.layouter) then
			self.layouter = EGP:TextLayouter( font )
			self.layouter:SetJustify( false )
			self.layouter:SetJustifyLast( false )
			self.layouter:SetTabWidth( 4 )
			self.layouter:SetLimitHeight( true )
			self.oldvalues = {}
		end
		if (self.oldvalues.x ~= self.x or
			self.oldvalues.y ~= self.y or
			self.oldvalues.w ~= self.w or
			self.oldvalues.h ~= self.h or
			self.oldvalues.text ~= self.text or
			self.oldvalues.size ~= self.size or
			self.oldvalues.halign ~= self.halign or
			self.oldvalues.valign ~= self.valign or
			self.oldvalues.fontid ~= self.fontid) then
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
	EGP.SendSize(self)
	base.Transmit(self)
end
Obj.Receive = function( self )
	local tbl = {}
	EGP.ReceiveSize(tbl)
	return table.Merge(tbl, base.Receive(self))
end
Obj.DataStreamInfo = function( self )
	return table.Merge({ w = self.w, h = self.h}, base.DataStreamInfo(self))
end
