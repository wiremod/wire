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

local devs = {}
function AddWireAdminMaxDevice(pluralname, dev)
	devs[pluralname] = dev
end

local function BuildAdminControlPanel(Panel)
	for name,dev in pairs(devs) do
		local slider = Panel:NumSlider(name, "sbox_max"..dev, 0, 999, 0)
	end
end

local function AddWireAdminControlPanelMenu()
	spawnmenu.AddToolMenuOption("Utilities", "Admin", "WireAdminControlPanel", "Max Wire Devices", "", "", BuildAdminControlPanel, {})
end
hook.Add("PopulateToolMenu", "AddAddWireAdminControlPanelMenu", AddWireAdminControlPanelMenu)
