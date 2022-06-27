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

---@param cmd_var "cmd"|"var"
---@return boolean override # Whether the user set their whitelist to "" (allow everything)
---@return table whitelist # Whitelist for specific commands otherwise.
local function getWhitelist(ply, cmd_var)
	local whitelist = (ply:GetInfo("wire_expression2_con" .. cmd_var .. "_whitelist") or ""):Trim()
	if whitelist == "" then return true end

	local whitelistTbl = {}
	for k, v in pairs(string.Split(whitelist, ",")) do
		whitelistTbl[v] = true
	end
	return false, whitelistTbl
end

local function checkConCmd(self, cmd)
	local ply = self.player
	if not ply:IsValid() then return self:throw("Invalid chip owner to run console command", false) end

	-- Validating the concmd length to ensure that it won't crash the server. 512 is the max
	if #cmd >= 512 then return self:throw("Concmd is too long!", false) end

	if ply:GetInfoNum("wire_expression2_concmd", 0) == 0 then return self:throw("Concmd is disabled through wire_expression2_concmd", false) end
	if IsConCommandBlocked(command) then return self:throw("This concmd is blacklisted by gmod, see https://wiki.facepunch.com/gmod/Blocked_ConCommands", false) end

	local override, whitelist = getWhitelist(ply, "cmd")
	if override then return true end

	local commands = tokenizeAndGetCommands(cmd)
	for _, command in pairs(commands) do
		if not whitelist[command] then
			return self:throw("Command '" .. command "' is not whitelisted w/ wire_expression2_concmd_whitelist", false)
		end
	end

	return true
end

local function checkConVar(self, var)
	local ply = self.player
	if not ply:IsValid() then return self:throw("Invalid chip owner to check convar", false) end

	if #var >= 512 then return self:throw("Convar is too long!", false) end
	if ply:GetInfoNum("wire_expression2_convar", 0) == 0 then return self:throw("Convar is disabled through wire_expression2_convar", false) end
	var = var:match("%s*([%w_]+)%s*")

	local override, whitelist = getWhitelist(ply, "var")
	if override then return true end

	if whitelist[var] == nil then return self:throw("Convar '" .. var .. "' is not whitelisted w/ wire_expression2_convar_whitelist ", false) end
	return true
end


__e2setcost(5)

e2function number concmd(string command)
	if not checkConCmd(self, command) then return 0 end
	self.player:ConCommand(command:gsub("%%", "%%%%"))
	return 1
end

e2function string convar(string cvar)
	if not checkConVar(self, cvar) then return "" end
	return self.player:GetInfo(cvar) or ""
end

e2function number convarnum(string cvar)
	if not checkConVar(self, cvar) then return 0 end
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
