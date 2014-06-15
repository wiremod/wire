local Categories = {
	"Favourites",
	"Chips, Gates",
	"Visuals",
	"Detection",
	"Input, Output",
	"Vehicle Control",
	"Physics",
	"Other",
	"Memory",
	"Advanced",
	"Tools",
	"Options",
}

hook.Add( "AddToolMenuCategories", "WireCategories", function()
	for i=1,#Categories do
		local Category = Categories[i]
		spawnmenu.AddToolCategory("Wire", Category, Category)
	end
end)

local function WireTab()
	spawnmenu.AddToolTab( "Wire", "Wire" )

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
