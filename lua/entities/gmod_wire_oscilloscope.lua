AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Oscilloscope"
ENT.WireDebugName	= "Oscilloscope"

function ENT:SetNextNode(x, y)
	local node_idx = self:GetNWInt("OscN") or 0
	if (node_idx > self:GetNWFloat("Length", 50)) then node_idx = node_idx-self:GetNWFloat("Length", 50) end

	self:SetNWFloat("OscX"..node_idx, x)
	self:SetNWFloat("OscY"..node_idx, y)
	self:SetNWInt("OscN", node_idx+1)
end

function ENT:GetNodeList()
	local nodes = {}
	local node_idx = self:GetNWInt("OscN")
	local length = self:GetNWFloat("Length", 50)
	for i=1,length do
		table.insert(nodes, { X = (self:GetNWFloat("OscX"..node_idx, 0)), Y = (self:GetNWFloat("OscY"..node_idx, 0)) })

		node_idx = node_idx+1
		if (node_idx > length) then node_idx = node_idx-length end
	end

	return nodes
end

if CLIENT then 
	function ENT:Initialize()
		self.GPU = WireGPU(self)
	end

	function ENT:OnRemove()
		self.GPU:Finalize()
	end

	function ENT:Draw()
		self:DrawModel()

		local length = self:GetNWFloat("Length", 50)
		local r,g,b = self:GetNWFloat("R"), self:GetNWFloat("G"), self:GetNWFloat("B")
		if r == 0 and g == 0 and b == 0 then g = 200 end

		self.GPU:RenderToGPU(function()
			surface.SetDrawColor(10,20,5,255)
			surface.DrawRect(0,0,512,512)

			local nodes = self:GetNodeList()
			for i=1,length do
				local i_next = i+1
				if not nodes[i_next] then continue end

				local nx1 = nodes[i].X*256+256
				local ny1 = -nodes[i].Y*256+256
				local nx2 = nodes[i_next].X*256+256
				local ny2 = -nodes[i_next].Y*256+256

				if ((nx1-nx2)*(nx1-nx2) + (ny1-ny2)*(ny1-ny2) < 256*256) then
					local a = math.max(1, 3.75-(3*i)/length)^1.33
					local a2 = math.max(1, a/2)

					for i=-3,3 do
						surface.SetDrawColor(r/a, g/a, b/a, 255)
						surface.DrawLine(nx1, ny1+i, nx2, ny2+i)
						surface.SetDrawColor(r/a, g/a, b/a, 255)
						surface.DrawLine(nx1+i, ny1, nx2+i, ny2)
					end

					surface.SetDrawColor(r/a2, g/a2, b/a2, 255)
					surface.DrawLine(nx1, ny1, nx2, ny2)
				end
			end

			surface.SetDrawColor(30, 120, 10, 255)
			surface.DrawLine(0, 128, 512, 128)
			surface.DrawLine(0, 384, 512, 384)
			surface.DrawLine(128, 0, 128, 512)
			surface.DrawLine(384, 0, 384, 512)

			surface.SetDrawColor(180, 200, 10, 255)
			surface.DrawLine(0, 256, 512, 256)
			surface.DrawLine(256, 0, 256, 512)
		end)

		self.GPU:Render()
		Wire_Render(self)
	end
	
	return  -- No more client
end

-- Server

local wire_oscilloscope_maxlength = CreateConVar("wire_oscilloscope_maxlength", 100, {FCVAR_ARCHIVE}, "Maximum number of nodes")

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "X", "Y", "R", "G", "B", "Pause", "Length", "Update Frequency" })
end

function ENT:Think()
	if (self.Inputs.Pause.Value == 0) then
		self.BaseClass.Think(self)

		local x = math.max(-1, math.min(self.Inputs.X.Value or 0, 1))
		local y = math.max(-1, math.min(self.Inputs.Y.Value or 0, 1))
		self:SetNextNode(x, y)

		self:NextThink(CurTime()+(self.updaterate or 0.08))
		return true
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "R" then
		self:SetNWFloat("R", math.Clamp(value, 0, 255))
	elseif iname == "G" then
		self:SetNWFloat("G", math.Clamp(value, 0, 255))
	elseif iname == "B" then
		self:SetNWFloat("B", math.Clamp(value, 0, 255))
	elseif iname == "Length" then
		if value == 0 then value = 50 end
		self:SetNWFloat("Length", math.Clamp(value, 1, wire_oscilloscope_maxlength:GetInt()))
	elseif iname == "Update Frequency" then
		if value <= 0 then value = 0.08 end
		self.updaterate = value
	end
end

--[[
	hi-speed Addresses:
	0: X
	1: Y
	2: R
	3: G
	4: B
	5: Length
	6: Update frequency
]]
local address_lookup = {nil,nil,"R","G","B","Length","Update Frequency"}
function ENT:WriteCell( address, value )
	address = address + 1
	if address == 1 then
		self.Inputs.X.Value = value
	elseif address == 2 then
		self.Inputs.Y.Value = value
	elseif address_lookup[address] then
		self:TriggerInput( address_lookup[address], value )
	end
end

function ENT:ReadCell( address )
	address = address + 1
	if address == 1 then
		return self.Inputs.X.Value
	elseif address == 2 then
		return self.Inputs.Y.Value
	elseif address == 4 then
		return self.updaterate
	elseif address_lookup[address] then
		return self:GetNWFloat( address_lookup[address] )
	end

	return 0
end

duplicator.RegisterEntityClass("gmod_wire_oscilloscope", WireLib.MakeWireEnt, "Data")
