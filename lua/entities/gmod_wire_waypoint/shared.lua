ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Waypoint Beacon"
ENT.Author      = ""
ENT.Contact     = ""


-- ENT:SetNextWaypoint is in init.lua

function ENT:GetNextWaypoint()
	return self:GetNetworkedEntity("NextWaypoint")
end
