include('shared.lua')

ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:Initialize()
	self.GPU = WireGPU(self)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	self:DrawModel()


	if (true) then
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
	end

	self.GPU:Render()
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end
