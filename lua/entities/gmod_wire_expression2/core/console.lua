--
-- Console support
--

E2Lib.RegisterExtension("console", true, "Lets E2 chips run concommands and retrieve convars")

local function tokenizeAndGetCommands(concmd)
	local null = string.find(concmd, "\0", 1, true)

	if null then
		concmd = string.sub(concmd, 1, null - 1)
	end

	if string.find(concmd, "[\1-\8\14-\31\127]") then
		return nil, "unsupported control characters"
	end

	local commands = {}
	concmd = string.gsub(concmd, "[\t\v\f\r]", " ")

	for line in string.gmatch(concmd .. "\n", "([^\n]*)\n") do
		local segments = {}
		local start = 1
		local stop = #line
		local in_quotes

		for i = 1, stop do
			local c = string.byte(line, i)

			if c == 34 then -- "
				in_quotes = not in_quotes
			elseif not in_quotes then
				if c == 59 then -- ;
					table.insert(segments, string.sub(line, start, i - 1))
					start = i + 1
				elseif c == 47 and string.byte(line, i + 1) == 47 then -- //
					stop = i - 1
					break
				end
			end
		end

		if in_quotes then return nil, "unbalanced quotes" end
		table.insert(segments, string.sub(line, start, stop))

		for _, seg in ipairs(segments) do
			seg = string.match(seg, "^ *(.*)$")

			local name

			if string.byte(seg, 1) == 34 then -- "
				name = string.match(seg, "^\"([^\"]*)")
			else
				name = string.match(seg, "^[{}()':]") or string.match(seg, "^[^ \"{}()':]+")
			end

			if name and name ~= "" then
				if string.find(name, "[\128-\255]") then return nil, "non-ASCII command name" end
				table.insert(commands, string.lower(name))
			end
		end
	end

	return commands
end

---@param cvar "wire_expression2_concmd_whitelist"|"wire_expression2_convar_whitelist"
---@return table whitelist # Whitelist for specific commands, if empty, disregard whitelist and allow everything
local function getWhitelist(ply, cvar)
	local whitelist = {}

	for _, v in ipairs(string.Split(WireLib.Trim(ply:GetInfo(cvar)), ",")) do
		v = string.lower(string.Trim(v))

		if v ~= "" then
			whitelist[v] = true
		end
	end

	return whitelist
end

local function checkConCmd(self, cmd)
	local ply = self.player
	if not ply:IsValid() then return self:throw("Invalid chip owner to run console command", false) end
	if #cmd >= 512 then return self:throw("Concmd is too long!", false) end

	if ply:GetInfoNum("wire_expression2_concmd", 0) == 0 then return self:throw("Concmd is disabled through wire_expression2_concmd", false) end

	local commands, err = tokenizeAndGetCommands(cmd)
	if commands and #commands == 0 then return self:throw("Concmd is empty", false) end

	if IsConCommandBlocked(cmd) then return self:throw("This concmd is blacklisted by gmod, see https://wiki.facepunch.com/gmod/Blocked_ConCommands", false) end

	if hook.Run("Expression2_CanConCmd", ply, cmd) == false then
        return self:throw("Command '" .. cmd .. "' was blocked by the server. ", false)
    end

	local whitelist = getWhitelist(ply, "wire_expression2_concmd_whitelist")
	if table.IsEmpty(whitelist) then return true end

	if not commands then
		return self:throw("Command cannot be checked against wire_expression2_concmd_whitelist: " .. err, false)
	end

	for _, command in ipairs(commands) do
		if not whitelist[command] then
			return self:throw("Command '" .. command .. "' is not whitelisted in wire_expression2_concmd_whitelist", false)
		end
	end

	return true
end

local function checkConVar(self, var)
	local ply = self.player
	if not ply:IsValid() then return self:throw("Invalid chip owner to check convar", false) end

	if #var >= 512 then return self:throw("Convar is too long!", false) end
	if ply:GetInfoNum("wire_expression2_convar", 0) == 0 then return self:throw("Convar is disabled through wire_expression2_convar", false) end
	if not string.find(var, "^[%w_]+$") then return self:throw("Invalid convar name", false) end

	if hook.Run("Expression2_CanConVar", ply, var) == false then
        return self:throw("Convar '" .. var .. "' was blocked by the server. ", false)
    end

	local whitelist = getWhitelist(ply, "wire_expression2_convar_whitelist")
	if table.IsEmpty(whitelist) then return true end

	if whitelist[string.lower(var)] == nil then
		return self:throw("Convar '" .. var .. "' is not whitelisted in wire_expression2_convar_whitelist ", false)
	end

	return true
end

__e2setcost(5)

e2function number concmd(string command)
	if not checkConCmd(self, command) then return 0 end
	self.player:ConCommand(string.gsub(command, "%%", "%%%%"))
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
	if typename == "wire_holograms" then return cvars.Number("wire_holograms_max", 0) end
	return cvars.Number("sbox_max" .. typename, 0)
end

e2function number playerDamage()
	return cvars.Bool("sbox_playershurtplayers") and 1 or 0
end
