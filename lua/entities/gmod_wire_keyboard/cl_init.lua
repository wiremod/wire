include('shared.lua')
include("remap.lua") -- For stools/keyboard.lua's layout selector

net.Receive("wire_keyboard_blockinput", function(netlen)
	if net.ReadBit() ~= 0 then 
		hook.Add("PlayerBindPress", "wire_keyboard_blockinput", function(ply, bind, pressed) return true end)
	else
		hook.Remove("PlayerBindPress", "wire_keyboard_blockinput")
	end
end)