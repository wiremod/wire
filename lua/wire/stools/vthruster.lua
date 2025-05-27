WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "vthruster", "Vector Thruster", "gmod_wire_vectorthruster", nil, "Vector Thrusters" )

if ( CLIENT ) then
	language.Add( "Tool.wire_vthruster.name", "Vector Thruster Tool (Wire)" )
	language.Add( "Tool.wire_vthruster.desc", "Spawns a vector thruster for use with the wire system." )
	language.Add( "WireVThrusterTool_Mode", "Mode:" )
	language.Add( "WireVThrusterTool_Angle", "Use Yaw/Pitch Inputs Instead" )
	language.Add( "WireVThrusterTool_LengthIsMul", "Use Vector Length for Mul" )

	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create/Update " .. TOOL.Name },
		{ name = "left_1", stage = 1, text = "Set the Angle, hold Shift to lock to 45 degrees" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_speed.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "soundname" ] = ""
TOOL.ClientConVar[ "oweffect" ] = "fire"
TOOL.ClientConVar[ "uweffect" ] = "same"
TOOL.ClientConVar[ "owater" ] = "1"
TOOL.ClientConVar[ "uwater" ] = "1"
TOOL.ClientConVar[ "mode" ] = "0"
TOOL.ClientConVar[ "angleinputs" ] = "0"
TOOL.ClientConVar[ "lengthismul" ] = "0"

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "force" ), self:GetClientNumber( "force_min" ), self:GetClientNumber( "force_max" ), self:GetClientInfo( "oweffect" ),
			self:GetClientInfo( "uweffect" ), self:GetClientNumber( "owater" ) ~= 0, self:GetClientNumber( "uwater" ) ~= 0, self:GetClientNumber( "bidir" ) ~= 0,
			self:GetClientInfo( "soundname" ), self:GetClientNumber( "mode" ), self:GetClientNumber( "angleinputs" ) ~= 0, self:GetClientNumber( "lengthismul" ) ~= 0
	end
end

function TOOL:LeftClick( trace )
	local numobj = self:NumObjects()

	local ply = self:GetOwner()

	if (numobj == 0) then
		if IsValid(trace.Entity) and trace.Entity:IsPlayer() then return false end

		-- If there's no physics object then we can't constraint it!
		if ( SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
		if (CLIENT) then return true end

		local ent = WireToolObj.LeftClick_Make(self, trace, ply )
		if isbool(ent) then return ent end
		if IsValid(ent) then
			ent:GetPhysicsObject():EnableMotion( false )
			self:ReleaseGhostEntity()

			self:SetObject(1, trace.Entity, trace.HitPos, trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone), trace.PhysicsBone, trace.HitNormal)
			self:SetObject(2, ent, trace.HitPos, ent:GetPhysicsObject(), 0, trace.HitNormal)
			self:SetStage(1)
		end
	else
		if (CLIENT) then return true end

		local anchor, wire_thruster = self:GetEnt(1), self:GetEnt(2)
		local anchorbone = self:GetBone(1)

		local const = WireLib.Weld(wire_thruster, anchor, anchorbone, true, false)

		local Phys = wire_thruster:GetPhysicsObject()
		Phys:EnableMotion( true )

		undo.Create("WireVThruster")
			undo.AddEntity( wire_thruster )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( "wire_vthrusters", wire_thruster )
		ply:AddCleanup( "wire_vthrusters", const )

		self:ClearObjects()
	end

	return true
end

local degrees = 0

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
		WireToolObj.Think(self) -- Basic ghost
	end
end

if (CLIENT) then
	function TOOL:FreezeMovement()
		return self:GetStage() == 1
	end
end

function TOOL:Holster()
	if self:NumObjects() > 0 and IsValid(self:GetEnt(2)) then
		self:GetEnt(2):Remove()
	end
	self:ClearObjects()
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_vthruster")
	WireDermaExts.ModelSelect(panel, "wire_vthruster_model", list.Get( "ThrusterModels" ), 4, true)

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
	panel:AddControl( "ListBox", { Label = "#Thruster_Sounds", Options = lst } )

	panel:NumSlider("#WireThrusterTool_force", "wire_vthruster_force", 1, 10000, 2 )
	panel:NumSlider("#WireThrusterTool_force_min", "wire_vthruster_force_min", -10000, 10000, 2 ):SetTooltip("#WireThrusterTool_force_min.help")
	panel:NumSlider("#WireThrusterTool_force_max", "wire_vthruster_force_max", -10000, 10000, 2 )
	panel:CheckBox("#WireThrusterTool_bidir", "wire_vthruster_bidir")
	panel:CheckBox("#WireThrusterTool_owater", "wire_vthruster_owater")
	panel:CheckBox("#WireThrusterTool_uwater", "wire_vthruster_uwater")

	panel:AddControl("ListBox", {
		Label = "#WireVThrusterTool_Mode",
		Options = {
			["#XYZ Local"]			= { wire_vthruster_mode = "0" },
			["#XYZ World"]			= { wire_vthruster_mode = "1" },
			["#XY Local, Z World"]	= { wire_vthruster_mode = "2" },
		}
	})

	panel:CheckBox("#WireVThrusterTool_Angle", "wire_vthruster_angleinputs")
	panel:CheckBox("#WireVThrusterTool_LengthIsMul", "wire_vthruster_lengthismul")
end

list.Set( "ThrusterModels", "models/jaanus/wiretool/wiretool_speed.mdl", {} )
