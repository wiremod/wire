include('shared.lua')
include("remap.lua") -- For stools/keyboard.lua's layout selector

net.Receive("wire_keyboard_blockinput", function(netlen)
	if net.ReadBit() ~= 0 then
		hook.Add("PlayerBindPress", "wire_keyboard_blockinput", function(ply, bind, pressed)
			-- return true for all keys except the mouse, to block keyboard actions while typing
			if bind == "+attack" then return nil end
			if bind == "+attack2" then return nil end

			return true
		end)
	else
		hook.Remove("PlayerBindPress", "wire_keyboard_blockinput")
	end
end)

net.Receive("wire_keyboard_activatemessage", function(netlen)
	local pod = net.ReadBit() ~= 0

	local leaveKey = LocalPlayer():GetInfoNum("wire_keyboard_leavekey", KEY_LALT)
	local leaveKeyName = string.upper(input.GetKeyName(leaveKey))

	local text
	if pod then
		text = "This pod is linked to a keyboard - press " .. leaveKeyName .. " to leave."
	else
		text = "Keyboard turned on - press " .. leaveKeyName .. " to leave."
	end

	chat.AddText(text)
end)
