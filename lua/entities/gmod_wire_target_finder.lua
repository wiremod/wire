AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Target Finder"
ENT.WireDebugName = "Target Finder"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "Hold" })
	self.Outputs = WireLib.CreateSpecialOutputs( self, { "Out" }, { "ENTITY" } )
end

function ENT:Setup(maxrange, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel, vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist )	
	local ttable = { -- For dupe support
		range		= maxrange,
		players		= players,
		npcs		= npcs,
		npcname		= npcname,
		beacons		= beacons,
		hoverballs	= hoverballs,
		thrusters	= thrusters,
		props		= props,
		propmodel	= propmodel,
		vehicles	= vehicles,
		playername	= playername,
		steamname	= steamname,
		colorcheck	= colorcheck,
		colortarget = colortarget,
		pcolR		= pcolR,
		pcolG		= pcolG,
		pcolB		= pcolB,
		pcolA		= pcolA,
		casesen		= casesen,
		rpgs		= rpgs,
		painttarget = painttarget,
		minrange	= minrange,
		maxtargets	= maxtargets,
		maxbogeys	= maxbogeys,
		notargetowner 	= notargetowner,
		notownersstuff	= notownersstuff,
		checkbuddylist 	= checkbuddylist,
		onbuddylist		= onbuddylist,
		entity 			= entity,
	}
	table.Merge( self:GetTable(), ttable )
	
	self.MaxRange            = maxrange
	self.MinRange            = minrange or 1
	self.TargetPlayer        = players
	self.NoTargetOwner       = notargetowner
	self.NoTargetOwnersStuff = notownersstuff
	self.TargetNPC           = npcs
	self.NPCName             = npcname
	self.TargetBeacon        = beacons
	self.TargetHoverballs    = hoverballs
	self.TargetThrusters     = thrusters
	self.TargetProps         = props
	self.PropModel           = propmodel
	self.TargetVehicles      = vehicles
	self.PlayerName          = playername
	self.SteamName           = steamname
	self.ColorCheck          = colorcheck
	self.ColorTarget         = colortarget
	self.PcolR               = pcolR
	self.PcolG               = pcolG
	self.PcolB               = pcolB
	self.PcolA               = pcolA
	self.CaseSen             = casesen
	self.TargetRPGs          = rpgs
	self.EntFil              = entity
	self.CheckBuddyList      = checkbuddylist
	self.OnBuddyList         = onbuddylist
	self.PaintTarget         = painttarget
	self.MaxTargets          = math.floor(math.Clamp((maxtargets or 1), 1, GetConVarNumber("wire_target_finders_maxtargets", 10)))
	self.MaxBogeys           = math.floor(math.Clamp((maxbogeys or 1), self.MaxTargets, GetConVarNumber("wire_target_finders_maxbogeys", 30)))

	if (self.SelectedTargets) then --unpaint before clearing
		for _,ent in pairs(self.SelectedTargets) do
			self:TargetPainter(ent, false)
		end
	end
	self.SelectedTargets = {}
	self.SelectedTargetsSel = {}

	local AdjOutputs = {}
	local AdjOutputsT = {}
	for i = 1, self.MaxTargets do
		table.insert(AdjOutputs, tostring(i))
		table.insert(AdjOutputsT, "NORMAL")
		table.insert(AdjOutputs, tostring(i).."_Ent")
		table.insert(AdjOutputsT, "ENTITY")
	end
	WireLib.AdjustSpecialOutputs(self, AdjOutputs, AdjOutputsT)


	self.Selector = {}
	self.Selector.Next = {}
	self.Selector.Prev = {}
	self.Selector.Hold = {}
	local AdjInputs = {}
	for i = 1, self.MaxTargets do
		local inputnext = tostring(i).."-NextTarget"
		--local inputprev = tostring(i).."-PrevTarget"
		local inputhold = tostring(i).."-HoldTarget"
		self.Selector.Next[inputnext] = i
		--self.Selector.Prev[inputprev] = i
		--self.Selector.Hold[inputhold] = i
		table.insert(AdjInputs, inputnext)
		--table.insert(AdjInputs, inputprev)
		table.insert(AdjInputs, inputhold)
	end
	table.insert(AdjInputs, "Hold")
	Wire_AdjustInputs(self, AdjInputs)

	self:ShowOutput(false)
end

function ENT:TriggerInput(iname, value)
	if (value > 0) then
		if self.Selector.Next[iname] then
			self:SelectorNext(self.Selector.Next[iname])
		--[[elseif self.Selector.Prev[iname] then
			self:SelectorPrev(self.Selector.Prev[iname])]]
		--[[elseif self.Selector.Hold[iname] then
			self:SelectorHold(self.Selector.Hold[iname])]]
		end
	end
end


function ENT:GetBeaconPos(sensor)
	local ch = 1
	if (sensor.Inputs) and (sensor.Inputs.Target.SrcId) then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	if self.SelectedTargets[ch] then
		if (not self.SelectedTargets[ch]:IsValid()) then
			self.SelectedTargets[ch] = nil
			Wire_TriggerOutput(self, tostring(ch), 0)
			return sensor:GetPos()
		end

		return self.SelectedTargets[ch]:GetPos()
	end

	return sensor:GetPos()
end

function ENT:GetBeaconVelocity(sensor)
	local ch = 1
	if (sensor.Inputs) and (sensor.Inputs.Target.SrcId) then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	if self.SelectedTargets[ch] then
		if (not self.SelectedTargets[ch]:IsValid()) then
			self.SelectedTargets[ch] = nil
			Wire_TriggerOutput(self, tostring(ch), 0)
			return sensor:GetVelocity()
		end
		return self.SelectedTargets[ch]:GetVelocity()
	end
	return sensor:GetVelocity()
end


function ENT:SelectorNext(ch)
	if (self.Bogeys) and (#self.Bogeys > 0) then
		if (!self.SelectedTargetsSel[ch]) then self.SelectedTargetsSel[ch] = 1 end

		local sel = self.SelectedTargetsSel[ch]
		if (sel > #self.Bogeys) then sel = 1 end

		if (self.SelectedTargets[ch]) and (self.SelectedTargets[ch]:IsValid()) then

			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], false) end
			table.insert(self.Bogeys, self.SelectedTargets[ch]) --put old target back
			self.SelectedTargets[ch] = table.remove(self.Bogeys, sel) --pull next target
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end

		else

			self.SelectedTargets[ch] = table.remove(self.Bogeys, sel) --pull next target
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end

		end

		self.SelectedTargetsSel[ch] = sel + 1
		self.Inputs[ch.."-HoldTarget"].Value = 1 --put the channel on hold so it wont change in the next scan
		Wire_TriggerOutput(self, tostring(ch), 1)
		Wire_TriggerOutput(self, tostring(ch).."_Ent", self.SelectedTargets[ch])
	end
end

--function ENT:SelectorPrev(ch) end --TODO if needed

function ENT:FindInValue(haystack,needle,case_sensitive)
	if !isstring(haystack) or !isstring(needle) then return false end;
	if(needle == "") then return true end;
	if(case_sensitive) then
		if(haystack:find(needle)) then return true end;
	else
		if(haystack:lower():find(needle:lower())) then return true end;
	end
	return false
end

function ENT:FindColor(contact)
	if (not self.ColorCheck) then return true end
	local col = contact:GetColor()
	if (col.r == self.PcolR) and (col.g == self.PcolG) and (col.b == self.PcolB) and (col.a == self.PcolA) then
		return self.ColorTarget
	else
		return !self.ColorTarget
	end
end

function ENT:CheckTheBuddyList(friend)
	if not self.CheckBuddyList or not CPPI then return true end
	if not IsValid(self:GetPlayer()) then return false end
	
	for _, v in pairs(self:GetPlayer():CPPIGetFriends()) do
		if v == friend then return self.OnBuddyList end
	end
	return not self.OnBuddyList
end

function ENT:Think()
	self.BaseClass.Think(self)

	if not (self.Inputs.Hold and self.Inputs.Hold.Value > 0) then
		-- Find targets that meet requirements
		local mypos = self:GetPos()
		local bogeys,dists = {},{}
		for _,contact in pairs(ents.FindInSphere(mypos, self.MaxRange or 10)) do
			local class = contact:GetClass()
			if (not self.NoTargetOwnersStuff or (class == "player") or (WireLib.GetOwner(contact) ~= self:GetPlayer())) and (
				-- NPCs
				((self.TargetNPC) and (contact:IsNPC()) and (self:FindInValue(class,self.NPCName))) or
				--Players
				((self.TargetPlayer) and (class == "player") and (!self.NoTargetOwner or self:GetPlayer() != contact) and self:FindInValue(contact:GetName(),self.PlayerName,self.CaseSen) and self:FindInValue(contact:SteamID(),self.SteamName) and self:FindColor(contact) and self:CheckTheBuddyList(contact)) or
				--Locators
				((self.TargetBeacon) and (class == "gmod_wire_locator")) or
				--RPGs
				((self.TargetRPGs) and (class == "rpg_missile")) or
				-- Hoverballs
				((self.TargetHoverballs) and (class == "gmod_hoverball" or class == "gmod_wire_hoverball")) or
				-- Thruster
				((self.TargetThrusters)	and (class == "gmod_thruster" or class == "gmod_wire_thruster" or class == "gmod_wire_vectorthruster")) or
				-- Props
				((self.TargetProps) and (class == "prop_physics") and (self:FindInValue(contact:GetModel(),self.PropModel))) or
				-- Vehicles
				((self.TargetVehicles) and (contact:IsVehicle())) or
				-- Entity classnames
				(self.EntFil ~= "" and self:FindInValue(class,self.EntFil)))
			then
				local dist = (contact:GetPos() - mypos):Length()
				if (dist >= self.MinRange) then
					-- put targets in a table index by the distance from the finder
					bogeys[dist] = contact
					dists[#dists+1] = dist
				end
			end
		end

		-- sort the list of bogeys by key (distance)
		self.Bogeys = {}
		self.InRange = {}
		table.sort(dists)
		local k = 1
		for i,d in pairs(dists) do
			if !self:IsTargeted(bogeys[d], i) then
				self.Bogeys[k] = bogeys[d]
				k = k + 1
				if (k > self.MaxBogeys) then break end
			end
		end


		-- check that the selected targets are valid
		for i = 1, self.MaxTargets do
			if (self:IsOnHold(i)) then
				self.InRange[i] = true
			end

			if (!self.InRange[i]) or (!self.SelectedTargets[i]) or (self.SelectedTargets[i] == nil) or (!self.SelectedTargets[i]:IsValid()) then
				if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], false) end
				if (#self.Bogeys > 0) then
					self.SelectedTargets[i] = table.remove(self.Bogeys, 1)
					if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], true) end
					Wire_TriggerOutput(self, tostring(i), 1)
					Wire_TriggerOutput(self, tostring(i).."_Ent", self.SelectedTargets[i])
				else
					self.SelectedTargets[i] = nil
					Wire_TriggerOutput(self, tostring(i), 0)
					Wire_TriggerOutput(self, tostring(i).."_Ent", NULL)
				end
			end
		end

	end

	-- temp hack
	if self.SelectedTargets[1] then
		self:ShowOutput(true)
	else
		self:ShowOutput(false)
	end
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:IsTargeted(bogey, bogeynum)
	for i = 1, self.MaxTargets do
		if (self.SelectedTargets[i]) and (self.SelectedTargets[i] == bogey) then
			--hold this target
			if (self.Inputs[i.."-HoldTarget"]) and (self.Inputs[i.."-HoldTarget"].Value > 0) then
				self.InRange[i] = true
				return true
			end

			--this bogey is not as close as others, untarget it and let it be add back to the list
			if (bogeynum > self.MaxTargets) then
				self.SelectedTargets[i] = nil
				if (self.PaintTarget) then self:TargetPainter(bogey, false) end
				return false
			end

			self.InRange[i] = true
			return true
		end
	end
	return false
end

function ENT:IsOnHold(ch)
	if (self.Inputs[ch.."-HoldTarget"]) and (self.Inputs[ch.."-HoldTarget"].Value > 0) then
		return true
	end
	return false
end


function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	--unpaint all our targets
	if (self.PaintTarget) then
		for _,ent in pairs(self.SelectedTargets) do
			self:TargetPainter(ent, false)
		end
	end
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)

	self.MaxTargets = self.MaxTargets or 1
end

function ENT:TargetPainter( tt, targeted )
	if tt and IsValid(tt) and tt:EntIndex() ~= 0 then
		if (targeted) then
			self.OldColor = tt:GetColor()
			tt:SetColor(Color(255, 0, 0, 255))
		else
			if not self.OldColor then self.OldColor = Color(255,255,255,255) end

			local c = tt:GetColor()

			-- do not change color back if the target color changed in the meantime
			if c.r != 255 or c.g != 0 or c.b != 0 or c.a != 255 then
				self.OldColor = c
			end

			tt:SetColor(self.OldColor)
		end
	end
end


function ENT:ShowOutput(value)
	local txt
	if (value) then
		txt = "Target Acquired"
	else
		txt = "No Target"
	end

	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then txt = txt .. " - Locked" end

	self:SetOverlayText(txt)
end



--
--	PropProtection support
--
--	Uses code from uclip for checking ownership
--
-- Written by Team Ulysses, http://ulyssesmod.net/
local hasPropProtection = false -- Chaussette's Prop Protection (preferred over PropSecure)
local propProtectionFn -- Function to call to see if a prop belongs to a player. We have to fetch it from a local so we'll store it here.

local hasPropSecure = false -- Prop Secure by Conna
local hasProtector = false -- Protector by Conna

local noProtection = false -- If there's no protection whatsoever, this is flagged.
-- We need this flag because with a protector, we default to _not_ being able to go through things.
-- This flag saves us major memory/bandwidth when there's no protection

-- We'll check status of protectors in this init
local function init()
	local t = hook.GetTable()
	local fn
	if(t.CanTool) then
		if t.CanTool[0] then -- ULib
			fn = t.CanTool[0].PropProtection
		else
			fn = t.CanTool.PropProtection
		end
	end

	hasPropProtection = isfunction( fn )

	if hasPropProtection then
		-- We're going to get the function we need now. It's local so this is a bit dirty
		local gi = debug.getinfo( fn )
		for i=1,gi.nups do
			if debug.getupvalue( fn, i ) == "Appartient" then
				local junk
				junk, propProtectionFn = debug.getupvalue( fn, i )
				break
			end
		end
	end

	hasPropSecure = istable( PropSecure )
	hasProtector = istable( Protector )

	if not hasPropProtection and not hasPropSecure and not hasProtector then
		noProtection = true
	end
end
hook.Add( "Initialize", "WireTargetFinderInitialize", init )

duplicator.RegisterEntityClass("gmod_wire_target_finder", WireLib.MakeWireEnt, "Data", "range", "players", "npcs", "npcname", "beacons", "hoverballs", "thrusters", "props", "propmodel", "vehicles", "playername", "casesen", "rpgs", "painttarget", "minrange", "maxtargets", "maxbogeys", "notargetowner", "entity", "notownersstuff", "steamname", "colorcheck", "colortarget", "pcolR", "pcolG", "pcolB", "pcolA", "checkbuddylist", "onbuddylist")
