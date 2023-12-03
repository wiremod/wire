util.AddNetworkString( "wire_expression2_set_clipboard_text" )

__e2setcost(100)
e2function void setClipboardText(string text)
	-- The maximum allowed length of a single written string is 65532 characters while using net.WriteString
	-- See https://wiki.facepunch.com/gmod/net.WriteString

	-- This is probably more than sufficient for most people
	if string.len(text) > 65532 then return self:throw("Exceeded maximum string length for clipboard text", 0) end

	net.Start("wire_expression2_set_clipboard_text")
		net.WriteString(text)
	net.Send(self.player)
end