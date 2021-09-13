/******************************************************************************\
  Console support
\******************************************************************************/

E2Lib.RegisterExtension("console", true, "Lets E2 chips run concommands and retrieve convars")

local function tokenizeAndGetCommands(str)
	-- Tokenize!
	local tokens = {}
	local curtoken = {}
	local escaped = false
	for i=1, #str do
		local char = string.sub(str, i, i)
		if (escaped and char ~= "\"") or string.match(char, "[%w+-]") then
			curtoken[#curtoken + 1] = char
		else
			if #curtoken>0 then tokens[#tokens + 1] = table.concat(curtoken) curtoken = {} end
			if char == "\"" then
				escaped = not escaped
			elseif char ~= " " then
				tokens[#tokens + 1] = char
			end
		end
	end
	if #curtoken>0 then tokens[#tokens+1] = table.concat(curtoken) end

	-- Get table of commands used
	local commands = {tokens[1] or ""}
	for i=1, #tokens do
		if tokens[i]==";" then
			commands[#commands + 1] = tokens[i+1] or ""
		end
	end

	return commands
end

local function validConCmd(self, command)
	local ply = self.player
	if not ply:IsValid() then return false end
	if ply:GetInfoNum("wire_expression2_concmd", 0) == 0 then return self:throw("Concmd is disabled through wire_expression2_concmd", false) end
	-- Validating the concmd length to ensure that it won't crash the server. 512 is the max
	if #command >= 512 then return self:throw("Concommand/Var is too long!", false) end

	local whitelist = (ply:GetInfo("wire_expression2_concmd_whitelist") or ""):Trim()
	if whitelist == "" then return true end

	local whitelistTbl = {}
	for k, v in pairs(string.Split(whitelist, ",")) do whitelistTbl[v] = true end

	local commands = tokenizeAndGetCommands(command)
	for _, command in pairs(commands) do
		if not whitelistTbl[command] then
			return false
		end
	end
	return true
end


__e2setcost(5)

e2function number concmd(string command)
	if not validConCmd(self, command) then return self:throw("Invalid concommand", 0) end
	self.player:ConCommand(command:gsub("%%", "%%%%"))
	return 1
end

e2function string convar(string cvar)
	if not validConCmd(self, cvar) then return self:throw("Invalid convar", "") end
	return self.player:GetInfo(cvar) or ""
end

e2function number convarnum(string cvar)
	if not validConCmd(self, cvar) then return self:throw("Invalid convar", 0) end
	return self.player:GetInfoNum(cvar, 0)
end

e2function number maxOfType(string typename)
	if typename == "wire_holograms" then return GetConVarNumber("wire_holograms_max") or 0 end
	return GetConVarNumber("sbox_max"..typename) or 0
end

e2function number playerDamage()
	local ret = GetConVarNumber("sbox_playershurtplayers") or 0
	return ret ~= 0 and 1 or 0
end
