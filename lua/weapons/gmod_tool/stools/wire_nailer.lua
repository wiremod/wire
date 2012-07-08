TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Nailer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_nailer_name", "Nailer Tool (Wire)" )
	language12.Add( "Tool_wire_nailer_desc", "Spawns a constant nailer prop for use with the wire system." )
	language12.Add( "Tool_wire_nailer_0", "Primary: Create/Update Nailer" )
	language12.Add( "WireNailerTool_nailer", "Nailer:" )
	language12.Add( "WireNailerTool_Model", "Choose a Model:")
	language12.Add( "sboxlimit_wire_nailers", "You've hit nailers limit!" )
	language12.Add( "undone_wirenailer", "Undone Wire Nailer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_nailers', 20)
end

TOOL.ClientConVar[ "forcelim" ] = "0"
TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

local nailermodels = {
	["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
	["models/jaanus/wiretool/wiretool_siren.mdl"] = {}};

cleanup.Register( "wire_nailers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local model = self:GetClientInfo( "Model" )
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

	local flim = self:GetClientNumber( "forcelim" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_nailer" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( flim )
		trace.Entity.Flim = flim
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_nailers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_nailer = MakeWireNailer( ply, trace.HitPos, Ang, model, flim )

	local min = wire_nailer:OBBMins()
	wire_nailer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_nailer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Nailer")
		undo.AddEntity( wire_nailer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_nailers", wire_nailer )

	return true
end

if (SERVER) then

	function MakeWireNailer( pl, Pos, Ang, model, flim )
		if ( !pl:CheckLimit( "wire_nailers" ) ) then return false end

		local wire_nailer = ents.Create( "gmod_wire_nailer" )
		if (!wire_nailer:IsValid()) then return false end

		wire_nailer:SetAngles( Ang )
		wire_nailer:SetPos( Pos )
		wire_nailer:SetModel( model )
		wire_nailer:Spawn()

		wire_nailer:Setup( flim )
		wire_nailer:SetPlayer( pl )

		local ttable = {
			pl = pl,
			Flim = flim
		}
		table.Merge(wire_nailer:GetTable(), ttable )

		pl:AddCount( "wire_nailers", wire_nailer )

		return wire_nailer
	end

	duplicator.RegisterEntityClass("gmod_wire_nailer", MakeWireNailer, "Pos", "Ang", "Model", "Flim")

end

function TOOL:UpdateGhostWireNailer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_nailer" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model")  ) then
		self:MakeGhostEntity( self:GetClientInfo("Model") , Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireNailer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_nailer_name", Description = "#Tool_wire_nailer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_nailer",

		Options = {
			Default = {
				wire_nailer_nailer = "0",
			}
		},
		CVars = {
		}
	})

	panel:AddControl( "PropSelect", { Label = "#WireNailerTool_Model",
									 ConVar = "wire_nailer_Model",
									 Category = "Wire Nailer",
									 Models = nailermodels } )

	panel:AddControl("Slider", {
		Label = "Force Limit",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "wire_nailer_forcelim"
	})
end
