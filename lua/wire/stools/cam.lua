WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "cam", "Cam Controller", "gmod_wire_cameracontroller", nil, "Cam Controllers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_cam.name", "Cam Controller Tool (Wire)" )
	language.Add( "Tool.wire_cam.desc", "Spawns a constant Cam Controller prop for use with the wire system." )
	language.Add( "Tool.wire_cam.0", "Primary: Create/Update Cam Controller Secondary: Link a cam controller to a Pod." )
	language.Add( "Tool.wire_cam.1", "Now click a pod to link to." )
	language.Add( "WirecamTool_cam", "Camera Controller:" )
	language.Add( "WirecamTool_Static","Static")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber( "static" )
	end
	
	function TOOL:LeftClick_PostMake( ent, ply, trace )
		if ent == true or not IsValid(ent) then return false end

		-- Welding
		local const
		if not self.ClientConVar.weld or self:GetClientNumber( "weld" ) == 1 then
			const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true, false )
		end

		undo.Create( self.WireClass )
			undo.AddEntity( ent )
			if (const) then undo.AddEntity( const ) end
			if IsValid(ent.CamEnt) then undo.AddEntity( ent.CamEnt ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		ply:AddCleanup( self.WireClass, ent )

		return true
	end
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "static" ] = "0"

function TOOL:RightClick( trace )
	if CLIENT then return true end
	if not trace.Entity then return false end
	if not trace.Entity:IsValid() then return false end

	if self:GetStage() == 0 then
		if trace.Entity:GetClass() ~= "gmod_wire_cameracontroller" then return false end
		self.Oldent = trace.Entity;
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 then
		if not trace.Entity:IsVehicle() then return false end
		self.Oldent.CamPod = trace.Entity;
		self.Oldent = nil;
		self:SetStage(0)
		return true
	else
		return false
	end
end

function TOOL:Reload( trace )
	self.Oldent = nil;
	self:SetStage(0)

	if not IsValid(trace.Entity) then return false end
	if CLIENT then return true end

	trace.Entity.CamPod = nil;
end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cam_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#Wirecamtool_Static", "wire_cam_static" )
end
