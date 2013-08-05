AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Oscilloscope"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName	= "Oscilloscope"


-- Shared

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

if CLIENT then 
	function ENT:Initialize()
		self.GPU = WireGPU(self)
	end

	function ENT:OnRemove()
		self.GPU:Finalize()
	end

	function ENT:Draw()
		self:DrawModel()

		local oldw = ScrW()
		local oldh = ScrH()

		local length = math.Clamp(self:GetNetworkedFloat("Length"), 1, 100)
		if self:GetNetworkedFloat("Length") <= 0 then length = 50 end

		self.GPU:RenderToGPU(function()
			surface.SetDrawColor(10,20,5,255)
			surface.DrawRect(0,0,512,512)

			local nodes = self:GetNodeList()
			for i=101-length,100 do
				local i_next = i+1

				local nx1 = nodes[i].X*256+256
				local ny1 = -nodes[i].Y*256+256
				local nx2 = nodes[i_next].X*256+256
				local ny2 = -nodes[i_next].Y*256+256

				if ((nx1-nx2)*(nx1-nx2) + (ny1-ny2)*(ny1-ny2) < 256*256) then
					local a = math.max(1, 3.75-(3*(i-100+length))/length)
					local a2 = math.max(1, a/2)

					local r,g,b = math.Clamp(self:GetNetworkedFloat("R"), 0, 255), math.Clamp(self:GetNetworkedFloat("G"), 0, 255), math.Clamp(self:GetNetworkedFloat("B"), 0, 255)
					if r <= 0 and g <= 0 and b <= 0 then g = 200 end

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

	function ENT:IsTranslucent() return true end
	
	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "X", "Y", "R", "G", "B", "Pause", "Length", "Update Frequency" })
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
		self:SetNetworkedFloat("R", value)
	elseif iname == "G" then
		self:SetNetworkedFloat("G", value)
	elseif iname == "B" then
		self:SetNetworkedFloat("B", value)
	elseif iname == "Length" then
		self:SetNetworkedFloat("Length", value)
	elseif iname == "Update Frequency" then
		if value <= 0 then value = 0.08 end
		self.updaterate = value
	end
end

function MakeWireOscilloscope( pl, Pos, Ang, model )

	if ( !pl:CheckLimit( "wire_oscilloscopes" ) ) then return false end

	local wire_oscilloscope = ents.Create( "gmod_wire_oscilloscope" )
	if (!wire_oscilloscope:IsValid()) then return false end
	wire_oscilloscope:SetModel( model )

	wire_oscilloscope:SetAngles( Ang )
	wire_oscilloscope:SetPos( Pos )
	wire_oscilloscope:Spawn()

	wire_oscilloscope:SetPlayer(pl)
	wire_oscilloscope.pl = pl

	pl:AddCount( "wire_oscilloscopes", wire_oscilloscope )

	return wire_oscilloscope
end

duplicator.RegisterEntityClass("gmod_wire_oscilloscope", MakeWireOscilloscope, "Pos", "Ang", "Model")
