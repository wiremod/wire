ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Waypoint Beacon"
ENT.Author      = ""
ENT.Contact     = ""


function ENT:SetNextWaypoint(wp)
	self.Entity:SetNetworkedEntity("NextWaypoint", wp)
end

function ENT:GetNextWaypoint()
	return self.Entity:GetNetworkedEntity("NextWaypoint")
end
