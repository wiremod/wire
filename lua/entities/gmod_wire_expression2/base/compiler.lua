--[[
  Expression 2 Compiler for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

AddCSLuaFile()

E2Lib.Compiler = {}
local Compiler = E2Lib.Compiler
Compiler.__index = Compiler

function Compiler.Execute(...)
	-- instantiate Compiler
	local instance = setmetatable({}, Compiler)

	-- and pcall the new instance's Process method.
	return xpcall(Compiler.Process, E2Lib.errorHandler, instance, ...)
end

function Compiler:Error(message, instr)
	error(message .. " at line " .. instr[2][1] .. ", char " .. instr[2][2], 0)
end

function Compiler:Process(root, inputs, outputs, persist, delta, includes) -- Took params out becuase it isnt used.
	self.context = {}

	self.inputs = inputs
	self.outputs = outputs
	self.persist = persist
	self.includes = includes or {}
	self.prfcounter = 0
	self.prfcounters = {}
	self.funcs = {}
	self.dvars = {}
	self.funcs_ret = {}
	self.VariableTypes = {}

	for name, v in pairs(inputs) do
		self:SetVariableType(name, name, { nil, { 0, 0 } }, wire_expression_types[v][1])
	end

	for name, v in pairs(outputs) do
		self:SetVariableType(name, name, { nil, { 0, 0 } }, wire_expression_types[v][1])
	end

	for name, v in pairs(persist) do
		self:SetVariableType(name, name, { nil, { 0, 0 } }, wire_expression_types[v][1])
	end

	for name, v in pairs(delta) do
		self.dvars[name] = v
	end

	local script = Compiler["Instr" .. string.upper(root[1])](self, root)

	return script, self
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

function Compiler:SetVariableType(name, id, instruction, newType)
	local oldType = self.VariableTypes[id]
	if oldType and oldType ~= newType then
		self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") of type [" .. tps_pretty({ oldType }) .. "] cannot be assigned value of type [" .. tps_pretty({ newType }) .. "]", instruction)
	end

	self.VariableTypes[id] = assert(newType)
	return isnumber(id) and 2 or 1
end

function Compiler:GetVariableType(name, id, instruction)
	local type = self.VariableTypes[id]
	if not type then
		self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") does not exist", instruction)
	end
	return type, isnumber(id) and 2 or 1
end

-- ---------------------------------------------------------------------------

function Compiler:EvaluateStatement(args, index)
	local name = string.upper(args[index + 2][1])
	local ex, tp = Compiler["Instr" .. name](self, args[index + 2])
	-- ex.TraceBack = args[index + 2]
	ex.TraceName = name
	return ex, tp
end

function Compiler:Evaluate(args, index)
	local ex, tp = self:EvaluateStatement(args, index)

	if tp == "" then
		self:Error("Function has no return value (void), cannot be part of expression or assigned", args[index + 2])
	end

	return ex, tp
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

	return { Func[3], Func[2], Func[1] }
end


function Compiler:GetMethod(instr, Name, Meta, Args)
	local Params = Meta .. ":" .. table.concat(Args)
	local Func = wire_expression2_funcs[Name .. "(" .. Params .. ")"]

	if not Func then
		Func = self:UDFunction(Name .. "(" .. Params .. ")")
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

	return { Func[3], Func[2], Func[1] }
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

function Compiler:InstrSEQ(args)
	self:PushPrfCounter()

	local stmts = { self:GetOperator(args, "seq", {})[1], 0 }

	for i = 1, #args - 2 do
		stmts[#stmts + 1] = self:EvaluateStatement(args, i)
	end

	stmts[2] = self:PopPrfCounter()

	return stmts
end

function Compiler:InstrBRK(args)
	return { self:GetOperator(args, "brk", {})[1] }
end

function Compiler:InstrCNT(args)
	return { self:GetOperator(args, "cnt", {})[1] }
end

function Compiler:InstrFOR(args)
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

	self:SetVariableType(var, args.Id, args, "n")

	local stmt = self:EvaluateStatement(args, 5)

	return { self:GetOperator(args, "for", {})[1], args.Id, estart, estop, estep, stmt }
end

function Compiler:InstrWHL(args)
	self:PushPrfCounter()
	local cond = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	local stmt = self:EvaluateStatement(args, 2)

	return { self:GetOperator(args, "whl", {})[1], cond, stmt, prf_cond }
end


function Compiler:InstrIF(args)
	self:PushPrfCounter()
	local ex1, tp1 = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	local st1 = self:EvaluateStatement(args, 2)
	local st2 = self:EvaluateStatement(args, 3)

	local rtis = self:GetOperator(args, "is", { tp1 })
	local rtif = self:GetOperator(args, "if", { rtis[2] })
	return { rtif[1], prf_cond, { rtis[1], ex1 }, st1, st2 }
end

function Compiler:InstrDEF(args)
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
	local exprs = { false }

	local tps = {}
	for i = 2, #args - 2 do
		local ex, tp = self:Evaluate(args, i)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	local rt = self:GetFunction(args, args[3], tps)
	exprs[1] = rt[1]
	exprs[#exprs + 1] = tps

	return exprs, rt[2]
end

local kvcallFunctions = {
	-- function name ⇒ allowed key types
	array = { n = true },
	table = { n = true, s = true },
}
function Compiler:InstrKVCALL(args)
	local name = args[3]

	local allowedKeyTypes = kvcallFunctions[name]
	if not allowedKeyTypes then
		self:Error("Function " .. name .. " can't be called with key-value syntax", args)
	end

	local entries = {}
	local types = {}

	for i = 2, #args - 2, 2 do
		local key, keytype = self:Evaluate(args, i)
		if not allowedKeyTypes[keytype] then
			self:Error("Function " .. name .. " doesn't accept keys of type " .. tps_pretty(keytype), args[i + 2])
		end
		local value, valuetype = self:Evaluate(args, i + 1)
		types[key] = valuetype
		entries[key] = value
	end

	local op = self:GetOperator(args, "kv" .. name, {})
	return { op[1], entries, types }, op[2]
end

function Compiler:InstrSCALL(args)
	local name, nameType = self:Evaluate(args, 1)
	if nameType ~= "s" then
		self:Error("User function is not string-type", args)
	end

	-- The scall operator passes the function parameters straight through to the
	-- function whose name is matched. That function, like all E2 functions, expects
	-- to be in a table with its arguments when it's called, with itself as the
	-- first member of the table. For example, f(1) is represented as:
	--     { f, { function() return 1 end } }.
	-- An operator like this can be executed with the familiar pattern op[1](self, op).
	-- The dummy argument false below is a placeholder for scall to make this all
	-- work without having to insert at the beginning of the table at runtime.
	local parameters = { false }
	local parameterTypes = {}
	for i = 3, #args - 2 do
		local parameter, parameterType = self:Evaluate(args, i)
		table.insert(parameters, parameter)
		table.insert(parameterTypes, parameterType)
	end

	local signature = table.concat(parameterTypes)

	local scall = self:GetOperator(args, "scall", {})[1]

	local returnType = args[4]
	return { scall, name, parameters, parameterTypes, signature, returnType }, returnType
end

function Compiler:InstrMTO(args)
	local exprs = { false }

	local tps = {}

	local ex, tp = self:Evaluate(args, 2)
	exprs[#exprs + 1] = ex

	for i = 3, #args - 2 do
		local ex, tp = self:Evaluate(args, i)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	local rt = self:GetMethod(args, args[3], tp, tps)
	exprs[1] = rt[1]
	exprs[#exprs + 1] = tps

	return exprs, rt[2]
end

function Compiler:InstrASS(args)
	local op = args[3]
	local ex, tp = self:Evaluate(args, 2)
	local ScopeID = self:SetVariableType(op, args.Id, args, tp)
	local rt = self:GetOperator(args, "ass", { tp })

	if isstring(args.Id) and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. args.Id, { self:GetOperator(args, "var", {})[1], args.Id, 1 }, 1 }
		stmts[4] = { rt[1], args.Id, ex, 1 }
		return stmts, tp
	else
		assert(ScopeID == 1 or ScopeID == 2)
		return { rt[1], args.Id, ex, ScopeID }, tp
	end
end

function Compiler:InstrASSL(args)
	local op = args[3]
	local ex, tp = self:Evaluate(args, 2)
	local ScopeID = self:SetVariableType(op, args.Id, args, tp)
	local rt = self:GetOperator(args, "ass", { tp })

	return { rt[1], args.Id, ex, ScopeID }, tp
end

function Compiler:InstrGET(args)
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
		local ex1, tp1 = self:Evaluate(args, 1)
		local ex2, tp2 = self:Evaluate(args, 2)
		local rt = self:GetOperator(args, operator, { tp1, tp2 })
		return { rt[1], ex1, ex2 }, rt[2]
	end
end

function Compiler:InstrINC(args)
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(op, args.Id, args)
	local rt = self:GetOperator(args, "inc", { tp })

	if isstring(args.Id) and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. args.Id, { self:GetOperator(args, "var", {})[1], args.Id, ScopeID }, ScopeID }
		stmts[4] = { rt[1], args.Id, ScopeID }
		return stmts
	else
		return { rt[1], args.Id, ScopeID }
	end
end

function Compiler:InstrDEC(args)
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(op, args.Id, args)
	local rt = self:GetOperator(args, "dec", { tp })

	if isstring(args.Id) and self.dvars[op] then
		local stmts = { self:GetOperator(args, "seq", {})[1], 0 }
		stmts[3] = { self:GetOperator(args, "ass", { tp })[1], "$" .. args.Id, { self:GetOperator(args, "var", {})[1], args.Id, ScopeID }, ScopeID }
		stmts[4] = { rt[1], args.Id, ScopeID }
		return stmts
	else
		return { rt[1], args.Id, ScopeID }
	end
end

function Compiler:InstrNEG(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt = self:GetOperator(args, "neg", { tp1 })
	return { rt[1], ex1 }, rt[2]
end


function Compiler:InstrNOT(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt = self:GetOperator(args, "not", { rt1is[2] })
	return { rt[1], { rt1is[1], ex1 } }, rt[2]
end

function Compiler:InstrAND(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt2is = self:GetOperator(args, "is", { tp2 })
	local rt = self:GetOperator(args, "and", { rt1is[2], rt2is[2] })
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end

function Compiler:InstrOR(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is = self:GetOperator(args, "is", { tp1 })
	local rt2is = self:GetOperator(args, "is", { tp2 })
	local rt = self:GetOperator(args, "or", { rt1is[2], rt2is[2] })
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end


function Compiler:InstrTRG(args)
	local op = args[3]
	if not self.inputs[op] then
		self:Error("Triggered operator (~" .. E2Lib.limitString(op, 10) .. ") can only be used on inputs", args)
	end
	local rt = self:GetOperator(args, "trg", {})
	return { rt[1], op }, rt[2]
end

function Compiler:InstrDLT(args)
	local op = args[3]
	local tp, ScopeID = self:GetVariableType(op, args.Id, args)

	if not isstring(args.Id) or not self.dvars[op] then
		self:Error("Delta operator ($" .. E2Lib.limitString(op, 10) .. ") cannot be used on temporary variables", args)
	end

	self.dvars[op] = true
	local rt = self:GetOperator(args, "sub", { tp, tp })
	local rtvar = self:GetOperator(args, "var", {})
	return { rt[1], { rtvar[1], args.Id, ScopeID }, { rtvar[1], "$" .. args.Id, ScopeID } }, rt[2]
end

function Compiler:InstrIWC(args)
	local op = args[3]

	if self.inputs[op] then
		local rt = self:GetOperator(args, "iwc", {})
		return { rt[1], op }, rt[2]
	elseif self.outputs[op] then
		local rt = self:GetOperator(args, "owc", {})
		return { rt[1], op }, rt[2]
	else
		self:Error("Connected operator (->" .. E2Lib.limitString(op, 10) .. ") can only be used on inputs or outputs", args)
	end
end
function Compiler:InstrLITERAL(args)
	self.prfcounter = self.prfcounter + 0.5
	local value = args[3]
	return { function() return value end }, args[4]
end

function Compiler:InstrVAR(args)
	self.prfcounter = self.prfcounter + 1.0
	local name, id = args[3], args.Id
	local type = self:GetVariableType(name, id, args)

	local func
	if isnumber(id) then -- local
		func = function(self)
			return self.Scope[id]
		end
	else -- global
		func = function(self)
			return self.GlobalScope[id]
		end
	end

	return { func }, type
end

function Compiler:InstrFEA(args)
	-- local sfea = self:Instruction(trace, "fea", keyvar, keytype, valvar, valtype, tableexpr, self:Block("foreach statement"))
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

	self:SetVariableType(keyvar, args.KeyId, args, keytype)
	self:SetVariableType(valvar, args.ValueId, args, valtype)

	local stmt = self:EvaluateStatement(args, 6)

	return {op[1], args.KeyId, args.ValueId, tableexpr, stmt}
end


function Compiler:InstrFUNCTION(args)

	local Sig, Return, Args = args[3], args[4], args[6]
	Return = Return or ""

	for _, D in pairs(Args) do
		local Name, Type = D[1], wire_expression_types[D[2]][1]
		self:SetVariableType(Name, D.Id, args, Type)
	end

	if self.funcs_ret[Sig] and self.funcs_ret[Sig] ~= Return then
		local TP = tps_pretty(self.funcs_ret[Sig])
		self:Error("Function " .. Sig .. " must be given return type " .. TP, args)
	end

	self.funcs_ret[Sig] = Return

	self.func_ret = Return

	local Stmt = self:EvaluateStatement(args, 5) -- Offset of -2

	self.func_ret = nil

	self.prfcounter = self.prfcounter + 40

	return { self:GetOperator(args, "function", {})[1], Stmt, args }
end

function Compiler:InstrRETURN(args)
	local Value, Type = self:Evaluate(args, 1)

	if not self.func_ret or self.func_ret == "" then
		self:Error("Return type mismatch: void expected, got " .. tps_pretty(Type), args)
	elseif self.func_ret ~= Type then
		self:Error("Return type mismatch: " .. tps_pretty(self.func_ret) .. " expected, got " .. tps_pretty(Type), args)
	end

	return { self:GetOperator(args, "return", {})[1], Value, Type }
end

function Compiler:InstrRETURNVOID(args)
	if self.func_ret and self.func_ret ~= "" then
		self:Error("Return type mismatch: " .. tps_pretty(self.func_ret) .. " expected got, void", args)
	end

	return { self:GetOperator(args, "return", {})[1], nil, nil }
end

function Compiler:InstrSWITCH(args)
	self:PushPrfCounter()
	local value, type = Compiler["Instr" .. string.upper(args[3][1])](self, args[3]) -- This is the value we are passing though the switch statment
	local prf_cond = self:PopPrfCounter()

	local cases = {}
	local Cases = args[4]
	local default
	for i = 1, #Cases do
		local case, block, prf_eq, eq = Cases[i][1], Cases[i][2], 0, nil
		if case then -- The default will not have one
			self:PushPrfCounter()
			local ex, tp = Compiler["Instr" .. string.upper(case[1])](self, case) --This is the value we are checking against
			prf_eq = self:PopPrfCounter() -- We add some pref
			if tp == "" then -- There is no value
				self:Error("Function has no return value (void), cannot be part of expression or assigned", args)
			elseif tp ~= type then -- Value types do not match.
				self:Error("Case missmatch can not compare " .. tps_pretty(type) .. " with " .. tps_pretty(tp), args)
			end
			eq = { self:GetOperator(args, "eq", { type, tp })[1], value, ex } -- This is the equals operator to check if values match
		else
			default=i
		end
		local stmts = Compiler["Instr" .. string.upper(block[1])](self, block) -- This is statments that are run when Values match
		cases[i] = { eq, stmts, prf_eq }
	end


	local rtswitch = self:GetOperator(args, "switch", {})
	return { rtswitch[1], prf_cond, cases, default }
end

function Compiler:InstrINCLU(args)

	local file = args[3]
	local include = self.includes[file]

	assert(include and include[1])

	if not include[2] then

		include[2] = true -- Tempory value to prvent E2 compiling itself when itself. (INFINATE LOOOP!)

		local root = include[1]
		local status, script = pcall(Compiler["Instr" .. string.upper(root[1])], self, root)

		if not status then
			if script:find("C stack overflow") then script = "Include depth to deep" end

			if not self.IncludeError then
				-- Otherwise Errors messages will be wrapped inside other error messages!
				self.IncludeError = true
				self:Error("include '" .. file .. "' -> " .. script, args)
			else
				error(script, 0)
			end
		end

		include[2] = script

	end


	return { self:GetOperator(args, "include", {})[1], file }
end
