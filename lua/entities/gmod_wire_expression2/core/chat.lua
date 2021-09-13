-- Original author: ZeikJT
-- Modified by Gwahir and TomyLobo

local IsValid = IsValid

local TextList = {
	last = { "", 0, nil }
}
local ChatAlert = {}
local chipHideChat = false

--[[************************************************************************]]--

registerCallback("destruct",function(self)
	ChatAlert[self.entity] = nil
end)

hook.Add("PlayerSay","Exp2TextReceiving", function(ply, text, teamchat)
	local entry = { text, CurTime(), ply, teamchat }
	TextList[ply:EntIndex()] = entry
	TextList.last = entry

	chipHideChat = false
	local hideCurrent = false
	for e,_ in pairs(ChatAlert) do
		if IsValid(e) then
			chipHideChat = nil
			e.context.data.runByChat = entry
			e:Execute()
			e.context.data.runByChat = nil
			--if chipHideChat ~= nil and ply == e.player then
			if chipHideChat and ply == e.player then
				hideCurrent = chipHideChat
			end
		else
			ChatAlert[e] = nil
		end
	end

	if hideCurrent then return "" end
end)

hook.Add("EntityRemoved","Exp2ChatPlayerDisconnect", function(ply)
	TextList[ply:EntIndex()] = nil
end)

--[[************************************************************************]]--
__e2setcost(3)

--- If <activate> == 0, the chip will no longer run on chat events, otherwise it makes this chip execute when someone chats. Only needs to be called once, not in every execution.
e2function void runOnChat(activate)
	if activate ~= 0 then
		ChatAlert[self.entity] = true
	else
		ChatAlert[self.entity] = nil
	end
end

--- Returns 1 if the chip is being executed because of a chat event. Returns 0 otherwise.
e2function number chatClk()
	return self.data.runByChat and 1 or 0
end

--- Returns 1 if the chip is being executed because of a chat event by player <ply>. Returns 0 otherwise.
e2function number chatClk(entity ply)
	if not IsValid(ply) then return self:throw("Invalid player!", 0) end
	local cause = self.data.runByChat
	return cause and cause[3] == ply and 1 or 0
end

--- If <hide> != 0, hide the chat message that is currently being processed.
e2function void hideChat(hide)
	chipHideChat = hide ~= 0
end

--[[************************************************************************]]--

--- Returns the last player to speak.
e2function entity lastSpoke()
	local entry = TextList.last
	if not entry then return nil end

	local ply = entry[3]
	if not IsValid(ply) then return nil end
	if not ply:IsPlayer() then return nil end

	return ply
end

--- Returns the last message in the chat log.
e2function string lastSaid()
	local entry = TextList.last
	if not entry then return "" end

	return entry[1]
end

--- Returns the time the last message was sent.
e2function number lastSaidWhen()
	local entry = TextList.last
	if not entry then return 0 end

	return entry[2]
end

--- Returns 1 if the last message was sent in the team chat, 0 otherwise.
e2function number lastSaidTeam()
	local entry = TextList.last
	if not entry then return 0 end

	return entry[4] and 1 or 0
end

--- Returns what the player <this> last said.
e2function string entity:lastSaid()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if not this:IsPlayer() then return self:throw("Not a player", "") end

	local entry = TextList[this:EntIndex()]
	if not entry then return "" end

	return entry[1]
end

--- Returns when the given player last said something.
e2function number entity:lastSaidWhen()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Not a player", 0) end

	local entry = TextList[this:EntIndex()]
	if not entry then return 0 end

	return entry[2]
end

--- Returns 1 if the last message was sent in the team chat, 0 otherwise.
e2function number entity:lastSaidTeam()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Not a player", 0) end

	local entry = TextList[this:EntIndex()]
	if not entry then return 0 end

	return entry[4] and 1 or 0
end
