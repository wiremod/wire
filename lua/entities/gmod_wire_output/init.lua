
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Output"

local keylist = {"0","1","2","3","4","5","6","7","8","9",".","Enter","+","-","*","/"}

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetOn( false )

	self.Inputs = Wire_CreateInputs(self, { "A" })
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if ((value > 0) ~= self:IsOn()) then
			self:Switch(not self:IsOn(), self:GetPlayer())
		end
	end
end

function ENT:Switch( on, ply )
	local plyindex 	= self:GetPlayerIndex()
	local key 		= self:GetKey()
	if (not key) then return end

	if (on) then
		numpad.Activate( ply, key )
	else
		numpad.Deactivate( ply, key )
	end

	self:SetOn(on)
end

function ENT:ShowOutput()
	if (self.key) then
		if (keylist[self.key + 1]) then
			self:SetOverlayText(keylist[self.key + 1])
		end
	end
end

function ENT:Setup( key )
	if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(self:GetOwner(), key) end
	self.key = key
	self:ShowOutput()
end

function ENT:GetKey()
	return self.key
end

function ENT:SetOn( on )
	self.On = on
end

function ENT:IsOn()
	return self.On
end

function MakeWireOutput( pl, Pos, Ang, model, key )
	if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(pl, key) end

	if ( !pl:CheckLimit( "wire_outputs" ) ) then return false end

	local wire_output = ents.Create( "gmod_wire_output" )
	if (!wire_output:IsValid()) then return false end

	wire_output:SetAngles( Ang )
	wire_output:SetPos( Pos )
	wire_output:SetModel( Model(model or "models/jaanus/wiretool/wiretool_output.mdl") )
	wire_output:Spawn()

	wire_output:SetPlayer(pl)
	wire_output.pl = pl
	wire_output:Setup(key)

	wire_output:ShowOutput()
	pl:AddCount( "wire_outputs", wire_output )

	return wire_output
end
duplicator.RegisterEntityClass("gmod_wire_output", MakeWireOutput, "Pos", "Ang", "Model", "key")
