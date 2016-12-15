--[[
	
	ColorPicker for Expression2
	Allows faster color picking whithin the editor.
	
	by NickMBR
	Dec 2016
	
]]--

-- Convars
CopyWithVecString = CreateClientConVar("wire_expression2_colorwithvec", 1, true, false)
CopyWithAlpha = CreateClientConVar("wire_expression2_copyalpha", 0, true, false)

-- Follows sound_browser pattern
-- Sets up the panel
local PickColorPanel = nil

-- Checks the Color and Checkboxes and copies to clipboard.
local function ColorToClipboard(colorStr)
	
	local clrCopy
	
	if (CopyWithVecString:GetInt() == 1 && CopyWithAlpha:GetInt() == 1) then
		clrCopy = "vec4("..colorStr.r..","..colorStr.g..","..colorStr.b..","..colorStr.a..")"
		
	elseif (CopyWithVecString:GetInt() == 1 && CopyWithAlpha:GetInt() == 0) then
		clrCopy = "vec("..colorStr.r..","..colorStr.g..","..colorStr.b..")"
		
	elseif (CopyWithVecString:GetInt() == 0 && CopyWithAlpha:GetInt() == 1) then
		clrCopy = colorStr.r..","..colorStr.g..","..colorStr.b..","..colorStr.a
		
	elseif (CopyWithVecString:GetInt() == 0 && CopyWithAlpha:GetInt() == 0) then
		clrCopy = colorStr.r..","..colorStr.g..","..colorStr.b
	end
	
	-- Copy it!
	if (clrCopy != nil) then SetClipboardText(clrCopy) end
end

-- Creates the Color Panel
local function CreatePickColorBrowser()
	if(IsValid(PickColorPanel)) then PickColorPanel:Remove() end
	
	-- Default
	PickColorPanel = vgui.Create("DFrame")
	PickColorPanel:SetPos(50,25)
	PickColorPanel:SetSize(300, 340)

	PickColorPanel:SetMinWidth(700)
	PickColorPanel:SetMinHeight(400)

	PickColorPanel:SetSizable(false)
	PickColorPanel:SetDeleteOnClose( false )
	PickColorPanel:SetTitle("Color Browser by NickMBR")
	PickColorPanel:SetVisible(false)
	
	-- Color Mixer
	Mixer = PickColorPanel:Add( "DColorMixer")
	Mixer:Dock(TOP)
	Mixer:SetSize(200, 200)
	Mixer:SetPalette( false )
	Mixer:SetAlphaBar( true )
	Mixer:SetWangs( true )
	Mixer:SetColor( Color( 255, 255, 255, 255 ) )

	-- Copy Button
	local ClipboardButton = PickColorPanel:Add("DButton")
	ClipboardButton:SetText("Copy to clipboard")
	ClipboardButton:DockMargin(4, 4, 4, 4)
	ClipboardButton:Dock(BOTTOM)
	ClipboardButton:SetSize(0, 40)
	ClipboardButton:SetVisible(true)
	ClipboardButton.DoClick = function(btn)
		ColorToClipboard(Mixer:GetColor())
	end
	
	-- Checkbox for Vector Copy
	local CopyVecCheck = PickColorPanel:Add( "DCheckBoxLabel" )
	CopyVecCheck:SetParent( PickColorPanel )
	CopyVecCheck:Dock(BOTTOM)
	CopyVecCheck:DockMargin(4, 4, 4, 4)
	CopyVecCheck:SetText( "Copy with function: vec(r, g, b)" )
	CopyVecCheck:SetConVar( "wire_expression2_colorwithvec" )
	CopyVecCheck:SizeToContents()
	
	-- Checkbox for Alpha Copy
	local CopyAplhaCheck = PickColorPanel:Add( "DCheckBoxLabel" )
	CopyAplhaCheck:SetParent( PickColorPanel )
	CopyAplhaCheck:Dock(BOTTOM)
	CopyAplhaCheck:DockMargin(4, 4, 4, 4)
	CopyAplhaCheck:SetText( "Copy with alpha: vec4(r, g, b, a)" )
	CopyAplhaCheck:SetConVar( "wire_expression2_copyalpha" )
	CopyAplhaCheck:SizeToContents()
	
end

-- Open the Panel
local function OpenPickColorBrowser(pl, cmd, args)
	if (!IsValid(PickColorPanel)) then
		CreatePickColorBrowser()
	end

	PickColorPanel:SetVisible(true)
	PickColorPanel:MakePopup()
	PickColorPanel:InvalidateLayout(true)
end

concommand.Add("wire_pickcolor_browser_open", OpenPickColorBrowser)