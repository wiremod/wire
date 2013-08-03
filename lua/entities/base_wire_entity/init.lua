AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "No Name"

local BaseClass = baseclass.Get("base_gmodentity")

-- We want more fine-grained control over the networking of the oerlay text,
-- so we don't just immediately send it like base_gmodentity does.
function ENT:SetOverlayText( txt )
	self.OverlayText = txt
end

timer.Create("WireOverlayUpdate", 0.1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		BaseClass.SetOverlayText(ent, ent.OverlayText)
	end
end)

function ENT:OnRemove()
	WireLib.Remove(self)
end

function ENT:OnRestore()
    WireLib.Restored(self)
end

function ENT:BuildDupeInfo()
	return WireLib.BuildDupeInfo(self)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
end

function ENT:PreEntityCopy()
	-- build the DupeInfo table and save it as an entity mod
	duplicator.StoreEntityModifier(self, "WireDupeInfo", self:BuildDupeInfo())
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	-- We manually apply the entity mod here rather than using a
	-- duplicator.RegisterEntityModifier because we need access to the
	-- CreatedEntities table.
	if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end
