AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Target Finder"
ENT.WireDebugName = "Target Finder"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "Hold", "Ignore [ARRAY]" })
	self.Outputs = WireLib.CreateSpecialOutputs( self, { "Out" }, { "ENTITY" } )
end

local MaxBogeys = GetConVar("wire_target_finders_maxbogeys")
local MaxTargets = GetConVar("wire_target_finders_maxtargets")

function ENT:Setup(maxrange, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel, vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamidfilter, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist )
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
		steamname	= steamidfilter,
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
	self.SteamName           = steamidfilter
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
	self.MaxTargets          = math.floor(math.Clamp(maxtargets or 1, 1, MaxTargets:GetInt()))
	self.MaxBogeys           = math.floor(math.Clamp(maxbogeys or 1, self.MaxTargets, MaxBogeys:GetInt()))

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
		table.insert(AdjOutputs, tostring(i) .. "_Ent")
		table.insert(AdjOutputsT, "ENTITY")
	end
	WireLib.AdjustSpecialOutputs(self, AdjOutputs, AdjOutputsT)


	self.Selector = {}
	self.Selector.Next = {}
	self.Selector.Prev = {}
	self.Selector.Hold = {}
	local AdjInputs = {}
	for i = 1, self.MaxTargets do
		local inputnext = tostring(i) .. "-NextTarget"
		--local inputprev = tostring(i).."-PrevTarget"
		local inputhold = tostring(i) .. "-HoldTarget"
		self.Selector.Next[inputnext] = i
		--self.Selector.Prev[inputprev] = i
		--self.Selector.Hold[inputhold] = i
		table.insert(AdjInputs, inputnext)
		--table.insert(AdjInputs, inputprev)
		table.insert(AdjInputs, inputhold)
	end
	table.insert(AdjInputs, "Hold")
	table.insert(AdjInputs, "Ignore [ARRAY]")

	Wire_AdjustInputs(self, AdjInputs)

	self:ShowOutput(false)
end

function ENT:TriggerInput(iname, value)
	if iname == "Ignore" then
		self.Ignored = value
		return
	end

	if value > 0 and self.Selector.Next[iname] then
		self:SelectorNext(self.Selector.Next[iname])
		--[[elseif self.Selector.Prev[iname] then
			self:SelectorPrev(self.Selector.Prev[iname])
		elseif self.Selector.Hold[iname] then
			self:SelectorHold(self.Selector.Hold[iname])
		]]
	end
end


function ENT:GetBeaconPos(sensor)
	local ch = 1
	if sensor.Inputs and sensor.Inputs.Target.SrcId then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	if self.SelectedTargets[ch] then
		if not self.SelectedTargets[ch]:IsValid() then
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
	if sensor.Inputs and sensor.Inputs.Target.SrcId then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	local selected = self.SelectedTargets[ch]
	if selected then
		if not selected:IsValid() then
			self.SelectedTargets[ch] = nil
			Wire_TriggerOutput(self, tostring(ch), 0)
			return sensor:GetVelocity()
		end
		return selected:GetVelocity()
	end
	return sensor:GetVelocity()
end


function ENT:SelectorNext(ch)
	if self.Bogeys and #self.Bogeys > 0 then
		if not self.SelectedTargetsSel[ch] then self.SelectedTargetsSel[ch] = 1 end

		local sel = self.SelectedTargetsSel[ch]
		if (sel > #self.Bogeys) then sel = 1 end

		local target = self.SelectedTargets[ch]
		if target and target:IsValid() then

			if (self.PaintTarget) then self:TargetPainter(target, false) end
			table.insert(self.Bogeys, target) --put old target back

			target = table.remove(self.Bogeys, sel) --pull next target
			self.SelectedTargets[ch] = target

			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end
		else
			self.SelectedTargets[ch] = table.remove(self.Bogeys, sel) --pull next target
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end
		end

		self.SelectedTargetsSel[ch] = sel + 1
		self.Inputs[ch .. "-HoldTarget"].Value = 1 --put the channel on hold so it wont change in the next scan
		Wire_TriggerOutput(self, tostring(ch), 1)
		Wire_TriggerOutput(self, tostring(ch) .. "_Ent", self.SelectedTargets[ch])
	end
end

--function ENT:SelectorPrev(ch) end --TODO if needed

function ENT:FindColor(contact)
	if (not self.ColorCheck) then return true end
	local col = contact:GetColor()
	if (col.r == self.PcolR) and (col.g == self.PcolG) and (col.b == self.PcolB) and (col.a == self.PcolA) then
		return self.ColorTarget
	else
		return not self.ColorTarget
	end
end

function ENT:CheckTheBuddyList(friend)
	if not self.CheckBuddyList or not CPPI then return true end
	local ply = self:GetPlayer()
	if not ply:IsValid() then return false end

	local friends = ply:CPPIGetFriends()
	if istable(friends) then
		for _, v in pairs(friends) do
			if v == friend then return self.OnBuddyList end
		end
	end
	return not self.OnBuddyList
end

-- Like the old FindInValue but without string.find() and for multiple values split by either a space or a comma.
local function isOneOf(value, values_str, case_sensitive)
	if not isstring(value) or not isstring(values_str) then return false end
	if values_str == "" then return true end -- why :/

	if not case_sensitive then
		value = value:lower()
		values_str = values_str:lower()
	end

	for possible in values_str:gmatch("[^, ]+") do
		if possible == value then return true end
	end
	return false
end

local function CheckPlayers(self, contact)
	if self.NoTargetOwner and self:GetPlayer() == contact then return false end
	if not isOneOf(contact:GetName(), self.PlayerName, self.CaseSen) then return false end

	-- Check if the player's steamid/steamid64 matches the SteamIDs
	if self.SteamName:Trim() ~= "" then
		local contact_steamid, contact_steamid64 = contact:SteamID(), contact:SteamID64() or "multirun"
		if not ( isOneOf(contact_steamid, self.SteamName, self.CaseSen) or isOneOf(contact_steamid64, self.SteamName, self.CaseSen) ) then
			return false
		end
	end

	return self:FindColor(contact) and self:CheckTheBuddyList(contact)
end

function ENT:Think()
	BaseClass.Think(self)

	if not (self.Inputs.Hold and self.Inputs.Hold.Value > 0) then
		-- Find targets that meet requirements
		local mypos = self:GetPos()
		local bogeys, dists, ndists = {}, {}, 0
		for _, contact in ipairs(ents.FindInSphere(mypos, self.MaxRange or 10)) do
			local class = contact:GetClass()
			if
				-- Ignore array of entities if provided
				(not self.Ignored or not table.HasValue(self.Ignored, contact) ) and
				-- Ignore owned stuff if checked
				((not self.NoTargetOwnersStuff or (class == "player") or (WireLib.GetOwner(contact) ~= self:GetPlayer())) and
				-- NPCs
				((self.TargetNPC and (contact:IsNPC()) and (isOneOf(class, self.NPCName))) or
				--Players
				(self.TargetPlayer and (class == "player") and CheckPlayers(self, contact) or
				--Locators
				(self.TargetBeacon and (class == "gmod_wire_locator")) or
				--RPGs
				(self.TargetRPGs and (class == "rpg_missile")) or
				-- Hoverballs
				(self.TargetHoverballs and (class == "gmod_hoverball" or class == "gmod_wire_hoverball")) or
				-- Thruster
				(self.TargetThrusters	and (class == "gmod_thruster" or class == "gmod_wire_thruster" or class == "gmod_wire_vectorthruster")) or
				-- Props
				(self.TargetProps and (class == "prop_physics") and (isOneOf(contact:GetModel(), self.PropModel))) or
				-- Vehicles
				(self.TargetVehicles and contact:IsVehicle()) or
				-- Entity classnames
				(self.EntFil ~= "" and isOneOf(class, self.EntFil)))))
			then
				local dist = (contact:GetPos() - mypos):Length()
				if (dist >= self.MinRange) then
					-- put targets in a table index by the distance from the finder
					bogeys[dist] = contact

					ndists = ndists + 1
					dists[ndists] = dist
				end
			end
		end

		-- sort the list of bogeys by key (distance)
		self.Bogeys = {}
		self.InRange = {}
		table.sort(dists)
		local k = 1
		for i, d in ipairs(dists) do
			if not self:IsTargeted(bogeys[d], i) then
				self.Bogeys[k] = bogeys[d]
				k = k + 1
				if k > self.MaxBogeys then break end
			end
		end


		-- check that the selected targets are valid
		for i = 1, self.MaxTargets do
			if (self:IsOnHold(i)) then
				self.InRange[i] = true
			end

			if not self.InRange[i] or not self.SelectedTargets[i] or self.SelectedTargets[i] == nil or not self.SelectedTargets[i]:IsValid() then
				if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], false) end
				if (#self.Bogeys > 0) then
					self.SelectedTargets[i] = table.remove(self.Bogeys, 1)
					if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], true) end
					Wire_TriggerOutput(self, tostring(i), 1)
					Wire_TriggerOutput(self, tostring(i) .. "_Ent", self.SelectedTargets[i])
				else
					self.SelectedTargets[i] = nil
					Wire_TriggerOutput(self, tostring(i), 0)
					Wire_TriggerOutput(self, tostring(i) .. "_Ent", NULL)
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
		local target = self.SelectedTargets[i]
		if target and (target == bogey) then
			-- hold this target
			if self.Inputs[i .. "-HoldTarget"] and self.Inputs[i .. "-HoldTarget"].Value > 0 then
				self.InRange[i] = true
				return true
			end

			-- this bogey is not as close as others, untarget it and let it be add back to the list
			if bogeynum > self.MaxTargets then
				self.SelectedTargets[i] = nil
				if self.PaintTarget then self:TargetPainter(bogey, false) end
				return false
			end

			self.InRange[i] = true
			return true
		end
	end
	return false
end

function ENT:IsOnHold(ch)
	if self.Inputs[ch .. "-HoldTarget"] and self.Inputs[ch .. "-HoldTarget"].Value > 0 then
		return true
	end
	return false
end


function ENT:OnRemove()
	BaseClass.OnRemove(self)

	-- unpaint all our targets
	if self.PaintTarget then
		for _,ent in pairs(self.SelectedTargets) do
			self:TargetPainter(ent, false)
		end
	end
end

function ENT:OnRestore()
	BaseClass.OnRestore(self)

	self.MaxTargets = self.MaxTargets or 1
end

function ENT:TargetPainter( tt, targeted )
	local ply = self:GetPlayer()
	if tt and IsValid(tt) and tt:EntIndex() ~= 0 and ply:IsValid() and WireLib.CanTool(ply, tt, "colour") then
		if (targeted) then
			self.OldColor = tt:GetColor()
			tt:SetColor(Color(255, 0, 0, 255))
		else
			if not self.OldColor then self.OldColor = Color(255,255,255,255) end

			local c = tt:GetColor()

			-- do not change color back if the target color changed in the meantime
			if c.r ~= 255 or c.g ~= 0 or c.b ~= 0 or c.a ~= 255 then
				self.OldColor = c
			end

			tt:SetColor(self.OldColor)
		end
	end
end


function ENT:ShowOutput(value)
	local txt = "No Target"
	if value then
		txt = "Target Acquired"
	end

	if self.Inputs.Hold and (self.Inputs.Hold.Value > 0) then txt = txt .. " - Locked" end

	self:SetOverlayText(txt)
end

duplicator.RegisterEntityClass("gmod_wire_target_finder", WireLib.MakeWireEnt, "Data", "range", "players", "npcs", "npcname", "beacons", "hoverballs", "thrusters", "props", "propmodel", "vehicles", "playername", "casesen", "rpgs", "painttarget", "minrange", "maxtargets", "maxbogeys", "notargetowner", "entity", "notownersstuff", "steamname", "colorcheck", "colortarget", "pcolR", "pcolG", "pcolB", "pcolA", "checkbuddylist", "onbuddylist")
