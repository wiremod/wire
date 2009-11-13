/******************************************************************************\
  Console support
\******************************************************************************/

E2Lib.RegisterExtension("console", true)

local function validConCmd(self, command)
	local ply = self.player
	if not ply:IsValid() then return false end
	if ply:GetInfoNum("wire_expression2_concmd") == 0 then return false end


	local whitelist = (ply:GetInfo("wire_expression2_concmd_whitelist") or ""):Trim()
	if whitelist == "" then return true end

	command = command.." "
	for _,whitelist_element in ipairs(string.Explode(",",whitelist)) do
		whitelist_element = whitelist_element:Trim().." "
		if whitelist_element == command:sub(1,whitelist_element:len()) then return true end
	end
	return false
end

--[[
e2function trace(string message)
	self.player:Msg(message .. "\n")
end
]]

e2function number concmd(string command)
	if not validConCmd(self, command) then return 0 end
	self.player:ConCommand(command)
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
	local ret = self.player:GetInfoNum(cvar)
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
