WireToolSetup.setCategory( "Render" )
WireToolSetup.open( "fx_emitter", "FX Emitter", "gmod_wire_fx_emitter", nil, "FX Emitters" )

TOOL.ClientConVar[ "Effect" ]    = "sparks"
TOOL.ClientConVar[ "Delay" ]     = "0.07"
TOOL.ClientConVar[ "Weldworld" ] = "0"

if SERVER then
	CreateConVar('sbox_maxwire_fx_emitter', 20)
end

cleanup.Register( "wire_fx_emitter" )

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "Tool.wire_fx_emitter.name", "Wire FX Emitter" )
	language.Add( "Tool.wire_fx_emitter.desc", "Wire FX Emitter Emits effects eh?" )
	language.Add( "Tool.wire_fx_emitter.0", "Click somewhere to spawn a wire fx emitter. Click on an existing wire fx emitter to update it." )

	language.Add( "Undone_wire_fx_emitter", "Undone Wire FX Emitter" )
	language.Add( "Cleanup_wire_fx_emitter", "Wire FX Emitter" )
	language.Add( "Cleaned_wire_fx_emitter", "Cleaned up all Wire FX Emitters" )

end


function TOOL:LeftClick( trace )

	worldweld = worldweld or false

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end

	if (CLIENT) then return true end

	if !self:GetSWEP():CheckLimit( "wire_fx_emitter" ) then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local ply = self:GetOwner()
	local delay         = self:GetClientNumber( "Delay" )
	local effect        = self:GetClientInfo( "Effect" )
	local worldweld     = self:GetClientNumber( "Weldworld" ) ~= 0

	effect = ComboBox_Wire_FX_Emitter_Options[effect]

	if effect<1 then return false end

	// Safe(ish) limits
	delay = math.Clamp( delay, 0.05, 20 )

	// We shot an existing emitter - just change its values
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_fx_emitter" ) then

		if !trace.Entity.Inputs.Delay.Src then trace.Entity:SetDelay( delay ) end
		if !trace.Entity.Inputs.On.Src then trace.Entity:SetEffect( effect ) end
		return true

	end

	if ( !self:GetSWEP():CheckLimit( "emitters" ) ) then return false end

	if ( trace.Entity != NULL && (!trace.Entity:IsWorld() || worldweld) ) then

		trace.HitPos = trace.HitPos + trace.HitNormal * -5

	else

		trace.HitPos = trace.HitPos + trace.HitNormal * 1.75

	end

	local ang = trace.HitNormal:Angle()

	local wire_fx_emitter = MakeWireFXEmitter( ply, trace.HitPos, ang, "models/props_lab/tpplug.mdl", delay, effect )

	local weld

	// Don't weld to world
	--TODO: use wirelib weld.
	if ( trace.Entity != NULL && (!trace.Entity:IsWorld() || worldweld) ) then

		weld = constraint.Weld( wire_fx_emitter, trace.Entity, 0, trace.PhysicsBone, 0, true, true )

		// >:(
		wire_fx_emitter:GetPhysicsObject():EnableCollisions( false )
		wire_fx_emitter.nocollide = true

	end

	undo.Create("wire_fx_emitter")
		undo.AddEntity( wire_fx_emitter )
		undo.AddEntity( weld )
		undo.SetPlayer( ply )
	undo.Finish()

	return true

end

function TOOL:RightClick( trace )
	return self:LeftClick( trace, true )
end

if (SERVER) then

	function MakeWireFXEmitter( ply, Pos, Ang, model, delay, effect, nocollide )

		if ( !ply:CheckLimit( "wire_fx_emitter" ) ) then return nil end

		local wire_fx_emitter = ents.Create( "gmod_wire_fx_emitter" )
		if (!wire_fx_emitter:IsValid()) then return false end

		wire_fx_emitter:SetAngles( Ang )
		wire_fx_emitter:SetPos( Pos )
		wire_fx_emitter:SetModel(model or "models/props_lab/tpplug.mdl")
		wire_fx_emitter:Spawn()

		wire_fx_emitter:SetDelay( delay )
		wire_fx_emitter:SetEffect( effect )
		wire_fx_emitter:SetPlayer( ply )

		if ( nocollide == true ) then wire_fx_emitter:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl = ply,
			nocollide = nocollide
		}

		table.Merge( wire_fx_emitter:GetTable(), ttable )

		ply:AddCount( "wire_fx_emitters", wire_fx_emitter )
		ply:AddCleanup( "wire_fx_emitter", wire_fx_emitter )

		return wire_fx_emitter

	end

	duplicator.RegisterEntityClass( "gmod_wire_fx_emitter", MakeWireFXEmitter, "Pos", "Ang", "Model", "effect", "nocollide" )

	function TOOL:UpdateGhostWireFXEmitter( ent, player )
		if ( !ent || !ent:IsValid() ) then return end

		local trace = player:GetEyeTrace()

		if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_fx_emitter" ) then
			ent:SetNoDraw( true )
			return
		end

		local worldweld		= self:GetClientNumber( "Weldworld" ) ~= 0
		if ( !trace.Entity:IsWorld() || worldweld ) then
			ent:SetPos( trace.HitPos + trace.HitNormal * -5 )
		else
			ent:SetPos( trace.HitPos + trace.HitNormal * 1.75 )
		end

		ent:SetAngles( trace.HitNormal:Angle() )

		ent:SetNoDraw( false )
	end

	function TOOL:Think()
		if (!self.GhostEntity || !self.GhostEntity:IsValid() ) then
			self:MakeGhostEntity( "models/props_lab/tpplug.mdl", Vector(0,0,0), Angle(0,0,0) )
		end

		self:UpdateGhostWireFXEmitter( self.GhostEntity, self:GetOwner() )
	end

end


// NOTE the . instead of : here - there is no 'self' argument!!
// This is just a function on the table - not a member function!

function TOOL.BuildCPanel( CPanel )
	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool.wire_fx_emitter.name", Description	= "#Tool.wire_fx_emitter.desc" }  )

	// EMITTERS
	local params = { Label = "#Effect", Height = "250", MenuButton="0", Options = {} }

		for k,_ in pairs(ComboBox_Wire_FX_Emitter_Options) do
			params.Options[ "#wire_fx_emitter_" .. k ] = { wire_fx_emitter_Effect = k }
		end

	CPanel:AddControl( "ListBox", params )

	// DELAY
	CPanel:AddControl( "Slider",  { Label	= "How much time between the effect",
		Type	= "Float",
		Min		= 0.05,
		Max		= 5,
		Command = "wire_fx_emitter_Delay" }	 )

	CPanel:AddControl("CheckBox", {
		Label = "Allow weld to world",
		Command = "wire_fx_emitter_Weldworld"
	})

end
