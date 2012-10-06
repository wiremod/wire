TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Cam Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_cam_name", "Cam Controller Tool (Wire)" )
	language12.Add( "Tool_wire_cam_desc", "Spawns a constant Cam Controller prop for use with the wire system." )
	language12.Add( "Tool_wire_cam_0", "Primary: Create/Update Cam Controller Secondary: Link a cam controller to a Pod." )
	language12.Add( "Tool_wire_cam_1", "Now click a pod to link to." )
	language12.Add( "WirecamTool_cam", "Camera Controller:" )
	language12.Add( "WirecamTool_Static","Static")
	language12.Add( "sboxlimit_wire_cams", "You've hit Cam Controller limit!" )
	language12.Add( "undone_Wire cam", "Undone Wire Cam Controller" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cams', 20)
end


TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Static" ] = "0"

cleanup.Register( "wire_cams" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cameracontroller" && trace.Entity.pl == ply ) then
		return true
	end

	if (pl!=nil) then if ( !self:GetSWEP():CheckLimit( "wire_cams" ) ) then return false end end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local Static = self:GetClientNumber("Static")

	local wire_cam = MakeWireCam( ply, trace.HitPos, Ang, self:GetModel(), Static )

	local min = wire_cam:OBBMins()
	wire_cam:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_cam, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Cam")
		undo.AddEntity( wire_cam )
		undo.AddEntity( const )
		if Static == 1 then
			undo.AddEntity( wire_cam.CamEnt )
		end
		undo.SetPlayer( ply )
	undo.Finish()

	if (ply!=nil) then ply:AddCleanup( "wire_cams", wire_cam ) end

	return true
end

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

	if CLIENT then return true end
	if not trace.Entity then return false end
	if not trace.Entity:IsValid() then return false end

	self.trace.Entity.CamPod = nil;
end

if (SERVER) then

	function MakeWireCam( pl, Pos, Ang, model, Static )
		if (pl!=nil) then if ( !pl:CheckLimit( "wire_cams" ) ) then return false end end

		local wire_cam = ents.Create( "gmod_wire_cameracontroller" )
		if (!wire_cam:IsValid()) then return false end

		wire_cam:SetAngles( Ang )
		wire_cam:SetPos( Pos )
		wire_cam:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_cam:Spawn()
		wire_cam:Setup(pl,Static)

		wire_cam:SetPlayer( pl )

		local ttable = {
			pl = pl,
			Static=Static
		}
		table.Merge(wire_cam:GetTable(), ttable )

		if (pl!=nil) then pl:AddCount( "wire_cams", wire_cam ) end

		return wire_cam
	end

	duplicator.RegisterEntityClass("gmod_wire_cameracontroller", MakeWireCam, "Pos", "Ang", "Model", "Static")

end

function TOOL:UpdateGhostWirecam( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_cameracontroller" ) then
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
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model( model ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirecam( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cam_name", Description = "#Tool_wire_cam_desc" })
	WireDermaExts.ModelSelect(panel, "wire_cam_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:AddControl( "Checkbox", { Label = "#Wirecamtool_Static", Command = "wire_cam_static" } )
end
