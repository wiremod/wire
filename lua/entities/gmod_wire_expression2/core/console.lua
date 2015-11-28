/******************************************************************************\
  Console support
\******************************************************************************/

E2Lib.RegisterExtension("console", true, "Lets E2 chips run concommands and retrieve convars")

local function validConCmd(self, command)
	local ply = self.player
	if not ply:IsValid() then return false end
	if ply:GetInfoNum("wire_expression2_concmd", 0) == 0 then return false end

	local whitelist = (ply:GetInfo("wire_expression2_concmd_whitelist") or ""):Trim()
	if whitelist == "" then return true end

	for cmd in command:gmatch( "[^;]+" ) do -- Split around ; and space
		cmd = cmd:match( "[^%s]+" ) -- Get everything up to the first space
		local found = false
		for whitelist_element in whitelist:gmatch( "[^,]+" ) do -- Split around ,
			if (cmd == whitelist_element) then -- This command is in the whitelist
				found = true
				break
			end
		end
		if (!found) then return false end -- If the command is not in the whitelist, return false
	end
	return true
end


__e2setcost(5)

e2function number concmd(string command)
	if not validConCmd(self, command) then return 0 end
	self.player:ConCommand(command:gsub("%%", "%%%%"))
	return 1
end

e2function string convar(string cvar)
	if not validConCmd(self, cvar) then return "" end
	local ret = self.player:GetInfo(cvar)
	if not ret then return "" end
	return ret
end

e2function number convarnum(string cvar)
	if not validConCmd(self, cvar) then return 0 end
	local ret = self.player:GetInfoNum(cvar, 0)
	if not ret then return 0 end
	return ret
end

e2function number maxOfType(string typename)
	if typename == "wire_holograms" then return GetConVarNumber("wire_holograms_max") or 0 end
	return GetConVarNumber("sbox_max"..typename) or 0
end

e2function number playerDamage()
	local ret = GetConVarNumber("sbox_plpldamage") or 0
	return ret ~= 0 and 1 or 0
end
