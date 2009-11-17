
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera Controller"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self.Entity, {"On", "X", "Y", "Z"})
	self.Active = 0
	self.OriginalOwner = nil
	self.CamEnt = nil
	self.CamPlayer = nil
	self.CamPod = nil
	self.ZoomAmount = 0
	self.OriginalFOV = 0
	self.Static = 0
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
	cam:SetColor(0, 0, 0, 0)
	cam:Spawn()

	cam:CallOnRemove("wire_cam_restore", function(oldcam) self:MakeDynamicCam(oldcam) end)

	self.CamEnt = cam

	if oldcam then
		self:TriggerInput("Activated", self.Active)
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
		self.Inputs = WireLib.CreateSpecialInputs(self.Entity, {"Activated", "Zoom", "X", "Y", "Z", "Pitch", "Yaw", "Roll", "Angle", "Position", "Direction", "Velocity", "Parent"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "ANGLE", "VECTOR", "VECTOR", "VECTOR", "ENTITY"})
	else
		local cam = ents.Create("prop_physics")
		if (!cam:IsValid()) then return false end

		cam:SetAngles( Angle(0,0,0) )
		cam:SetPos( self:GetPos()+Vector(0,0,64) )
		cam:SetModel( Model("models/dav0r/camera.mdl") )
		cam:Spawn()

		self.CamEnt = cam

		self.Inputs = Wire_CreateInputs(self.Entity, {"Activated", "Zoom"})
		self.Static = 1
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	local vStart = self.CamEnt:GetPos()
	local vForward = self.CamEnt:GetForward()

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * 100000)
	trace.filter = { self.CamEnt }
	local trace = util.TraceLine( trace )

	if trace.HitPos then
		Wire_TriggerOutput(self.Entity, "X", trace.HitPos.x)
		Wire_TriggerOutput(self.Entity, "Y", trace.HitPos.y)
		Wire_TriggerOutput(self.Entity, "Z", trace.HitPos.z)
	else
		Wire_TriggerOutput(self.Entity, "X", 0)
		Wire_TriggerOutput(self.Entity, "Y", 0)
		Wire_TriggerOutput(self.Entity, "Z", 0)
	end

	self.Entity:NextThink(CurTime()+0.1)
	return true
end

function ENT:OnRemove()
	if self.CamEnt and self.CamEnt:IsValid() then
		self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
		self.CamEnt:Remove()
	end

	if self.Active == 1 then
		self.CamPlayer:SetViewEntity(self.CamPlayer)
	end
	Wire_Remove(self.Entity)
end

function ENT:TriggerInput(iname, value)
	if iname == "Activated" then
		if value == 0 then
			self.Active = 0
			Wire_TriggerOutput(self.Entity, "On", 0)
			if not ValidEntity(self.CamPlayer) then return end
			self.CamPlayer:SetViewEntity(self.CamPlayer)
			self.CamPlayer:SetFOV(self.OrginialFOV, 0.01)
		else
			if self.CamPod then
				if self.CamPod:GetDriver() and self.CamPod:GetDriver():IsValid() then
					self.CamPlayer = self.CamPod:GetDriver()
				else
					self.CamPlayer = self.OriginalOwner
				end
			end
			self.CamPlayer:SetViewEntity(self.CamEnt)
			self.CamPlayer:SetFOV(self.ZoomAmount, 0.01)
			self.Active = 1
			Wire_TriggerOutput(self.Entity, "On", 1)
		end
	elseif iname == "Zoom" /* and not self.RT */ then
		self.ZoomAmount = math.Clamp(value, 1, self.OriginalFOV)
		if self.Active == 1 then
			self.CamPlayer:SetFOV(self.ZoomAmount, 0.01) -- TODO: RT camera
		end
	else
		if self.CamEnt then
			self.CamEnt:ReceiveInfo(iname, value)
		end
	end
end

function ENT:ShowOutput()
	local text = "Wired Camera"
	self:SetOverlayText( text )
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

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
		if ValidEntity(self.CamEnt) then
			self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
			self.CamEnt:Remove()
		end
		self.CamEnt = GetEntByID(info.cam)
		if not self.CamEnt then
			self.CamEnt = ents.GetByIndex(info.cam)
		end
	end
end
