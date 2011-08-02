/*==============================================================
	E2 Function System
		By Rusketh
			Function Creator
==============================================================*/

local function Function(A,S)

	local Func = function(self,args)

		local OldVars = {}

		for K,Data in pairs (A) do
			local Name, Type, OP = Data[1], Data[2], args[K + 1]
			local RV = OP[1](self, OP)


			if self.vars[Name] then

				OldVars[Name] = {}
				OldVars[Name][1] = self.vars[Name]
				OldVars[Name][2] = self.vars["$" .. Name]
				OldVars[Name][3] = self.vclk[Name]

				//OldVars[Name][4] = self[#self][Name]

			end

			self.vars[Name] = RV
			self.vars["$" .. Name] = RV
			self.vclk[Name] = false

			//self[#self][Name] = wire_expression_types[Type][1]

		end

		self.func_rv = nil
		local ok, msg = pcall(S[1],self,S)

		for K,Data in pairs (A) do
			local Name,Type = Data[1], Data[2]

			if OldVars[Name] then

				self.vars[Name] = OldVars[Name][1]
				self.vars["$" .. Name] = OldVars[Name][2]
				self.vclk[Name] = OldVars[Name][3]

				//self[#self][Name] = OldVars[Name][4]

			else

				self.vars[Name] = nil
				self.vars["$" .. Name] = nil
				self.vclk[Name] = nil

				//self[#self][Name] = nil

			end
		end

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


--[[Disabled because Syranide disagreed with it--
/*==============================================================
	E2 Function System
		By Rusketh
			Function Type
==============================================================*/
Function, Perams, Return Type, isfunction (true), isnotreal (nil function)
local DEF = {function() end,"","",isfunction = true,isnotreal = true}

registerType("function", "f", DEF,

	nil,

	nil,

	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
	end,

	function(v) return type(v) ~= "table" end
)


/*==============================================================
	E2 Function System
		By Rusketh
			GetFunction Function
==============================================================*/

__e2setcost(20)

e2function function getFunction(string name,string perams)
    local Sig = name .. "(" .. perams .. ")"

	if self.funcs[Sig] and self.funcs_ret[Sig] then
		return {self.funcs[Sig],perams,self.funcs_ret[Sig] or "" ,isfunction = true}
	end

	return DEF
end

/*==============================================================
	E2 Function System
		By Rusketh
			Store Function Function
==============================================================*/

__e2setcost(20)

e2function number storeFunction(function func, string name)
    if func.isnotreal then return 0 end

	local Perams,Return = func[2], func[3]
	local Sig = name .. "(" .. Perams .. ")"

	if wire_expression2_funcs[Sig] then return 0 end
	if self.funcs_ret[Sig] and (self.funcs_ret[Sig] || "") != (Return || "") then return 0 end
	if !self.funcs[Sig] then return 0 end

	self.funcs[Sig] = func[1]
	self.funcs_ret[Sig] = Return

	return 1
end

/*==============================================================
	E2 Function System
		By Rusketh
			Function Valid
==============================================================*/
__e2setcost(5)

e2function function operator=(function lhs, function rhs)
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

__e2setcost(2)

e2function number operator_is(function func)
	if !func.isnotreal then return 1 else return 0 end
end

e2function string toString(function func)
	if func.isnotreal then return "blank function" end
	return "function " .. func[3] .. " = (" .. func[2] .. ")"
end

e2function string function:toString()
	if this.isnotreal then return "blank function" end
	return "function " .. this[3] .. " = (" .. this[2] .. ")"
end]]
