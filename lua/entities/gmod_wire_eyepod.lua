AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.WireDebugName = "Eye Pod"

function ENT:Initialize()
	-- Make Physics work
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	-- set it so we don't colide
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)

	-- turn off shadow
	self:DrawShadow(false)

	-- Set wire I/O
	self.Inputs = WireLib.CreateSpecialInputs(self, { "Enable", "SetPitch", "SetYaw", "SetViewAngle", "UnfreezePitch", "UnfreezeYaw" }, { "NORMAL", "NORMAL", "NORMAL", "ANGLE", "NORMAL", "NORMAL" })
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "X", "Y", "XY" }, { "NORMAL", "NORMAL", "VECTOR2" })

	-- Initialize values
	self.driver = nil
	self.X = 0
	self.Y = 0
	self.enabled = false
	self.pod = nil
	self.eyeAng = Angle(0, 0, 0)
	self.rotate90 = false
	self.DefaultToZero = 1
	self.ShowRateOfChange = 0
	self.LastUpdateTime = CurTime()

	-- clamps
	self.ClampXMin = 0
	self.ClampXMax = 0
	self.ClampYMin = 0
	self.ClampYMax = 0
	self.ClampX = 0
	self.ClampY = 0

	self.freezePitch = true
	self.freezeYaw = true

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
end

function ENT:Setup(DefaultToZero, RateOfChange, ClampXMin, ClampXMax, ClampYMin, ClampYMax, ClampX, ClampY)
	self.DefaultToZero = DefaultToZero
	self.ShowRateOfChange = RateOfChange
	self.ClampXMin = ClampXMin
	self.ClampXMax = ClampXMax
	self.ClampYMin = ClampYMin
	self.ClampYMax = ClampYMax
	self.ClampX = ClampX
	self.ClampY = ClampY
end

local Rotate90ModelList = {
	"models/props_c17/furniturechair001a.mdl",
	"models/airboat.mdl",
	"models/props_c17/chair_office01a.mdl",
	"models/nova/chair_office02.mdl",
	"models/nova/chair_office01.mdl",
	"models/props_combine/breenchair.mdl",
	"models/nova/chair_wood01.mdl",
	"models/nova/airboat_seat.mdl",
	"models/nova/chair_plastic01.mdl",
	"models/nova/jeep_seat.mdl",
	"models/props_phx/carseat.mdl",
	"models/props_phx/carseat2.mdl",
	"models/props_phx/carseat3.mdl",
	"models/buggy.mdl",
	"models/vehicle.mdl"
}

function ENT:PodLink(vehicle)
	if not IsValid(vehicle) or not vehicle:IsVehicle() then
		if IsValid(self.pod) then
			self.pod.AttachedWireEyePod = nil
		end
		self.pod = nil
		return false
	end
	self.pod = vehicle

	self.rotate90 = false
	self.eyeAng = Angle(0, 0, 0)
	if IsValid(vehicle) and vehicle:IsVehicle() then
		if table.HasValue(Rotate90ModelList, string.lower(vehicle:GetModel())) then
			self.rotate90 = true
			self.eyeAng = Angle(0, 90, 0)
		end
	end


	vehicle.AttachedWireEyePod = self
	return true
end

function ENT:updateEyePodState(enabled)
	umsg.Start("UpdateEyePodState", self.driver)
		umsg.Angle(self.eyeAng)
		umsg.Bool(enabled)
		umsg.Bool(self.rotate90)
		umsg.Bool(self.freezePitch)
		umsg.Bool(self.freezeYaw)
	umsg.End()
end

function ENT:OnRemove()
	if IsValid(self.pod) and self.pod:IsVehicle() then
		self.pod.AttachedWireEyePod = nil
	end

	if IsValid(self.driver) then
		self:updateEyePodState(false)
		self.driver = nil
	end
end

function ENT:Think()
	-- Make sure the gate updates even if we don't receive any input
	self:TriggerInput()

	if IsValid(self.pod) then
		-- if we are in a pod, set the player
		if self.pod:IsVehicle() and self.pod:GetDriver():IsPlayer() then
			self.driver = self.pod:GetDriver()
		else -- else set X and Y to 0
			if IsValid(self.driver) then
				self:updateEyePodState(false)
				self.driver = nil
			end
			if self.DefaultToZero == 1 then
				self.X = 0
				self.Y = 0
				Wire_TriggerOutput(self, "X", self.X)
				Wire_TriggerOutput(self, "Y", self.Y)
				local XY_Vec = {self.X, self.Y}
				Wire_TriggerOutput(self, "XY", XY_Vec)
			end
		end
	else -- else set X and Y to 0
		if IsValid(self.driver) then
			self:updateEyePodState(false)
			self.driver = nil
		end
		if self.DefaultToZero == 1 then
			self.X = 0
			self.Y = 0
			Wire_TriggerOutput(self, "X", self.X)
			Wire_TriggerOutput(self, "Y", self.Y)
			local XY_Vec = {self.X, self.Y}
			Wire_TriggerOutput(self, "XY", XY_Vec)
		end
		self.pod = nil
	end

	-- update the overlay with the user's name
	local Txt = ""
	if self.enabled and IsValid(self.driver) and self.driver:IsPlayer() then
		Txt = Txt.." - In use by "..self.driver:Name()
	else
		Txt = Txt.." - Not Active"
	end
	if IsValid(self.pod) and self.pod:IsVehicle() then
		Txt = Txt.."\nLinked to "..self.pod:GetModel()
	else
		Txt = Txt.."\nNot Linked"
	end

	self:SetOverlayText(Txt)

	self:NextThink(CurTime() + 0.1)

	return true
end

local function AngNorm(Ang)
	return (Ang + 180) % 360 - 180
end
local function AngNorm90(Ang)
	return (Ang + 90) % 180 - 90
end

function ENT:TriggerInput(iname, value)
	-- Change variables to reflect input
	if iname == "Enable" then
		self.enabled = value ~= 0
	elseif iname == "SetPitch" then
		self.eyeAng = Angle(AngNorm90(value), self.eyeAng.y, self.eyeAng.r)
	elseif iname == "SetYaw" then
		if self.rotate90 == true then
			self.eyeAng = Angle(AngNorm90(self.eyeAng.p), AngNorm(value+90), self.eyeAng.r)
		else
			self.eyeAng = Angle(AngNorm90(self.eyeAng.p), AngNorm(value), self.eyeAng.r)
		end
	elseif iname == "SetViewAngle" then
		if self.rotate90 == true then
			self.eyeAng = Angle(AngNorm90(value.p), AngNorm(value.y+90), 0)
		else
			self.eyeAng = Angle(AngNorm90(value.p), AngNorm(value.y), 0)
		end
	elseif iname == "UnfreezePitch" then
		self.freezePitch = value == 0
	elseif iname == "UnfreezeYaw" then
		self.freezeYaw = value == 0
	end

	-- If we're not enabled, set the output to zero and exit
	if not self.enabled then
		if self.DefaultToZero == 1 then
			self.X = 0
			self.Y = 0
			Wire_TriggerOutput(self, "X", self.X)
			Wire_TriggerOutput(self, "Y", self.Y)
			local XY_Vec = {self.X, self.Y}
			Wire_TriggerOutput(self, "XY", XY_Vec)
		end
		if IsValid(self.driver) and IsValid(self.pod) then
			self:updateEyePodState(self.enabled)
		end
		return
	end

	--Turn on the EyePod Control file
	self.enabled = true
	if IsValid(self.driver) and IsValid(self.pod) then
		self:updateEyePodState(self.enabled)
	end
end

local UpdateTimer = CurTime()

hook.Add("SetupMove", "WireEyePodMouseControl", function(ply, movedata)
	--is the player in a vehicle?
	if not ply then return end
	if not ply:InVehicle() then return end

	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then return end

	local Table = vehicle:GetTable()

	if not Table then return end

	--get the EyePod
	local eyePod = Table.AttachedWireEyePod

	--is the vehicle linked to an EyePod?
	if not IsValid(eyePod) then return end

	if eyePod.enabled then

		local cmd = ply:GetCurrentCommand()

		--update the cumualative output
		eyePod.X = cmd:GetMouseX()/10 + eyePod.X
		eyePod.Y = -cmd:GetMouseY()/10 + eyePod.Y

		--clamp the output
		if eyePod.ClampX == 1 then
			eyePod.X = math.Clamp(eyePod.X, eyePod.ClampXMin, eyePod.ClampXMax)
		end
		if eyePod.ClampY == 1 then
			eyePod.Y = math.Clamp(eyePod.Y, eyePod.ClampYMin, eyePod.ClampYMax)
		end

		--update the outputs every 0.015 seconds
		if (CurTime() > (eyePod.LastUpdateTime+0.015)) then
			Wire_TriggerOutput(eyePod, "X", eyePod.X)
			Wire_TriggerOutput(eyePod, "Y", eyePod.Y)
			local XY_Vec = {eyePod.X, eyePod.Y}
			Wire_TriggerOutput(eyePod, "XY", XY_Vec)
			--reset the output so it is not cumualative if you want the rate of change
			if eyePod.ShowRateOfChange == 1 then
				eyePod.X = 0
				eyePod.Y = 0
			end
			eyePod.LastUpdateTime = CurTime()
		end

		--reset the mouse
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
		return

	end
end)

-- Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.pod) then
		info.pod = self.pod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if info.pod then
		self.pod = GetEntByID(info.pod)
		if not self.pod then
			self.pod = ents.GetByIndex(info.pod)
		end
		if self.pod then
			self:PodLink(self.pod)
		end
	end
end
