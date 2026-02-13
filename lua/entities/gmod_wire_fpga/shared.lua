DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire FPGA"
ENT.Author = ""
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "FPGA"

CreateConVar("wire_fpga_quota_avg", "2000", {FCVAR_REPLICATED})
CreateConVar("wire_fpga_quota_spike", "-1", {FCVAR_REPLICATED})



--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------
FPGADefaultValueForType = {
	NORMAL = 0,
	VECTOR2 = nil, --no
	VECTOR = Vector(0, 0, 0),
	VECTOR4 = nil, --no
	ANGLE = Angle(0, 0, 0),
	STRING = "",
	ARRAY = {},
	ENTITY = NULL,
	RANGER = nil,
	WIRELINK = nil
}

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





--------------------------------------------------------------------------------
-- Option syncing ((Server ->) Client -> Server)
--------------------------------------------------------------------------------
if CLIENT then
	function FPGASendOptionsToServer(options)
		net.Start("wire_fpga_options")
			net.WriteString(options)
		net.SendToServer()
	end

	-- Received request to send options
	net.Receive("wire_fpga_options", function(len)
		local options = FPGAGetOptions()

		FPGASendOptionsToServer(options)
	end)
end

if SERVER then
	FPGAPlayerOptions = {}

	util.AddNetworkString("wire_fpga_options")

	-- Request options from player
	timer.Create("WireFPGACheckForOptions", 1, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then continue end

			if not FPGAPlayerOptions[ply] then
				net.Start("wire_fpga_options")
				net.Send(ply)
			end
		end
	end)

	-- Receive options from player
	net.Receive("wire_fpga_options", function(len, ply)
		local ok, options = pcall(WireLib.von.deserialize, net.ReadString())

		if ok then
			FPGAPlayerOptions[ply] = options
		end
	end)
end

--------------------------------------------------------------------------------
-- Inside view syncing (Server -> Client)
--------------------------------------------------------------------------------
if SERVER then
	FPGAPlayerHasHash = {}

	util.AddNetworkString("wire_fpga_view_data")

	timer.Create("WireFPGAViewDataUpdate", 0.1, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then continue end --don't know why this happens, but it does

			if not ply:KeyDown(IN_USE) then continue end

			local ent = ply:GetEyeTrace().Entity

			if IsValid(ent) and ent:GetClass() == "gmod_wire_fpga" and ent:AllowsInsideView() and ent:GetViewData() then
				if not FPGAPlayerHasHash[ply] then FPGAPlayerHasHash[ply] = {} end

				if FPGAPlayerHasHash[ply][ent:GetTimeHash()] then
					--player already has this inside view
					continue
				end

				FPGAPlayerHasHash[ply][ent:GetTimeHash()] = true

				local data = util.Compress(ent:GetViewData())

				net.Start("wire_fpga_view_data")
					net.WriteEntity(ent)
					net.WriteUInt(#data, 16)
					net.WriteData(data, #data)
				net.Send(ply)
			end
		end
	end)
end