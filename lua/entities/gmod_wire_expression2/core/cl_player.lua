local function SendFriendStatus()
	local friends = {}
	for _,ply in ipairs(player.GetHumans()) do
		if ply:GetFriendStatus() == "friend" then
			table.insert(friends, ply:EntIndex())
		end
	end
	RunConsoleCommand("wire_expression2_friend_status", table.concat(friends, ","))
end

if CanRunConsoleCommand() then
	SendFriendStatus()
end
hook.Add("OnEntityCreated", "wire_expression2_extension_player", function(ent)
	if not IsValid(ent) then return end
	if not ent:IsPlayer() then return end

	SendFriendStatus()
end)

-- isTyping
hook.Add("StartChat","E2_IsTyping_Start",function() RunConsoleCommand("E2_StartChat") end)
hook.Add("FinishChat","E2_IsTyping_Finish",function() RunConsoleCommand("E2_FinishChat") end)
hook.Add("ShutDown", "E2_FinishChat_Remove", function()
    hook.Remove("FinishChat", "E2_IsTyping_Finish")
end)
