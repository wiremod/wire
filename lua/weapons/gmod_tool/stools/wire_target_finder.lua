
TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "Target Finder"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_target_finder_name", "Target Finder Beacon Tool (Wire)" )
	language12.Add( "Tool_wire_target_finder_desc", "Spawns a target finder beacon for use with the wire system." )
	language12.Add( "Tool_wire_target_finder_0", "Primary: Create/Update Target Finder Beacon" )

	language12.Add( "WireTargetFinderTool_minrange", "Minimum Range:" )
	language12.Add( "WireTargetFinderTool_maxrange", "Maximum Range:" )
	language12.Add( "WireTargetFinderTool_maxtargets", "Maximum number of targets to track:" )
	language12.Add( "WireTargetFinderTool_MaxBogeys", "Max number of bogeys (closest):" )
	language12.Add( "WireTargetFinderTool_MaxBogeys_desc", "Set to 0 for all within range, this needs to be atleast as many as Max Targets." )
	language12.Add( "WireTargetFinderTool_players", "Target players" )
	language12.Add( "WireTargetFinderTool_notowner", "Do not target owner" )
	language12.Add( "WireTargetFinderTool_notownersstuff", "Do not target owner's stuff" )
	language12.Add( "WireTargetFinderTool_npcs", "Target NPCs" )
	language12.Add( "WireTargetFinderTool_npcname", "NPC Filter:" )
	language12.Add( "WireTargetFinderTool_beacons", "Target Locators" )
	language12.Add( "WireTargetFinderTool_hoverballs", "Target Hoverballs" )
	language12.Add( "WireTargetFinderTool_thrusters", "Target Thrusters" )
	language12.Add( "WireTargetFinderTool_props", "Target Props" )
	language12.Add( "WireTargetFinderTool_propmodel", "Prop Model Filter:" )
	language12.Add( "WireTargetFinderTool_vehicles", "Target Vehicles" )
	language12.Add( "WireTargetFinderTool_rpgs", "Target RPGs" )
	--language12.Add( "WireTargetFinderTool_OutDistance", "Output Distance/Bearing/Elevation:" )
	language12.Add( "WireTargetFinderTool_PaintTarget", "Paint Target" )
	language12.Add( "WireTargetFinderTool_PaintTarget_desc", "Paints currently selected target(s)." )
	language12.Add( "WireTargetFinderTool_casesen", "Case Sensitive" )
	language12.Add( "WireTargetFinderTool_playername", "Name Filter:" )
	language12.Add( "WireTargetFinderTool_entity", "Entity Name:" )
	language12.Add( "WireTargetFinderTool_steamname", "SteamID Filter:" )
	language12.Add( "WireTargetFinderTool_colorcheck", "Color Filter")
	language12.Add( "WireTargetFinderTool_colortarget", "Color Target/Skip")
	language12.Add( "WireTargetFinderTool_pcolR", "Red:")
	language12.Add( "WireTargetFinderTool_pcolG", "Green:")
	language12.Add( "WireTargetFinderTool_pcolB", "Blue:")
	language12.Add( "WireTargetFinderTool_pcolA", "Alpha:")
	language12.Add( "WireTargetFinderTool_checkbuddylist", "Check Propprotection Buddy List (EXPERIMENTAL!)" )
	language12.Add( "WireTargetFinderTool_onbuddylist", "Target Only Buddys (EXPERIMENTAL!)" )

	language12.Add( "sboxlimit_wire_target_finders", "You've hit target finder beacons limit!" )
	language12.Add( "undone_wiretargetfinder", "Undone Wire Target Finder Beacon" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_target_finders',30)
	CreateConVar("wire_target_finders_maxtargets",10)
	CreateConVar("wire_target_finders_maxbogeys",30)
	ModelPlug_Register("TargetFinder")
end

TOOL.ClientConVar[ "minrange" ]		= "1"
TOOL.ClientConVar[ "maxrange" ]		= "1000"
TOOL.ClientConVar[ "players" ] 		= "0"
TOOL.ClientConVar[ "npcs" ] 		= "1"
TOOL.ClientConVar[ "npcname" ] 		= ""
TOOL.ClientConVar[ "beacons" ] 		= "0"
TOOL.ClientConVar[ "hoverballs" ] 	= "0"
TOOL.ClientConVar[ "thrusters" ] 	= "0"
TOOL.ClientConVar[ "props" ] 		= "0"
TOOL.ClientConVar[ "propmodel" ] 	= ""
TOOL.ClientConVar[ "vehicles" ] 	= "0"
TOOL.ClientConVar[ "playername" ] 	= ""
TOOL.ClientConVar[ "steamname" ] 	= ""
TOOL.ClientConVar[ "colorcheck" ]	= "0"
TOOL.ClientConVar[ "colortarget" ]	= "0"
TOOL.ClientConVar[ "pcolR" ]		= "255"
TOOL.ClientConVar[ "pcolG" ]		= "255"
TOOL.ClientConVar[ "pcolB" ]		= "255"
TOOL.ClientConVar[ "pcolA" ]		= "255"
TOOL.ClientConVar[ "casesen" ] 		= "0"
TOOL.ClientConVar[ "rpgs" ] 		= "0"
TOOL.ClientConVar[ "painttarget" ]	= "1"
TOOL.ClientConVar[ "maxtargets" ]	= "1"
TOOL.ClientConVar[ "maxbogeys" ]	= "1"
TOOL.ClientConVar[ "notargetowner" ]	= "0"
TOOL.ClientConVar[ "notownersstuff" ]	= "0"
TOOL.ClientConVar[ "entityfil" ] 		= ""
TOOL.ClientConVar[ "checkbuddylist" ]	= "0"
TOOL.ClientConVar[ "onbuddylist" ]	= "0"
TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/targetfinder.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""
local ModelInfo = {"","",""}

cleanup.Register( "wire_target_finders" )

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	// Get client's CVars
	local minrange		= self:GetClientNumber("minrange")
	local range			= self:GetClientNumber("maxrange")
	local players		= (self:GetClientNumber("players") ~= 0)
	local npcs			= (self:GetClientNumber("npcs") ~= 0)
	local npcname		= self:GetClientInfo("npcname")
	local beacons		= (self:GetClientNumber("beacons") ~= 0)
	local hoverballs	= (self:GetClientNumber("hoverballs") ~= 0)
	local thrusters		= (self:GetClientNumber("thrusters") ~= 0)
	local props			= (self:GetClientNumber("props") ~= 0)
	local propmodel		= self:GetClientInfo("propmodel")
	local vehicles		= (self:GetClientNumber("vehicles") ~= 0)
	local playername	= self:GetClientInfo("playername")
	local steamname		= self:GetClientInfo("steamname")
	local colorcheck	= (self:GetClientNumber("colorcheck") ~= 0)
	local colortarget	= (self:GetClientNumber("colortarget") ~= 0)
	local pcolR			= self:GetClientNumber("pcolR")
	local pcolG			= self:GetClientNumber("pcolG")
	local pcolB			= self:GetClientNumber("pcolB")
	local pcolA			= self:GetClientNumber("pcolA")
	local casesen		= (self:GetClientNumber("casesen") ~= 0)
	local rpgs 			= (self:GetClientNumber("rpgs") ~= 0)
	local painttarget 	= (self:GetClientNumber("painttarget") ~= 0)
	local maxtargets	= self:GetClientNumber("maxtargets")
	local maxbogeys		= self:GetClientNumber("maxbogeys")
	local notargetowner	= (self:GetClientNumber("notargetowner") != 0)
	local notownersstuff	= (self:GetClientNumber("notownersstuff") != 0)
	local entity		= self:GetClientInfo("entityfil")
	local checkbuddylist = (self:GetClientNumber("checkbuddylist") != 0)
	local onbuddylist	= (self:GetClientNumber("onbuddylist") != 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_target_finder" && trace.Entity.pl == ply ) then
		//trace.Entity:Setup(range, players, npcs, npcname, beacons, hoverballs, thrusters, rpgs, painttarget)
		trace.Entity:Setup(range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist)

		trace.Entity.range			= range
		trace.Entity.players		= players
		trace.Entity.npcs			= npcs
		trace.Entity.npcname		= npcname
		trace.Entity.beacons		= beacons
		trace.Entity.hoverballs		= hoverballs
		trace.Entity.thrusters		= thrusters
		trace.Entity.props			= props
		trace.Entity.propmodel		= propmodel
		trace.Entity.vehicles		= vehicles
		trace.Entity.playername		= playername
		trace.Entity.steamname		= steamname
		trace.Entity.colorcheck		= colorcheck
		trace.Entity.colortarget	= colortarget
		trace.Entity.pcolR			= pcolR
		trace.Entity.pcolG			= pcolG
		trace.Entity.pcolB			= pcolB
		trace.Entity.pcolA			= pcolA
		trace.Entity.casesen		= casesen
		trace.Entity.rpgs			= rpgs
		trace.Entity.painttarget	= painttarget
		trace.Entity.minrange		= minrange
		trace.Entity.maxtargets		= maxtargets
		trace.Entity.maxbogeys		= maxbogeys
		trace.Entity.notargetowner	= notargetowner
		trace.Entity.notownersstuff	= notownersstuff
		trace.Entity.checkbuddylist	= checkbuddylist
		trace.Entity.onbuddylist	= onbuddylist
		trace.Entity.entity			= entity

		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_target_finders" ) ) then return false end

	if ( !util.IsValidModel( ModelInfo[3] ) ) then return false end
	if ( !util.IsValidProp( ModelInfo[3] ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	if(ModelInfo[1]!="models/props_lab/powerbox02d.mdl")then
		Ang.p = Ang.p + 90
	end

	local wire_target_finder = MakeWireTargetFinder( ply, trace.HitPos, Ang, ModelInfo[3], range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist )

	local min = wire_target_finder:OBBMins()
	wire_target_finder:SetPos( trace.HitPos - trace.HitNormal*min.z )

	local const = WireLib.Weld(wire_target_finder, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireTargetFinder")
		undo.AddEntity( wire_target_finder )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_target_finders", wire_target_finder )

	return true

end

function TOOL:Reload(trace)
	if trace.Entity:IsValid() then
		self:GetOwner():ConCommand("wire_target_finder_entityfil "..trace.Entity:GetClass().."\n")
	else
		self:GetOwner():ConCommand("wire_target_finder_entityfil \n")
	end
	return true
end

function TOOL:RightClick(trace)
	return self:LeftClick(trace)
end


if SERVER then

	function MakeWireTargetFinder(pl, Pos, Ang, model, range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist)
		if (!pl:CheckLimit("wire_target_finders")) then return end

		local wire_target_finder = ents.Create("gmod_wire_target_finder")
		wire_target_finder:SetPos(Pos)
		wire_target_finder:SetAngles(Ang)
		wire_target_finder:SetModel( Model(model or "models/props_lab/powerbox02d.mdl") )
		wire_target_finder:Spawn()
		wire_target_finder:Activate()

		wire_target_finder:Setup(range, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel,  vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist)
		wire_target_finder:SetPlayer(pl)

		local ttable = {
			range		= range,
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
			steamname	= steamname,
			colorcheck	= colorcheck,
			colortarget = colortarget,
			pcolR		= pcolR,
			pcolG		= pcolG,
			pcolB		= pcolB,
			pcolA		= pcolA,
			casesen		= casesen,
			rpgs		= rpgs,
			painttarget = painttarget,
			pl			= pl,
			nocollide	= nocollide,
			description	= description,
			minrange	= minrange,
			maxtargets	= maxtargets,
			maxbogeys	= maxbogeys,
			notargetowner 	= notargetowner,
			notownersstuff	= notownersstuff,
			checkbuddylist 	= checkbuddylist,
			onbuddylist		= onbuddylist,
			entity 			= entity,
		}

		table.Merge( wire_target_finder:GetTable(), ttable )

		pl:AddCount( "wire_target_finders", wire_target_finder )

		return wire_target_finder
	end

	duplicator.RegisterEntityClass("gmod_wire_target_finder", MakeWireTargetFinder, "Pos", "Ang", "Model", "range", "players", "npcs", "npcname", "beacons", "hoverballs", "thrusters", "props", "propmodel", "vehicles", "playername", "casesen", "rpgs", "painttarget", "minrange", "maxtargets", "maxbogeys", "notargetowner", "entity", "notownersstuff", "steamname", "colorcheck", "colortarget", "pcolR", "pcolG", "pcolB", "pcolA", "checkbuddylist", "onbuddylist")

end

function TOOL:UpdateGhostWireTargetFinder( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_target_finder" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	if(ModelInfo[1]!="models/props_lab/powerbox02d.mdl")then
		Ang.p = Ang.p + 90
	end
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function TOOL:Think()
	if ModelInfo[1]!= self:GetClientInfo( "model" ) || ModelInfo[2]!= self:GetClientInfo( "modelsize" ) then
		ModelInfo[1] = self:GetClientInfo( "model" )
		ModelInfo[2] = self:GetClientInfo( "modelsize" )
		ModelInfo[3] = ModelInfo[1]
		if (ModelInfo[1] && ModelInfo[2] && ModelInfo[2]!="") then
			local test = string.sub(ModelInfo[1], 1, -5) .. ModelInfo[2] .. string.sub(ModelInfo[1], -4)
			if (util.IsValidModel(test) && util.IsValidProp(test)) then
				ModelInfo[3] = test
			end
		end
		self:MakeGhostEntity( ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
	end
	if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() then
		self:MakeGhostEntity( ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireTargetFinder( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_target_finder_name", Description = "#Tool_wire_target_finder_desc" })

	panel:AddControl("Label", {Text = "Model Size (if available)"})
	panel:AddControl("ComboBox", {
		Label = "Model Size",
		MenuButton = 0,
		Options = {
				["normal"] = { wire_target_finder_modelsize = "" },
				["mini"] = { wire_target_finder_modelsize = "_mini" },
				["nano"] = { wire_target_finder_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(panel, "TargetFinder", "wire_target_finder", "#ToolWireIndicator_Model")
	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_minrange",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_target_finder_minrange"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_maxrange",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_target_finder_maxrange"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_maxtargets",
		Type = "Integer",
		Min = "1",
		Max = "10",
		Command = "wire_target_finder_maxtargets"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_MaxBogeys",
		Description = "#WireTargetFinderTool_MaxBogeys_desc",
		Type = "Integer",
		Min = "0",
		Max = "30",
		Command = "wire_target_finder_maxbogeys"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_players",
		Command = "wire_target_finder_players"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_notowner",
		Command = "wire_target_finder_notargetowner"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_notownersstuff",
		Command = "wire_target_finder_notownersstuff"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_npcs",
		Command = "wire_target_finder_npcs"
	})

	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_npcname",
		Command = "wire_target_finder_npcname",
		MaxLength = "20"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_beacons",
		Command = "wire_target_finder_beacons"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_hoverballs",
		Command = "wire_target_finder_hoverballs"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_thrusters",
		Command = "wire_target_finder_thrusters"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_props",
		Command = "wire_target_finder_props"
	})

	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_propmodel",
		Command = "wire_target_finder_propmodel",
		MaxLength = "100"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_vehicles",
		Command = "wire_target_finder_vehicles"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_rpgs",
		Command = "wire_target_finder_rpgs"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_PaintTarget",
		Description = "#WireTargetFinderTool_PaintTarget_desc",
		Command = "wire_target_finder_painttarget"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_casesen",
		Command = "wire_target_finder_casesen"
	})

	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_playername",
		Command = "wire_target_finder_playername",
		MaxLength = "50"
	})

	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_entity",
		Command = "wire_target_finder_entityfil",
		MaxLength = "50"
	})

	panel:AddControl("TextBox", {
		Label = "#WireTargetFinderTool_steamname",
		Command = "wire_target_finder_steamname",
		MaxLength = "50"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_colorcheck",
		Command = "wire_target_finder_colorcheck"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_colortarget",
		Command = "wire_target_finder_colortarget"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_pcolR",
		Type = "Integer",
		Min = "0",
		Max = "255",
		Command = "wire_target_finder_pcolR"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_pcolG",
		Type = "Integer",
		Min = "0",
		Max = "255",
		Command = "wire_target_finder_pcolG"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_pcolB",
		Type = "Integer",
		Min = "0",
		Max = "255",
		Command = "wire_target_finder_pcolB"
	})

	panel:AddControl("Slider", {
		Label = "#WireTargetFinderTool_pcolA",
		Type = "Integer",
		Min = "0",
		Max = "255",
		Command = "wire_target_finder_pcolA"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_checkbuddylist",
		Command = "wire_target_finder_checkbuddylist"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTargetFinderTool_onbuddylist",
		Command = "wire_target_finder_onbuddylist"
	})

end

