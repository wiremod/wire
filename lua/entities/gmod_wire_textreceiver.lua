AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "TextReceiver"

local receivers = {}

local function RegisterReceiver( ent )
	receivers[ent] = true
end

local function RemoveReceiver( ent )
	receivers[ent] = nil
end

hook.Add( "PlayerSay", "Wire Text receiver PlayerSay", function( ply, txt )
	for ent,_ in pairs( receivers ) do
		if not ent or not ent:IsValid() then
			RemoveReceiver( ent )
		else
			ent:PlayerSpoke( ply, txt )
		end
	end
end)

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	RegisterReceiver( self )

	self.Outputs = WireLib.CreateOutputs( self, { "Message [STRING]", "Player [ENTITY]", "Clk" } )

	self.UseLuaPatterns = false
	self.CaseInsensitive = true
	self.Matches = {}
end

function ENT:Setup( UseLuaPatterns, Matches, CaseInsensitive )
	local outputs = { "Message [STRING]", "Player [ENTITY]", "Clk" }
	if #Matches > 0 then
		local txt = "Matches:"
		for i=1,#Matches do
			outputs[#outputs+1] = "Match " .. i
			txt = txt .. "\n" .. Matches[i]
		end
		self:SetOverlayText(txt)
	end
	self.Outputs = WireLib.AdjustOutputs( self, outputs )

	self.UseLuaPatterns = UseLuaPatterns
	self.Matches = Matches
	self.CaseInsensitive = CaseInsensitive
end

function ENT:OnRemove()
	RemoveReceiver( self )
end

local string_find = string.find
local string_lower = string.lower

function ENT:PlayerSpoke( ply, text )
	WireLib.TriggerOutput( self, "Message", text )
	WireLib.TriggerOutput( self, "Player", ply )

	WireLib.TriggerOutput( self, "Clk", 1 )
	timer.Simple( 0, function()
		if self and self:IsValid() then
			WireLib.TriggerOutput( self, "Clk", 0 )
		end
	end	)

	if self.CaseInsensitive then text = string_lower(text) end

	for i=1,#self.Matches do
		local match = self.Matches[i]
		if self.CaseInsensitive then match = string_lower(match) end
		if string_find( text, match, 1, not self.UseLuaPatterns ) then
			WireLib.TriggerOutput( self, "Match " .. i, 1 )
		else
			WireLib.TriggerOutput( self, "Match " .. i, 0 )
		end
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.UseLuaPatterns = self.UseLuaPatterns
	info.Matches = self.Matches

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self:Setup( info.UseLuaPatterns, info.Matches )

	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

function MakeWireTextReceiver( ply, Pos, Ang, model, UseLuaPatterns, Matches, CaseInsensitive )
	if not ply:CheckLimit( "wire_textreceivers" ) then return false end

	local ent = ents.Create( "gmod_wire_textreceiver" )
	if not ent or not ent:IsValid() then return false end

	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	ent:SetModel( model or "models/jaanus/wiretool/wiretool_range.mdl" )
	ent:Spawn()
	ent:Activate()
	ent:SetPlayer(ply)

	ent:Setup( UseLuaPatterns, Matches, CaseInsensitive )

	ply:AddCount( "wire_textreceivers", ent )

	return ent
end
duplicator.RegisterEntityClass("gmod_wire_textreceiver", MakeWireTextReceiver, "Pos", "Ang", "Model", "UseLuaPatterns", "Matches", "CaseInsensitive" )
