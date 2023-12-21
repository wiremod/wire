AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Text Receiver"
ENT.WireDebugName = "Text Receiver"

if CLIENT then return end -- No more client

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

	self.Outputs = WireLib.CreateOutputs( self, { "Message [STRING]", "Player [ENTITY]", "Clk (Will output 1 for a single tick after both 'Message' and 'Player' have been updated.)" } )

	self.UseLuaPatterns = false
	self.CaseInsensitive = true
	self.Matches = {}
end

function ENT:Setup( UseLuaPatterns, Matches, CaseInsensitive )
	local outputs = { "Message", "Player", "Clk (Will output 1 for a single tick after both 'Message' and 'Player' have been updated.)" }
	local types = { "STRING", "ENTITY", "NORMAL" }

	if UseLuaPatterns then
		outputs[#outputs+1] = "PatternError (If there are any errors in your Lua patterns, this string will contain a list of each error message.)"
		types[#types+1] = "STRING"
	end

	if #Matches > 0 then
		local txt = "Matches:"
		for i=1,#Matches do
			outputs[#outputs+1] = "Match " .. i
			types[#types+1] = "NORMAL"
			txt = txt .. "\n" .. Matches[i]
			if UseLuaPatterns then
				outputs[#outputs+1] = "Matches " .. i
				types[#types+1] = "ARRAY"
			end
		end
		self:SetOverlayText(txt)
	end
	self.Outputs = WireLib.AdjustSpecialOutputs( self, outputs, types )

	self:PlayerSpoke( nil, "" ) -- Reset outputs

	self.UseLuaPatterns = UseLuaPatterns
	self.Matches = Matches
	self.CaseInsensitive = CaseInsensitive
end

function ENT:OnRemove()
	RemoveReceiver( self )
end

local string_find = string.find
local string_lower = string.lower
local string_match = string.match

function ENT:PcallFind( text, match )
	if self.UseLuaPatterns then
		local ok,err = pcall(function() WireLib.CheckRegex(text, match) end)
		if not ok then
			self.PatternError = err
			return false
		end
	end

	local ok, ret = pcall( string_find, text, match, 1, not self.UseLuaPatterns )

	if ok == true then
		return ret ~= nil
	else
		return false
	end
end

function ENT:AddError( err, idx )
	self.PatternError = self.PatternError .. err .. " at match nr " .. idx .. "\n"
end

function ENT:PcallMatch( text, match, idx )
	local ok,err = pcall(function() WireLib.CheckRegex(text, match) end)
	if not ok then
		self:AddError( err, idx )
		return {}
	end

	local ret = { pcall( string_match, text, match ) }

	if ret[1] == true then
		table.remove( ret, 1 )
		return ret
	else
		self:AddError( ret[2], idx )
		return {}
	end
end

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

	if self.UseLuaPatterns then
		-- Reset error
		self.PatternError = ""
		WireLib.TriggerOutput( self, "PatternError", self.PatternError )
	end

	for i=1,#self.Matches do
		local match = self.Matches[i]
		if self.CaseInsensitive then match = string_lower(match) end
		if self:PcallFind( text, match ) then
			WireLib.TriggerOutput( self, "Match " .. i, 1 )
		else
			WireLib.TriggerOutput( self, "Match " .. i, 0 )
		end

		if self.UseLuaPatterns then
			WireLib.TriggerOutput( self, "Matches " .. i, self:PcallMatch( text, match, i ) )
		end
	end

	if self.UseLuaPatterns then
		WireLib.TriggerOutput( self, "PatternError", string.sub( self.PatternError, 1, -2 ) )
	end
end

duplicator.RegisterEntityClass("gmod_wire_textreceiver", WireLib.MakeWireEnt, "Data", "UseLuaPatterns", "Matches", "CaseInsensitive" )
