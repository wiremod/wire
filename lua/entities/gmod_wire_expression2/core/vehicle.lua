--[[----------------------------------------------------------------------------
	Vehicle-Entity support
------------------------------------------------------------------------------]]

local isOwner = E2Lib.isOwner

local function ValidVehicle(self, this)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsVehicle() then return self:throw("Expected a Vehicle but got an Entity!", nil) end
	return true
end

__e2setcost(5)

e2function number entity:boostTimeLeft()
	if not ValidVehicle(self, this) then return 0 end
	return this:BoostTimeLeft()
end

e2function vector entity:getExitPoint(number yaw, number distance)
	if not ValidVehicle(self, this) then return Vector(0, 0, 0) end
	return this:getExitPoint(yaw, distance) or Vector(0, 0, 0)
end

e2function number entity:getCameraDistance()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetCameraDistance()
end

e2function entity entity:getDriver()
	if not ValidVehicle(self, this) then return NULL end
	return this:GetDriver()
end

e2function number entity:getVehicleSpeed()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetHLSpeed()
end

e2function number entity:getMaxSpeed()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetMaxSpeed()
end

e2function entity entity:getPassenger(number index)
	if not ValidVehicle(self, this) then return NULL end
	return this:GetPassenger(index)
end

e2function array entity:getSeatInfo(number seat)
	if not ValidVehicle(self, this) then return {} end
	return {this:GetPassengerSeatPoint(seat)}
end

e2function number entity:getRPM()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetRPM()
end

e2function number entity:getMPH()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetSpeed()
end

e2function number entity:getSteering()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetSteering()
end

e2function number entity:getSteeringDegrees()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetSteeringDegrees()
end

e2function number entity:getThirdPersonMode()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetThirdPersonMode() and 1 or 0
end

e2function number entity:getThrottle()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetThrottle()
end

e2function string entity:getVehicleClass()
	if not ValidVehicle(self, this) then return "" end
	return this:GetVehicleClass()
end

e2function table entity:getVehicleParams()
	if not ValidVehicle(self, this) then return {} end
	return this:GetVehicleParams()
end

e2function array entity:getSeatViewInfo(number seat)
	if not ValidVehicle(self, this) then return {} end
	return {this:GetVehicleViewPosition(seat)}
end

e2function array entity:getWheelContactInfo(number wheel)
	if not ValidVehicle(self, this) then return {} end
	return {this:GetWheelContactPoint(wheel)}
end

e2function number entity:getWheelCount()
	if not ValidVehicle(self, this) then return 0 end
	return this:GetWheelCount()
end

e2function number entity:getWheelHeight(number wheel)
	if not ValidVehicle(self, this) then return 0 end
	return this:GetWheelTotalHeight(wheel)
end

e2function number entity:hasBoost()
	if not ValidVehicle(self, this) then return 0 end
	return this:HasBoost() and 1 or 0
end

e2function number entity:hasBrakePedal()
	if not ValidVehicle(self, this) then return 0 end
	return this:HasBrakePedal() and 1 or 0
end

e2function number entity:isBoosting()
	if not ValidVehicle(self, this) then return 0 end
	return this:IsBoosting() and 1 or 0
end

e2function number entity:isEngineEnabled()
	if not ValidVehicle(self, this) then return 0 end
	return this:IsEngineEnabled() and 1 or 0
end

e2function number entity:isEngineStarted()
	if not ValidVehicle(self, this) then return 0 end
	return this:IsEngineStarted() and 1 or 0
end

__e2setcost(15)

e2function void entity:enableEngine(number enable)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:EnableEngine(enable == 1)
end

e2function void entity:setBoost(number boost)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetBoost(boost)
end

e2function void entity:setCameraDistance(number distance)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetCameraDistance(distance)
end

e2function void entity:setHandbrake(number handbrake)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetHandbrake(handbrake == 1)
end

e2function void entity:setHasBrakePedal(number brakepedal)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetHasBrakePedal(brakepedal == 1)
end

e2function void entity:setMaxReverseThrottle(number maxrevthrottle)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetMaxReverseThrottle(maxrevthrottle)
end

e2function void entity:setMaxThrottle(number maxthrottle)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetMaxThrottle(maxthrottle)
end

e2function void entity:setSpringLength(number wheel, number length)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSpringLength(wheel, length)
end

e2function void entity:setSteering(number front, number rear)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSteering(math.Clamp(front, -1, 1), math.Clamp(rear, -1, 1))
end

e2function void entity:setSteeringDegrees(number steeringdegress)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetSteeringDegrees(steeringdegress)
end

e2function void entity:setThirdPersonMode(number enable)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetThirdPersonMode(enable == 1)
end

e2function void entity:setThrottle(number throttle)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:SetThrottle(throttle)
end

e2function void entity:startEngine(number start)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	this:StartEngine(start == 1)
end

__e2setcost(10)

e2function void entity:lockPod(number lock)
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	if lock ~= 0 then
		this:Fire("Lock")
	else
		this:Fire("Unlock")
	end
end

e2function void entity:killPod()
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	local ply = this:GetDriver()

	if ply:IsValid() and ply:Alive() then
		ply:Kill()
	end
end

e2function void entity:ejectPod()
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	local ply = this:GetDriver()

	if ply:IsValid() then
		ply:ExitVehicle()
	end
end

e2function void entity:podStripWeapons()
	if not ValidVehicle(self, this) then return nil end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	local ply = this:GetDriver()

	if ply:IsValid() then
		ply:StripWeapons()
	end
end

e2function void entity:podSetName(string name)
	if not ValidVehicle(self, this) then return nil end
	if not this.VehicleTable or not this.VehicleTable.Name then return self:throw("Invalid vehicle table!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this vehicle!", nil) end

	name = string.sub(name, 1, 200)
	if hook.Run("Wire_CanName", name) == false then return self:throw("A hook prevented this function from running") end

	this.VehicleTable.Name = name
end

__e2setcost(5)

[deprecated = "Use getDriver instead"]
e2function entity entity:driver() = e2function entity entity:getDriver()

[deprecated = "Use getPassenger with 0 instead"]
e2function entity entity:passenger()
	if not ValidVehicle(self, this) then return NULL end
	return this:GetPassenger(0)
end