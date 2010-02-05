AddCSLuaFile( "physics.lua" )
WireToolSetup.setCategory( "Physics" )

do --wire_weight
	WireToolSetup.open( "weight", "Weight", "gmod_wire_weight", WireToolMakeWeight )

	if CLIENT then
		language.Add( "Tool_wire_weight_name", "Weight Tool (Wire)" )
		language.Add( "Tool_wire_weight_desc", "Spawns a weight." )
		language.Add( "Tool_wire_weight_0", "Primary: Create/Update weight" )
		language.Add( "WireDataWeightTool_weight", "Weight:" )
		language.Add( "sboxlimit_wire_weights", "You've hit weights limit!" )
	end
	WireToolSetup.BaseLang("Weights")

	if SERVER then
		CreateConVar('sbox_maxwire_weights', 20)
		ModelPlug_Register("weight")
	end

	TOOL.ClientConVar = {model	= "models/props_interiors/pot01a.mdl"}

	function TOOL.BuildCPanel(panel)
		ModelPlug_AddToCPanel(panel, "weight", "wire_weight", nil, nil, nil, 1)
	end
end --wire_weight


do --wire_simple_explosive
	WireToolSetup.open( "simple_explosive", "Explosives (Simple)", "gmod_wire_simple_explosive", WireToolMakeExplosivesSimple )
	TOOL.ConfigName = nil -- eeeeeewwwwwwwwwwwwww D:

	if CLIENT then
		language.Add( "Tool_wire_simple_explosive_name", "Simple Wired Explosives Tool" )
		language.Add( "Tool_wire_simple_explosive_desc", "Creates a simple explosives for wire system." )
		language.Add( "Tool_wire_simple_explosive_0", "Left click to place the bomb. Right click update." )
		language.Add( "WireSimpleExplosiveTool_Model", "Model:" )
		language.Add( "WireSimpleExplosiveTool_modelman", "Manual model selection:" )
		language.Add( "WireSimpleExplosiveTool_usemodelman", "Use manual model selection:" )
		language.Add( "WireSimpleExplosiveTool_tirgger", "Trigger value:" )
		language.Add( "WireSimpleExplosiveTool_damage", "Damage:" )
		language.Add( "WireSimpleExplosiveTool_remove", "Remove on explosion" )
		language.Add( "WireSimpleExplosiveTool_doblastdamage", "Do blast damage" )
		language.Add( "WireSimpleExplosiveTool_radius", "Blast radius:" )
		language.Add( "WireSimpleExplosiveTool_freeze", "Freeze" )
		language.Add( "WireSimpleExplosiveTool_weld", "Weld" )
		language.Add( "WireSimpleExplosiveTool_noparentremove", "Don't remove on parent remove" )
		language.Add( "WireSimpleExplosiveTool_nocollide", "No collide all but world" )
		language.Add( "WireSimpleExplosiveTool_weight", "Weight:" )
		language.Add( "sboxlimit_wire_simple_explosive", "You've hit wired explosives limit!" )
	end
	WireToolSetup.BaseLang("SimpleExplosives")

	if SERVER then
		CreateConVar('sbox_maxwire_simple_explosive', 30)
	end

	TOOL.ClientConVar = {
		model = "models/props_c17/oildrum001_explosive.mdl",
		modelman = "",
		tirgger = 1,		-- Current tirgger
		damage = 200,		-- Damage to inflict
		doblastdamage = 1,
		radius = 300,
		removeafter = 0,
		freeze = 0,
		weld = 1,
		weight = 400,
		nocollide = 0,
		noparentremove = 0,
	}

	function TOOL:GetSelModel( showerr )
		local model = self:GetClientInfo( "model" )

		if (model == "usemanmodel") then
			local _modelman = self:GetClientInfo( "modelman" )
			if (_modelman && string.len(_modelman) > 0) then
				model = _modelman
			else
				local message = "You need to define a model."
				if (showerr) then
					self:GetOwner():PrintMessage(3, message)
					self:GetOwner():PrintMessage(2, message)
				end
				return false
			end
		elseif (model == "usereloadmodel") then
			if (self.reloadmodel && string.len(self.reloadmodel) > 0) then
				model = self.reloadmodel
			else
				local message = "You need to select a model model."
				if (showerr) then
					self:GetOwner():PrintMessage(3, message)
					self:GetOwner():PrintMessage(2, message)
				end
				return false
			end
		end

		if (not util.IsValidModel(model)) then
			--something fucked up, notify user of that
			local message = "This is not a valid model."..model
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
		if (not util.IsValidProp(model)) then return false end

		return model
	end

	function TOOL:RightClick( trace )
		local ply = self:GetOwner()
		--shot an explosive, update it instead
		if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_simple_explosive" && trace.Entity.pl == ply ) then
			local _trigger			= self:GetClientNumber( "tirgger" )
			local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
			local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
			local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
			local _radius			= math.Clamp( self:GetClientNumber( "radius" ), 0, 10000 )
			local _weld				= self:GetClientNumber( "weld" ) == 1
			local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
			local _weight			= math.Max(self:GetClientNumber( "weight" ), 1)

			trace.Entity:Setup( _damage, _delaytime, _removeafter, _doblastdamage, _radius, _nocollide )

			local ttable = {
				nocollide = _nocollide,
				key = _trigger,
				damage = _damage,
				removeafter = _removeafter,
				doblastdamage = _doblastdamage,
				radius = _radius
			}
			table.Merge( trace.Entity:GetTable(), ttable )

			trace.Entity:GetPhysicsObject():SetMass(_weight)
			duplicator.StoreEntityModifier( trace.Entity, "MassMod", {Mass = _weight} )

			return true
		end

	end

	function TOOL:Reload( trace )
		--get the model of what was shot and set our reloadmodel to that
		--model info getting code mostly copied from OverloadUT's What Is That? STool
		if !trace.Entity then return false end
		local ent = trace.Entity
		local ply = self:GetOwner()
		local class = ent:GetClass()
		if class == "worldspawn" then
			return false
		else
			local model = ent:GetModel()
			local message = "Model selected: "..model
			self.reloadmodel = model
			ply:PrintMessage(3, message)
			ply:PrintMessage(2, message)
		end
		return true
	end
end --wire_simple_explosive


do --wire_wheel
	WireToolSetup.open( "wheel", "Wheel", "gmod_wire_wheel", WireToolMakeWheel )

	if CLIENT then
		language.Add( "Tool_wire_wheel_name", "Wheel Tool (wire)" )
		language.Add( "Tool_wire_wheel_desc", "Attaches a wheel to something." )
		language.Add( "Tool_wire_wheel_0", "Click on a prop to attach a wheel." )

		language.Add( "WireWheelTool_group", "Input value to go forward:" )
		language.Add( "WireWheelTool_group_reverse", "Input value to go in reverse:" )
		language.Add( "WireWheelTool_group_stop", "Input value for no acceleration:" )
		language.Add( "WireWheelTool_group_desc", "All these values need to be different." )

		language.Add( "undone_WireWheel", "Undone Wire Wheel" )
		language.Add( "Cleanup_wire_wheels", "Wired Wheels" )
		language.Add( "Cleaned_wire_wheels", "Cleaned up all Wired Wheels" )
		language.Add( "SBoxLimit_wire_wheels", "You've reached the wired wheels limit!" )
	end
	WireToolSetup.BaseLang("Wheels")

	if SERVER then
		CreateConVar('sbox_maxwire_wheels', 30)
	end

	TOOL.ClientConVar = {
		torque 		= 3000,
		friction 	= 1,
		nocollide 	= 1,
		forcelimit 	= 0,
		fwd			= 1,	-- Forward
		bck			= -1,	-- Back
		stop 		= 0,	-- Stop
	}

	--[[---------------------------------------------------------
	   Apply new values to the wheel
	---------------------------------------------------------]]
	function TOOL:RightClick( trace )
		if trace.Entity and trace.Entity:GetClass() ~= "gmod_wire_wheel" then return false end

		if CLIENT then return true end

		local wheelEnt = trace.Entity

		-- Only change your own wheels...
		if wheelEnt:GetPlayer():IsValid() and
			 wheelEnt:GetPlayer() != self:GetOwner() then
			 return false
		end

		-- Get client's CVars
		local torque		= self:GetClientNumber( "torque" )
		local toggle		= self:GetClientNumber( "toggle" ) != 0
		local fwd			= self:GetClientNumber( "fwd" )
		local bck			= self:GetClientNumber( "bck" )
		local stop			= self:GetClientNumber( "stop" )

		wheelEnt:SetTorque( torque )
		wheelEnt:SetFwd( fwd )
		wheelEnt:SetBck( bck )
		wheelEnt:SetStop( stop )
		wheelEnt:UpdateOverlayText()

		return true
	end

	function TOOL:UpdateGhostWireWheel( ent, player )
		if not (ent and ent:IsValid()) then return end

		local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
		local trace = util.TraceLine( tr )
		if not trace.Hit then return end

		if trace.Entity:IsPlayer() then
			ent:SetNoDraw( true )
			return
		end

		local Ang = trace.HitNormal:Angle() + self.wheelAngle
		local CurPos = ent:GetPos()
		local NearestPoint = ent:NearestPoint( CurPos - (trace.HitNormal * 512) )
		local WheelOffset = CurPos - NearestPoint

		local min = ent:OBBMins()
		ent:SetPos( trace.HitPos + trace.HitNormal + WheelOffset )
		ent:SetAngles( Ang )
		ent:SetNoDraw( false )
	end

	--[[---------------------------------------------------------
	   Maintains the ghost wheel
	---------------------------------------------------------]]
	function TOOL:Think()

		if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetOwner():GetInfo( "wheel_model" )) then
			self.wheelAngle = Angle( tonumber(self:GetOwner():GetInfo( "wheel_rx" )), tonumber(self:GetOwner():GetInfo( "wheel_ry" )), tonumber(self:GetOwner():GetInfo( "wheel_rz" )) )
			self:MakeGhostEntity( self:GetOwner():GetInfo( "wheel_model" ), Vector(0,0,0), Angle(0,0,0) )
		end

		self:UpdateGhostWireWheel( self.GhostEntity, self:GetOwner() )

	end


	function TOOL.BuildCPanel( panel )
		-- HEADER
		panel:AddControl( "Header", { Text = "#Tool_wire_wheel_name", Description	= "#Tool_wire_wheel_desc" }  )

		local Options = { Default = {	wire_wheel_torque		= "3000",
										wire_wheel_friction		= "0",
										wire_wheel_nocollide	= "1",
										wire_wheel_forcelimit	= "0",
										wire_wheel_fwd			= "1",
										wire_wheel_bck			= "-1",
										wire_wheel_stop			= "0", } }

		local CVars = { "wire_wheel_torque", "wire_wheel_friction", "wire_wheel_nocollide", "wire_wheel_forcelimit", "wire_wheel_fwd", "wire_wheel_bck", "wire_wheel_stop" }

		panel:AddControl( "ComboBox", { Label = "#Presets",
										 MenuButton = 1,
										 Folder = "wire_wheel",
										 Options = Options,
										 CVars = CVars } )

		panel:AddControl( "Slider", { Label = "#WireWheelTool_group",
										 Description = "#WireWheelTool_group_desc",
										 Type = "Float",
										 Min = -10,
										 Max = 10,
										 Command = "wire_wheel_fwd" } )

		panel:AddControl( "Slider", { Label = "#WireWheelTool_group_stop",
										 Description = "#WireWheelTool_group_desc",
										 Type = "Float",
										 Min = -10,
										 Max = 10,
										 Command = "wire_wheel_stop" } )

		panel:AddControl( "Slider", { Label = "#WireWheelTool_group_reverse",
										 Description = "#WireWheelTool_group_desc",
										 Type = "Float",
										 Min = -10,
										 Max = 10,
										 Command = "wire_wheel_bck" } )

		panel:AddControl( "PropSelect", { Label = "#WheelTool_model",
										 ConVar = "wheel_model",
										 Category = "Wheels",
										 Models = list.Get( "WheelModels" ) } )

		panel:AddControl( "Slider", { Label = "#WheelTool_torque",
										 Description = "#WheelTool_torque_desc",
										 Type = "Float",
										 Min = 10,
										 Max = 10000,
										 Command = "wire_wheel_torque" } )


		panel:AddControl( "Slider", { Label = "#WheelTool_forcelimit",
										 Description = "#WheelTool_forcelimit_desc",
										 Type = "Float",
										 Min = 0,
										 Max = 50000,
										 Command = "wire_wheel_forcelimit" } )

		panel:AddControl( "Slider", { Label = "#WheelTool_friction",
										 Description = "#WheelTool_friction_desc",
										 Type = "Float",
										 Min = 0,
										 Max = 100,
										 Command = "wire_wheel_friction" } )

		panel:AddControl( "CheckBox", { Label = "#WheelTool_nocollide",
										 Description = "#WheelTool_nocollide_desc",
										 Command = "wire_wheel_nocollide" } )

		--[[ This is the stuff that broke the wheels. I hope TAD2020 can fix it some time...
		WireToolHelpers.MakePresetControl(panel, "wire_wheel")
		panel:NumSlider("#WireWheelTool_group", "wire_wheel_fwd", -10, 10, 1)
		panel:NumSlider("#WireWheelTool_group_stop", "wire_wheel_stop", -10, 10, 1)
		panel:NumSlider("#WireWheelTool_group_reverse", "wire_wheel_bck", -10, 10, 1)
		WireDermaExts.ModelSelect(panel, "wheel_model", list.Get( "WheelModels" ), 3, true)
		panel:NumSlider("#WheelTool_torque", "wire_wheel_torque", 10, 10000, 0)
		panel:NumSlider("#WheelTool_forcelimit", "wire_wheel_forcelimit", 0, 50000, 0)
		panel:NumSlider("#WheelTool_friction", "wire_wheel_friction", 0, 100, 1)
		panel:CheckBox("#WheelTool_nocollide", "wire_wheel_nocollide")
		]]
	end

end --wire_wheel


do --wire_turret
	WireToolSetup.open( "turret", "Turret", "gmod_wire_turret", nil )

	-- Precache these sounds..
	Sound( "ambient.electrical_zap_3" )
	Sound( "NPC_FloorTurret.Shoot" )

	-- Add Default Language translation (saves adding it to the txt files)
	if CLIENT then
		language.Add( "Tool_wire_turret_name", "Turret" )
		language.Add( "Tool_wire_turret_desc", "Throws bullets at things" )
		language.Add( "Tool_wire_turret_0", "Click somewhere to spawn an turret. Click on an existing turret to change it." )

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

		-- We shot an existing turret - just change its values
		if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_turret" and trace.Entity.pl == ply then
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
		if SinglePlayer() then
			CPanel:NumSlider("#Tool_wire_turret_numbullets", "wire_turret_numbullets", 1, 10, 0)
		end
		CPanel:NumSlider("#Damage", "wire_turret_damage", 0, 100, 0)
		CPanel:NumSlider("#Tool_wire_turret_spread", "wire_turret_spread", 0, 1.0, 2)
		CPanel:NumSlider("#Tool_wire_turret_force", "wire_turret_force", 0, 500, 1)

		-- The delay between shots.
		if SinglePlayer() then
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
		language.Add( "Tool_wire_forcer_name", "Forcer Tool (Wire)" )
		language.Add( "Tool_wire_forcer_desc", "Spawns a forcer prop for use with the wire system." )
		language.Add( "Tool_wire_forcer_0", "Primary: Create/Update Forcer" )
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
		language.Add( "Tool_wire_detonator_name", "Detonator Tool (Wire)" )
		language.Add( "Tool_wire_detonator_desc", "Spawns a Detonator for use with the wire system." )
		language.Add( "Tool_wire_detonator_0", "Primary: Create/Update Detonator" )
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
		language.Add( "Tool_wire_grabber_name", "Grabber Tool (Wire)" )
		language.Add( "Tool_wire_grabber_desc", "Spawns a constant grabber prop for use with the wire system." )
		language.Add( "Tool_wire_grabber_0", "Primary: Create/Update Grabber Secondary: link the grabber to its extra prop that is attached for stabilty" )
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
		language.Add( "Tool_wire_hoverball_name", "Wired Hoverball Tool" )
		language.Add( "Tool_wire_hoverball_desc", "Spawns a hoverball for use with the wire system." )
		language.Add( "Tool_wire_hoverball_0", "Primary: Create/Update Hoverball" )
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
		language.Add( "Tool_wire_igniter_name", "Igniter Tool (Wire)" )
		language.Add( "Tool_wire_igniter_desc", "Spawns a constant igniter prop for use with the wire system." )
		language.Add( "Tool_wire_igniter_0", "Primary: Create/Update Igniter" )
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
		language.Add( "Tool_wire_trail_name", "Trail Tool (Wire)" )
		language.Add( "Tool_wire_trail_desc", "Spawns a wired trail." )
		language.Add( "Tool_wire_trail_0", "Primary: Create/Update trail" )
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
	WireToolSetup.open( "thruster", "Thruster", "gmod_wire_thruster", WireToolMakeThruster )

	if CLIENT then
		language.Add( "Tool_wire_thruster_name", "Thruster Tool (Wire)" )
		language.Add( "Tool_wire_thruster_desc", "Spawns a thruster for use with the wire system." )
		language.Add( "Tool_wire_thruster_0", "Primary: Create/Update Thruster" )
		language.Add( "WireThrusterTool_Model", "Model:" )
		language.Add( "WireThrusterTool_OWEffects", "Over water effects:" )
		language.Add( "WireThrusterTool_UWEffects", "Under water effects:" )
		language.Add( "WireThrusterTool_force", "Force multiplier:" )
		language.Add( "WireThrusterTool_force_min", "Force minimum:" )
		language.Add( "WireThrusterTool_force_max", "Force maximum:" )
		language.Add( "WireThrusterTool_bidir", "Bi-directional" )
		language.Add( "WireThrusterTool_collision", "Collision" )
		language.Add( "WireThrusterTool_sound", "Enable sound" )
		language.Add( "WireThrusterTool_owater", "Works out of water" )
		language.Add( "WireThrusterTool_uwater", "Works under water" )
		language.Add( "sboxlimit_wire_thrusters", "You've hit thrusters limit!" )
		language.Add( "undone_wirethruster", "Undone Wire Thruster" )
	end
	WireToolSetup.BaseLang("Thrusters")

	if SERVER then
		CreateConVar('sbox_maxwire_thrusters', 10)
	end

	TOOL.ClientConVar = {
		force		= 1500,
		force_min	= 0,
		force_max	= 10000,
		model		= "models/props_c17/lampShade001a.mdl",
		bidir		= 1,
		collision	= 0,
		sound		= 0,
		oweffect	= "fire",
		uweffect	= "same",
		owater		= 1,
		uwater		= 1,
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_thruster")

		WireDermaExts.ModelSelect(panel, "wire_thruster_model", list.Get( "ThrusterModels" ), 4, true)

		panel:AddControl("ComboBox", {
			Label = "#WireThrusterTool_OWEffects",
			MenuButton = "0",

			Options = {
				["#No_Effects"] = { wire_thruster_oweffect = "none" },
				["#Flames"] = { wire_thruster_oweffect = "fire" },
				["#Plasma"] = { wire_thruster_oweffect = "plasma" },
				["#Smoke"] = { wire_thruster_oweffect = "smoke" },
				["#Smoke Random"] = { wire_thruster_oweffect = "smoke_random" },
				["#Smoke Do it Youself"] = { wire_thruster_oweffect = "smoke_diy" },
				["#Rings"] = { wire_thruster_oweffect = "rings" },
				["#Rings Growing"] = { wire_thruster_oweffect = "rings_grow" },
				["#Rings Shrinking"] = { wire_thruster_oweffect = "rings_shrink" },
				["#Bubbles"] = { wire_thruster_oweffect = "bubble" },
				["#Magic"] = { wire_thruster_oweffect = "magic" },
				["#Magic Random"] = { wire_thruster_oweffect = "magic_color" },
				["#Magic Do It Yourself"] = { wire_thruster_oweffect = "magic_diy" },
				["#Colors"] = { wire_thruster_oweffect = "color" },
				["#Colors Random"] = { wire_thruster_oweffect = "color_random" },
				["#Colors Do It Yourself"] = { wire_thruster_oweffect = "color_diy" },
				["#Blood"] = { wire_thruster_oweffect = "blood" },
				["#Money"] = { wire_thruster_oweffect = "money" },
				["#Sperms"] = { wire_thruster_oweffect = "sperm" },
				["#Feathers"] = { wire_thruster_oweffect = "feather" },
				["#Candy Cane"] = { wire_thruster_oweffect = "candy_cane" },
				["#Goldstar"] = { wire_thruster_oweffect = "goldstar" },
				["#Water Small"] = { wire_thruster_oweffect = "water_small" },
				["#Water Medium"] = { wire_thruster_oweffect = "water_medium" },
				["#Water Big"] = { wire_thruster_oweffect = "water_big" },
				["#Water Huge"] = { wire_thruster_oweffect = "water_huge" },
				["#Striderblood Small"] = { wire_thruster_oweffect = "striderblood_small" },
				["#Striderblood Medium"] = { wire_thruster_oweffect = "striderblood_medium" },
				["#Striderblood Big"] = { wire_thruster_oweffect = "striderblood_big" },
				["#Striderblood Huge"] = { wire_thruster_oweffect = "striderblood_huge" },
				["#More Sparks"] = { wire_thruster_oweffect = "more_sparks" },
				["#Spark Fountain"] = { wire_thruster_oweffect = "spark_fountain" },
				["#Jetflame"] = { wire_thruster_oweffect = "jetflame" },
				["#Jetflame Advanced"] = { wire_thruster_oweffect = "jetflame_advanced" },
				["#Jetflame Blue"] = { wire_thruster_oweffect = "jetflame_blue" },
				["#Jetflame Red"] = { wire_thruster_oweffect = "jetflame_red" },
				["#Jetflame Purple"] = { wire_thruster_oweffect = "jetflame_purple" },
				["#Comic Balls"] = { wire_thruster_oweffect = "balls" },
				["#Comic Balls Random"] = { wire_thruster_oweffect = "balls_random" },
				["#Comic Balls Fire Colors"] = { wire_thruster_oweffect = "balls_firecolors" },
				["#Souls"] = { wire_thruster_oweffect = "souls" },
				["#Debugger 10 Seconds"] = { wire_thruster_oweffect = "debug_10" },
				["#Debugger 30 Seconds"] = { wire_thruster_oweffect = "debug_30" },
				["#Debugger 60 Seconds"] = { wire_thruster_oweffect = "debug_60" },
				["#Fire and Smoke"] = { wire_thruster_oweffect = "fire_smoke" },
				["#Fire and Smoke Huge"] = { wire_thruster_oweffect = "fire_smoke_big" },
				["#5 Growing Rings"] = { wire_thruster_oweffect = "rings_grow_rings" },
				["#Color and Magic"] = { wire_thruster_oweffect = "color_magic" },
			}
		})

		panel:AddControl("ComboBox", {
			Label = "#WireThrusterTool_UWEffects",
			MenuButton = "0",

			Options = {
				["#No_Effects"] = { wire_thruster_uweffect = "none" },
				["#Same as over water"] = { wire_thruster_uweffect = "same" },
				["#Flames"] = { wire_thruster_uweffect = "fire" },
				["#Plasma"] = { wire_thruster_uweffect = "plasma" },
				["#Smoke"] = { wire_thruster_uweffect = "smoke" },
				["#Smoke Random"] = { wire_thruster_uweffect = "smoke_random" },
				["#Smoke Do it Youself"] = { wire_thruster_uweffect = "smoke_diy" },
				["#Rings"] = { wire_thruster_uweffect = "rings" },
				["#Rings Growing"] = { wire_thruster_uweffect = "rings_grow" },
				["#Rings Shrinking"] = { wire_thruster_uweffect = "rings_shrink" },
				["#Bubbles"] = { wire_thruster_uweffect = "bubble" },
				["#Magic"] = { wire_thruster_uweffect = "magic" },
				["#Magic Random"] = { wire_thruster_uweffect = "magic_color" },
				["#Magic Do It Yourself"] = { wire_thruster_uweffect = "magic_diy" },
				["#Colors"] = { wire_thruster_uweffect = "color" },
				["#Colors Random"] = { wire_thruster_uweffect = "color_random" },
				["#Colors Do It Yourself"] = { wire_thruster_uweffect = "color_diy" },
				["#Blood"] = { wire_thruster_uweffect = "blood" },
				["#Money"] = { wire_thruster_uweffect = "money" },
				["#Sperms"] = { wire_thruster_uweffect = "sperm" },
				["#Feathers"] = { wire_thruster_uweffect = "feather" },
				["#Candy Cane"] = { wire_thruster_uweffect = "candy_cane" },
				["#Goldstar"] = { wire_thruster_uweffect = "goldstar" },
				["#Water Small"] = { wire_thruster_uweffect = "water_small" },
				["#Water Medium"] = { wire_thruster_uweffect = "water_medium" },
				["#Water Big"] = { wire_thruster_uweffect = "water_big" },
				["#Water Huge"] = { wire_thruster_uweffect = "water_huge" },
				["#Striderblood Small"] = { wire_thruster_uweffect = "striderblood_small" },
				["#Striderblood Medium"] = { wire_thruster_uweffect = "striderblood_medium" },
				["#Striderblood Big"] = { wire_thruster_uweffect = "striderblood_big" },
				["#Striderblood Huge"] = { wire_thruster_uweffect = "striderblood_huge" },
				["#More Sparks"] = { wire_thruster_uweffect = "more_sparks" },
				["#Spark Fountain"] = { wire_thruster_uweffect = "spark_fountain" },
				["#Jetflame"] = { wire_thruster_uweffect = "jetflame" },
				["#Jetflame Advanced"] = { wire_thruster_uweffect = "jetflame_advanced" },
				["#Jetflame Blue"] = { wire_thruster_uweffect = "jetflame_blue" },
				["#Jetflame Red"] = { wire_thruster_uweffect = "jetflame_red" },
				["#Jetflame Purple"] = { wire_thruster_uweffect = "jetflame_purple" },
				["#Comic Balls"] = { wire_thruster_uweffect = "balls" },
				["#Comic Balls Random"] = { wire_thruster_uweffect = "balls_random" },
				["#Comic Balls Fire Colors"] = { wire_thruster_uweffect = "balls_firecolors" },
				["#Souls"] = { wire_thruster_uweffect = "souls" },
				["#Debugger 10 Seconds"] = { wire_thruster_uweffect = "debug_10" },
				["#Debugger 30 Seconds"] = { wire_thruster_uweffect = "debug_30" },
				["#Debugger 60 Seconds"] = { wire_thruster_uweffect = "debug_60" },
				["#Fire and Smoke"] = { wire_thruster_uweffect = "fire_smoke" },
				["#Fire and Smoke Huge"] = { wire_thruster_uweffect = "fire_smoke_big" },
				["#5 Growing Rings"] = { wire_thruster_uweffect = "rings_grow_rings" },
				["#Color and Magic"] = { wire_thruster_uweffect = "color_magic" },
			}
		})

		panel:NumSlider("#WireThrusterTool_force", "wire_thruster_force", 1, 10000, 0)
		panel:NumSlider("#WireThrusterTool_force_min", "wire_thruster_force_min", -10000, 10000, 0)
		panel:NumSlider("#WireThrusterTool_force_max", "wire_thruster_force_max", -10000, 10000, 0)
		panel:CheckBox("#WireThrusterTool_bidir", "wire_thruster_bidir")
		panel:CheckBox("#WireThrusterTool_collision", "wire_thruster_collision")
		panel:CheckBox("#WireThrusterTool_sound", "wire_thruster_sound")
		panel:CheckBox("#WireThrusterTool_owater", "wire_thruster_owater")
		panel:CheckBox("#WireThrusterTool_uwater", "wire_thruster_uwater")
	end
	--from model pack 1
	list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )
end --wire_thruster
