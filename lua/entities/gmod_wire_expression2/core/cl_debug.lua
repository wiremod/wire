local chips = {}

hook.Add("EntityRemoved", "wire_expression2_printColor", function(ent)
	chips[ent] = nil
end)

local msg1 = "While in somone's seat/car/whatever, printColorDriver can be used to 100% realistically fake people talking, including admins."
local msg2 = "Don't trust a word you hear while in a seat after seeing this message!"

datastream.Hook("wire_expression2_printColor", function( ply, handle, id, printinfo )
	local chip = printinfo.chip
	if chip and not chips[chip] then
		chips[chip] = true
		-- printColorDriver is used for the first time on us by this chip
		WireLib.AddNotify(msg1, NOTIFY_GENERIC, 7, NOTIFYSOUND_DRIP3)
		WireLib.AddNotify(msg2, NOTIFY_GENERIC, 7)
		chat.AddText(Color(255,0,0),msg1)
		chat.AddText(Color(255,0,0),msg2)
	end

	chat.AddText(unpack(printinfo))
end)
