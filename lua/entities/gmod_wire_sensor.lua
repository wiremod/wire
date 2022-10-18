AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Beacon Sensor"
ENT.WireDebugName = "Beacon Sensor"

if CLIENT then return end -- No more client

local MODEL = Model( "models/props_lab/huladoll.mdl" )

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "Target" })
	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup(xyz_mode, outdist, outbrng, gpscord, direction_vector, direction_normalized, target_velocity, velocity_normalized)
	if not xyz_mode and not outdist and not outbrng and not gpscord and not direction_vector and not target_velocity then outdist = true end

	self.xyz_mode = xyz_mode
	self.PrevOutput = nil
	self.Value = 0
	self.outdist = outdist
	self.outbrng = outbrng
	self.gpscord = gpscord
	self.direction_vector = direction_vector
	self.direction_normalized = direction_normalized
	self.target_velocity = target_velocity
	self.velocity_normalized = velocity_normalized


	local onames = {}
	if (outdist) then
	    table.insert(onames, "Distance")
	end

	if (xyz_mode) then
	    table.insert(onames, "X")
	    table.insert(onames, "Y")
	    table.insert(onames, "Z")
	end
	if (outbrng) then
		table.insert(onames, "Bearing")
		table.insert(onames, "Elevation")
	end
	if (gpscord) then
	    table.insert(onames, "World_X")
	    table.insert(onames, "World_Y")
	    table.insert(onames, "World_Z")
	end
	if (direction_vector) then
	    table.insert(onames, "Direction_X")
	    table.insert(onames, "Direction_Y")
	    table.insert(onames, "Direction_Z")
	end
	if (target_velocity) then
	    table.insert(onames, "Velocity_X")
	    table.insert(onames, "Velocity_Y")
	    table.insert(onames, "Velocity_Z")
	end

	Wire_AdjustOutputs(self, onames)
	self:TriggerOutputs(0, Angle(0, 0, 0),Vector(0, 0, 0),Vector(0, 0, 0),Vector(0, 0, 0),Vector(0,0,0))
	self:ShowOutput()
end

function ENT:Think()
	BaseClass.Think(self)

	if not IsValid(self.ToSense) or not self.ToSense.GetBeaconPos then return end
	if (self.Active) then
	    local dist = 0
	    local distc = Vector(0,0,0);
	    local brng = Angle(0,0,0);
		local velo = Vector(0,0,0);
		local gpscords = Vector(0,0,0);
		local dirvec = Vector(0,0,0);
		local MyPos = self:GetPos()
		//local BeaconPos = self.Inputs["Target"].Src:GetBeaconPos(self)
		local BeaconPos = self.ToSense:GetBeaconPos(self) or MyPos
		if (self.outdist) then
			dist = (BeaconPos-MyPos):Length()
		end
		if (self.xyz_mode) then
			local DeltaPos = self:WorldToLocal(BeaconPos)
			distc = Vector(-DeltaPos.y,DeltaPos.x,DeltaPos.z)
		end
		if (self.outbrng) then
		    local DeltaPos = self:WorldToLocal(BeaconPos)
		    brng = DeltaPos:Angle()
		end
		if (self.gpscord) then gpscords = BeaconPos end
		if (self.direction_vector) then
			dirvec = BeaconPos - MyPos;
			if(self.direction_normalized) then dirvec:Normalize() end;
		end;
		if (self.target_velocity) then
			velo = self.ToSense:GetBeaconVelocity(self);
			if(self.velocity_normalized) then velo:Normalize() end;
		end
		self:TriggerOutputs(dist, brng, distc, gpscords,dirvec,velo)
		self:ShowOutput()

		self:NextThink(CurTime()+0.04)
		return true
	end
end

function ENT:ShowOutput()
	local txt = ""
	if (self.outdist) then
		txt = string.format("%s\nDistance = %.3f", txt, self.Outputs.Distance.Value)
	end
	if (self.xyz_mode) then
		txt = string.format("%s\nOffset = %.3f, %.3f, %.3f", txt, self.Outputs.X.Value, self.Outputs.Y.Value, self.Outputs.Z.Value)
	end
	if (self.outbrng) then
		txt = string.format("%s\nBearing = %.3f, %.3f", txt, self.Outputs.Bearing.Value, self.Outputs.Elevation.Value)
	end
	if (self.gpscord) then
		txt = string.format("%s\nWorldPos = %.3f, %.3f, %.3f", txt, self.Outputs.World_X.Value, self.Outputs.World_Y.Value, self.Outputs.World_Z.Value)
	end
	if (self.direction_vector) then
		txt = string.format("%s\nDirectionVector = %.3f, %.3f, %.3f", txt, self.Outputs.Direction_X.Value, self.Outputs.Direction_Y.Value, self.Outputs.Direction_Z.Value)
	end
	if (self.target_velocity) then
		txt = string.format("%s\nTargetVelocity = %.3f, %.3f, %.3f", txt, self.Outputs.Velocity_X.Value, self.Outputs.Velocity_Y.Value, self.Outputs.Velocity_Z.Value)
	end

	self:SetOverlayText(string.Right(txt,#txt-1)) -- Cut off the first \n
end


function ENT:TriggerOutputs(dist, brng, distc, gpscords,dirvec,velo)
    if (self.outdist) then
		Wire_TriggerOutput(self, "Distance", dist)
	end
	if (self.xyz_mode) then
	    Wire_TriggerOutput(self, "X", distc.x)
	    Wire_TriggerOutput(self, "Y", distc.y)
	    Wire_TriggerOutput(self, "Z", distc.z)
	end
	if (self.gpscord) then
	    Wire_TriggerOutput(self, "World_X", gpscords.x)
	    Wire_TriggerOutput(self, "World_Y", gpscords.y)
	    Wire_TriggerOutput(self, "World_Z", gpscords.z)
	end
	if (self.outbrng) then
		local pitch = brng.p
		local yaw = brng.y

		if (pitch > 180) then pitch = pitch - 360 end
		if (yaw > 180) then yaw = yaw - 360 end

		Wire_TriggerOutput(self, "Bearing", -yaw)
	    Wire_TriggerOutput(self, "Elevation", -pitch)
	end
	if(self.direction_vector) then
	    Wire_TriggerOutput(self, "Direction_X", dirvec.x)
	    Wire_TriggerOutput(self, "Direction_Y", dirvec.y)
	    Wire_TriggerOutput(self, "Direction_Z", dirvec.z)
	end
	if(self.target_velocity) then
	    Wire_TriggerOutput(self, "Velocity_X", velo.x)
	    Wire_TriggerOutput(self, "Velocity_Y", velo.y)
	    Wire_TriggerOutput(self, "Velocity_Z", velo.z)
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Target") and ( self.ToSense ~= self.Inputs.Target.Src ) then
		self:LinkEnt(self.Inputs.Target.Src)
	end
end

function ENT:LinkEnt(beacon)
	if IsValid(beacon) and beacon.GetBeaconPos then
		self.ToSense = beacon
		self.Active = true
		WireLib.SendMarks(self, {beacon})
		return true
	else
		self:UnlinkEnt()
		return false, "Must link to ent that outputs BeaconPos"
	end
end
function ENT:UnlinkEnt(ent)
	self.ToSense = nil
	self.Active = false
	WireLib.SendMarks(self, {})
	return true
end

duplicator.RegisterEntityClass("gmod_wire_sensor", WireLib.MakeWireEnt, "Data", "xyz_mode", "outdist", "outbrng", "gpscord", "direction_vector", "direction_normalized", "target_velocity", "velocity_normalized")

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if IsValid(self.ToSense) then
	    info.to_sense = self.ToSense:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:LinkEnt(GetEntByID(info.to_sense))
end
