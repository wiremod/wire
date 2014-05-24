AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Camera Controller"
ENT.WireDebugName	= "Camera Controller"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Outputs = WireLib.CreateOutputs( self, { "On", "X", "Y", "Z", "XYZ [VECTOR]" } )

	self.CamPlayer = self:GetPlayer() -- The player being shown the camera view.

	self.Active = false -- Whether the player is currently being shown the camera view.
	self.FOV = nil -- The FOV of the player's view. (By default, do not change the FOV.)
	self.Static = false -- Whether the camera controller has a separate camera entity.
	self.FLIR = false -- Whether infrared view is turned on.
end

function ENT:MakeCamera(oldcam)
	local cam = ents.Create(self.Static and "prop_physics" or "base_point")

	if not IsValid(cam) then return false end

	if self.Static then
		cam:SetModel(Model("models/dav0r/camera.mdl"))
	else
		-- By default, base_point isn't sent to the client.
		cam.UpdateTransmitState = function() return TRANSMIT_PVS end
	end

	if IsValid(oldcam) then
		cam:SetPos(oldcam:GetPos())
		cam:SetAngles(oldcam:GetAngles())
	else
		local offset = self.Static and (self:GetAngles():Up() * 64) or Vector()
		cam:SetPos( self:GetPos() + offset )
		cam:SetAngles( self:GetAngles() )
	end

	cam:Spawn()
	cam:Activate()

	if self.Static then constraint.NoCollide(self, cam, 0, 0) end

	-- If the camera is ever deleted by the user, we immediately recreate it
	cam:CallOnRemove(self:GetClass() .. self:EntIndex(), function(ent)
		if IsValid(self) then
			self:MakeCamera(ent)
			self:EnableCam(false)
		end
	end)

	self:TriggerInput("Activated", 0)
	self.CamEnt = cam
	self:UpdateMarks()
	return cam
end

function ENT:Setup(Static, ParentLocal)
	self.Static = tobool(Static)
	self.ParentLocal = tobool(ParentLocal)

	if not IsValid(self.CamEnt) then self:MakeCamera() end
	if not IsValid(self.CamEnt) then return false end

	if self.Static then
		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom (1-90)", "FLIR" } )
	else
		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom (1-90)", "X", "Y", "Z", "Pitch", "Yaw", "Roll",
		                                            "Angle [ANGLE]", "Position [VECTOR]", "Direction [VECTOR]",
		                                            "Parent [ENTITY]", "FLIR" } )
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if not IsValid(self.CamEnt) then self:MakeCamera() end

	local trace = util.QuickTrace(self.CamEnt:GetPos(), self.CamEnt:GetForward(), self.CamEnt)
	local hitPos = trace.HitPos or Vector()

	WireLib.TriggerOutput(self, "XYZ", hitPos)
	WireLib.TriggerOutput(self, "X", hitPos.x)
	WireLib.TriggerOutput(self, "Y", hitPos.y)
	WireLib.TriggerOutput(self, "Z", hitPos.z)

	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:OnRemove()
	self:EnableCam(false)

	if IsValid(self.CamEnt) then
		self.CamEnt:RemoveCallOnRemove(self:GetClass() .. self:EntIndex())
		self.CamEnt:Remove()
	end

	self.BaseClass.OnRemove(self)
end

function ENT:EnableCam(enabled)
	if enabled and not self.Active then
		self.CamPlayer = IsValid(self.CamPod) and self.CamPod:GetDriver()
		if not IsValid(self.CamPlayer) then self.CamPlayer = self:GetPlayer() end
		if not IsValid(self.CamPlayer) then return end
		-- We allow cam controllers to override other view entities, but not each other
		if self.CamPlayer:GetViewEntity():GetClass() == self:GetClass then return end
		
		self.CamPlayer.OriginalFOV = self.CamPlayer:GetFOV()
		self.CamPlayer.OriginalView = self.CamPlayer:GetViewEntity()
		self.CamPlayer:SetViewEntity(self.CamEnt)
		self:UpdateCam()
	elseif self.Active and not enabled then
		if not IsValid(self.CamPlayer) or self.CamPlayer:GetViewEntity() ~= self.CamEnt then return end
		self.CamPlayer:SetFOV(self.CamPlayer.OriginalFOV or 75, 0.01)
		self.CamPlayer:SetViewEntity(self.CamPlayer.OriginalView or self.CamPlayer)
		self.CamPlayer.OriginalFOV = nil
		self.CamPlayer.OriginalView = nil
		self.CamPlayer = nil
	end
	
	self.Active = enabled
	WireLib.TriggerOutput(self, "On", self.Active and 1 or 0)
end

function ENT:UpdateCam()
	if not IsValid(self.CamPlayer) then return end
	FLIR.enable(self.CamPlayer, self.FLIR)
	self.CamPlayer:SetFOV( self.FOV or self.CamPlayer.OriginalFOV or 75, 0.01 )
	
end

function ENT:TriggerInput( name, value )
	if name == "Activated" then
		value = tobool(value)
		if value and IsValid(self.CamPod) then
				self.CamPlayer = self.CamPod:GetDriver() or nil
		end
		self:EnableCam(value)
	elseif name == "Zoom" then
		self.FOV = value > 0 and math.Clamp( value, 1, 90 ) or nil
		self:UpdateCam()
	elseif name == "FLIR" then
		self.FLIR = tobool(value)
		self:UpdateCam()
	elseif name == "Direction" then
		self:TriggerInput("Angle", value:Angle())
	elseif IsValid(self.CamEnt) then
		local pos, ang = self.CamEnt:GetPos(), self.CamEnt:GetAngles()
		if IsValid(self.CamEnt:GetParent()) and self.ParentLocal then
			pos = self.CamEnt:GetParent():WorldToLocal(pos)
			ang = self.CamEnt:GetParent():WorldToLocalAngles(ang)
		end

		if name == "Parent" then
			self.CamEnt:SetParent(IsValid(value) and value or nil)
		elseif name == "Position" then pos = value
		elseif name == "Angle" then ang = value
		elseif name == "X" then pos.x = value
		elseif name == "Y" then pos.y = value
		elseif name == "Z" then pos.z = value
		elseif name == "Pitch" then ang.p = value
		elseif name == "Yaw" then ang.y = value
		elseif name == "Roll" then ang.r = value
		end

		if IsValid(self.CamEnt:GetParent()) and self.ParentLocal then
			pos = self.CamEnt:GetParent():LocalToWorld(pos)
			ang = self.CamEnt:GetParent():LocalToWorldAngles(ang)
		end
		self.CamEnt:SetPos(pos)
		self.CamEnt:SetAngles(ang)
	end
end

hook.Add("PlayerLeaveVehicle", "gmod_wire_cameracontroller", function(player, vehicle)
if player:GetViewEntity().CamPod == vehicle then
	player:GetViewEntity():EnableCam(false)
end)

concommand.Add( "wire_cameracontroller_leave", function(player)
	if player:GetViewEntity().EnableCam then player:GetViewEntity:EnableCam(false) end
end)

function ENT:UpdateMarks()
	self.Marks = {}
	if IsValid(self.CamPod) then table.insert(self.Marks, self.CamPod) end
	if self.Static and IsValid(self.CamEnt) then table.insert(self.Marks, self.CamEnt) end
	WireLib.SendMarks(self)
end

function ENT:LinkEnt(pod)
	if not IsValid(pod) or not pod:IsVehicle() then return "Must link to a vehicle" end
	self.CamPod = pod
	self:UpdateMarks()
	return true
end

function ENT:UnlinkEnt()
	self.CamPod = nil
	self:UpdateMarks()
	return true
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self)
	if IsValid(self.CamPod) then info.pod = self.CamPod:EntIndex() end
	if IsValid(self.CamEnt) and self.Static then info.cam = self.CamEnt:EntIndex() end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.CamPod = GetEntByID(info.pod)
	-- Setup is called before ApplyDupeInfo, so we will already have spawned
	-- a camera by the time we restore the duped camera.
	if IsValid(self.CamEnt) then
		self.CamEnt:RemoveCallOnRemove(self:GetClass() .. self:EntIndex())
		self.CamEnt:Remove()
	end

	self.CamEnt = GetEntByID(info.cam)
	self:UpdateMarks()
end

duplicator.RegisterEntityClass("gmod_wire_cameracontroller", WireLib.MakeWireEnt, "Data", "Static", "ParentLocal")
