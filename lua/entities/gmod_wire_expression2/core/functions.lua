-- Implements operators for E2 user-defined functions

local function Function(parameters, statement)

	local Func = function(self, args)

		local variables = {}
		for i, data in pairs(parameters) do
			local name, expression = data[1], args[i + 1]
			local value = expression[1](self, expression)
			variables[#variables + 1] = { name, value }
		end

		local OldScopes = self:SaveScopes()
		self:InitScope() -- Create a new Scope Enviroment
		self:PushScope()

		for I = 1, #variables do
			local Var = variables[I]
			self.Scope[Var[1]] = Var[2]
			self.Scope["$" .. Var[1]] = Var[2]
			self.Scope.vclk[Var[1]] = true
		end

		self.func_rv = nil
		local ok, message = pcall(statement[1], self, statement)

		self:PopScope()
		self:LoadScopes(OldScopes)

		if !ok and message:find("C stack overflow") then
			-- a "C stack overflow" error will probably just confuse E2 users more than a "tick quota" error.
			error("tick quota exceeded", -1)
		end

		if !ok and message == "return" then
			return self.func_rv
		end

		if !ok then
			error(message, 0)
		end

	end

	return Func
end

__e2setcost(20)
registerOperator("function", "", "", function(self, args)

	local statement, args = args[2], args[3]
	local signature, returntype, parameters = args[3], args[4], args[6]

	self.funcs[signature] = Function(parameters, statement)

end)

__e2setcost(2)
registerOperator("return", "", "", function(self, args)
	if args[2] then
		local op = args[2]
		local rv = op[1](self, op)
		self.func_rv = rv
	end

	error("return", 0)
end)
