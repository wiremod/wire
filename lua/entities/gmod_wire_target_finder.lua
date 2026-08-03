AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire Target Finder"
ENT.WireDebugName = "Target Finder"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, {"Hold", "Ignore [ARRAY]"})
	WireLib.CreateSpecialOutputs(self, {"Out"}, {"ENTITY"})
end

local MaxBogeys = GetConVar("wire_target_finders_maxbogeys")
local MaxTargets = GetConVar("wire_target_finders_maxtargets")

function ENT:Setup(maxrange, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel, vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamidfilter, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist)
	-- For dupe support
	local tab = self:GetTable()

	table.Merge(tab, {
		range = maxrange,
		players = players,
		npcs = npcs,
		npcname = npcname,
		beacons = beacons,
		hoverballs = hoverballs,
		thrusters = thrusters,
		props = props,
		propmodel = propmodel,
		vehicles = vehicles,
		playername = playername,
		steamname = steamidfilter,
		colorcheck = colorcheck,
		colortarget = colortarget,
		pcolR = pcolR,
		pcolG = pcolG,
		pcolB = pcolB,
		pcolA = pcolA,
		casesen = casesen,
		rpgs = rpgs,
		painttarget = painttarget,
		minrange = minrange,
		maxtargets = maxtargets,
		maxbogeys = maxbogeys,
		notargetowner = notargetowner,
		notownersstuff = notownersstuff,
		checkbuddylist = checkbuddylist,
		onbuddylist = onbuddylist,
		entity = entity,
	})

	tab.MaxRange = maxrange
	tab.MinRange = minrange or 1
	tab.TargetPlayer = players
	tab.NoTargetOwner = notargetowner
	tab.NoTargetOwnersStuff = notownersstuff
	tab.TargetNPC = npcs
	tab.NPCName = npcname
	tab.TargetBeacon = beacons
	tab.TargetHoverballs = hoverballs
	tab.TargetThrusters = thrusters
	tab.TargetProps = props
	tab.PropModel = propmodel
	tab.TargetVehicles = vehicles
	tab.PlayerName = playername
	tab.SteamName = steamidfilter
	tab.ColorCheck = colorcheck
	tab.ColorTarget = colortarget
	tab.PcolR = pcolR
	tab.PcolG = pcolG
	tab.PcolB = pcolB
	tab.PcolA = pcolA
	tab.CaseSen = casesen
	tab.TargetRPGs = rpgs
	tab.EntFil = entity
	tab.CheckBuddyList = checkbuddylist
	tab.OnBuddyList = onbuddylist
	tab.PaintTarget = painttarget
	tab.MaxTargets = math.floor(math.Clamp(maxtargets or 1, 1, MaxTargets:GetInt()))
	tab.MaxBogeys = math.floor(math.Clamp(maxbogeys or 1, tab.MaxTargets, MaxBogeys:GetInt()))

	if (tab.SelectedTargets) then -- Unpaint before clearing
		for _, ent in pairs(tab.SelectedTargets) do
			tab.TargetPainter(self, ent, false, tab)
		end
	end

	tab.SelectedTargets = {}
	tab.SelectedTargetsSel = {}

	local AdjOutputs = {}
	local AdjOutputsT = {}

	for i = 1, tab.MaxTargets do
		local i_string = tostring(i)
		table.insert(AdjOutputs, i_string)
		table.insert(AdjOutputsT, "NORMAL")
		table.insert(AdjOutputs, i_string .. "_Ent")
		table.insert(AdjOutputsT, "ENTITY")
	end

	WireLib.AdjustSpecialOutputs(self, AdjOutputs, AdjOutputsT)

	tab.Selector = {}
	tab.Selector.Next = {}
	tab.Selector.Prev = {}
	tab.Selector.Hold = {}

	local AdjInputs = {}

	for i = 1, self.MaxTargets do
		local i_string = tostring(i)
		local inputnext = i_string .. "-NextTarget"
		local inputhold = i_string .. "-HoldTarget"
		tab.Selector.Next[inputnext] = i

		table.insert(AdjInputs, inputnext)
		table.insert(AdjInputs, inputhold)
	end

	table.insert(AdjInputs, "Hold")
	table.insert(AdjInputs, "Ignore [ARRAY]")

	WireLib.AdjustInputs(self, AdjInputs)
end

function ENT:TriggerInput(name, value)
	if name == "Ignore" then
		local ignored_hash = {}
		self.Ignored = ignored_hash

		for _, ent in ipairs(value) do
			ignored_hash[ent] = true
		end
	else
		local select_next = self.Selector.Next

		if value > 0 and select_next[name] then
			self:SelectorNext(select_next)
		end
	end
end

function ENT:GetBeaconPos(sensor)
	local ch = 1
	local inputs = sensor.Inputs

	if inputs and inputs.Target.SrcId then
		ch = tonumber(inputs.Target.SrcId)
	end

	local selected_targets = self.SelectedTargets
	local selected = selected_targets[ch]

	if selected then
		if not selected:IsValid() then
			selected_targets[ch] = nil
			WireLib.TriggerOutput(self, tostring(ch), 0)
			return sensor:GetPos()
		end

		return selected:GetPos()
	end

	return sensor:GetPos()
end

function ENT:GetBeaconVelocity(sensor)
	local ch = 1
	local inputs = sensor.Inputs

	if inputs and inputs.Target.SrcId then
		ch = tonumber(inputs.Target.SrcId)
	end

	local selected_targets = self.SelectedTargets
	local selected = selected_targets[ch]

	if selected then
		if not selected:IsValid() then
			selected_targets[ch] = nil
			WireLib.TriggerOutput(self, tostring(ch), 0)
			return sensor:GetVelocity()
		end

		return selected:GetVelocity()
	end

	return sensor:GetVelocity()
end


function ENT:SelectorNext(ch)
	local tab = self:GetTable()
	local bogeys = tab.Bogeys

	if bogeys and #bogeys > 0 then
		local selected_targets_sel = tab.SelectedTargetsSel
		if not selected_targets_sel[ch] then selected_targets_sel[ch] = 1 end

		local sel = selected_targets_sel[ch]
		if sel > bogeys then sel = 1 end

		local paint_target = tab.PaintTarget
		local selected_targets = tab.SelectedTargets
		local target = selected_targets[ch]

		if target and target:IsValid() then
			if paint_target then tab.TargetPainter(self, target, false, tab) end
			table.insert(bogeys, target) -- Put old target back

			target = table.remove(bogeys, sel) -- Pull next target
			selected_targets[ch] = target

			if paint_target then tab.TargetPainter(self, selected_targets[ch], true, tab) end
		else
			selected_targets[ch] = table.remove(bogeys, sel) -- Pull next target
			if paint_target then tab.TargetPainter(self, selected_targets[ch], true, tab) end
		end

		selected_targets_sel[ch] = sel + 1

		-- Put the channel on hold so it wont change in the next scan
		tab.Inputs[ch .. "-HoldTarget"].Value = 1

		local ch_string = tostring(ch)
		WireLib.TriggerOutput(self, ch_string, 1)
		WireLib.TriggerOutput(self, ch_string .. "_Ent", selected_targets[ch])
	end
end

--function ENT:SelectorPrev(ch) end --TODO if needed

function ENT:FindColor(contact, tab)
	if not tab.ColorCheck then return true end
	local color = contact:GetColor()

	if color.r == tab.PcolR and color.g == tab.PcolG and color.b == tab.PcolB and color.a == tab.PcolA then
		return tab.ColorTarget
	else
		return not tab.ColorTarget
	end
end

function ENT:CheckTheBuddyList(ply, tab)
	if not CPPI or not tab.CheckBuddyList then return true end

	local ply = tab.GetPlayer(self)
	if not ply:IsValid() then return false end

	local friends = ply:CPPIGetFriends()

	if istable(friends) then
		for _, friend in pairs(friends) do
			if friend == ply then
				return tab.OnBuddyList
			end
		end
	end

	return not tab.OnBuddyList
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

local function CheckPlayers(self, contact, tab)
	if tab.NoTargetOwner and tab.GetPlayer(self) == contact then return false end
	if not isOneOf(contact:GetName(), tab.PlayerName, tab.CaseSen) then return false end

	-- Check if the player's steamid/steamid64 matches the SteamIDs
	if tab.SteamName:Trim() ~= "" then
		local contact_steamid, contact_steamid64 = contact:SteamID(), contact:SteamID64()

		if not isOneOf(contact_steamid, tab.SteamName, tab.CaseSen) or isOneOf(contact_steamid64, tab.SteamName, tab.CaseSen) then
			return false
		end
	end

	return tab.FindColor(self, contact, tab) and tab.CheckTheBuddyList(self, contact, tab)
end

function ENT:Think()
	BaseClass.Think(self)

	local tab = self:GetTable()

	if not (tab.Inputs.Hold and tab.Inputs.Hold.Value > 0) then
		-- Find targets that meet requirements
		local bogeys, dists, ndists = {}, {}, 0

		local pos = self:GetPos()
		local max_range = tab.MaxRange
		local min_range = tab.MinRange
		local ignored = tab.Ignored
		local no_target_owner = tab.NoTargetOwnersStuff
		local target_npc = tab.TargetNPC
		local target_player = tab.TargetPlayer
		local target_beacon = tab.TargetBeacon
		local target_rpgs = tab.TargetRPGs
		local target_hoverballs = tab.TargetHoverballs
		local target_thrusters = tab.TargetThrusters
		local target_props = tab.TargetProps
		local target_vehicles = tab.TargetVehicles
		local ent_filter = tab.EntFil
		local prop_model = tab.PropModel
		local npc_name = tab.NPCName

		for _, contact in ipairs(ents.FindInSphere(pos, max_range)) do
			local class = contact:GetClass()
			if
				-- Ignore array of entities if provided
				(not ignored or not ignored[contact]) and
				-- Ignore owned stuff if checked
				((not no_target_owner or (class == "player") or (WireLib.GetOwner(contact) ~= tab.GetPlayer(self))) and
				-- NPCs
				((target_npc and (contact:IsNPC()) and (isOneOf(class, npc_name))) or
				-- Players
				(target_player and (class == "player") and CheckPlayers(self, contact, tab) or
				-- Locators
				(target_beacon and (class == "gmod_wire_locator")) or
				-- RPGs
				(target_rpgs and (class == "rpg_missile")) or
				-- Hoverballs
				(target_hoverballs and (class == "gmod_hoverball" or class == "gmod_wire_hoverball")) or
				-- Thruster
				(target_thrusters and (class == "gmod_thruster" or class == "gmod_wire_thruster" or class == "gmod_wire_vectorthruster")) or
				-- Props
				(target_props and (class == "prop_physics") and (isOneOf(contact:GetModel(), prop_model))) or
				-- Vehicles
				(target_vehicles and contact:IsVehicle()) or
				-- Entity classnames
				(ent_filter ~= "" and isOneOf(class, ent_filter)))))
			then
				if (contact:GetPos():Distance(pos) >= min_range) then
					-- Put targets in a table index by the distance from the finder
					ndists = ndists + 1
					bogeys[dist] = contact
					dists[ndists] = dist
				end
			end
		end

		-- Sort the list of bogeys by key (distance)
		tab.Bogeys = {}
		tab.InRange = {}
		table.sort(dists)

		local k = 1
		local bogeys = tab.Bogeys
		local max_bogeys = tab.MaxBogeys

		for i, d in ipairs(dists) do
			if not tab.IsTargeted(self, bogeys[d], i, tab) then
				bogeys[k] = bogeys[d]
				k = k + 1

				if k > max_bogeys then
					break
				end
			end
		end

		-- Check that the selected targets are valid
		local max_targets = tab.MaxTargets
		local paint_target = tab.PaintTarget
		local selected_targets = tab.SelectedTargets
		local in_range = tab.InRange

		for i = 1, max_targets do
			if tab.IsOnHold(self, i, tab) then
				in_range[i] = true
			end

			if not in_range[i] or not selected_targets[i] or selected_targets[i] == nil or not selected_targets[i]:IsValid() then
				local i_string = tostring(i)

				if paint_target then
					tab.TargetPainter(self, selected_targets[i], false, tab)
				end

				if #bogeys > 0 then
					selected_targets[i] = table.remove(bogeys, 1)

					if paint_target then
						tab.TargetPainter(self, selected_targets[i], true, tab)
					end

					WireLib.TriggerOutput(self, i_string, 1)
					WireLib.TriggerOutput(self, i_string .. "_Ent", selected_targets[i])
				else
					selected_targets[i] = nil
					WireLib.TriggerOutput(self, i_string, 0)
					WireLib.TriggerOutput(self, i_string .. "_Ent", NULL)
				end
			end
		end
	end

	self:NextThink(CurTime() + 1)

	return true
end

function ENT:IsTargeted(bogey, bogeynum, tab)
	local max_range = tab.MaxTargets
	local paint_target = tab.PaintTarget
	local selected_targets = tab.SelectedTargets
	local in_range = tab.InRange
	local inputs = tab.Inputs

	for i = 1, max_range do
		local target = selected_targets[i]

		if target and target == bogey then
			-- Hold this target
			local i_string = i .. "-HoldTarget"

			if inputs[i_string] and inputs[i_string].Value > 0 then
				in_range[i] = true
				return true
			end

			-- This bogey is not as close as others, untarget it and let it be add back to the list
			if bogeynum > max_range then
				selected_targets[i] = nil

				if paint_target then
					tab.TargetPainter(self, bogey, false, tab)
				end

				return false
			end

			in_range[i] = true

			return true
		end
	end

	return false
end

function ENT:IsOnHold(ch, tab)
	local inputs = tab.Inputs
	local ch_string = ch .. "-HoldTarget"

	return inputs[ch_string] and inputs[ch_string].Value > 0
end


function ENT:OnRemove()
	BaseClass.OnRemove(self)

	-- Unpaint all our targets
	local tab = self:GetTable()

	if tab.PaintTarget then
		for _, ent in pairs(tab.SelectedTargets) do
			tab.TargetPainter(self, ent, false, tab)
		end
	end
end

function ENT:OnRestore()
	BaseClass.OnRestore(self)
	self.MaxTargets = self.MaxTargets or 1
end

function ENT:TargetPainter(tt, targeted, tab)
	local ply = tab.GetPlayer(self)

	if IsValid(tt) and not tt:IsEFlagSet(EFL_SERVER_ONLY) and ply:IsValid() and WireLib.CanTool(ply, tt, "colour") then
		if targeted then
			tab.OldColor = tt:GetColor()
			tt:SetColor(Color(255, 0, 0, 255))
		else
			local color = tt:GetColor()

			-- Do not change color back if the target color changed in the meantime
			if color.r ~= 255 or color.g ~= 0 or color.b ~= 0 or color.a ~= 255 then
				tab.OldColor = color
			end

			if not tab.OldColor then
				tab.OldColor = Color(255, 255, 255)
			end

			tt:SetColor(tab.OldColor)
		end
	end
end


function ENT:PrepareOverlayData()
	local txt = self.SelectedTargets[1] and "Target Acquired" or "No Target"
	if self.Inputs.Hold and self.Inputs.Hold.Value > 0 then txt = txt .. " - Locked" end

	self:SetOverlayText(txt)
end

duplicator.RegisterEntityClass("gmod_wire_target_finder", WireLib.MakeWireEnt, "Data", "range", "players", "npcs", "npcname", "beacons", "hoverballs", "thrusters", "props", "propmodel", "vehicles", "playername", "casesen", "rpgs", "painttarget", "minrange", "maxtargets", "maxbogeys", "notargetowner", "entity", "notownersstuff", "steamname", "colorcheck", "colortarget", "pcolR", "pcolG", "pcolB", "pcolA", "checkbuddylist", "onbuddylist")
