AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )
ENT.Type = "anim"
ENT.PrintName       = "Wire Unnamed Ent"
ENT.Purpose = "Base for all wired SEnts"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.IsWire = true

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
	
	local WorldTip = { dietime = 0 }
	function ENT:AddWorldTip( txt )
		WorldTip.dietime = SysTime() + RealFrameTime() * 4
		WorldTip.ent = self
	end
	
	local edgesize = 18
	
	 -- makes sure the overlay doesn't go out of the screen & provides several useful sizes and positions for the DrawBody function
	function ENT:GetWorldTipPositions( w, h, w_body, h_body, w_footer, h_footer )
		local pos = LocalPlayer():GetEyeTrace().HitPos
		local spos = LocalPlayer():GetShootPos()
		if pos == spos then -- if the position is right in your face, get a better position
			pos = spos + LocalPlayer():GetAimVector() * 5
		end
		pos = pos:ToScreen()
		
		pos.x = math.Round(pos.x)
		pos.y = math.Round(pos.y)
		
		w = math.min( w, ScrW() - 64 )
		h = math.min( h, ScrH() - 64 )
		
		local maxx = pos.x - 32
		local maxy = pos.y - 32
		
		local minx = maxx - w
		local miny = maxy - h
		
		if minx < 32 then
			maxx = 32 + w
			minx = 32
		end
		
		if miny < 32 then
			maxy = 32 + h
			miny = 32
		end
		
		local centerx = (maxx+minx)/2
		local centery = (maxy+miny)/2
		
		return {	min = {x = minx,y = miny},
					max = {x = maxx,y = maxy}, 
					center = {x = centerx, y = centery},
					size = {w = w, h = h},
					bodysize = {w = w_body, h = h_body },
					footersize = {w = w_footer, h = h_footer},
					edgesize = edgesize
				}
	end

	-- This is overridable by other wire entities which want to customize the overlay, but generally you shouldn't override it
	function ENT:DrawWorldTipOutline( pos )
		draw.NoTexture()
		surface.SetDrawColor(Color(25,25,25,200))
		
		local poly = {
						{x = pos.min.x + edgesize, 			y = pos.min.y,					u = 0, v = 0 },
						{x = pos.max.x, 					y = pos.min.y,					u = 0, v = 0 },
						{x = pos.max.x, 					y = pos.max.y - edgesize + 0.5,	u = 0, v = 0 },
						{x = pos.max.x - edgesize + 0.5, 	y = pos.max.y,					u = 0, v = 0 },
						{x = pos.min.x, 					y = pos.max.y,					u = 0, v = 0 },
						{x = pos.min.x, 					y = pos.min.y + edgesize,		u = 0, v = 0 },
					}
		
		render.CullMode(MATERIAL_CULLMODE_CCW)
		surface.DrawPoly( poly )
		
		surface.SetDrawColor(Color(0,0,0,255))
		
		for i=1,#poly-1 do
			surface.DrawLine( poly[i].x, poly[i].y, poly[i+1].x, poly[i+1].y )
		end
		surface.DrawLine( poly[#poly].x, poly[#poly].y, poly[1].x, poly[1].y )
	end
	
	local function getWireName( ent )
		local name = ent:GetNWString("WireName")
		if not name or name == "" then return ent.PrintName else return name end
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:GetWorldTipBodySize()
		local txt = self:GetOverlayData().txt
		if txt == nil or txt == "" then return 0,0 end
		return surface.GetTextSize( txt )
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:DrawWorldTipBody( pos )
		local data = self:GetOverlayData()
		draw.DrawText( data.txt, "GModWorldtip", pos.center.x, pos.min.y + edgesize/2, Color(255,255,255,255), TEXT_ALIGN_CENTER )
	end
	
	-- This is overridable by other wire entities which want to customize the overlay
	function ENT:DrawWorldTip()
		local data = self:GetOverlayData()
		if not data then return end
		
		surface.SetFont( "GModWorldtip" )
		
		local txt = data.txt
		local class = getWireName( self ) .. " [" .. self:EntIndex() .. "]"
		local name = "(" .. self:GetPlayerName() .. ")"
	
		local w_body, 	h_body = self:GetWorldTipBodySize()
		local w_class, 	h_class = surface.GetTextSize( class )
		local w_name, 	h_name = surface.GetTextSize( name )
		
		local w_total = txt ~= "" and w_body or 0
		local h_total = txt ~= "" and h_body or 0
		
		local w_footer, h_footer = 0, 0
		
		local info_requires_multiline = false
		if w_total < w_class + w_name - edgesize then
			info_requires_multiline = true
			
			w_footer = math.max(w_total,w_class,w_name)
			h_footer = h_class + h_name + edgesize + 8
			
			w_total = w_footer
			h_total = h_total + h_footer
		else
			w_footer = math.max(w_total,w_class + 8 + w_name)
			h_footer = math.max(h_class,h_name) + edgesize + 8
			
			w_total = w_footer
			h_total = h_total + h_footer
		end
		
		if h_body == 0 then h_total = h_total - h_body - edgesize end
		
		local pos = self:GetWorldTipPositions( w_total + edgesize*2,h_total + edgesize,
												w_body,h_body,
												w_footer,h_footer )

		self:DrawWorldTipOutline( pos )
		
		local offset = pos.min.y
		if h_body > 0 then
			self:DrawWorldTipBody( pos )
			offset = offset + h_body + edgesize
			
			surface.SetDrawColor( Color(0,0,0,255) )
			surface.DrawLine( pos.min.x, offset, pos.max.x, offset )
		end
		
		if info_requires_multiline then
			draw.DrawText( class, "GModWorldtip", pos.center.x, offset + 8, Color(255,255,255,255), TEXT_ALIGN_CENTER )
			draw.DrawText( name, "GModWorldtip", pos.center.x, offset + h_class + 16, Color(255,255,255,255), TEXT_ALIGN_CENTER )
		else
			draw.DrawText( class, "GModWorldtip", pos.min.x + edgesize, offset + 16, Color(255,255,255,255) )
			draw.DrawText( name, "GModWorldtip", pos.min.x + pos.size.w - w_name - edgesize, offset + 16, Color(255,255,255,255) )
		end
	end
	
	hook.Add("HUDPaint","wire_draw_world_tips",function()
		if SysTime() > WorldTip.dietime then return end
	
		local ent = WorldTip.ent
		if not IsValid(ent) then return end
		
		ent:DrawWorldTip()
	end)
	
	-- Custom better version of this base_gmodentity function
	function ENT:BeingLookedAtByLocalPlayer()
		local trace = LocalPlayer():GetEyeTrace()
		
		if trace.Entity ~= self then return false end
		if trace.HitPos:Distance(LocalPlayer():GetShootPos()) > 200 then return false end
	
		return true
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
			self:AddWorldTip()
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
	
	--------------------------------------------------------------------------------
	-- Overlay getting
	--------------------------------------------------------------------------------
	
	-- Basic legacy GetOverlayText, is no longer used here but we leave it here in case other addons rely on it.
	function ENT:GetOverlayText()
		local name = self:GetNWString("WireName")
		if name == "" then name = self.PrintName end
		local header = "- " .. name .. " -"
		
		local data = self:GetOverlayData()
		if data and data.txt then
			return header .. "\n" .. data.txt
		else
			return header
		end
	end
	
	--------------------------------------------------------------------------------
	-- Overlay receiving
	--------------------------------------------------------------------------------
	net.Receive( "wire_overlay_data", function( len )
		local ent = net.ReadEntity()
		if IsValid( ent ) then
			ent.OverlayData = net.ReadTable()
		end
	end )
end

--------------------------------------------------------------------------------
-- Overlay setting
--------------------------------------------------------------------------------
-- We want more fine-grained control over everything related to overlays,
-- so we have a custom system here

-- It allows us to optionally send values rather than entire strings, which saves networking
-- It also allows us to only update overlays when someone is looking at the entity.

function ENT:SetOverlayText( txt )
	if not self.OverlayData then
		self.OverlayData = {}
	end
	
	if txt and #txt > 12000 then
		txt = string.sub(txt,1,12000) -- I have tested this and 12000 chars is enough to cover the entire screen at 1920x1080. You're unlikely to need more
	end
	
	self.OverlayData.txt = txt
	
	if not self.OverlayData_UpdateTime then	self.OverlayData_UpdateTime = {} end
	self.OverlayData_UpdateTime.time = CurTime()
end

function ENT:SetOverlayData( data )
	self.OverlayData = data
	if self.OverlayData.txt and #self.OverlayData.txt > 12000 then
		self.OverlayData.txt = string.sub(self.OverlayData.txt,1,12000)
	end
	
	if not self.OverlayData_UpdateTime then	self.OverlayData_UpdateTime = {} end
	self.OverlayData_UpdateTime.time = CurTime()
end

function ENT:GetOverlayData()
	return self.OverlayData
end

if CLIENT then return end -- no more client

--------------------------------------------------------------------------------
-- Overlay syncing
--------------------------------------------------------------------------------

util.AddNetworkString( "wire_overlay_data" )

timer.Create("WireOverlayUpdate", 0.1, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) and ent.IsWire and 
			ent.OverlayData and 
			ent.OverlayData_UpdateTime and 
			ent.OverlayData_UpdateTime.time > (ent.OverlayData_UpdateTime[ply] or 0) then
			
			ent.OverlayData_UpdateTime[ply] = CurTime()
			
			net.Start( "wire_overlay_data" )
				net.WriteEntity( ent )
				net.WriteTable( ent.OverlayData )
			net.Send( ply )
		end
	end
end)

--------------------------------------------------------------------------------
-- Other functions
--------------------------------------------------------------------------------

local base_gmodentity = scripted_ents.Get("base_gmodentity")
function ENT:Initialize()
	base_gmodentity.Initialize(self)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.WireDebugName = self.WireDebugName or (self.PrintName and self.PrintName:sub(6)) or self:GetClass():gsub("gmod_wire", "")
end

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

function ENT:OnEntityCopyTableFinish(dupedata)
	-- Called by Garry's duplicator, to modify the table that will be saved about an ent
	
	-- Remove anything with non-string keys, or util.TableToJSON will crash the game
	dupedata.OverlayData_UpdateTime = nil
end

local function EntityLookup(CreatedEntities)
	return function(id, default)
		if id == nil then return default end
		if id == 0 then return game.GetWorld() end
		local ent = CreatedEntities[id] or (isnumber(id) and ents.GetByIndex(id))
		if IsValid(ent) then return ent else return default end
	end
end

function ENT:OnDuplicated()
	self.DuplicationInProgress = true
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	-- We manually apply the entity mod here rather than using a
	-- duplicator.RegisterEntityModifier because we need access to the
	-- CreatedEntities table.
	if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup(CreatedEntities))
	end
	self.DuplicationInProgress = nil
end
