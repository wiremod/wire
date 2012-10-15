TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Numpad Output"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.wire_output.name", "Output Tool (Wire)" )
	language.Add( "Tool.wire_output.desc", "Spawns an output for use with the wire system." )
	language.Add( "Tool.wire_output.0", "Primary: Create/Update Output" )
	language.Add( "WireOutput_keygroup", "Key:" )
	language.Add( "sboxlimit_wire_outputs", "You've hit outputs limit!" )
	language.Add( "undone_wireoutput", "Undone Wire Output" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_outputs', 10)
	ModelPlug_Register("Numpad")
end

TOOL.ClientConVar[ "keygroup" ] = "1"
TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/numpad.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""
local ModelInfo = {"","",""}

cleanup.Register( "wire_outputs" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local key 				= self:GetClientNumber( "keygroup" )

	// If we shot a wire_output do nothing
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_output" && trace.Entity.pl == ply ) then
		trace.Entity.key = key
		if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(ply, key) end
		trace.Entity:SetKey(key)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_outputs" ) ) then return false end

	if ( !util.IsValidModel( ModelInfo[3] ) ) then return false end
	if ( !util.IsValidProp( ModelInfo[3] ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_output = MakeWireOutput( ply, trace.HitPos, Ang, ModelInfo[3], key )

	local min = wire_output:OBBMins()
	wire_output:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_output, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireOutput")
		undo.AddEntity( wire_output )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_outputs", wire_output )

	return true
end

if (SERVER) then

	function MakeWireOutput( pl, Pos, Ang, model, key )
		if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(pl, key) end

		if ( !pl:CheckLimit( "wire_outputs" ) ) then return false end

		local wire_output = ents.Create( "gmod_wire_output" )
		if (!wire_output:IsValid()) then return false end

		wire_output:SetAngles( Ang )
		wire_output:SetPos( Pos )
		if(!model) then
			wire_output:SetModel( Model("models/jaanus/wiretool/wiretool_output.mdl") )
		else
			wire_output:SetModel( Model(model) )
		end
		wire_output:Spawn()

		wire_output:SetPlayer(pl)
		wire_output:SetKey(key)

		local ttable = {
			key	= key,
			pl	= pl,
		}
		table.Merge(wire_output:GetTable(), ttable )

		wire_output:ShowOutput()
		pl:AddCount( "wire_outputs", wire_output )

		return wire_output
	end

	duplicator.RegisterEntityClass("gmod_wire_output", MakeWireOutput, "Pos", "Ang", "Model", "key")

end

function TOOL:UpdateGhostWireOutput( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_output" || trace.Entity:IsPlayer()) then
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

function TOOL:GetModel()
	local model = self:GetClientInfo("model")
	local size = self:GetClientInfo("modelsize")
if (model=="models/jaanus/wiretool/wiretool_output.mdl") then return model end
if (model && size) then
	if (size!="") then
		return string.sub(model, 1, -5) .. size .. string.sub(model, -4)
	end
	return model
end
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
	self:UpdateGhostWireOutput( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_output.name", Description = "#Tool.wire_output.desc" })

	panel:AddControl("Label", {Text = "Model Size (if available)"})
	panel:AddControl("ComboBox", {
		Label = "Model Size",
		MenuButton = 0,
		Options = {
				["normal"] = { wire_output_modelsize = "" },
				["mini"] = { wire_output_modelsize = "_mini" },
				["nano"] = { wire_output_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(panel, "Numpad", "wire_output", "#ToolWireIndicator_Model")
	panel:AddControl("Numpad", {
		Label = "#WireOutput_keygroup",
		Command = "wire_output_keygroup",
		ButtonSize = "22"
	})
end
