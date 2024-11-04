-- Structure to register components for propcore's sentSpawn function and for thirdparty addons.
-- Most of entity code is by Sevii77 from starfall (https://github.com/Sevii77 / https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_sv/prop_sent.lua).
-- Thanks for making my life easier :)

-- To register - just use register(string classname, table data) in this file, or WireLib.SentSpawn.Register(classname, data) global function.
-- Data is a table with keys as parameter names (case sensitive) and table, where:
--	[1] is lua type,
--	[2] is default value (can be nil, or not declared, if you don't want no default values)
--	[3] is description (can be nil, or not declared, if you don't want descriptions).



-- ----- Regarding E2's propcore's sentSpawn ----- --

-- WARNING: All your data that you want to get from user HAVE TO BE AT THE TOP SCOPE of the data table (second parameter to register function).
-- E.g. You CAN NOT have something like that:
--
--  register("gmod_foo_sent", {
--  	["Model"] = {TYPE_STRING, "models/maxofs2d/button_05.mdl"},
--  	["FooTable"] = {
--      	["FooBool"] = {TYPE_BOOL, true}, ["FooNumber"] = {TYPE_NUMBER, 1}
--  	}
--  })
--
-- You can later on organize it however you want either in _preFactory or _postFactory.

-- WARNING: e2's propcore's sentspawn DO NOT MAKE ANY PROP PROTECTION CHECKS! Check if the entity is not a player/belongs to player yourself!

-- WARNING: You have to validate table structures by yourself!
-- (Either you expect numerical table, ranger data, or any other kind of table.)

-- WARNING: sentSpawn will stop any sent from being spawned, if user passed parameter that isn't registered (or if _pre/postFactory is attempted to be set)!

-- TIP: If you want to stop an entity from being able to be spawned, either return false on Expression2_CanSpawnSent hook, or statically append a classname + true at
-- 		lua/entities/gmod_wire_expression2/core/custom/prop.lua:201 (local blacklistedSents table).
-- 		(Or comment out a register function call in this file, or use WireLib.Unregister, but that possibly can break thirdparty addon support. Use only if you know what you're doing.)

-- TIP: You can use "_preFactory" and "_postFactory" keys to register a callbacks, that will be called before, and after the entity was spawned.
-- 		Parameters are: _preFactory(playerThatTriesToSpawn, entityTable) and _postFactory(playerThatSpawned, spawnedEntity, DataTable)

-- TIP: Most of basic castings is being handled by propcore's sentSpawn function, so you don't have to worry about that.
-- 		(E.g. E2 Vectors/Vectors4 to Color, E2 Strings to Material, etc.)

-- TIP: To return a strict-only error in _preFactory, or _postFactory, just return a string, which contains the error message.
-- 		(If you return a string to non-strict E2, obv it will also stop spawning the entity)

-- Supported types (to which can WireLib.castE2ValueToLuaValue cast E2 values): 
-- TYPE_STRING, TYPE_NUMBER, TYPE_BOOL, TYPE_ENTITY, TYPE_VECTOR,
-- TYPE_COLOR, TYPE_TABLE, TYPE_USERDATA, TYPE_ANGLE, TYPE_DAMAGEINFO,
-- TYPE_MATERIAL, TYPE_EFFECTDATA, TYPE_MATRIX



-- ----- Regarding thirdparty addon support ----- --

-- Tbh you can use this as you want, but make sure not to override existing entries, to not break propSpawn (or do it, if you know what you're doing).

-- WARNING: Obviously, you shouldn't add any sents by WireLib.SentSpawn.Register, or directly to 'wire_spawnable_ents_registry' list, if you don't want them to be spawned by propcore's sentSpawn function.
--		(Or blacklist them beforehand)

local GetOwner = WireLib.GetOwner
local SentSpawn = WireLib.SentSpawn
if not SentSpawn then
	SentSpawn = {}
	WireLib.SentSpawn = SentSpawn
end

-- Registers new class to be able to be spawned using sentSpawn, and appends it to 'wire_spawnable_ents_registry' list.
-- Even tho it's global function, I would recommend appending your entities here in this file. (To keep everything tidy and organized).
-- It've been made global to support thirdparty addons.
---@param class string
---@param data table
function SentSpawn.Register(class, data)
	if TypeID(class) ~= TYPE_STRING then ErrorNoHaltWithStack("Class type must be TYPE_STRING!") return end
	if TypeID(data) ~= TYPE_TABLE then ErrorNoHaltWithStack("Data type must be TYPE_TABLE") return end

	list.Set("wire_spawnable_ents_registry", class, data)
end

-- Deletes registered sent class and it's data from 'wire_spawnable_ents_registry' list.
-- Even tho it can be used as a way to blacklist an entity from being spawned by propcore's sentSpawn function, better use use Expression2_CanSpawnSent hook, or statically
-- blacklist an entity in lua/entities/gmod_wire_expression2/core/custom/prop.lua:201 (local blacklistedSents table).
-- It've been made global to support thirdparty addons.
---@param class string
function SentSpawn.Unregister(class)
	if not list.HasEntry("wire_spawnable_ents_registry", class) then ErrorNoHaltWithStack("Trying to remove entity that is not registered!") return end

	list.GetForEdit("wire_spawnable_ents_registry")[class] = nil
end



local register = SentSpawn.Register

local SocketPlugPairs = {}
for socket, tbl in pairs(list.Get("Wire_Socket_Models")) do
	SocketPlugPairs[socket] = tbl.plug
end
local PlugSocketPairs = table.Flip(SocketPlugPairs)
local gmod_wire_rt_screen_validScreenEffects = {
	normal = true,
	ep1_projector = true,
	ep1_projector_noisy = true,
	flicker1 = true,
	flicker2 = true,
	hl2_combinedisplay1 = true,
	hl2_combinedisplay2 = true,
	hl2_combineholo = true,
	noisy1 = true,
	noisy2 = true,
	scanlines = true
}

-- Sent registering --

----------------------------------------

-- Basic Gmod sents

register("gmod_balloon", {
	["Model"] = {TYPE_STRING, "models/maxofs2d/balloon_classic.mdl", "Path to model"},
	["force"] = {TYPE_NUMBER, -50, "With how much force should the balloon go up? Make it negative to go down"},
	["r"] = {TYPE_NUMBER, 255, "Color's red component"},
	["g"] = {TYPE_NUMBER, 255, "Color's green component"},
	["b"] = {TYPE_NUMBER, 255, "Color's blue component"},
})

register("gmod_button", {
	["Model"] = {TYPE_STRING, "models/maxofs2d/button_05.mdl", "Path to model"},
	["description"] = {TYPE_STRING, "", "Description of the button"},
	["key"] = {TYPE_NUMBER, KEY_NONE, "What key press will this buttom simulate?"},
	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
})

-- register("gmod_cameraprop", {
-- 	["Model"] = {TYPE_STRING, "models/dav0r/camera.mdl", "Path to model"},
-- 	["controlkey"] = {TYPE_NUMBER, KEY_NONE},
-- 	["locked"] = {TYPE_BOOL, false},
-- 	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
-- })

register("gmod_dynamite", {
	["Model"] = {TYPE_STRING, "models/dav0r/tnt/tnt.mdl", "Path to model"},
	["key"] = {TYPE_NUMBER, KEY_NONE},
	["Damage"] = {TYPE_NUMBER, 200},
	["delay"] = {TYPE_NUMBER, 0},
	["remove"] = {TYPE_BOOL, false},
})

-- register("gmod_emitter", {
-- 	["Model"] = {TYPE_STRING, "models/props_lab/tpplug.mdl", "Path to model"},
-- 	["effect"] = {TYPE_STRING, "ManhackSparks"},
-- 	["key"] = {TYPE_NUMBER, KEY_NONE},
-- 	["delay"] = {TYPE_NUMBER, 1},
-- 	["scale"] = {TYPE_NUMBER, 1},
-- 	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
-- 	["starton"] = {TYPE_BOOL, false},
-- })

register("gmod_hoverball", {
	["Model"] = {TYPE_STRING, "models/dav0r/hoverball.mdl", "Path to model"},
	["key_u"] = {TYPE_NUMBER, KEY_NONE, "Key to go up"},
	["key_d"] = {TYPE_NUMBER, KEY_NONE, "Key to go down"},
	["speed"] = {TYPE_NUMBER, 1, "Speed (multiplier)"},
	["resistance"] = {TYPE_NUMBER, 0},
	["strength"] = {TYPE_NUMBER, 1},
})

register("gmod_lamp", {
	["Model"] = {TYPE_STRING, "models/lamps/torch.mdl", "Path to model"},
	["Texture"] = {TYPE_STRING, "effects/flashlight001"},
	["KeyDown"] = {TYPE_NUMBER, KEY_NONE},
	["fov"] = {TYPE_NUMBER, 90},
	["distance"] = {TYPE_NUMBER, 1024},
	["brightness"] = {TYPE_NUMBER, 4},
	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
	["on"] = {TYPE_BOOL, false},
	["r"] = {TYPE_NUMBER, 255},
	["g"] = {TYPE_NUMBER, 255},
	["b"] = {TYPE_NUMBER, 255},
})

register("gmod_light", {
	["Model"] = {TYPE_STRING, "models/maxofs2d/light_tubular.mdl", "Path to model"},
	["KeyDown"] = {TYPE_NUMBER, KEY_NONE},
	["Size"] = {TYPE_NUMBER, 256},
	["Brightness"] = {TYPE_NUMBER, 2},
	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
	["on"] = {TYPE_BOOL, false},
	["lightr"] = {TYPE_NUMBER, 255},
	["lightg"] = {TYPE_NUMBER, 255},
	["lightb"] = {TYPE_NUMBER, 255},
})

register("gmod_thruster", {
	["Model"] = {TYPE_STRING, "models/props_phx2/garbage_metalcan001a.mdl", "Path to model"},
	["effect"] = {TYPE_STRING, "fire"},
	["soundname"] = {TYPE_STRING, "PhysicsCannister.ThrusterLoop"},
	["key"] = {TYPE_NUMBER, KEY_NONE},
	["key_bck"] = {TYPE_NUMBER, -1},
	["force"] = {TYPE_NUMBER, 1500},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["damageable"] = {TYPE_BOOL, false},
})

----------------------------------------

-- Wiremod sents

register("gmod_wire_plug", {
	_preFactory = function(ply, self)
		if not PlugSocketPairs[self.Model] then return "Invalid plug model! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/props_lab/tpplug.mdl", "Plug model"},
	["ArrayInput"] = {TYPE_BOOL, false, "Should there be an array input"}
})

register("gmod_wire_socket", {
	_preFactory = function(ply, self)
		if not SocketPlugPairs[self.Model] then return "Invalid socket model! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/props_lab/tpplugholder_single.mdl", "Path to model"},
	["ArrayInput"] = {TYPE_BOOL, false},
	["WeldForce"] = {TYPE_NUMBER, 5000},
	["AttachRange"] = {TYPE_NUMBER, 5}
})

register("gmod_wire_rt_camera", {
	_preFactory = function(ply, self)
		self.CamFOV = math.Clamp(self.CamFOV, 10, 120)
	end,

	["Model"] = {TYPE_STRING, "models/maxofs2d/camera.mdl", "Path to model"},
	["CamFOV"] = {TYPE_NUMBER, 90}
})

register("gmod_wire_rt_screen", {
	_preFactory = function(ply, self)
		self.ScreenMaterial = string.lower(self.ScreenMaterial)
		if not gmod_wire_rt_screen_validScreenEffects[self.ScreenMaterial] then return "Invalid screen material! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/kobilica/wiremonitorbig.mdl", "Path to model"},
	["ScreenMaterial"] = {TYPE_STRING, "normal"},
})

register("gmod_wire_interactiveprop", {
	_preFactory = function(ply, self)
		if not WireLib.IsValidInteractiveModel(self.Model) then return "Invalid interactive prop model! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/props_lab/reciever01a.mdl", "Path to model"},
})

register("gmod_wire_dataplug", {
	_preFactory = function(ply, self)
		if not PlugSocketPairs[self.Model] then return "Invalid plug model! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/hammy/pci_card.mdl", "Path to model"}
})

register("gmod_wire_datasocket", {
	_preFactory = function(ply, self)
		if not SocketPlugPairs[self.Model] then return "Invalid socket model! (Use only those that are shown on toolgun menu)" end
	end,

	["Model"] = {TYPE_STRING, "models/hammy/pci_slot.mdl", "Path to model"},
	["WeldForce"] = {TYPE_NUMBER, 5000},
	["AttachRange"] = {TYPE_NUMBER, 5}

})

register("gmod_wire_spawner", {
	["Model"] = {TYPE_STRING},
	["delay"] = {TYPE_NUMBER, 0},
	["undo_delay"] = {TYPE_NUMBER, 0},
	["spawn_effect"] = {TYPE_NUMBER, 0},
	["mat"] = {TYPE_STRING, ""},
	["skin"] = {TYPE_NUMBER, 0},
	["r"] = {TYPE_NUMBER, 255},
	["g"] = {TYPE_NUMBER, 255},
	["b"] = {TYPE_NUMBER, 255},
	["a"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_emarker", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_forcer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["Force"] = {TYPE_NUMBER, 1},
	["Length"] = {TYPE_NUMBER, 100},
	["ShowBeam"] = {TYPE_BOOL, true},
	["Reaction"] = {TYPE_BOOL, false},
})

register("gmod_wire_adv_input", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/numpad.mdl", "Path to model"},
	["keymore"] = {TYPE_NUMBER, 3},
	["keyless"] = {TYPE_NUMBER, 1},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["value_min"] = {TYPE_NUMBER, 0},
	["value_max"] = {TYPE_NUMBER, 10},
	["value_start"] = {TYPE_NUMBER, 5},
	["speed"] = {TYPE_NUMBER, 1},
})

register("gmod_wire_oscilloscope", {
	["Model"] = {TYPE_STRING, "models/props_lab/monitor01b.mdl", "Path to model"},
})

register("gmod_wire_dhdd", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
})

register("gmod_wire_friendslist", {
	_preFactory = function(ply, self)
		for k, steamid in pairs(self.steamids) do
			if TypeID(steamid) ~= TYPE_STRING then return "Incorrect 'steamids' entry #"..k.." type! Expected string. Got: "..type( steamid ) end
		end
	end,

	["Model"] = {TYPE_STRING, "models/kobilica/value.mdl", "Path to model"},
	["save_on_entity"] = {TYPE_BOOL, false},
	["steamids"] = {TYPE_TABLE, {}}
})

register("gmod_wire_nailer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["Flim"] = {TYPE_NUMBER, 0},
	["Range"] = {TYPE_NUMBER, 100},
	["ShowBeam"] = {TYPE_BOOL, true},
})

register("gmod_wire_grabber", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
	["Range"] = {TYPE_NUMBER, 100},
	["Gravity"] = {TYPE_BOOL, true},
})

register("gmod_wire_weight", {
	["Model"] = {TYPE_STRING, "models/props_interiors/pot01a.mdl", "Path to model"},
})

register("gmod_wire_exit_point", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
})

register("gmod_wire_latch", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_dataport", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
})

register("gmod_wire_colorer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["outColor"] = {TYPE_BOOL, false},
	["Range"] = {TYPE_NUMBER, 2000},
})

register("gmod_wire_addressbus", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
	["Mem1st"] = {TYPE_NUMBER, 0},
	["Mem2st"] = {TYPE_NUMBER, 0},
	["Mem3st"] = {TYPE_NUMBER, 0},
	["Mem4st"] = {TYPE_NUMBER, 0},
	["Mem1sz"] = {TYPE_NUMBER, 0},
	["Mem2sz"] = {TYPE_NUMBER, 0},
	["Mem3sz"] = {TYPE_NUMBER, 0},
	["Mem4sz"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_cd_disk", {
	["Model"] = {TYPE_STRING, "models/venompapa/wirecd_medium.mdl", "Path to model"},
	["Precision"] = {TYPE_NUMBER, 4},
	["IRadius"] = {TYPE_NUMBER, 10},
	["Skin"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_las_receiver", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
})

register("gmod_wire_lever", {
	_preFactory = function(ply, self)
		self.Model = "models/props_wasteland/tram_leverbase01.mdl"
	end,

	["Min"] = {TYPE_NUMBER, 0},
	["Max"] = {TYPE_NUMBER, 1},
})

register("gmod_wire_waypoint", {
	["Model"] = {TYPE_STRING, "models/props_lab/powerbox02d.mdl", "Path to model"},
	["range"] = {TYPE_NUMBER, 150},
})

register("gmod_wire_vehicle", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_vectorthruster", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_speed.mdl", "Path to model"},
	["force"] = {TYPE_NUMBER, 1500},
	["force_min"] = {TYPE_NUMBER, 0},
	["force_max"] = {TYPE_NUMBER, 10000},
	["oweffect"] = {TYPE_STRING, "fire"},
	["uweffect"] = {TYPE_STRING, "same"},
	["owater"] = {TYPE_BOOL, true},
	["uwater"] = {TYPE_BOOL, true},
	["bidir"] = {TYPE_BOOL, true},
	["soundname"] = {TYPE_STRING, ""},
	["mode"] = {TYPE_NUMBER, 0},
	["angleinputs"] = {TYPE_BOOL, false},
	["lengthismul"] = {TYPE_BOOL, false},
})

register("gmod_wire_user", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["Range"] = {TYPE_NUMBER, 200},
})

register("gmod_wire_twoway_radio", {
	["Model"] = {TYPE_STRING, "models/props_lab/binderblue.mdl", "Path to model"},
})

register("gmod_wire_numpad", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/numpad.mdl", "Path to model"},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["value_off"] = {TYPE_NUMBER, 0, "Value to output when disabled"},
	["value_on"] = {TYPE_NUMBER, 0, "Value to output when enabled"},
})

register("gmod_wire_turret", {
	["Model"] = {TYPE_STRING, "models/weapons/w_smg1.mdl", "Path to model"},
	["delay"] = {TYPE_NUMBER, 0.05},
	["damage"] = {TYPE_NUMBER, 10},
	["force"] = {TYPE_NUMBER, 1},
	["sound"] = {TYPE_STRING, "0"},
	["numbullets"] = {TYPE_NUMBER, 1},
	["spread"] = {TYPE_NUMBER, 0},
	["tracer"] = {TYPE_STRING, "Tracer"},
	["tracernum"] = {TYPE_NUMBER, 1},
})

register("gmod_wire_soundemitter", {
	["Model"] = {TYPE_STRING, "models/cheeze/wires/speaker.mdl", "Path to model"},
	["sound"] = {TYPE_STRING, "synth/square.wav"},
})

register("gmod_wire_textscreen", {
	["Model"] = {TYPE_STRING, "models/kobilica/wiremonitorbig.mdl", "Path to model"},
	["text"] = {TYPE_STRING, ""},
	["chrPerLine"] = {TYPE_NUMBER, 6},
	["textJust"] = {TYPE_NUMBER, 1},
	["valign"] = {TYPE_NUMBER, 0},
	["tfont"] = {TYPE_STRING, "Arial"},
	["fgcolor"] = {TYPE_COLOR, Color(255, 255, 255)},
	["bgcolor"] = {TYPE_COLOR, Color(0, 0, 0)},
})

register("gmod_wire_holoemitter", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
})

register("gmod_wire_textreceiver", {
	_preFactory = function(ply, self)
		for k, v in ipairs(self.Matches) do
			if TypeID(v) ~= TYPE_STRING then return "Incorrect 'Matches' entry #"..k.." type! Expected string. Got: "..type( v ) end
		end
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
	["UseLuaPatterns"] = {TYPE_BOOL, false},
	["Matches"] = {TYPE_TABLE, {"Hello World"}},
	["CaseInsensitive"] = {TYPE_BOOL, true},
})

register("gmod_wire_textentry", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/keyboard.mdl", "Path to model"},
})

register("gmod_wire_teleporter", {
	["Model"] = {TYPE_STRING, "models/props_c17/utilityconducter001.mdl", "Path to model"},
	["UseSounds"] = {TYPE_BOOL, true},
	["UseEffects"] = {TYPE_BOOL, true},
})

register("gmod_wire_target_finder", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/targetfinder.mdl", "Path to model"},
	["range"] = {TYPE_NUMBER, 1000},
	["players"] = {TYPE_BOOL, false},
	["npcs"] = {TYPE_BOOL, true},
	["npcname"] = {TYPE_STRING, ""},
	["beacons"] = {TYPE_BOOL, false},
	["hoverballs"] = {TYPE_BOOL, false},
	["thrusters"] = {TYPE_BOOL, false},
	["props"] = {TYPE_BOOL, false},
	["propmodel"] = {TYPE_STRING, ""},
	["vehicles"] = {TYPE_BOOL, false},
	["playername"] = {TYPE_STRING, ""},
	["casesen"] = {TYPE_BOOL, false},
	["rpgs"] = {TYPE_BOOL, false},
	["painttarget"] = {TYPE_BOOL, true},
	["minrange"] = {TYPE_NUMBER, 1},
	["maxtargets"] = {TYPE_NUMBER, 1},
	["maxbogeys"] = {TYPE_NUMBER, 1},
	["notargetowner"] = {TYPE_BOOL, false},
	["entity"] = {TYPE_STRING, ""},
	["notownersstuff"] = {TYPE_BOOL, false},
	["steamname"] = {TYPE_STRING, ""},
	["colorcheck"] = {TYPE_BOOL, false},
	["colortarget"] = {TYPE_BOOL, false},
	["checkbuddylist"] = {TYPE_BOOL, false},
	["onbuddylist"] = {TYPE_BOOL, false},
	["pcolR"] = {TYPE_NUMBER, 255},
	["pcolG"] = {TYPE_NUMBER, 255},
	["pcolB"] = {TYPE_NUMBER, 255},
	["pcolA"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_digitalscreen", {
	["Model"] = {TYPE_STRING, "models/props_lab/monitor01b.mdl", "Path to model"},
	["ScreenWidth"] = {TYPE_NUMBER, 32},
	["ScreenHeight"] = {TYPE_NUMBER, 32},
})

register("gmod_wire_trail", {
	_preFactory = function(ply, self)
		self.Trail = {
			Color = self.Color,
			Length = self.Length,
			StartSize = self.StartSize,
			EndSize = self.EndSize,
			Material = self.Material
		}
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
	["Color"] = {TYPE_COLOR, Color(255, 255, 255)},
	["Length"] = {TYPE_NUMBER, 5},
	["StartSize"] = {TYPE_NUMBER, 32},
	["EndSize"] = {TYPE_NUMBER, 0},
	["Material"] = {TYPE_STRING, "trails/smoke"},
})

register("gmod_wire_egp", {
	_preFactory = function(ply, self)
		self.model = self.Model
	end,

	["Model"] = {TYPE_STRING, "models/kobilica/wiremonitorbig.mdl", "Path to model"},
})

register("gmod_wire_egp_hud", {
	["Model"] = {TYPE_STRING, "models/bull/dynamicbutton.mdl", "Path to model"},
})

register("gmod_wire_egp_emitter", {
	["Model"] = {TYPE_STRING, "models/bull/dynamicbutton.mdl", "Path to model"},
})

register("gmod_wire_speedometer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_speed.mdl", "Path to model"},
	["z_only"] = {TYPE_BOOL, false},
	["AngVel"] = {TYPE_BOOL, false},
})

register("gmod_wire_trigger", {
	_preFactory = function(ply, self)
		self.model = self.Model
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["filter"] = {TYPE_NUMBER, 0},
	["owneronly"] = {TYPE_BOOL, false},
	["sizex"] = {TYPE_NUMBER, 64},
	["sizey"] = {TYPE_NUMBER, 64},
	["sizez"] = {TYPE_NUMBER, 64},
	["offsetx"] = {TYPE_NUMBER, 0},
	["offsety"] = {TYPE_NUMBER, 0},
	["offsetz"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_socket", {
	["Model"] = {TYPE_STRING, "models/props_lab/tpplugholder_single.mdl", "Path to model"},
	["ArrayInput"] = {TYPE_BOOL, false},
	["WeldForce"] = {TYPE_NUMBER, 5000},
	["AttachRange"] = {TYPE_NUMBER, 5},
})

register("gmod_wire_simple_explosive", {
	["Model"] = {TYPE_STRING, "models/props_c17/oildrum001_explosive.mdl", "Path to model"},
	["key"] = {TYPE_NUMBER, 1},
	["damage"] = {TYPE_NUMBER, 200},
	["removeafter"] = {TYPE_BOOL, false},
	["radius"] = {TYPE_NUMBER, 300},
})

register("gmod_wire_sensor", {
	["Model"] = {TYPE_STRING, "models/props_lab/huladoll.mdl", "Path to model"},
	["xyz_mode"] = {TYPE_BOOL, false},
	["outdist"] = {TYPE_BOOL, true},
	["outbrng"] = {TYPE_BOOL, false},
	["gpscord"] = {TYPE_BOOL, false},
	["direction_vector"] = {TYPE_BOOL, false},
	["direction_normalized"] = {TYPE_BOOL, false},
	["target_velocity"] = {TYPE_BOOL, false},
	["velocity_normalized"] = {TYPE_BOOL, false},
})

register("gmod_wire_screen", {
	["Model"] = {TYPE_STRING, "models/props_lab/monitor01b.mdl", "Path to model"},
	["SingleValue"] = {TYPE_BOOL, false},
	["SingleBigFont"] = {TYPE_BOOL, true},
	["TextA"] = {TYPE_STRING, "Value A"},
	["TextB"] = {TYPE_STRING, "Value B"},
	["LeftAlign"] = {TYPE_BOOL, false},
	["Floor"] = {TYPE_BOOL, false},
	["FormatNumber"] = {TYPE_BOOL, false},
	["FormatTime"] = {TYPE_BOOL, false},
})

register("gmod_wire_detonator", {
	["Model"] = {TYPE_STRING, "models/props_combine/breenclock.mdl", "Path to model"},
	["damage"] = {TYPE_NUMBER, 1},
})

register("gmod_wire_relay", {
	["Model"] = {TYPE_STRING, "models/kobilica/relay.mdl", "Path to model"},
	["keygroup1"] = {TYPE_NUMBER, 1},
	["keygroup2"] = {TYPE_NUMBER, 2},
	["keygroup3"] = {TYPE_NUMBER, 3},
	["keygroup4"] = {TYPE_NUMBER, 4},
	["keygroup5"] = {TYPE_NUMBER, 5},
	["keygroupoff"] = {TYPE_NUMBER, 0},
	["toggle"] = {TYPE_BOOL, true, "Toggleable?"},
	["normclose"] = {TYPE_NUMBER, 0},
	["poles"] = {TYPE_NUMBER, 1},
	["throws"] = {TYPE_NUMBER, 2},
	["nokey"] = {TYPE_BOOL, false},
})

register("gmod_wire_ranger", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
	["range"] = {TYPE_NUMBER, 1500},
	["default_zero"] = {TYPE_BOOL, true},
	["show_beam"] = {TYPE_BOOL, true},
	["ignore_world"] = {TYPE_BOOL, false},
	["trace_water"] = {TYPE_BOOL, false},
	["out_dist"] = {TYPE_BOOL, true},
	["out_pos"] = {TYPE_BOOL, false},
	["out_vel"] = {TYPE_BOOL, false},
	["out_ang"] = {TYPE_BOOL, false},
	["out_col"] = {TYPE_BOOL, false},
	["out_val"] = {TYPE_BOOL, false},
	["out_sid"] = {TYPE_BOOL, false},
	["out_uid"] = {TYPE_BOOL, false},
	["out_eid"] = {TYPE_BOOL, false},
	["out_hnrm"] = {TYPE_BOOL, false},
	["hires"] = {TYPE_BOOL, false},
})

register("gmod_wire_radio", {
	["Model"] = {TYPE_STRING, "models/props_lab/binderblue.mdl", "Path to model"},
	["Channel"] = {TYPE_STRING, "1"},
	["values"] = {TYPE_NUMBER, 4},
	["Secure"] = {TYPE_BOOL, false},
})

register("gmod_wire_thruster", {
	["Model"] = {TYPE_STRING, "models/props_c17/lampShade001a.mdl", "Path to model"},
	["force"] = {TYPE_NUMBER, 1500},
	["force_min"] = {TYPE_NUMBER, 0},
	["force_max"] = {TYPE_NUMBER, 10000},
	["oweffect"] = {TYPE_STRING, "fire"},
	["uweffect"] = {TYPE_STRING, "same"},
	["owater"] = {TYPE_BOOL, true},
	["uwater"] = {TYPE_BOOL, true},
	["bidir"] = {TYPE_BOOL, true},
	["soundname"] = {TYPE_STRING, ""},
})

register("gmod_wire_pod", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_data_satellitedish", {
	["Model"] = {TYPE_STRING, "models/props_wasteland/prison_lamp001c.mdl", "Path to model"},
})

register("gmod_wire_consolescreen", {
	["Model"] = {TYPE_STRING, "models/props_lab/monitor01b.mdl", "Path to model"},
})

register("gmod_wire_pixel", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_output", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/numpad.mdl", "Path to model"},
	["key"] = {TYPE_NUMBER, 1},
})

register("gmod_wire_motor", {
	_preFactory = function(ply, self)
		if not IsValid(self.Ent1) then return "'Ent1' is invalid entity!" end
		if not IsValid(self.Ent2) then return "'Ent2' is invalid entity!" end

		if self.Ent1 == self.Ent2 then return "'Ent1' and 'Ent2' must be different entities!" end

		if self.Ent1:IsPlayer() then return "'Ent1' cannot be a player!" end
		if self.Ent2:IsPlayer() then return "'Ent2' cannot be a player!" end

		if self.Ent1:IsNPC() then return "'Ent1' cannot be an NPC!" end
		if self.Ent2:IsNPC() then return "'Ent2' cannot be an NPC!" end

		if GetOwner(self.Ent1) ~= ply then return "You do not own 'Ent1'!" end
		if GetOwner(self.Ent2) ~= ply then return "You do not own 'Ent2'!" end

		self.model = self.Model
		self.MyId = "e2_spawned_sent"
	end,

	_postFactory = function(ply, self, enttbl)
		MakeWireMotor(
			ply,
			enttbl.Ent1,
			enttbl.Ent2,
			enttbl.Bone1,
			enttbl.Bone2,
			enttbl.LPos1,
			enttbl.LPos2,
			enttbl.friction,
			enttbl.torque,
			0,
			enttbl.torque,
			enttbl.MyId
		)
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["Ent1"] = {TYPE_ENTITY, nil},
	["Ent2"] = {TYPE_ENTITY, nil},
	["Bone1"] = {TYPE_NUMBER, 0},
	["Bone2"] = {TYPE_NUMBER, 0},
	["LPos1"] = {TYPE_VECTOR, Vector()},
	["LPos2"] = {TYPE_VECTOR, Vector()},
	["friction"] = {TYPE_NUMBER, 1},
	["torque"] = {TYPE_NUMBER, 500},
	["forcelimit"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_explosive", {
	["Model"] = {TYPE_STRING, "models/props_c17/oildrum001_explosive.mdl", "Path to model"},
	["key"] = {TYPE_NUMBER, 1},
	["damage"] = {TYPE_NUMBER, 200},
	["delaytime"] = {TYPE_NUMBER, 0},
	["removeafter"] = {TYPE_BOOL, false},
	["radius"] = {TYPE_NUMBER, 300},
	["affectother"] = {TYPE_BOOL, false},
	["notaffected"] = {TYPE_BOOL, false},
	["delayreloadtime"] = {TYPE_NUMBER, 0},
	["maxhealth"] = {TYPE_NUMBER, 100},
	["bulletproof"] = {TYPE_BOOL, false},
	["explosionproof"] = {TYPE_BOOL, false},
	["fallproof"] = {TYPE_BOOL, false},
	["explodeatzero"] = {TYPE_BOOL, true},
	["resetatexplode"] = {TYPE_BOOL, true},
	["fireeffect"] = {TYPE_BOOL, true},
	["coloreffect"] = {TYPE_BOOL, true},
	["invisibleatzero"] = {TYPE_BOOL, false},
})

register("gmod_wire_light", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["directional"] = {TYPE_BOOL, false},
	["radiant"] = {TYPE_BOOL, false},
	["glow"] = {TYPE_BOOL, false},
	["brightness"] = {TYPE_NUMBER, 2},
	["size"] = {TYPE_NUMBER, 256},
	["R"] = {TYPE_NUMBER, 255},
	["G"] = {TYPE_NUMBER, 255},
	["B"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_lamp", {
	["Model"] = {TYPE_STRING, "models/lamps/torch.mdl", "Path to model"},
	["Texture"] = {TYPE_STRING, "effects/flashlight001"},
	["FOV"] = {TYPE_NUMBER, 90},
	["Dist"] = {TYPE_NUMBER, 1024},
	["Brightness"] = {TYPE_NUMBER, 8},
	["on"] = {TYPE_BOOL, false},
	["r"] = {TYPE_NUMBER, 255},
	["g"] = {TYPE_NUMBER, 255},
	["b"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_keypad", {
	_preFactory = function(ply, self)
		self.Password = util.CRC(self.Password)
	end,

	["Model"] = {TYPE_STRING, "models/props_lab/keypad.mdl", "Path to model"},
	["Password"] = {TYPE_STRING, nil, "Valid password"},
	["Secure"] = {TYPE_BOOL, true, "Should display asterixes instead of plain numbers?"},
})

register("gmod_wire_data_store", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_range.mdl", "Path to model"},
})

register("gmod_wire_gpulib_controller", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_clutch", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_input", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/numpad.mdl", "Path to model"},
	["keygroup"] = {TYPE_NUMBER, 7},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["value_off"] = {TYPE_NUMBER, 0, "Value to output when disabled"},
	["value_on"] = {TYPE_NUMBER, 1, "Value to output when enabled"},
})

register("gmod_wire_indicator", {
	["Model"] = {TYPE_STRING, "models/segment.mdl", "Path to model"},
	["a"] = {TYPE_NUMBER, 0},
	["b"] = {TYPE_NUMBER, 1},
	["ar"] = {TYPE_NUMBER, 255},
	["ag"] = {TYPE_NUMBER, 0},
	["ab"] = {TYPE_NUMBER, 0},
	["aa"] = {TYPE_NUMBER, 255},
	["br"] = {TYPE_NUMBER, 0},
	["bg"] = {TYPE_NUMBER, 255},
	["bb"] = {TYPE_NUMBER, 0},
	["ba"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_igniter", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["TargetPlayers"] = {TYPE_BOOL, false},
	["Range"] = {TYPE_NUMBER, 2048},
})

register("gmod_wire_hydraulic", {
	_preFactory = function(ply, self)
		if not IsValid(self.Ent1) then return "'Ent1' is invalid entity!" end
		if not IsValid(self.Ent2) then return "'Ent2' is invalid entity!" end

		if self.Ent1 == self.Ent2 then return "'Ent1' and 'Ent2' must be different entities!" end

		if self.Ent1:IsPlayer() then return "'Ent1' cannot be a player!" end
		if self.Ent2:IsPlayer() then return "'Ent2' cannot be a player!" end

		if self.Ent1:IsNPC() then return "'Ent1' cannot be an NPC!" end
		if self.Ent2:IsNPC() then return "'Ent2' cannot be an NPC!" end

		if GetOwner(self.Ent1) ~= ply then return "You do not own 'Ent1'!" end
		if GetOwner(self.Ent2) ~= ply then return "You do not own 'Ent2'!" end

		self.model = self.Model
		self.MyId = "e2_spawned_sent"
	end,

	_postFactory = function(ply, self, enttbl)
		MakeWireHydraulic(
			ply,
			enttbl.Ent1,
			enttbl.Ent2,
			enttbl.Bone1,
			enttbl.Bone2,
			enttbl.LPos1,
			enttbl.LPos2,
			enttbl.width,
			enttbl.material,
			enttbl.speed,
			enttbl.fixed,
			enttbl.stretchonly,
			enttbl.MyId
		)
	end,

	["Model"] = {TYPE_STRING, "models/beer/wiremod/hydraulic.mdl", "Path to model"},
	["Ent1"] = {TYPE_ENTITY, nil},
	["Ent2"] = {TYPE_ENTITY, nil},
	["Bone1"] = {TYPE_NUMBER, 0},
	["Bone2"] = {TYPE_NUMBER, 0},
	["LPos1"] = {TYPE_VECTOR, Vector()},
	["LPos2"] = {TYPE_VECTOR, Vector()},
	["width"] = {TYPE_NUMBER, 3},
	["material"] = {TYPE_STRING, "cable/rope"},
	["speed"] = {TYPE_NUMBER, 16},
	["fixed"] = {TYPE_NUMBER, 0},
	["stretchonly"] = {TYPE_BOOL, false},
})

register("gmod_wire_hudindicator", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["a"] = {TYPE_NUMBER, 0},
	["b"] = {TYPE_NUMBER, 1},
	["material"] = {TYPE_STRING, "models/debug/debugwhite"},
	["showinhud"] = {TYPE_BOOL, false},
	["huddesc"] = {TYPE_STRING, ""},
	["hudaddname"] = {TYPE_BOOL, false},
	["hudshowvalue"] = {TYPE_NUMBER, 0},
	["hudstyle"] = {TYPE_NUMBER, 0},
	["allowhook"] = {TYPE_BOOL, true},
	["fullcircleangle"] = {TYPE_NUMBER, 0},
	["ar"] = {TYPE_NUMBER, 255},
	["ag"] = {TYPE_NUMBER, 0},
	["ab"] = {TYPE_NUMBER, 0},
	["aa"] = {TYPE_NUMBER, 255},
	["br"] = {TYPE_NUMBER, 0},
	["bg"] = {TYPE_NUMBER, 255},
	["bb"] = {TYPE_NUMBER, 0},
	["ba"] = {TYPE_NUMBER, 255},
})

register("gmod_wire_hoverball", {
	["Model"] = {TYPE_STRING, "models/dav0r/hoverball.mdl", "Path to model"},
	["speed"] = {TYPE_NUMBER, 1},
	["resistance"] = {TYPE_NUMBER, 0},
	["strength"] = {TYPE_NUMBER, 1},
	["starton"] = {TYPE_BOOL, true},
})

register("gmod_wire_fx_emitter", {
	_preFactory = function(ply, self)
		if not ComboBox_Wire_FX_Emitter_Options[self.effect] then return "Invalid effect name" end
		self.effect = ComboBox_Wire_FX_Emitter_Options[self.effect]
	end,

	["Model"] = {TYPE_STRING, "models/props_lab/tpplug.mdl", "Path to model"},
	["delay"] = {TYPE_NUMBER, 0.07, "Delay between effect plays"},
	["effect"] = {TYPE_STRING, "sparks", "Name of effect"},
})

register("gmod_wire_hologrid", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["usegps"] = {TYPE_BOOL, false},
})

register("gmod_wire_data_transferer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["Range"] = {TYPE_NUMBER, 25000},
	["DefaultZero"] = {TYPE_BOOL, false},
	["IgnoreZero"] = {TYPE_BOOL, false},
})

register("gmod_wire_graphics_tablet", {
	["Model"] = {TYPE_STRING, "models/kobilica/wiremonitorbig.mdl", "Path to model"},
	["gmode"] = {TYPE_BOOL, false},
	["draw_background"] = {TYPE_BOOL, true},
})

register("gmod_wire_gps", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/gps.mdl", "Path to model"},
})

register("gmod_wire_gimbal", {
	["Model"] = {TYPE_STRING, "models/props_c17/canister01a.mdl", "Path to model"},
})

register("gmod_wire_button", {
	["Model"] = {TYPE_STRING, "models/props_c17/clock01.mdl", "Path to model"},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["value_off"] = {TYPE_NUMBER, 0, "Value to output when disabled"},
	["value_on"] = {TYPE_NUMBER, 1, "Value to output when enabled"},
	["description"] = {TYPE_STRING, "", "Description"},
	["entityout"] = {TYPE_BOOL, false},
})

register("gmod_wire_extbus", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
})

register("gmod_wire_locator", {
	["Model"] = {TYPE_STRING, "models/props_lab/powerbox02d.mdl", "Path to model"},
})

register("gmod_wire_cameracontroller", {
	_preFactory = function(ply, self)
		-- Verifies that all entities are valid, all entities are vehicles, and that passed table is an array
		local i = 0
		for _ in pairs(self.Vehicles) do
			i = i + 1
			if self.Vehicles[i] == nil then return "Vehicles parameter must be of type array!" end
			if TypeID(self.Vehicles[i]) ~= TYPE_ENTITY then return "Vehicles parameter must consist only of entities" end
			if not self.Vehicles[i]:IsVehicle() then return "Vehicles parameter must consist only of vehicles" end
		end
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["ParentLocal"] = {TYPE_BOOL, false, "Should the coordinates be local to the parent?"},
	["AutoMove"] = {TYPE_BOOL, false, "Allow the player to rotate camera using their mouse? (Coordinaets becomes center of orbit)"},
	["FreeMove"] = {TYPE_BOOL, false, "Allow 360 rotation? The 'UnRoll' input can be toggled to match the parent entity's roll. (NOTE: Only used if 'AutoMove' is enabled)"},
	["LocalMove"] = {TYPE_BOOL, false, "Is client movement local to parent? (NOTE: Only used if 'AutoMove' is enabled)"},
	["AllowZoom"] = {TYPE_BOOL, false, "Allow user to move camera in and out using mouse scroller? (NOTE: Only used if 'AutoMove' is enabled. NOTE: Some outputs may become wrong)"},
	["AutoUnclip"] = {TYPE_BOOL, false, "Prevent the camera from clipping into world? (By moving it closer)"},
	["DrawPlayer"] = {TYPE_BOOL, true, "Should user be able to see himself?"},
	["AutoUnclip_IgnoreWater"] = {TYPE_BOOL, false, "Should camera clip into water? (NOTE: Only used if 'AutoUnclip' is enabled)"},
	["DrawParent"] = {TYPE_BOOL, true, "Should the parent of camera be rendered?"},
	["Vehicles"] = {TYPE_TABLE, {}, "Autolink cameras to array of vehicles/seats"}
})

register("gmod_wire_dual_input", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/numpad.mdl", "Path to model"},
	["keygroup"] = {TYPE_NUMBER, 7},
	["keygroup2"] = {TYPE_NUMBER, 4},
	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
	["value_off"] = {TYPE_NUMBER, 0, "Value to output when disabled"},
	["value_on"] = {TYPE_NUMBER, 1, "Value to output when enabled"},
	["value_on2"] = {TYPE_NUMBER, -1},
})

register("gmod_wire_cd_ray", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_beamcaster.mdl", "Path to model"},
	["Range"] = {TYPE_NUMBER, 64},
	["DefaultZero"] = {TYPE_BOOL, false},
})

register("gmod_wire_datarate", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
})

register("gmod_wire_keyboard", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_input.mdl", "Path to model"},
	["AutoBuffer"] = {TYPE_BOOL, true},
	["Synchronous"] = {TYPE_BOOL, true},
	["EnterKeyAscii"] = {TYPE_BOOL, true},
})

-- No idea why it's broken. Starfall can't spawn it either. (duplicator.CreateEntityFromTable(self.player, enttbl) returns invalid entity)
-- register("gmod_wire_dynamic_button", {
-- 	["Model"] = {TYPE_STRING, "models/bull/ranger.mdl", "Path to model"},
-- 	["toggle"] = {TYPE_BOOL, false, "Toggleable?"},
-- 	["value_on"] = {TYPE_NUMBER, 1, "Value to output when enabled"},
-- 	["value_off"] = {TYPE_NUMBER, 0, "Value to output when disabled"},
-- 	["description"] = {TYPE_STRING, "", "Description"},
-- 	["entityout"] = {TYPE_BOOL, false},
-- 	["material_on"] = {TYPE_STRING, "bull/dynamic_button_1"},
-- 	["material_off"] = {TYPE_STRING, "bull/dynamic_button_0"},
-- 	["on_r"] = {TYPE_NUMBER, 255},
-- 	["on_g"] = {TYPE_NUMBER, 255},
-- 	["on_b"] = {TYPE_NUMBER, 255},
-- 	["off_r"] = {TYPE_NUMBER, 255},
-- 	["off_g"] = {TYPE_NUMBER, 255},
-- 	["off_b"] = {TYPE_NUMBER, 255},
-- })

register("gmod_wire_damage_detector", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["includeconstrained"] = {TYPE_BOOL, false},
})

register("gmod_wire_hdd", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
	["DriveID"] = {TYPE_NUMBER, 0},
	["DriveCap"] = {TYPE_NUMBER, 128},
})

register("gmod_wire_watersensor", {
	["Model"] = {TYPE_STRING, "models/beer/wiremod/watersensor.mdl", "Path to model"},
})

register("gmod_wire_value", {
	_preFactory = function(ply, self)
		local castE2TypeToWireValueType = {
			NORMAL = function(val, e2TypeID)
					if e2TypeID == TYPE_NUMBER then return tostring(val) end
					if e2TypeID == TYPE_STRING then return val end

					return nil
				end,
			VECTOR = function(val, e2TypeID)
					if e2TypeID == TYPE_STRING then
						local x,y,z = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
						if x and y and z then return x..", "..y..", "..z end
					end
					if e2TypeID == TYPE_VECTOR then return val[1]..", "..val[2]..", "..val[3] end
					if e2TypeID == TYPE_TABLE then
						if #val >= 3 and isnumber(val[1]) and isnumber(val[2]) and isnumber(val[3]) then
							return val[1]..", "..val[2]..", "..val[3]
						end
					end

					return nil
				end,
			VECTOR2 = function(val, e2TypeID)
					if e2TypeID == TYPE_TABLE and #val >= 2 and isnumber(val[1]) and isnumber(val[2]) then return val[1]..", "..val[2] end
					if e2TypeID == TYPE_STRING then
						local x,y,z = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *$" )
						if x and y and z then return x..", "..y..", "..z end
					end

					return nil
				end,
			VECTOR4 = function(val, e2TypeID)
					if e2TypeID == TYPE_TABLE and #val >= 4 and isnumber(val[1]) and isnumber(val[2]) and isnumber(val[3]) and isnumber(val[4]) then
						return val[1]..", "..val[2]..", "..val[3]..", "..val[4]
					end
					if e2TypeID == TYPE_STRING then
						local x,y,z,a = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
						if x and y and z and a then return x..", "..y..", "..z..", "..a end
					end

					return nil
				end,
			STRING = function(val, e2TypeID)
					return tostring(val)
				end,
			ANGLE = function(val, e2TypeID)
					if e2TypeID == TYPE_ANGLE then return val[1]..", "..val[2]..", "..val[3] end
					if e2TypeID == TYPE_STRING then
						local p,y,r = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
						if p and y and r then return p..", "..y..", "..r end
					end

					return nil
				end
		}

		local additionalDataNames = {
			V = "VECTOR",
			XV2 = "VECTOR2",
			XV4 = "VECTOR4",
			A = "ANGLE",
			S = "STRING",
			N = "NORMAL",
			NUMBER = "NORMAL",
			v = "VECTOR",
			xv2 = "VECTOR2",
			xv4 = "VECTOR4",
			a = "ANGLE",
			s = "STRING",
			n = "NORMAL",
			number = "NORMAL",
			vec = "VECTOR",
			vec2 = "VECTOR2",
			vec4 = "VECTOR4",
			angle = "ANGLE",
			string = "STRING"
		}

		local value = {}
		if #self.value == 0 then self.value = {{"NORMAL", 0}} end

		for i, val in ipairs(self.value) do
			local e2TypeID = TypeID(val)

			if e2TypeID ~= TYPE_TABLE then -- No default value provided. Let's try to find it.
				if e2TypeID == TYPE_NUMBER then val = {"NORMAL", castE2TypeToWireValueType["NORMAL"](val, e2TypeID)}
				elseif e2TypeID == TYPE_VECTOR then val = {"VECTOR", castE2TypeToWireValueType["VECTOR"](val, e2TypeID)}
				elseif e2TypeID == TYPE_ANGLE then val = {"ANGLE", castE2TypeToWireValueType["ANGLE"](val, e2TypeID)}
				elseif e2TypeID == TYPE_STRING then val = {"STRING", castE2TypeToWireValueType["STRING"](val, e2TypeID)}
				else return "Incorrect 'value' parameter #"..i.." type! Expected table (Ex. table(\"normal\", 0)). Got: "..type( steamid ) end
			elseif not isnumber(val[1]) then -- Plain table
				if TypeID(val[1]) ~= TYPE_STRING then return "Incorrect 'value' parameter #"..i.."[1] type! Expected string ('NORMAL/VECTOR/VECTOR2/VECTOR4/ANGLE/STRING'). Got: "..type( val ) end

				local wireValueType = string.upper(tostring(val[1]))
				local CastFunc = castE2TypeToWireValueType[wireValueType]
				if not CastFunc then
					if not additionalDataNames[wireValueType] then return "Incorrect value[" .. i .. "] value! Expected 'NORMAL/VECTOR/VECTOR2/VECTOR4/ANGLE/STRING'. Got '"..wireValueType.."'" end
					wireValueType = additionalDataNames[wireValueType]
					CastFunc = castE2TypeToWireValueType[wireValueType]
				end
				val = {wireValueType, CastFunc(val[2], TypeID(val[2]))}
			elseif #val == 2 then -- vector2
				local tempVal = castE2TypeToWireValueType["VECTOR2"](val[2], typeID(val[2]))
				if not tempVal then
					return "Incorrect 'value' parameter #"..i.." value! Expected 'VECTOR2'. Got: "..tostring(val[2])
				end

				val = {"VECTOR2", tempVal}
			elseif #val==4 then -- vector4
				local tempVal = castE2TypeToWireValueType["VECTOR4"](val[2], typeID(val[2]))
				if not tempVal then return "Incorrect 'value' parameter #"..i.." value! Expected 'VECTOR2'. Got: "..tostring(val[2]) end

				val = {"VECTOR4", tempVal}
			else
				return "Corrupted 'value' parameter data."
			end

			if not isstring(val[1]) or not isstring(val[2]) then return "Corrupted 'value' parameter data." end

			value[i] = {
				DataType = val[1],
				Value = val[2]
			}
		end
		self.value = value
	end,

	["Model"] = {TYPE_STRING, "models/kobilica/value.mdl", "Path to model"},
	["value"] = {TYPE_TABLE, {}, "Values to be stored. Can either be direct value (type will be auto found), array of direct values (types will be auto found), or sequential table of arrays with arr[1]==type, arr[2]==value. (Ex. - \"value\" = table(\n    array(\"VECTOR\", vec(25)), array(\"string\", \"foo\")))"},
})

register("gmod_wire_adv_emarker", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})

register("gmod_wire_wheel", {
	_preFactory = function(ply, self)
		if not IsValid(self.Base) then return "'Base' value is not valid entity!" end

		if self.Base:IsPlayer() then return "'Base' cannot be a player!" end
		if self.Base:IsNPC() then return "'Base' cannot be an NPC!" end
		if GetOwner(self.Base) ~= ply then return "You do not own 'Base' entity!" end
	end,

	_postFactory = function(ply, self, enttbl)
		local motor, axis = constraint.Motor(self, enttbl.Base, 0, enttbl.Bone, Vector(), enttbl.LPos, enttbl.friction, 1000, 0, 0, false, ply, enttbl.forcelimit)
		self:SetWheelBase(enttbl.Base)
		self:SetMotor(motor)
		self:SetDirection(motor.direction)
		local axis = Vector(enttbl.LAxis[1], enttbl.LAxis[2], enttbl.LAxis[3])
		axis:Rotate(self:GetAngles())
		self:SetAxis(axis)
		self:DoDirectionEffect()
	end,

	["Model"] = {TYPE_STRING, "models/props_vehicles/carparts_wheel01a.mdl", "Path to model"},
	["Base"] = {TYPE_ENTITY, nil},
	["Bone"] = {TYPE_NUMBER, 0},
	["LPos"] = {TYPE_VECTOR, Vector()},
	["LAxis"] = {TYPE_VECTOR, Vector(0, 1, 0)},
	["fwd"] = {TYPE_NUMBER, 1},
	["bck"] = {TYPE_NUMBER, -1},
	["stop"] = {TYPE_NUMBER, 0},
	["BaseTorque"] = {TYPE_NUMBER, 3000},
	["friction"] = {TYPE_NUMBER, 1},
	["forcelimit"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_gyroscope", {
	["Model"] = {TYPE_STRING, "models/bull/various/gyroscope.mdl", "Path to model"},
	["out180"] = {TYPE_BOOL, false},
})

register("gmod_wire_eyepod", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
	["DefaultToZero"] = {TYPE_NUMBER, 1, "Default outputs to zero when inactive?"},
	["ShowRateOfChange"] = {TYPE_NUMBER, 1},
	["ClampXMin"] = {TYPE_NUMBER, 0},
	["ClampXMax"] = {TYPE_NUMBER, 0},
	["ClampYMin"] = {TYPE_NUMBER, 0},
	["ClampYMax"] = {TYPE_NUMBER, 0},
	["ClampX"] = {TYPE_NUMBER, 0},
	["ClampY"] = {TYPE_NUMBER, 0},
})

register("gmod_wire_gate", {
	_preFactory = function(ply, self)
		if not GateActions[self.action] then return "Invalid action name!" end
	end,

	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_gate.mdl", "Path to model"},
	["action"] = {TYPE_STRING, "+", "Action name. All action names you can look up at https://github.com/wiremod/wire/tree/master/lua/wire/gates source code. (GateActions global table)"},
})

register("gmod_wire_freezer", {
	["Model"] = {TYPE_STRING, "models/jaanus/wiretool/wiretool_siren.mdl", "Path to model"},
})
