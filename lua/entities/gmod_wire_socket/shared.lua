ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Socket"
ENT.Author          = "Divran"
ENT.Contact         = "www.wiremod.com"
ENT.Purpose         = "Links with a plug"
ENT.Instructions    = "Move a plug close to a plug to link them, and data will be transferred through the link."

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

local PositionOffsets = {
	["models/props_lab/tpplugholder_single.mdl"] = Vector(5, 13, 10),
	["models/bull/various/usb_socket.mdl"] = Vector(8,0,0)
}
local AngleOffsets = {
	["models/props_lab/tpplugholder_single.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_socket.mdl"] = Angle(0,0,0),
}
local SocketModels = {
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
}

function ENT:GetLinkPos()
	return self:LocalToWorld(PositionOffsets[self:GetModel()]), self:LocalToWorldAngles(AngleOffsets[self:GetModel()])
end

function ENT:CanLink( Target )
	if (Target.Socket and Target.Socket:IsValid()) then return false end
	if (SocketModels[self:GetModel()] != Target:GetModel()) then return false end
	return true
end

function ENT:GetClosestPlug()
	local Pos, _ = self:GetLinkPos()

	local plugs = ents.FindInSphere( Pos, (CLIENT and self:GetNWInt( "AttachRange", 5 ) or self.AttachRange) )

	local ClosestDist
	local Closest

	for k,v in pairs( plugs ) do
		if (v:GetClass() == "gmod_wire_plug") then
			local Dist = v:GetPos():Distance( Pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end
