WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "thruster", "Thruster", "gmod_wire_thruster", nil, "Thrusters" )

if CLIENT then
	language.Add( "tool.wire_thruster.name", "Thruster Tool (Wire)" )
	language.Add( "tool.wire_thruster.desc", "Spawns a thruster for use with the wire system." )
	language.Add( "WireThrusterTool_Model", "Model:" )
	language.Add( "WireThrusterTool_force", "Force multiplier:" )
	language.Add( "WireThrusterTool_force_min", "Input threshold:" )
	language.Add( "WireThrusterTool_force_min.help", "If the input force is below this amount, the thruster will not fire.")
	language.Add( "WireThrusterTool_force_max", "Force maximum:" )
	language.Add( "WireThrusterTool_bidir", "Bi-directional" )
	language.Add( "WireThrusterTool_soundname", "Select sound" )
	language.Add( "WireThrusterTool_owater", "Works out of water" )
	language.Add( "WireThrusterTool_uwater", "Works under water" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	force		= 1500,
	force_min	= 0,
	force_max	= 10000,
	model		= "models/props_c17/lampShade001a.mdl",
	bidir		= 1,
	soundname 	= "",
	oweffect	= "fire",
	uweffect	= "same",
	owater		= 1,
	uwater		= 1,
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "force" ), self:GetClientNumber( "force_min" ), self:GetClientNumber( "force_max" ), self:GetClientInfo( "oweffect" ),
			self:GetClientInfo( "uweffect" ), self:GetClientNumber( "owater" ) ~= 0, self:GetClientNumber( "uwater" ) ~= 0, self:GetClientNumber( "bidir" ) ~= 0,
			self:GetClientInfo( "soundname" )
	end
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_thruster")

	WireDermaExts.ModelSelect(panel, "wire_thruster_model", list.Get( "ThrusterModels" ), 4, true)

	local Effects = {
		["#No Effects"] = "none",
		--["#Same as over water"] = "same",
		["#Flames"] = "fire",
		["#Plasma"] = "plasma",
		["#Smoke"] = "smoke",
		["#Smoke Random"] = "smoke_random",
		["#Smoke Do it Youself"] = "smoke_diy",
		["#Exhaust"] = "exhaust",
		["#Exhaust Do it Yourself"] = "exhaust_diy",
		["#Rings"] = "rings",
		["#Rings Growing"] = "rings_grow",
		["#Rings Shrinking"] = "rings_shrink",
		["#Bubbles"] = "bubble",
		["#Magic"] = "magic",
		["#Magic Random"] = "magic_color",
		["#Magic Do It Yourself"] = "magic_diy",
		["#Colors"] = "color",
		["#Colors Random"] = "color_random",
		["#Colors Do It Yourself"] = "color_diy",
		["#Blood"] = "blood",
		["#Money"] = "money",
		["#Sperms"] = "sperm",
		["#Feathers"] = "feather",
		["#Candy Cane"] = "candy_cane",
		["#Goldstar"] = "goldstar",
		["#Water Small"] = "water_small",
		["#Water Medium"] = "water_medium",
		["#Water Big"] = "water_big",
		["#Water Huge"] = "water_huge",
		["#Striderblood Small"] = "striderblood_small",
		["#Striderblood Medium"] = "striderblood_medium",
		["#Striderblood Big"] = "striderblood_big",
		["#Striderblood Huge"] = "striderblood_huge",
		["#More Sparks"] = "more_sparks",
		["#Spark Fountain"] = "spark_fountain",
		["#Jetflame"] = "jetflame",
		["#Jetflame Do It Yourself"] = "jetflame_diy",
		["#Jetflame Blue"] = "jetflame_blue",
		["#Jetflame Red"] = "jetflame_red",
		["#Jetflame Purple"] = "jetflame_purple",
		["#Comic Balls"] = "balls",
		["#Comic Balls Random"] = "balls_random",
		["#Comic Balls Fire Colors"] = "balls_firecolors",
		["#Souls"] = "souls",
		--["#Debugger 10 Seconds"] = "debug_10", These are just buggy and shouldn't be used.
		--["#Debugger 30 Seconds"] = "debug_30",
		--["#Debugger 60 Seconds"] = "debug_60",
		["#Fire and Smoke"] = "fire_smoke",
		["#Fire and Smoke Huge"] = "fire_smoke_big",
		["#Flamethrower"] = "flamethrower",
		["#5 Growing Rings"] = "rings_grow_rings",
		["#Color and Magic"] = "color_magic",
	}

	local CateGoryOW = vgui.Create("DCollapsibleCategory")
		CateGoryOW:SetSize(0, 50)
		CateGoryOW:SetExpanded(0)
		CateGoryOW:SetLabel("Overwater Effect List")

	local ctrl = vgui.Create( "MatSelect", CateGoryOW )
		ctrl:SetItemWidth( 128 )
		ctrl:SetItemHeight( 128 )
		ctrl:SetConVar("wire_thruster_oweffect")
		for name, mat in pairs( Effects ) do
			ctrl:AddMaterialEx( name, "gui/thrustereffects/"..mat, mat, {wire_thruster_oweffect = mat} )
		end

	CateGoryOW:SetContents( ctrl )

	panel:AddItem(CateGoryOW)

	Effects["#Same as over water"] = "same"

	local CateGoryUW = vgui.Create("DCollapsibleCategory")
		CateGoryUW:SetSize(0, 50)
		CateGoryUW:SetExpanded(0)
		CateGoryUW:SetLabel("Underwater Effect List")

	local ctrlUW = vgui.Create( "MatSelect", CateGoryUW )
		ctrlUW:SetItemWidth( 128 )
		ctrlUW:SetItemHeight( 128 )
		ctrlUW:SetConVar("wire_thruster_uweffect")
		for name, mat in pairs( Effects ) do
			ctrlUW:AddMaterialEx( name, "gui/thrustereffects/"..mat, mat, {wire_thruster_uweffect = mat} )
		end

	CateGoryUW:SetContents( ctrlUW )

	panel:AddItem(CateGoryUW)


	local lst = {}
	for k,v in pairs( list.Get("ThrusterSounds") ) do
		lst[k] = {}
		for k2,v2 in pairs( v ) do
			lst[k]["wire_"..k2] = v2
		end
	end

	panel:AddControl( "ComboBox", { Label = "#WireThrusterTool_soundname",
									 Description = "Thruster_Sounds_Desc",
									 MenuButton = "0",
									 Options = lst } )

	panel:NumSlider("#WireThrusterTool_force", "wire_thruster_force", 1, 10000, 0)
	panel:NumSlider("#WireThrusterTool_force_min", "wire_thruster_force_min", -10000, 10000, 0):SetTooltip("#WireThrusterTool_force_min.help")
	panel:NumSlider("#WireThrusterTool_force_max", "wire_thruster_force_max", -10000, 10000, 0)
	panel:CheckBox("#WireThrusterTool_bidir", "wire_thruster_bidir")
	panel:CheckBox("#WireThrusterTool_owater", "wire_thruster_owater")
	panel:CheckBox("#WireThrusterTool_uwater", "wire_thruster_uwater")
end
--from model pack 1
list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
