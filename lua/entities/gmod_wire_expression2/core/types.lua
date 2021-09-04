--[[============================================================
	E2 User Defined Types by Vurv
============================================================]]--

__e2setcost(1)
registerOperator("type", "", "", function(self, args)
	local name, fields = args[2], args[3]
	self.types[name] = fields
end)