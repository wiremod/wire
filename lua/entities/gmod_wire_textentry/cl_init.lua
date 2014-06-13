include("shared.lua")
net.Receive("textentry_show",function()
	local self=net.ReadEntity()
	if !IsValid(self) then return end
	Derma_StringRequest(
		"Text Entry",
		"Please enter text below. Hit ENTER to send to the text entry.",
		"",
		function(text)
			net.Start("textentry_action")
				net.WriteEntity(self)
				net.WriteString("input")
				net.WriteString(text)
			net.SendToServer()
		end,
		function()
			net.Start("textentry_action")
				net.WriteEntity(self)
				net.WriteString("cancel")
			net.SendToServer()
		end,
		"ENTER","Cancel"
	)
end)