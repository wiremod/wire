DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire FPGA"
ENT.Author = "Lysdal"
ENT.Contact = "https://steamcommunity.com/id/lysdal1234/"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "FPGA"

CreateConVar("wire_fpga_quota_avg", "2000", {FCVAR_REPLICATED})
CreateConVar("wire_fpga_quota_spike", "-1", {FCVAR_REPLICATED})

if CLIENT then
	file.CreateDir("fpgachip")
end