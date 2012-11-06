TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Wired Numpad"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_numpad.name", "Wired Numpad Tool (Wire)" )
    language.Add( "Tool.wire_numpad.desc", "Spawns a numpad input for use with the wire system." )
    language.Add( "Tool.wire_numpad.0", "Primary: Create/Update Numpad" )
    language.Add( "WireNumpadTool_toggle", "Toggle" )
    language.Add( "WireNumpadTool_value_on", "Value On:" )
    language.Add( "WireNumpadTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_numpad", "You've hit wired numpads limit!" )
	language.Add( "undone_wirenumpad", "Undone Wire Numpad" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_numpads', 20)
	ModelPlug_Register("Numpad")
end

TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_off" ] = "0"
TOOL.ClientConVar[ "value_on" ] = "1"
TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/numpad.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""
local ModelInfo = {"","",""}

cleanup.Register( "wire_numpads" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_numpad" ) then
		trace.Entity:Setup( _toggle, _value_off, _value_on )
		trace.Entity.toggle = _toggle
		trace.Entity.value_off = _value_off
		trace.Entity.value_on = _value_on
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_numpads" ) ) then return false end

	if ( !util.IsValidModel( ModelInfo[3] ) ) then return false end
	if ( !util.IsValidProp( ModelInfo[3] ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_numpad = MakeWireNumpad( ply, trace.HitPos, Ang, ModelInfo[3], _toggle, _value_off, _value_on )

	local min = wire_numpad:OBBMins()
	wire_numpad:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_numpad, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireNumpad")
		undo.AddEntity( wire_numpad )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_numpads", wire_numpad )

	return true

end

if (SERVER) then

	function MakeWireNumpad( pl, Pos, Ang, model, toggle, value_off, value_on )
		if ( !pl:CheckLimit( "wire_numpads" ) ) then return false end

		local wire_numpad = ents.Create( "gmod_wire_numpad" )
		if (!wire_numpad:IsValid()) then return false end

		wire_numpad:SetAngles( Ang )
		wire_numpad:SetPos( Pos )
		if(!model) then
			wire_numpad:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		else
			wire_numpad:SetModel( Model(model) )
		end
		wire_numpad:Spawn()

		wire_numpad:Setup(toggle, value_off, value_on )
		wire_numpad:SetPlayer( pl )

		wire_numpad.impulses = {}
		for k = 0, 16 do
			table.insert(wire_numpad.impulses, numpad.OnDown( pl, k, "WireNumpad_On", wire_numpad, k ))
			table.insert(wire_numpad.impulses, numpad.OnUp( pl, k, "WireNumpad_Off", wire_numpad, k ))
		end

		local ttable = {
			toggle			= toggle,
			value_off		= value_off,
			value_on		= value_on,
			pl              = pl
		}
		table.Merge(wire_numpad, ttable )

		pl:AddCount( "wire_numpads", wire_numpad )

		return wire_numpad
	end

	duplicator.RegisterEntityClass("gmod_wire_numpad", MakeWireNumpad, "Pos", "Ang", "Model", "toggle", "value_off", "value_on")

end //end server if

function TOOL:UpdateGhostWireNumpad( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_numpad" ) then
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
	self:UpdateGhostWireNumpad( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_numpad.name", Description = "#Tool.wire_numpad.desc" })

	panel:AddControl("Label", {Text = "Model Size (if available)"})
	panel:AddControl("ComboBox", {
		Label = "Model Size",
		MenuButton = 0,
		Options = {
				["normal"] = { wire_numpad_modelsize = "" },
				["mini"] = { wire_numpad_modelsize = "_mini" },
				["nano"] = { wire_numpad_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_numpad", "#ToolWireIndicator_Model")
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_numpad",

		Options = {
			Default = {
				wire_numpad_toggle = "0",
				wire_numpad_value_on = "1",
				wire_numpad_value_off = "0"
			}
		},

		CVars = {
			[0] = "wire_numpad_toggle",
			[1] = "wire_numpad_value_on",
			[2] = "wire_numpad_value_off"
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#WireNumpadTool_toggle",
		Command = "wire_numpad_toggle"
	})

	panel:AddControl("Slider", {
		Label = "#WireNumpadTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_numpad_value_on"
	})
	panel:AddControl("Slider", {
		Label = "#WireNumpadTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_numpad_value_off"
	})
end
