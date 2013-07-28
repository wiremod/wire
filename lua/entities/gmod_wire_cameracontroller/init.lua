
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera Controller"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = WireLib.CreateOutputs( self, { "On", "X", "Y", "Z", "XYZ [VECTOR]" } )

	self.Activated = 0 -- User defined
	self.Active = false -- Actual status
	self.ZoomAmount = 0
	self.OriginalFOV = 0
	self.Static = 0
	self.FLIREnabled = false
	self.FLIR = 0
end

function ENT:MakeDynamicCam(oldcam)
	local cam = ents.Create("gmod_wire_cam") -- TODO: RT camera
	if not cam:IsValid() then return false end

	if oldcam then
		cam:SetAngles( oldcam:GetAngles() )
		cam:SetPos( oldcam:GetPos() )
	else
		cam:SetAngles( Angle(0, 0, 0) )
		cam:SetPos( self:GetPos() )
	end
	cam:SetModel( Model("models/props_junk/PopCan01a.mdl") )
	cam:SetNoDraw(true)
	cam:Spawn()

	cam:CallOnRemove("wire_cam_restore", function(oldcam) self:MakeDynamicCam(oldcam) end)

	self.CamEnt = cam

	if oldcam then
		self:TriggerInput("Activated", self.Activated)
	end
	return cam
end

function ENT:Setup(Player, Static)
	if Player and Player:IsValid() and Player:IsPlayer() then
		self.CamPlayer = Player
		self.OriginalOwner = Player
		self.OriginalFOV = self.CamPlayer:GetFOV()
	end

	if Static == 0 then
		if not self:MakeDynamicCam() then return false end
		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom", "X", "Y", "Z", "Pitch", "Yaw", "Roll",
													"Angle [ANGLE]", "Position [VECTOR]", "Direction [VECTOR]", "Velocity [VECTOR]", "Parent [ENTITY]", "FLIR" } )
	else
		local cam = ents.Create("prop_physics")
		if (!cam:IsValid()) then return false end

		cam:SetAngles( Angle(0,0,0) )
		cam:SetPos( self:GetPos()+Vector(0,0,64) )
		cam:SetModel( Model("models/dav0r/camera.mdl") )
		cam:Spawn()

		self.CamEnt = cam

		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom", "FLIR" } )
		self.Static = 1
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (!self.CamEnt or !self.CamEnt:IsValid()) then return end

	local vStart = self.CamEnt:GetPos()
	local vForward = self.CamEnt:GetForward()

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * 100000)
	trace.filter = { self.CamEnt }
	local trace = util.TraceLine( trace )

	if trace.HitPos then
		WireLib.TriggerOutput( self, "XYZ", trace.HitPos )
		WireLib.TriggerOutput(self, "X", trace.HitPos.x)
		WireLib.TriggerOutput(self, "Y", trace.HitPos.y)
		WireLib.TriggerOutput(self, "Z", trace.HitPos.z)
	else
		WireLib.TriggerOutput( self, "XYZ", Vector(0,0,0) )
		WireLib.TriggerOutput(self, "X", 0)
		WireLib.TriggerOutput(self, "Y", 0)
		WireLib.TriggerOutput(self, "Z", 0)
	end

	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:OnRemove()
	if self.CamEnt and self.CamEnt:IsValid() then
		self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
		self.CamEnt:Remove()
	end

	if self.Active then
		self:ToggleCam( false )
		self:ToggleFLIR( false )
	end
	Wire_Remove(self)
end

function ENT:ToggleFLIR( b )
	if (b != self.FLIREnabled) then
		if (self.CamPlayer and self.CamPlayer:IsValid()) then
			umsg.Start( "toggle_flir", self.CamPlayer )
				umsg.Bool( b )
			umsg.End()
			self.FLIREnabled = b
		end
	end
end

function ENT:ToggleCam( b )
	if (b != self.Active) then
		if (self.CamPlayer and self.CamPlayer:IsValid()) then
			if (b and self.CamEnt and self.CamEnt:IsValid()) then
				self.CamPlayer:SetViewEntity( self.CamEnt )
				self.CamPlayer:SetFOV( self.ZoomAmount, 0.01 )
				self.Active = true
			else
				self.CamPlayer:SetViewEntity( self.CamPlayer )
				self.CamPlayer:SetFOV( self.OriginalFOV, 0.01 )
				self.Active = false
			end
		end
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Activated") then
		self.Activated = value
		WireLib.TriggerOutput( self, "On", value )
		if (value == 0 and self.CamPlayer and self.CamPlayer:IsValid()) then
			self:ToggleCam( false )
			self:ToggleFLIR( false )
		else
			if IsValid(self.CamPod) then
				if self.CamPod.GetDriver and self.CamPod:GetDriver() and self.CamPod:GetDriver():IsValid() then
					self.CamPlayer = self.CamPod:GetDriver()
				else
					self.CamPlayer = self.OriginalOwner
				end
			end
			self:ToggleCam( true )
			self:ToggleFLIR( self.FLIR != 0 )
		end
	elseif (name == "Zoom") then
		self.ZoomAmount = math.Clamp( value, 1, self.OriginalFOV )
		if self.Active then
			self.CamPlayer:SetFOV(self.ZoomAmount, 0.01) -- TODO: RT camera
		end
	elseif (name == "FLIR") then
		self:ToggleFLIR( (self.Active and value != 0) )
		self.FLIR = value
	else
		if (self.CamEnt and self.CamEnt:IsValid()) then
			self.CamEnt:ReceiveInfo(name, value)
		end
	end
end

-- Detect players exiting the pod
hook.Add("PlayerLeaveVehicle","Wire_CamController_PlayerEnteredVehicle",function( ply, vehicle )
	for k,v in pairs( ents.FindByClass( "gmod_wire_cameracontroller" ) ) do
		if (v.CamPod and v.CamPod:IsValid() and v.CamPod == vehicle) then
			if (v.Active) then
				v:ToggleCam( false )
				v:ToggleFLIR( false )
				v.CamPlayer = v.OriginalOwner
			end
		end
	end
end)

local antispam = {}
concommand.Add( "wire_cameracontroller_leave", function( ply, cmd, args )
	if (!ply or !ply:IsValid()) then return end
	if (!antispam[ply]) then antispam[ply] = 0 end
	if (antispam[ply] > CurTime()) then
		ply:ChatPrint( "This command has a 5 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime()) .. " seconds.")
		return
	end
	antispam[ply] = CurTime() + 5

	local found = false
	for k,v in pairs( ents.FindByClass( "gmod_wire_cameracontroller" ) ) do
		if (v.CamPlayer and v.CamPlayer:IsValid() and v.CamPlayer == ply) then
			found = true
			v:ToggleCam( false )
			v:ToggleFLIR( false )
			v.CamPlayer = v.OriginalOwner
		end
	end
	if (!found) then
		ply:SetViewEntity( ply )
		umsg.Start( "toggle_flir", ply )
			umsg.Bool( false )
		umsg.End()
	end
end)

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if self.CamPod and self.CamPod:IsValid() then
		info.pod = self.CamPod:EntIndex()
	end
	if self.CamEnt and self.CamEnt:IsValid() and self.Static ~= 0 then
		info.cam = self.CamEnt:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if info.pod then
		self.CamPod = GetEntByID(info.pod)
		if not self.CamPod then
			self.CamPod = ents.GetByIndex(info.pod)
		end
	end
	if info.cam then
		if IsValid(self.CamEnt) then
			self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
			self.CamEnt:Remove()
		end
		self.CamEnt = GetEntByID(info.cam)
		if not self.CamEnt then
			self.CamEnt = ents.GetByIndex(info.cam)
		end
	end
end
