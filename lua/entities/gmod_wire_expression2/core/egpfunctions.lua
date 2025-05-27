local EGP = E2Lib.EGP
local NULL_EGPOBJECT = EGP.Objects.NULL_EGPOBJECT
local hasObject = EGP.HasObject
local isAllowed = EGP.IsAllowed
local egp_create = EGP.Create

local function Update(self,this)
	self.data.EGP.UpdatesNeeded[this] = true
end

--------------------------------------------------------
-- Frames
--------------------------------------------------------
-------------
-- Save
-------------

__e2setcost(15)

e2function void wirelink:egpSaveFrame( string index )
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", nil) end
	if (!index or index == "") then return self:throw("Invalid index!", nil) end
	local bool, frame = EGP:LoadFrame( self.player, nil, index )
	if (bool) then
		if (!EGP:IsDifferent( this.RenderTable, frame )) then return end
	end
	EGP:DoAction( this, self, "SaveFrame", index )
	Update(self,this)
end

e2function void wirelink:egpSaveFrame( index )
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", nil) end
	if (!index) then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, tostring(index) )
	if (bool) then
		if (!EGP:IsDifferent( this.RenderTable, frame )) then return end
	end
	EGP:DoAction( this, self, "SaveFrame", tostring(index) )
	Update(self,this)
end

-------------
-- Load
-------------

__e2setcost(15)

e2function void wirelink:egpLoadFrame( string index )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!index or index == "") then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, index )
	if (bool) then
		if (EGP:IsDifferent( this.RenderTable, frame )) then
			EGP:DoAction( this, self, "LoadFrame", index )
			Update(self,this)
		end
	end
end

e2function void wirelink:egpLoadFrame( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!index) then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, tostring(index) )
	if (bool) then
		if (EGP:IsDifferent( this.RenderTable, frame )) then
			EGP:DoAction( this, self, "LoadFrame", tostring(index) )
			Update(self,this)
		end
	end
end

--------------------------------------------------------
-- Order
--------------------------------------------------------

e2function void wirelink:egpOrder(number index, number order)
	if not isAllowed(nil, self, this) then return end
	local bool, k, v = hasObject(this, index)
	if bool then
		if EGP.SetOrder(this, k, order) then
			EGP:DoAction(this, self, "SendObject", v)
			Update(self,this)
		end
	end
end

e2function number wirelink:egpOrder( number index )
	if not isAllowed(nil, self, this) then return -1 end
	local bool, k = hasObject(this, index)
	if bool then
		return k
	end
	return -1
end

e2function void wirelink:egpOrderAbove(number index, number abovethis)
	if not isAllowed(nil, self, this) then return end
	local bool, k, v = hasObject(this, index)
	if bool then
		if hasObject(this, abovethis) then
			if EGP.SetOrder(this, k, abovethis, 1) then
				EGP:DoAction(this, self, "SendObject", v)
				Update(self, this)
			end
		end
	end
end

e2function void wirelink:egpOrderBelow( number index, number belowthis )
	if not isAllowed(nil, self, this) then return end
	local bool, k, v = hasObject(this, index)
	if bool then
		if hasObject(this, belowthis) then
			if EGP.SetOrder(this, k, belowthis, -1) then
				EGP:DoAction(this, self, "SendObject", v)
				Update(self,this)
			end
		end
	end
end

__e2setcost(15)

--------------------------------------------------------
-- Box
--------------------------------------------------------
e2function egpobject wirelink:egpBox( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("Box", { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj 
end

--------------------------------------------------------
-- BoxOutline
--------------------------------------------------------
e2function egpobject wirelink:egpBoxOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("BoxOutline", { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- RoundedBox
--------------------------------------------------------
e2function egpobject wirelink:egpRoundedBox( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("RoundedBox", { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function void wirelink:egpRadius( number index, number radius )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ radius = radius }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

--------------------------------------------------------
-- RoundedBoxOutline
--------------------------------------------------------
e2function egpobject wirelink:egpRoundedBoxOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("RoundedBoxOutline", { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Text
--------------------------------------------------------
local EGP_TEXT_LIMIT = 512

e2function egpobject wirelink:egpText( number index, string text, vector2 pos )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if #text>EGP_TEXT_LIMIT then text = string.sub(text, 1, EGP_TEXT_LIMIT) end
	local bool, obj = egp_create("Text", { index = index, text = text, x = pos[1], y = pos[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function egpobject wirelink:egpTextLayout( number index, string text, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if #text>EGP_TEXT_LIMIT then text = string.sub(text, 1, EGP_TEXT_LIMIT) end
	local bool, obj = egp_create("TextLayout", { index = index, text = text, x = pos[1], y = pos[2], w = size[1], h = size[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

__e2setcost(10)

----------------------------
-- Set Text
----------------------------
e2function void wirelink:egpSetText( number index, string text )
	if (!EGP:IsAllowed( self, this )) then return end
	if #text>EGP_TEXT_LIMIT then text = string.sub(text, 1, EGP_TEXT_LIMIT) end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ text = text }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Alignment
----------------------------
e2function void wirelink:egpAlign( number index, number halign )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ halign = math.Clamp(halign,0,2) }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpAlign( number index, number halign, number valign )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ valign = math.Clamp(valign,0,2), halign = math.Clamp(halign,0,2) }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Filtering
----------------------------
e2function void wirelink:egpFiltering( number index, number filtering )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ filtering = math.Clamp(filtering,0,3) }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpGlobalFiltering( number filtering )
	if (!EGP:IsAllowed( self, this )) then return end
	if this:GetClass() == "gmod_wire_egp" then -- Only Screens use GPULib and can use global filtering
		EGP:DoAction( this, self, "EditFiltering", math.Clamp(filtering, 0, 3) )
	end
end

for _,cname in ipairs({ "NONE", "POINT", "LINEAR", "ANISOTROPIC" }) do
	local value = TEXFILTER[cname]
	if value < 0 or value > 3 then
		print("WARNING: TEXFILTER."..cname.."="..value.." out of expected range (0-3). Please adjust code to udpdated values. Skipping...")
		-- Update clamp for both filtering functions above as well as write/readUInt(filtering,2) in egp baseclass+poly netcode.
	else
		E2Lib.registerConstant("TEXFILTER_"..cname, value)
	end
end

----------------------------
-- Font
----------------------------
local function canCreateFont( ply, font, size )
	size = size or 18

	EGP.PlayerFontCount[ply:SteamID64()] = EGP.PlayerFontCount[ply:SteamID64()] or { fonts = {}, count = 0 }
	local fontTable = EGP.PlayerFontCount[ply:SteamID64()] 

	if fontTable.count >= 50 then return false end

	local fontName = font .. size
	if fontTable.fonts[fontName] then return true end

	fontTable.count = fontTable.count + 1
	fontTable.fonts[fontName] = true

	return true
end

e2function void wirelink:egpFont( number index, string font )
	if (!EGP:IsAllowed( self, this )) then return end
	if #font > 30 then return self:throw("Font string is too long!", nil) end
	if not canCreateFont( self.player, font ) then return self:throw("You have reached the maximum amount of fonts!", nil) end

	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ font = font }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpFont( number index, string font, number size )
	if (!EGP:IsAllowed( self, this )) then return end
	if #font > 30 then return self:throw("Font string is too long!", nil) end
	if not canCreateFont( self.player, font, size ) then return self:throw("You have reached the maximum amount of fonts!", nil) end

	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ font = font, size = size }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

--------------------------------------------------------
-- Poly
--------------------------------------------------------

__e2setcost(20)

local function maxvertices() return EGP.ConVars.MaxVertices:GetInt() end

e2function egpobject wirelink:egpPoly( number index, ...args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if #args < 3 then return NULL_EGPOBJECT end -- No less than 3

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if (typeids[k] == "xv2" or typeids[k] == "xv4") then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (typeids[k] == "xv4") then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("Poly", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function egpobject wirelink:egpPoly( number index, array args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if (#args<3) then return NULL_EGPOBJECT end -- No less than 3

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if istable(v) and (#v == 2 or #v == 4) then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (#v == 4) then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("Poly", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- PolyOutline
--------------------------------------------------------

e2function egpobject wirelink:egpPolyOutline( number index, ...args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if #args < 3 then return NULL_EGPOBJECT end -- No less than 3

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if (typeids[k] == "xv2" or typeids[k] == "xv4") then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (typeids[k] == "xv4") then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("PolyOutline", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function egpobject wirelink:egpPolyOutline( number index, array args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if (#args<3) then return NULL_EGPOBJECT end -- No less than 3

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if istable(v) and (#v == 2 or #v == 4) then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (#v == 4) then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("PolyOutline", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function void wirelink:egpAddVertices( number index, array args )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", nil) end
	if (#args<3) then return end -- No less than 3

	local bool, k, v = hasObject(this, index)
	if (bool) then

		local max = maxvertices()

		-- Each arg must be a vec2 or vec4
		local vertices = {}
		for k,v in ipairs( args ) do
			if istable(v) and (#v == 2 or #v == 4) then
				n = #vertices
				if (n > max) then break end
				vertices[n+1] = { x = v[1], y = v[2] }
				if (#v == 4) then
					vertices[n+1].u = v[3]
					vertices[n+1].v = v[4]
				end
			end
		end

		if v:EditObject({ vertices = vertices }) then
			EGP:InsertQueue( this, self.player, EGP._SetVertex, "SetVertex", index, vertices, true )
			Update(self,this)
		end
	end
end

--------------------------------------------------------
-- egpLineStrip (PolyOutline without the final connecting line)
--------------------------------------------------------

e2function egpobject wirelink:egpLineStrip( number index, ...args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if #args < 2 then return NULL_EGPOBJECT end -- No less than 2

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if (typeids[k] == "xv2" or typeids[k] == "xv4") then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (typeids[k] == "xv4") then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("LineStrip", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function egpobject wirelink:egpLineStrip( number index, array args )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", NULL_EGPOBJECT) end
	if (#args<2) then return NULL_EGPOBJECT end -- No less than 2

	local max = maxvertices()

	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if istable(v) and (#v == 2 or #v == 4) then
			n = #vertices
			if (n > max) then break end
			vertices[n+1] = { x = v[1], y = v[2] }
			if (#v == 4) then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end

	local bool, obj = egp_create("LineStrip", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

__e2setcost(15)

--------------------------------------------------------
-- Line
--------------------------------------------------------
e2function egpobject wirelink:egpLine( number index, vector2 pos1, vector2 pos2 )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("Line", { index = index, x = pos1[1], y = pos1[2], x2 = pos2[1], y2 = pos2[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Circle
--------------------------------------------------------
e2function egpobject wirelink:egpCircle( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("Circle", { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Circle Outline
--------------------------------------------------------
e2function egpobject wirelink:egpCircleOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("CircleOutline", { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Triangle
--------------------------------------------------------
e2function egpobject wirelink:egpTriangle( number index, vector2 v1, vector2 v2, vector2 v3 )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local vertices = { { x = v1[1], y = v1[2] }, { x = v2[1], y = v2[2] }, { x = v3[1], y = v3[2] } }
	local bool, obj = egp_create("Poly", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Triangle Outline
--------------------------------------------------------
e2function egpobject wirelink:egpTriangleOutline( number index, vector2 v1, vector2 v2, vector2 v3 )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local vertices = { { x = v1[1], y = v1[2] }, { x = v2[1], y = v2[2] }, { x = v3[1], y = v3[2] } }
	local bool, obj = egp_create("PolyOutline", { index = index, vertices = vertices }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Wedge
--------------------------------------------------------
e2function egpobject wirelink:egpWedge( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("Wedge", { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

--------------------------------------------------------
-- Wedge Outline
--------------------------------------------------------
e2function egpobject wirelink:egpWedgeOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("WedgeOutline", { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end


--------------------------------------------------------
-- 3DTracker
--------------------------------------------------------
e2function egpobject wirelink:egp3DTracker( number index, vector pos )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, obj = egp_create("3DTracker", { index = index, target_x = pos[1], target_y = pos[2], target_z = pos[3], directionality = 0 }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

e2function egpobject wirelink:egp3DTracker( number index, vector pos, number directionality )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end

	if directionality > 0 then
		directionality = 1
	elseif directionality < 0 then
		directionality = -1
	end

	local bool, obj = egp_create("3DTracker", { index = index, target_x = pos[1], target_y = pos[2], target_z = pos[3], directionality = directionality }, this)
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	return obj
end

__e2setcost(10)

e2function void wirelink:egpPos( number index, vector pos )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v:EditObject({ target_x = pos[1], target_y = pos[2], target_z = pos[3] })) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

--------------------------------------------------------
-- Set functions
--------------------------------------------------------

__e2setcost(10)

----------------------------
-- Size
----------------------------
e2function void wirelink:egpSize( number index, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ w = size[1], h = size[2] }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpSize( number index, number size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ size = size }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Position
----------------------------
e2function void wirelink:egpPos( number index, vector2 pos )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, _, v = hasObject(this, index)
	if bool and v:SetPos(pos[1], pos[2]) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

----------------------------
-- Angle
----------------------------

e2function void wirelink:egpAngle( number index, number angle )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:SetPos(nil, nil, angle) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

-------------
-- Position & Angle
-------------

e2function void wirelink:egpAngle( number index, vector2 worldpos, vector2 axispos, number angle )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.x and v.y) then

			local vec, ang = LocalToWorld(Vector(axispos[1],axispos[2],0), Angle(0,0,0), Vector(worldpos[1],worldpos[2],0), Angle(0,-angle,0))

			local x = vec.x
			local y = vec.y

			angle = -ang.yaw

			local t = { x = x, _x = x, y = y, _y = y }
			if (v.angle) then t.angle, t._angle = angle, angle end

			if v:EditObject(t) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
		end
	end
end

----------------------------
-- Color
----------------------------
e2function void wirelink:egpColor( number index, vector4 color )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ r = color[1], g = color[2], b = color[3], a = color[4] }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpColor( number index, vector color )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ r = color[1], g = color[2], b = color[3] }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpColor( number index, r,g,b,a )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, _, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ r = r, g = g, b = b, a = a }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpAlpha( number index, number a )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ a = a }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end


----------------------------
-- Material
----------------------------
e2function void wirelink:egpMaterial( number index, string material )
	if (!EGP:IsAllowed( self, this )) then return end
	material = WireLib.IsValidMaterial(material)
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ material = material }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpMaterialFromScreen( number index, entity gpu )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool and gpu and gpu:IsValid()) then
		if v:EditObject({ material = gpu }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Fidelity (number of corners for circles and wedges)
----------------------------
e2function void wirelink:egpFidelity( number index, number fidelity )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if v:EditObject({ fidelity = math.Clamp(fidelity,3,180) }) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function number wirelink:egpFidelity( number index )
	if (!EGP:IsAllowed( self, this )) then return -1 end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.fidelity) then
			return v.fidelity
		end
	end
	return -1
end

----------------------------
-- Parenting
----------------------------
e2function void wirelink:egpParent( number index, number parentindex )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:SetParent( this, index, parentindex )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

-- Entity parenting (only for 3Dtracker - does nothing for any other object)
e2function void wirelink:egpParent( number index, entity parent )
	if not parent or not parent:IsValid() then return end
	if (!EGP:IsAllowed( self, this )) then return end

	local bool, k, v = hasObject(this, index)
	if bool and v.NeedsConstantUpdate then
		if v.parententity == parent then return end -- Already parented to that
		v.parententity = parent

		EGP:DoAction( this, self, "SendObject", v )
		Update(self,this)
	end
end

-- Returns the entity a tracker is parented to
e2function entity wirelink:egpTrackerParent( number index )
	local bool, k, v = hasObject(this, index)
	if bool and v.NeedsConstantUpdate then
		return (v.parententity and v.parententity:IsValid()) and v.parententity or nil
	end
end

e2function void wirelink:egpParentToCursor( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:SetParent( this, index, -1 )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

e2function void wirelink:egpUnParent( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:UnParent( this, index )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

e2function number wirelink:egpParent( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.parent) then
			return v.parent
		end
	end
	return -1
end

--------------------------------------------------------
-- Clear & Remove
--------------------------------------------------------
e2function void wirelink:egpClear()
	if (!EGP:IsAllowed( self, this )) then return end
	if (EGP:ValidEGP( this )) then
		EGP:DoAction( this, self, "ClearScreen" )
		Update(self,this)
	end
end

e2function void wirelink:egpRemove( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = hasObject(this, index)
	if (bool) then
		EGP:DoAction( this, self, "RemoveObject", index )
		Update(self,this)
	end
end

--------------------------------------------------------
-- Get functions
--------------------------------------------------------

__e2setcost(5)

e2function vector2 wirelink:egpPos( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.x and v.y) then
			return {v.x, v.y}
		end
	end
	return {-1,-1}
end

__e2setcost(20)
e2function vector wirelink:egpGlobalPos( number index )
	local _, posang = EGP:GetGlobalPos( this, index )
	return Vector(posang.x, posang.y, posang.angle)
end

e2function array wirelink:egpGlobalVertices( number index )
	local hasobject, _, object = hasObject(this, index)
	if hasobject and object.verticesindex then
		local data = EGP:GetGlobalVertices(object)
		if data.vertices then
			local ret = {}
			for i=1,#data.vertices do
				local v = data.vertices[i]
				ret[i] = {v.x,v.y}
				self.prf = self.prf + 0.1
			end
			return ret
		elseif (data.x and data.y and data.x2 and data.y2 and data.x3 and data.y3) then
			return {{data.x,data.y},{data.x2,data.y2},{data.x3,data.y3}}
		elseif (data.x and data.y and data.x2 and data.y2) then
			return {{data.x,data.y},{data.x2,data.y2}}
		end
	end
	return { 0, 0, 0 }
end

__e2setcost(5)

e2function vector2 wirelink:egpSize( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.w and v.h) then
			return {v.w, v.h}
		end
	end
	return {-1,-1}
end

e2function number wirelink:egpSizeNum( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.size) then
			return v.size
		end
	end
	return -1
end

e2function vector4 wirelink:egpColor4( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.r and v.g and v.b and v.a) then
			return {v.r,v.g,v.b,v.a}
		end
	end
	return {-1,-1,-1,-1}
end

e2function vector wirelink:egpColor( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.r and v.g and v.b) then
			return Vector(v.r, v.g, v.b)
		end
	end
	return Vector(-1, -1, -1)
end

e2function number wirelink:egpAlpha( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.a) then
			return v.a
		end
	end
	return -1
end

e2function number wirelink:egpAngle( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.angle) then
			return v.angle
		end
	end
	return -1
end

e2function string wirelink:egpMaterial( number index )
	local bool, _, v = hasObject(this, index)
	return bool and v.material and tostring(v.material) or ""
end

e2function number wirelink:egpRadius( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.radius) then
			return v.radius
		end
	end
	return -1
end

__e2setcost(10)

e2function array wirelink:egpVertices( number index )
	local bool, k, v = hasObject(this, index)
	if (bool) then
		if (v.vertices) then
			local ret = {}
			for k2,v2 in ipairs( v.vertices ) do
				ret[k2] = {v2.x,v2.y}
			end
			return ret
		elseif (v.x and v.y and v.x2 and v.y2 and v.x3 and v.y3) then
			return {{v.x,v.y},{v.x2,v.y2},{v.x3,v.y3}}
		elseif (v.x and v.y and v.x2 and v.y2) then
			return {{v.x,v.y},{v.x2,v.y2}}
		end
	end
	return {}
end

--------------------------------------------------------
-- Indexes
--------------------------------------------------------
__e2setcost(1)
e2function array wirelink:egpObjectIndexes()
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", {}) end
	if not this.RenderTable or #this.RenderTable == 0 then return {} end
	local indexes = {}
	for _, v in pairs(this.RenderTable) do
		indexes[#indexes + 1] = v.index
	end
	self.prf = self.prf + #indexes/3
	return indexes
end

--------------------------------------------------------
-- Object Type
--------------------------------------------------------
__e2setcost(1)

e2function array wirelink:egpObjectTypes()
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", {}) end
	if not this.RenderTable or #this.RenderTable == 0 then return {} end
	local objs = {}
	for _, v in pairs(this.RenderTable) do
		objs[v.index] = EGP.Objects.Names_Inverted[v.ID] or ""
	end
	self.prf = self.prf + #this.RenderTable/3
	return objs
end

__e2setcost(10)

e2function string wirelink:egpObjectType(number index)
	local bool, _, v = hasObject(this, index)
	if bool then
		return EGP.Objects[v.ID].Name or ""
	end
	return ""
end

--------------------------------------------------------
-- Additional Functions
--------------------------------------------------------

__e2setcost(15)

e2function egpobject wirelink:egpCopy( index, fromindex )
	if (!EGP:IsAllowed( self, this )) then return NULL_EGPOBJECT end
	local bool, k, v = hasObject(this, fromindex)
	if (bool) then
		local copy = table.Copy( v )
		copy.index = index
		local bool2, obj = egp_create(v.ID, copy, this)
		if (bool2) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
		return obj
	end
	return NULL_EGPOBJECT
end

__e2setcost(20)

e2function vector2 wirelink:egpCursor( entity ply )
	return EGP:EGPCursor( this, ply )
end

__e2setcost(10)

e2function vector2 egpScrSize( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return {-1,-1} end
	return EGP.ScrHW[ply]
end

e2function number egpScrW( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return -1 end
	return EGP.ScrHW[ply][1]
end

e2function number egpScrH( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return -1 end
	return EGP.ScrHW[ply][2]
end

__e2setcost(15)

e2function number wirelink:egpHasObject( index )
	local bool, _, _ = hasObject(this, index)
	return bool and 1 or 0
end

__e2setcost(20)

--- Returns 1 if the object with specified index contains the specified point.
e2function number wirelink:egpObjectContainsPoint(number index, vector2 point)
	local _, _, object = hasObject(this, index)
	return object and object:Contains(point[1], point[2]) and 1 or 0
end

__e2setcost(10)

local function errorcheck( x, y )
	local xMul = x[2]-x[1]
	local yMul = y[2]-y[1]
	if (xMul == 0 or yMul == 0) then error("Invalid EGP scale") end
end

e2function void wirelink:egpScale( vector2 xScale, vector2 yScale )
	if (!EGP:IsAllowed( self, this )) then return end
	errorcheck(xScale,yScale)
	EGP:DoAction( this, self, "SetScale", xScale, yScale )
end

e2function void wirelink:egpResolution( vector2 topleft, vector2 bottomright )
	if (!EGP:IsAllowed( self, this )) then return end
	local xScale = { topleft[1], bottomright[1] }
	local yScale = { topleft[2], bottomright[2] }
	errorcheck(xScale,yScale)
	EGP:DoAction( this, self, "SetScale", xScale, yScale )
end

e2function vector2 wirelink:egpOrigin()
	if (!EGP:IsAllowed( self, this )) then return {0,0} end
	local xOrigin = this.xScale[1] + (this.xScale[2] - this.xScale[1])/2
	local yOrigin = this.yScale[1] + (this.yScale[2] - this.yScale[1])/2
	return { xOrigin, yOrigin }
	--return EGP:DoAction( this, self, "GetOrigin" )
end

e2function vector2 wirelink:egpSize()
	if (!EGP:IsAllowed( self, this )) then return {0,0} end
	local width = math.abs(this.xScale[1] - this.xScale[2])
	local height = math.abs(this.yScale[1] - this.yScale[2])
	return { width, height }
	--return EGP:DoAction( this, self, "GetScreenSize" )
end

e2function void wirelink:egpDrawTopLeft( number onoff )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool = true
	if (onoff == 0) then bool = false end
	EGP:DoAction( this, self, "MoveTopLeft", bool )
end

-- this code has some wtf strange things
local function ScalePoint( this, x, y )
	local xMin = this.xScale[1]
	local xMax = this.xScale[2]
	local yMin = this.yScale[1]
	local yMax = this.yScale[2]

	x = ((x - xMin) * 512) / (xMax - xMin) - xMax
	y = ((y - yMin) * 512) / (yMax - yMin) - yMax

	return x,y
end


__e2setcost(20)
e2function vector wirelink:egpToWorld( vector2 pos )
	if not EGP:ValidEGP( this ) then return self:throw("Invalid wirelink!", Vector(0, 0, 0)) end

	local class = this:GetClass()
	if class == "gmod_wire_egp_emitter" then
		local x,y = pos[1]*0.25,pos[2]*0.25 -- 0.25 because the scale of the 3D2D is 0.25.
		if this.Scaling then
			x,y = ScalePoint(this,x,y)
		end
		return this:LocalToWorld( Vector(-64,0,135) + Vector(x,0,-y) )
	elseif class == "gmod_wire_egp" then
		local monitor = WireGPU_Monitors[this:GetModel()]
		if not monitor then return Vector(0,0,0) end

		local x,y = pos[1],pos[2]

		if this.Scaling then
			x,y = ScalePoint( this, x, y )
		else
			x,y = x-256,y-256
		end

		x = x * monitor.RS / monitor.RatioX
		y = y * monitor.RS

		local vec = Vector(x,-y,0)
		vec:Rotate(monitor.rot)
		return this:LocalToWorld(vec+monitor.offset)
	end

	return Vector(0,0,0)
end

local antispam = {}
__e2setcost(25)
e2function void wirelink:egpHudToggle()
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", nil) end
	if antispam[self.player] and antispam[self.player] > CurTime() then return end
	antispam[self.player] = CurTime() + 0.1

	timer.Simple(0, function()
		EGP.EGPHudConnect(this, not (this.Users ~= nil and this.Users[self.player] ~= nil), self.player)
	end)
end

e2function void wirelink:egpHudEnable(enable)
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", nil) end
	if antispam[self.player] and antispam[self.player] > CurTime() then return end
	antispam[self.player] = CurTime() + 0.1

	timer.Simple(0, function()
		EGP.EGPHudConnect(this, enable ~= 0, self.player)
	end)
end

e2function array wirelink:egpConnectedUsers()
	if not EGP:ValidEGP(this) then return self:throw("Invalid wirelink!", {}) end
	if not this.Users then return {} end

	local sanitised_array, i = {}, 0
	for k, _ in pairs(this.Users) do
		i = i + 1
		sanitised_array[i] = k
	end
	return sanitised_array
end

E2Lib.registerEvent("egpHudConnect", { { "Screen", "xwl" }, { "Player", "e" }, { "Connected", "n" } })

--------------------------------------------------------
-- Useful functions
--------------------------------------------------------

-----------------------------
-- ConVars
-----------------------------

__e2setcost(10)

e2function number wirelink:egpNumObjects()
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", -1) end
	return #this.RenderTable
end

e2function number egpMaxObjects()
	return EGP.ConVars.MaxObjects:GetInt()
end

e2function number egpMaxUmsgPerSecond()
	return EGP.ConVars.MaxPerSec:GetInt()
end

e2function number egpBytesLeft()
	local maxcount = EGP.ConVars.MaxPerSec:GetInt()
	local tbl = EGP.IntervalCheck[self.player]
	tbl.bytes = math.max(0, tbl.bytes - (CurTime() - tbl.time) * maxcount)
	tbl.time = CurTime()
	return maxcount - tbl.bytes
end

__e2setcost(5)

e2function number egpCanSendUmsg()
	return (EGP:CheckInterval( self.player ) and 1 or 0)
end

-----------------------------
-- Queue system
-----------------------------

e2function number egpClearQueue()
	if (EGP.Queue[self.player]) then
		EGP.Queue[self.player] = {}
		return 1
	end
	return 0
end

--[[ currently does not work
e2 function number wirelink:egpClearQueue()
	if (!EGP:ValidEGP( this )) then return end
	if (EGP.Queue[self.player]) then
		EGP:StopQueueTimer( self.player )
		EGP.Queue[self.player].DONTADDMORE = true
		local removetable = {}
		for k,v in ipairs( EGP.Queue[self.player] ) do
			if (v.Ent == this) then
				table.insert( removetable, k )
				return 1
			end
		end
		for k,v in ipairs( removetable ) do
			table.remove( EGP.Queue[self.player], v )
		end
		EGP:SendQueueItem( self.player )
		EGP:StartQueueTimer( self.player )
		timer.Simple(1,function() EGP.Queue[self.player].DONTADDMORE = nil end)
	end
	return 0
end
]]

__e2setcost(10)

-- Returns the amount of items in your queue
e2function number egpQueue()
	if (EGP.Queue[self.player]) then
		return #EGP.Queue[self.player]
	end
	return 0
end

-- Choose whether or not to make this E2 run when the queue has finished sending all items for <this>
e2function void wirelink:egpRunOnQueue( yesno )
	if (!EGP:ValidEGP( this )) then return self:throw("Invalid wirelink!", nil) end
	local bool = false
	if (yesno ~= 0) then bool = true end
	self.data.EGP.RunOnEGP[this] = bool
end

-- Returns 1 if the current execution was caused by the EGP queue system OR if the EGP queue system finished in the current execution
e2function number egpQueueClk()
	return EGP.RunByEGPQueue and 1 or 0
end

-- Returns 1 if the current execution was caused by the EGP queue system regarding the entity <screen> OR if the EGP queue system finished in the current execution
e2function number egpQueueClk( wirelink screen )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_Ent == screen) then
		return 1
	end
	return 0
end

-- Returns 1 if the current execution was caused by the EGP queue system regarding the entity <screen> OR if the EGP queue system finished in the current execution
e2function number egpQueueClk( entity screen )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_Ent == screen) then
		return 1
	end
	return 0
end

-- Returns the screen which the queue finished sending items for
e2function entity egpQueueScreen()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_Ent
	end
end

-- Same as above, except returns wirelink
e2function wirelink egpQueueScreenWirelink()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_Ent
	end
end

-- Returns the player which ordered the current items to be sent (This is usually yourself, but if you're sharing pp with someone it might be them. Good way to check if someone is fucking with your screens)
e2function entity egpQueuePlayer()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_ply
	end
end

-- Returns 1 if the current execution was caused by the EGP queue system and the player <ply> was the player whom ordered the item to be sent (This is usually yourself, but if you're sharing pp with someone it might be them.)
e2function number egpQueueClkPly( entity ply )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_ply == ply) then
		return 1
	end
	return 0
end

--------------------------------------------------------
-- Callbacks
--------------------------------------------------------

registerCallback("postexecute",function(self)
	for k,v in pairs( self.data.EGP.UpdatesNeeded ) do
		if IsValid(k) then
			EGP:SendQueueItem( self.player )
		end
		self.data.EGP.UpdatesNeeded[k] = nil
	end
end)

registerCallback("construct",function(self)
	self.data.EGP = {}
	self.data.EGP.RunOnEGP = {}
	self.data.EGP.UpdatesNeeded = {}
end)
