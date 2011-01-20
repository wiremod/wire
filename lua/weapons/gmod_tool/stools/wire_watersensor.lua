TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Water Sensor"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_watersensor_name", "Water Sensor Tool (Wire)" )
    language.Add( "Tool_wire_watersensor_desc", "Spawns a constant Water Sensor prop for use with the wire system." )
    language.Add( "Tool_wire_watersensor_0", "Primary: Create/Update Water Sensor" )
    language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
	language.Add( "sboxlimit_wire_watersensors", "You've hit Water Sensors limit!" )
	language.Add( "undone_Wire Water Sensor", "Undone Wire Water Sensor" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_watersensors', 20)
	ModelPlug_Register("WaterSensor")
end

TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/watersensor.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""
local ModelInfo = {"","",""}

cleanup.Register( "wire_watersensors" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_watersensor" && trace.Entity.pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_watersensors" ) ) then return false end

	if ( !util.IsValidModel( ModelInfo[3] ) ) then return false end
	if ( !util.IsValidProp( ModelInfo[3] ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_watersensor = MakeWireWatersensor( ply, trace.HitPos, Ang, ModelInfo[3] )

	local min = wire_watersensor:OBBMins()
	wire_watersensor:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_watersensor, trace.Entity, trace.PhysicsBone, true, true)

	undo.Create("Wire Water Sensor")
		undo.AddEntity( wire_watersensor )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_watersensors", wire_watersensor )

	return true
end

if (SERVER) then

	function MakeWireWatersensor( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_watersensors" ) ) then return false end

		local wire_watersensor = ents.Create( "gmod_wire_watersensor" )
		if (!wire_watersensor:IsValid()) then return false end

		wire_watersensor:SetAngles( Ang )
		wire_watersensor:SetPos( Pos )
		if(!model) then
			wire_watersensor:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		else
			wire_watersensor:SetModel( Model(model) )
		end
		wire_watersensor:Spawn()

		wire_watersensor:SetPlayer( pl )
		wire_watersensor.pl = pl

		pl:AddCount( "wire_watersensors", wire_watersensor )

		return wire_watersensor
	end

	duplicator.RegisterEntityClass("gmod_wire_watersensor", MakeWireWatersensor, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireWatersensor( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_watersensor" ) then
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
	self:UpdateGhostWireWatersensor( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_watersensor_name", Description = "#Tool_wire_watersensor_desc" })
	panel:AddControl("Label", {Text = "Model Size (if available)"})
	panel:AddControl("ComboBox", {
		Label = "Model Size",
		MenuButton = 0,
		Options = {
				["normal"] = { wire_watersensor_modelsize = "" },
				["mini"] = { wire_watersensor_modelsize = "_mini" },
				["nano"] = { wire_watersensor_modelsize = "_nano" }
			}
	})
	ModelPlug_AddToCPanel(panel, "WaterSensor", "wire_watersensor", "#ToolWireIndicator_Model")
end
