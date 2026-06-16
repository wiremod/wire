local PANEL = {}

local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine

local draw_SimpleText = draw.SimpleText

local gui_MouseY = gui.MouseY

function PANEL:Init()
    local base = self

    self.Files = {}

    self:Dock(BOTTOM)
    self:DockMargin(-2, -3, -2, -3)
    self:SetSize(24,28)

    self.Dragger = self:Add("DButton")
    self.Dragger:Dock(TOP)
    self.Dragger:SetSize(0,6)
    self.Dragger:SetText("")
    self.Dragger:SetCursor("sizens")

    self.Dragger.Held = false
    self.Dragger.MouseY = 0
    self.Dragger.OldSize = 192

    self.CollapseSize = 37
    self.PanelHeight = 192

    function self.Dragger:Paint(w, h)
        if self.Hovered or self.Held then
			local color = base.ValidationColorDragger
            surface_SetDrawColor(color.r, color.g, color.b, color.a)
        else
            surface_SetDrawColor(48, 48, 48, 255)
        end

        surface_DrawRect(0, 0, w, h)
    end

    function self.Dragger:Think()
        if not self.Held then
            if self.UnheldDueToCollapse then
                self.UnheldDueToCollapse = false
                self.Hovered = false
                base:SetTall(base.CollapseSize)
            end
            return
        end

        local sizing = self.MouseY - gui.MouseY()
        local tall_request = self.OldSize + sizing

        if tall_request > base.CollapseSize + 16 then
            base:Expand(true)
        else
            base:Collapse(true)
        end
        if not base.IsCollapsed then
            base:SetTall(self.OldSize + sizing)
        end
    end

    function self.Dragger:OnMousePressed(btn)
        if btn ~= MOUSE_LEFT then return end

        self.OldSize = base:GetTall()
        self.MouseY = gui_MouseY()

        self:MouseCapture(true)
        self.Held = true
    end

    function self.Dragger:OnMouseReleased(btn)
        if btn ~= MOUSE_LEFT then return end

        self:MouseCapture(false)
        self.Held = false
    end

    self.ValidationButton = self:Add("DButton")
    self.ValidationButton:SetText("")
    self.ValidationButton:Dock(TOP)
    self.ValidationButton:DockMargin(2, 0, 2, 0)
    self.ValidationButton:SetSize(0, 28)

    self.IssuesView = self:Add("DTree")
    self.IssuesView:Dock(FILL)
    self.IssuesView:DockMargin(2, 0, 2, 3)

    self.IssuesView:Hide()
    self.IssuesView.OldAddNode = self.IssuesView.AddNode
    function self.IssuesView:AddNode(text)
        local n = self:OldAddNode(text)
        n.Label:SetTextColor(color_white)
        n.Paint = function(node, w, h)
            if self:GetSelectedItem() == node then
                surface_SetDrawColor(100, 100, 100, 75)
                surface_DrawRect(0, 0, w, h)

                return
            end
            if node.Label.Hovered then
                surface_SetDrawColor(100, 100, 100, 25)
                surface_DrawRect(0, 0, w, h)
            end
        end
        n.Label.Paint = function(_, _, _) end
        return n
    end
	
    function self.IssuesView:Paint(w, h)
        surface_SetDrawColor(32, 32, 32)
        surface_DrawRect(0, 0, w, h)
    end

    self.ValidationText = "Code Validator"
    self:SetValidationColors(Color(180, 180, 180))

    self.OnMousePressed = nil

    self.ShowWhatPopupDoes = 0

    function self.ValidationButton:Paint(w, h)
        local validation_color

        if self.Hovered and not base.Dragger.Held then
            validation_color = base.ValidationColorHovered
        else
            validation_color = base.ValidationColorBackground
        end
		
        surface_SetDrawColor(validation_color.r, validation_color.g, validation_color.b, validation_color.a)
        surface_DrawRect(0, 0, w, h)
	
		local color = base.ValidationColorOutline
        surface_SetDrawColor(color.r, color.g, color.b, color.a)
        surface_DrawOutlinedRect(0, 0, w, h, 2)

        draw_SimpleText(base.ValidationText, "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        if base.ShowWhatPopupDoes > 0 then
            draw_SimpleText((base.IsCollapsed and "Show" or "Hide") .. " Code Problems", "DermaDefault", 36, h / 2, Color(255, 255, 255, base.ShowWhatPopupDoes * 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        end
    end

    function self.ValidationButton:OnMousePressed(btn)
        if base.OnMousePressed ~= nil then
            base:OnMousePressed(btn)
        end
    end

    function self.IssuesView:DoClick()
        if base.OnIssueClicked ~= nil then
            base:OnIssueClicked(self:GetSelectedItem())
        end
    end

    function self.IssuesView:DoRightClick(node)
        local menu = DermaMenu()

        menu:AddOption(
            "Copy to clipboard",
            function()
                SetClipboardText(node.Label:GetText())
            end
        )

        if node.quick_fix then
            menu:AddOption(
                "Quick fix",
                function()
                    base:OnQuickFix(node)
                end
            )
        end

        menu:Open()
    end

    self.TogglePopupButton = self.ValidationButton:Add("DButton")
    self.TogglePopupButton:Dock(LEFT)
    self.TogglePopupButton:SetSize(36, 0)
    self.TogglePopupButton:SetText("")
    self.IsCollapsed = true

    function self.TogglePopupButton:Paint(w, h)

        surface_SetDrawColor(255, 255, 255)
        local centerX, centerY = w / 2, h / 2
        local arrowWidth, arrowHeight = 6, 3 * (base.IsCollapsed and -1 or 1)

        surface_DrawLine(centerX - arrowWidth, centerY - arrowHeight, centerX, centerY + arrowHeight)
        surface_DrawLine(centerX + arrowWidth, centerY - arrowHeight, centerX, centerY + arrowHeight)
    end

    function self.TogglePopupButton:DoClick()
        base:Toggle()
    end
    function self.TogglePopupButton:Think()
        local isHovered = self:IsHovered() and 1 or -1
        base.ShowWhatPopupDoes = math.Clamp(base.ShowWhatPopupDoes + (0.025 * isHovered), 0, 1)
    end
end

function PANEL:Paint(w, h)

end
function PANEL:GetValue()
    return self.ValidationText
end

function PANEL:Collapse(triggered_by_drag)
    if self.IsCollapsed then return end

    if triggered_by_drag then
        self.Dragger.Held = false
        self.Dragger:MouseCapture(false)
        self.Dragger.UnheldDueToCollapse = true
    end
    self.Dragger.OldSize = self:GetTall()
    self:SetTall(self.CollapseSize)

    self.IssuesView:Hide()
    self.IsCollapsed = true
end
function PANEL:Expand(triggered_by_drag)
    if not self.IsCollapsed then return end

    self:SetTall(self.Dragger.OldSize)

    self.IssuesView:Show()
    self.IsCollapsed = false
end
function PANEL:Toggle()
    if self.IsCollapsed then
        self:Expand()
    else
        self:Collapse()
    end
end

function PANEL:SetValidationColors(color)
    self.ValidationColorBackground = color
    local h, s, v = ColorToHSV(color)

    self.ValidationColorOutline = HSVToColor(h, s, v / 1.2)
    self.ValidationColorHovered = HSVToColor(h, s, v + 0.073)
    self.ValidationColorDepressed = HSVToColor(h, s, v - 0.073)
    self.ValidationColorDragger = HSVToColor(h, s, v + 0.2)
end

function PANEL:SetText(text)
    self.ValidationText = text
end

function PANEL:SetBGColor(r, g, b, a)
    self:SetValidationColors(Color(r, g, b, a))
end

---@param errors Error[]
---@param warnings Warning[],
function PANEL:Update(errors, warnings, header_text, header_color)
    self.ValidationText = header_text or self.ValidationText
    if header_color ~= nil then self:SetValidationColors(header_color) end

    self.Errors = errors
    self.Warnings = warnings

    local tree = self.IssuesView
    tree:Clear()

    local failed = false

    if warnings ~= nil and not table.IsEmpty(warnings) then
        for _, v in ipairs(warnings) do
            if v.message ~= nil then
                local node = tree:AddNode(v.message .. (v.trace ~= nil and string.format(" [line %u, char %u]", v.trace.start_line, v.trace.start_col) or "") .. (v.quick_fix and " (Quick fix available)" or ""))
                node:SetIcon("icon16/error.png")
                node.trace = v.trace
                node.quick_fix = v.quick_fix
            end
        end
        failed = true
    end

    if errors ~= nil and not table.IsEmpty(errors) then
        for _, v in ipairs(errors) do
            local node = tree:AddNode(v.message .. (v.trace ~= nil and string.format(" [line %u, char %u]", v.trace.start_line, v.trace.start_col) or "") .. (v.quick_fix and " (Quick fix available)" or ""))
            node:SetIcon("icon16/cancel.png")
            node.trace = v.trace
            node.quick_fix = v.quick_fix
        end
        failed = true
    end

    if not failed then
        local node = tree:AddNode("No problems were found in the code.")
        node:SetIcon("icon16/accept.png")
    end
end

vgui.Register("Wire.IssueViewer", PANEL, "DPanel")
