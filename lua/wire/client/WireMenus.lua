-- $Rev: 1366 $
-- $LastChangedDate: 2009-07-20 00:09:28 -0700 (Mon, 20 Jul 2009) $
-- $LastChangedBy: tad2020 $

local Wire_Categories = {
	"Wire - Advanced",
	"Wire - Beacon",
	"Wire - Control",
	"Wire - Data",
	"Wire - Detection",
	"Wire - Display",
	"Wire - Render",
	"Wire - I/O",
	"Wire - Physics",
	"Wire - Tools",
	"Administration",
}

local function WireTab()
	spawnmenu.AddToolTab( "Wire", "Wire" )
	for _,Category in ipairs(Wire_Categories) do
		spawnmenu.AddToolCategory("Wire", Category, Category)
	end

	--start: UGLY HACK, BAD BAD BAD D:
	local oldspawnmenuAddToolMenuOption = spawnmenu.AddToolMenuOption
	function spawnmenu.AddToolMenuOption(tab, category, ...)
		if tab == "Main" and string.lower(string.Left(category, 4)) == "wire" then tab = "Wire" end
		oldspawnmenuAddToolMenuOption(tab, category, ...)
	end
	--end: UGLY HACK, BAD BAD BAD D:
end
hook.Add( "AddToolMenuTabs", "WireTab", WireTab)


-- TODO: add these to the device files themselves???
local devs = {
	["#Max Wiremod Wheels"] 			= "wheels",
	["#Max Wiremod Waypoints"]			= "waypoints",
	["#Max Wiremod Values"] 			= "values",
	["#Max Wiremod Two-way Radios"]		= "twoway_radioes",
	["#Max Wiremod Turrets"]			= "turrets",
	["#Max Wiremod Thrusters"]			= "thrusters",
	["#Max Wiremod Target Finders"]		= "target_finders",
	["#Max Wiremod Speedometers"]		= "speedometers",
	["#Max Wiremod Spawners"]			= "spawners",
	["#Max Wiremod Simple Explosives"]	= "simple_explosive",
	["#Max Wiremod Sensors"]			= "sensors",
	["#Max Wiremod Relays"]				= "relays",
	["#Max Wiremod Rangers"]			= "rangers",
	["#Max Wiremod Radios"]				= "radioes",
	["#Max Wiremod Pods"]				= "pods",
	["#Max Wiremod Sockets"]			= "sockets",
	["#Max Wiremod Plugs"]				= "plugs",
	["#Max Wiremod Outputs"]			= "outputs",
	["#Max Wiremod Oscilloscopes"]		= "oscilloscopes",
	["#Max Wiremod Numpads"]			= "numpads",
	["#Max Wiremod Nailers"]			= "nailers",
	["#Max Wiremod Locators"]			= "locators",
	["#Max Wiremod Inputs"]				= "inputs",
	["#Max Wiremod Hoverballs"]			= "hoverballs",
	["#Max Wiremod Gyroscopes"]			= "gyroscopes",
	["#Max Wiremod GPSes"]				= "gpss",
	["#Max Wiremod Gates - Trig"]		= "gate_trigs",
	["#Max Wiremod Gates - Time"]		= "gate_times",
	["#Max Wiremod Gates - Selection"]	= "gate_selections",
	["#Max Wiremod Gates - Memory"]		= "gate_memorys",
	["#Max Wiremod Gates - Logic"]		= "gate_logics",
	["#Max Wiremod Gates - Comparison"]	= "gate_logics",
	["#Max Wiremod Gates"]				= "gates",
	["#Max Wiremod Forcers"]			= "forcers",
	["#Max Wiremod Explosives"]			= "explosive",
	["#Max Wiremod Dual Inputs"]		= "dual_inputs",
	["#Max Wiremod Detonators"]			= "detonators",
	["#Max Wiremod CPUs"]				= "cpus",
	["#Max Wiremod Buttons"]			= "buttons",
	["#Max Wiremod Adv. Inputs"]		= "adv_inputs",
}

function AddWireAdminMaxDevice(pluralname, dev)
	devs["Max Wiremod "..pluralname] = dev
end

if SinglePlayer() then
	local function BuildAdminControlPanel(Panel)
		for name,dev in pairs(devs) do
			local slider = Panel:NumSlider(name, "sbox_maxwire_"..dev, 0, 999, 0)
			slider.dev = dev
		end
	end

	local function AddWireAdminControlPanelMenu()
		spawnmenu.AddToolMenuOption("Wire", "Administration", "WireAdminControlPanel", "Max Wire Devices", "", "", BuildAdminControlPanel, {})
	end
	hook.Add("PopulateToolMenu", "AddAddWireAdminControlPanelMenu", AddWireAdminControlPanelMenu)
end
