local Obj = EGP:NewObject( "Text" )
Obj.h = nil
Obj.w = nil
Obj.text = ""
Obj.fontid = 1
Obj.size = 18
Obj.valign = 0
Obj.halign = 0
Obj.Draw = function( self )
	if (self.text and #self.text>0) then
		surface.SetTextColor( self.r, self.g, self.b, self.a )

		if (!EGP.ValidFonts[self.fontid]) then self.fontid = 1 end
		local font = "WireEGP_" .. self.size .. "_" .. self.fontid
		if (!EGP.ValidFonts_Lookup[font]) then
			surface.CreateFont( EGP.ValidFonts[self.fontid], self.size, 800, true, false, font )
			table.insert( EGP.ValidFonts, font )
			EGP.ValidFonts_Lookup[font] = true
		end
		surface.SetFont( font )

		local w,h
		local x, y = self.x, self.y
		if (self.halign != 0) then
			w,h = surface.GetTextSize( self.text )
			x = x - (w * ((self.halign%10)/2))
		end
		if (self.valign) then
			if (!h) then _,h = surface.GetTextSize( self.text ) end
			y = y - (h * ((self.valign%10)/2))
		end

		surface.SetTextPos( x, y )

		surface.DrawText( self.text )
	end
end
Obj.Transmit = function( self, Ent, ply )
	EGP.umsg.Short( self.x )
	EGP.umsg.Short( self.y )
	if (#self.text>150) then
		EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", self.index, self.text )
		EGP.umsg.String( "" )
	else
		EGP.umsg.String( self.text )
	end
	EGP.umsg.Char( self.fontid-128 )
	EGP.umsg.Char( math.Clamp(self.size,0,128)-128 )
	EGP.umsg.Char( math.Clamp(self.valign,0,2) )
	EGP.umsg.Char( math.Clamp(self.halign,0,2) )
	EGP.umsg.Short( self.parent )
	EGP:SendColor( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.x = um:ReadShort()
	tbl.y = um:ReadShort()
	tbl.text = um:ReadString()
	tbl.fontid = um:ReadChar()+128
	tbl.size = um:ReadChar()+128
	tbl.valign = um:ReadChar()
	tbl.halign = um:ReadChar()
	tbl.parent = um:ReadShort()
	EGP:ReceiveColor( tbl, self, um )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, valign = self.valign, halign = self.halign, size = self.size, r = self.r, g = self.g, b = self.b, a = self.a, text = self.text, fontid = self.fontid, parent = self.parent }
end
