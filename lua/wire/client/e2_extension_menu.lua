hook.Add("PopulateToolMenu", "AddAddWireAdminControlPanelMenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "Admin", "WireE2Extensions", "E2 Extensions", "", "", function(panel)
		local allowed = LocalPlayer():IsSuperAdmin()

		if not allowed then
			local permissionNotice = panel:Help("You are not a superadmin - you cannot change these settings, only view them.")
			permissionNotice:SetColor(Color(153, 51, 0))
		end

		for _, name in ipairs(E2Lib.GetExtensions()) do
			local item = vgui.Create("DListLayout", panel)
			item:DockPadding(5, 5, 5, 5)
			item:SetPaintBackground(true)
			panel:AddItem(item)

			local checkbox = vgui.Create("DCheckBoxLabel", item)
			checkbox.Button:SetDisabled(not allowed)
			checkbox:SetChecked(E2Lib.GetExtensionStatus(name))
			checkbox:SetText(name)
			checkbox:SetDark(true)
			checkbox:SizeToContents()

			function checkbox:OnChange(value)
				RunConsoleCommand(value and "wire_expression2_extension_enable" or "wire_expression2_extension_disable", name)
			end

			if allowed then
				function item:OnMouseReleased()
					checkbox:Toggle()
				end
			end

			local documentation = E2Lib.GetExtensionDocumentation(name)

			if documentation.Description then
				local description = Label(documentation.Description, item)
				description:DockMargin(40, 5, 5, 5)
				description:SetWrap(true)
				description:SetDark(true)
				description:SetAutoStretchVertical(true)
				description:SetFont("DermaDefault")
			end

			-- Only display warnings to admins (as they're usually about ways that players could exploit an E2 extension)
			if allowed and documentation.Warning then
				local warning = Label(documentation.Warning, item)
				warning:DockMargin(40, 5, 5, 5)
				warning:SetWrap(true)
				warning:SetTextColor(Color(153, 51, 0))
				warning:SetAutoStretchVertical(true)
				warning:SetFont("DermaDefaultBold")
			end
		end
	end)
end)
