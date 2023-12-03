E2Helper.Descriptions["setClipboardText(s)"] = "Adds the given string to the computers clipboard. Can not exceed 65532 characters"

net.Receive("wire_expression2_set_clipboard_text", function(len, ply)
	SetClipboardText(net.ReadString())
end)