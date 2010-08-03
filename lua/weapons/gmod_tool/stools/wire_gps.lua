TOOL.Category		= "Wire - Detection"
TOOL.Name			= "GPS"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_gps_name", "GPS Tool (Wire)" )
    language.Add( "Tool_wire_gps_desc", "Spawns a gps for use with the wire system." )
    language.Add( "Tool_wire_gps_0", "Primary: Create/Update GPS" )
	language.Add( "sboxlimit_wire_gpss", "You've hit GPS limit!" )
	language.Add( "undone_wiregps", "Undone Wire GPS" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gpss', 10)
	ModelPlug_Register("GPS")
end

TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/gps.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""
local ModelInfo = {"","",""}

cleanup.Register( "wire_gpss" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	// If we shot a wire_gps do nothing
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gps" && trace.Entity.pl == ply ) then
		trace.Entity:Setup()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gpss" ) ) then return false end

	if ( !util.IsValidModel( ModelInfo[3] ) ) then return false end
	if ( !util.IsValidProp( ModelInfo[3] ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_gps = MakeWireGPS( ply, trace.HitPos, Ang, ModelInfo[3] )

	local min = wire_gps:OBBMins()
	wire_gps:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_gps, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGPS")
		undo.AddEntity( wire_gps )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_gpss", wire_gps )

	return true
end

if (SERVER) then

	function MakeWireGPS( pl, Pos, Ang, model, nocollide )
		if ( !pl:CheckLimit( "wire_gpss" ) ) then return false end

		local wire_gps = ents.Create( "gmod_wire_gps" )
		if (!wire_gps:IsValid()) then return false end

		wire_gps:SetAngles( Ang )
		wire_gps:SetPos( Pos )
		if(!model) then
			wire_gps:SetModel( Model("models/jaanus/wiretool/wiretool_speed.mdl") )
		else
			wire_gps:SetModel( Model(model) )
		end
		wire_gps:Spawn()

		wire_gps:Setup()
		wire_gps:SetPlayer(pl)
		wire_gps.pl = pl

		if ( nocollide == true ) then wire_gps:GetPhysicsObject():EnableCollisions( false ) end

		pl:AddCount( "wire_gpss", wire_gps )

		return wire_gps
	end

	duplicator.RegisterEntityClass("gmod_wire_gps", MakeWireGPS, "Pos", "Ang", "Model", "nocollide")

end //end server if

function TOOL:UpdateGhostWireGPS( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_gps" || trace.Entity:IsPlayer()) then
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
	self:UpdateGhostWireGPS( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gps_name", Description = "#Tool_wire_gps_desc" })
	panel:AddControl("Label", {Text = "Model Size (if available)"})
	panel:AddControl("ComboBox", {
		Label = "Model Size",
		MenuButton = 0,
		Options = {
				["normal"] = { wire_gps_modelsize = "" },
				["mini"] = { wire_gps_modelsize = "_mini" },
				["nano"] = { wire_gps_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(panel, "GPS", "wire_gps", "#ToolWireIndicator_Model")
end
