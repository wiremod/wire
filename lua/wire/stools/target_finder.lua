WireToolSetup.setCategory( "Detection/Beacon" )
WireToolSetup.open( "target_finder", "Target Finder", "gmod_wire_target_finder", nil, "Target Finders" )

if CLIENT then
	language.Add( "Tool.wire_target_finder.name", "Target Finder Beacon Tool (Wire)" )
	language.Add( "Tool.wire_target_finder.desc", "Spawns a target finder beacon for use with the wire system." )

	language.Add( "WireTargetFinderTool_minrange", "Minimum Range:" )
	language.Add( "WireTargetFinderTool_maxrange", "Maximum Range:" )
	language.Add( "WireTargetFinderTool_maxtargets", "Maximum number of targets to track:" )
	language.Add( "WireTargetFinderTool_MaxBogeys", "Max number of bogeys (closest):" )
	language.Add( "WireTargetFinderTool_MaxBogeys_desc", "Set to 0 for all within range, this needs to be atleast as many as Max Targets." )
	language.Add( "WireTargetFinderTool_players", "Target players" )
	language.Add( "WireTargetFinderTool_notowner", "Do not target owner" )
	language.Add( "WireTargetFinderTool_notownersstuff", "Do not target owner's stuff" )
	language.Add( "WireTargetFinderTool_npcs", "Target NPCs" )
	language.Add( "WireTargetFinderTool_npcname", "NPC(s) Filter:" )
	language.Add( "WireTargetFinderTool_beacons", "Target Locators" )
	language.Add( "WireTargetFinderTool_hoverballs", "Target Hoverballs" )
	language.Add( "WireTargetFinderTool_thrusters", "Target Thrusters" )
	language.Add( "WireTargetFinderTool_props", "Target Props" )
	language.Add( "WireTargetFinderTool_propmodel", "Prop Model(s) Filter:" )
	language.Add( "WireTargetFinderTool_vehicles", "Target Vehicles" )
	language.Add( "WireTargetFinderTool_rpgs", "Target RPGs" )
	language.Add( "WireTargetFinderTool_PaintTarget", "Paint Target" )
	language.Add( "WireTargetFinderTool_PaintTarget_desc", "Paints currently selected target(s)." )
	language.Add( "WireTargetFinderTool_casesen", "Case Sensitive" )
	language.Add( "WireTargetFinderTool_playername", "Name(s) Filter:" )
	language.Add( "WireTargetFinderTool_entity", "Entity Name(s):" )
	language.Add( "WireTargetFinderTool_steamname", "SteamID(s) Filter:" )
	language.Add( "WireTargetFinderTool_colorcheck", "Color Filter")
	language.Add( "WireTargetFinderTool_colortarget", "Color Target/Skip")
	language.Add( "WireTargetFinderTool_pcolR", "Red:")
	language.Add( "WireTargetFinderTool_pcolG", "Green:")
	language.Add( "WireTargetFinderTool_pcolB", "Blue:")
	language.Add( "WireTargetFinderTool_pcolA", "Alpha:")
	language.Add( "WireTargetFinderTool_checkbuddylist", "Check Propprotection Buddy List (EXPERIMENTAL!)" )
	language.Add( "WireTargetFinderTool_onbuddylist", "Target Only Buddys (EXPERIMENTAL!)" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("Numpad")
	CreateConVar("wire_target_finders_maxtargets",10)
	CreateConVar("wire_target_finders_maxbogeys",30)
	function TOOL:GetConVars()
		return self:GetClientNumber("maxrange"), self:GetClientNumber("players") ~= 0, self:GetClientNumber("npcs") ~= 0, self:GetClientInfo("npcname"),
			self:GetClientNumber("beacons") ~= 0, self:GetClientNumber("hoverballs") ~= 0, self:GetClientNumber("thrusters") ~= 0, self:GetClientNumber("props") ~= 0,
			self:GetClientInfo("propmodel"), self:GetClientNumber("vehicles") ~= 0, self:GetClientInfo("playername"), self:GetClientNumber("casesen") ~= 0,
			self:GetClientNumber("rpgs") ~= 0, self:GetClientNumber("painttarget") ~= 0, self:GetClientNumber("minrange"), self:GetClientNumber("maxtargets"),
			self:GetClientNumber("maxbogeys"), self:GetClientNumber("notargetowner") ~= 0, self:GetClientInfo("entityfil"), self:GetClientNumber("notownersstuff") ~= 0,
			self:GetClientInfo("steamname"), self:GetClientNumber("colorcheck") ~= 0, self:GetClientNumber("colortarget") ~= 0,
			self:GetClientNumber("pcolR"), self:GetClientNumber("pcolG"), self:GetClientNumber("pcolB"), self:GetClientNumber("pcolA"),
			self:GetClientNumber("checkbuddylist") ~= 0, self:GetClientNumber("onbuddylist") ~= 0
	end
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/targetfinder.mdl",
	modelsize = "",
	minrange = 1,
	maxrange = 1000,
	players = 0,
	npcs = 1,
	npcname = "",
	beacons = 0,
	hoverballs = 0,
	thrusters = 0,
	props = 0,
	propmodel = "",
	vehicles = 0,
	playername = "",
	steamname = "",
	colorcheck = 0,
	colortarget = 0,
	pcolR = 255,
	pcolG = 255,
	pcolB = 255,
	pcolA = 255,
	casesen = 0,
	rpgs = 0,
	painttarget = 1,
	maxtargets = 1,
	maxbogeys = 1,
	notargetowner = 0,
	notownersstuff = 0,
	entityfil = "",
	checkbuddylist = 0,
	onbuddylist = 0,
}

function TOOL:Reload(trace)
	if trace.Entity:IsValid() then
		self:GetOwner():ConCommand("wire_target_finder_entityfil " .. trace.Entity:GetClass() .. "\n")
	else
		self:GetOwner():ConCommand("wire_target_finder_entityfil \n")
	end
	return true
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_target_finder")
	WireToolHelpers.MakeModelSizer(panel, "wire_target_finder_modelsize")
	ModelPlug_AddToCPanel(panel, "TargetFinder", "wire_target_finder", true, 1)
	panel:NumSlider("#WireTargetFinderTool_minrange","wire_target_finder_minrange",1,10000,0)
	panel:NumSlider("#WireTargetFinderTool_maxrange","wire_target_finder_maxrange",1,10000,0)
	panel:NumSlider("#WireTargetFinderTool_maxtargets","wire_target_finder_maxtargets",1,10,0)
	panel:NumSlider("#WireTargetFinderTool_MaxBogeys","wire_target_finder_maxbogeys",0,30,0)
	panel:NumSlider("#WireTargetFinderTool_minrange","wire_target_finder_minrange",1,1000,0)
	panel:CheckBox(	"#WireTargetFinderTool_players","wire_target_finder_players")
	panel:CheckBox(	"#WireTargetFinderTool_notowner","wire_target_finder_notargetowner")
	panel:CheckBox(	"#WireTargetFinderTool_notownersstuff","wire_target_finder_notownersstuff")
	panel:CheckBox(	"#WireTargetFinderTool_npcs","wire_target_finder_npcs")
	panel:TextEntry("#WireTargetFinderTool_npcname","wire_target_finder_npcname")
	panel:CheckBox(	"#WireTargetFinderTool_beacons","wire_target_finder_beacons")
	panel:CheckBox(	"#WireTargetFinderTool_hoverballs","wire_target_finder_hoverballs")
	panel:CheckBox(	"#WireTargetFinderTool_thrusters","wire_target_finder_thrusters")
	panel:CheckBox(	"#WireTargetFinderTool_props","wire_target_finder_props")
	panel:TextEntry("#WireTargetFinderTool_propmodel","wire_target_finder_propmodel")
	panel:CheckBox(	"#WireTargetFinderTool_vehicles","wire_target_finder_vehicles")
	panel:CheckBox(	"#WireTargetFinderTool_rpgs","wire_target_finder_rpgs")
	panel:CheckBox(	"#WireTargetFinderTool_PaintTarget","wire_target_finder_painttarget")
	panel:CheckBox(	"#WireTargetFinderTool_casesen","wire_target_finder_casesen")
	panel:TextEntry("#WireTargetFinderTool_playername","wire_target_finder_playername")
	panel:TextEntry("#WireTargetFinderTool_entity","wire_target_finder_entityfil")
	panel:TextEntry("#WireTargetFinderTool_steamname","wire_target_finder_steamname")
	panel:CheckBox(	"#WireTargetFinderTool_colorcheck","wire_target_finder_colorcheck")
	panel:CheckBox(	"#WireTargetFinderTool_colortarget","wire_target_finder_colortarget")
	panel:NumSlider("#WireTargetFinderTool_pcolR","wire_target_finder_pcolR",0,255,0)
	panel:NumSlider("#WireTargetFinderTool_pcolG","wire_target_finder_pcolG",0,255,0)
	panel:NumSlider("#WireTargetFinderTool_pcolB","wire_target_finder_pcolB",0,255,0)
	panel:NumSlider("#WireTargetFinderTool_pcolA","wire_target_finder_pcolA",0,255,0)
	panel:CheckBox(	"#WireTargetFinderTool_checkbuddylist","wire_target_finder_checkbuddylist")
	panel:CheckBox(	"#WireTargetFinderTool_onbuddylist","wire_target_finder_onbuddylist")
end
