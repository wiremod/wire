AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Eye Pod"
ENT.Purpose         = "To control the player's view in a pod and output their mouse movements"
ENT.WireDebugName	= "Eye Pod"

if CLIENT then
	local enabled = false
	local rotate90 = false
	local freezePitch = true
	local freezeYaw = true

	local previousEnabled = false

	usermessage.Hook("UpdateEyePodState", function(um)
		if not um then return end

		local eyeAng = um:ReadAngle()
		enabled = um:ReadBool()
		rotate90 = um:ReadBool()
		freezePitch = um:ReadBool() and eyeAng.p
		freezeYaw = um:ReadBool() and eyeAng.y
	end)

	hook.Add("CreateMove", "WireEyePodEyeControl", function(ucmd)
		if enabled then
			currentAng = ucmd:GetViewAngles()

			if freezePitch then
				currentAng.p = freezePitch
			end

			if freezeYaw then
				currentAng.y = freezeYaw
			end

			currentAng.r = 0

			ucmd:SetViewAngles(currentAng)
			previousEnabled = true
		elseif previousEnabled then
			if rotate90 then
				ucmd:SetViewAngles(Angle(0,90,0))
			else
				ucmd:SetViewAngles(Angle(0,0,0))
			end
			previousEnabled = false
		end
	end)

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
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

	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)
end

function ENT:UpdateOverlay()
	self:SetOverlayText(
		string.format( "Default to Zero: %s\nCumulative: %s\nMin: %s,%s\nMax: %s,%s\n%s\n\nActivated: %s%s",
			(self.DefaultToZero == 1) and "Yes" or "No",
			(self.ShowRateOfChange == 0) and "Yes" or "No",
			self.ClampXMin, self.ClampYMin,
			self.ClampXMax, self.ClampYMax,
			IsValid( self.pod ) and "Linked to: " .. self.pod:GetModel() or "Not linked",
			self.enabled and "Yes" or "No",
			(self.enabled == true and IsValid( self.driver )) and "\nIn use by: " .. self.driver:Nick() or ""
		)
	)
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

	self:UpdateOverlay()
end

local Rotate90ModelList = {
	["models/props_c17/furniturechair001a.mdl"]	= true,
	["models/airboat.mdl"]						= true,
	["models/props_c17/chair_office01a.mdl"]	= true,
	["models/nova/chair_office02.mdl"]			= true,
	["models/nova/chair_office01.mdl"]			= true,
	["models/props_combine/breenchair.mdl"]		= true,
	["models/nova/chair_wood01.mdl"]			= true,
	["models/nova/airboat_seat.mdl"]			= true,
	["models/nova/chair_plastic01.mdl"]			= true,
	["models/nova/jeep_seat.mdl"]				= true,
	["models/props_phx/carseat.mdl"]			= true,
	["models/props_phx/carseat2.mdl"]			= true,
	["models/props_phx/carseat3.mdl"]			= true,
	["models/buggy.mdl"]						= true,
	["models/vehicle.mdl"]						= true,
	-- Playermodel Chairs (https://steamcommunity.com/sharedfiles/filedetails/?id=2183798463)
	["models/chairs_playerstart/airboatpose.mdl"]	= true,
	["models/chairs_playerstart/jeeppose.mdl"]		= true,
	["models/chairs_playerstart/sitposealt.mdl"]	= true,
	["models/chairs_playerstart/pronepose.mdl"] 	= true,
	["models/chairs_playerstart/sitpose.mdl	"]		= true,
	["models/chairs_playerstart/standingpose.mdl"]	= true,
	-- ACF / ACE
	["models/vehicles/pilot_seat.mdl"] = true
}

-- Old function alias
function ENT:PodLink(vehicle) return self:LinkEnt(vehicle) end

function ENT:LinkEnt(vehicle)
	vehicle = WireLib.GetClosestRealVehicle(vehicle,self:GetPos(),self:GetPlayer())

	if not IsValid(vehicle) or not vehicle:IsVehicle() then
		if IsValid(self.pod) then
			self.pod.AttachedWireEyePod = nil
		end
		self.pod = nil
		self:UpdateOverlay()
		return false, "Must link to a vehicle"
	end
	self.pod = vehicle
	vehicle:CallOnRemove("wire_eyepod_remove",function()
		self:UnlinkEnt(vehicle)
	end)

	self.rotate90 = false
	self.eyeAng = Angle(0, 0, 0)
	if IsValid(vehicle) and vehicle:IsVehicle() then
		if Rotate90ModelList[string.lower(vehicle:GetModel())] then
			self.rotate90 = true
			self.eyeAng = Angle(0, 90, 0)
		end
	end

	vehicle.AttachedWireEyePod = self
	self:UpdateOverlay()
	WireLib.SendMarks(self,{vehicle})
	self:ColorByLinkStatus(IsValid(vehicle) and self.LINK_STATUS_LINKED or self.LINK_STATUS_UNLINKED)
	return true
end

function ENT:UnlinkEnt()
	if IsValid(self.pod) then
		self.pod.AttachedWireEyePod = nil
		self.pod:RemoveCallOnRemove("wire_eyepod_remove")
	end
	self.pod = nil
	if IsValid(self.driver) then
		self:updateEyePodState(false)
		self.driver = nil
	end
	WireLib.SendMarks(self,{})
	self:UpdateOverlay()
	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)
	return true
end

function ENT:updateEyePodState(enabled)
	self:ColorByLinkStatus(enabled and self.LINK_STATUS_ACTIVE or self.LINK_STATUS_LINKED)
	umsg.Start("UpdateEyePodState", self.driver)
		umsg.Angle(self.eyeAng)
		umsg.Bool(enabled)
		umsg.Bool(self.rotate90)
		umsg.Bool(self.freezePitch)
		umsg.Bool(self.freezeYaw)
	umsg.End()
end

hook.Add("PlayerEnteredVehicle","gmod_wire_eyepod_entervehicle",function(ply,vehicle)
	local eyepod = vehicle.AttachedWireEyePod
	if eyepod ~= nil then
		if IsValid(eyepod) then
			eyepod.driver = vehicle:GetDriver()
			eyepod:updateEyePodState(eyepod.enabled)
			eyepod:UpdateOverlay()
		else
			vehicle.AttachedWireEyePod = nil
		end
	end
end)

hook.Add("PlayerLeaveVehicle","gmod_wire_eyepod_leavevehicle",function(ply,vehicle)
	local eyepod = vehicle.AttachedWireEyePod
	if eyepod ~= nil then
		if IsValid(eyepod) then
			eyepod:updateEyePodState(false)
			eyepod.driver = nil
			if (eyepod.X ~= 0 or eyepod.Y ~= 0) and eyepod.DefaultToZero == 1 then
				eyepod.X = 0
				eyepod.Y = 0
				WireLib.TriggerOutput( eyepod, "X", 0 )
				WireLib.TriggerOutput( eyepod, "Y", 0 )
				WireLib.TriggerOutput( eyepod, "XY", {0,0} )
			end
			eyepod:UpdateOverlay()
		else
			vehicle.AttachedWireEyePod = nil
		end
	end
end)

function ENT:OnRemove()
	self:UnlinkEnt()
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

		if self.enabled == false and self.DefaultToZero == 1 and (self.X ~= 0 or self.Y ~= 0) then
			self.X = 0
			self.Y = 0
			WireLib.TriggerOutput( self, "X", 0 )
			WireLib.TriggerOutput( self, "Y", 0 )
			WireLib.TriggerOutput( self, "XY", {0,0} )
		end

		self:UpdateOverlay()
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

	if IsValid(self.pod) and IsValid(self.driver) then
		self:updateEyePodState(self.enabled)
	end
end

hook.Add("SetupMove", "WireEyePodMouseControl", function(ply, movedata)
	--is the player in a vehicle?
	if not ply then return end
	if not ply:InVehicle() then return end

	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then return end

	--get the EyePod
	local eyePod = vehicle.AttachedWireEyePod

	--is the vehicle linked to an EyePod?
	if not IsValid(eyePod) then return end

	if eyePod.enabled then

		local cmd = ply:GetCurrentCommand()

		local oldX = eyePod.X
		local oldY = eyePod.Y

		--reset the output so it is not cumualative if you want the rate of change
		if eyePod.ShowRateOfChange == 1 then
			eyePod.X = 0
			eyePod.Y = 0
		end

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

		if oldX ~= eyePod.X or oldY ~= eyePod.Y then
			-- Update outputs
			WireLib.TriggerOutput(eyePod, "X", eyePod.X)
			WireLib.TriggerOutput(eyePod, "Y", eyePod.Y)

			local XY_Vec = {eyePod.X, eyePod.Y}
			WireLib.TriggerOutput(eyePod, "XY", XY_Vec)
		end

		--reset the mouse
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)

	end
end)

-- Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.pod) then
		info.pod = self.pod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:PodLink(GetEntByID(info.pod))
end

duplicator.RegisterEntityClass("gmod_wire_eyepod", WireLib.MakeWireEnt, "Data", "DefaultToZero", "ShowRateOfChange" , "ClampXMin" , "ClampXMax" , "ClampYMin" , "ClampYMax" , "ClampX", "ClampY")
