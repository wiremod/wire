--[[

	ColorPicker for Expression2
	Allows faster color picking whithin the editor.

	Supported Color Format for Editors:
	GPU: RGB like: "color White, 255,255,255"
	E2: RGB like: "vec(255)"

]]--

-- Language Features
language.Add("pickcolorlang.copyvec", "Use vec(r, g, b) structure")
language.Add("pickcolorlang.copyalpha", "Use vec4(r, g, b, a) structure.")

-- Convars
CopyWithVecString = CreateClientConVar("wire_expression2_colorwithvec", 1, true, false)
CopyWithAlpha = CreateClientConVar("wire_expression2_copyalpha", 0, true, false)

-- Follows sound_browser pattern
-- Invalidates the panel on start
local PickColorPanel = nil

local function GetCurrentEditorType()
	return GetEditorType
end

-- Checks the Color and Checkboxes and copies to clipboard.
local function ColorToClipboard(colorStr)

	local clrCopy
	local etype = GetCurrentEditorType()
	local cfmt = ", " -- comma format

	if etype == "E2" then
		if CopyWithVecString:GetBool() and CopyWithAlpha:GetBool() then
			clrCopy = "vec4("..colorStr.r..cfmt..colorStr.g..cfmt..colorStr.b..cfmt..colorStr.a..")"

		elseif CopyWithVecString:GetBool() and not CopyWithAlpha:GetBool() then
			clrCopy = "vec("..colorStr.r..cfmt..colorStr.g..cfmt..colorStr.b..")"

		elseif not CopyWithVecString:GetBool() and CopyWithAlpha:GetBool() then
			clrCopy = colorStr.r..cfmt..colorStr.g..", "..colorStr.b..cfmt..colorStr.a

		elseif not CopyWithVecString:GetBool() and not CopyWithAlpha:GetBool() then
			clrCopy = colorStr.r..cfmt..colorStr.g..cfmt..colorStr.b
		end

	elseif etype == "GPU" then
		cfmt = ","
		clrCopy = colorStr.r..cfmt..colorStr.g..cfmt..colorStr.b

	end

	-- Copy it!
	if clrCopy then SetClipboardText(clrCopy) end
end

local function CreatePickColorBrowser()
	if IsValid(PickColorPanel) then PickColorPanel:Remove() end

	-- Default
	PickColorPanel = vgui.Create("DFrame")
	PickColorPanel:SetPos(50,25)
	PickColorPanel:SetSize(300, 340)
	PickColorPanel:SetSizable(false)
	PickColorPanel:SetDeleteOnClose( false )
	PickColorPanel:SetTitle("Color Browser")
	PickColorPanel:SetVisible(false)

	-- Color Mixer
	local Mixer = PickColorPanel:Add( "DColorMixer")
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
	CopyVecCheck:Dock(BOTTOM)
	CopyVecCheck:DockMargin(4, 4, 4, 4)
	CopyVecCheck:SetText( "#pickcolorlang.copyvec" )
	CopyVecCheck:SetConVar( "wire_expression2_colorwithvec" )

	-- Checkbox for Alpha Copy
	local CopyAlphaCheck = PickColorPanel:Add( "DCheckBoxLabel" )
	CopyAlphaCheck:Dock(BOTTOM)
	CopyAlphaCheck:DockMargin(4, 4, 4, 4)
	CopyAlphaCheck:SetText( "#pickcolorlang.copyalpha" )
	CopyAlphaCheck:SetConVar( "wire_expression2_copyalpha" )

	PickColorPanel.OnFocusChanged = function()
		if GetCurrentEditorType() == "E2" then
			CopyAlphaCheck:SetDisabled(false)
			CopyVecCheck:SetDisabled(false)
		else
			CopyVecCheck:SetDisabled(true)
			CopyAlphaCheck:SetDisabled(true)
		end
	end

end

local function OpenPickColorBrowser(pl, cmd, args)
	if not IsValid(PickColorPanel) then
		CreatePickColorBrowser()
	end

	PickColorPanel:SetVisible(true)
	PickColorPanel:MakePopup()
end

concommand.Add("wire_pickcolor_browser_open", OpenPickColorBrowser)
