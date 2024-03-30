E2Lib.RegisterExtension("find", true, "Allows an E2 to search for entities matching a filter.")

local function table_IsEmpty(t) return not next(t) end

local filterList = E2Lib.filterList

local function replace_match(a,b)
	return string.match( string.Replace(a,"-","__"), string.Replace(b,"-","__") )
end

-- String used to check regex complexities
local sample_string = string.rep(" ", 40)

-- -- some generic filter criteria -- --

local function filter_all() return true end
local function filter_none() return false end

local forbidden_classes = {
	--[[
	["info_apc_missile_hint"] = true,
	["info_camera_link"] = true,
	["info_constraint_anchor"] = true,
	["info_hint"] = true,
	["info_intermission"] = true,
	["info_ladder_dismount"] = true,
	["info_landmark"] = true,
	["info_lighting"] = true,
	["info_mass_center"] = true,
	["info_no_dynamic_shadow"] = true,
	["info_node"] = true,
	["info_node_air"] = true,
	["info_node_air_hint"] = true,
	["info_node_climb"] = true,
	["info_node_hint"] = true,
	["info_node_link"] = true,
	["info_node_link_controller"] = true,
	["info_npc_spawn_destination"] = true,
	["info_null"] = true,
	["info_overlay"] = true,
	["info_particle_system"] = true,
	["info_projecteddecal"] = true,
	["info_snipertarget"] = true,
	["info_target"] = true,
	["info_target_gunshipcrash"] = true,
	["info_teleport_destination"] = true,
	["info_teleporter_countdown"] = true,
	]]
	["info_player_allies"] = true,
	["info_player_axis"] = true,
	["info_player_combine"] = true,
	["info_player_counterterrorist"] = true,
	["info_player_deathmatch"] = true,
	["info_player_logo"] = true,
	["info_player_rebel"] = true,
	["info_player_start"] = true,
	["info_player_terrorist"] = true,
	["info_player_blu"] = true,
	["info_player_red"] = true,
	["prop_dynamic"] = true,
	["physgun_beam"] = true,
	["player_manager"] = true,
	["predicted_viewmodel"] = true,
	["gmod_ghost"] = true,
}
local function filter_default(self)
	local chip = self.entity
	return function(ent)
		if forbidden_classes[ent:GetClass()] then return false end

		if ent == chip then return false end
		return true
	end
end

local function filter_default_without_class_blocklist(self)
	local chip = self.entity
	return function(ent)
		return ent ~= chip
	end
end

-- -- some filter criterion generators -- --

-- Generates a filter that filters out everything not in a lookup table.
local function filter_in_lookup(lookup)
	if table_IsEmpty(lookup) then return filter_none end

	return function(ent)
		return lookup[ent]
	end
end

-- Generates a filter that filters out everything in a lookup table.
local function filter_not_in_lookup(lookup)
	if table_IsEmpty(lookup) then return filter_all end

	return function(ent)
		return not lookup[ent]
	end
end

-- Generates a filter that filters out everything not in a lookup table.
local function filter_function_result_in_lookup(lookup, func)
	if table_IsEmpty(lookup) then return filter_none end

	return function(ent)
		return lookup[func(ent)]
	end
end

-- Generates a filter that filters out everything in a lookup table.
local function filter_function_result_not_in_lookup(lookup, func)
	if table_IsEmpty(lookup) then return filter_all end

	return function(ent)
		return not lookup[func(ent)]
	end
end

-- checks if binary_predicate(func(ent), key) matches for any of the keys in the lookup table. Returns false if it does.
local function filter_binary_predicate_match_none(lookup, func, binary_predicate)
	if table_IsEmpty(lookup) then return filter_all end

	return function(a)
		a = func(a)
		for b,_ in pairs(lookup) do
			if binary_predicate(a, b) then return false end
		end
		return true
	end
end

-- checks if binary_predicate(func(ent), key) matches for any of the keys in the lookup table. Returns true if it does.
local function filter_binary_predicate_match_one(lookup, func, binary_predicate)
	if table_IsEmpty(lookup) then return filter_none end

	return function(a)
		a = func(a)
		for b,_ in pairs(lookup) do
			if binary_predicate(a, b) then return true end
		end
		return false
	end
end


-- -- filter criterion combiners -- --

local _filter_and = {
	[0] = function() return filter_all end,
	function(f1)                   return f1 end,
	function(f1,f2)                return function(v) return f1(v) and f2(v) end end,
	function(f1,f2,f3)             return function(v) return f1(v) and f2(v) and f3(v) end end,
	function(f1,f2,f3,f4)          return function(v) return f1(v) and f2(v) and f3(v) and f4(v) end end,
	function(f1,f2,f3,f4,f5)       return function(v) return f1(v) and f2(v) and f3(v) and f4(v) and f5(v) end end,
	function(f1,f2,f3,f4,f5,f6)    return function(v) return f1(v) and f2(v) and f3(v) and f4(v) and f5(v) and f6(v) end end,
	function(f1,f2,f3,f4,f5,f6,f7) return function(v) return f1(v) and f2(v) and f3(v) and f4(v) and f5(v) and f6(v) and f7(v) end end,
}

-- Usage: filter = filter_and(filter1, filter2, filter3)
local function filter_and(...)
	local args = {...}

	-- filter out all filter_all entries
	filterList(args, function(f)
		if f == filter_none then
			args = { filter_none } -- If a filter_none is in the list, we can discard all other filters.
		end
		return f ~= filter_all
	end)

	local combiner = _filter_and[#args]
	if not combiner then return nil end -- TODO: write generic combiner
	return combiner(unpack(args))
end

local _filter_or = {
	[0] = function() return filter_none end,
	function(f1)                   return f1 end,
	function(f1,f2)                return function(v) return f1(v) or f2(v) end end,
	function(f1,f2,f3)             return function(v) return f1(v) or f2(v) or f3(v) end end,
	function(f1,f2,f3,f4)          return function(v) return f1(v) or f2(v) or f3(v) or f4(v) end end,
	function(f1,f2,f3,f4,f5)       return function(v) return f1(v) or f2(v) or f3(v) or f4(v) or f5(v) end end,
	function(f1,f2,f3,f4,f5,f6)    return function(v) return f1(v) or f2(v) or f3(v) or f4(v) or f5(v) or f6(v) end end,
	function(f1,f2,f3,f4,f5,f6,f7) return function(v) return f1(v) or f2(v) or f3(v) or f4(v) or f5(v) or f6(v) or f7(v) end end,
}

-- Usage: filter = filter_or(filter1, filter2, filter3)
local function filter_or(...)
	local args = {...}

	-- filter out all filter_none entries
	filterList(args, function(f)
		if f == filter_all then
			args = { filter_all } -- If a filter_all is in the list, we can discard all other filters.
		end
		return f ~= filter_none
	end)

	local combiner = _filter_or[#args]
	if not combiner then return nil end -- TODO: write generic combiner
	return combiner(unpack(args))
end

local function invalidate_filters(self)
	-- Update the filters the next time they are used.
	self.data.findfilter = nil
end

-- This function should be called after the black- or whitelists have changed.
local function update_filters(self)
	-- Do not update again until the filters are invalidated the next time.

	local find = self.data.find

	---------------------
	--    blacklist    --
	---------------------

	-- blacklist for single entities
	local bl_entity_filter = filter_not_in_lookup(find.bl_entity)
	-- blacklist for a player's props
	local bl_owner_filter = filter_function_result_not_in_lookup(find.bl_owner, function(ent) return getOwner(self,ent) end)

	-- blacklist for models
	local bl_model_filter = filter_binary_predicate_match_none(find.bl_model, function(ent) return string.lower(ent:GetModel() or "") end, replace_match)
	-- blacklist for classes
	local bl_class_filter = filter_binary_predicate_match_none(find.bl_class, function(ent) return string.lower(ent:GetClass()) end, replace_match)

	-- combine all blacklist filters (done further down)
	--local filter_blacklist = filter_and(bl_entity_filter, bl_owner_filter, bl_model_filter, bl_class_filter)

	---------------------
	--    whitelist    --
	---------------------

	local filter_whitelist = filter_all

	-- if not all whitelists are empty, use the whitelists.
	local whiteListInUse = not (table_IsEmpty(find.wl_entity) and table_IsEmpty(find.wl_owner) and table_IsEmpty(find.wl_model) and table_IsEmpty(find.wl_class))

	if whiteListInUse then
		-- blacklist for single entities
		local wl_entity_filter = filter_in_lookup(find.wl_entity)
		-- blacklist for a player's props
		local wl_owner_filter = filter_function_result_in_lookup(find.wl_owner, function(ent) return getOwner(self,ent) end)

		-- blacklist for models
		local wl_model_filter = filter_binary_predicate_match_one(find.wl_model, function(ent) return string.lower(ent:GetModel() or "") end, replace_match)
		-- blacklist for classes
		local wl_class_filter = filter_binary_predicate_match_one(find.wl_class, function(ent) return string.lower(ent:GetClass()) end, replace_match)

		-- combine all whitelist filters
		filter_whitelist = filter_or(wl_entity_filter, wl_owner_filter, wl_model_filter, wl_class_filter)
	end
	---------------------

	-- finally combine all filters
	--self.data.findfilter = filter_and(find.filter_default, filter_blacklist, filter_whitelist)
	self.data.findfilter = filter_and(find.filter_default, bl_entity_filter, bl_owner_filter, bl_model_filter, bl_class_filter, filter_whitelist)
end

local function applyFindList(self, findlist)
	local findfilter = self.data.findfilter
	if not findfilter then
		update_filters(self)
		findfilter = self.data.findfilter
	end
	filterList(findlist, findfilter)

	self.data.findlist = findlist
	return #findlist
end

--[[************************************************************************]]--


local _findrate = CreateConVar("wire_expression2_find_rate", 0.05,{FCVAR_ARCHIVE,FCVAR_NOTIFY})
local _maxfinds = CreateConVar("wire_expression2_find_max",10,{FCVAR_ARCHIVE,FCVAR_NOTIFY})
local function findrate() return _findrate:GetFloat() end
local function maxfinds() return _maxfinds:GetInt() end

local chiplist = {}

registerCallback("construct", function(self)
	self.data.find = {
		filter_default = filter_default(self),
		bl_entity = {},
		bl_owner = {},
		bl_model = {},
		bl_class = {},

		wl_entity = {},
		wl_owner = {},
		wl_model = {},
		wl_class = {},
	}
	invalidate_filters(self)
	self.data.findnext = 0
	self.data.findlist = {}
	self.data.findcount = maxfinds()
	chiplist[self.data] = true
end)

registerCallback("destruct", function(self)
	chiplist[self.data] = nil
end)

hook.Add("EntityRemoved", "wire_expression2_find_EntityRemoved", function(ent)
	for chip,_ in pairs(chiplist) do
		local find = chip.find
		find.bl_entity[ent] = nil
		find.bl_owner[ent] = nil
		find.wl_entity[ent] = nil
		find.wl_owner[ent] = nil

		filterList(chip.findlist, function(v) return ent ~= v end)
	end
end)


--[[************************************************************************]]--

function query_blocked(self, update)
	if (update) then
		if (self.data.findcount > 0) then
			self.data.findcount = self.data.findcount - 1
			return false
		else
			return self:throw("You cannot send a new find request yet!", true)
		end
	end
	return (self.data.findcount < 1)
end

-- Adds to the available find calls
local delay = 0
local function addcount()
	if (delay > CurTime()) then return end
	delay = CurTime() + findrate()

	for v,_ in pairs( chiplist ) do
		if (v and v.findcount and v.findcount < maxfinds()) then
			v.findcount = v.findcount + 1
		end
	end
end
hook.Add("Think","Wire_Expression2_Find_AddCount",addcount)

__e2setcost(2)

--- Returns the minimum delay between entity find events on a chip
[nodiscard]
e2function number findUpdateRate()
	return findrate()
end

-- Returns the maximum number of finds per E2
[nodiscard]
e2function number findMax()
	return maxfinds()
end

-- Returns the remaining available find calls
[nodiscard]
e2function number findCount()
	return self.data.findcount
end

--[[ This function wasn't used
--- Returns the minimum delay between entity find events per player
e2 function number findPlayerUpdateRate()
	return wire_exp2_playerFindRate:GetFloat()
end
]]

--- Returns 1 if find functions can be used, 0 otherwise.
e2function number findCanQuery()
	return query_blocked(self) and 0 or 1
end

--[[************************************************************************]]--
__e2setcost(30)

--- Finds entities in a sphere around V with a radius of N, returns the number found after filtering
e2function number findInSphere(vector center, radius)
	if query_blocked(self, 1) then return 0 end
	center = Vector(center[1], center[2], center[3])

	return applyFindList(self,ents.FindInSphere(center, radius))
end

--- Like findInSphere but with a [[http://mathworld.wolfram.com/SphericalCone.html Spherical cone]], arguments are for position, direction, length, and degrees (works now)
e2function number findInCone(vector position, vector direction, length, degrees)
	if query_blocked(self, 4) then return 0 end

	position = Vector(position[1], position[2], position[3])
	direction = Vector(direction[1], direction[2], direction[3]):GetNormalized()

	local findlist = ents.FindInSphere(position, length)

	local cosDegrees = math.cos(math.rad(degrees))
	local Dot = direction.Dot

	-- update filter and apply it, together with the cone filter. This is an optimization over applying the two filters in separate passes
	if not self.data.findfilter then update_filters(self) end
	filterList(findlist, filter_and(
		self.data.findfilter,
		function(ent)
			return Dot(direction, (ent:GetPos() - position):GetNormalized()) > cosDegrees
		end
	))

	self.data.findlist = findlist
	return #findlist
end

--- Like findInSphere but with a globally aligned box, the arguments are the diagonal corners of the box
e2function number findInBox(vector min, vector max)
	if query_blocked(self, 1) then return 0 end
	min = Vector(min[1], min[2], min[3])
	max = Vector(max[1], max[2], max[3])
	return applyFindList(self, ents.FindInBox(min, max))
end

--- Find all entities with the given name
e2function number findByName(string name)
	if query_blocked(self, 1) then return 0 end
	return applyFindList(self, ents.FindByName(name))
end

--- Find all entities with the given model
e2function number findByModel(string model)
	if query_blocked(self, 1) then return 0 end
	return applyFindList(self, ents.FindByModel(model))
end

--- Find all entities with the given class
e2function number findByClass(string class)
	if query_blocked(self, 1) then return 0 end
	return applyFindList(self, ents.FindByClass(class))
end

--[[************************************************************************]]--

local function findPlayer(name)
	name = string.lower(name)
	return filterList(player.GetAll(), function(ent) return string.find(string.lower(ent:GetName()), name,1,true) end)[1]
end

--- Returns the player with the given name, this is an exception to the rule
[nodiscard]
e2function entity findPlayerByName(string name)
	if query_blocked(self, 1) then return nil end
	return findPlayer(name)
end

--- Returns the player with the given SteamID
[nodiscard]
e2function entity findPlayerBySteamID(string id)
	if query_blocked(self, 1) then return NULL end
	return player.GetBySteamID(id) or NULL
end

--- Returns the player with the given SteamID64
[nodiscard]
e2function entity findPlayerBySteamID64(string id)
	if query_blocked(self, 1) then return NULL end
	return player.GetBySteamID64(id) or NULL
end

--[[************************************************************************]]--
__e2setcost(10)

--- Exclude all entities from <arr> from future finds
e2function void findExcludeEntities(array arr)
	local bl_entity = self.data.find.bl_entity
	local IsValid = IsValid

	for _,ent in ipairs(arr) do
		if not IsValid(ent) then return end
		bl_entity[ent] = true
	end
	invalidate_filters(self)
end

--- Exclude <ent> from future finds
e2function void findExcludeEntity(entity ent)
	if not IsValid(ent) then return end
	self.data.find.bl_entity[ent] = true
	invalidate_filters(self)
end

--- Exclude this player from future finds (put it on the entity blacklist)
e2function void findExcludePlayer(entity ply) = e2function void findExcludeEntity(entity ent)

--- Exclude this player from future finds (put it on the entity blacklist)
e2function void findExcludePlayer(string name)
	local ply = findPlayer(name)
	if not ply then return end
	self.data.find.bl_entity[ply] = true
	invalidate_filters(self)
end

--- Exclude entities owned by this player from future finds
e2function void findExcludePlayerProps(entity ply)
	if not IsValid(ply) then return end
	self.data.find.bl_owner[ply] = true
	invalidate_filters(self)
end

--- Exclude entities owned by this player from future finds
e2function void findExcludePlayerProps(string name)
	local ply = findPlayer(name)
	if not ply then return end
	registeredfunctions.e2_findExcludePlayerProps_e(self, { nil, { function() return ply end } })
end

--- Exclude entities with this model (or partial model name) from future finds
e2function void findExcludeModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", nil) end	
	self.data.find.bl_model[string.lower(model)] = true
	invalidate_filters(self)
end

--- Exclude entities with this class (or partial class name) from future finds
e2function void findExcludeClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", nil) end
	self.data.find.bl_class[string.lower(class)] = true
	invalidate_filters(self)
end

--[[************************************************************************]]--

--- Remove all entities from <arr> from the blacklist
e2function void findAllowEntities(array arr)
	local bl_entity = self.data.find.bl_entity
	local IsValid = IsValid

	for _,ent in ipairs(arr) do
		if not IsValid(ent) then return end
		bl_entity[ent] = nil
	end
	invalidate_filters(self)
end

--- Remove <ent> from the blacklist
e2function void findAllowEntity(entity ent)
	if not IsValid(ent) then return end
	self.data.find.bl_entity[ent] = nil
	invalidate_filters(self)
end

--- Remove this player from the entity blacklist
e2function void findAllowPlayer(entity ply) = e2function void findAllowEntity(entity ent)

--- Remove this player from the entity blacklist
e2function void findAllowPlayer(string name)
	local ply = findPlayer(name)
	if not ply then return end
	self.data.find.bl_entity[ply] = nil
	invalidate_filters(self)
end

--- Remove entities owned by this player from the blacklist
e2function void findAllowPlayerProps(entity ply)
	if not IsValid(ply) then return end
	self.data.find.bl_owner[ply] = nil
	invalidate_filters(self)
end

--- Remove entities owned by this player from the blacklist
e2function void findAllowPlayerProps(string name)
	local ply = findPlayer(name)
	if not ply then return end
	registeredfunctions.e2_findAllowPlayerProps_e(self, { nil, { function() return ply end } })
end

--- Remove entities with this model (or partial model name) from the blacklist
e2function void findAllowModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", nil) end
	self.data.find.bl_model[string.lower(model)] = nil
	invalidate_filters(self)
end

--- Remove entities with this class (or partial class name) from the blacklist
e2function void findAllowClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", nil) end
	self.data.find.bl_class[string.lower(class)] = nil
	invalidate_filters(self)
end

--[[************************************************************************]]--

--- Include all entities from <arr> in future finds, and remove others not in the whitelist
e2function void findIncludeEntities(array arr)
	local wl_entity = self.data.find.wl_entity
	local IsValid = IsValid

	for _,ent in ipairs(arr) do
		if not IsValid(ent) then return end
		wl_entity[ent] = true
	end
	invalidate_filters(self)
end

--- Include <ent> in future finds, and remove others not in the whitelist
e2function void findIncludeEntity(entity ent)
	if not IsValid(ent) then return end
	self.data.find.wl_entity[ent] = true
	invalidate_filters(self)
end

--- Include this player in future finds, and remove other entities not in the entity whitelist
e2function void findIncludePlayer(entity ply) = e2function void findIncludeEntity(entity ent)

--- Include this player in future finds, and remove other entities not in the entity whitelist
e2function void findIncludePlayer(string name)
	local ply = findPlayer(name)
	if not ply then return end
	self.data.find.wl_entity[ply] = true
	invalidate_filters(self)
end

--- Include entities owned by this player from future finds, and remove others not in the whitelist
e2function void findIncludePlayerProps(entity ply)
	if not IsValid(ply) then return end
	self.data.find.wl_owner[ply] = true
	invalidate_filters(self)
end

--- Include entities owned by this player from future finds, and remove others not in the whitelist
e2function void findIncludePlayerProps(string name)
	local ply = findPlayer(name)
	if not ply then return end
	registeredfunctions.e2_findIncludePlayerProps_e(self, { nil, { function() return ply end } })
end

--- Include entities with this model (or partial model name) in future finds, and remove others not in the whitelist
e2function void findIncludeModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", nil) end
	self.data.find.wl_model[string.lower(model)] = true
	invalidate_filters(self)
end

--- Include entities with this class (or partial class name) in future finds, and remove others not in the whitelist
e2function void findIncludeClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", nil) end
	self.data.find.wl_class[string.lower(class)] = true
	invalidate_filters(self)
end

--[[************************************************************************]]--

--- Remove all entities from <arr> from the whitelist
e2function void findDisallowEntities(array arr)
	local wl_entity = self.data.find.wl_entity
	local IsValid = IsValid

	for _,ent in ipairs(arr) do
		if not IsValid(ent) then return end
		wl_entity[ent] = nil
	end
	invalidate_filters(self)
end

--- Remove <ent> from the whitelist
e2function void findDisallowEntity(entity ent)
	if not IsValid(ent) then return end
	self.data.find.wl_entity[ent] = nil
	invalidate_filters(self)
end

--- Remove this player from the entity whitelist
e2function void findDisallowPlayer(entity ply) = e2function void findDisallowEntity(entity ent)

--- Remove this player from the entity whitelist
e2function void findDisallowPlayer(string name)
	local ply = findPlayer(name)
	if not ply then return end
	self.data.find.wl_entity[ply] = nil
	invalidate_filters(self)
end

--- Remove entities owned by this player from the whitelist
e2function void findDisallowPlayerProps(entity ply)
	if not IsValid(ply) then return end
	self.data.find.wl_owner[ply] = nil
	invalidate_filters(self)
end

--- Remove entities owned by this player from the whitelist
e2function void findDisallowPlayerProps(string name)
	local ply = findPlayer(name)
	if not ply then return end
	registeredfunctions.e2_findDisallowPlayerProps_e(self, { nil, { function() return ply end } })
end

--- Remove entities with this model (or partial model name) from the whitelist
e2function void findDisallowModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", nil) end
	self.data.find.wl_model[string.lower(model)] = nil
	invalidate_filters(self)
end

--- Remove entities with this class (or partial class name) from the whitelist
e2function void findDisallowClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", nil) end
	self.data.find.wl_class[string.lower(class)] = nil
	invalidate_filters(self)
end

--[[************************************************************************]]--

--- Clear all entries from the entire blacklist
e2function void findClearBlackList()
	local find = self.data.find
	find.bl_entity = {}
	find.bl_owner = {}
	find.bl_model = {}
	find.bl_class = {}

	invalidate_filters(self)
end

--- Clear all entries from the entity blacklist
e2function void findClearBlackEntityList()
	self.data.find.bl_entity = {}
	invalidate_filters(self)
end

--- Clear all entries from the prop owner blacklist
e2function void findClearBlackPlayerPropList()
	self.data.find.bl_owner = {}
	invalidate_filters(self)
end

--- Clear all entries from the model blacklist
e2function void findClearBlackModelList()
	self.data.find.bl_model = {}
	invalidate_filters(self)
end

--- Clear all entries from the class blacklist
e2function void findClearBlackClassList()
	self.data.find.bl_class = {}
	invalidate_filters(self)
end

--- Clear all entries from the entire whitelist
e2function void findClearWhiteList()
	local find = self.data.find
	find.wl_entity = {}
	find.wl_owner = {}
	find.wl_model = {}
	find.wl_class = {}

	invalidate_filters(self)
end

--- Clear all entries from the player whitelist
e2function void findClearWhiteEntityList()
	self.data.find.wl_entity = {}
	invalidate_filters(self)
end

--- Clear all entries from the prop owner whitelist
e2function void findClearWhitePlayerPropList()
	self.data.find.wl_owner = {}
	invalidate_filters(self)
end

--- Clear all entries from the model whitelist
e2function void findClearWhiteModelList()
	self.data.find.wl_model = {}
	invalidate_filters(self)
end

--- Clear all entries from the class whitelist
e2function void findClearWhiteClassList()
	self.data.find.wl_class = {}
	invalidate_filters(self)
end

--[[************************************************************************]]--
__e2setcost(2)

--- Allows or disallows finding entities on the hardcoded class blocklist, including classes like "prop_dynamic", "physgun_beam" and "gmod_ghost".
e2function void findAllowBlockedClasses(useHardcodedFilter)
	if useHardcodedFilter ~= 0 then
		self.data.find.filter_default = filter_default_without_class_blocklist(self)
	else
		self.data.find.filter_default = filter_default(self)
	end
end

--[[************************************************************************]]--

--- Returns the indexed entity from the previous find event (valid parameters are 1 to the number of entities found)
[nodiscard]
e2function entity findResult(index)
	return self.data.findlist[index]
end

--- Returns the closest entity to the given point from the previous find event
[nodiscard]
e2function entity findClosest(vector position)
	local closest = nil
	local dist = math.huge
	self.prf = self.prf + #self.data.findlist * 10
	for _,ent in pairs(self.data.findlist) do
		if IsValid(ent) then
			local pos = ent:GetPos()
			local xd, yd, zd = pos.x-position[1], pos.y-position[2], pos.z-position[3]
			local curdist = xd*xd + yd*yd + zd*zd
			if curdist < dist then
				closest = ent
				dist = curdist
			end
		end
	end
	return closest
end

--- Formats the query as an array, R:entity(Index) to get a entity, R:string to get a description including the name and entity id.
[nodiscard]
e2function array findToArray()
	local tmp = {}
	for k,v in ipairs(self.data.findlist) do
		tmp[k] = v
	end
	self.prf = self.prf + #tmp / 3
	return tmp
end

--- Equivalent to findResult(1)
[nodiscard]
e2function entity find()
	return self.data.findlist[1]
end

--[[************************************************************************]]--
__e2setcost(10)

--- Sorts the entities from the last find event, index 1 is the closest to point V, returns the number of entities in the list
e2function number findSortByDistance(vector position)
	position = Vector(position[1], position[2], position[3])
	local findlist = self.data.findlist
	self.prf = self.prf + #findlist * 12

	local d = {}
	for i=1, #findlist do
		local v = findlist[i]
		if v:IsValid() then
			d[v] = (position - v:GetPos()):LengthSqr()
		else
			d[v] = math.huge
		end
	end
	table.sort(findlist, function(a, b) return d[a] < d[b] end)
	return #findlist
end

--[[************************************************************************]]--
__e2setcost(5)

local function applyClip(self, filter)
	local findlist = self.data.findlist
	self.prf = self.prf + #findlist * 5

	filterList(findlist, filter)

	return #findlist
end

--- Filters the list of entities by removing all entities that are NOT of this class
e2function number findClipToClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", 0) end
	class = string.lower(class)
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return replace_match(string.lower(ent:GetClass()), class)
	end)
end

--- Filters the list of entities by removing all entities that are of this class
e2function number findClipFromClass(string class)
	if not pcall(WireLib.CheckRegex, sample_string, class) then return self:throw("Search string too complex!", 0) end
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return not replace_match(string.lower(ent:GetClass()), class)
	end)
end

--- Filters the list of entities by removing all entities that do NOT have this model
e2function number findClipToModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", 0) end
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return replace_match(string.lower(ent:GetModel() or ""), model)
	end)
end

--- Filters the list of entities by removing all entities that do have this model
e2function number findClipFromModel(string model)
	if not pcall(WireLib.CheckRegex, sample_string, model) then return self:throw("Search string too complex!", 0) end
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return not replace_match(string.lower(ent:GetModel() or ""), model)
	end)
end

--- Filters the list of entities by removing all entities that do NOT have this name
e2function number findClipToName(string name)
	if not pcall(WireLib.CheckRegex, sample_string, name) then return self:throw("Search string too complex!", 0) end
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return replace_match(string.lower(ent:GetName()), name)
	end)
end

--- Filters the list of entities by removing all entities that do have this name
e2function number findClipFromName(string name)
	if not pcall(WireLib.CheckRegex, sample_string, name) then return self:throw("Search string too complex!", 0) end
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return not replace_match(string.lower(ent:GetName()), name)
	end)
end

--- Filters the list of entities by removing all entities NOT within the specified sphere (center, radius)
e2function number findClipToSphere(vector center, radius)
	center = Vector(center[1], center[2], center[3])
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return center:Distance(ent:GetPos()) <= radius
	end)
end

--- Filters the list of entities by removing all entities within the specified sphere (center, radius)
e2function number findClipFromSphere(vector center, radius)
	center = Vector(center[1], center[2], center[3])
	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return center:Distance(ent:GetPos()) > radius
	end)
end

--- Filters the list of entities by removing all entities NOT on the positive side of the defined plane. (Plane origin, vector perpendicular to the plane) You can define any convex hull using this.
e2function number findClipToRegion(vector origin, vector perpendicular)
	origin = Vector(origin[1], origin[2], origin[3])
	perpendicular = Vector(perpendicular[1], perpendicular[2], perpendicular[3])

	local perpdot = perpendicular:Dot(origin)

	return applyClip(self, function(ent)
		if !IsValid(ent) then return false end
		return perpdot < perpendicular:Dot(ent:GetPos())
	end)
end

-- inrange used in findClip*Box (below)
local function inrange( vec1, vecmin, vecmax )
	if (vec1.x < vecmin.x) then return false end
	if (vec1.y < vecmin.y) then return false end
	if (vec1.z < vecmin.z) then return false end

	if (vec1.x > vecmax.x) then return false end
	if (vec1.y > vecmax.y) then return false end
	if (vec1.z > vecmax.z) then return false end

	return true
end

-- If vecmin is greater than vecmax, flip it
local function sanitize( vecmin, vecmax )
	for I=1, 3 do
		if (vecmin[I] > vecmax[I]) then
			local temp = vecmin[I]
			vecmin[I] = vecmax[I]
			vecmax[I] = temp
		end
	end
	return vecmin, vecmax
end

-- Filters the list of entities by removing all entities within the specified box
e2function number findClipFromBox( vector min, vector max )

	min, max = sanitize( min, max )

	min = Vector(min[1], min[2], min[3])
	max = Vector(max[1], max[2], max[3])

	return applyClip( self, function(ent)
		return !inrange(ent:GetPos(),min,max)
	end)
end

-- Filters the list of entities by removing all entities not within the specified box
e2function number findClipToBox( vector min, vector max )

	min, max = sanitize( min, max )

	min = Vector(min[1], min[2], min[3])
	max = Vector(max[1], max[2], max[3])

	return applyClip( self, function(ent)
		return inrange(ent:GetPos(),min,max)
	end)
end

-- Filters the list of entities by removing all entities equal to this entity
e2function number findClipFromEntity( entity ent )
	if !IsValid( ent ) then return -1 end
	return applyClip( self, function( ent2 )
		if !IsValid(ent2) then return false end
		return ent ~= ent2
	end)
end

-- Filters the list of entities by removing all entities equal to one of these entities
e2function number findClipFromEntities( array entities )
	local lookup = {}
	self.prf = self.prf + #entities / 3
	for k,v in ipairs( entities ) do lookup[v] = true end
	return applyClip( self, function( ent )
		if !IsValid(ent) then return false end
		return !lookup[ent]
	end)
end

-- Filters the list of entities by removing all entities not equal to this entity
e2function number findClipToEntity( entity ent )
	if !IsValid( ent ) then return -1 end
	return applyClip( self, function( ent2 )
		if !IsValid(ent2) then return false end
		return ent == ent2
	end)
end

-- Filters the list of entities by removing all entities not equal to one of these entities
e2function number findClipToEntities( array entities )
	local lookup = {}
	self.prf = self.prf + #entities / 3
	for k,v in ipairs( entities ) do lookup[v] = true end
	return applyClip( self, function( ent )
		if !IsValid(ent) then return false end
		return lookup[ent]
	end)
end

-- Filters the list of entities by removing all props not owned by this player
e2function number findClipToPlayerProps( entity ply )
	if not IsValid(ply) then return -1 end
	return applyClip( self, function( ent )
		if not IsValid(ent) then return false end
		return getOwner(self,ent) == ply
	end)
end

-- Filters the list of entities by removing all props owned by this player
e2function number findClipFromPlayerProps( entity ply )
	if not IsValid(ply) then return -1 end
	return applyClip( self, function( ent )
		if not IsValid(ent) then return false end
		return getOwner(self,ent) ~= ply
	end)
end
