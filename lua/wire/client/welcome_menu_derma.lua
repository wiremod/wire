------------------------------------------------------------------------------------------------
-- Wiremod Community Welcome & Informaton Menu Custom Derma Panels
-- This file adds custom derma panels used in the welcome menu popup.
-- Made by Divran
------------------------------------------------------------------------------------------------
local WireLib = WireLib
local Menu = WireLib.WelcomeMenu
------------------------------------------------------------------------------------------------
-- "Copypasta"
-- Used to open URLs in the Browser tab, or copy to clipboard
------------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
	self:SetSize( 104, 44 )
	self:SetBGColor( Color( 150,150,150,210) )

	Menu:AddColoring( self.SetBGColor, "LabelBGColor", self )

	self.Label = vgui.Create("DLabel",self)
	self.Label:SetPos( 4, 2 )
	self.Label:SetText( "hello world" )
	self.Label:SetColor( Menu.Colors.TextColor )
	self.Label:SizeToContents()

	Menu:AddColoring( self.Label.SetColor, "TextColor", self.Label )

	self.Open = vgui.Create("Wire_WMenu_Button",self)
	self.Open:SetPos( 4, 20 )
	self.Open:SetText( "Open" )
	self.Open:SetSize( 46, 20 )

	self.Copy = vgui.Create("Wire_WMenu_Button",self)
	self.Copy:SetPos( 54, 20 )
	self.Copy:SetSize( 46, 20 )
	self.Copy:SetText( "Copy" )

	self.URL = ""
end

function PANEL:GetURL()
	return self.URL
end

function PANEL:SetBGColor( clr )
	self._BGColor = clr
end

function PANEL:GetBGColor()
	return self._BGColor
end

function PANEL:Paint()
	draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self:GetBGColor() )
end


function PANEL:SetURL( NiceName, Description, URL )
	self.Label:SetText( NiceName )
	self.Label:SizeToContents()
	self:SetToolTip( Description )
	function self.Open:DoClick()
		gui.OpenURL( self:GetParent():GetURL() )
	end
	function self.Copy:DoClick()
		SetClipboardText( self:GetParent():GetURL() )
	end
	self.URL = URL
end

derma.DefineControl( "Wire_WMenu_Copypasta", "WMenu Copy Pasta", PANEL, "DPanel" )

------------------------------------------------------------------------------------------------
-- Button
-- A regular button with a custom appearance
------------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:OnCursorEntered(...)
	self.Hovering = true
end
function PANEL:OnCursorExited(...)
	self.Hovering = nil
end
function PANEL:OnMousePressed(...)
	self.BaseClass.OnMousePressed(self,...)
	self.Holding = true
end
function PANEL:OnMouseReleased(...)
	self.BaseClass.OnMouseReleased(self,...)
	self.Holding = nil
end
function PANEL:Paint()
	local clr = Menu.Colors.ButtonColor
	if (self.Hovering) then
		if (self.Holding) then
			clr = Menu.Colors.ButtonClickColor
		else
			clr = Menu.Colors.ButtonHoverColor
		end
	end
	draw.RoundedBox( 4, 0,0,self:GetWide(),self:GetTall(),clr)
end

derma.DefineControl( "Wire_WMenu_Button", "WMenu Button", PANEL, "DButton" )

------------------------------------------------------------------------------------------------
-- Label
-- A regular label with a custom appearance
------------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
	self.BaseClass.Init(self)

	Menu:AddColoring( self.SetBGColor, "LabelBGColor", self )

	self.Label = vgui.Create("DLabel",self)
	self:SetBGColor( Menu.Colors.LabelBGColor )
	self:SetColor( Menu.Colors.TextColor )

	Menu:AddColoring( self.Label.SetColor, "TextColor", self.Label )
end

function PANEL:SizeToContents()
	self.Label:SizeToContents()
	local w,h = self.Label:GetSize()
	self:SetSize( w+6,h+6 )
end

function PANEL:SetText( txt )
	self.Label:SetText( txt )
end

function PANEL:PerformLayout()
	self.Label:SetPos(2,0)
	self.Label:SetSize( self:GetSize() )
end

function PANEL:Paint()
	draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self:GetBGColor() )
end

function PANEL:SetColor( clr )
	self.Label:SetColor( clr or Color(255,255,255,255) )
end

function PANEL:SetBGColor( clr )
	self._BGColor = clr
end

function PANEL:GetBGColor()
	return self._BGColor
end

derma.DefineControl( "Wire_WMenu_Label", "WMenu Label", PANEL, "DPanel" )

------------------------------------------------------------------------------------------------
-- Radio button
-- A radio button
------------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
    self:SetSize( 16, 16 )
    self:SetType("none")
    self.Partners = {}
end

function PANEL:Toggle()
    if (!self:GetChecked()) then
        for k,v in pairs( self.Partners ) do
            if (v == true) then
                k:SetValue(false)
                k:SetType("none")
            end
        end
        self:SetValue(true)
        self:SetType("none")
    end
end

function PANEL:Paint()
    draw.RoundedBox( 8, 0, 0, 16, 16, Color( 0,0,0,255 ) )
    draw.RoundedBox( 6, 2, 2, 12, 12, Color( 255,255,255,255 ) )
    if (self:GetChecked()) then
        draw.RoundedBox( 4, 4, 4, 8, 8, Color( 0,0,0,255 ) )
    end
end

--function PANEL:DrawBorder() end
--function PANEL:PaintOver() end
--function PANEL:ApplySchemeSettings() end
--function PANEL:Scheme() end

function PANEL:AddPartner( Partner )
    if (Partner.Button) then
        self.Partners[Partner.Button] = true
        if (Partner.Button.Partners[self] == nil) then Partner.Button:AddPartner( self ) end
    else
        self.Partners[Partner] = true
        if (Partner.Partners[self] == nil) then Partner:AddPartner( self ) end
    end
end

function PANEL:RemovePartner( Partner )
    if (Partner.Button) then
        self.Partners[Partner.Button] = nil
        if (Partner.Button.Partners[self] == true) then Partner.Button:RemovePartner( self ) end
    else
        self.Partners[Partner] = nil
        if (Partner.Partners[self] == true) then Partner.Button:RemovePartner( self ) end
    end
end

function PANEL:SetPartners( ... )
    local args = {...}
    table.insert( args, self )
    for k,v in ipairs( args ) do
        if (v.Button) then v.Button.Partners = {} else v.Partners = {} end
        for k2, v2 in ipairs( args ) do
            v:AddPartner( v2 )
        end
    end
end

derma.DefineControl( "DRadioButton", "Radio Button", PANEL, "DCheckBox" )

------------------------------------------------------------------------------------------------
-- Radio button label
-- A radio button with a label attached
------------------------------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
    self:SetTall( 18 )
    self.Button = vgui.Create("DRadioButton",self)
    function self:DoClick() self.Button:Toggle() end
	function self.Button.OnChange( _, val ) self:OnChange( val ) end
end

function PANEL:DoClick()
	self.Button:Toggle()
end

function PANEL:AddPartner( Partner )
    self.Button:AddPartner( Partner )
end

function PANEL:RemovePartner( Partner )
    self.Button:RemovePartner( Partner )
end

function PANEL:SetPartners( ... )
    self.Button:SetPartners( ... )
end

function PANEL:PerformLayout()
    local x = self.m_iIndent or 0
    self.Button:SetSize( 16, 16 )
    self.Button:SetPos( x, 0 )
    if (self.Label) then
        self.Label:SizeToContents()
        self.Label:SetPos( x + 16 + 10, 0 )
    end
end

function PANEL:SizeToContents()
	self.Label:SizeToContents()
	local w = self.Label:GetWide()
	self:SetSize( w + 32, 18 )
end

function PANEL:SetText( Text )
    if (!self.Label) then
        self.Label = vgui.Create("DLabel",self)
        self.Label:SetMouseInputEnabled(true)
        self.Label.OnMouseReleased = function() self.Button:Toggle() end
    end

    self.Label:SetText( Text )
    self:InvalidateLayout()
end

function PANEL:SetValue( val )
	if (self.Button:GetChecked() != val) then
		self.Button:Toggle()
	end
end
function PANEL:SetChecked( val )
	if (self.Button:GetChecked() != val) then
		self.Button:Toggle()
	end
end
function PANEL:GetChecked( val ) return self.Button:GetChecked() end
function PANEL:Toggle() self.Button:Toggle() end
function PANEL:Paint() end

derma.DefineControl( "DRadioButtonLabel", "Radio Button label", PANEL, "DPanel" )
