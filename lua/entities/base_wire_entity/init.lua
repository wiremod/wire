AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "No Name"
function ENT:Think()
end

function ENT:SetOverlayText( txt )
	self.OverlayText = txt
end

util.AddNetworkString("WireOverlay")


local function overlayUpdate()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) == false then return end
		if ent.OverlayText == nil then return end
		-- send update.
		net.Start("WireOverlay")
		net.WriteEntity( ent )
		net.WriteString( ent.OverlayText )
		net.Send( ply )
	end
end

timer.Create("OverlayUpdate", 0.25, 0, overlayUpdate )

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
