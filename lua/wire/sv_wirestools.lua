--[[
	This is stool code,
		These are used by the Wired tools' LeftClick to make/update ents,
		the part after trace check and before welding/undo/cleanup creation.
]]--


function WireToolMakeGate( self, trace, ply )
	local action	= self:GetClientInfo( "action" )
	local noclip	= self:GetClientNumber( "noclip" ) == 1
	local model		= self:GetModel()

	if GateActions[action] == nil then return false end

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_gate" then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity.action = action
		return true
	end

	if not util.IsValidModel(model) and not util.IsValidProp(model) then return false end

	-- Check common limit
	if (!ply:CheckLimit( "wire_gates" )) then return false end

	-- Check individual limit
	if (!ply:CheckLimit( "wire_gate_" .. string.lower( GateActions[action].group ) .. "s" )) then return false end

	local Ang = self:GetAngle( trace )

	local wire_gate = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )

	local min = wire_gate:OBBMins()
	wire_gate:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_gate
end

