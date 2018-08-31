-- the names of the concommands used to enable/disable extensions
-- (with a trailing space so we can concatenate extension names straight on)
local CONCOMMAND_NAMES = {
  [false] = "wire_expression2_extension_disable ",
  [true] = "wire_expression2_extension_enable "
}

-- the same parameters as DermaDefault, but with italic=true
surface.CreateFont("DermaDefaultItalic", {
  font = system.IsLinux() and "DejaVu Sans" or "Tahoma",
  size = system.IsLinux() and 14 or 13,
  italic = true,
})

local function BuildExtensionMenu(panel)
  local allowed = LocalPlayer():IsSuperAdmin()

  if not allowed then
    local permissionNotice = panel:Help("You are not a superadmin - you cannot change these settings, only view them.")
    permissionNotice:SetColor(Color(153, 51, 0, 255))
  end

  for _, name in pairs(E2Lib.GetExtensions()) do
    local item = vgui.Create("DListLayout", panel)
    item:DockPadding(5, 5, 5, 5)
    item:SetPaintBackground(true)

    panel:AddItem(item)

    local checkbox = vgui.Create("DCheckBoxLabel", item)
    checkbox:SetText(name)
    checkbox:SetChecked(E2Lib.GetExtensionStatus(name))
    checkbox.Button:SetDisabled(not allowed)
    checkbox:SizeToContents()
    checkbox:SetDark(true)
    function checkbox:OnChange(value)
      LocalPlayer():ConCommand(CONCOMMAND_NAMES[value] .. name)
    end

    if allowed then
      function item:OnMouseReleased() checkbox:Toggle() end
    end

    local documentation = E2Lib.GetExtensionDocumentation(name)
    if documentation.Description then
      local description = Label(documentation.Description, item)
      description:DockMargin(40, 5, 5, 5)
      description:SetWrap(true)
      description:SetDark(true)
      description:SetAutoStretchVertical(true)
      description:SetFont("DermaDefaultItalic")
    end

    -- only display warnings to admins (as they're usually about ways that
    -- players could exploit an E2 extension). Yes, this is a bit paranoid.
    if allowed and documentation.Warning then
      local warning = Label(documentation.Warning, item)
      warning:DockMargin(40, 5, 5, 5)
      warning:SetWrap(true)
      warning:SetTextColor(Color(153, 51, 0))
      warning:SetAutoStretchVertical(true)
      warning:SetFont("DermaDefaultBold")
    end
  end
end

hook.Add("PopulateToolMenu", "AddAddWireAdminControlPanelMenu", function()
  spawnmenu.AddToolMenuOption("Utilities", "Admin", "WireE2Extensions", "E2 Extensions", "", "", BuildExtensionMenu, {})
end)
