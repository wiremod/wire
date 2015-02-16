local ent_tool_mappings = {
	prop_physics = { "easy_precision", "!weapon_physgun" },
	func_physbox = { "easy_precision", "!weapon_physgun" },
}

local ent_tool_patterns = {
	{"^.*$", ent_tool_mappings},

	{"^prop_", "!weapon_physgun"},
	bogus = {"^gmod_(.*)$", true}, -- The bogus index ensures that this always is iterated last, so extensions can override it.
}

local function pattern_mappings(ent, class, ntapped)
	local function maprep(replacement, result, ...)
		if not result then return end

		if replacement == true then
			return result
		elseif isstring(replacement) then
			return replacement
		elseif istable(replacement) then
			local narray = #replacement
			if narray == 0 then
				return maprep(replacement[result], result, ...)
			else
				return maprep(replacement[((ntapped-1) % narray)+1], result, ...)
			end
		elseif isfunction(replacement) then
			return maprep(replacement(ent, ntapped, result, ...), result, ...)
		end
	end

	for _,pattern,replacement in pairs_map(ent_tool_patterns, unpack) do
		local ret = maprep(replacement, class:match(pattern))
		if ret then return ret end
	end
end

local lastent = NULL
local ntapped = 0

concommand.Add("gmod_tool_auto", function(ply, command, args)
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity
	local class = ent:GetClass()

	if ent ~= lastent then
		lastent = ent
		ntapped = 0
	end
	ntapped = ntapped + 1
	local toolmode = pattern_mappings(ent, class, ntapped)

	if not toolmode then return end
	local weapon = toolmode:match("^!(.*)$")
	if weapon then
		RunConsoleCommand( "use", weapon )
		return
	end

	spawnmenu.ActivateTool(toolmode)
end)

local toolbuttons = {}
hook.Add("PostReloadToolsMenu", "toolcpanel_ListTools",function()
	local toolmenu = g_SpawnMenu:GetToolMenu()
	for toolpanelid=1,#toolmenu.ToolPanels do
		if toolmenu:GetToolPanel(toolpanelid) and toolmenu:GetToolPanel(toolpanelid).List.GetChildren and toolmenu:GetToolPanel(toolpanelid).List:GetChildren()[1] then
			for sectionid,section in pairs(toolmenu:GetToolPanel(toolpanelid).List:GetChildren()[1]:GetChildren()) do
				for buttonid,button in pairs(section:GetChildren()) do
					if tobool(button.Command) then toolbuttons[button.Command] = button end
				end
			end
		end
	end
end)
concommand.Add("toolcpanel", function(ply,cmd,args)
	local panel = toolbuttons["gmod_tool "..args[1]]
	if panel then panel:DoClick() end
end)

-- extension interface:
gmod_tool_auto = {}

local lastuniqueid = 0
--- Adds a pattern to be matched against the entity class for gmod_tool_auto. Good for packs with some kind of naming scheme.
--- Returns a uniqueid that can be used to remove the pattern later.
---
--- replacement can be:
---   true: Use the first pattern capture as the toolmode.
---   string: Use this string as the toolmode.
---   table: Look up first pattern capture and use the result as the toolmode. If nothing was found, the match is ignored.
---   array table: Cycles through the table's entries when using gmod_tool_auto multiple times on the same entity.
---   function(ent, ntapped, capture1, capture2, ...): pass the captures to a function, along with a number that specifies how often gmod_tool_auto was used on the same entity.
---
--- The table/array lookups and function calls are done recursively.
function gmod_tool_auto.AddPattern(pattern, replacement, index)
	lastuniqueid = lastuniqueid + 1
	table.insert(ent_tool_patterns, index or #ent_tool_patterns+1, { pattern, replacement, lastuniqueid })
	return lastuniqueid
end

--- Removes a pattern given by uniqueid
function gmod_tool_auto.RemovePattern(uniqueid)
	for i,pattern,replacement,uid in ipairs_map(ent_tool_patterns, unpack) do
		if uniqueid == uid then
			table.remove(ent_tool_patterns, i)
			return pattern, replacement
		end
	end
end

--- Maps a single entity class for gmod_tool_auto. Good for single tools and tools that break your pack's norm.
--- "replacement" can be the same as in gmod_tool_auto.AddPattern.
function gmod_tool_auto.AddSimple(class, replacement)
	ent_tool_mappings[class] = replacement
end

--- Adds all mappings in the given table to the table of single mappings.
--- This basically corresponds to a bunch of calls to gmod_tool_auto.AddSimple.
function gmod_tool_auto.AddSimpleMultiple(mappings)
	table.Merge(ent_tool_mappings, mappings)
end

--- Returns the pattern table and the table of single mappings.
function gmod_tool_auto.GetTables()
	return ent_tool_patterns, ent_tool_mappings
end

local hook = {Add=function(a,b,c)c()end}

--------------------------------- wiremod part ---------------------------------
local wiremod_mappings = {
	-- wiremod+advdupe
	gmod_wire_gate = "wire_gates",
	gmod_wire_cameracontroller = "wire_cam",
	gmod_wire_cd_lock = "wire_cd_ray",
	gmod_wire_vectorthruster = "wire_vthruster",
	gmod_adv_dupe_paster = "adv_duplicator",
}

-- Cycle with wire_adv and wire_debugger.
for k,v in pairs(wiremod_mappings) do
	wiremod_mappings[k] = { v, "wire_adv", "wire_debugger" }
end

hook.Add("Initialize", "gmod_tool_auto_wiremod", function()
	if not gmod_tool_auto then return end

	gmod_tool_auto.AddPattern("^gmod_(wire_.*)$", { true, "wire_adv", "wire_debugger" })
	gmod_tool_auto.AddSimpleMultiple(wiremod_mappings)
end)

-------------------------- resource distribution part --------------------------
local rd_mappings = {
	resource_node = { "resourcenodes", "rd3_dev_link2" },
	rd_pump = { "pumps", "rd3_dev_link2" },
}

hook.Add("Initialize", "gmod_tool_auto_resource_distribution", function()
	if not gmod_tool_auto then return end

	gmod_tool_auto.AddPattern("^rd_.*_valve$", { "valves", "rd3_dev_link2" })-- TODO: add valve links?

	gmod_tool_auto.AddSimpleMultiple(rd_mappings)
end)

------------------------------- life support part ------------------------------
local ls_mappings = {
	other_screen = "ls3_other",
	other_lamp = "ls3_other_lights",
	other_spotlight = "ls3_other_lights",
}

-- Cycle with smart link tool.
for k,v in pairs(ls_mappings) do
	ls_mappings[k] = { v, "rd3_dev_link2" }
end

hook.Add("Initialize", "gmod_tool_auto_life_support", function()
	if not gmod_tool_auto then return end

	gmod_tool_auto.AddPattern("^storage_.*$",   { "ls3_receptacles", "rd3_dev_link2" })
	gmod_tool_auto.AddPattern("^generator_.*$", { "ls3_energysystems", "rd3_dev_link2" })
	gmod_tool_auto.AddPattern("^other_.*$",     { "ls3_environmental_control", "rd3_dev_link2" })
	gmod_tool_auto.AddPattern("^base_.*$",      { "ls3_environmental_control", "rd3_dev_link2" })
	gmod_tool_auto.AddPattern("^nature_.*$",    { "ls3_environmental_control", "rd3_dev_link2" })

	gmod_tool_auto.AddSimpleMultiple(ls_mappings)
end)

-------------------------------- spacebuild part -------------------------------
local spacebuild_mappings = {
	base_terraformer = "sb_terraformer",
	nature_dev_tree = "sb_dev_plants",
	base_default_res_module = "sbep_res_mods",
}

-- Cycle with smart link tool.
for k,v in pairs(spacebuild_mappings) do
	spacebuild_mappings[k] = { v, "rd3_dev_link2" }
end

hook.Add("Initialize", "gmod_tool_auto_life_support", function()
	if not gmod_tool_auto then return end

	gmod_tool_auto.AddSimpleMultiple(spacebuild_mappings)
end)
