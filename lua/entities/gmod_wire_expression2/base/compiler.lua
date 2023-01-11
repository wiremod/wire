--[[
  Expression 2 Compiler for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

AddCSLuaFile()

---@class Compiler
---@field warnings table<number|string, Warning> # Array of warnings (main file) with keys to included file warnings.
---@field include string? # Current include file or nil if main file
---@field Scopes Scope[]
---@field Scope Scope?
---@field ScopeID integer
---@field GlobalScope Scope
---@field persist table<string, string> # Variable: Type
---@field inputs table<string, string> # Variable: Type
---@field outputs table<string, string> # Variable: Type
---@field registered_events table<string, function>
local Compiler = {}
Compiler.__index = Compiler
E2Lib.Compiler = Compiler

local BLOCKED_ARRAY_TYPES = E2Lib.blocked_array_types

---@return boolean ok
---@return function script
---@return Compiler self
function Compiler.Execute(root, inputs, outputs, persist, delta, includes)
	-- instantiate Compiler
	local instance = setmetatable({}, Compiler)

	-- and pcall the new instance's Process method.
	local ok, script = xpcall(Compiler.Process, E2Lib.errorHandler, instance, root, inputs, outputs, persist, delta, includes)

	return ok, script, instance
end

function Compiler:Error(message, instr)
	error(message .. " at line " .. instr[2][1] .. ", char " .. instr[2][2], 0)
end

function Compiler:Warning(message, instr)
	if self.include then
		local tbl = self.warnings[self.include]
		tbl[#tbl + 1] = { message = message, line = instr[2][1], char = instr[2][2] }
	else
		self.warnings[#self.warnings + 1] = { message = message, line = instr[2][1], char = instr[2][2] }
	end
end

local string_upper = string.upper

function Compiler:CallInstruction(name, trace, ...)
	return self["Instr" .. string_upper(name)](self, trace, ...)
end

---@return function script
function Compiler:Process(root, inputs, outputs, persist, delta, includes) -- Took params out becuase it isnt used.
	self.context = {}
	self.registered_events = {}
	self.warnings = {}

	self:InitScope() -- Creates global scope!

	self.inputs = inputs[3]
	self.outputs = outputs[3]
	self.persist = persist[3]
	self.includes = includes or {}
	self.prfcounter = 0
	self.prfcounters = {}
	self.funcs = {}
	self.dvars = {}
	self.funcs_ret = {}
	self.EnclosingFunctions = { --[[ { ReturnType: string } ]] }

	for name, v in pairs(inputs[3]) do
		self:SetGlobalVariableType(name, wire_expression_types[v][1], { nil, inputs[5][name] }, true)
	end

	for name, v in pairs(outputs[3]) do
		self:SetGlobalVariableType(name, wire_expression_types[v][1], { nil, outputs[5][name] }, false)
	end

	for name, v in pairs(persist[3]) do
		self:SetGlobalVariableType(name, wire_expression_types[v][1], { nil, persist[5][name] }, false)
	end

	for name, v in pairs(delta) do
		self.dvars[name] = v
	end

	self:PushScope()

	local script = self:CallInstruction(root[1], root)

	for name, var in pairs(self.GlobalScope) do
		if var.var_tok then
			self:Warning("Unused global variable [" .. name .. "]", var.var_tok)
		end
	end

	self:PopScope()

	return script
end

function tps_pretty(tps)
	if not tps or #tps == 0 then return "void" end
	if type(tps) == "string" then tps = { tps } end
	local ttt = {}
	for i = 1, #tps do
		local _, typenames = E2Lib.splitType(tps[i])
		for j = 1, #typenames do table.insert(ttt, typenames[j]) end
	end
	return table.concat(ttt, ", ")
end

local function op_find(name)
	return E2Lib.optable_inv[name] or "unknown?!"
end

---@class ScopeData
---@field type string
---@field var_tok table? # Instance token pointing to the declaration, only exists if variable has yet to be used.
---@field initialized boolean # Whether the variable is defined as initialized (e.g. whether a @persist variable has been assigned to by the user)

---@alias Scope table<string, ScopeData>

function Compiler:InitScope()
	self.Scopes = {}
	self.ScopeID = 0
	self.Scopes[0] = self.GlobalScope or {} --for creating new enviroments
	self.Scope = self.Scopes[0]
	self.GlobalScope = self.Scope
end

function Compiler:PushScope(Scope)
	self.ScopeID = self.ScopeID + 1
	self.Scope = Scope or {}
	self.Scopes[self.ScopeID] = self.Scope
end

function Compiler:PopScope()
	self.ScopeID = self.ScopeID - 1
	self.Scope = self.Scopes[self.ScopeID]
	self.Scopes[self.ScopeID] = self.Scope
	return table.remove(self.Scopes, self.ScopeID + 1)
end

function Compiler:SaveScopes()
	return { self.Scopes, self.ScopeID, self.Scope }
end

function Compiler:LoadScopes(Scopes)
	self.Scopes = Scopes[1]
	self.ScopeID = Scopes[2]
	self.Scope = Scopes[3]
end

-- Should not be used with discard (_) variables
function Compiler:SetLocalVariableType(name, type, instance, binding)
	local var = self.Scope[name]
	if var and var.type ~= type then
		self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") of type [" .. tps_pretty({ var.type }) .. "] cannot be assigned value of type [" .. tps_pretty({ type }) .. "]", instance)
	end

	self.Scope[name] = { type = type, var_tok = instance, initialized = true, binding = binding }
	return self.ScopeID
end

-- Should not be used with discard (_) variables
---@param initialized boolean
function Compiler:SetGlobalVariableType(name, type, instance, initialized)
	for i = self.ScopeID, 0, -1 do
		local var = self.Scopes[i][name]
		if var then
			if var.type ~= type then
				self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") of type [" .. tps_pretty({ var.type }) .. "] cannot be assigned value of type [" .. tps_pretty({ type }) .. "]", instance)
			elseif i == 0 and not var.initialized then
				var.var_tok = instance
				var.initialized = true
				return i
			end
			return i
		end
		if var and var.type ~= type then
			self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") of type [" .. tps_pretty({ var.type }) .. "] cannot be assigned value of type [" .. tps_pretty({ type }) .. "]", instance)
		elseif var then
			return i
		end
	end

	self.GlobalScope[name] = { type = type, var_tok = instance, initialized = initialized }
	return 0
end

function Compiler:GetVariableType(instance, name)
	for i = self.ScopeID, 0, -1 do
		local var = self.Scopes[i][name]
		if var then
			var.var_tok = nil -- Mark variable as used
			return var.type, i, var.initialized
		end
	end

	self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") does not exist", instance)
	return nil
end

-- ---------------------------------------------------------------------------

--- May return nil in the case of a statement without any runtime side effects.
---@return table?, string, string, any
function Compiler:EvaluateStatement(args, index)
	local trace = args[index + 2]

	local name = string_upper(trace[1])

	local ex, tp, extra = self:CallInstruction(name, trace)
	if ex then
		ex.TraceName = name
		ex.Trace = trace[2]
	end

	return ex, tp, name, extra
end

function Compiler:Evaluate(args, index)
	local ex, tp, name = self:EvaluateStatement(args, index)

	if tp == "" then
		self:Error("Function has no return value (void), cannot be part of expression or assigned", args[index + 2])
	end

	return ex, tp, name
end

function Compiler:HasOperator(instr, name, tps)
	local pars = table.concat(tps)
	local a = wire_expression2_funcs["op:" .. name .. "(" .. pars .. ")"]
	return a and true or false
end

function Compiler:GetOperator(instr, name, tps)
	local pars = table.concat(tps)
	local a = wire_expression2_funcs["op:" .. name .. "(" .. pars .. ")"]
	if not a then
		self:Error("No such operator: " .. op_find(name) .. "(" .. tps_pretty(tps) .. ")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (a[4] or 3)

	return { a[3], a[2], a[1] }
end


function Compiler:UDFunction(Sig)
	if self.funcs_ret and self.funcs_ret[Sig] then
		return {
			Sig, self.funcs_ret[Sig],
			function(self, args)
				if self.funcs and self.funcs[Sig] then
					return self.funcs[Sig](self, args)
				elseif self.funcs_ret and self.funcs_ret[Sig] then
					-- This only occurs if a function's definition isn't executed before the function is called
					-- Would probably only accidentally come about when pasting an E2 that has function definitions in
					-- if(first()) instead of if(first() || duped())
					error("UDFunction: " .. Sig .. " undefined at runtime!", -1)
					-- return wire_expression_types2[self.funcs_ret[Sig]][2] -- This would return the default value for the type, probably better to error though
				end
			end,
			20
		}
	end
end


function Compiler:GetFunction(instr, Name, Args)
	local Params = table.concat(Args)
	local Func = wire_expression2_funcs[Name .. "(" .. Params .. ")"]

	if not Func then
		Func = self:UDFunction(Name .. "(" .. Params .. ")")

		if not Func then
			for I = #Params, 0, -1 do
				local sig = Name .. "(" .. Params:sub(1, I)
				local arrsig, tblsig = sig .. "..r)", sig .. "..t)"
				if self.funcs_ret[arrsig] then
					Func = self:UDFunction(arrsig)
					break
				elseif self.funcs_ret[tblsig] then
					Func = self:UDFunction(tblsig)
					break
				end
			end
		end
	end

	if not Func then
		for I = #Params, 0, -1 do
			Func = wire_expression2_funcs[Name .. "(" .. Params:sub(1, I) .. "...)"]
			if Func then break end
		end
	end

	if not Func then
		self:Error("No such function: " .. Name .. "(" .. tps_pretty(Args) .. ")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (Func[4] or 20)

	return { Func[3], Func[2], Func[1], Func.attributes }
end


function Compiler:GetMethod(instr, Name, Meta, Args)
	local Params = Meta .. ":" .. table.concat(Args)
	local Func = wire_expression2_funcs[Name .. "(" .. Params .. ")"]

	if not Func then
		Func = self:UDFunction(Name .. "(" .. Params .. ")")

		if not Func then
			for I = #Params, 0, -1 do
				local sig = Name .. "(" .. Params:sub(1, I)
				local arrsig, tblsig = sig .. "..r)", sig .. "..t)"
				if self.funcs_ret[arrsig] then
					Func = self:UDFunction(arrsig)
					break
				elseif self.funcs_ret[tblsig] then
					Func = self:UDFunction(tblsig)
					break
				end
			end
		end
	end

	if not Func then
		for I = #Params, #Meta + 1, -1 do
			Func = wire_expression2_funcs[Name .. "(" .. Params:sub(1, I) .. "...)"]
			if Func then break end
		end
	end

	if not Func then
		self:Error("No such function: " .. tps_pretty({ Meta }) .. ":" .. Name .. "(" .. tps_pretty(Args) .. ")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (Func[4] or 20)

	return { Func[3], Func[2], Func[1], Func.attributes }
end

function Compiler:PushPrfCounter()
	self.prfcounters[#self.prfcounters + 1] = self.prfcounter
	self.prfcounter = 0
end

function Compiler:PopPrfCounter()
	local prfcounter = self.prfcounter
	self.prfcounter = self.prfcounters[#self.prfcounters]
	self.prfcounters[#self.prfcounters] = nil
	return prfcounter
end

-- ------------------------------------------------------------------------

--- Warnings for expressions in statement positions
-- "add", "sub", "mul", "div", "mod", "exp", "eq", "neq", "geq", "leq", "gth", "lth", "band", "band", "bor", "bxor", "bshl", "bshr"
local ExprWarnings = {
	["GET"] = "Cannot discard value of an index (Remove this pointless indexing)",
	["LITERAL"] = "This literal won't have any effect on the code",

	["NOT"] = "Cannot discard result of logical NOT operation (!)",
	["AND"] = "Cannot discard result of logical AND operation (&)",
	["OR"] = "Cannot discard result of logical OR operation (|)",

	["BAND"] = "Cannot discard result of binary AND operation (&&)",
	["BOR"] = "Cannot discard result of binary OR operation (||)",

	["BXOR"] = "Cannot discard result of binary XOR operation (^^)",

	["BSHL"] = "Cannot discard result of binary left shift operation (<<)",
	["BSHR"] = "Cannot discard result of binary right shift operation (>>)",

	["ADD"] = "Cannot discard result of addition operation (+)",
	["SUB"] = "Cannot discard result of subtraction operation (-)",
	["MUL"] = "Cannot discard result of multiplication operation (*)",
	["DIV"] = "Cannot discard result of division operation (/)",
	["MOD"] = "Cannot discard result of modulus operation (%)",
	["EXP"] = "Cannot discard result of exponential operation (^)",

	["EQ"] = "Cannot discard result of equal to comparison (==)",
	["NEQ"] = "Cannot discard result of not equal to comparison (!=)",
	["GEQ"] = "Cannot discard result of greater than or equal to comparison (>=)",
	["LEQ"] = "Cannot discard result of less than than or equal to comparison (<=)",
	["GTH"] = "Cannot discard result of greater than comparison (>)",
	["LTH"] = "Cannot discard result of less than comparison (<)",

	["TRG"] = "Cannot discard result of triggered (~) operation",
	["DLT"] = "Cannot discard result of delta ($) operator",
	["IWC"] = "Cannot discard result of connected (->) operator",

	["VAR"] = "Cannot discard variable"
}

function Compiler:InstrSEQ(args)
	-- args = { "seq", trace, subexpressions... }
	self:PushPrfCounter()

	local stmts = { self:GetOperator(args, "seq", {})[1], 0 }

	for i = 1, #args - 2 do
		if self.Scope._dead then
			-- Don't compile dead code.
			self:Warning("Unreachable code detected", args[i + 2])
			break
		else
			local stmt, _, instr, extra = self:EvaluateStatement(args, i)
			if (instr == "CALL" or instr == "METHODCALL") and (extra and extra.nodiscard) then
				self:Warning("The return value of this function cannot be discarded", args[i + 2])
			elseif ExprWarnings[instr] then
				self:Warning(ExprWarnings[instr], args[i + 2])
			end

			if stmt then
				-- Statement has a runtime side effect.
				stmts[#stmts + 1] = stmt
			end
		end
	end

	for varname, var in pairs(self.Scope) do
		if var ~= true and var.var_tok then
			if var.binding then
				self:Warning("Unused variable [" .. varname .. "] (You can use _ to discard it)", var.var_tok)
			else
				self:Warning("Unused variable [" .. varname .. "]", var.var_tok)
			end
		end
	end

	stmts[2] = self:PopPrfCounter()

	return stmts
end

function Compiler:InstrBRK(args)
	-- args = { "brk", trace }
	self.Scope._dead = true
	return { self:GetOperator(args, "brk", {})[1] }
end

function Compiler:InstrCNT(args)
	-- args = { "cnt", trace }
	self.Scope._dead = true
	return { self:GetOperator(args, "cnt", {})[1] }
end

function Compiler:InstrFOR(args)
	-- args = { "for", trace, variable name, start expression, stop expression, step expression or nil, loop body }
	local var = args[3]

	local estart, tp1 = self:Evaluate(args, 2)
	local estop, tp2 = self:Evaluate(args, 3)

	local estep, tp3
	if args[6] then
		estep, tp3 = self:Evaluate(args, 4)
		if tp1 ~= "n" or tp2 ~= "n" or tp3 ~= "n" then self:Error("for(" .. tps_pretty({ tp1 }) .. ", " .. tps_pretty({ tp2 }) .. ", " .. tps_pretty({ tp3 }) .. ") is invalid, only supports indexing by number", args) end
	else
		if tp1 ~= "n" or tp2 ~= "n" then self:Error("for(" .. tps_pretty({ tp1 }) .. ", " .. tps_pretty({ tp2 }) .. ") is invalid, only supports indexing by number", args) end
	end

	self:PushScope()
	if var ~= "_" then
		self:SetLocalVariableType(var, "n", args, true)
	end

	local stmt = self:EvaluateStatement(args, 5)
	self:PopScope()

	return { self:GetOperator(args, "for", {})[1], var, estart, estop, estep, stmt }
end

function Compiler:InstrWHL(args)
	-- args = { "whl", trace, condition expression, loop body, skip condition check first time? }

	local skipCondFirstTime = args[5]

	self:PushScope()

	self:PushPrfCounter()
	local cond = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	local stmt = self:EvaluateStatement(args, 2)
	self:PopScope()

	return { self:GetOperator(args, "whl", {})[1], cond, stmt, prf_cond, skipCondFirstTime }
end


function Compiler:InstrIF(args)
	-- args = { "if", trace, condition expression, true case body, false case body }
	self:PushPrfCounter()
	local ex1, tp1 = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	self:PushScope()
	local st1 = self:EvaluateStatement(args, 2)
	self:PopScope()

	self:PushScope()
	local st2 = self:EvaluateStatement(args, 3)
	self:PopScope()

	local rtis = self:GetOperator(args, "is", { tp1 })
	local rtif = self:GetOperator(args, "if", { rtis[2] })
	return { rtif[1], prf_cond, { rtis[1], ex1 }, st1, st2 }
end

function Compiler:InstrDEF(args)
	-- args = { "def", trace, primary expression, fallback expression }
	local ex1, tp1 = self:Evaluate(args, 1)

	self:PushPrfCounter()
	local ex2, tp2 = self:Evaluate(args, 2)
	local prf_ex2 = self:PopPrfCounter()

	local rtis = self:GetOperator(args, "is", { tp1 })
	local rtif = self:GetOperator(args, "def", { rtis[2] })
	local rtdat = self:GetOperator(args, "dat", {})

	if tp1 ~= tp2 then
		self:Error("Different types (" .. tps_pretty({ tp1 }) .. ", " .. tps_pretty({ tp2 }) .. ") returned in default conditional", args)
	end

	return { rtif[1], { rtis[1], { rtdat[1], nil } }, ex1, ex2, prf_ex2 }, tp1
end

function Compiler:InstrCND(args)
	-- args = { "cnd", trace, conditional expression, true expression, false expression }
	local ex1, tp1 = self:Evaluate(args, 1)

	self:PushPrfCounter()
	local ex2, tp2 = self:Evaluate(args, 2)
	local prf_ex2 = self:PopPrfCounter()

	self:PushPrfCounter()
	local ex3, tp3 = self:Evaluate(args, 3)
	local prf_ex3 = self:PopPrfCounter()

	local rtis = self:GetOperator(args, "is", { tp1 })
	local rtif = self:GetOperator(args, "cnd", { rtis[2] })

	if tp2 ~= tp3 then
		self:Error("Different types (" .. tps_pretty({ tp2 }) .. ", " .. tps_pretty({ tp3 }) .. ") returned in conditional", args)
	end

	return { rtif[1], { rtis[1], ex1 }, ex2, ex3, prf_ex2, prf_ex3 }, tp2
end


function Compiler:InstrCALL(args)
	-- args = { "call", trace, function name, { argument expressions... } }
	local exprs = { false }

	local tps, fname = {}, args[3]
	if fname == "array" then
		-- Hack for array creation.
		-- Check if illegal arguments are passed
		for i = 1, #args[4] do
			local ex, tp = self:Evaluate(args[4], i - 2)
			if BLOCKED_ARRAY_TYPES[tp] then
				self:Error("Cannot have type " .. tps_pretty(tp) .. " in array creation argument #" .. i, args[4][i])
			end

			exprs[i + 1] = ex
			tps[i] = tp
		end
	elseif fname == "changed" then
		for i = 1, #args[4] do
			local ex, tp, instr = self:Evaluate(args[4], i - 2)
			if instr == "LITERAL" then
				self:Warning("Using changed on a literal will only evaluate once", args[4][i])
			elseif instr == "VAR" then
				local varname = args[4][i][3]
				if self.inputs[varname] then
					self:Warning("Using changed on an input is bad, use the ~ or -> operators instead", args[4][i])
				end
			end
			exprs[i + 1], tps[i] = ex, tp
		end
	else
		for i = 1, #args[4] do
			exprs[i + 1], tps[i] = self:Evaluate(args[4], i - 2)
		end
	end

	local rt = self:GetFunction(args, args[3], tps)
	exprs[1] = rt[1]
	exprs[#exprs + 1] = tps

	if rt[4] then
		if rt[4].deprecated ~= nil and rt[4].deprecated ~= true then
			-- Deprecation message (string)
			self:Warning("Use of deprecated function: " .. args[3] .. "(" .. tps_pretty(tps) .. "): '" .. rt[4].deprecated .. "'", args)
		elseif rt[4].deprecated then
			self:Warning("Use of deprecated function: " .. args[3] .. "(" .. tps_pretty(tps) .. ")", args)
		end

		if rt[4].noreturn then
			self.Scope._dead = true
		end
	end

	return exprs, rt[2], rt[4]
end

function Compiler:InstrSTRINGCALL(args)
	-- args = { "stringcall", trace, function name expression, { argument expressions... }, return type }
	local exprs = { false }

	local fexp, ftp = self:Evaluate(args, 1)

	if ftp ~= "s" then
		self:Error("User function is not string-type", args)
	end

	local tps = {}
	for i = 1, #args[4] do
		local ex, tp = self:Evaluate(args[4], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	exprs[#exprs + 1] = tps

	local rtsfun = self:GetOperator(args, "stringcall", {})[1]

	local typeids_str = table.concat(tps, "")

	return { rtsfun, fexp, exprs, tps, typeids_str, args[5] }, args[5]
end

function Compiler:InstrMETHODCALL(args)
	-- args = { "methodcall", trace, method name, object expression, { argument expressions... } }
	local exprs = { false }

	local tps = {}

	local ex, tp = self:Evaluate(args, 2)
	exprs[#exprs + 1] = ex

	for i = 1, #args[5] do
		local ex, tp = self:Evaluate(args[5], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	local rt = self:GetMethod(args, args[3], tp, tps)
	exprs[1] = rt[1]
	exprs[#exprs + 1] = tps

	if rt[4] then
		if rt[4].deprecated ~= nil and rt[4].deprecated ~= true then
			-- Deprecation message (string)
			self:Warning("Use of deprecated method: " .. tps_pretty(tp) .. ":" .. args[3] .. "(" .. tps_pretty(tps) .. "): '" .. rt[4].deprecated .. "'", args)
		elseif rt[4].deprecated then
			self:Warning("Use of deprecated method: " .. tps_pretty(tp) .. ":" .. args[3] .. "(" .. tps_pretty(tps) .. ")", args)
		end

		if rt[4].noreturn then
			self.Scope._dead = true
		end
	end

	return exprs, rt[2], rt[4]
end

function Compiler:InstrASS(args)
	-- args = { "ass", trace, variable name, assigned expression }
	local op = args[3]
	local ex, tp = self:Evaluate(args, 2)

	local keep_as_used = self.persist[op] and not self.GlobalScope[op].var_tok

	local ScopeID = self:SetGlobalVariableType(op, tp, args, true)
	if keep_as_used or (ScopeID == 0 and self.outputs[op]) then
		-- Mark output variable as being used to prevent warnings.
		-- Also mark @persist variable as used if already used in InstrVAR prior to assignment
		-- (Without this, the InstrASS would mark it as unused once again even if it was used prior)
		self.Scopes[ScopeID][op].var_tok = nil
	end

	local rt = self:GetOperator(args, "ass", { tp })

	if ScopeID == 0 and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. op, { self:GetOperator(args, "var", {})[1], op, ScopeID }, ScopeID }
		stmts[4] = { rt[1], op, ex, ScopeID }
		return stmts, tp
	else
		return { rt[1], op, ex, ScopeID }, tp
	end
end

function Compiler:InstrASSL(args)
	-- args = { "assl", trace, variable name, assigned expression }
	local op = args[3]
	local ex, tp = self:Evaluate(args, 2)
	local ScopeID = self:SetLocalVariableType(op, tp, args)
	local rt = self:GetOperator(args, "ass", { tp })

	if ScopeID == 0 then
		self:Error("Invalid use of 'local' inside the global scope.", args)
	end -- Just to make code look neater.

	return { rt[1], op, ex, ScopeID }, tp
end

function Compiler:InstrGET(args)
	-- args = { "get", trace, object expression, field expression, return type or nil }
	local ex, tp = self:Evaluate(args, 1)
	local ex1, tp1 = self:Evaluate(args, 2)
	local tp2 = args[5]

	if tp2 == nil then
		if not self:HasOperator(args, "idx", { tp, tp1 }) then
			self:Error("No such operator: get " .. tps_pretty({ tp }) .. "[" .. tps_pretty({ tp1 }) .. "]", args)
		end

		local rt = self:GetOperator(args, "idx", { tp, tp1 })
		return { rt[1], ex, ex1 }, rt[2]


	else
		if not self:HasOperator(args, "idx", { tp2, "=", tp, tp1 }) then
			self:Error("No such operator: get " .. tps_pretty({ tp }) .. "[" .. tps_pretty({ tp1, tp2 }) .. "]", args)
		end

		local rt = self:GetOperator(args, "idx", { tp2, "=", tp, tp1 })
		return { rt[1], ex, ex1 }, tp2
	end
end

function Compiler:InstrSET(args)
	-- args = { "set", trace, object expression, field expression, value expression, value type or nil }
	local ex, tp = self:Evaluate(args, 1)
	local ex1, tp1 = self:Evaluate(args, 2)
	local ex2, tp2 = self:Evaluate(args, 3)

	if args[6] == nil then
		if not self:HasOperator(args, "idx", { tp, tp1, tp2 }) then
			self:Error("No such operator: set " .. tps_pretty({ tp }) .. "[" .. tps_pretty({ tp1 }) .. "]=" .. tps_pretty({ tp2 }), args)
		end

		local rt = self:GetOperator(args, "idx", { tp, tp1, tp2 })

		return { rt[1], ex, ex1, ex2, nil }, rt[2]
	else
		if tp2 ~= args[6] then
			self:Error("Indexing type mismatch, specified [" .. tps_pretty({ args[6] }) .. "] but value is [" .. tps_pretty({ tp2 }) .. "]", args)
		end

		if not self:HasOperator(args, "idx", { tp2, "=", tp, tp1, tp2 }) then
			self:Error("No such operator: set " .. tps_pretty({ tp }) .. "[" .. tps_pretty({ tp1, tp2 }) .. "]", args)
		end
		local rt = self:GetOperator(args, "idx", { tp2, "=", tp, tp1, tp2 })

		return { rt[1], ex, ex1, ex2 }, tp2
	end
end


-- generic code for all binary non-boolean operators
for _, operator in ipairs({ "add", "sub", "mul", "div", "mod", "exp", "eq", "neq", "geq", "leq", "gth", "lth", "band", "band", "bor", "bxor", "bshl", "bshr" }) do

	Compiler["Instr" .. operator:upper()] = function(self, args)
		-- args = { operator, trace, left expression, right expression }
		local ex1, tp1 = self:Evaluate(args, 1)
		local ex2, tp2 = self:Evaluate(args, 2)
		local rt = self:GetOperator(args, operator, { tp1, tp2 })
		return { rt[1], ex1, ex2 }, rt[2]
	end
end

function Compiler:InstrINC(args)
	-- args = { "inc", trace, variable name }
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "inc", { tp })

	if ScopeID == 0 and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. op, { self:GetOperator(args, "var", {})[1], op, ScopeID }, ScopeID }
		stmts[4] = { rt[1], op, ScopeID }
		return stmts
	else
		return { rt[1], op, ScopeID }
	end
end

function Compiler:InstrDEC(args)
	-- args = { "dec", trace, variable name }
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "dec", { tp })

	if ScopeID == 0 and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. op, { self:GetOperator(args, "var", {})[1], op, ScopeID }, ScopeID }
		stmts[4] = { rt[1], op, ScopeID }
		return stmts
	else
		return { rt[1], op, ScopeID }
	end
end

function Compiler:InstrNEG(args)
	-- args = { "neg", trace, expression }
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt = self:GetOperator(args, "neg", { tp1 })
	return { rt[1], ex1 }, rt[2]
end


function Compiler:InstrNOT(args)
	-- args = { "not", trace, expression }
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt = self:GetOperator(args, "not", { rt1is[2] })
	return { rt[1], { rt1is[1], ex1 } }, rt[2]
end

function Compiler:InstrAND(args)
	-- args = { "and", trace, left expression, right expression }
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt2is = self:GetOperator(args, "is", { tp2 })
	local rt = self:GetOperator(args, "and", { rt1is[2], rt2is[2] })
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end

function Compiler:InstrOR(args)
	-- args = { "or", trace, left expression, right expression }
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt2is = self:GetOperator(args, "is", { tp2 })
	local rt = self:GetOperator(args, "or", { rt1is[2], rt2is[2] })
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end


function Compiler:InstrTRG(args)
	-- args = { "trg", trace, variable name }
	local op = args[3]
	local _tp, ScopeID = self:GetVariableType(args, op)

	if ScopeID ~= 0 or not self.inputs[op] then
		self:Error("Triggered operator (~" .. E2Lib.limitString(op, 10) .. ") can only be used on inputs", args)
	end

	-- Necessary since this doesn't use Compiler:Evaluate (which would call InstrVAR, and do this.)
	self.Scopes[0][op].var_tok = nil

	local rt = self:GetOperator(args, "trg", {})
	return { rt[1], op }, rt[2]
end

function Compiler:InstrDLT(args)
	-- args = { "dlt", trace, variable name }
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(args, op)

	if ScopeID ~= 0 or not self.dvars[op] then
		self:Error("Delta operator ($" .. E2Lib.limitString(op, 10) .. ") cannot be used on temporary variables", args)
	end

	self.dvars[op] = true
	local rt = self:GetOperator(args, "sub", { tp, tp })
	local rtvar = self:GetOperator(args, "var", {})
	return { rt[1], { rtvar[1], op, ScopeID }, { rtvar[1], "$" .. op, ScopeID } }, rt[2]
end

function Compiler:InstrIWC(args)
	-- args = { "iwc", trace, variable name }
	local op = args[3]
	local _tp, ScopeID = self:GetVariableType(args, op)

	if ScopeID == 0 then
		if self.inputs[op] then
			local rt = self:GetOperator(args, "iwc", {})
			return { rt[1], op }, rt[2]
		elseif self.outputs[op] then
			local rt = self:GetOperator(args, "owc", {})
			return { rt[1], op }, rt[2]
		end
	end

	self:Error("Connected operator (->" .. E2Lib.limitString(op, 10) .. ") can only be used on inputs or outputs", args)
end

function Compiler:InstrLITERAL(args)
	-- args = { "literal", trace, value, value type }
	self.prfcounter = self.prfcounter + 0.5
	local value = args[3]
	return { function() return value end }, args[4]
end

function Compiler:InstrVAR(args)
	-- args = { "var", trace, variable name }
	self.prfcounter = self.prfcounter + 1.0
	local name = args[3]
	local tp, ScopeID, initialized = self:GetVariableType(args, name)

	-- Mark variable as used.
	self.Scopes[ScopeID][name].var_tok = nil

	if ScopeID == 0 and not initialized then
		self:Warning("Use of variable [" .. name .. "] before initialization", args)
	end

	return {function(self)
		return self.Scopes[ScopeID][name]
	end}, tp
end

function Compiler:InstrFEA(args)
	-- args = { "fea", trace, key variable name, key type, value variable name, value type, table expression, loop body }
	local keyvar, keytype, valvar, valtype = args[3], args[4], args[5], args[6]
	local tableexpr, tabletp = self:Evaluate(args, 5)

	local op

	if keytype then
		op = self:GetOperator(args, "fea", {keytype, valtype, tabletp})
	else
		-- If no key type is specified, fallback to old behavior

		-- The type of the keys iterated over depends on what's being iterated over (ie. tabletp).
		-- The 'table' returned by tableexpr can be a table, an array, a gtable, or others in future.
		-- If the type has an indexing operator that takes strings, then we iterate over strings,
		-- otherwise we iterator over numbers.

		if self:HasOperator(args, "fea", {"s", valtype, tabletp}) then
			op = self:GetOperator(args, "fea", {"s", valtype, tabletp})
			keytype = "s"
		elseif self:HasOperator(args, "fea", {"n", valtype, tabletp}) then
			op = self:GetOperator(args, "fea", {"n", valtype, tabletp})
			keytype = "n"
		else
			self:Error("Type '" .. tps_pretty(tabletp) .. "' has no valid default foreach operator", args)
		end
	end

	self:PushScope()

	if keyvar ~= "_" then
		self:SetLocalVariableType(keyvar, keytype, args, true)
	end

	if valvar ~= "_" then
		self:SetLocalVariableType(valvar, valtype, args, true)
	end

	local stmt = self:EvaluateStatement(args, 6)

	self:PopScope()

	return {op[1], keyvar, valvar, tableexpr, stmt}
end


function Compiler:InstrFUNCTION(args)
	-- args = { "function", trace, signature, return type, object type, { { parameter name, parameter type }... }, function body }
	local Sig, Return, methodType, Args = args[3], args[4], args[5], args[6]
	Return = Return or ""

	local OldScopes = self:SaveScopes()
	self:InitScope() -- Create a new Scope Enviroment
	self:PushScope()

	local VariadicType
	for _, D in pairs(Args) do
		local Name, Type, Variadic, Discard = D[1], wire_expression_types[D[2]][1], D[3], D[4]
		VariadicType = Variadic and Type

		if not Discard then
			self:SetLocalVariableType(Name, Type, args, true)
		end
	end

	if VariadicType then
		-- Don't allow users to define two functions with different variadic types
		-- Because that'd cause ambiguity.
		local opposite = VariadicType == "r" and "t" or "r"
		if self.funcs_ret[Sig:gsub("%.%." .. VariadicType, ".." .. opposite)] then
			self:Error("Cannot override variadic " .. tps_pretty(opposite) .. " function with variadic " .. tps_pretty(VariadicType) .. " function to avoid ambiguity.", args)
		end
	end

	if self.funcs_ret[Sig] and self.funcs_ret[Sig] ~= Return then
		local TP = tps_pretty(self.funcs_ret[Sig])
		self:Error("Function " .. Sig .. " must be given return type " .. TP, args)
	end

	self.funcs_ret[Sig] = Return

	table.insert(self.EnclosingFunctions, { ReturnType = Return })

	local Stmt = self:EvaluateStatement(args, 5) -- Offset of -2

	table.remove(self.EnclosingFunctions)

	self:PopScope()
	self:LoadScopes(OldScopes) -- Reload the old enviroment

	self.prfcounter = self.prfcounter + (VariadicType and 80 or 40)

	-- This is the function that will be bound to to the function name, ie. the
	-- one that's called at runtime when code calls the function
	local function body(self, runtimeArgs)
		-- runtimeArgs = { body, parameterExpression1, ..., parameterExpressionN, parameterTypes }
		-- we need to evaluate the arguments before switching to the new scope

		local parameterValues = {}
		if VariadicType then
			local nargs = #Args
			-- There's 100% a better way to structure this mess but this works fine for now...
			local offset = methodType ~= "" and 1 or 0

			for parameterIndex = 2, nargs do
				local parameterExpression = runtimeArgs[parameterIndex]
				local parameterValue = parameterExpression[1](self, parameterExpression)
				parameterValues[parameterIndex - 1] = parameterValue
			end

			local types = runtimeArgs[#runtimeArgs]
			if VariadicType == "t" then
				-- Table argument.
				local tbl, len = E2Lib.newE2Table(), 1
				local n, ntypes = tbl.n, tbl.ntypes

				for parameterIndex = nargs + 1, #runtimeArgs - 1 do
					local ty = types[nargs - 1 - offset + len]

					local parameterExpression = runtimeArgs[parameterIndex]
					local parameterValue = parameterExpression[1](self, parameterExpression)

					n[len], ntypes[len] = parameterValue, ty
					len = len + 1
				end

				tbl.size = len - 1
				parameterValues[nargs] = tbl
			else
				-- Array
				-- Construct array here w/ dynamic values
				local arr, len = {}, 1

				for parameterIndex = nargs + 1, #runtimeArgs - 1 do
					local ty = types[nargs - 1 - offset + len]

					if BLOCKED_ARRAY_TYPES[ty] then
						self:throw("Cannot use type " .. tps_pretty(ty) .. " as an argument for variadic array function", nil)
						break
					end

					local parameterExpression = runtimeArgs[parameterIndex]
					local parameterValue = parameterExpression[1](self, parameterExpression)

					arr[len] = parameterValue
					len = len + 1
				end

				parameterValues[nargs] = arr
			end
		else
			for parameterIndex = 2, #Args + 1 do
				local parameterExpression = runtimeArgs[parameterIndex]
				local parameterValue = parameterExpression[1](self, parameterExpression)
				parameterValues[parameterIndex - 1] = parameterValue
			end
		end

		local OldScopes = self:SaveScopes()
		self:InitScope()
		self:PushScope()

		for parameterIndex = 1, #Args do
			local parameterName = Args[parameterIndex][1]
			local parameterValue = parameterValues[parameterIndex]
			self.Scope[parameterName] = parameterValue
		end

		self.func_rv = nil
		local ok, err = pcall(Stmt[1], self, Stmt)

		local msg = err
		if istable(err) then
			msg = err.msg
		end

		self:PopScope()
		self:LoadScopes(OldScopes)

		-- a "C stack overflow" error will probably just confuse E2 users more than a "tick quota" error.
		if not ok and msg:find( "C stack overflow" ) then error( "tick quota exceeded", -1 ) end

		if not ok and msg == "return" then return self.func_rv end

		if not ok then error(err, 0) end

		if Return ~= "" then
			local argNames = {}
			local offset = methodType == "" and 0 or 1

			for k, v in ipairs(Args) do
				argNames[k - offset] = v[1]
			end

			error("Function " .. E2Lib.generate_signature(Sig, nil, argNames) ..
				" executed and didn't return a value - expecting a value of type " ..
				E2Lib.typeName(Return), 0)
		end
	end

	return { self:GetOperator(args, "function", {})[1], Sig, body }
end

function Compiler:InstrRETURN(args)
	-- args = { "return", trace, return expression or nil }
	local enclosingFunction = self.EnclosingFunctions[#self.EnclosingFunctions]
	if enclosingFunction == nil then
		self:Error("Return may not exist outside of a function", args)
	end

	local expectedType = assert(enclosingFunction.ReturnType)
	local value, actualType
	if args[3] then
		value, actualType = self:Evaluate(args, 1)
	else
		actualType = ""
	end

	if actualType ~= expectedType then
		self:Error("Return type mismatch: " .. tps_pretty(expectedType) .. " expected, got " .. tps_pretty(actualType), args)
	end

	self.Scope._dead = true
	return { self:GetOperator(args, "return", {})[1], value, actualType }
end

function Compiler:InstrKVTABLE(args)
	-- args = { "kvtable", trace, { key expression = value expression... } }
	local s = {}
	local stypes = {}

	local exprs = args[3]
	for k, v in pairs(exprs) do
		local key, type = self:CallInstruction(k[1], k)
		if type == "s" or type == "n" then
			local value, type = self:CallInstruction(v[1], v)
			s[key] = value
			stypes[key] = type
		else
			self:Error("String or number expected, got " .. tps_pretty(type), k)
		end
	end

	return { self:GetOperator(args, "kvtable", {})[1], s, stypes }, "t"
end

function Compiler:InstrKVARRAY(args)
	-- args = { "kvarray", trace, { key expression = value expression... } }
	local values = {}
	local types = {}

	local exprs = args[3]
	for k, v in pairs(exprs) do
		local key, type = self:CallInstruction(k[1], k)
		if type == "n" then
			local value, type = self:CallInstruction(v[1], v)
			if BLOCKED_ARRAY_TYPES[type] then
				self:Error("Cannot have type " .. tps_pretty(type) .. " in array creation for keyvalue", v)
			end

			values[key] = value
			types[key] = type
		else
			self:Error("Number expected, got " .. tps_pretty(type), k)
		end
	end

	return { self:GetOperator(args, "kvarray", {})[1], values, types }, "r"
end

function Compiler:InstrSWITCH(args)
	-- args = { "switch", trace, value expression, { { case expression or nil, body }... } }
	-- up to one case can have a nil case expression, this is the default case
	self:PushPrfCounter()
	local value, type = self:CallInstruction(args[3][1], args[3]) -- This is the value we are passing though the switch statment
	local prf_cond = self:PopPrfCounter()

	local cases = {}
	local Cases = args[4]
	local default

	for i = 1, #Cases do
		local case, block, prf_eq, eq = Cases[i][1], Cases[i][2], 0, nil

		self:PushScope()
		if case then -- The default will not have one
			self:PushPrfCounter()
			local ex, tp = self:CallInstruction(case[1], case) -- This is the value we are checking against
			prf_eq = self:PopPrfCounter() -- We add some pref

			if tp == "" then -- There is no value
				self:Error("Function has no return value (void), cannot be part of expression or assigned", args)
			elseif tp ~= type then -- Value types do not match.
				self:Error("Case mismatch can not compare " .. tps_pretty(type) .. " with " .. tps_pretty(tp), args)
			end
			eq = { self:GetOperator(args, "eq", { type, tp })[1], value, ex } -- This is the equals operator to check if values match
		else
			default=i
		end

		local stmts = self:CallInstruction(block[1], block) -- This is statments that are run when Values match
		self:PopScope()

		cases[i] = { eq, stmts, prf_eq }
	end

	local rtswitch = self:GetOperator(args, "switch", {})
	return { rtswitch[1], prf_cond, cases, default }
end

function Compiler:InstrINCLU(args)
	-- args = { "inclu", trace, filename }
	local file = args[3]
	local include = self.includes[file]

	if not include or not include[1] then
		self:Error("Problem including file '" .. file .. "'", args)
	end

	if not include[2] then
		include[2] = true -- Temporary value to prevent E2 compiling itself in itself.

		local OldScopes = self:SaveScopes()
		self:InitScope() -- Create a new Scope Enviroment
		self:PushScope()

		local last_file = self.include
		self.include = file

		self.warnings[file] = self.warnings[file] or {}

		local root = include[1]
		local status, script = pcall(self.CallInstruction, self, root[1], root)

		if not status then
			local _catchable, reason =  E2Lib.unpackException(script)
			if reason:find("C stack overflow") then reason = "Include depth too deep" end

			if not self.IncludeError then
				-- Otherwise Errors messages will be wrapped inside other error messages!
				self.IncludeError = true
				self:Error("include '" .. file .. "' -> " .. reason, args)
			else
				error(script, 0)
			end
		else
			self.include = last_file

			local nwarnings = #self.warnings[file]
			if nwarnings ~= 0 then
				self:Warning("include '" .. file .. "' has " .. nwarnings .. " warning(s).", args)
			end
		end

		include[2] = script

		self:PopScope()
		self:LoadScopes(OldScopes) -- Reload the old enviroment
	end


	return { self:GetOperator(args, "include", {})[1], file }
end

function Compiler:InstrTRY(args)
	-- args = { "try", trace, try_block, variable, catch_block }
	self:PushPrfCounter()
	local stmt = self:EvaluateStatement(args, 1)
	local var_name = args[4]
	self:PushScope()
		if var_name ~= "_" then
			self:SetLocalVariableType(var_name, "s", args, true)
		end

		local stmt2 = self:EvaluateStatement(args, 3)
	self:PopScope()

	local prf_cond = self:PopPrfCounter()

	return { self:GetOperator(args, "try", {})[1], prf_cond, stmt, var_name, stmt2 }
end

function Compiler:InstrEVENT(args)
	-- args = { "event", trace, name, args, event_block }
	local name, hargs = args[3], args[4]

	if not E2Lib.Env.Events[name] then
		self:Error("No such event exists: '" .. name .. "'", args)
	end

	local event = E2Lib.Env.Events[name]

	if #hargs > #event.args then
		local extra_arg_types = {}
		for i = #event.args + 1, #hargs do
			-- name, type, variadic
			extra_arg_types[#extra_arg_types + 1] = hargs[i][2]
		end

		self:Error("Event '" .. name .. "' does not take arguments (" .. table.concat(extra_arg_types, ", ") .. ")", args)
	end

	for k, typeid in ipairs(event.args) do
		if not hargs[k] then
			-- TODO: Maybe this should be a warning so that events can have extra params added without breaking old code?
			self:Error("Event '" .. name .. "' missing argument #" .. k .. " of type " .. tps_pretty(typeid), args)
		end

		local param_id = wire_expression_types[hargs[k][2]][1]
		if typeid ~= param_id then
			self:Error("Mismatched event argument: " .. tps_pretty(arg) .. " vs " .. tps_pretty(param_id), args)
		end
	end

	if (self.registered_events[name] and self.registered_events[name][self.include or "__main__"]) then
		self:Error("You can only register one event callback per file", args)
	end

	self.registered_events[name] = self.registered_events[name] or {}

	local OldScopes = self:SaveScopes()
	self:InitScope()
	self:PushScope()
		for k, typeid in ipairs(event.args) do
			if not hargs[k][4] --[[ ensure it isn't a discard parameter ]] then
				self:SetLocalVariableType(hargs[k][1], typeid, args, true)
			end
		end

		local block = self:EvaluateStatement(args, 3)
	self:LoadScopes(OldScopes)

	self.registered_events[name][self.include or "__main__"] = function(self, args)
		for i, arg in ipairs(hargs) do
			local name = arg[1]
			self.Scope[name] = args[i]
		end

		block[1](self, block)
	end
end