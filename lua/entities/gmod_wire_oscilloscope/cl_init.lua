include('shared.lua')

if not ConVarExists("wire_oscilloscope_color") then
	CreateClientConVar("wire_oscilloscope_color", "0,255,0", false, false)
end
if not ConVarExists("wire_oscilloscope_length") then
	CreateClientConVar("wire_oscilloscope_length", 50, false, false)
end

ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:Initialize()
	self.GPU = WireGPU(self.Entity)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:Draw()
	self.Entity:DrawModel()


	if (true) then
		local oldw = ScrW()
		local oldh = ScrH()

		local length = math.Clamp(GetConVarNumber("wire_oscilloscope_length"),1,100)

		self.GPU:RenderToGPU(function()
			surface.SetDrawColor(10,20,5,255)
			surface.DrawRect(0,0,512,512)

			local nodes = self:GetNodeList()
			for i=1,length do
				local i_next = i+1

				local nx1 = nodes[i].X*256+256
				local ny1 = -nodes[i].Y*256+256
				local nx2 = nodes[i_next].X*256+256
				local ny2 = -nodes[i_next].Y*256+256

				if ((nx1-nx2)*(nx1-nx2) + (ny1-ny2)*(ny1-ny2) < 256*256) then
					local a = math.max(1,3.75-(3*i)/length)
					local a2 = math.max(1,a/2)

					local rgb = string.Explode(",", GetConVarString("wire_oscilloscope_color"))
					local r,g,b = tonumber(rgb[1]) or 0, tonumber(rgb[2]) or 200, tonumber(rgb[3]) or 0

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
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
