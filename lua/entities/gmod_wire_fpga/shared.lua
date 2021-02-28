DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire FPGA"
ENT.Author = "Lysdal"
ENT.Contact = "https://steamcommunity.com/id/lysdal1234/"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "FPGA"

CreateConVar("wire_fpga_quota_avg", "2000", {FCVAR_REPLICATED})
CreateConVar("wire_fpga_quota_spike", "-1", {FCVAR_REPLICATED})



--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------
FPGATypeEnum = {
  NORMAL = 1,
  VECTOR2 = 2,
  VECTOR = 3,
  VECTOR4 = 4,
  ANGLE = 5,
  STRING = 6,
  ARRAY = 7,
  ENTITY = 8,
  RANGER = 9,
  WIRELINK = 10,
}

FPGATypeEnumLookup = {
  "NORMAL",
  "VECTOR2",
  "VECTOR",
  "VECTOR4",
  "ANGLE",
  "STRING",
  "ARRAY",
  "ENTITY",
  "RANGER",
  "WIRELINK",
}

FPGANodeSize = 5



if CLIENT then return end

--------------------------------------------------------------------------------
-- Inside view syncing
--------------------------------------------------------------------------------

util.AddNetworkString("wire_fpga_view_data")

timer.Create("WireFPGAViewDataUpdate", 1.0, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) and ent:GetClass() == "gmod_wire_fpga" and ent.ViewData and ply:KeyDown(IN_USE) then
			net.Start("wire_fpga_view_data")
				net.WriteEntity(ent)
				net.WriteString(ent.ViewData)
			net.Send(ply)
		end
	end
end)
