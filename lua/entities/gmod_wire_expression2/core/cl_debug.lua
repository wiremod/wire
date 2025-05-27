CreateClientConVar( "wire_expression2_print_max", 15, true, true )
CreateClientConVar( "wire_expression2_print_max_length", 1000, true, true )
CreateClientConVar( "wire_expression2_print_delay", 0.3, true, true )
local cvar_warn = CreateClientConVar("wire_expression2_printcolor_warn", 1, true, true, "Shows a warning when someone uses printColorDriver on you")

local not_warned = not game.SinglePlayer()

local RED = Color(255, 0, 0)

local printcolor_readers = {
	[1] = function() return tostring(net.ReadDouble()) end,
	[2] = function() return net.ReadString() end,
	[3] = function() return net.ReadColor(false) end,
	[4] = function()
		local e = net.ReadEntity() -- Passing directly will set color as the player's color which isn't desirable I believe
		return e:IsValid() and (e:IsPlayer() and e:GetName() or e:GetClass()) or "NULL" -- Also, MsgC doesn't have this feature, so adds parity
	end
}

net.Receive("wire_expression2_printColor", function()
	local ply = net.ReadPlayer()
	local console = net.ReadBool()

	local msg = {}

	for i = 1, 1024 do
		local reader = printcolor_readers[net.ReadUInt(4)]
		if not reader then break end
		msg[i] = reader()
	end

	if console then
		MsgC(unpack(msg))
	else
		if not_warned and ply ~= LocalPlayer() then
			not_warned = false
			if cvar_warn:GetBool() then
				chat.AddText(RED, "While in somone's seat/car/whatever, printColorDriver can be used to 100% realistically fake people talking, including admins.\
Don't trust a word you hear while in a seat after seeing this message!")
			end
		end
		chat.AddText(unpack(msg))
	end
end)

net.Receive("wire_expression2_print", function()
	chat.AddText(net.ReadString())
end)

CreateClientConVar("wire_expression2_clipboard_allow", 0, true, true, "Allow E2 to set your clipboard text", 0, 1)

net.Receive("wire_expression2_set_clipboard_text", function(len, ply)
	SetClipboardText(net.ReadString())
end)

net.Receive("wire_expression2_caption", function()
	gui.AddCaption(net.ReadData(net.ReadUInt(16)), net.ReadDouble(), net.ReadBool())
end)