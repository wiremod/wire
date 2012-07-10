
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Text Receiver"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_textreceiver_name", "Text Receiver Tool (Wire)" )
	language12.Add( "Tool_wire_textreceiver_desc", "Spawns a text receiver for use with the wire system." )
	language12.Add( "Tool_wire_textreceiver_0", "Primary: Create/Update text receiver, Secondary: Copy Settings" )

	language12.Add( "undone_textreceiver", "Undone Wire Text Receiver" )

	language12.Add( "Tool_wire_textreceiver_case_insensitive", "Case insensitive" )
	language12.Add( "Tool_wire_textreceiver_use_lua_patterns", "Use Lua Patterns" )
	language12.Add( "Tool_wire_textreceiver_num_matches", "Number of matches to use" )
	for i=1,24 do
		language12.Add( "Tool_wire_textreceiver_match" .. i, "Match " .. i .. ":" )
	end
end

if (SERVER) then
	CreateConVar('sbox_maxwire_textreceivers', 10)
end

TOOL.ClientConVar["case_insensitive"] = 1
TOOL.ClientConVar["use_lua_patterns"] = 0
TOOL.ClientConVar["weld"] = 1

TOOL.ClientConVar["num_matches"] = 1
TOOL.ClientConVar["match1"] = "Hello World"
for i=2,24 do
	TOOL.ClientConVar["match"..i] = ""
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_range.mdl"



function TOOL:LeftClick( trace )
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local UseLuaPatterns = (self:GetClientNumber("use_lua_patterns") ~= 0)

	local Matches = {}
	for i=1,math.Clamp(self:GetClientNumber("num_matches"),0,24) do
		local match = self:GetClientInfo("match"..i)
		Matches[i] = match
	end

	local CaseInsensitive = (self:GetClientNumber("case_insensitive") ~= 0)

	if trace.Entity and trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_textreceiver" then
		trace.Entity:Setup( UseLuaPatterns, Matches, CaseInsensitive )

		ply:ChatPrint( "Text receiver updated." )

		return true
	end

	local ent = MakeWireTextReceiver( ply, trace.HitPos, trace.HitNormal:Angle() + Angle(90,0,0), self:GetModel(), UseLuaPatterns, Matches, CaseInsensitive )
	if not ent or not ent:IsValid() then return false end

	ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )


	undo.Create( "TextReceiver" )
		undo.AddEntity( ent )

		if self:GetClientNumber( "weld" ) ~= 0 then
			local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
			undo.AddEntity( const )
		end

		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "text_receivers", text_receiver )
	ply:AddCleanup( "text_receivers", const )

	return true
end

if SERVER then
	function MakeWireTextReceiver( ply, Pos, Ang, model, UseLuaPatterns, Matches, CaseInsensitive )
		if not ply:CheckLimit( "wire_textreceivers" ) then return false end

		local ent = ents.Create( "gmod_wire_textreceiver" )
		if not ent or not ent:IsValid() then return false end

		ent:SetAngles( Ang )
		ent:SetPos( Pos )
		ent:SetModel( model or "models/jaanus/wiretool/wiretool_range.mdl" )
		ent:Spawn()
		ent:Activate()

		ent:Setup( UseLuaPatterns, Matches, CaseInsensitive )

		ply:AddCount( "wire_textreceivers", ent )

		return ent
	end

	duplicator.RegisterEntityClass("gmod_wire_textreceiver", MakeWireTextReceiver, "Pos", "Ang", "Model", "UseLuaPatterns", "Matches", "CaseInsensitive" )
end

function TOOL:RightClick( trace )
	if trace.Entity and trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_textreceiver" then
		if CLIENT then return true end

		local UseLuaPatterns = trace.Entity.UseLuaPatterns
		local Matches = trace.Entity.Matches
		local CaseInsensitive = trace.Entity.CaseInsensitive

		local ply = self:GetOwner()
		ply:ConCommand( "wire_textreceiver_use_lua_patterns " .. (UseLuaPatterns and 1 or 0))
		ply:ConCommand( "wire_textreceiver_case_insensitive " .. (CaseInsensitive and 1 or 0))
		for i=1,24 do
			local match = Matches[i]
			ply:ConCommand( "wire_textreceiver_match" .. i .. " " .. match )
		end

		ply:ChatPrint( "Text receiver settings copied." )
	else
		return false
	end
end

function TOOL:UpdateGhostWireTextReceiver( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_textreceiver" || trace.Entity:IsPlayer()) then

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
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireTextReceiver( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )

	if (util.IsValidModel(model) and util.IsValidProp(model)) then
		return model
	end

	return "models/jaanus/wiretool/wiretool_range.mdl"
end


if CLIENT then
	function TOOL.BuildCPanel( panel )
		local CaseInsensitive = vgui.Create( "DCheckBoxLabel" )
		CaseInsensitive:SetConVar( "wire_textreceiver_case_insensitive" )
		CaseInsensitive:SetText( "#Tool_wire_textreceiver_case_insensitive" )
		panel:AddItem( CaseInsensitive )

		local UseLuaPatterns = vgui.Create( "DCheckBoxLabel" )
		UseLuaPatterns:SetConVar( "wire_textreceiver_use_lua_patterns" )
		UseLuaPatterns:SetText( "#Tool_wire_textreceiver_use_lua_patterns" )
		panel:AddItem( UseLuaPatterns )

		local NumMatches = vgui.Create( "DNumSlider" )
		NumMatches:SetMin( 0 )
		NumMatches:SetMax( 24 )
		NumMatches:SetDecimals( 0 )
		NumMatches:SetText( "#Tool_wire_textreceiver_num_matches" )
		NumMatches:SetConVar( "wire_textreceiver_num_matches" )

		local matchlist = vgui.Create( "DPanelList" )

		matchlist:SetTall( 300 )
		matchlist:EnableVerticalScrollbar( true )

		local function UpdateMatchList(n)
			local n = math.Clamp(n or GetConVarNumber( "wire_textreceiver_num_matches" ),0,24)

			matchlist:Clear()

			for i=1,n do
				local pnl = vgui.Create( "DPanel" )

				local label = vgui.Create( "DLabel", pnl )
				label:SetText( "Match " .. i .. ":" )
				label:SetPos( 2, 2 )
				label:SizeToContents()

				local text = vgui.Create( "DTextEntry", pnl )
				text:SetText( GetConVarString( "wire_textreceiver_match" .. i ) )
				text:SetPos( 50, 2 )
				text:SetWide( 220 )
				text:SetConVar( "wire_textreceiver_match" .. i )

				matchlist:AddItem(pnl)
			end
		end

		function NumMatches:OnValueChanged( value )
			UpdateMatchList(tonumber(value)) -- what the fuck garry it's a string?!
		end

		panel:AddItem( NumMatches )
		panel:AddItem( matchlist )
	end
end
