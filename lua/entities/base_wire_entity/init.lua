AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("WireOverlay")

ENT.WireDebugName = "No Name"

local playerOverlays = {}
timer.Create("WireOverlayUpdate", 0.1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if not IsValid(ent) or not ent.IsWire then continue end
		playerOverlays[ply] = playerOverlays[ply] or {}
		if playerOverlays[ply][ent] != ent.OverlayText then
			playerOverlays[ply][ent] = ent.OverlayText
			net.Start("WireOverlay")
				net.WriteEntity(ent)
				net.WriteString(ent.OverlayText)
			net.Send(ply)
		end
	end
end)

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:OnRestore()
    Wire_Restored(self)
end

function ENT:BuildDupeInfo()
	return WireLib.BuildDupeInfo(self)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end

function ENT:PreEntityCopy()
	//build the DupeInfo table and save it as an entity mod
	local DupeInfo = self:BuildDupeInfo()
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self,"WireDupeInfo",DupeInfo)
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	//apply the DupeInfo
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end
