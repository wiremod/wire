E2Lib.RegisterExtension( "light", false )

-- By Divran

local max_convar = CreateConVar( "wire_expression2_lights_max", 20, { FCVAR_ARCHIVE, FCVAR_NOTIFY } )

local count = {}

-----------------------------------------------------------------------
-- Construct & Destruct
-- Create initial table/Remove light entities
-----------------------------------------------------------------------
registerCallback( "construct", function( self )
	self.lights = {}
end)
registerCallback( "destruct", function( self )
	for k,v in pairs( self.lights ) do
		if v and v:IsValid() then
			count[self.uid] = count[self.uid] - 1
			v:Remove()
		end
	end
end)

-----------------------------------------------------------------------
-- GetLight
-- Gets the light entity at the specified index
-----------------------------------------------------------------------
local function GetLight( self, index )
	return self.lights[index]
end

-----------------------------------------------------------------------
-- CheckLimit
-- Check if the user can create a light right now
-----------------------------------------------------------------------
local function CheckLimit( self, dontsub )
	if not count[self.uid] then
		count[self.uid] = 0
		return true
	end
	
	if count[self.uid] >= max_convar:GetInt() then return false end

	if dontsub == nil then
		count[self.uid] = count[self.uid] + 1
	end
	
	return true
end

-----------------------------------------------------------------------
-- CreateLight
-- Create the light entity
-----------------------------------------------------------------------
local function CreateLight( self, index, position, color, distance, brightness )
	local light = GetLight( self, index )
	if light and light:IsValid() then
		if position then
			light:SetPos( Vector(position[1],position[2],position[3]) )
		end
		
		if color then
			light:SetKeyValue("_light", ("%d %d %d 255"):format( color[1], color[2], color[3] ))
			light.color = color
		end
		
		if distance then
			light:SetKeyValue("distance",math.Clamp(distance,50,255))
			light.distance = distance
		end
		
		if brightness then
			light:SetKeyValue("brightness",math.Clamp(brightness,1,10))
			light.brightness = brightness
		end
	else
		if not CheckLimit( self ) then return end
	
		if not position then position = self.entity:GetPos() else position = Vector(position[1],position[2],position[3]) end
		if not color then color = {255,255,255} end
		distance = distance or 255
		brightness = brightness or 5
		
		local light = ents.Create( "light_dynamic" )
		if not light or not light:IsValid() then return end
		
		self.lights[index] = light
		
		light:SetPos( position )
		light:SetKeyValue("style", 0)
		
		light:SetKeyValue("_light", ("%d %d %d 255"):format( color[1], color[2], color[3] ))
		light.color = color
		
		light:SetKeyValue("distance",math.Clamp(distance,50,255))
		light.distance = distance
		
		light:SetKeyValue("brightness",math.Clamp(brightness,1,10))
		light.brightness = brightness
		
		light.toggle = 1
		
		light:Spawn()
	end
end

-----------------------------------------------------------------------
-- E2 functions
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Creation functions
-----------------------------------------------------------------------
__e2setcost( 25 )

e2function void lightCreate( index )
	CreateLight( self, index )
end
e2function void lightCreate( index, vector position )
	CreateLight( self, index, position )
end
e2function void lightCreate( index, vector position, vector color )
	CreateLight( self, index, position, color )
end
e2function void lightCreate( index, vector position, vector color, distance )
	CreateLight( self, index, position, color, distance )
end
e2function void lightCreate( index, vector position, vector color, distance, brightness )
	CreateLight( self, index, position, color, distance, brightness )
end

-----------------------------------------------------------------------
-- Modification functions
-----------------------------------------------------------------------
__e2setcost( 10 )
e2function void lightPos( index, vector position )
	local light = GetLight( self, index )
	if not light then return end
	light:SetPos( Vector(position[1],position[2],position[3]) )
end

__e2setcost( 5 )
e2function vector lightPos( index )
	local light = GetLight( self, index )
	if not light then return {0,0,0} end
	return light:GetPos()
end

-----------------
__e2setcost( 10 )
e2function void lightColor( index, vector color )
	local light = GetLight( self, index )
	if not light then return end
	light:SetKeyValue("_light", ("%d %d %d 255"):format( color[1], color[2], color[3] ))
	light.color = color
end

__e2setcost( 5 )
e2function vector lightColor( index )
	local light = GetLight( self, index )
	if not light then return {0,0,0} end
	return {color[1],color[2],color[3]}
end

-----------------
__e2setcost( 10 )
e2function void lightToggle( index, toggle )
	local light = GetLight( self, index )
	if not light then return end
	if toggle == 0 then
		light:Fire( "TurnOff", "", "0" )
		light.toggle = 0
	else
		light:Fire( "TurnOn", "", "0" )
		light.toggle = 1
	end
end

__e2setcost( 2 )
e2function number lightToggle( index )
	local light = GetLight( self, index )
	if not light then return 0 end
	return light.toggle
end

-----------------
__e2setcost( 8 )
e2function void lightDistance( index, distance )
	local light = GetLight( self, index )
	if not light then return end
	distance = math.Clamp( distance, 50, 255 )
	light:SetKeyValue( "distance", distance )
	light.distance = distance
end

__e2setcost( 2 )
e2function number lightDistance( index, distance )
	local light = GetLight( self, index )
	if not light then return 0 end
	return light.distance
end

-----------------
__e2setcost( 8 )
e2function void lightBrightness( index, brightness )
	local light = GetLight( self, index )
	if not light then return end
	brightness = math.Clamp( brightness, 1, 10 )
	light:SetKeyValue("brightness", brightness )
	light.brightness = brightness
end

__e2setcost( 2 )
e2function number lightBrightness( index, distance )
	local light = GetLight( self, index )
	if not light then return 0 end
	return light.distance
end

-----------------------------------------------------------------------
-- Remove & Parent functions
-----------------------------------------------------------------------
__e2setcost( 10 )
e2function void lightParent( index, parent )
	local light = GetLight( self, index )
	if not light then return end
	
	local light2 = GetLight( self, parent )
	if not light2 then return end
	
	light:SetParent( light2 )
end
e2function void lightParent( index, entity parent )
	if not parent or not parent:IsValid() then return end

	local light = GetLight( self, index )
	if not light then return end

	light:SetParent( parent )
end

e2function void lightUnparent( number index )
	local light = GetLight( self, index )
	if not light then return end
	
	light:SetParent()
end

-----------------

__e2setcost( 15 )
e2function void lightRemove( index )
	local light = GetLight( self, index )
	if not light then return end
	
	self.lights[light] = nil
	count[self.uid] = count[self.uid] - 1
	light:Remove()
end

__e2setcost( 2 )
e2function void lightRemoveAll()
	for k,v in pairs( self.lights ) do
		self.prf = self.prf + 1/3
		if v and v:IsValid() then
			v:Remove()
			count[self.uid] = count[self.uid] - 1
		end
	end
	self.lights = {}
end

-----------------------------------------------------------------------
-- Other functions
-----------------------------------------------------------------------
__e2setcost( 2 )
e2function entity lightEntity( number index )
	return GetLight( self, index )
end

e2function number lightRemainingSpawns()
	return max_convar:GetInt() - (count[self.uid] or 0)
end

__e2setcost( nil )