AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Oscilloscope"

function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "X", "Y", "R", "G", "B", "Pause", "Length", "Update Frequency" })
end

function ENT:Think()
	if (self.Inputs.Pause.Value == 0) then
		self.BaseClass.Think(self)

		local x = math.max(-1, math.min(self.Inputs.X.Value or 0, 1))
		local y = math.max(-1, math.min(self.Inputs.Y.Value or 0, 1))
		self:SetNextNode(x, y)

		self.Entity:NextThink(CurTime()+(self.updaterate or 0.08))
		return true
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "R" then
		self.Entity:SetNetworkedFloat("R", value)
	elseif iname == "G" then
		self.Entity:SetNetworkedFloat("G", value)
	elseif iname == "B" then
		self.Entity:SetNetworkedFloat("B", value)
	elseif iname == "Length" then
		self.Entity:SetNetworkedFloat("Length", value)
	elseif iname == "Update Frequency" then
		if value <= 0 then value = 0.08 end
		self.updaterate = value
	end
end

function MakeWireOscilloscope( pl, Pos, Ang, model )

	if ( !pl:CheckLimit( "wire_oscilloscopes" ) ) then return false end

	local wire_oscilloscope = ents.Create( "gmod_wire_oscilloscope" )
	if (!wire_oscilloscope:IsValid()) then return false end
	wire_oscilloscope:SetModel( model )

	wire_oscilloscope:SetAngles( Ang )
	wire_oscilloscope:SetPos( Pos )
	wire_oscilloscope:Spawn()

	wire_oscilloscope:SetPlayer(pl)
	wire_oscilloscope.pl = pl

	pl:AddCount( "wire_oscilloscopes", wire_oscilloscope )

	return wire_oscilloscope
end

duplicator.RegisterEntityClass("gmod_wire_oscilloscope", MakeWireOscilloscope, "Pos", "Ang", "Model")
