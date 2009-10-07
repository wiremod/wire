
function WireToolMakeAdvInput( self, trace, ply )

	local _keymore			= self:GetClientNumber( "keymore" )
	local _keyless			= self:GetClientNumber( "keyless" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_min		= self:GetClientNumber( "value_min" )
	local _value_max		= self:GetClientNumber( "value_max" )
	local _value_start		= self:GetClientNumber( "value_start" )
	local _speed			= self:GetClientNumber( "speed" )

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_adv_input" and trace.Entity.pl == ply then
		trace.Entity:Setup( _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_adv_inputs" ) then return false end

	if not util.IsValidModel(self.ModelInfo[3]) or not util.IsValidProp(self.ModelInfo[3]) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_adv_input = MakeWireAdvInput( ply, trace.HitPos, Ang, self.ModelInfo[3], _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )

	local min = wire_adv_input:OBBMins()
	wire_adv_input:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_adv_input
end


function WireToolMakeAdvPod( self, trace, ply )

	if not self:GetSWEP():CheckLimit("wire_pods") then return false end

	local model = self:GetModel()
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_pod = MakeWireAdvPod(ply, trace.HitPos, Ang, model)

	wire_pod:SetPos(trace.HitPos - trace.HitNormal * wire_pod:OBBMins().z)

	return wire_pod
end


function WireToolMakeButton( self, trace, ply )

	local _model			= self:GetModel()
	local _toggle			= (self:GetClientNumber( "toggle" ) ~= 0)
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _description		= self:GetClientInfo( "description" )
	local _entityout		= (self:GetClientNumber( "entityout" ) ~= 0)

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_button" and trace.Entity.pl == ply then
		trace.Entity:Setup(_toggle, _value_off, _value_on, _entityout)
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_buttons" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_button = MakeWireButton( ply, trace.HitPos, Ang, _model, _toggle, _value_off, _value_on, _description, _entityout )

	local min = wire_button:OBBMins()
	wire_button:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_button
end


function WireToolMakeDualInput( self, trace, ply )

	local _keygroup			= self:GetClientNumber( "keygroup" )
	local _keygroup2		= self:GetClientNumber( "keygroup2" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _value_on2		= self:GetClientNumber( "value_on2" )

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_dual_input" and trace.Entity.pl == ply then
		trace.Entity:Setup( _keygroup, _keygroup2, _toggle, _value_off, _value_on, _value_on2 )
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_dual_inputs" ) then return false end

	if not util.IsValidModel(self.ModelInfo[3]) or not util.IsValidProp(self.ModelInfo[3]) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_dual_input = MakeWireDualInput( ply, trace.HitPos, Ang, self.ModelInfo[3], _keygroup, _keygroup2, _toggle, _value_off, _value_on, _value_on2 )

	local min = wire_dual_input:OBBMins()
	wire_dual_input:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_dual_input
end


function WireToolMakeInput( self, trace, ply )

	local keygroup	= self:GetClientNumber( "keygroup" )
	local toggle	= self:GetClientNumber( "toggle" )
	local value_off	= self:GetClientNumber( "value_off" )
	local value_on	= self:GetClientNumber( "value_on" )

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_input" and trace.Entity.pl == ply then
		trace.Entity:Setup( keygroup, toggle, value_off, value_on )
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_inputs" ) then return false end

	if not util.IsValidModel(self.ModelInfo[3]) or not util.IsValidProp(self.ModelInfo[3]) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_input = MakeWireInput( ply, trace.HitPos, Ang, self.ModelInfo[3], keygroup, toggle, value_off, value_on )

	local min = wire_input:OBBMins()
	wire_input:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_input
end

