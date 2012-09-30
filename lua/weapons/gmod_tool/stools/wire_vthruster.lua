TOOL.Category   = "Wire - Physics"
TOOL.Name       = "Vector Thruster"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_vthruster_name", "Vector Thruster Tool (Wire)" )
	language12.Add( "Tool_wire_vthruster_desc", "Spawns a vector thruster for use with the wire system." )
	language12.Add( "Tool_wire_vthruster_0", "Primary: Create/Update Vector Thruster" )
	language12.Add( "Tool_wire_vthruster_1", "Primary: Finish" )
	language12.Add( "WireVThrusterTool_Mode", "Mode:" )
	language12.Add( "WireVThrusterTool_Angle", "Use Yaw/Pitch Inputs Instead" )
	language12.Add( "undone_wirevthruster", "Undone Wire Vector Thruster" )
end

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_speed.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "soundname" ] = ""
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
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end
	local bidir       = self:GetClientNumber( "bidir" ) ~= 0
	local nocollide   = self:GetClientNumber( "collision" ) == 0
	local soundname   = self:GetClientInfo( "soundname" )
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
			trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs)

			trace.Entity.force       = force
			trace.Entity.force_min   = force_min
			trace.Entity.force_max   = force_max
			trace.Entity.bidir       = bidir
			trace.Entity.soundname   = soundname
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

		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90

		local wire_thruster = MakeWireVectorThruster( ply, trace.HitPos, ang, self:GetModel(), force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, nocollide, mode, angleinputs )

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

	function MakeWireVectorThruster( pl, Pos, Ang, model, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, nocollide, mode, angleinputs)
		if ( !pl:CheckLimit( "wire_thrusters" ) ) then return false end
		mode = mode or 0

		local wire_thruster = ents.Create( "gmod_wire_vectorthruster" )
		if (!wire_thruster:IsValid()) then return false end
		wire_thruster:SetModel( model )

		wire_thruster:SetAngles( Ang )
		wire_thruster:SetPos( Pos )
		wire_thruster:Spawn()

		wire_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, soundname, mode, angleinputs)
		wire_thruster:SetPlayer( pl )

		if ( nocollide == true ) then wire_thruster:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			force       = force,
			force_min   = force_min,
			force_max   = force_max,
			bidir       = bidir,
			soundname   = soundname,
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
	duplicator.RegisterEntityClass("gmod_wire_vectorthruster", MakeWireVectorThruster, "Pos", "Ang", "Model", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "soundname", "nocollide", "mode", "angleinputs")

end

function TOOL:UpdateGhostWireThruster( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
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
			Phys2:SetAngles( Ang )
			Phys2:Wake()
		end
	else
		local model = self:GetModel()

		if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
			self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
		end

		self:UpdateGhostWireThruster( self.GhostEntity, self:GetOwner() )
	end

end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_speed.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
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
				wire_vthruster_model = "models/jaanus/wiretool/wiretool_speed.mdl",
				wire_vthruster_force = "1500",
				wire_vthruster_force_min = "0",
				wire_vthruster_force_max = "10000",
				wire_vthruster_bidir = "1",
				wire_vthruster_soundname = "",
				wire_vthruster_oweffect = "fire",
				wire_vthruster_uweffect = "same",
				wire_vthruster_owater = "1",
				wire_vthruster_uwater = "1",
				wire_vthruster_mode = "0",
				wire_vthruster_angleinputs = "0"

			}
		},

		CVars = {
			[0] = "wire_vthruster_model",
			[1] = "wire_vthruster_force",
			[2] = "wire_vthruster_force_min",
			[3] = "wire_vthruster_force_max",
			[4] = "wire_vthruster_bidir",
			[5] = "wire_vthruster_soundname",
			[6] = "wire_vthruster_oweffect",
			[7] = "wire_vthruster_uweffect",
			[8] = "wire_vthruster_owater",
			[9] = "wire_vthruster_uwater",
			[10] = "wire_vthruster_mode",
			[11] = "wire_vthruster_angleinputs"
		}
	})

	WireDermaExts.ModelSelect(panel, "wire_vthruster_model", list.Get( "ThrusterModels" ), 4, true)

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
			ctrl:SetConVar("wire_vthruster_oweffect")
			for name, mat in pairs( Effects ) do
				ctrl:AddMaterialEx( name, "gui/thrustereffects/"..mat, mat, {wire_vthruster_oweffect = mat} )
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
			ctrlUW:SetConVar("wire_vthruster_uweffect")
			for name, mat in pairs( Effects ) do
				ctrlUW:AddMaterialEx( name, "gui/thrustereffects/"..mat, mat, {wire_vthruster_uweffect = mat} )
			end

		CateGoryUW:SetContents( ctrlUW )

		panel:AddItem(CateGoryUW)

	local lst = {}
	for k,v in pairs( list.Get("ThrusterSounds") ) do
		lst[k] = {}
		for k2,v2 in pairs( v ) do
			lst[k]["wire_v"..k2] = v2
		end
	end

	panel:AddControl( "ComboBox", { Label = "#Thruster_Sounds",
									 Description = "Thruster_Sounds_Desc",
									 MenuButton = "0",
									 Options = lst } )

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
