E2Lib.RegisterExtension( "camera", false )

-- Original by WireDemon
-- Edit by Divran

local max_convar = CreateConVar( "wire_expression2_cameras_max", 5, { FCVAR_ARCHIVE, FCVAR_NOTIFY } )

local count = {}

-----------------------------------------------------------------------
-- Construct & Destruct
-- Create initial table/Remove camera entities
-----------------------------------------------------------------------
registerCallback( "construct", function( self )
	self.cameras = {}
end)
registerCallback( "destruct", function( self )
	for k,v in pairs( self.cameras ) do
		if v and v:IsValid() then
			if v.user then
				v.user:SetFOV( 0, 0.01 )
				v.user:SetViewEntity()
			end
			
			v:Remove()
			count[self.uid] = count[self.uid] - 1
		end
	end
end)
hook.Add( "PlayerLeaveVehicle", "wire_expression2_camera_exitvehicle", function( ply )
	local camera = ply:GetViewEntity()
	if camera and camera:IsValid() and camera.IsE2Camera then
		camera.user = nil
		ply:SetFOV( 0, 0.01 )
		ply:SetViewEntity()
	end
end)
hook.Add( "EntityRemoved", "wire_expression2_camera_player_disconnected", function( ply )
	if ply:IsPlayer() then
		local camera = ply:GetViewEntity()
		if camera and camera:IsValid() and camera.IsE2Camera then
			camera.user = nil
			ply:SetFOV( 0, 0.01 )
			ply:SetViewEntity()
		end
	end
end)

-----------------------------------------------------------------------
-- GetCamera
-- Gets the camera entity at the specified index
-----------------------------------------------------------------------
local function GetCamera( self, index )
	return self.cameras[index]
end

-----------------------------------------------------------------------
-- CheckLimit
-- Check if the user can create a camera right now
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
-- CreateCamera
-- Create the camera entity
-----------------------------------------------------------------------
local function CreateCamera( self, index, position, angle, zoom )
	local camera = GetCamera( self, index )
	if camera and camera:IsValid() then
		if position then
			camera:SetPos( Vector(position[1],position[2],position[3]) )
		end
		
		if angle then
			camera:SetAngles( Angle(angle[1],angle[2],angle[3]) )
		end
		
		if zoom then
			if camera.user then camera.user:SetFOV( zoom, 0.3 ) end
			camera.zoom = zoom
		end
	else
		if not CheckLimit( self ) then return end
		
		if not position then position = self.entity:GetPos() else position = Vector(position[1],position[2],position[3]) end
		if not angle then angle = self.entity:GetAngles() else angle = Angle(angle[1],angle[2],angle[3]) end
		zoom = zoom or 0
	
		local camera = ents.Create( "gmod_wire_cam" )
		camera:SetNoDraw(true)
		camera:SetPos( position )
		camera:SetAngles( angle )
		camera.zoom = zoom
		camera.IsE2Camera = true
		
		self.cameras[index] = camera
	end
end

-----------------------------------------------------------------------
-- E2 functions
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Creation functions
-----------------------------------------------------------------------
__e2setcost( 25 )

e2function void cameraCreate( index )
	CreateCamera( self, index )
end
e2function void cameraCreate( index, vector position )
	CreateCamera( self, index, position )
end
e2function void cameraCreate( index, vector position, angle ang )
	CreateCamera( self, index, position, ang )
end
e2function void cameraCreate( index, vector position, angle ang, zoom )
	CreateCamera( self, index, position, ang, zoom )
end

-----------------------------------------------------------------------
-- Modification functions
-----------------------------------------------------------------------
__e2setcost( 10 )
e2function void cameraPos( index, vector position )
	local camera = GetCamera( self, index )
	if not camera then return end
	camera:SetPos( Vector(position[1],position[2],position[3]) )
end

__e2setcost( 2 )
e2function vector cameraPos( index )
	local camera = GetCamera( self, index )
	if not camera then return {0,0,0} end
	return camera:GetPos()
end

-----------------
__e2setcost( 10 )
e2function void cameraAng( index, angle ang )
	local camera = GetCamera( self, index )
	if not camera then return end
	camera:SetAngles( Angle(ang[1],ang[2],ang[3]) )
end

__e2setcost( 2 )
e2function vector cameraAng( index )
	local camera = GetCamera( self, index )
	if not camera then return {0,0,0} end
	return camera:GetAngles()
end

-----------------
__e2setcost( 15 )
e2function void cameraToggle( index, toggle )
	local camera = GetCamera( self, index )
	if not camera then return end
	if toggle == 0 then
		if camera.user then
			camera.user:SetFOV( 0, 0.01 )
			camera.user:SetViewEntity()
			camera.user = nil
		end
	else
		camera.user = self.player
		self.player:SetViewEntity( camera )
		self.player:SetFOV( camera, camera.zoom )
	end
end
__e2setcost( 20 )
e2function void cameraToggle( index, toggle, entity vehicle )
	local camera = GetCamera( self, index )
	if not camera then return end
	
	
	if toggle == 0 then
		if camera.user then
			camera.user:SetFOV( 0, 0.01 )
			camera.user:SetViewEntity()
			camera.user = nil
		end
	else
		if not vehicle or not vehicle:IsValid() or not E2Lib.isOwner( self, vehicle ) then return end
		local driver = vehicle:GetDriver()
		if not driver or not driver:IsValid() then return end
		
		camera.user = driver
		driver:SetViewEntity( camera )
		driver:SetFOV( camera.zoom, 0.01 )
	end
end

__e2setcost( 2 )
e2function number cameraToggle( index )
	local camera = GetCamera( self, index )
	if not camera then return 0 end
	return camera.user and 1 or 0
end

-----------------
__e2setcost( 15 )
e2function void cameraZoom( index, zoom )
	local camera = GetCamera( self, index )
	if not camera then return end
	if camera.user then
		camera.user:SetFOV( zoom, 0.01 )
	end
	camera.zoom = zoom
end
e2function void cameraZoom( index, zoom, time )
	local camera = GetCamera( self, index )
	if not camera then return end
	if camera.user then
		camera.user:SetFOV( zoom, time )
	end
	camera.zoom = zoom
end

__e2setcost( 2 )
e2function number cameraZoom( index )
	local camera = GetCamera( self, index )
	if not camera then return 0 end
	return camera.zoom
end


-----------------------------------------------------------------------
-- Remove & Parent functions
-----------------------------------------------------------------------
__e2setcost( 10 )
e2function void cameraParent( index, entity parent )
	if not parent or not parent:IsValid() then return end

	local camera = GetCamera( self, index )
	if not camera then return end

	camera:SetParent( parent )
end

__e2setcost( 2 )
e2function void cameraUnparent( number index )
	local camera = GetCamera( self, index )
	if not camera then return end
	
	camera:SetParent()
end

-----------------

__e2setcost( 10 )
e2function void cameraRemove( index )
	local camera = GetCamera( self, index )
	if not camera then return end
	
	self.cameras[camera] = nil
	count[self.uid] = count[self.uid] - 1
	
	if camera.user then
		camera.user:SetFOV( 0, 0.01 )
		camera.user:SetViewEntity()
	end
	
	camera:Remove()
end

__e2setcost( 1 )
e2function void cameraRemoveAll()
	for ent,_ in pairs( self.cameras ) do
		self.prf = self.prf + 1/3
		if ent and ent:IsValid() then
			if ent.user then
				ent.user:SetFOV( 0, 0.01 )
				ent.user:SetViewEntity()
			end
			
			ent:Remove()
			count[self.uid] = count[self.uid] - 1
		end
	end
	self.cameras = {}
end

-----------------------------------------------------------------------
-- Other functions
-----------------------------------------------------------------------
__e2setcost( 2 )
e2function entity cameraEntity( number index )
	return GetCamera( self, index )
end

e2function number cameraRemainingSpawns()
	return max_convar:GetInt() - (count[self.uid] or 0)
end

__e2setcost( nil )