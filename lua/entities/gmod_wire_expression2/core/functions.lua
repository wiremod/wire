-- Implements operators for E2 user-defined functions

__e2setcost(20)
registerOperator("function", "", "", function(self, args)

	local statement, args = args[2], args[3]
	local signature, returntype, parameters = args[3], args[4], args[6]

	self.funcs[signature] = function(self, arguments)
		-- First, evaluate each argument in the current (calling) scope
		local variables = {}
		for i, data in ipairs(parameters) do
			local name, expression = data[1], arguments[i + 1]
			local value = expression[1](self, expression)
			variables[name] = value
		end

		-- Then create a new scope for the body of the function, which consists only of the global
		-- variables (as a function can only be written in global scope) and bind each parameter name
		-- to the evaluated argument. (We don't have to call self:SetLocalVariableType here because the
		-- statement was already compiled in a scope with those set.)
		local OldScopes = self:SaveScopes()
		self:InitScope()
		self:PushScope()
		for name, value in pairs(variables) do
			self.Scope[name] = value
			self.Scope["$" .. name] = value
			self.Scope.vclk[name] = true
		end

		-- Then evaluate the statement to get the return value
		self.func_rv = nil
		local ok, message = pcall(statement[1], self, statement)

		self:LoadScopes(OldScopes) -- Restore the old scope before we throw any errors

		if ok then
			-- the statement executed without calling 'return'
			if returntype == '' then
				return -- which is okay only if the function has a void return type
			else
				error("Function " .. E2Lib.generate_signature(signature, nil, parameters) ..
				        " executed and didn't return a value - expecting a value of type " ..
				        E2Lib.typeName(returntype) .. "'", 0)
			end
		end

		if message == "return" then
			-- return instructions implement early-out with error("return")
			return self.func_rv
		elseif message:find("C stack overflow") then
			-- a 'C stack overflow' message typically means infinite recursion. To keep things simple for
			-- users we just phrase this as a regular tick quota error.
			message = "tick quota exceeded"
		end

		error(message, 0)
	end
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
