AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Colorer"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Colorer"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then

	local color_box_size = 64
	function ENT:GetWorldTipBodySize()
		-- "Input color:" text
		local w_total,h_total = surface.GetTextSize( "Input color:\n255,255,255,255" )

		-- Color box width
		w_total = math.max(w_total,color_box_size)

		-- "Target color:" text
		local w,h = surface.GetTextSize( "Target color:\n255,255,255,255" )
		w_total = w_total + 18 + math.max(w,color_box_size)
		h_total = math.max(h_total, h)

		-- Color box height
		h_total = h_total + 18 + color_box_size + 18/2

		return w_total, h_total
	end

	local white = Color(255,255,255,255)
	local black = Color(0,0,0,255)

	local function drawColorBox( color, x, y )
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.DrawRect( x, y, color_box_size, color_box_size )

		local size = color_box_size

		surface.SetDrawColor(0, 0, 0)
		surface.DrawLine( x, 		y, 			x + size, 	y )
		surface.DrawLine( x + size, y, 			x + size, 	y + size )
		surface.DrawLine( x + size, y + size, 	x, 			y + size )
		surface.DrawLine( x, 		y + size, 	x, 			y )
	end

	function ENT:DrawWorldTipBody( pos )
		-- get colors
		local data = self:GetOverlayData()
		local inColor = istable(data) and Color(data.r or 255,data.g or 255,data.b or 255,data.a or 255) or Color(255, 255, 255)

		local trace = util.TraceLine( { start = self:GetPos(), endpos = self:GetPos() + self:GetUp() * self:GetBeamLength(), filter = {self} } )

		local targetColor = Color(255,255,255,255)
		if IsValid( trace.Entity ) then
			targetColor = trace.Entity:GetColor()
		end

		-- "Input color" text
		local color_text = string.format("Input color:\n%d,%d,%d,%d",inColor.r,inColor.g,inColor.b,inColor.a)

		local w,h = surface.GetTextSize( color_text )
		draw.DrawText( color_text, "GModWorldtip", pos.min.x + pos.edgesize + w/2, pos.min.y + pos.edgesize, white, TEXT_ALIGN_CENTER )

		-- "Target color" text
		local color_text = string.format("Target color:\n%d,%d,%d,%d",targetColor.r,targetColor.g,targetColor.b,targetColor.a)
		local w2,h2 = surface.GetTextSize( color_text )
		draw.DrawText( color_text, "GModWorldtip", pos.max.x - w/2 - pos.edgesize, pos.min.y + pos.edgesize, white, TEXT_ALIGN_CENTER )

		local h = math.max(h,h2)

		-- Input color box
		local x = pos.min.x + pos.edgesize + w/2 - color_box_size/2
		local y = pos.min.y + pos.edgesize * 1.5 + h
		drawColorBox( inColor, x, y )

		-- Target color box

		local x = pos.max.x - pos.edgesize - w/2 - color_box_size/2
		local y = pos.min.y + pos.edgesize * 1.5 + h
		drawColorBox( targetColor, x, y )

	end


	return -- No more client
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "Fire", "R", "G", "B", "A", "RGB" }, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR"})
	self.Outputs = WireLib.CreateOutputs( self, {"Out"} )
	self.InColor = Color(255, 255, 255, 255)
	self:SetBeamLength(2048)
	self:ShowOutput()
end

function ENT:Setup(outColor,Range)
	if(outColor)then
		self.outColor = outColor
		WireLib.AdjustOutputs(self, {"R","G","B","A"})
	else
		WireLib.AdjustOutputs(self, {"Out"})
	end

	if Range then self:SetBeamLength(Range) end
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if iname == "Fire" and value ~= 0 then
		local vStart = self:GetPos()
		local vForward = self:GetUp()

		local trace = util.TraceLine {
			start = vStart,
			endpos = vStart + (vForward * self:GetBeamLength()),
			filter = { self }
		}
		if not IsValid(trace.Entity) then return end
		if not WireLib.CanTool(self:GetPlayer(), trace.Entity, "colour") then return end

		if trace.Entity:IsPlayer() then
			trace.Entity:SetColor(Color(self.InColor.r, self.InColor.g, self.InColor.b, 255))
		else
			WireLib.SetColor(trace.Entity, Color(self.InColor.r, self.InColor.g, self.InColor.b, self.InColor.a))
		end
	elseif iname == "R" then
		self.InColor.r = math.Clamp(value, 0, 255)
		self:ShowOutput()
	elseif iname == "G" then
		self.InColor.g = math.Clamp(value, 0, 255)
		self:ShowOutput()
	elseif iname == "B" then
		self.InColor.b = math.Clamp(value, 0, 255)
		self:ShowOutput()
	elseif iname == "A" then
		self.InColor.a = math.Clamp(value, 0, 255)
		self:ShowOutput()
	elseif iname == "RGB" then
		self.InColor = Color( value.x, value.y, value.z, self.InColor.a )
		self:ShowOutput()
	end
end

function ENT:ShowOutput()
	self:SetOverlayData( {	r = self.InColor.r,
							g = self.InColor.g,
							b = self.InColor.b,
							a = self.InColor.a } )
end

function ENT:Think()
	BaseClass.Think(self)
	if self.outColor then
		local vStart = self:GetPos()
		local vForward = self:GetUp()

		local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamLength())
			trace.filter = { self }
		local trace = util.TraceLine( trace )

		if not IsValid( trace.Entity ) then
			WireLib.TriggerOutput( self, "R", 255 )
			WireLib.TriggerOutput( self, "G", 255 )
			WireLib.TriggerOutput( self, "B", 255 )
			WireLib.TriggerOutput( self, "A", 255 )
		else
			local c = trace.Entity:GetColor()
			WireLib.TriggerOutput( self, "R", c.r )
			WireLib.TriggerOutput( self, "G", c.g )
			WireLib.TriggerOutput( self, "B", c.b )
			WireLib.TriggerOutput( self, "A", c.a )
		end
	end
	self:NextThink(CurTime() + 0.1)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_colorer", WireLib.MakeWireEnt, "Data", "outColor", "Range")
