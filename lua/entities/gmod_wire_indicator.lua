AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Indicator"
ENT.WireDebugName	= "Indicator"
ENT.RenderGroup = RENDERGROUP_BOTH

-- Helper functions
function ENT:GetFactorFromValue( value )
	return math.Clamp((value-self.a)/(self.b-self.a), 0, 1)
end

function ENT:GetColorFromValue( value )
	local factor = self:GetFactorFromValue( value, self )
	local r = math.Clamp((self.br-self.ar)*factor+self.ar, 0, 255)
	local g = math.Clamp((self.bg-self.ag)*factor+self.ag, 0, 255)
	local b = math.Clamp((self.bb-self.ab)*factor+self.ab, 0, 255)
	local a = math.Clamp((self.ba-self.aa)*factor+self.aa, 0, 255)
	return Color(r,g,b,a), factor
end

if CLIENT then
	local color_box_size = 64
	function ENT:GetWorldTipBodySize()
		return 400,80
	end

	local function drawSquare( x,y,w,h )
		surface.SetDrawColor(0, 0, 0)
		surface.DrawLine( x, 	 y, 	x + w, 	y )
		surface.DrawLine( x + w, y, 	x + w, 	y + h )
		surface.DrawLine( x + w, y + h, x, 		y + h )
		surface.DrawLine( x, 	 y + h, x, 		y )
	end

	local function drawColorSlider( x, y, w, h, self )
		if self.a == self.b then -- no infinite loops!
			draw.DrawText( "Can't draw color bar because A == B",
							"GModWorldtip", x + w / 2, y + h / 2, color_white, TEXT_ALIGN_CENTER )

			return
		end

		local diff = self.b - self.a
		local len = math.abs(self.b) - math.abs(self.a)
		local step = diff / 50

		local find_selected = nil

		for i=self.a,self.b - step/2, step do
			local color, factor = self:GetColorFromValue( i )
			local pos_x = math.floor(x + (factor * w))

			-- we're not stepping over every single possible value here,
			-- so we have to check if we're close-ish to the user's selected value
			if not find_selected then
				if diff >= 0 and i >= self.value then
					find_selected = i
				elseif diff < 0 and i < self.value then
					find_selected = i
				end
			end

			surface.SetDrawColor(color.r, color.g, color.b, color.a)
			surface.DrawRect( pos_x, y, math.ceil(w/50), h )
		end

		-- if the user has set the value to this exactly, then
		-- there's a possibility that the above check couldn't detect it
		if self.value == self.b then find_selected = self.b end

		-- draw the outline of the color slider
		drawSquare( x,y,w,h )

		-- draw the small box showing the current selected color
		if find_selected then
			find_selected = math.Clamp(find_selected,math.min(self.a,self.b)+step/2,math.max(self.a,self.b)-step/2)
			local factor = self:GetFactorFromValue( find_selected )
			local pos_x = math.floor(x + (factor * w))
			drawSquare(pos_x - step / 2,y-h*0.15,math.ceil(w/50),h*1.4)
		end
	end

	function ENT:DrawWorldTipBody( pos )
		-- Get colors
		local data = self:GetOverlayData()

		if istable(data) then
			-- Merge the data onto the entity itself.
			-- This allows us to use the same references as serverside
			for k, v in pairs(data) do self[k] = v end
		else
			-- Set the data to default to draw the body anyway
			self.a = 0
			self.ar = 0
			self.ag = 0
			self.ab = 0
			self.aa = 0
			self.b = 0
			self.br = 0
			self.bg = 0
			self.bb = 0
			self.ba = 0
			self.value = 0
		end

		-- A
		local color_text = string.format("A color: %d,%d,%d,%d\nA value: %d",self.ar,self.ag,self.ab,self.aa,self.a)
		draw.DrawText( color_text, "GModWorldtip", pos.min.x + pos.edgesize, pos.min.y + pos.edgesize, color_white, TEXT_ALIGN_LEFT )

		-- B
		local color_text = string.format("B color: %d,%d,%d,%d\nB value: %d",self.br,self.bg,self.bb,self.ba,self.b)
		draw.DrawText( color_text, "GModWorldtip", pos.max.x - pos.edgesize, pos.min.y + pos.edgesize, color_white, TEXT_ALIGN_RIGHT )

		-- Percent
		local factor = math.Clamp((self.value-self.a)/(self.b-self.a), 0, 1)
		local color_text = string.format("%s (%d%%)",math.Round(self.value,2),factor*100)
		local w,h = surface.GetTextSize(color_text)
		draw.DrawText( color_text, "GModWorldtip", pos.center.x + 40, pos.min.y + pos.edgesize + h, color_white, TEXT_ALIGN_RIGHT )

		-- Slider
		drawColorSlider( pos.min.x + pos.edgesize, pos.min.y + pos.edgesize + 46, 401, 16, self )
	end

	return
end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Preferably we would switch to storing these as colors,
	-- but it's not really worth breaking all old dupes
	self.a = 0
	self.ar = 0
	self.ag = 0
	self.ab = 0
	self.aa = 0
	self.b = 0
	self.br = 0
	self.bg = 0
	self.bb = 0
	self.ba = 0

	self.Inputs = WireLib.CreateInputs(self, { "A" })
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	self.a = a or 0
	self.ar = ar or 255
	self.ag = ag or 0
	self.ab = ab or 0
	self.aa = aa or 255
	self.b = b or 1
	self.br = br or 0
	self.bg = bg or 255
	self.bb = bb or 0
	self.ba = ba or 255

	self:TriggerInput("A", self.a)
end

function ENT:TriggerInput(iname, value)
	if iname == "A" then
		self:ShowOutput(value)
		local color = self:GetColorFromValue( value )
		self:SetColor(color)
	end
end

function ENT:ShowOutput(value)
	self:SetOverlayData({
		a = self.a,
		b = self.b,
		ar = self.ar,
		ag = self.ag,
		ab = self.ab,
		aa = self.aa,
		br = self.br,
		bg = self.bg,
		bb = self.bb,
		ba = self.ba,
		value = value
	})
end

duplicator.RegisterEntityClass("gmod_wire_indicator", WireLib.MakeWireEnt, "Data", "a", "ar", "ag", "ab", "aa", "b", "br", "bg", "bb", "ba")

function MakeWire7Seg( pl, Pos, Ang, Model, a, ar, ag, ab, aa, b, br, bg, bb, ba)
	if IsValid(pl) and not pl:CheckLimit( "wire_indicators" ) then return false end

	local function MakeWireIndicator(prototype, scale)
		local name, angOffset, posOffset = unpack(prototype)
		posOffset = Vector(0, posOffset.x, -posOffset.y)
		local Pos, Ang  = LocalToWorld(posOffset * scale, Angle(), Pos, Ang), Ang + angOffset
		local ent = WireLib.MakeWireEnt(pl,
		{ Class = "gmod_wire_indicator",
		Pos = Pos, Angle = Ang,
		Model = Model, frozen = frozen, nocollide = nocollide },
		a, ar, ag, ab, aa, b, br, bg, bb, ba )
		if IsValid(ent) then
			ent:SetNWString("WireName", name)
			duplicator.StoreEntityModifier( ent, "WireName", { name = name } )
		end
		return ent
	end


	local prototypes = {
		{ "G", Angle(0, 0, 0), Vector(0, 0) },
		{ "A", Angle(0, 0, 0), Vector(0, 2) },
		{ "B", Angle(0, 0, 90), Vector(1, 1) },
		{ "C", Angle(0, 0, 90), Vector(1, -1) },
		{ "D", Angle(0, 0, 0), Vector(0, -2) },
		{ "E", Angle(0, 0, 90), Vector(-1, -1) },
		{ "F", Angle(0, 0, 90), Vector(-1, 1) }
	}

	local wire_indicators = {}
	wire_indicators[1] = MakeWireIndicator( prototypes[1], 0 )

	-- get the scale (half the long side of the indicator) from the first one
	local scale = wire_indicators[1]:OBBMaxs().y

	for i = 2, 7 do
		wire_indicators[i] = MakeWireIndicator( prototypes[i], scale )
		if not IsValid( wire_indicators[i] ) then break end

		for y = 1, i-1 do
			const = constraint.Weld( wire_indicators[i], wire_indicators[y], 0, 0, 0, true, true )
		end
		wire_indicators[i - 1]:DeleteOnRemove( wire_indicators[i] ) --when one is removed, all are. a linked chain
	end

	if wire_indicators[7] then
		wire_indicators[7]:DeleteOnRemove( wire_indicators[1] ) --loops chain back to first
	end

	return wire_indicators
end
