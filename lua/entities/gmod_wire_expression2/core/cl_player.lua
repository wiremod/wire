local function SendFriendStatus()
	local friends = {}

	for _, ply in ipairs(player.GetHumans()) do
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
