include('shared.lua')
include("remap.lua") -- For stools/keyboard.lua's layout selector

net.Receive("wire_keyboard_blockinput", function(netlen)
	if net.ReadBit() ~= 0 then 
		hook.Add("PlayerBindPress", "wire_keyboard_blockinput", function(ply, bind, pressed) 
			return (bind ~= "+attack" and bind ~= "+attack2") or nil -- true for all keys except the mouse, to block keyboard actions while typing
		end)
	else
		hook.Remove("PlayerBindPress", "wire_keyboard_blockinput")
	end
end)

net.Receive("wire_keyboard_activatemessage", function(netlen)
	local pod = net.ReadBit() ~= 0
	local keyName = string.upper(input.GetKeyName(net.ReadUInt(16)))

	if pod then
		chat.AddText( "This pod is linked to a keyboard - press " .. keyName .. " to leave." )
	else
		chat.AddText( "Keyboard turned on - press " .. keyName .. " to leave." )
	end
end)
