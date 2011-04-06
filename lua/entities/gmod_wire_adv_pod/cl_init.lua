include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Draw()
	self.BaseClass.Draw(self)
	Wire_Render(self)
end

local bindlist = ENT.bindlist
ENT.bindlist = nil

hook.Add("PlayerBindPress", "wire_adv_pod", function(ply, bind, pressed)
	if ply:InVehicle() then
		if (bind == "invprev") then
			bind = "1"
		elseif (bind == "invnext") then
			bind = "2"
		elseif (bind == "impulse 100") then
			bind = "3"
		else return end
		RunConsoleCommand("wire_adv_pod_bind", bind )
	end
end)
