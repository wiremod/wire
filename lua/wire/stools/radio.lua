TOOL.Category   = "Wire - I/O"
TOOL.Name       = "Radio"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.wire_radio.name", "Radio Tool (Wire)" )
	language.Add( "Tool.wire_radio.desc", "Spawns a radio for use with the wire system." )
	language.Add( "Tool.wire_radio.0", "Primary: Create/Update Radio" )
	language.Add( "WireRadioTool_channel", "Channel:" )
	language.Add( "WireRadioTool_values", "Values:" );
	language.Add( "WireRadioTool_secure", "Secure" );
	language.Add( "sboxlimit_wire_radios", "You've hit the radio limit!" )
	language.Add( "undone_wireradio", "Undone Wire Radio" )
end

if (SERVER) then
	ModelPlug_Register("radio")
	CreateConVar('sbox_maxwire_radioes',30)
end

TOOL.ClientConVar = {
	channel = 1,
	values  = 4,
	secure  = 0,
	model   = "models/props_lab/binderblue.mdl"
}

cleanup.Register( "wire_radioes" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local _channel	= self:GetClientInfo( "channel" )
	local values		= self:GetClientNumber("values")
	local secure		= (self:GetClientNumber("secure") ~= 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_radio" ) then
		trace.Entity:Setup( _channel,values,secure)
		trace.Entity.channel = _channel
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_radioes" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_radio = MakeWireRadio( ply, trace.HitPos, Ang, self:GetModel(), _channel,values,secure)

	local min = wire_radio:OBBMins()
	wire_radio:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_radio, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireRadio")
		undo.AddEntity( wire_radio )
		undo.SetPlayer( ply )
		undo.AddEntity(const)
	undo.Finish()

	ply:AddCleanup( "wire_radioes", wire_radio )

	return true
end

if SERVER then

	function MakeWireRadio(pl, Pos, Ang, model, channel, values, secure )
		if ( !pl:CheckLimit( "wire_radioes" ) ) then return nil end

		local wire_radio = ents.Create( "gmod_wire_radio" )
		wire_radio:SetPos( Pos )
		wire_radio:SetAngles( Ang )
		wire_radio:SetModel(model)
		wire_radio:Spawn()
		wire_radio:Activate()

		local ttable = {
			channel   = channel,
			values    = values,
			secure    = secure,
			pl        = pl,
			nocollide = nocollide,
		}
		table.Merge( wire_radio:GetTable(), ttable )

		wire_radio:Setup( channel ,values ,secure )
		wire_radio:SetPlayer( pl )

		pl:AddCount( "wire_radioes", wire_radio )

		return wire_radio
	end

	duplicator.RegisterEntityClass("gmod_wire_radio", MakeWireRadio, "Pos", "Ang", "Model", "channel", "values", "secure")

end

function TOOL:UpdateGhostWireRadio( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_radio" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	ent:SetAngles( Ang )

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireRadio( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/props_lab/binderblue.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_radio.name", Description = "#Tool.wire_radio.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_radio",

		Options = {
			Default = {
				wire_radio_channel = "1",
				wire_radio_values = "4",
				wire_radio_secure = "0",
				wire_radio_model = "models/props_lab/binderblue.mdl"
			}
		},

		CVars = {
			[0] = "wire_radio_channel",
			[1] = "wire_radio_values",
			[2] = "wire_radio_secure",
			[3] = "wire_radio_model"
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireRadioTool_channel",
		Type = "Integer",
		Min = "1",
		Max = "30",
		Command = "wire_radio_channel"
	})

	ModelPlug_AddToCPanel(panel, "radio", "wire_radio", true)

	panel:AddControl("Slider", {
		Label = "#WireRadioTool_values",
		Type = "Integer",
		Min = "1",
		Max = "20",
		Command = "wire_radio_values"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRadioTool_secure",
		Command = "wire_radio_secure"
	})

end
