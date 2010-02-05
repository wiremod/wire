TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Constant Value"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool_wire_value_name", "Value Tool (Wire)" )
	language.Add( "Tool_wire_value_desc", "Spawns a constant value prop for use with the wire system." )
	language.Add( "Tool_wire_value_0", "Primary: Create/Update Value   Secondary: Copy Settings" )
	language.Add( "WireValueTool_value", "Value:" )
	language.Add( "WireValueTool_model", "Model:" )
	language.Add( "WireValueTool_desc", "In addition to specifying numbers, you can also specify strings, all kinds of vectors and angles. Write \"type:value\" to use this feature." )
	language.Add( "sboxlimit_wire_values", "You've hit values limit!" )
	language.Add( "undone_wirevalue", "Undone Wire Value" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_values', 20)
	ModelPlug_Register("value")
end

TOOL.ClientConVar[ "model" ] = "models/kobilica/value.mdl"
TOOL.ClientConVar[ "numvalues" ] = "1"
TOOL.ClientConVar[ "value1" ] = "0"
TOOL.ClientConVar[ "value2" ] = "0"
TOOL.ClientConVar[ "value3" ] = "0"
TOOL.ClientConVar[ "value4" ] = "0"
TOOL.ClientConVar[ "value5" ] = "0"
TOOL.ClientConVar[ "value6" ] = "0"
TOOL.ClientConVar[ "value7" ] = "0"
TOOL.ClientConVar[ "value8" ] = "0"
TOOL.ClientConVar[ "value9" ] = "0"
TOOL.ClientConVar[ "value10" ] = "0"
TOOL.ClientConVar[ "value11" ] = "0"
TOOL.ClientConVar[ "value12" ] = "0"

cleanup.Register( "wire_values" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local numvalues	= self:GetClientNumber( "numvalues" )

	//value is a table of strings so we can save a step later in adjusting the outputs
	local value = {}
	if (numvalues < 1) then
			numvalues = 1
	elseif (numvalues > 12) then
		numvalues = 12
	end
	for i = 1, numvalues do
		value[i] = self:GetClientInfo( "value"..i )
	end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" && trace.Entity:GetPlayer() == ply ) then
		trace.Entity:Setup(value)
		trace.Entity.value = value
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_values" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_value = MakeWireValue( ply, trace.HitPos, Ang, self:GetModel(), value )

	local min = wire_value:OBBMins()
	wire_value:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_value, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireValue")
		undo.AddEntity( wire_value )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_values", wire_value )

	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" ) then
		local i = 0
		for k,v in pairs(trace.Entity.value) do
			ply:ConCommand("wire_value_value"..k.." "..v)
			i = i + 1
		end
		ply:ConCommand("wire_value_numvalues "..i)
		return true
	end
end

if (SERVER) then

	function MakeWireValue( ply, Pos, Ang, model, value )
		if ( !ply:CheckLimit( "wire_values" ) ) then return false end

		local wire_value = ents.Create( "gmod_wire_value" )
		if (!wire_value:IsValid()) then return false end

		wire_value:SetAngles( Ang )
		wire_value:SetPos( Pos )
		wire_value:SetModel( model )
		wire_value:Spawn()

		wire_value:Setup(value)
		wire_value:SetPlayer( ply )

		ply:AddCount( "wire_values", wire_value )

		return wire_value
	end

	duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Pos", "Ang", "Model", "value")

end

function TOOL:UpdateGhostWireValue( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_value" ) then
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
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireValue( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/kobilica/value.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_value_name", Description = "#Tool_wire_value_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_value",

		Options = {
			Default = {
				wire_value_numvalues = "1",
				wire_value_value1 = "0",
				wire_value_value2 = "0",
				wire_value_value3 = "0",
				wire_value_value4 = "0",
				wire_value_value5 = "0",
				wire_value_value6 = "0",
				wire_value_value7 = "0",
				wire_value_value8 = "0",
				wire_value_value9 = "0",
				wire_value_value10 = "0",
				wire_value_value11 = "0",
				wire_value_value12 = "0",
				wire_value_model = "models/kobilica/value.mdl"
			}
		},

		CVars = {
			[0] = "wire_value_numvalues",
			[1] = "wire_value_value1",
			[2] = "wire_value_value2",
			[3] = "wire_value_value3",
			[4] = "wire_value_value4",
			[5] = "wire_value_value5",
			[6] = "wire_value_value6",
			[7] = "wire_value_value7",
			[8] = "wire_value_value8",
			[9] = "wire_value_value9",
			[10] = "wire_value_value10",
			[11] = "wire_value_value11",
			[12] = "wire_value_value12",
			[13] = "wire_value_model"
		}
	})

	panel:AddControl("Button", {
		Text = "Reset values to zero",
		Name = "Reset",
		Command = "wire_value_value1 0;wire_value_value2 0;wire_value_value3 0;wire_value_value4 0;wire_value_value5 0;wire_value_value6 0;wire_value_value7 0;wire_value_value8 0;wire_value_value9 0;wire_value_value10 0;wire_value_value11 0;wire_value_value12 0;",
	})

	panel:AddControl("Slider", {
		Label = "Num of Values",
		Type = "Integer",
		Min = "1",
		Max = "12",
		Command = "wire_value_numvalues",
	})

	panel:AddControl("Label", {
		Text = "#WireValueTool_desc",
	})
	for i = 1,12 do
		panel:AddControl("TextBox", {
			Label = "Value"..i..":",
			Text = "test",
			Command = "wire_value_value"..i,
			WaitForEnter = true,
		})
	end

	ModelPlug_AddToCPanel(panel, "value", "wire_value", "#WireValueTool_model", nil, "#WireValueTool_model")
end
