ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Oscilloscope"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetNextNode(x, y)
	local node_idx = self.Entity:GetNetworkedInt("OscN") or 0
	if (node_idx > 41) then node_idx = node_idx-41 end

	self.Entity:SetNetworkedFloat("OscX"..node_idx, x)
	self.Entity:SetNetworkedFloat("OscY"..node_idx, y)
	self.Entity:SetNetworkedInt("OscN", node_idx+1)
end

function ENT:GetNodeList()
	local nodes = {}
	local node_idx = self.Entity:GetNetworkedInt("OscN")
	for i=1,40 do
		table.insert(nodes, { X = (self.Entity:GetNetworkedFloat("OscX"..node_idx) or 0), Y = (self.Entity:GetNetworkedFloat("OscY"..node_idx) or 0) })

		node_idx = node_idx+1
		if (node_idx > 41) then node_idx = node_idx-41 end
	end

	return nodes
end
