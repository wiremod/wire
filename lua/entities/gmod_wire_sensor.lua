
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Distance"

local MODEL = Model( "models/props_lab/huladoll.mdl" )

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "Target" })
	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup( xyz_mode, outdist, outbrng, gpscord, swapyz,direction_vector,direction_normalized,target_velocity,velocity_normalized)
	self.XYZMode = xyz_mode
	self.PrevOutput = nil
	self.Value = 0
	self.OutDist = outdist
	self.OutBrng = outbrng
	self.GPSCord = gpscord
	self.SwapYZ = swapyz
	self.direction_vector = direction_vector;
	self.direction_normalized = direction_normalized;
	self.target_velocity = target_velocity;
	self.velocity_normalized = velocity_normalized;

	if !xyz_mode and !outdist and !outbrng and !gpscord and !direction_vector and !target_velocity then self.OutDist = true outdist = true end

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
	self.BaseClass.Think(self)

	//if (!self.Inputs.Target.Src or !self.Inputs.Target.Src:IsValid() ) then return end
	if ( !self.ToSense or !self.ToSense:IsValid() or !self.ToSense.GetBeaconPos ) then return end
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
		if (self.OutDist) then
			dist = (BeaconPos-MyPos):Length()
		end
		if (self.XYZMode) then
			local DeltaPos = self:WorldToLocal(BeaconPos)
			if (self.SwapYZ) then
				distc = Vector(DeltaPos.z,DeltaPos.x,-DeltaPos.y)
			else
				distc = Vector(-DeltaPos.y,DeltaPos.x,DeltaPos.z)
			end
		end
		if (self.OutBrng) then
		    local DeltaPos = self:WorldToLocal(BeaconPos)
		    brng = DeltaPos:Angle()
		end
		if (self.GPSCord) then gpscords = BeaconPos end
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
	if (self.OutDist) then
		txt = txt .. "\nDistance = " .. math.Round(self.Outputs.Distance.Value*1000)/1000
	end
	if (self.XYZMode) then
		txt = txt .. "\nOffset = " .. math.Round(self.Outputs.X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Z.Value*1000)/1000
	end
	if (self.OutBrng) then
		txt = txt .. "\nBearing = " .. math.Round(self.Outputs.Bearing.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Elevation.Value*1000)/1000
	end
	if (self.GPSCord) then
		txt = txt .. "\nWorldPos = " .. math.Round(self.Outputs.World_X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.World_Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.World_Z.Value*1000)/1000
	end
	if (self.direction_vector) then
		txt = txt .. "\nDirectionVector = " .. math.Round(self.Outputs.Direction_X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Direction_Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Direction_Z.Value*1000)/1000
	end
	if (self.target_velocity) then
		txt = txt .. "\nTargetVelocity = " .. math.Round(self.Outputs.Velocity_X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Velocity_Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Velocity_Z.Value*1000)/1000
	end

	self:SetOverlayText(string.Right(txt,#txt-1)) -- Cut off the first \n
end


function ENT:TriggerOutputs(dist, brng, distc, gpscords,dirvec,velo)
    if (self.OutDist) then
		Wire_TriggerOutput(self, "Distance", dist)
	end
	if (self.XYZMode) then
	    Wire_TriggerOutput(self, "X", distc.x)
	    Wire_TriggerOutput(self, "Y", distc.y)
	    Wire_TriggerOutput(self, "Z", distc.z)
	end
	if (self.GPSCord) then
	    Wire_TriggerOutput(self, "World_X", gpscords.x)
	    Wire_TriggerOutput(self, "World_Y", gpscords.y)
	    Wire_TriggerOutput(self, "World_Z", gpscords.z)
	end
	if (self.OutBrng) then
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
	if (iname == "Target") and ( self.ToSense != self.Inputs.Target.Src ) then
		self:SetBeacon(self.Inputs.Target.Src)
	end
end

function ENT:SetBeacon(beacon)
	if (beacon) and (beacon:IsValid()) then
		self.ToSense = beacon
		self.Active = true
	else
		self.ToSense = nil
		self.Active = false
	end
end

function ENT:OnRestore()
	//this is to prevent old save breakage
	self:Setup(self.XYZMode, self.OutDist, self.OutBrng, self.GPSCord, self.SwapYZ,self.direction_vector,self.direction_normalized,self.target_velocity,self.velocity_normalized)

	self.BaseClass.OnRestore(self)
end


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.ToSense) and (self.ToSense:IsValid()) then
	    info.to_sense = self.ToSense:EntIndex()
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.to_sense) then
		self:SetBeacon(GetEntByID(info.to_sense))
		if (!self.ToSense) then
			self:SetBeacon(ents.GetByIndex(info.to_sense))
		end
	end
end
