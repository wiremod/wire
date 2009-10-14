/******************************************************************************\
  Console support
\******************************************************************************/

E2Lib.RegisterExtension("console", true)

local function validConCmd(self)
	if not self.player:IsValid() then return false end
	return self.player:GetInfoNum("wire_expression2_concmd") ~= 0
end

--[[
e2function trace(string message)
	self.player:Msg(message .. "\n")
end
]]

e2function number concmd(string command)
	if not validConCmd(self) then return 0 end
	self.player:ConCommand(command)
	return 1
end

e2function string convar(string cvar)
	if not validConCmd(self) then return "" end
	local ret = self.player:GetInfo(cvar)
	if not ret then return "" end
	return ret
end

e2function number convarnum(string cvar)
	if not validConCmd(self) then return 0 end
	local ret = self.player:GetInfoNum(cvar)
	if not ret then return 0 end
	return ret
end
