include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Draw()
	self.BaseClass.Draw(self)
	Wire_Render(self.Entity)
end

local bindlist = ENT.bindlist
ENT.bindlist = nil

hook.Add("PlayerBindPress", "wire_adv_pod", function(ply, bind, pressed)
	if ply:InVehicle() then
		if bindlist[bind] then
			RunConsoleCommand("wire_adv_pod_bind", bind)
		end
	end
end)
