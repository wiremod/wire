TOOL.Category   = "Wire - Physics"
TOOL.Name       = "Vector Thruster"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if ( CLIENT ) then
	language.Add( "Tool_wire_vthruster_name", "Vector Thruster Tool (Wire)" )
	language.Add( "Tool_wire_vthruster_desc", "Spawns a vector thruster for use with the wire system." )
	language.Add( "Tool_wire_vthruster_0", "Primary: Create/Update Vector Thruster" )
	language.Add( "Tool_wire_vthruster_1", "Primary: Finish" )
	language.Add( "WireVThrusterTool_Mode", "Mode:" )
	language.Add( "WireVThrusterTool_Angle", "Use Yaw/Pitch Inputs Instead" )
	language.Add( "undone_wirevthruster", "Undone Wire Vector Thruster" )
end

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_speed.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "sound" ] = "0"
TOOL.ClientConVar[ "oweffect" ] = "fire"
TOOL.ClientConVar[ "uweffect" ] = "same"
TOOL.ClientConVar[ "owater" ] = "1"
TOOL.ClientConVar[ "uwater" ] = "1"
TOOL.ClientConVar[ "mode" ] = "0"
TOOL.ClientConVar[ "angleinputs" ] = "0"

local degrees = 0

function TOOL:LeftClick( trace )
	local numobj = self:NumObjects()

	local ply = self:GetOwner()

	local force       = self:GetClientNumber( "force" )
	local force_min   = self:GetClientNumber( "force_min" )
	local force_max   = self:GetClientNumber( "force_max" )
	local model       = self:GetClientInfo( "model" )
	local bidir       = self:GetClientNumber( "bidir" ) ~= 0
	local nocollide   = self:GetClientNumber( "collision" ) == 0
	local sound       = self:GetClientNumber( "sound" ) ~= 0
	local oweffect    = self:GetClientInfo( "oweffect" )
	local uweffect    = self:GetClientInfo( "uweffect" )
	local owater      = self:GetClientNumber( "owater" ) ~= 0
	local uwater      = self:GetClientNumber( "uwater" ) ~= 0
	local mode        = self:GetClientNumber( "mode" )
	local angleinputs = self:GetClientNumber( "angleinputs" ) ~= 0

	if (numobj == 0) then
		if trace.Entity && trace.Entity:IsPlayer() then return false end

		// If there's no physics object then we can't constraint it!
		if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

		if (CLIENT) then return true end

		// If we shot a wire_thruster change its force
		if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_vectorthruster" && trace.Entity.pl == ply ) then

			trace.Entity:SetForce( force )
			trace.Entity:SetEffect( effect )
			trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, mode, angleinputs)

			trace.Entity.force       = force
			trace.Entity.force_min   = force_min
			trace.Entity.force_max   = force_max
			trace.Entity.bidir       = bidir
			trace.Entity.sound       = sound
			trace.Entity.oweffect    = oweffect
			trace.Entity.uweffect    = uweffect
			trace.Entity.owater      = owater
			trace.Entity.uwater      = uwater
			trace.Entity.nocollide   = nocollide
			trace.Entity.mode        = mode
			trace.Entity.angleinputs = angleinputs

			if ( nocollide == true ) then trace.Entity:GetPhysicsObject():EnableCollisions( false ) end

			return true
		end

		if ( !self:GetSWEP():CheckLimit( "wire_thrusters" ) ) then return false end

		if (not util.IsValidModel(model)) then return false end
		if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90

		local wire_thruster = MakeWireVectorThruster( ply, trace.HitPos, ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide, mode, angleinputs )

		local min = wire_thruster:OBBMins()
		wire_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )

		undo.Create("WireVThruster")
			undo.AddEntity( wire_thruster )
			undo.SetPlayer( ply )
		undo.Finish()

		local Phys = wire_thruster:GetPhysicsObject()
		Phys:EnableMotion( false )
		Phys:Wake()

		if ( !trace.Entity:IsValid() ) then return true end

		self:ReleaseGhostEntity()

		self:SetObject(1, trace.Entity, trace.HitPos, trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone), trace.PhysicsBone, trace.HitNormal)
		self:SetObject(2, wire_thruster, trace.HitPos, Phys, 0, trace.HitNormal)
		self:SetStage(1)

	else
		if (CLIENT) then return true end

		local anchor, wire_thruster = self:GetEnt(1), self:GetEnt(2)
		local anchorbone = self:GetBone(1)
		local normal = self:GetNormal(1)

		local const = WireLib.Weld(wire_thruster, anchor, trace.PhysicsBone, true, nocollide)

		local Phys = wire_thruster:GetPhysicsObject()
		Phys:EnableMotion( true )

		undo.Create("WireVThruster")
			undo.AddEntity( wire_thruster )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( "wire_thrusters", wire_thruster )
		ply:AddCleanup( "wire_thrusters", const )

		self:ClearObjects()
	end

	return true
end

if (SERVER) then

	function MakeWireVectorThruster( pl, Pos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide, mode, angleinputs)
		print("angleinputs=",angleinputs)
		if ( !pl:CheckLimit( "wire_thrusters" ) ) then return false end
		mode = mode or 0

		local wire_thruster = ents.Create( "gmod_wire_vectorthruster" )
		if (!wire_thruster:IsValid()) then return false end
		wire_thruster:SetModel( model )

		wire_thruster:SetAngles( Ang )
		wire_thruster:SetPos( Pos )
		wire_thruster:Spawn()

		wire_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, mode, angleinputs)
		wire_thruster:SetPlayer( pl )

		if ( nocollide == true ) then wire_thruster:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			force       = force,
			force_min   = force_min,
			force_max   = force_max,
			bidir       = bidir,
			sound       = sound,
			pl          = pl,
			oweffect    = oweffect,
			uweffect    = uweffect,
			owater      = owater,
			uwater      = uwater,
			nocollide   = nocollide,
			mode        = mode,
			angleinputs = angleinputs,
		}
		table.Merge(wire_thruster:GetTable(), ttable )

		pl:AddCount( "wire_thrusters", wire_thruster )

		return wire_thruster
	end
	duplicator.RegisterEntityClass("gmod_wire_vectorthruster", MakeWireVectorThruster, "Pos", "Ang", "Model", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "sound", "nocollide", "mode", "angleinputs")

end

function TOOL:UpdateGhostWireThruster( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_thruster" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	 ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end


function TOOL:Think()

	if (self:NumObjects() > 0) then
		if ( SERVER ) then
			local Phys2 = self:GetPhys(2)
			local Norm2 = self:GetNormal(2)
			local cmd = self:GetOwner():GetCurrentCommand()
			degrees = degrees + cmd:GetMouseX() * 0.05
			local ra = degrees
			if (self:GetOwner():KeyDown(IN_SPEED)) then ra = math.Round(ra/45)*45 end
			local Ang = Norm2:Angle()
			Ang.pitch = Ang.pitch + 90
			Ang:RotateAroundAxis(Norm2, ra)
			Phys2:SetAngle( Ang )
			Phys2:Wake()
		end
	else
		if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
			self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
		end
		self:UpdateGhostWireThruster( self.GhostEntity, self:GetOwner() )
	end

end

if (CLIENT) then
	function TOOL:FreezeMovement()
		return self:GetStage() == 1
	end
end

function TOOL:Holster()
	self:ClearObjects()
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_vthruster_name", Description = "#Tool_wire_vthruster_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_vthruster",

		Options = {
			Default = {
				wire_vthruster_force = "20",
				wire_vthruster_model = "models/jaanus/wiretool/wiretool_speed.mdl",
				wire_vthruster_effect = "fire",
			}
		},

		CVars = {
			[0] = "wire_vthruster_model",
			[1] = "wire_vthruster_force",
			[2] = "wire_vthruster_effect"
		}
	})

	/*panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Spedo"]                  = { wire_vthruster_model = "models/jaanus/wiretool/wiretool_speed.mdl" },
			["#Thruster"]               = { wire_vthruster_model = "models/dav0r/thruster.mdl" },
			["#Paint_Bucket"]           = { wire_vthruster_model = "models/props_junk/plasticbucket001a.mdl" },
			["#Small_Propane_Canister"] = { wire_vthruster_model = "models/props_junk/PropaneCanister001a.mdl" },
			["#Medium_Propane_Tank"]    = { wire_vthruster_model = "models/props_junk/propane_tank001a.mdl" },
			["#Cola_Can"]               = { wire_vthruster_model = "models/props_junk/PopCan01a.mdl" },
			["#Bucket"]                 = { wire_vthruster_model = "models/props_junk/MetalBucket01a.mdl" },
			["#Vitamin_Jar"]            = { wire_vthruster_model = "models/props_lab/jar01a.mdl" },
			["#Lamp_Shade"]             = { wire_vthruster_model = "models/props_c17/lampShade001a.mdl" },
			["#Fat_Can"]                = { wire_vthruster_model = "models/props_c17/canister_propane01a.mdl" },
			["#Black_Canister"]         = { wire_vthruster_model = "models/props_c17/canister01a.mdl" },
			["#Red_Canister"]           = { wire_vthruster_model = "models/props_c17/canister02a.mdl" }
		}
	})*/
	/*panel:AddControl( "PropSelect", { Label = "#WireThrusterTool_Model",
		ConVar = "wire_vthruster_model",
		Category = "Thrusters",
		Models = list.Get( "ThrusterModels" )
	})*/

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_OWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"]              = { wire_vthruster_oweffect = "none" },
			["#Flames"]                  = { wire_vthruster_oweffect = "fire" },
			["#Plasma"]                  = { wire_vthruster_oweffect = "plasma" },
			["#Smoke"]                   = { wire_vthruster_oweffect = "smoke" },
			["#Smoke Random"]            = { wire_vthruster_oweffect = "smoke_random" },
			["#Smoke Do it Youself"]     = { wire_vthruster_oweffect = "smoke_diy" },
			["#Rings"]                   = { wire_vthruster_oweffect = "rings" },
			["#Rings Growing"]           = { wire_vthruster_oweffect = "rings_grow" },
			["#Rings Shrinking"]         = { wire_vthruster_oweffect = "rings_shrink" },
			["#Bubbles"]                 = { wire_vthruster_oweffect = "bubble" },
			["#Magic"]                   = { wire_vthruster_oweffect = "magic" },
			["#Magic Random"]            = { wire_vthruster_oweffect = "magic_color" },
			["#Magic Do It Yourself"]    = { wire_vthruster_oweffect = "magic_diy" },
			["#Colors"]                  = { wire_vthruster_oweffect = "color" },
			["#Colors Random"]           = { wire_vthruster_oweffect = "color_random" },
			["#Colors Do It Yourself"]   = { wire_vthruster_oweffect = "color_diy" },
			["#Blood"]                   = { wire_vthruster_oweffect = "blood" },
			["#Money"]                   = { wire_vthruster_oweffect = "money" },
			["#Sperms"]                  = { wire_vthruster_oweffect = "sperm" },
			["#Feathers"]                = { wire_vthruster_oweffect = "feather" },
			["#Candy Cane"]              = { wire_vthruster_oweffect = "candy_cane" },
			["#Goldstar"]                = { wire_vthruster_oweffect = "goldstar" },
			["#Water Small"]             = { wire_vthruster_oweffect = "water_small" },
			["#Water Medium"]            = { wire_vthruster_oweffect = "water_medium" },
			["#Water Big"]               = { wire_vthruster_oweffect = "water_big" },
			["#Water Huge"]              = { wire_vthruster_oweffect = "water_huge" },
			["#Striderblood Small"]      = { wire_vthruster_oweffect = "striderblood_small" },
			["#Striderblood Medium"]     = { wire_vthruster_oweffect = "striderblood_medium" },
			["#Striderblood Big"]        = { wire_vthruster_oweffect = "striderblood_big" },
			["#Striderblood Huge"]       = { wire_vthruster_oweffect = "striderblood_huge" },
			["#More Sparks"]             = { wire_vthruster_oweffect = "more_sparks" },
			["#Spark Fountain"]          = { wire_vthruster_oweffect = "spark_fountain" },
			["#Jetflame"]                = { wire_vthruster_oweffect = "jetflame" },
			["#Jetflame Advanced"]       = { wire_vthruster_oweffect = "jetflame_advanced" },
			["#Jetflame Blue"]           = { wire_vthruster_oweffect = "jetflame_blue" },
			["#Jetflame Red"]            = { wire_vthruster_oweffect = "jetflame_red" },
			["#Jetflame Purple"]         = { wire_vthruster_oweffect = "jetflame_purple" },
			["#Comic Balls"]             = { wire_vthruster_oweffect = "balls" },
			["#Comic Balls Random"]      = { wire_vthruster_oweffect = "balls_random" },
			["#Comic Balls Fire Colors"] = { wire_vthruster_oweffect = "balls_firecolors" },
			["#Souls"]                   = { wire_vthruster_oweffect = "souls" },
			["#Debugger 10 Seconds"]     = { wire_vthruster_oweffect = "debug_10" },
			["#Debugger 30 Seconds"]     = { wire_vthruster_oweffect = "debug_30" },
			["#Debugger 60 Seconds"]     = { wire_vthruster_oweffect = "debug_60" },
			["#Fire and Smoke"]          = { wire_vthruster_oweffect = "fire_smoke" },
			["#Fire and Smoke Huge"]     = { wire_vthruster_oweffect = "fire_smoke_big" },
			["#5 Growing Rings"]         = { wire_vthruster_oweffect = "rings_grow_rings" },
			["#Color and Magic"]         = { wire_vthruster_oweffect = "color_magic" },
		}
	})

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_UWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"]				= { wire_vthruster_uweffect = "none" },
			["#Same as over water"]		= { wire_vthruster_uweffect = "same" },
			["#Flames"]					= { wire_vthruster_uweffect = "fire" },
			["#Plasma"]					= { wire_vthruster_uweffect = "plasma" },
			["#Smoke"]					= { wire_vthruster_uweffect = "smoke" },
			["#Smoke Random"]			= { wire_vthruster_uweffect = "smoke_random" },
			["#Smoke Do it Youself"]	= { wire_vthruster_uweffect = "smoke_diy" },
			["#Rings"]					= { wire_vthruster_uweffect = "rings" },
			["#Rings Growing"]			= { wire_vthruster_uweffect = "rings_grow" },
			["#Rings Shrinking"]		= { wire_vthruster_uweffect = "rings_shrink" },
			["#Bubbles"]				= { wire_vthruster_uweffect = "bubble" },
			["#Magic"]					= { wire_vthruster_uweffect = "magic" },
			["#Magic Random"]			= { wire_vthruster_uweffect = "magic_color" },
			["#Magic Do It Yourself"]	= { wire_vthruster_uweffect = "magic_diy" },
			["#Colors"]					= { wire_vthruster_uweffect = "color" },
			["#Colors Random"]			= { wire_vthruster_uweffect = "color_random" },
			["#Colors Do It Yourself"]	= { wire_vthruster_uweffect = "color_diy" },
			["#Blood"]					= { wire_vthruster_uweffect = "blood" },
			["#Money"]					= { wire_vthruster_uweffect = "money" },
			["#Sperms"]					= { wire_vthruster_uweffect = "sperm" },
			["#Feathers"]				= { wire_vthruster_uweffect = "feather" },
			["#Candy Cane"]				= { wire_vthruster_uweffect = "candy_cane" },
			["#Goldstar"]				= { wire_vthruster_uweffect = "goldstar" },
			["#Water Small"]			= { wire_vthruster_uweffect = "water_small" },
			["#Water Medium"]			= { wire_vthruster_uweffect = "water_medium" },
			["#Water Big"]				= { wire_vthruster_uweffect = "water_big" },
			["#Water Huge"]				= { wire_vthruster_uweffect = "water_huge" },
			["#Striderblood Small"]		= { wire_vthruster_uweffect = "striderblood_small" },
			["#Striderblood Medium"]	= { wire_vthruster_uweffect = "striderblood_medium" },
			["#Striderblood Big"]		= { wire_vthruster_uweffect = "striderblood_big" },
			["#Striderblood Huge"]		= { wire_vthruster_uweffect = "striderblood_huge" },
			["#More Sparks"]			= { wire_vthruster_uweffect = "more_sparks" },
			["#Spark Fountain"]			= { wire_vthruster_uweffect = "spark_fountain" },
			["#Jetflame"]				= { wire_vthruster_uweffect = "jetflame" },
			["#Jetflame Advanced"]		= { wire_vthruster_uweffect = "jetflame_advanced" },
			["#Jetflame Blue"]			= { wire_vthruster_uweffect = "jetflame_blue" },
			["#Jetflame Red"]			= { wire_vthruster_uweffect = "jetflame_red" },
			["#Jetflame Purple"]		= { wire_vthruster_uweffect = "jetflame_purple" },
			["#Comic Balls"]			= { wire_vthruster_uweffect = "balls" },
			["#Comic Balls Random"]		= { wire_vthruster_uweffect = "balls_random" },
			["#Comic Balls Fire Colors"]	= { wire_vthruster_uweffect = "balls_firecolors" },
			["#Souls"]					= { wire_vthruster_uweffect = "souls" },
			["#Debugger 10 Seconds"]	= { wire_vthruster_uweffect = "debug_10" },
			["#Debugger 30 Seconds"]	= { wire_vthruster_uweffect = "debug_30" },
			["#Debugger 60 Seconds"]	= { wire_vthruster_uweffect = "debug_60" },
			["#Fire and Smoke"]			= { wire_vthruster_uweffect = "fire_smoke" },
			["#Fire and Smoke Huge"]	= { wire_vthruster_uweffect = "fire_smoke_big" },
			["#5 Growing Rings"]		= { wire_vthruster_uweffect = "rings_grow_rings" },
			["#Color and Magic"]		= { wire_vthruster_uweffect = "color_magic" },
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_vthruster_force"
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force_min",
		Type = "Float",
		Min = "-10000",
		Max = "10000",
		Command = "wire_vthruster_force_min"
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force_max",
		Type = "Float",
		Min = "-10000",
		Max = "10000",
		Command = "wire_vthruster_force_max"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_bidir",
		Command = "wire_vthruster_bidir"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_collision",
		Command = "wire_vthruster_collision"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_sound",
		Command = "wire_vthruster_sound"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_owater",
		Command = "wire_vthruster_owater"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_uwater",
		Command = "wire_vthruster_uwater"
	})

	panel:AddControl("ComboBox", {
		Label = "#WireVThrusterTool_Mode",
		MenuButton = "0",

		Options = {
			["#XYZ Local"]			= { wire_vthruster_mode = "0" },
			["#XYZ World"]			= { wire_vthruster_mode = "1" },
			["#XY Local, Z World"]	= { wire_vthruster_mode = "2" },
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#WireVThrusterTool_Angle",
		Command = "wire_vthruster_angleinputs"
	})

end

list.Set( "ThrusterModels", "models/jaanus/wiretool/wiretool_speed.mdl", {} )
