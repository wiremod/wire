include('shared.lua')
include("remap.lua") -- For stools/keyboard.lua's layout selector

net.Receive("wire_keyboard_blockinput", function(netlen)
	if net.ReadBit() ~= 0 then
		hook.Add("StartChat", "wire_keyboard_startchatoverride", function(teamChat)
			return true
		end)
		hook.Add("PlayerBindPress", "wire_keyboard_blockinput", function(ply, bind, pressed)
			-- return true for all keys except the mouse, to block keyboard actions while typing
			if bind == "+attack" then return nil end
			if bind == "+attack2" then return nil end

			return true
		end)
	else
		hook.Remove("StartChat", "wire_keyboard_startchatoverride")
		hook.Remove("PlayerBindPress", "wire_keyboard_blockinput")
	end
end)

local panel

local function hideMessage()
	if not panel then return end

	panel:Remove()
	panel = nil
end

net.Receive("wire_keyboard_activatemessage", function(netlen)
	local on = net.ReadBit() ~= 0

	hideMessage()

	if not on then return end

	local pod = net.ReadBit() ~= 0

	local leaveKey = LocalPlayer():GetInfoNum("wire_keyboard_leavekey", KEY_LALT)
	local leaveKeyName = string.upper(input.GetKeyName(leaveKey))

	local text
	if pod then
		text = "This pod is linked to a Wire Keyboard - press " .. leaveKeyName .. " to leave."
	else
		text = "Wire Keyboard turned on - press " .. leaveKeyName .. " to leave."
	end

	panel = vgui.Create("DShape") -- DPanel is broken for small sizes
	panel:SetColor(Color(0, 0, 0, 192))
	panel:SetType("Rect")

	local label = vgui.Create("DLabel", panel)
	label:SetText(text)
	label:SizeToContents()

	local padding = 3
	label:SetPos(2 * padding, 2 * padding)
	panel:SizeToChildren(true, true)
	label:SetPos(padding, padding)

	panel:CenterHorizontal()
	panel:CenterVertical(0.95)
end)
