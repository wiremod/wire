/*==============================================================
	E2 Function System
		By Rusketh
			Function Creator
==============================================================*/

local function Function(A,S,Scopes)

	local Func = function(self,args)

		local Variables = {}
		for K,Data in pairs (A) do
			local Name, Type, OP = Data[1], Data[2], args[K + 1]
			local RV = OP[1](self, OP)
			Variables[#Variables + 1] = {Name,RV}
		end

		local OldScopes = self:SaveScopes()
		self:InitScope() -- Create a new Scope Enviroment
		self:PushScope()

		for I = 1, #Variables do
			local Var = Variables[I]
			self.Scope[Var[1]] = Var[2]
			self.Scope["$" .. Var[1]] = Var[2]
			self.Scope.vclk[Var[1]] = true
		end

		self.func_rv = nil
		local ok, msg = pcall(S[1],self,S)

		self:PopScope()
		self:LoadScopes(OldScopes)

		if !ok and msg:find( "C stack overflow" ) then error( "tick quota exceeded", -1 ) end -- a "C stack overflow" error will probably just confuse E2 users more than a "tick quota" error.

		if !ok and msg == "return" then return self.func_rv end

		if !ok then error(msg,0) end

	end

	return Func
end



/*==============================================================
	E2 Function System
		By Rusketh
			General Operators
==============================================================*/

__e2setcost(20)

registerOperator("function", "", "", function(self, args)

	local Stmt, args = args[2], args[3]
	local Sig, Return, Args = args[3], args[4], args[6]

	self.funcs[Sig] = Function(Args,Stmt)

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
