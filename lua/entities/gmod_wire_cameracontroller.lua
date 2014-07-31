AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Camera Controller"
ENT.WireDebugName	= "Camera Controller"

if CLIENT then

	--------------------------------------------------
	-- Camera controller
	-- Clientside
	--------------------------------------------------

	local enabled = false
	local self
	
	local clientprop
	
	-- Position
	local pos = Vector(0,0,0)
	local smoothpos = Vector(0,0,0)
	
	-- Distance & zooming
	local distance = 0
	local curdistance = 0
	local oldcurdistance = 0
	local smoothdistance = 0
	
	local zoomdistance = 0
	local zoombind = 0
	
	-- Angle
	local ang = Angle(0,0,0)
	local smoothang = Angle(0,0,0)
	
	local oldeyeang = Angle(0,0,0)
	
	-- Options
	local ParentLocal = false
	local AutoMove = false
	local LocalMove = false
	local AutoUnclip = false
	local AllowZoom = false
	local DrawPlayer = true
	
	-- View calculations
	local max = math.max
	local abs = math.abs
	
	local pos_speed_convar = GetConVar( "wire_cam_smooth_amount" )
	
	local function GetParent()
		local parent
		
		local HasParent = self:GetNWBool( "HasParent", false )
		if HasParent then
			local p = self:GetNWEntity( "Parent" )
			if IsValid( p ) then
				parent = p
			end
		end
		
		local ValidParent = IsValid( parent )
		
		return parent, HasParent, ValidParent
	end
	
	local function DoAutoMove( curpos, curang, curdistance, parent, HasParent, ValidParent )
		local pos_speed = pos_speed_convar:GetFloat()
		local ang_speed = pos_speed - 2
	
		curang = LocalPlayer():EyeAngles()
		
		if AllowZoom then
			if zoombind ~= 0 then
				zoomdistance = math.Clamp(zoomdistance + zoombind * max((abs(curdistance) + abs(zoomdistance))/10,10),0,16000-curdistance)
				zoombind = 0
			end
			curdistance = curdistance + zoomdistance
		end
		
		smoothdistance = Lerp( FrameTime() * pos_speed, smoothdistance, curdistance )
					
		if HasParent and ValidParent then
			if LocalMove then
				curpos = parent:LocalToWorld( curpos - curang:Forward() * smoothdistance )
				curang = parent:LocalToWorldAngles( curang )
			else
				curpos = parent:LocalToWorld( curpos ) - curang:Forward() * smoothdistance
			end
		else
			curpos = curpos - curang:Forward() * smoothdistance
		end
		
		return curpos, curang
	end
	
	local function DoAutoUnclip( curpos, parent, HasParent, ValidParent )
		local start, endpos
		
		if not AutoMove then
			if HasParent and ValidParent then
				start = parent:GetPos()
			else
				start = self:GetPos()
			end
			
			endpos = curpos
		else
			if HasParent and ValidParent then
				start = parent:LocalToWorld(pos)
			else
				start = pos
			end
			
			endpos = curpos
		end
	
		local tr = {
			start = start,
			endpos = endpos,
			mask = bit.bor(MASK_WATER, CONTENTS_SOLID),
			mins = Vector(-8,-8,-8),
			maxs = Vector(8,8,8)
		}
		
		local trace = util.TraceHull( tr )
		
		if trace.Hit then
			return trace.HitPos
		end
		
		return curpos
	end
	
	hook.Remove("CalcView","wire_camera_controller_calcview")
	hook.Add( "CalcView", "wire_camera_controller_calcview", function()
		if not enabled then return end
		if not IsValid( self ) then enabled = false return end
			
		local pos_speed = pos_speed_convar:GetFloat()
		local ang_speed = pos_speed - 2
		
		local curpos = pos
		local curang = ang
		local curdistance = distance
		
		local parent, HasParent, ValidParent = GetParent()
		
		local newview = {}
		
		-- AutoMove
		if AutoMove then
			-- only smooth the position, and do it before the automove
			smoothpos = LerpVector( FrameTime() * pos_speed, smoothpos, curpos )
		
			curpos, curang = DoAutoMove( smoothpos, curang, curdistance, parent, HasParent, ValidParent )
			
			if AutoUnclip then
				curpos = DoAutoUnclip( curpos, parent, HasParent, ValidParent )
			end
			
			-- apply view
			newview.origin = curpos
			newview.angles = curang
		elseif HasParent and ValidParent then			
			-- smooth BEFORE using toWorld
			smoothpos = LerpVector( FrameTime() * pos_speed, smoothpos, curpos )
			smoothang = LerpAngle( FrameTime() * ang_speed, smoothang, curang )
			
			-- now toworld it
			curpos = parent:LocalToWorld( smoothpos )
			curang = parent:LocalToWorldAngles( smoothang )
			
			-- now check for auto unclip
			if AutoUnclip then
				curpos = DoAutoUnclip( curpos, parent, HasParent, ValidParent )
			end
			
			-- apply view
			newview.origin = curpos
			newview.angles = curang
		else
			-- check auto unclip first
			if AutoUnclip then
				curpos = DoAutoUnclip( curpos, parent, HasParent, ValidParent )
			end
		
			-- there's no parent, just smooth it
			smoothpos = LerpVector( FrameTime() * pos_speed, smoothpos, curpos )
			smoothang = LerpAngle( FrameTime() * ang_speed, smoothang, curang )
			newview.origin = smoothpos
			newview.angles = smoothang
		end
		
		newview.drawviewer = DrawPlayer -- this doesn't work (probably because I use SetViewEntity serverside)
		return newview
	end)
	
	-- calcview.drawviewer doesn't work, probably because I use SetViewEntity serverside, so I do this to fix that
	hook.Add( "PrePlayerDraw", "wire_camera_controller_preplayerdraw", function( ply )
		if enabled and not DrawPlayer and ply == LocalPlayer() then return true end
	end )
	
	hook.Add("PlayerBindPress", "wire_camera_controller_zoom", function(ply, bind, pressed)
		if enabled and AllowZoom then
			if (bind == "invprev") then
				zoombind = -1
				return true
			elseif (bind == "invnext") then
				zoombind = 1
				return true
			end
		end
	end)
	
	--------------------------------------------------
	-- Receiving data from server
	--------------------------------------------------
	
	local function ReadPositions()
		-- pos/ang
		pos.x = net.ReadFloat()
		pos.y = net.ReadFloat()
		pos.z = net.ReadFloat()
		ang.p = net.ReadFloat()
		ang.y = net.ReadFloat()
		ang.r = net.ReadFloat()
		
		-- distance
		distance = math.Clamp(net.ReadFloat(),-16000,16000)
	end
	
	net.Receive( "wire_camera_controller_toggle", function( len )
		local enable = net.ReadBit() ~= 0
		local cam = net.ReadEntity()
		
		if cam ~= self and enabled then return end -- another camera controller is already enabled
		
		self = cam
		
		if enable then
			ParentLocal = net.ReadBit() ~= 0
			AutoMove = net.ReadBit() ~= 0
			LocalMove = net.ReadBit() ~= 0
			AllowZoom = net.ReadBit() ~= 0
			AutoUnclip = net.ReadBit() ~= 0
			DrawPlayer = net.ReadBit() ~= 0
			ReadPositions()
			
			-- If we switched on, set current positions and angles
			if not enabled then
				-- Copy them
				curpos = Vector(pos.x,pos.y,pos.z)
				curang = Angle(ang.p,ang.y,ang.r)
				smoothpos = Vector(pos.x,pos.y,pos.z)
				smoothang = Angle(ang.p,ang.y,ang.r)
				curdistance = distance
				smoothdistance = distance
				zoomdistance = 0
				
				--[[ ******************
					This is a hack to solve the issue of the parent entity being invisible, due to 
					the fact that ply:SetViewEntity( parent ) must be used serverside
					in order to be able to move through visleafs
					
					SetViewEntity makes the entity invisible for some reason, so this renders it again
					using a client side model.
				]]
				
				local parent, HasParent, ValidParent = GetParent()
				if HasParent and ValidParent then
					clientprop = ClientsideModel( parent:GetModel(), parent:GetRenderGroup() )
					clientprop:SetPos( parent:GetPos() )
					clientprop:SetAngles( parent:GetAngles() )
					clientprop:SetParent( parent )
					clientprop:DrawShadow( false ) -- shadow is already drawn by parent
					parent:CallOnRemove( "CamController.RemoveClientProp", function()
						if IsValid( clientprop ) then
							clientprop:Remove()
						end
					end )
				end
			end
		elseif enabled then
			if IsValid( clientprop ) then
				clientprop:Remove()
			end
		end
		--[[ ****************** ]]
		
		enabled = enable
	end)
	
	function ENT:Draw()
		self.BaseClass.Draw( self )
		
		if enabled then
			local parent, HasParent, ValidParent = GetParent()
			if parent.Draw then parent:Draw()
			elseif parent.DrawModel then parent:DrawModel() end
		end		
	end
	
	net.Receive( "wire_camera_controller_sync", function( len )
		if not enabled or not IsValid( self ) then return end
		local cam = net.ReadEntity()
		if cam ~= self then return end -- another cam controller is trying to hijack us
		
		ReadPositions()
	end)
	
	return -- No more client
end

--------------------------------------------------
-- Initialize
--------------------------------------------------

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Outputs = WireLib.CreateOutputs( self, { 	"On", "HitPos [VECTOR]", "CamPos [VECTOR]", "CamDir [VECTOR]", 
													"CamAng [ANGLE]", "Trace [RANGER]" } )
	self.Inputs = WireLib.CreateInputs( self, {	"Activated", "Direction [VECTOR]", "Angle [ANGLE]", "Position [VECTOR]",
												"Distance", "Parent [ENTITY]", "FLIR", "FOV" } )

	self.Activated = false -- Whether or not to activate the cam controller for all players sitting in linked vehicles, or as soon as a player sits in a linked vehicle
	self.Active = false -- Whether the player is currently being shown the camera view.
	self.FOV = nil -- The FOV of the player's view. (By default, do not change the FOV.)
	self.FLIR = false -- Whether infrared view is turned on.
	
	self.Position = Vector(0,0,0)
	self.Angle = Angle(0,0,0)
	self.Distance = 0
	
	self.Players = {}
	self.Vehicles = {}
	
	self.NextSync = 0
	self.NextGetContraption = 0
	self.NextUpdateOutputs = 0
	
	self:GetContraption()
end

--------------------------------------------------
-- Setup
--------------------------------------------------

function ENT:Setup(ParentLocal,AutoMove,LocalMove,AllowZoom,AutoUnclip,DrawPlayer)
	self.ParentLocal = tobool(ParentLocal)
	self.AutoMove = tobool(AutoMove)
	self.LocalMove = tobool(LocalMove)
	self.AllowZoom = tobool(AllowZoom)
	self.AutoUnclip = tobool(AutoUnclip)
	self.DrawPlayer = tobool(DrawPlayer)
	self:SyncSettings()
end

--------------------------------------------------
-- Data sending
--------------------------------------------------

local function SendPositions( pos, ang, dist )
	-- pos/ang
	net.WriteFloat( pos.x )
	net.WriteFloat( pos.y )
	net.WriteFloat( pos.z )
	net.WriteFloat( ang.p )
	net.WriteFloat( ang.y )
	net.WriteFloat( ang.r )
	
	-- distance
	net.WriteFloat( dist )
end

util.AddNetworkString( "wire_camera_controller_toggle" )
function ENT:SyncSettings( ply, active )
	if active == nil then active = self.Active end
	net.Start( "wire_camera_controller_toggle" )
		net.WriteBit( active )
		net.WriteEntity( self )
		if self.Active then
			net.WriteBit( self.ParentLocal )
			net.WriteBit( self.AutoMove )
			net.WriteBit( self.LocalMove )
			net.WriteBit( self.AllowZoom )
			net.WriteBit( self.AutoUnclip )
			net.WriteBit( self.DrawPlayer )
			SendPositions( self.Position, self.Angle, self.Distance )
		end
	if #self.Vehicles == 0 then self.Players[1] = self:GetPlayer() end
	net.Send( ply or self.Players )
end


util.AddNetworkString( "wire_camera_controller_sync" )
function ENT:SyncPositions( ply )
	if CurTime() < self.NextSync then return end
	
	self.NextSync = CurTime() + 0.05
	
	net.Start( "wire_camera_controller_sync" )
		net.WriteEntity( self )
		SendPositions( self.Position, self.Angle, self.Distance )
	if #self.Vehicles == 0 then self.Players[1] = self:GetPlayer() end
	net.Send( ply or self.Players )
end


--------------------------------------------------
-- GetContraption
-- Used in UpdateOutputs to make the traces ignore the contraption
--------------------------------------------------
function ENT:GetContraption()
	if CurTime() < self.NextGetContraption then return end
	self.NextGetContraption = CurTime() + 5
	
	self.Entities = {}
	
	local parent = self
	if IsValid( self.Parent ) then parent = self.Parent end
	
	local ents = constraint.GetAllConstrainedEntities( parent )
	for k,v in pairs( ents ) do
		self.Entities[#self.Entities+1] = v
	end
end

--------------------------------------------------
-- UpdateOutputs
--------------------------------------------------
function ENT:UpdateOutputs()
	if CurTime() < self.NextUpdateOutputs then return end
	self.NextUpdateOutputs = CurTime() + 0.1
	
	local ply = self.Players[1]
	
	if self.Active and IsValid( ply ) then
		local HasParent = self:GetNWBool( "HasParent", false )
		local parent = self:GetNWEntity( "Parent" )
		local ValidParent = IsValid( parent )

		local pos, ang = self.Position, self.Angle
		
		local curpos = pos
		local curang = ang
		
		if self.AutoMove then
			curang = ply:EyeAngles()
			local veh = ply:GetVehicle()
			if IsValid( veh ) then curang = veh:WorldToLocalAngles( curang ) end
			
			local dist = self.Distance
			
			if HasParent and IsValid( parent ) then
				if self.LocalMove then
					curpos = parent:LocalToWorld( curpos - curang:Forward() * dist )
					curang = parent:LocalToWorldAngles( curang )
				else
					curpos = parent:LocalToWorld( curpos ) - curang:Forward() * dist
				end
			else
				curpos = curpos - curang:Forward() * dist
			end
		else
			if HasParent and ValidParent then
				curpos = parent:LocalToWorld( curpos )
				curang = parent:LocalToWorldAngles( curang )
			end
		end
		
		-- AutoUnclip
		if self.AutoUnclip then
			local start, endpos
			
			if not self.AutoMove then
				if HasParent and ValidParent then
					start = parent:GetPos()
				else
					start = self:GetPos()
				end
				
				endpos = curpos
			else
				if HasParent and ValidParent then
					start = parent:LocalToWorld(pos)
				else
					start = pos
				end
				
				endpos = curpos
			end
		
			local tr = {
				start = start,
				endpos = endpos,
				mask = bit.bor(MASK_WATER, CONTENTS_SOLID),
				mins = Vector(-8,-8,-8),
				maxs = Vector(8,8,8)
			}
			
			local trace = util.TraceHull( tr )
			
			if trace.Hit then
				curpos = trace.HitPos
			end
		end
		
		local trace = util.TraceLine({start=curpos,endpos=curpos+curang:Forward()*999999999,filter=self.Entities})
		local hitPos = trace.HitPos or Vector(0,0,0)
		
		if self.OldDupe then
			WireLib.TriggerOutput(self, "X", hitPos.x)
			WireLib.TriggerOutput(self, "Y", hitPos.y)
			WireLib.TriggerOutput(self, "Z", hitPos.z)
		end
		
		WireLib.TriggerOutput(self,"HitPos",hitPos)
		WireLib.TriggerOutput(self,"CamPos",curpos)
		WireLib.TriggerOutput(self,"CamDir",curang:Forward())
		WireLib.TriggerOutput(self,"CamAng",curang)
		WireLib.TriggerOutput(self,"Trace",trace)
	else
		if self.OldDupe then
			WireLib.TriggerOutput(self, "X", 0)
			WireLib.TriggerOutput(self, "Y", 0)
			WireLib.TriggerOutput(self, "Z", 0)
		end
		
		WireLib.TriggerOutput(self,"HitPos", Vector(0,0,0))
		WireLib.TriggerOutput(self,"CamPos",Vector(0,0,0))
		WireLib.TriggerOutput(self,"CamDir",Vector(0,0,0))
		WireLib.TriggerOutput(self,"CamAng",Angle(0,0,0))
		WireLib.TriggerOutput(self,"Trace",nil)
	end
end

--------------------------------------------------
-- Think
--------------------------------------------------
function ENT:Think()
	self.BaseClass.Think(self)
	
	if self.NeedsSync then
		self.NeedsSync = nil
		self:SyncPositions()
	end
	
	self:GetContraption()
	self:UpdateOutputs()
	
	self:NextThink(CurTime())
	return true
end

--------------------------------------------------
-- OnRemove
--------------------------------------------------

function ENT:OnRemove()
	if IsValid( self.Parent ) then
		self.Parent:RemoveCallOnRemove( "wire_camera_controller_remove_parent" )
	end
	
	self:ClearEntities()
end

--------------------------------------------------
-- DisableCam
--------------------------------------------------

function ENT:DisableCam( ply )
	if #self.Vehicles == 0 and not ply then -- if the cam controller isn't linked, it controls the owner's view
		ply = self:GetPlayer()
	end
	
	self:SetFOV( ply, false )
	self:SetFLIR( ply, false )
		
	self:SyncSettings( ply, false )
	
	if IsValid( ply ) then
		for i=1,#self.Players do
			if self.Players[i] == ply then
				table.remove( self.Players, i )
				break
			end
		end
		
		-- Unhook the SetViewEntity hack
		ply:SetViewEntity()
		
		ply.CamController = nil
	else
		-- Unhook the SetViewEntity hack for all players
		for i=1,#self.Players do
			if IsValid( self.Players[i] ) then
				self.Players[i]:SetViewEntity()
			end
		end
		
		self.Players = {}
	end
		
	if #self.Players == 0 then
		WireLib.TriggerOutput(self, "On", 0)
		self.Active = false
	end
end

--------------------------------------------------
-- EnableCam
--------------------------------------------------

function ENT:EnableCam( ply )
	if #self.Vehicles == 0 and not ply then -- if the cam controller isn't linked, it controls the owner's view
		ply = self:GetPlayer()
	end
	
	if IsValid( ply ) then
		for i=1,#self.Players do
			if self.Players[i] == ply then return end -- check if this player is already active
		end
	
		self.Players[#self.Players+1] = ply
		ply.CamController = self
		
		self:SetFOV( ply )
		self:SetFLIR( ply )
		
		WireLib.TriggerOutput(self, "On", 1)
		self.Active = true
		
		-- SetViewEntity fixes the problem where the camera would get stuck if you fly through a PVS edge
		-- this is a hack since isn't actually used, because we're overriding it with CalcView
		if IsValid( self.Parent ) then ply:SetViewEntity( self.Parent )	end
		
		self:SyncSettings( ply )
	else -- No player specified, activate cam for everyone not already active
		local lookup = {}
		for i=1,#self.Players do lookup[self.Players[i]] = true end
		
		for i=#self.Vehicles,1,-1 do
			local veh = self.Vehicles[i]
			if IsValid( veh ) then
				local ply = veh:GetDriver()
				if IsValid( ply ) then
					if not lookup[ply] then
						self:EnableCam( ply )
					end
				end
			else
				self:UnlinkEnt( veh )
			end
		end
	end		
end

--------------------------------------------------
-- SetFOV
--------------------------------------------------

function ENT:SetFOV( ply, b )
	if b == nil then b = self.FOV ~= nil end
	
	if IsValid( ply ) then
		if b then
			if not ply.DefaultFOV then
				ply.DefaultFOV = ply:GetFOV()
			end
			
			if ply:GetFOV() ~= self.FOV then
				ply:SetFOV( self.FOV, 0.01 )
			end
		elseif ply.DefaultFOV then
			if ply:GetFOV() ~= ply.DefaultFOV then
				ply:SetFOV( ply.DefaultFOV, 0.01 )
			end
			ply.DefaultFOV = nil
		end
	else
		for i=#self.Players,1,-1 do
			local ply = self.Players[i]
			if IsValid(ply) then
				self:SetFOV( ply, b, 0.01 )
			else
				table.remove( self.Players, i )
			end
		end
	end
end

--------------------------------------------------
-- SetFLIR
--------------------------------------------------

function ENT:SetFLIR( ply, b )
	if b == nil then b = self.FLIR end
	
	if IsValid( ply ) then
		if b then
			FLIR.start( ply )
		else
			FLIR.stop( ply )
		end
	else
		for i=#self.Players,1,-1 do
			local ply = self.Players[i]
			if IsValid(ply) then
				self:SetFLIR( ply, b )
			else
				table.remove( self.Players, i )
			end
		end
	end
end

--------------------------------------------------
-- LocalizePositions
--------------------------------------------------

function ENT:LocalizePositions(b)
	if self.ParentLocal then return end
	-- Localize the position if we have a parent
	if self:GetNWBool( "HasParent", false ) then
		local parent = self:GetNWEntity( "Parent" )
		if IsValid( parent ) then
			if b then
				self.Position = parent:WorldToLocal( self.Position )
				self.Angle = parent:WorldToLocalAngles( self.Angle )
			else
				self.Position = parent:LocalToWorld( self.Position )
				self.Angle = parent:LocalToWorldAngles( self.Angle )
			end
		end
	end
end

--------------------------------------------------
-- TriggerInput
--------------------------------------------------

function ENT:TriggerInput( name, value )
	if name == "Activated" then
		self.Activated = value ~= 0
		if value ~= 0 then self:EnableCam() else self:DisableCam() end
		return
	elseif name == "Zoom" or name == "FOV" then
		self.FOV = math.Clamp( value, 1, 90 )
		self:SetFOV()
		return
	elseif name == "FLIR" then
		self.FLIR = value ~= 0
		self:SetFLIR()
		return
	else
		self:LocalizePositions(false)
		
		if name == "Parent" then
			if IsValid( self.Parent ) then
				self.Parent:RemoveCallOnRemove( "wire_camera_controller_remove_parent" )
			end
			
			self.Parent = value
			self:SetNWEntity( "Parent", value )
			self:SetNWBool( "HasParent", IsValid(value) )
			
			if IsValid( self.Parent ) and self.Parent ~= self then
				self.Parent:CallOnRemove( "wire_camera_controller_remove_parent", function()
					self:SetNWBool( "HasParent", false )
				end)
			end
		elseif name == "Position" then
			self.Position = value
		elseif name == "Distance" then
			self.Distance = value
		elseif name == "Direction" then
			self.Angle = value:Angle()
		elseif name == "Angle" then
			self.Angle = value
		elseif name == "X" then
			self.Position.x = value
		elseif name == "Y" then
			self.Position.y = value
		elseif name == "Z" then
			self.Position.z = value
		elseif name == "Pitch" then
			self.Angle.p = value
		elseif name == "Yaw" then
			self.Angle.y = value
		elseif name == "Roll" then
			self.Angle.r = value
		end
	
		self:LocalizePositions(true)
		if name ~= "Parent" then self.NeedsSync = true end
	end
end

--------------------------------------------------
-- Enter/exit vehicle hooks
--------------------------------------------------

hook.Add("PlayerEnteredVehicle", "gmod_wire_cameracontroller", function(player, vehicle)
	if IsValid(vehicle.CamController) and vehicle.CamController.Activated then
		vehicle.CamController:EnableCam( player )
	end
end)
hook.Add("PlayerLeaveVehicle", "gmod_wire_cameracontroller", function(player, vehicle)
	if IsValid(vehicle.CamController) and vehicle.CamController.Activated then
		vehicle.CamController:DisableCam( player )
	end
end)

--------------------------------------------------
-- Leave camera manually
--------------------------------------------------
concommand.Add( "wire_cameracontroller_leave", function(player)
	if IsValid(player.CamController) then
		player.CamController:DisableCam( player )
	end
end)

--------------------------------------------------
-- Linking to vehicles
--------------------------------------------------

function ENT:UpdateMarks()
	WireLib.SendMarks(self,self.Vehicles)
end

function ENT:ClearEntities()
	self:DisableCam()
	
	for i=1,#self.Vehicles do
		self.Vehicles[i]:RemoveCallOnRemove( "wire_camera_controller_remove_pod" )
		self.Vehicles[i].CamController = nil
	end
	
	self.Vehicles = {}
	self:UpdateMarks()
	return true
end

function ENT:LinkEnt(pod)
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	for i=1,#self.Vehicles do
		if self.Vehicles[i] == pod then
			return false
		end
	end
	
	pod.CamController = self
	pod:CallOnRemove( "wire_camera_controller_remove_pod", function()
		self:UnlinkEnt( pod )
	end)
	
	self.Vehicles[#self.Vehicles+1] = pod
	self.Players = {}
	
	if IsValid( pod:GetDriver() ) then
		self:EnableCam( pod:GetDriver() )
	end
	
	self:UpdateMarks()
	return true
end

function ENT:UnlinkEnt(pod)
	local idx = 0
	for i=1,#self.Vehicles do
		if self.Vehicles[i] == pod then
			idx = i
			break
		end
	end
	if idx == 0 then return false end
	
	if IsValid( pod:GetDriver() ) then
		self:DisableCam( pod:GetDriver() )
	end
	
	pod:RemoveCallOnRemove( "wire_camera_controller_remove_pod" )
	table.remove( self.Vehicles, idx )
	pod.CamController = nil
	
	self:UpdateMarks()
	return true
end

--------------------------------------------------
-- Dupe support
--------------------------------------------------

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self)
	local veh = {}
	for i=1,#self.Vehicles do
		veh[i] = self.Vehicles[i]:EntIndex()
	end
	info.Vehicles = veh
	
	info.OldDupe = self.OldDupe
	
	-- Other options are saved using duplicator.RegisterEntityClass
	
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	
	if info.cam or info.pod or info.OldDupe then -- OLD DUPE DETECTED
		if info.cam then
			local CamEnt = GetEntByID( info.cam )
			if IsValid( CamEnt ) then CamEnt:Remove() end
		end
	
		if info.pod then
			self.Vehicles[1] = GetEntByID( info.pod )
		end
						
		WireLib.AdjustSpecialInputs( self, {	"Activated", "X", "Y", "Z", "Pitch", "Yaw", "Roll",
												"Angle [ANGLE]", "Position [VECTOR]", "Distance", "Direction [VECTOR]",
												"Parent [ENTITY]", "FLIR", "FOV" } )
		
		WireLib.AdjustSpecialOutputs( self, { 	"On", "X", "Y", "Z", "HitPos [VECTOR]", 
												"CamPos [VECTOR]", "CamDir [VECTOR]", "CamAng [ANGLE]", 
												"Trace [RANGER]" } )
		
		self.OldDupe = true
	else
		local veh = info.Vehicles
		if veh then
			for i=1,#veh do
				self:LinkEnt( GetEntByID( veh[i] ) )
			end
		end
	end
	
	timer.Simple( 0.1, function() if IsValid( self ) then self:UpdateMarks() end end ) -- timers solve everything (the entity isn't valid on the client at first, so we wait a bit)
end

WireLib.AddInputAlias( "Zoom", "FOV" )
WireLib.AddOutputAlias( "XYZ", "HitPos" )

duplicator.RegisterEntityClass("gmod_wire_cameracontroller", WireLib.MakeWireEnt, "Data", "ParentLocal","AutoMove","LocalMove","AllowZoom","AutoUnclip","DrawPlayer")
