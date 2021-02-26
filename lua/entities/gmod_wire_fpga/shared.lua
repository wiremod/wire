DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire FPGA"
ENT.Author = "Lysdal"
ENT.Contact = "https://steamcommunity.com/id/lysdal1234/"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "FPGA"

CreateConVar("wire_fpga_quota_avg", "2000", {FCVAR_REPLICATED})
CreateConVar("wire_fpga_quota_spike", "-1", {FCVAR_REPLICATED})


if CLIENT then return end

--------------------------------------------------------------------------------
-- Inside view syncing
--------------------------------------------------------------------------------

util.AddNetworkString("wire_fpga_view_data")

timer.Create("WireFPGAViewDataUpdate", 1.0, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) and ent:GetClass() == "gmod_wire_fpga" and ent.ViewData then
			net.Start("wire_fpga_view_data")
				net.WriteEntity(ent)
				net.WriteString(ent.ViewData)
			net.Send(ply)
		end
	end
end)
