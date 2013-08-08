AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )
ENT.Type = "anim"
ENT.PrintName       = "Wire Unnamed Ent"
ENT.Purpose = "Base for all wired SEnts"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.IsWire = true
ENT.OverlayText = ""
local base_gmodentity = scripted_ents.Get("base_gmodentity")

if CLIENT then 
	local wire_drawoutline = CreateClientConVar("wire_drawoutline", 1, true, false)

	function ENT:Initialize()
		self.NextRBUpdate = CurTime() + 0.25
	end

	function ENT:Draw()
		self:DoNormalDraw()
		Wire_Render(self)
		if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then 
			-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
			Wire_DrawTracerBeam( self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false ) 
		end
	end

	function ENT:DoNormalDraw(nohalo, notip)
		local looked_at = self:BeingLookedAtByLocalPlayer()
		if not nohalo and wire_drawoutline:GetBool() and looked_at then
			if self.RenderGroup == RENDERGROUP_OPAQUE then
				self.OldRenderGroup = self.RenderGroup
				self.RenderGroup = RENDERGROUP_TRANSLUCENT
			end
			self:DrawEntityOutline()
			self:DrawModel()
		else
			if self.OldRenderGroup then
				self.RenderGroup = self.OldRenderGroup
				self.OldRenderGroup = nil
			end
			self:DrawModel()
		end
		if not notip and looked_at then
			AddWorldTip(self:EntIndex(), self:GetOverlayText(), 0.5, self:GetPos(), self)
		end
	end

	function ENT:Think()
		if (CurTime() >= (self.NextRBUpdate or 0)) then
			self.NextRBUpdate = CurTime() + math.random(30,100)/10 --update renderbounds every 3 to 10 seconds
			Wire_UpdateRenderBounds(self)
		end
	end

	local halos = {}
	local halos_inv = {}

	function ENT:DrawEntityOutline()
		if halos_inv[self] then return end
		halos[#halos+1] = self
		halos_inv[self] = true
	end

	hook.Add("PreDrawHalos", "Wiremod_overlay_halos", function()
		if #halos == 0 then return end
		halo.Add(halos, Color(100,100,255), 3, 3, 1, true, true)
		halos = {}
		halos_inv = {}
	end)

	function ENT:GetOverlayText()
		local name = self:GetNetworkedString("WireName")
		if name == "" then name = self.PrintName end
		local header = "- " .. name .. " -"
		local message = base_gmodentity.GetOverlayText(self)
		if message == "" then
			return header
		else
			return header .. "\n" .. message
		end
	end
	
	return  -- No more client
end

-- Server

-- We want more fine-grained control over the networking of the overlay text,
-- so we don't just immediately send it like base_gmodentity does.
function ENT:SetOverlayText( txt )
	self.OverlayText = txt
end

function ENT:Initialize()
	base_gmodentity.Initialize(self)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.WireDebugName = self.WireDebugName or (self.PrintName and self.PrintName:sub(6)) or self:GetClass():gsub("gmod_wire", "")
end

timer.Create("WireOverlayUpdate", 0.1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) and ent.IsWire then base_gmodentity.SetOverlayText(ent, ent.OverlayText) end
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
	local DupeInfo = self:BuildDupeInfo()
	if DupeInfo then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", DupeInfo)
	end
end

local function EntityLookup(CreatedEntities)
	return function(id, default)
		if id == nil then return default end
		if id == 0 then return game.GetWorld() end
		local ent = CreatedEntities[id] or (isnumber(id) and ents.GetByIndex(id))
		if IsValid(ent) then return ent else return default end
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	-- We manually apply the entity mod here rather than using a
	-- duplicator.RegisterEntityModifier because we need access to the
	-- CreatedEntities table.
	if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup(CreatedEntities))
	end
end
