WireToolSetup.setCategory( "Input, Output/Keyboard Interaction" )
WireToolSetup.open( "textreceiver", "Text Receiver", "gmod_wire_textreceiver", nil, "Text Receivers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_textreceiver.name", "Text Receiver Tool (Wire)" )
	language.Add( "Tool.wire_textreceiver.desc", "Spawns a text receiver for use with the wire system." )

	language.Add( "Tool_wire_textreceiver_case_insensitive", "Case insensitive" )
	language.Add( "Tool_wire_textreceiver_use_lua_patterns", "Use Lua Patterns" )
	language.Add( "Tool_wire_textreceiver_num_matches", "Number of matches to use" )
	for i=1,24 do
		language.Add( "Tool_wire_textreceiver_match" .. i, "Match " .. i .. ":" )
	end

	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Copy settings" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar["case_insensitive"] = 1
TOOL.ClientConVar["use_lua_patterns"] = 0

TOOL.ClientConVar["num_matches"] = 1
TOOL.ClientConVar["match1"] = "Hello World"
for i=2,24 do
	TOOL.ClientConVar["match"..i] = ""
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_range.mdl"

if SERVER then
	function TOOL:GetConVars()
		local matches = {}
		for i=1,math.Clamp(self:GetClientNumber("num_matches"),0,24) do
			matches[i] = self:GetClientInfo("match"..i)
		end
		return self:GetClientNumber("use_lua_patterns") ~= 0, matches, self:GetClientNumber("case_insensitive") ~= 0
	end
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
			if match ~= nil then
				ply:ConCommand( "wire_textreceiver_match" .. i .. " " .. match )
			end
		end

		ply:ChatPrint( "Text receiver settings copied." )
	else
		return false
	end
end

if CLIENT then
	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_textreceiver")
		panel:CheckBox("#Tool_wire_textreceiver_case_insensitive", "wire_textreceiver_case_insensitive")
		panel:CheckBox("#Tool_wire_textreceiver_use_lua_patterns", "wire_textreceiver_use_lua_patterns")
		local NumMatches = panel:NumSlider("#Tool_wire_textreceiver_num_matches", "wire_textreceiver_num_matches", 0, 24, 0)

		local matchlist = vgui.Create( "DPanelList" )

		matchlist:SetTall( 300 )
		matchlist:EnableVerticalScrollbar( true )

		local function UpdateMatchList(n)
			local n = math.Clamp(math.Round(n) or GetConVarNumber( "wire_textreceiver_num_matches" ),0,24)

			matchlist:Clear()

			for i=1,n do
				local pnl = vgui.Create( "DPanel" )

				local label = vgui.Create( "DLabel", pnl )
				label:SetText( "Match " .. i .. ":" )
				label:SetPos( 2, 2 )
				label:SetDark(true)
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

		panel:AddItem( matchlist )
	end
end
