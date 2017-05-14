--------------------------------------------------------------------------------
--  Vehicle-Entity support
--------------------------------------------------------------------------------

local IsValid = IsValid
local isOwner = E2Lib.isOwner

-- Localization; Faster access to bit/math/util library functions
local bit = bit
local bit_band = bit.band
local math = math
local math_max = math.max
local math_min = math.min
local util = util
--local util_TraceHull = util.TraceHull
local util_PointContents = util.PointContents

registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "IsValid" then
		IsValid = func
	elseif funcname == "isOwner" then
		isOwner = func
	end
end)

--------------------------------------------------------------------------------

local wire_pod_exit_distance = GetConVar("wire_pod_exit_distance") -- ConVar is created in Vehicle Exit Point entity. We use this to get the maximum distance an exit-point can move a player (by default it is set to 1000 units).
local VehicleExitPoints = {} -- This will contain the exit-point data (indexed by Vehicle).
local InvalidExitValue = { 0, 0, 0 } -- Localized table for "invalid" angle/vector, heck why not, it is better this way than creating a table each time.

hook.Add("PlayerLeaveVehicle", "E2SetVehicleExitPoint", function(ply, vehicle)
	if not (ply:IsValid() and vehicle:IsValid()) then return end -- Don't run if the player/vehicle is not valid.
	-- Don't run if there is no exit-point data for this vehicle.
	local exitPoint = VehicleExitPoints[vehicle]
	if not exitPoint then return end
	if exitPoint.Position then -- If exit-point data has set the custom Position then "teleport" the player, taking into account for "wire_pod_exit_distance".
		-- These four lines below are just slightly changed but still copy/paste code (from Vehicle Exit Point entity):
		local origin = vehicle:GetPos()
		local direction = exitPoint.Position - origin
		local direction_distance = direction:Length()
		ply:SetPos(origin + direction / direction_distance * math_min(direction_distance, math_max(0, wire_pod_exit_distance:GetInt())))
	end
	if exitPoint.Angle then -- If exit-point data has set the custom Angle then set new eye angles for the player.
		ply:SetEyeAngles(exitPoint.Angle)
	end
end)

hook.Add("EntityRemoved", "E2RemoveVehicleExitPoint", function(ent)
	-- No need for redundant checks, if <ent> key exists in VehicleExitPoints table, data will be removed by setting it to nil value.
	VehicleExitPoints[ent] = nil
end)

__e2setcost(5) -- approximated

--- Gets exit angles of a vehicle (this will return exit-point angle only if you have set it via setVehicleExitAng; otherwise, it will return invalid/zero angle).
e2function angle entity:getVehicleExitAng()
	if IsValid(this) and this:IsVehicle() then
		local exitPoint = VehicleExitPoints[this]
		if exitPoint and exitPoint.Angle then
			return { exitPoint.Angle.p, exitPoint.Angle.y, 0 }
		end
	end
	return InvalidExitValue
end

--- Gets exit position of a vehicle (this will return exit-point position only if you have set it via setVehicleExitPos; otherwise, it will return invalid/origin vector).
e2function vector entity:getVehicleExitPos()
	if IsValid(this) and this:IsVehicle() then
		local exitPoint = VehicleExitPoints[this]
		if exitPoint and exitPoint.Position then
			return { exitPoint.Position.x, exitPoint.Position.y, exitPoint.Position.z }
		end
	end
	return InvalidExitValue
end

--- Removes exit angles of a vehicle (this will remove exit-point angle only if you have set it via setVehicleExitAng).
e2function void entity:removeVehicleExitAng()
	if IsValid(this) and this:IsVehicle() and isOwner(self, this) and VehicleExitPoints[this] then
		VehicleExitPoints[this].Angle = nil
	end
end

--- Removes exit position of a vehicle (this will remove exit-point position only if you have set it via setVehicleExitPos).
e2function void entity:removeVehicleExitPos()
	if IsValid(this) and this:IsVehicle() and isOwner(self, this) and VehicleExitPoints[this] then
		VehicleExitPoints[this].Position = nil
	end
end

__e2setcost(10) -- approximated

--- Sets exit angles of a vehicle.
e2function void entity:setVehicleExitAng(angle exitAng)
	if not (IsValid(this) and this:IsVehicle() and isOwner(self, this)) then return end
	local exitPoint = VehicleExitPoints[this] or {}
	exitPoint.Angle = Angle(exitAng[1], exitAng[2], 0) -- Prevent angle's roll-axis from changing.
	VehicleExitPoints[this] = exitPoint
end

--- Sets exit position of a vehicle (returns 1 on success; otherwise, it returns 0 to indicate a failure).
e2function number entity:setVehicleExitPos(vector exitPos)
	if not (IsValid(this) and this:IsVehicle() and isOwner(self, this)) then return 0 end
	-- Validate exitPos (make sure it is inside of the world).
	local pos = Vector(exitPos[1], exitPos[2], exitPos[3])
	--[[
	-- I didn't like using hull-trace here..
	local tr = util_TraceHull({
		start = pos,
		endpos = pos,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72),
		--mask = ...
	})
	if tr.Hit then return 0 end -- If the trace is hit then we quit, because the player will be stuck at exitPos.
	]]
	-- Let's keep it simple and effective via PointContents function:
	if bit_band(util_PointContents(pos), CONTENTS_SOLID) == CONTENTS_SOLID then return 0 end -- Check if the contents at exitPos is "solid", we quit if it is solid, because it means that exitPos is outside of the world.
	local exitPoint = VehicleExitPoints[this] or {}
	exitPoint.Position = pos
	VehicleExitPoints[this] = exitPoint
	return 1
end
