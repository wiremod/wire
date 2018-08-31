--[[============================================================
	E2 Function System
		By Rusketh
			General Operators
============================================================]]--

__e2setcost(1)

registerOperator("function", "", "", function(self, args)
	local sig, body = args[2], args[3]
	self.funcs[sig] = body
	self.strfunc_cache = {}
end)

__e2setcost(2)

registerOperator("return", "", "", function(self, args)
	if args[2] then
		local op = args[2]
		local rv = op[1](self, op)
		self.func_rv = rv
	end

	error("return",0)
end)
