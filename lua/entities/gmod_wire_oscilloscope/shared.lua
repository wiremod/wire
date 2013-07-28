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
	local node_idx = self:GetNetworkedInt("OscN") or 0
	if (node_idx > 102) then node_idx = node_idx-102 end

	self:SetNetworkedFloat("OscX"..node_idx, x)
	self:SetNetworkedFloat("OscY"..node_idx, y)
	self:SetNetworkedInt("OscN", node_idx+1)
end

function ENT:GetNodeList()
	local nodes = {}
	local node_idx = self:GetNetworkedInt("OscN")
	for i=1,101 do
		table.insert(nodes, { X = (self:GetNetworkedFloat("OscX"..node_idx) or 0), Y = (self:GetNetworkedFloat("OscY"..node_idx) or 0) })

		node_idx = node_idx+1
		if (node_idx > 102) then node_idx = node_idx-102 end
	end

	return nodes
end
