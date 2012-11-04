WireToolSetup.setCategory( "Physics" )

do --wire_turret
	WireToolSetup.open( "turret", "Turret", "gmod_wire_turret", nil )

	-- Precache these sounds..
	Sound( "ambient.electrical_zap_3" )
	Sound( "NPC_FloorTurret.Shoot" )

	-- Add Default Language translation (saves adding it to the txt files)
	if CLIENT then
		language.Add( "tool.wire_turret.name", "Turret" )
		language.Add( "tool.wire_turret.desc", "Throws bullets at things" )
		language.Add( "tool.wire_turret.0", "Click somewhere to spawn an turret. Click on an existing turret to change it." )

		language.Add( "Tool_wire_turret_spread", "Bullet Spread" )
		language.Add( "Tool_wire_turret_numbullets", "Bullets per Shot" )
		language.Add( "Tool_wire_turret_force", "Bullet Force" )
		language.Add( "Tool_wire_turret_sound", "Shoot Sound" )
		language.Add( "Tool_wire_turret_tracernum", "Tracer Every x Bullets:" )

		language.Add( "SBoxLimit_wire_turrets", "You've reached the Turret limit!" )
	end
	WireToolSetup.BaseLang("Turrets")

	TOOL.ClientConVar = {
		delay 		= 0.05,
		force 		= 1,
		sound 		= 0,
		damage 		= 10,
		spread 		= 0,
		numbullets	= 1,
		automatic	= 1,
		tracer 		= "Tracer",
		tracernum 	= 1,
		model		= "models/weapons/w_smg1.mdl"
	}

	TOOL.GhostAngle = Angle(-90,0,0)
	TOOL.GetGhostMin = function() return -2 end

	if SERVER then
		CreateConVar('sbox_maxwire_turrets', 30)
	end

	function TOOL:LeftClick( trace, worldweld )
		if trace.Entity and trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		worldweld = worldweld or false

		local ply = self:GetOwner()

		local delay 		= self:GetClientNumber( "delay" )
		local force 		= self:GetClientNumber( "force" )
		local sound 		= self:GetClientInfo( "sound" )
		local tracer 		= self:GetClientInfo( "tracer" )
		local damage	 	= self:GetClientNumber( "damage" )
		local spread	 	= self:GetClientNumber( "spread" )
		local numbullets 	= self:GetClientNumber( "numbullets" )
		local tracernum 	= self:GetClientNumber( "tracernum" )
		local model 		= self:GetClientInfo( "model" )
		if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

		-- We shot an existing turret - just change its values
		if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_turret" then
			trace.Entity:SetDamage( damage )
			trace.Entity:SetDelay( delay )
			trace.Entity:SetNumBullets( numbullets )
			trace.Entity:SetSpread( spread )
			trace.Entity:SetForce( force )
			trace.Entity:SetSound( sound )
			trace.Entity:SetTracer( tracer )
			trace.Entity:SetTracerNum( tracernum )
			return true
		end

		if not self:GetSWEP():CheckLimit( "wire_turrets" ) then return false end

		trace.HitPos = trace.HitPos + trace.HitNormal * 2

		local Ang=nil

		local turret = MakeWireTurret( ply, trace.HitPos, Ang, model, delay, damage, force, sound, numbullets, spread, tracer, tracernum )

		turret:SetAngles( trace.HitNormal:Angle() )

		local weld = WireLib.Weld(turret, trace.Entity, trace.PhysicsBone, true, false, worldweld)

		undo.Create("WireTurret")
			undo.AddEntity( turret )
			undo.AddEntity( weld )
			undo.SetPlayer( ply )
		undo.Finish()

		return true
	end

	function TOOL:RightClick( trace )
		return self:LeftClick( trace, true )
	end


	function TOOL.BuildCPanel( CPanel )
		WireToolHelpers.MakePresetControl(CPanel, "wire_turret")

		-- Shot sounds
		local weaponSounds = {Label = "#Tool_wire_turret_sound", MenuButton = 0, Options={}, CVars = {}}
			weaponSounds["Options"]["#No Weapon"]	= { wire_turret_sound = "" }
			weaponSounds["Options"]["#Pistol"]		= { wire_turret_sound = "Weapon_Pistol.Single" }
			weaponSounds["Options"]["#SMG"]			= { wire_turret_sound = "Weapon_SMG1.Single" }
			weaponSounds["Options"]["#AR2"]			= { wire_turret_sound = "Weapon_AR2.Single" }
			weaponSounds["Options"]["#Shotgun"]		= { wire_turret_sound = "Weapon_Shotgun.Single" }
			weaponSounds["Options"]["#Floor Turret"]	= { wire_turret_sound = "NPC_FloorTurret.Shoot" }
			weaponSounds["Options"]["#Airboat Heavy"]	= { wire_turret_sound = "Airboat.FireGunHeavy" }
			weaponSounds["Options"]["#Zap"]	= { wire_turret_sound = "ambient.electrical_zap_3" }


		CPanel:AddControl("ComboBox", weaponSounds )

		-- Tracer
		local TracerType = {Label = "#Tracer", MenuButton = 0, Options={}, CVars = {}}
			TracerType["Options"]["#Default"]			= { wire_turret_tracer = "Tracer" }
			TracerType["Options"]["#AR2 Tracer"]		= { wire_turret_tracer = "AR2Tracer" }
			TracerType["Options"]["#Airboat Tracer"]	= { wire_turret_tracer = "AirboatGunHeavyTracer" }
			TracerType["Options"]["#Laser"]				= { wire_turret_tracer = "LaserTracer" }

		--Turret Models
		local TurretModels = {
		["models/weapons/w_smg1.mdl"] = {},
		["models/weapons/w_smg_mp5.mdl"] = {},
		["models/weapons/w_smg_mac10.mdl"] = {},
		["models/weapons/w_rif_m4a1.mdl"] = {},
		["models/weapons/w_357.mdl"] = {},
		["models/weapons/w_shot_m3super90.mdl"] = {}
		}

		CPanel:AddControl( "PropSelect", { Label = "#Select Model",
										 ConVar = "wire_turret_model",
										 Category = "Wire Turrets",
										 Models = TurretModels } )

		CPanel:AddControl("ComboBox", TracerType )

		-- Various controls that you should play with!
		if game.SinglePlayer() then
			CPanel:NumSlider("#Tool_wire_turret_numbullets", "wire_turret_numbullets", 1, 10, 0)
		end
		CPanel:NumSlider("#Damage", "wire_turret_damage", 0, 100, 0)
		CPanel:NumSlider("#Tool_wire_turret_spread", "wire_turret_spread", 0, 1.0, 2)
		CPanel:NumSlider("#Tool_wire_turret_force", "wire_turret_force", 0, 500, 1)

		-- The delay between shots.
		if game.SinglePlayer() then
			CPanel:NumSlider("#Delay", "wire_turret_delay", 0.01, 1.0, 2)
			CPanel:NumSlider("#Tool_wire_turret_tracernum", "wire_turret_tracernum", 0, 15, 0)
		else
			CPanel:NumSlider("#Delay", "wire_turret_delay", 0.05, 1.0, 2)
		end

	end

end --wire_turret


do --wire_forcer
	WireToolSetup.open( "forcer", "Forcer", "gmod_wire_forcer", WireToolMakeForcer )

	if CLIENT then
		language.Add( "tool.wire_forcer.name", "Forcer Tool (Wire)" )
		language.Add( "tool.wire_forcer.desc", "Spawns a forcer prop for use with the wire system." )
		language.Add( "tool.wire_forcer.0", "Primary: Create/Update Forcer" )
		language.Add( "sboxlimit_wire_forcers", "You've hit forcers limit!" )
	end
	WireToolSetup.BaseLang("Forcers")

	if SERVER then
		CreateConVar('sbox_maxwire_forcers', 20)
	end

	TOOL.ClientConVar = {
		multiplier	= 1,
		length		= 100,
		beam		= 1,
		reaction	= 0,
		model		= "models/jaanus/wiretool/wiretool_siren.mdl"
	}

	local forcermodels = {
		["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
		["models/jaanus/wiretool/wiretool_siren.mdl"] = {}
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_forcer")
		WireDermaExts.ModelSelect(panel, "wire_forcer_Model", forcermodels, 1, true)
		panel:NumSlider("Force multiplier", "wire_forcer_multiplier", 1, 10000, 0)
		panel:NumSlider("Force distance", "wire_forcer_length", 1, 10000, 0)
		panel:CheckBox("Show beam", "wire_forcer_beam")
		panel:CheckBox("Apply reaction force", "wire_forcer_reaction")
	end
end --wire_forcer


do --wire_detonator
	WireToolSetup.open( "detonator", "Detonator", "gmod_wire_detonator", WireToolMakeDetonator )

	if CLIENT then
		language.Add( "tool.wire_detonator.name", "Detonator Tool (Wire)" )
		language.Add( "tool.wire_detonator.desc", "Spawns a Detonator for use with the wire system." )
		language.Add( "tool.wire_detonator.0", "Primary: Create/Update Detonator" )
		language.Add( "sboxlimit_wire_detonators", "You've hit Detonators limit!" )
	end
	WireToolSetup.BaseLang("Detonators")

	if SERVER then
		CreateConVar('sbox_maxwire_detonators', 20)
		ModelPlug_Register("detonator")
	end

	TOOL.ClientConVar = {
		damage = 1,
		model = "models/props_combine/breenclock.mdl"
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_detonator")
		panel:NumSlider("#Damage", "wire_detonator_damage", 1, 200, 0)
		ModelPlug_AddToCPanel(panel, "detonator", "wire_detonator", nil, nil, true, 1)
	end
end --wire_detonator


do --wire_grabber
	WireToolSetup.open( "grabber", "Grabber", "gmod_wire_grabber", WireToolMakeGrabber )

	if CLIENT then
		language.Add( "tool.wire_grabber.name", "Grabber Tool (Wire)" )
		language.Add( "tool.wire_grabber.desc", "Spawns a constant grabber prop for use with the wire system." )
		language.Add( "tool.wire_grabber.0", "Primary: Create/Update Grabber Secondary: link the grabber to its extra prop that is attached for stabilty" )
		language.Add( "WireGrabberTool_Range", "Max Range:" )
		language.Add( "WireGrabberTool_Gravity", "Disable Gravity" )
		language.Add( "sboxlimit_wire_grabbers", "You've hit grabbers limit!" )
	end
	WireToolSetup.BaseLang("Grabbers")

	if SERVER then
		CreateConVar('sbox_maxwire_grabbers', 20)
		CreateConVar('sbox_wire_grabbers_onlyOwnersProps', 1)
	end

	TOOL.ClientConVar = {
		model	= "models/jaanus/wiretool/wiretool_range.mdl",
		Range	= 100,
		Gravity	= 1,
	}

	local grabbermodels = {
		["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
		["models/jaanus/wiretool/wiretool_range.mdl"] = {}
	}

	function TOOL:GetGhostMin( min )
		if self:GetClientInfo("model") == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
			return min.z + 20
		end
		return min.z
	end

	function TOOL:RightClick( trace )
		if not trace.HitPos then return false end
		if CLIENT then return true end
		if not trace.Entity or not trace.Entity:IsValid() then return false end
		if self.Oldent then
			self.Oldent.ExtraProp = trace.Entity
			self.Oldent = nil
			return true
		else
			if trace.Entity:GetClass() == "gmod_wire_grabber" then
				self.Oldent = trace.Entity
				return true
			end
		end
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_grabber")
		WireDermaExts.ModelSelect(panel, "wire_grabber_Model", grabbermodels, 1, true)
		panel:CheckBox("#WireGrabberTool_Gravity", "wire_grabber_Gravity")
		panel:NumSlider("#WireGrabberTool_Range", "wire_grabber_Range", 1, 10000, 0)
	end
end --wire_grabber


do --wire_hoverball
	WireToolSetup.open( "hoverball", "Hoverball", "gmod_wire_hoverball", WireToolMakeHoverball )

	if CLIENT then
		language.Add( "tool.wire_hoverball.name", "Wired Hoverball Tool" )
		language.Add( "tool.wire_hoverball.desc", "Spawns a hoverball for use with the wire system." )
		language.Add( "tool.wire_hoverball.0", "Primary: Create/Update Hoverball" )
		language.Add( "WireHoverballTool_starton", "Create with hover mode on" )
		language.Add( "sboxlimit_wire_hoverballs", "You've hit wired hover balls limit!" )
	end
	WireToolSetup.BaseLang("Hoverballs")

	if SERVER then
		CreateConVar('sbox_maxwire_hoverballs', 30)
	end

	TOOL.ClientConVar = {
		speed		= 1,
		resistance	= 0,
		strength	= 1,
		starton		= 1,
	}

	TOOL.Model		= "models/dav0r/hoverball.mdl"

	function TOOL:GetGhostMin( min, trace )
		if trace.Entity:IsWorld() then
			return -8
		end
		return 0
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_hoverball")
		panel:NumSlider("#Movement Speed", "wire_hoverball_speed", 1, 10, 0)
		panel:NumSlider("#Air Resistance", "wire_hoverball_resistance", 1, 10, 0)
		panel:NumSlider("#Strength", "wire_hoverball_strength", .1, 10, 2)
		panel:CheckBox("#WireHoverballTool_starton", "wire_hoverball_starton")
	end
end --wire_hoverball


do --wire_igniter
	WireToolSetup.open( "igniter", "Igniter", "gmod_wire_igniter", WireToolMakeIgniter )

	if CLIENT then
		language.Add( "tool.wire_igniter.name", "Igniter Tool (Wire)" )
		language.Add( "tool.wire_igniter.desc", "Spawns a constant igniter prop for use with the wire system." )
		language.Add( "tool.wire_igniter.0", "Primary: Create/Update Igniter" )
		language.Add( "WireIgniterTool_trgply", "Allow Player Igniting" )
		language.Add( "WireIgniterTool_Range", "Max Range:" )
		language.Add( "sboxlimit_wire_igniters", "You've hit igniters limit!" )
	end
	WireToolSetup.BaseLang("Igniters")

	if SERVER then
		CreateConVar('sbox_maxwire_igniters', 20)
		CreateConVar('sbox_wire_igniters_maxlen', 30)
		CreateConVar('sbox_wire_igniters_allowtrgply',1)
	end

	TOOL.ClientConVar = {
		trgply	= 0,
		Range	= 2048,
		model	= "models/jaanus/wiretool/wiretool_siren.mdl",
	}

	local ignitermodels = {
		["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
		["models/jaanus/wiretool/wiretool_siren.mdl"] = {}
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_igniter")
		WireDermaExts.ModelSelect(panel, "wire_igniter_Model", ignitermodels, 1, true)
		panel:CheckBox("#WireIgniterTool_trgply", "wire_igniter_trgply")
		panel:NumSlider("#WireIgniterTool_Range", "wire_igniter_Range", 1, 10000, 0)
	end
end --wire_igniter


do --wire_trail
	WireToolSetup.open( "trail", "Trail", "gmod_wire_trail", WireToolMakeTrail )

	if CLIENT then
		language.Add( "tool.wire_trail.name", "Trail Tool (Wire)" )
		language.Add( "tool.wire_trail.desc", "Spawns a wired trail." )
		language.Add( "tool.wire_trail.0", "Primary: Create/Update trail" )
		language.Add( "WireTrailTool_trail", "Trail:" )
		language.Add( "WireTrailTool_mat", "Material:" )
		language.Add( "sboxlimit_wire_trails", "You've hit trails limit!" )
	end
	WireToolSetup.BaseLang("Trails")

	if SERVER then
		CreateConVar('sbox_maxwire_trails', 20)
	end

	TOOL.ClientConVar = {
		material = ""
	}

	TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_trail")
		panel:AddControl( "MatSelect", { Height = "2", Label = "#WireTrailTool_mat", ConVar = "wire_trail_material", Options = list.Get( "trail_materials" ), ItemWidth = 64, ItemHeight = 64 } )
	end
end --wire_trail


do --wire_thruster
	WireToolSetup.open( "thruster", "Thruster", "gmod_wire_thruster", WireToolMakeThruster, "Thrusters" )

	if CLIENT then
		language.Add( "tool.wire_thruster.name", "Thruster Tool (Wire)" )
		language.Add( "tool.wire_thruster.desc", "Spawns a thruster for use with the wire system." )
		language.Add( "tool.wire_thruster.0", "Primary: Create/Update Thruster" )
		language.Add( "WireThrusterTool_Model", "Model:" )
		language.Add( "WireThrusterTool_force", "Force multiplier:" )
		language.Add( "WireThrusterTool_force_min", "Force minimum:" )
		language.Add( "WireThrusterTool_force_max", "Force maximum:" )
		language.Add( "WireThrusterTool_bidir", "Bi-directional" )
		language.Add( "WireThrusterTool_collision", "Collision" )
		language.Add( "WireThrusterTool_soundname", "Select sound" )
		language.Add( "WireThrusterTool_owater", "Works out of water" )
		language.Add( "WireThrusterTool_uwater", "Works under water" )
	end
	WireToolSetup.BaseLang("Thrusters")
	WireToolSetup.SetupMax( 10, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

	TOOL.ClientConVar = {
		force		= 1500,
		force_min	= 0,
		force_max	= 10000,
		model		= "models/props_c17/lampShade001a.mdl",
		bidir		= 1,
		collision	= 0,
		soundname 	= "",
		oweffect	= "fire",
		uweffect	= "same",
		owater		= 1,
		uwater		= 1,
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_thruster")

		WireDermaExts.ModelSelect(panel, "wire_thruster_model", list.Get( "ThrusterModels" ), 4, true)

		local Effects = {
			["#No Effects"] = "none",
			//["#Same as over water"] = "same",
			["#Flames"] = "fire",
			["#Plasma"] = "plasma",
			["#Smoke"] = "smoke",
			["#Smoke Random"] = "smoke_random",
			["#Smoke Do it Youself"] = "smoke_diy",
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
			["#Jetflame Blue"] = "jetflame_blue",
			["#Jetflame Red"] = "jetflame_red",
			["#Jetflame Purple"] = "jetflame_purple",
			["#Comic Balls"] = "balls",
			["#Comic Balls Random"] = "balls_random",
			["#Comic Balls Fire Colors"] = "balls_firecolors",
			["#Souls"] = "souls",
			//["#Debugger 10 Seconds"] = "debug_10", These are just buggy and shouldn't be used.
			//["#Debugger 30 Seconds"] = "debug_30",
			//["#Debugger 60 Seconds"] = "debug_60",
			["#Fire and Smoke"] = "fire_smoke",
			["#Fire and Smoke Huge"] = "fire_smoke_big",
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
		panel:NumSlider("#WireThrusterTool_force_min", "wire_thruster_force_min", -10000, 10000, 0)
		panel:NumSlider("#WireThrusterTool_force_max", "wire_thruster_force_max", -10000, 10000, 0)
		panel:CheckBox("#WireThrusterTool_bidir", "wire_thruster_bidir")
		panel:CheckBox("#WireThrusterTool_collision", "wire_thruster_collision")
		panel:CheckBox("#WireThrusterTool_owater", "wire_thruster_owater")
		panel:CheckBox("#WireThrusterTool_uwater", "wire_thruster_uwater")
	end
	--from model pack 1
	list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
end --wire_thruster
