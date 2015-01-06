CreateClientConVar( "wire_expression2_print_max", 15, true, true )
CreateClientConVar( "wire_expression2_print_delay", 0.3, true, true )

local chips = {}

hook.Add("EntityRemoved", "wire_expression2_printColor", function(ent)
	chips[ent] = nil
end)

net.Receive("wire_expression2_printColor", function( len, ply )
	local chip = net.ReadEntity()
	if chip and not chips[chip] then
		chips[chip] = true
		-- printColorDriver is used for the first time on us by this chip
		WireLib.AddNotify(msg1, NOTIFY_GENERIC, 7, NOTIFYSOUND_DRIP3)
		WireLib.AddNotify(msg2, NOTIFY_GENERIC, 7)
		chat.AddText(Color(255,0,0),"While in somone's seat/car/whatever, printColorDriver can be used to 100% realistically fake people talking, including admins.")
		chat.AddText(Color(255,0,0),"Don't trust a word you hear while in a seat after seeing this message!")
	end
	
	chat.AddText(unpack(net.ReadTable()))
end)
