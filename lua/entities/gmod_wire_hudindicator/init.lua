
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

DEFINE_BASECLASS("base_wire_entity")

ENT.WireDebugName = "HUD Indicator"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.A = 0
	self.AR = 0
	self.AG = 0
	self.AB = 0
	self.AA = 0
	self.B = 0
	self.BR = 0
	self.BG = 0
	self.BB = 0
	self.BA = 0

	-- List of players who have hooked this indicator
	self.RegisteredPlayers = {}
	self.PrefixText = "(Hud) Color = "

	self.Inputs = Wire_CreateInputs(self, { "A", "HideHUD" })
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle)
	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.B = b or 1
	self.BR = br or 0
	self.BG = bg or 255
	self.BB = bb or 0
	self.BA = ba or 255
	self:SetMaterial(material)

	local ttable = {
		a	= a,
		ar	= ar,
		ag	= ag,
		ab	= ab,
		aa	= aa,
		b	= b,
		br	= br,
		bg	= bg,
		bb	= bb,
		ba	= ba,
		material = material,
		showinhud = showinhud,
		huddesc = huddesc,
		hudaddname = hudaddname,
		hudshowvalue = hudshowvalue,
		hudstyle = hudstyle,
		allowhook = allowhook,
		fullcircleangle = fullcircleangle
	}
	table.Merge(self:GetTable(), ttable )

	self:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle)
end

-- For HUD Indicators
function ENT:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle)
	local ply = self:GetPlayer()
	-- If user updates with the STool to take indicator off of HUD
	if not showinhud and self.ShowInHUD then
		self:UnRegisterPlayer(ply)

		-- Adjust inputs back to normal
		--Wire_AdjustInputs(self, { "A" })
	elseif (showinhud) then
		-- Basic style is useless without a value
		-- to show so set a default if necessary
		if hudstyle == 0 and hudshowvalue == 0 then
			hudshowvalue = 1
		end

		if not self:CheckRegister(ply) then
			-- First-time register
			-- Updating this player is handled further down
			self:RegisterPlayer(ply, true)
		end

		-- Add name if desired
		if (hudaddname) then
			self:SetNWString("WireName", huddesc)
		elseif (self:GetNWString("WireName") == huddesc) then
			-- Only remove it if the HUD Description was there
			-- because there might be another name on it
			self:SetNWString("WireName", "")
		end

		-- Adjust inputs accordingly
		--[[ if (!self.Inputs.HideHUD) then
			Wire_AdjustInputs(self, { "A", "HideHUD" })
			self:TriggerInput("HideHUD", 0)
			self.PrevHideHUD = false
		end ]]
	end

	self.ShowInHUD = showinhud
	self.HUDDesc = huddesc
	self.HUDAddName = hudaddname
	self.HUDShowValue = hudshowvalue
	self.HUDStyle = hudstyle
	self.AllowHook = allowhook
	self.FullCircleAngle = fullcircleangle

	-- To tell if you can hook a HUD Indicator at a glance
	if (allowhook) then
		self.PrefixText = "(Hud) Color = "
	else
		self.PrefixText = "(Hud - Locked) Color = "
	end

	-- Update all registered players with this info
	for _, v in pairs(self.RegisteredPlayers) do
		self:RegisterPlayer(v.ply, v.hookhidehud)
	end

	-- Only trigger this input on the
	-- first time that Setup() is called
	if not self.HasBeenSetup then
		self:TriggerInput("A", self.A)
		self:TriggerInput("HideHUD", 0)
		self.PrevHideHUD = false
		self.HasBeenSetup = true
	end
end

-- This is called from RegisterPlayer to send any style-specific info
function ENT:SetupHUDStyle(hudstyle, rplayer)
	-- 0 (Basic) and 1 (Gradient) don't require any extra info
	local pl = rplayer or self:GetPlayer()
	-- Allow for hooked players
	--if (rplayer) then pl = rplayer end

	if (hudstyle == 2) then -- Percent Bar
		-- Send as string (there should be a way to send colors)
		local ainfo = self.AR.."|"..self.AG.."|"..self.AB
		local binfo = self.BR.."|"..self.BG.."|"..self.BB
		umsg.Start("HUDIndicatorStylePercent", pl)
			umsg.Short(self:EntIndex())
			umsg.String(ainfo)
			umsg.String(binfo)
		umsg.End()
	elseif (hudstyle == 3) then -- Full Circle Gauge
		umsg.Start("HUDIndicatorStyleFullCircle", pl)
			umsg.Short(self:EntIndex())
			umsg.Float(self.FullCircleAngle)
		umsg.End()
	end
end

-- Hook this player to the HUD Indicator
function ENT:RegisterPlayer(ply, hookhidehud, podonly)
	local plyuid = ply:UniqueID()
	local eindex = self:EntIndex()

	-- If player is already registered, this will send an update
	-- The podonly is used for players who are registered only because they are in a linked pod
	if not self.RegisteredPlayers[plyuid] then
		self.RegisteredPlayers[plyuid] = { ply = ply, hookhidehud = hookhidehud, podonly = podonly }
		-- This is used to check for pod-only status in ClientCheckRegister()
		self:SetNWBool( plyuid, util.tobool(podonly) )
	end

	umsg.Start("HUDIndicatorRegister", ply)
		umsg.Short(eindex)
		umsg.String(self.HUDDesc or "")
		umsg.Short(self.HUDShowValue)
		umsg.Short(self.HUDStyle)
	umsg.End()
	self:SetupHUDStyle(self.HUDStyle, ply)

	-- Trigger inputs to fully add this player to the list
	-- Force factor to update
	self.PrevOutput = nil
	self:TriggerInput("A", self.Inputs.A.Value)
	if (hookhidehud) then
		self:TriggerInput("HideHUD", self.Inputs.HideHUD.Value)
	end
end

function ENT:UnRegisterPlayer(ply)
	umsg.Start("HUDIndicatorUnRegister", ply)
		umsg.Short(self:EntIndex())
	umsg.End()
	self.RegisteredPlayers[ply:UniqueID()] = nil
end

-- Is this player registered?
function ENT:CheckRegister(ply)
	return self.RegisteredPlayers[ply:UniqueID()] ~= nil
end

-- Is this player registered only because he is in a linked pod?
function ENT:CheckPodOnly(ply)
	if not ply or not ply:IsValid() then return false end
	local plyuid = ply:UniqueID()
	return self.RegisteredPlayers[plyuid] ~= nil and self.RegisteredPlayers[plyuid].podonly
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local factor = math.Clamp((value-self.A)/(self.B-self.A), 0, 1)
		self:ShowOutput(factor, value)

		local r = math.Clamp((self.BR-self.AR)*factor+self.AR, 0, 255)
		local g = math.Clamp((self.BG-self.AG)*factor+self.AG, 0, 255)
		local b = math.Clamp((self.BB-self.AB)*factor+self.AB, 0, 255)
		local a = math.Clamp((self.BA-self.AA)*factor+self.AA, 0, 255)
		self:SetColor(Color(r, g, b, a))
	elseif (iname == "HideHUD") then
		if (self.PrevHideHUD == (value > 0)) then return end

		self.PrevHideHUD = (value > 0)
		-- Value has updated, so send information
		self:SendHUDInfo(self.PrevHideHUD)
	end
end

function ENT:ShowOutput(factor, value)
	if (factor ~= self.PrevOutput) then
		self:SetOverlayText( self.PrefixText .. string.format("%.1f", (factor * 100)) .. "%" )
		self.PrevOutput = factor

		local rf = RecipientFilter()
		local pl = self:GetPlayer()

		-- RecipientFilter will contain all registered players
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if (rplayer.ply and rplayer.ply:IsValid()) then
				if rplayer.ply ~= pl or (self.ShowInHUD or self.PodPly == pl) then
					rf:AddPlayer(rplayer.ply)
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end

		umsg.Start("HUDIndicatorFactor", rf)
			umsg.Short(self:EntIndex())
			-- Send both to ensure that all styles work properly
			umsg.Float(factor)
			umsg.Float(value)
		umsg.End()
	end
end

function ENT:SendHUDInfo(hidehud)
	-- Sends information to player
	local pl = self:GetPlayer()

	for index,rplayer in pairs(self.RegisteredPlayers) do
		if (rplayer.ply) then
			if rplayer.ply ~= pl or (self.ShowInHUD or self.PodPly == pl) then
				umsg.Start("HUDIndicatorHideHUD", rplayer.ply)
					umsg.Short(self:EntIndex())
					-- Check player's preference
					if (rplayer.hookhidehud) then
						umsg.Bool(hidehud)
					else
						umsg.Bool(false)
					end
				umsg.End()
			end
		else
			self.RegisteredPlayers[index] = nil
		end
	end
end

-- Despite everything being named "pod", any vehicle will work
function ENT:LinkEnt(pod)
	pod = WireLib.GetClosestRealVehicle(pod, self:GetPos(), self:GetPlayer())
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end

	local ply = nil
	-- Check if a player is in pod first
	for _, v in pairs(player.GetAll()) do
		if (v:GetVehicle() == pod) then
			ply = v
			break
		end
	end

	if ply and not self:CheckRegister(ply) then
		-- Register as "only in pod" if not registered before
		self:RegisterPlayer(ply, false, true)

		-- Force factor to update
		self.PrevOutput = nil
		self:TriggerInput("A", self.Inputs.A.Value)
	end
	self.Pod = pod
	self.PodPly = ply

	WireLib.SendMarks(self, {pod})

	return true
end

function ENT:UnlinkEnt()
	local ply = self.PodPly

	if ply and self:CheckPodOnly(ply) then
		-- Only unregister if player is registered only because he is in a linked pod
		self:UnRegisterPlayer(ply)
	end
	self.Pod = nil
	self.PodPly = nil

	WireLib.SendMarks(self, {})
end

function ENT:Think()
	BaseClass.Think(self)

	if IsValid(self.Pod) then
		local ply = nil

		if not IsValid(self.PodPly) or self.PodPly:GetVehicle() ~= self.Pod then
			for _, v in pairs(player.GetAll()) do
				if (v:GetVehicle() == self.Pod) then
					ply = v
					break
				end
			end
		else
			ply = self.PodPly
		end

		-- Has the player changed?
		if ply ~= self.PodPly then
			if self.PodPly and self:CheckPodOnly(self.PodPly) then -- Don't send umsg if player disconnected or is registered otherwise
				self:UnRegisterPlayer(self.PodPly)
			end

			self.PodPly = ply

			if self.PodPly and not self:CheckRegister(self.PodPly) then
				self:RegisterPlayer(self.PodPly, false, true)

				-- Force factor to update
				self.PrevOutput = nil
				self:TriggerInput("A", self.Inputs.A.Value)
			end
		end
	else
		-- If we deleted this pod and there was a player in it
		if self.PodPly and self:CheckPodOnly(self.PodPly) then
			self:UnRegisterPlayer(self.PodPly)
		end
		self.PodPly = nil
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

-- Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if (self.Pod) and (self.Pod:IsValid()) then
	    info.pod = self.Pod:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Pod = GetEntByID(info.pod)
end

duplicator.RegisterEntityClass("gmod_wire_hudindicator", WireLib.MakeWireEnt, "Data", "a", "ar", "ag", "ab", "aa", "b", "br",
	"bg", "bb", "ba", "material", "showinhud", "huddesc", "hudaddname", "hudshowvalue", "hudstyle", "allowhook", "fullcircleangle")
