AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Panel"

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	self.chan = 1

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)

	self.Inputs = WireLib.CreateInputs(self, { "Ch1", "Ch2", "Ch3", "Ch4", "Ch5", "Ch6", "Ch7", "Ch8" })

	self:SetNetworkedInt('chan',self.chan)
	self.Outputs = Wire_CreateOutputs(self, { "Out" })

	self:InitializeShared()
end

function ENT:TriggerInput(iname, value, iter)
	local channel_number = tonumber(iname:match("^Ch([1-8])$"))
	if not channel_number then return end
	if self.chan == channel_number then Wire_TriggerOutput(self, "Out", value) end
	self:SetChannelValue( channel_number, value )
end

function MakeWirePanel( pl, Pos, Ang, model )

	if ( !pl:CheckLimit( "wire_panels" ) ) then return false end

	local wire_panel = ents.Create( "gmod_wire_panel" )
	if (!wire_panel:IsValid()) then return false end
	wire_panel:SetModel(model)

	wire_panel:SetAngles( Ang )
	wire_panel:SetPos( Pos )
	wire_panel:Spawn()

	wire_panel:SetPlayer(pl)

	pl:AddCount( "wire_panels", wire_panel )

	return wire_panel

end

duplicator.RegisterEntityClass("gmod_wire_panel", MakeWirePanel, "Pos", "Ang", "Model")
