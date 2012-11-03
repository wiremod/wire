AddCSLuaFile()
WireToolSetup.setCategory( "Detection" )

do
	WireToolSetup.open( "adv_emarker", "Adv Entity Marker", "gmod_wire_adv_emarker", nil, "Adv Entity Markers" )

	if CLIENT then
		language.Add( "Tool.wire_adv_emarker.name", "Adv Entity Marker Tool (Wire)" )
		language.Add( "Tool.wire_adv_emarker.desc", "Spawns an Adv Entity Marker for use with the wire system." )
		language.Add( "Tool.wire_adv_emarker.0", "Primary: Create Entity Marker, Secondary: Add a link, Reload: Remove a link" )
		language.Add( "Tool.wire_adv_emarker.1", "Now select the entity to link to (Tip: Hold down shift to link to more entities).")
		language.Add( "Tool.wire_adv_emarker.2", "Now select the entity to unlink (Tip: Hold down shift to unlink from more entities). Click Reload on the same entity marker again to clear all linked entities." )
		language.Add( "sboxlimit_wire_adv_emarker", "You've hit adv entity marker limit!" )
	end
	WireToolSetup.BaseLang()

	TOOL.Model =  "models/jaanus/wiretool/wiretool_siren.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
	}

	if SERVER then
		CreateConVar('sbox_maxwire_adv_emarkers', 3)
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireAdvEMarker( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	function TOOL:RightClick(trace)
		if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		local ent = trace.Entity
		if (self:GetStage() == 0 and ent:GetClass() == "gmod_wire_adv_emarker") then
			self.marker = ent
			self:SetStage(1)
		elseif (self:GetStage() == 1) then
			local ret = self.marker:AddEnt(ent)
			local ply = self:GetOwner()
			if (ret) then
				if (!ply:KeyDown(IN_SPEED)) then self:SetStage(0) end
				ply:ChatPrint("Added entity: " .. tostring(ent) .. " to the Adv Entity Marker.")
			else
				ply:ChatPrint("The Entity Marker is already linked to that entity.")
			end
		end
		return true
	end

	function TOOL:Reload(trace)
		if not trace.HitPos or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		local ent = trace.Entity
		if not IsValid(ent) then return false end
		if (self:GetStage() == 0 and ent:GetClass() == "gmod_wire_adv_emarker") then
			self.marker = ent
			self:SetStage(2)
		elseif (self:GetStage() == 2) then
			local ply = self:GetOwner()
			if (ent == self.marker) then
				ent:ClearEntities()
				ply:ChatPrint("Adv Entity Marker unlinked from all entities.")
				self:SetStage(0)
			else
				local ret = self.marker:CheckEnt(ent)
				if (ret) then
					if (!ply:KeyDown(IN_SPEED)) then self:SetStage(0) end
					self.marker:RemoveEnt( ent )
					ply:ChatPrint("Removed entity: " .. tostring(ent) .. " from the Adv Entity Marker.")
				else
					ply:ChatPrint("The Entity Marker is not linked to that entity.")
				end
			end
		end
	end

	if CLIENT then
		function TOOL:DrawHUD()
			local trace = self:GetOwner():GetEyeTrace()
			if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_adv_emarker" then
				local marks = trace.Entity.Marks
				if (marks and #marks > 0) then
					local markerpos = trace.Entity:GetPos():ToScreen()
					for _, ent in pairs( marks ) do
						if (ent:IsValid()) then
							local markpos = ent:GetPos():ToScreen()
							surface.SetDrawColor( 255,255,100,255 )
							surface.DrawLine( markerpos.x, markerpos.y, markpos.x, markpos.y )
						end
					end
				end
			end
		end
		usermessage.Hook("Wire_Adv_EMarker_Links", function(um)
			local Marker = Entity(um:ReadShort())
			if (Marker:IsValid()) then
				local nr = um:ReadShort()
				local marks = {}
				for i=1,nr do
					local en = Entity(um:ReadShort())
					if (en:IsValid()) then
						marks[#marks+1] = en
					end
				end
				Marker.Marks = marks
			end
		end)

		function TOOL.BuildCPanel(panel)
			panel:Help("#Tool.wire_adv_emarker.desc")
			ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_adv_emarker")
		end
	end
end

do
	WireToolSetup.open( "damage_detector", "Damage Detector", "gmod_wire_damage_detector", nil, "Damage Detectors" )

	if CLIENT then
		language.Add( "Tool.wire_damage_detector.name", "Damage Detector Tool (Wire)" )
		language.Add( "Tool.wire_damage_detector.desc", "Spawns a damage detector for use with the wire system" )
		language.Add( "Tool.wire_damage_detector.0", "Primary: Create/Update Detector, Secondary: Link Detector to an entity, Reload: Unlink Detector" )
		language.Add( "Tool.wire_damage_detector.1", "Now select the entity to link to." )
		language.Add( "Tool.wire_damage_detector.includeconstrained", "Include Constrained Props" )
		language.Add( "sboxlimit_wire_damage_detectors", "You've hit damage detectors limit!" )
	end
	WireToolSetup.BaseLang()

	TOOL.Model =  "models/jaanus/wiretool/wiretool_siren.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		includeconstrained = 0
	}

	if SERVER then
		CreateConVar('sbox_maxwire_damage_detectors', 10)
		
		function TOOL:GetConVars()
			return self:GetClientNumber( "includeconstrained" )
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireDamageDetector( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end
		
	function TOOL:LeftClick(trace)
		if not trace.HitPos or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		self:SetStage(0)
		local ply = self:GetOwner()

		if ( trace.Entity:GetClass() == "gmod_wire_damage_detector" ) then
			trace.Entity:Setup( self:GetConVars() )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", Entity(trace.Entity.linked_entities[0]) )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", trace.Entity )
		else
			local ent = self:LeftClick_Make( trace, ply )
			return self:LeftClick_PostMake( ent, ply, trace )
		end
		return true
	end

	function TOOL:RightClick(trace)
		if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_damage_detector" then
			self.detector = trace.Entity
			self:SetStage(1)
			return true
		elseif self:GetStage() == 1 then
			self.detector:LinkEntity( trace.Entity )
			self:SetStage(0)
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Damage Detector linked" )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", trace.Entity )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", self.detector )
			return true
		else
			self:SetStage(0)
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Invalid Target" )
			return false
		end
	end

	function TOOL:Reload(trace)
		if not trace.HitPos or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		self:SetStage(0)
		local detector = trace.Entity
		if !IsValid(detector) then return false end
		if detector:GetClass() == "gmod_wire_damage_detector" then
			detector:Unlink()
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Damage Detector unlinked" )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorLink", detector )
			self:GetWeapon():SetNetworkedEntity( "WireDamageDetectorEnt", detector ) // Set same point so line won't draw
			return true
		end
	end

	function TOOL:DrawHUD()
		local link = self:GetWeapon():GetNetworkedEntity( "WireDamageDetectorLink" )
		local ent = self:GetWeapon():GetNetworkedEntity( "WireDamageDetectorEnt" )
		if !IsValid(link) or !IsValid(ent) then return end

		local linkpos = link:GetPos():ToScreen()
		local entpos = ent:GetPos():ToScreen()
		if linkpos.x > 0 and linkpos.y > 0 and linkpos.x < ScrW() and linkpos.y < ScrH( ) then
			surface.SetDrawColor( 255, 255, 100, 255 )
			surface.DrawLine(entpos.x, entpos.y, linkpos.x, linkpos.y)
		end
	end

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_damage_detector.desc")
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_damage_detector")
		panel:CheckBox("#Tool.wire_damage_detector.includeconstrained","wire_damage_detector_includeconstrained")
	end
end

do
	WireToolSetup.open( "emarker", "Entity Marker", "gmod_wire_emarker", nil, "Entity Markers" )

	if CLIENT then
		language.Add( "Tool.wire_emarker.name", "Entity Marker Tool (Wire)" )
		language.Add( "Tool.wire_emarker.desc", "Spawns an Entity Marker for use with the wire system." )
		language.Add( "Tool.wire_emarker.0", "Primary: Create Entity Marker/Display Link Info, Secondary: Link Entity Marker, Reload: Unlink Entity Marker" )
		language.Add( "Tool.wire_emarker.1", "Now select the entity to link to.")
		language.Add( "sboxlimit_wire_emarker", "You've hit entity marker limit!" )
	end
	WireToolSetup.BaseLang()

	TOOL.Model =  "models/jaanus/wiretool/wiretool_siren.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
	}

	if SERVER then
		CreateConVar('sbox_maxwire_emarkers', 30)
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireEmarker( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end
		
	function TOOL:LeftClick(trace)
		if not trace.HitPos or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		self:SetStage(0)
		local ply = self:GetOwner()

		if ( trace.Entity:GetClass() == "gmod_wire_emarker" ) then
			self.marker = trace.Entity

			if ( !self.marker.mark || !self.marker.mark:IsValid() ) then
				ply:PrintMessage(HUD_PRINTTALK, "Entity Marker not linked")
				return false
			end

			ply:PrintMessage( HUD_PRINTTALK, "Linked model: " .. self.marker.mark:GetModel() )
			self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker.mark )
			self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker )
		else
			local ent = self:LeftClick_Make( trace, ply )
			return self:LeftClick_PostMake( ent, ply, trace )
		end
		return true
	end

	function TOOL:RightClick(trace)
		if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		if ( self:GetStage() == 0 && trace.Entity:GetClass() == "gmod_wire_emarker" ) then
			self.marker = trace.Entity
			self:SetStage(1)
			return true
		elseif ( self:GetStage() == 1  ) then
			self.marker:LinkEMarker(trace.Entity)
			self:SetStage(0)
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Entity Marker linked" )
			self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker.mark )
			self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker )
			return true
		else
			return false
		end
	end

	function TOOL:Reload(trace)
		if not trace.HitPos or trace.Entity:IsPlayer() then return false end
		if ( CLIENT ) then return true end

		self:SetStage(0)
		local marker = trace.Entity
		if not IsValid(marker) then return false end
		if (marker:GetClass() == "gmod_wire_emarker") then
			marker:UnLinkEMarker()
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Entity Marker unlinked" )
			self:GetWeapon():SetNetworkedEntity( "WireEntityMark", self.marker ) // Substitute for null, which won't set
			self:GetWeapon():SetNetworkedEntity( "WireEntityMarker", self.marker ) // Set same point so line won't draw
			return true
		end
	end

	function TOOL:DrawHUD()
		local mark = self:GetWeapon():GetNetworkedEntity( "WireEntityMark" )
		local marker = self:GetWeapon():GetNetworkedEntity( "WireEntityMarker" )
		if not IsValid(mark) or not IsValid(marker) then return end

		local markerpos = marker:GetPos():ToScreen()
		local markpos = mark:GetPos():ToScreen()
		if ( markpos.x > 0 && markpos.y > 0 && markpos.x < ScrW() && markpos.y < ScrH( ) ) then
			surface.SetDrawColor( 255, 255, 100, 255 )
			surface.DrawLine(markerpos.x, markerpos.y, markpos.x, markpos.y)
		end
	end

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_emarker.desc")
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_emarker")
	end
end

do -- wire_speedometer
	WireToolSetup.open( "speedometer", "Speedometer", "gmod_wire_speedometer", nil, "Speedometers" )

	if CLIENT then
		language.Add( "tool.wire_speedometer.name", "Speedometer Tool (Wire)" )
		language.Add( "tool.wire_speedometer.desc", "Spawns a speedometer for use with the wire system." )
		language.Add( "tool.wire_speedometer.0", "Primary: Create/Update Speedometer" )
		language.Add( "Tool_wire_speedometer_xyz_mode", "Split Outputs to X,Y,Z" )
		language.Add( "Tool_wire_speedometer_angvel", "Add Angular Velocity Outputs" )
		language.Add( "sboxlimit_wire_speedometers", "You've hit speedometers limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_speedometers', 10)
		
		function TOOL:GetConVars() 
			return tobool(self:GetClientNumber("xyz_mode")), tobool(self:GetClientNumber("angvel")) 
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireSpeedometer( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/jaanus/wiretool/wiretool_speed.mdl"
	TOOL.ClientConVar = {
		xyz_mode = 0,
		angvel = 0
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_speedometer.desc")
		panel:CheckBox("#Tool_wire_speedometer_xyz_mode", "wire_speedometer_xyz_mode")
		panel:CheckBox("#Tool_wire_speedometer_angvel", "wire_speedometer_AngVel")
	end
end -- wire_speedometer

do -- wire_gps
	WireToolSetup.open( "gps", "GPS", "gmod_wire_gps", nil, "GPSs" )

	if CLIENT then
		language.Add( "Tool.wire_gps.name", "GPS Tool (Wire)" )
		language.Add( "Tool.wire_gps.desc", "Spawns a GPS for use with the wire system." )
		language.Add( "Tool.wire_gps.0", "Primary: Create/Update GPS" )
		
		language.Add( "sboxlimit_wire_gpss", "You've hit GPS limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_gpss', 10)
		ModelPlug_Register("GPS")
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireGPS( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/beer/wiremod/gps.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		modelsize = "",
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_gps.desc")
		panel:AddControl("ListBox", {
			Label = "Model Size",
			Options = {
					["normal"] = { wire_gps_modelsize = "" },
					["mini"] = { wire_gps_modelsize = "_mini" },
					["nano"] = { wire_gps_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(panel, "GPS", "wire_gps")
	end
end -- wire_gps

do -- wire_gyroscope
	WireToolSetup.open( "gyroscope", "Gyroscope", "gmod_wire_gyroscope", nil, "Gyroscopes" )

	if CLIENT then
		language.Add( "Tool.wire_gyroscope.name", "Gyroscope Tool (Wire)" )
		language.Add( "Tool.wire_gyroscope.desc", "Spawns a gyroscope for use with the wire system." )
		language.Add( "Tool.wire_gyroscope.0", "Primary: Create/Update Gyroscope" )
		language.Add( "Tool.wire_gyroscope.out180", "Output -180 to 180 instead of 0 to 360" )
		language.Add( "sboxlimit_wire_gyroscopes", "You've hit gyroscopes limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_gyroscopes', 10)
		ModelPlug_Register("GPS")
		
		function TOOL:GetConVars() 
			return tobool(self:GetClientNumber("out180"))
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireGyroscope( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/bull/various/gyroscope.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		out180 = 0,
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_gyroscope.desc")
		ModelPlug_AddToCPanel(panel, "gyroscope", "wire_gyroscope")
		panel:CheckBox("#Tool.wire_gyroscope.out180","wire_gyroscope_out180")
	end
end -- wire_gyroscope

do
	WireToolSetup.open( "las_reciever", "Laser Pointer Receiver", "gmod_wire_las_reciever", nil, "Laser Pointer Receiver" )

	if CLIENT then
		language.Add( "Tool.wire_las_reciever.name", "Laser Receiver Tool (Wire)" )
		language.Add( "Tool.wire_las_reciever.desc", "Spawns a constant laser receiver prop for use with the wire system." )
		language.Add( "Tool.wire_las_reciever.0", "Primary: Create/Update Laser Receiver" )
		language.Add( "WireILaserRecieverTool_ilas_reciever", "Laser Receiver:" )
		language.Add( "sboxlimit_wire_las_recievers", "You've hit laser receivers limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_las_recievers', 20)
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireLaserReciever( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model =  "models/jaanus/wiretool/wiretool_range.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_las_reciever.desc")
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_las_reciever")
	end
end

do
	WireToolSetup.open( "ranger", "Ranger", "gmod_wire_ranger", nil, "Rangers" )

	if CLIENT then
		language.Add( "Tool.wire_ranger.name", "Ranger Tool (Wire)" )
		language.Add( "Tool.wire_ranger.desc", "Spawns a ranger for use with the wire system." )
		language.Add( "Tool.wire_ranger.0", "Primary: Create/Update Ranger" )
		language.Add( "Tool.wire_ranger.range", "Range:" )
		language.Add( "Tool.wire_ranger.default_zero", "Default to zero" )
		language.Add( "Tool.wire_ranger.show_beam", "Show Beam" )
		language.Add( "Tool.wire_ranger.ignore_world", "Ignore world" )
		language.Add( "Tool.wire_ranger.trace_water", "Hit water" )
		language.Add( "Tool.wire_ranger.out_dist", "Output Distance" )
		language.Add( "Tool.wire_ranger.out_pos", "Output Position" )
		language.Add( "Tool.wire_ranger.out_vel", "Output Velocity" )
		language.Add( "Tool.wire_ranger.out_ang", "Output Angle" )
		language.Add( "Tool.wire_ranger.out_col", "Output Color" )
		language.Add( "Tool.wire_ranger.out_val", "Output Value" )
		language.Add( "Tool.wire_ranger.out_sid", "Output SteamID(number)" )
		language.Add( "Tool.wire_ranger.out_uid", "Output UniqueID" )
		language.Add( "Tool.wire_ranger.out_eid", "Output Entity+EntID" )
		language.Add( "Tool.wire_ranger.out_hnrm", "Output HitNormal" )
		language.Add( "Tool.wire_ranger.hires", "High Resolution")
		language.Add( "sboxlimit_wire_rangers", "You've hit rangers limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_rangers', 10)
		ModelPlug_Register("ranger")
		
		function TOOL:GetConVars() 
			return self:GetClientNumber("range"), self:GetClientNumber("default_zero")~=0, self:GetClientNumber("show_beam")~=0, self:GetClientNumber("ignore_world")~=0,
				self:GetClientNumber("trace_water")~=0, self:GetClientNumber("out_dist")~=0, self:GetClientNumber("out_pos")~=0, self:GetClientNumber("out_vel")~=0,
				self:GetClientNumber("out_ang")~=0, self:GetClientNumber("out_col")~=0, self:GetClientNumber("out_val")~=0, self:GetClientNumber("out_sid")~=0,
				self:GetClientNumber("out_uid")~=0, self:GetClientNumber("out_eid")~=0, self:GetClientNumber("out_hnrm")~=0, self:GetClientNumber("hires")~=0
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireRanger( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		range = 1500,
		default_zero = 1,
		show_beam = 1,
		ignore_world = 0,
		trace_water = 0,
		out_dist = 1,
		out_pos = 0,
		out_vel = 0,
		out_ang = 0,
		out_col = 0,
		out_val = 0,
		out_sid = 0,
		out_uid = 0,
		out_eid = 0,
		out_hnrm = 0,
		hires = 0,
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_ranger.desc")
		ModelPlug_AddToCPanel(panel, "ranger", "wire_ranger")
		panel:NumSlider("#Tool.wire_ranger.range", "wire_ranger_range", 1, 1000, 2 )
		panel:CheckBox("#Tool.wire_ranger.default_zero","wire_ranger_default_zero")
		panel:CheckBox("#Tool.wire_ranger.show_beam","wire_ranger_show_beam")
		panel:CheckBox("#Tool.wire_ranger.ignore_world","wire_ranger_ignore_world")
		panel:CheckBox("#Tool.wire_ranger.trace_water","wire_ranger_trace_water")
		panel:CheckBox("#Tool.wire_ranger.out_dist","wire_ranger_out_dist")
		panel:CheckBox("#Tool.wire_ranger.out_pos","wire_ranger_out_pos")
		panel:CheckBox("#Tool.wire_ranger.out_vel","wire_ranger_out_vel")
		panel:CheckBox("#Tool.wire_ranger.out_ang","wire_ranger_out_ang")
		panel:CheckBox("#Tool.wire_ranger.out_col","wire_ranger_out_col")
		panel:CheckBox("#Tool.wire_ranger.out_val","wire_ranger_out_val")
		panel:CheckBox("#Tool.wire_ranger.out_sid","wire_ranger_out_sid")
		panel:CheckBox("#Tool.wire_ranger.out_uid","wire_ranger_out_uid")
		panel:CheckBox("#Tool.wire_ranger.out_eid","wire_ranger_out_eid")
		panel:CheckBox("#Tool.wire_ranger.out_hnrm","wire_ranger_out_hnrm")
		panel:CheckBox("#Tool.wire_ranger.hires","wire_ranger_hires")
	end
end

do
	WireToolSetup.open( "watersensor", "Water Sensor", "gmod_wire_watersensor", nil, "Water Sensors" )

	if CLIENT then
		language.Add( "Tool.wire_watersensor.name", "Water Sensor Tool (Wire)" )
		language.Add( "Tool.wire_watersensor.desc", "Spawns a constant Water Sensor prop for use with the wire system." )
		language.Add( "Tool.wire_watersensor.0", "Primary: Create/Update Water Sensor" )
		language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
		language.Add( "sboxlimit_wire_watersensors", "You've hit Water Sensors limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_watersensors', 10)
		ModelPlug_Register("WaterSensor")
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireWaterSensor( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/beer/wiremod/watersensor.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		modelsize = "",
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_watersensor.desc")
		panel:AddControl("ListBox", {
			Label = "Model Size",
			Options = {
					["normal"] = { wire_watersensor_modelsize = "" },
					["mini"] = { wire_watersensor_modelsize = "_mini" },
					["nano"] = { wire_watersensor_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(panel, "WaterSensor", "wire_watersensor")
	end
end
