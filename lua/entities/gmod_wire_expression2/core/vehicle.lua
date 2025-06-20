--[[----------------------------------------------------------------------------
	Vehicle-Entity support
------------------------------------------------------------------------------]]

local isOwner = E2Lib.isOwner

__e2setcost(5)

e2function number entity:boostTimeLeft()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:BoostTimeLeft()
end

e2function vector entity:checkExitPoint(number yaw, number distance)
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", Vector(0, 0, 0)) end

	return this:CheckExitPoint(yaw, distance) or Vector(0, 0, 0)
end

e2function number entity:getCameraDistance()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetCameraDistance()
end

e2function entity entity:getDriver()
	if not IsValid(this) then return self:throw("Invalid entity!", NULL) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", NULL) end

	return this:GetDriver()
end

e2function number entity:getHLSpeed()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetHLSpeed()
end

e2function number entity:getMaxSpeed()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetMaxSpeed()
end

e2function table entity:getOperatingParams()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", {}) end

	return this:GetOperatingParams()
end

e2function entity entity:getPassenger(number index)
	if not IsValid(this) then return self:throw("Invalid entity!", NULL) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", NULL) end

	return this:GetPassenger(index)
end

e2function table entity:getPassengerSeatInfo(number role)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", {}) end

	return {this:GetPassengerSeatPoint(role)}
end

e2function number entity:getRPM()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetRPM()
end

e2function number entity:getSpeed()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetSpeed()
end

e2function number entity:getSteering()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetSteering()
end

e2function number entity:getSteeringDegrees()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetSteeringDegrees()
end

e2function number entity:getThirdPersonMode()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetThirdPersonMode() and 1 or 0
end

e2function number entity:getThrottle()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetThrottle()
end

e2function string entity:getVehicleClass()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", "") end

	return this:GetVehicleClass()
end

e2function table entity:getVehicleParams()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", {}) end

	return this:GetVehicleParams()
end

e2function table entity:getVehicleViewTable(number role)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", {}) end

	return {this:GetVehicleViewPosition(role)}
end

e2function number entity:getWheelBaseHeight(number wheel)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetWheelBaseHeight(wheel)
end

e2function table entity:getWheelContactInfo(number wheel)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", {}) end

	return {this:GetWheelContactPoint(wheel)}
end

e2function number entity:getWheelCount()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetWheelCount()
end

e2function number entity:getWheelTotalHeight(number wheel)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:GetWheelTotalHeight(wheel)
end

e2function number entity:hasBoost()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:HasBoost() and 1 or 0
end

e2function number entity:hasBrakePedal()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:HasBrakePedal() and 1 or 0
end

e2function number entity:isBoosting()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:IsBoosting() and 1 or 0
end

e2function number entity:isEngineEnabled()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:IsEngineEnabled() and 1 or 0
end

e2function number entity:isEngineStarted()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:IsEngineStarted() and 1 or 0
end

e2function number entity:isValidVehicle()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:IsValidVehicle() and 1 or 0
end

e2function number entity:isVehicleBodyInWater()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", 0) end

	return this:IsVehicleBodyInWater() and 1 or 0
end

__e2setcost(15)

e2function void entity:enableEngine(number enable)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:EnableEngine(enable == 1)
end

e2function void entity:releaseHandbrake()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:ReleaseHandbrake()
end

e2function void entity:setBoost(number boost)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetBoost(boost)
end

e2function void entity:setCameraDistance(number distance)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetCameraDistance(distance)
end

e2function void entity:setHandbrake(number handbrake)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetHandbrake(handbrake == 1)
end

e2function void entity:setHasBrakePedal(number brakepedal)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetHasBrakePedal(brakepedal == 1)
end

e2function void entity:setMaxReverseThrottle(number maxrevthrottle)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetMaxReverseThrottle(maxrevthrottle)
end

e2function void entity:setMaxThrottle(number maxthrottle)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetMaxThrottle(maxthrottle)
end

e2function void entity:setSpringLength(number wheel, number length)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSpringLength(wheel, length)
end

e2function void entity:setSteering(number front, number rear)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSteering(math.Clamp(front, -1, 1), math.Clamp(rear, -1, 1))
end

e2function void entity:setSteeringDegrees(number steeringdegress)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSteeringDegrees(steeringdegress)
end

e2function void entity:setThirdPersonMode(number enable)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetThirdPersonMode(enable == 1)
end

e2function void entity:setThrottle(number throttle)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetThrottle(throttle)
end

e2function void entity:setVehicleEntryAnim(number bon)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetVehicleEntryAnim(bon == 1)
end

e2function void entity:setVehicleParams(table params)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetVehicleParams(params)
end

e2function void entity:setWheelFriction(number wheel, number friction)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetWheelFriction(wheel, friction)
end

e2function void entity:startEngine(number start)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:StartEngine(start == 1)
end