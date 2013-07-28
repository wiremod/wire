ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Socket"
ENT.Author          = "Divran"
ENT.Contact         = "www.wiremod.com"
ENT.Purpose         = "Links with a plug"
ENT.Instructions    = "Move a plug close to a plug to link them, and data will be transferred through the link."

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

list.Set( "wire_socket_models", "models/props_lab/tpplugholder_single.mdl", {} )
list.Set( "wire_socket_models", "models/bull/various/usb_socket.mdl", {} )
list.Set( "wire_socket_models", "models/hammy/pci_slot.mdl", {} )
list.Set( "wire_socket_models", "models/wingf0x/isasocket.mdl", {} )
list.Set( "wire_socket_models", "models/wingf0x/altisasocket.mdl", {} )
list.Set( "wire_socket_models", "models/wingf0x/ethernetsocket.mdl", {} )
list.Set( "wire_socket_models", "models/wingf0x/hdmisocket.mdl", {} )

local PositionOffsets = {
	["models/wingf0x/isasocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Vector(0,0,2.6),
	["models/wingf0x/ethernetsocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Vector(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Vector(5, 13, 10),
	["models/bull/various/usb_socket.mdl"] = Vector(8,0,0),
	["models/hammy/pci_slot.mdl"] = Vector(0,0,0),
	["models//hammy/pci_slot.mdl"] = Vector(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local AngleOffsets = {
	["models/wingf0x/isasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/ethernetsocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Angle(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_socket.mdl"] = Angle(0,0,0),
	["models/hammy/pci_slot.mdl"] = Angle(0,0,0),
	["models//hammy/pci_slot.mdl"] = Angle(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local SocketModels = {
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl",
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models//hammy/pci_slot.mdl"] = "models//hammy/pci_card.mdl", -- For some reason, GetModel on this model has two / on the client... Bug?
}

function ENT:GetLinkPos()
	return self:LocalToWorld(PositionOffsets[self:GetModel()] or Vector(0,0,0)), self:LocalToWorldAngles(AngleOffsets[self:GetModel()] or Angle(0,0,0))
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
		if (v:GetClass() == "gmod_wire_plug" and !v:GetNWBool( "Linked", false )) then
			local Dist = v:GetPos():Distance( Pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end
