/******************************************************************************\
  Expression 2 Compiler for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

AddCSLuaFile("compiler.lua")

Compiler = {}
Compiler.__index = Compiler

function Compiler.Execute(...)
	-- instantiate Compiler
	local instance = setmetatable({}, Compiler)

	-- and pcall the new instance's Process method.
	return pcall(Compiler.Process, instance, ...)
end

function Compiler:Error(message, instr)
	error(message .. " at line " .. instr[2][1] .. ", char " .. instr[2][2], 0)
end

function Compiler:Process(root, inputs, outputs, persist, delta, params)
	self.context = {}

	self:PushContext()

	self.inputs = inputs
	self.prfcounter = 0
	self.prfcounters = {}
	self.dvars = {}
	self.tvars = {}
	self.vars = {}

	for name,v in pairs(inputs) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1], {nil, {0, 0}})
	end
	for name,v in pairs(outputs) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1], {nil, {0, 0}})
	end
	for name,v in pairs(persist) do
		self.vars[name] = v
		self:SetVariableType(name, wire_expression_types[v][1], {nil, {0, 0}})
	end
	for name,v in pairs(delta) do
		self.dvars[name] = v
	end

	self:PushContext()
	local script = Compiler["Instr" .. string.upper(root[1])](self, root)
	local ctx = self:PopContext()

	local init = {self:GetOperator(args, "seq", {})[1], 0}
	for name,tp in pairs(self.tvars) do
		self:SetVariableType(name, tp, args)
		init[#init + 1] = { self:GetOperator(args, "ass", {tp})[1], name, { self:GetOperator(args, "dat", {})[1], wire_expression_types2[tp][2] } }
	end
	init[#init + 1] = script

	return init, self.dvars
end

/******************************************************************************/

function Compiler:EvaluateStatement(args, index)
	local name = string.upper(args[index + 2][1])
	local ex, tp = Compiler["Instr" .. name](self, args[index + 2])
	return ex, tp
end

function Compiler:Evaluate(args, index)
	local ex, tp = self:EvaluateStatement(args, index)

	if tp == "" then
		self:Error("Function has no return value (void), cannot be part of expression or assigned", args)
	end

	return ex, tp
end

local function tps_pretty(tps)
	local ttt = {}
	for i=1,#tps do
		ttt[i] = string.lower(wire_expression_types2[tps[i]][1])
		if ttt[i] == "NORMAL" then ttt[i] = "number" end
	end
	return table.concat(ttt, ", ")
end

local function op_find(name)
	return E2Lib.optable_inv[name]
end

function Compiler:HasOperator(instr, name, tps)
	pars = table.concat(tps)
	local a = wire_expression2_funcs["op:" .. name .. "(" .. pars .. ")"]
	return a and true or false
end

function Compiler:AssertOperator(instr, name, alias, tps)
	if not self:HasOperator(instr, name, tps) then
		self:Error("No such operator: " .. op_find(alias) .. "(".. tps_pretty(tps) ..")", instr)
	end
end

function Compiler:GetOperator(instr, name, tps)
	pars = table.concat(tps)
	local a = wire_expression2_funcs["op:" .. name .. "(" .. pars .. ")"]
	if not a then
		self:Error("No such operator: " .. op_find(name) .. "(".. tps_pretty(tps) ..")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (a[4] or 3)

	return { a[3], a[2], a[1] }
end

function Compiler:GetFunction(instr, name, tps)
	pars = table.concat(tps)
	local a = wire_expression2_funcs[name .. "(" .. pars .. ")"]
	if !a then
		for i = #pars,0,-1 do
			a = wire_expression2_funcs[name .. "(" .. pars:sub(1,i) .. "...)"]
			if a then break end
		end
	end
	if !a then
		self:Error("No such function: " .. name .. "(".. tps_pretty(tps) ..")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (a[4] or 20)

	return { a[3], a[2], a[1] }
end

function Compiler:GetMethod(instr, name, tp, tps)
	pars = tp .. ":" .. table.concat(tps)
	local a = wire_expression2_funcs[name .. "(" .. pars .. ")"]
	if !a then
		for i = #pars,#tp+1,-1 do
			a = wire_expression2_funcs[name .. "(" .. pars:sub(1,i) .. "...)"]
			if a then break end
		end
	end
	if !a then
		self:Error("No such function: " .. tps_pretty({tp}) .. ":" .. name .. "("..tps_pretty(tps) ..")", instr)
		return
	end

	self.prfcounter = self.prfcounter + (a[4] or 20)

	return { a[3], a[2], a[1] }
end

function Compiler:PushContext()
	self.context[#self.context + 1] = {}
end

function Compiler:PopContext()
	local context = self.context[#self.context]
	self.context[#self.context] = nil
	return context
end

function Compiler:SingleContext(cx, instr)
	for name,tp in pairs(cx) do
		self:SetVariableType(name, tp, instr)
		self.tvars[name] = tp
	end
end

function Compiler:MergeContext(cx1, cx2, instr)
	for name,tp in pairs(cx1) do
		if cx2[name] and cx2[name] != tp then
			self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") is assigned different types (" .. tps_pretty({tp}) .. ", " .. tps_pretty({cx2[name]}) .. ") in if-statement", instr)
		end
	end

	for name,tp in pairs(cx1) do
		self:SetVariableType(name, tp, instr)
		if !cx2[name] then self.tvars[name] = tp end
	end

	for name,tp in pairs(cx2) do
		self:SetVariableType(name, tp, instr)
		if !cx1[name] then self.tvars[name] = tp end
	end
end


function Compiler:SetVariableType(name, tp, instr)
	for i=#self.context,1,-1 do
		if self.context[i][name] then
			if self.context[i][name] != tp then self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") of type [" .. tps_pretty({self.context[i][name]}) .. "] cannot be assigned value of type [" .. tps_pretty({tp}) .. "]", instr) end
			return
		end
	end

	self.context[#self.context][name] = tp
end

function Compiler:GetVariableType(instr, name)
	for i=1,#self.context do
		if self.context[i][name] then return self.context[i][name] end
	end

	self:Error("Variable (" .. E2Lib.limitString(name, 10) .. ") does not exist", instr)
	return nil
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

/******************************************************************************/

function Compiler:InstrSEQ(args)
	self:PushPrfCounter()

	local stmts = {self:GetOperator(args, "seq", {})[1], 0}

	for i=1,#args-2 do
		stmts[#stmts + 1] = self:EvaluateStatement(args, i)
	end

	stmts[2] = self:PopPrfCounter()

	return stmts
end

function Compiler:InstrBRK(args)
	return {self:GetOperator(args, "brk", {})[1]}
end

function Compiler:InstrCNT(args)
	return {self:GetOperator(args, "cnt", {})[1]}
end

function Compiler:InstrFOR(args)
	self:PushContext()

	local var = args[3]
	self:SetVariableType(var, "n", args)

	local estart = self:Evaluate(args, 2)
	local estop = self:Evaluate(args, 3)
	local estep
	if args[6] then estep = self:Evaluate(args, 4) end

	local stmt = self:EvaluateStatement(args, 5)
	local cx = self:PopContext()

	self:SingleContext(cx, args)

	return {self:GetOperator(args, "for", {})[1], var, estart, estop, estep, stmt}
end

function Compiler:InstrWHL(args)
	self:PushContext()

	self:PushPrfCounter()
	local cond = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	local stmt = self:EvaluateStatement(args, 2)
	local cx = self:PopContext()

	self:SingleContext(cx, args)

	return {self:GetOperator(args, "whl", {})[1], cond, stmt, prf_cond}
end


function Compiler:InstrIF(args)
	self:PushPrfCounter()
	local ex1, tp1 = self:Evaluate(args, 1)
	local prf_cond = self:PopPrfCounter()

	self:PushContext()
	local st1 = self:EvaluateStatement(args, 2)
	local cx1 = self:PopContext()

	self:PushContext()
	local st2 = self:EvaluateStatement(args, 3)
	local cx2 = self:PopContext()

	self:MergeContext(cx1, cx2, args)

	local rtis = self:GetOperator(args, "is", {tp1})
	local rtif = self:GetOperator(args, "if", {rtis[2]})
	return { rtif[1], prf_cond, { rtis[1], ex1 }, st1, st2 }
end

function Compiler:InstrDEF(args)
	local ex1, tp1 = self:Evaluate(args, 1)

	self:PushPrfCounter()
	local ex2, tp2 = self:Evaluate(args, 2)
	local prf_ex2 = self:PopPrfCounter()

	local rtis = self:GetOperator(args, "is", {tp1})
	local rtif = self:GetOperator(args, "def", {rtis[2]})
	local rtdat = self:GetOperator(args, "dat", {})

	if tp1 != tp2 then
		self:Error("Different types (" .. tps_pretty({tp1}) .. ", " .. tps_pretty({tp2}) .. ") specified returned in default conditional", args)
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

	local rtis = self:GetOperator(args, "is", {tp1})
	local rtif = self:GetOperator(args, "cnd", {rtis[2]})

	if tp2 != tp3 then
		self:Error("Different types (" .. tps_pretty({tp2}) .. ", " .. tps_pretty({tp3}) .. ") returned in conditional", args)
	end

	return { rtif[1], { rtis[1], ex1 }, ex2, ex3, prf_ex2, prf_ex3 }, tp2
end


function Compiler:InstrFUN(args)
	local exprs = {false}

	local tps = {}
	for i=1,#args[4] do
		local ex, tp = self:Evaluate(args[4], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	local rt = self:GetFunction(args, args[3], tps)
	exprs[1] = rt[1]
	exprs[#exprs+1] = tps

	return exprs, rt[2]
end

function Compiler:InstrMTO(args)
	local exprs = {false}

	local tps = {}

	local ex, tp = self:Evaluate(args, 2)
	exprs[#exprs + 1] = ex

	for i=1,#args[5] do
		local ex, tp = self:Evaluate(args[5], i - 2)
		tps[#tps + 1] = tp
		exprs[#exprs + 1] = ex
	end

	local rt = self:GetMethod(args, args[3], tp, tps)
	exprs[1] = rt[1]
	exprs[#exprs+1] = tps

	return exprs, rt[2]
end

function Compiler:InstrASS(args)
	local op     = args[3]
	local ex, tp = self:Evaluate(args, 2)
	local rt     = self:GetOperator(args, "ass", {tp})

	self:SetVariableType(op, tp, args)

	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1], 0}
		stmts[3] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[4] = {rt[1], op, ex}
		return stmts, tp
	else
		return {rt[1], op, ex}, tp
	end
end

function Compiler:InstrGET(args)
	local ex,  tp  = self:Evaluate(args, 1)
	local ex1, tp1 = self:Evaluate(args, 2)
	local      tp2 = args[5]

	if tp2 == nil then
		if !self:HasOperator(args, "idx", {tp,tp1}) then
			self:Error("No such operator: get " .. tps_pretty({tp}) .. "[".. tps_pretty({tp1}) .."]", args)
		end

		local rt = self:GetOperator(args, "idx", {tp,tp1})
		return {rt[1], ex, ex1}, rt[2]
	else
		if !self:HasOperator(args, "idx", {tp2, "=", tp,tp1}) then
			self:Error("No such operator: get " .. tps_pretty({tp}) .. "[".. tps_pretty({tp1, tp2}) .."]", args)
		end

		local rt = self:GetOperator(args, "idx", {tp2, "=", tp,tp1})
		return {rt[1], ex, ex1}, tp2
	end
end

function Compiler:InstrSET(args)
	local op       = args[3]
	local ex1, tp1 = self:Evaluate(args, 2)
	local ex2, tp2 = self:Evaluate(args, 3)

	if args[6] == nil then
		local tp = self:GetVariableType(args, op)

		if !self:HasOperator(args, "idx", {tp,tp1,tp2}) then
			self:Error("No such operator: set " .. tps_pretty({tp}) .. "[".. tps_pretty({tp1}) .."]=" .. tps_pretty({tp2}), args)
		end

		local rt = self:GetOperator(args, "idx", {tp,tp1,tp2})

		RunString("native = function(self) return self.vars[" .. string.format("%q", op) .. "] end")
		return {rt[1], {native}, ex1, ex2}, rt[2]
	else
		if tp2 != args[6] then
			self:Error("Indexing type-mismatch, specified [" .. tps_pretty({args[6]}) .. "] but value is [" .. tps_pretty({tp2}) .. "]", args)
		end

		local tp = self:GetVariableType(args, op)

		if !self:HasOperator(args, "idx", {tp2, "=", tp,tp1,tp2}) then
			self:Error("No such operator: set " .. tps_pretty({tp}) .. "[".. tps_pretty({tp1, tp2}) .."]", args)
		end
		local rt = self:GetOperator(args, "idx", {tp2, "=", tp,tp1,tp2})

		RunString("native = function(self) return self.vars[" .. string.format("%q", op) .. "] end")
		return {rt[1], {native}, ex1, ex2}, tp2
	end
end

-- generic code for all binary non-boolean operators
for _,operator in ipairs({"add", "sub", "mul", "div", "mod", "exp", "eq", "neq", "geq", "leq", "gth", "lth"}) do
	Compiler["Instr"..operator:upper()] = function(self, args)
		local ex1, tp1 = self:Evaluate(args, 1)
		local ex2, tp2 = self:Evaluate(args, 2)
		local rt       = self:GetOperator(args, operator, {tp1, tp2})
		return { rt[1], ex1, ex2 }, rt[2]
	end
end

function Compiler:InstrINC(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "inc", {tp})

	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1], 0}
		stmts[3] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[4] = {rt[1], op}
		return stmts
	else
		return {rt[1], op}
	end
end

function Compiler:InstrDEC(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "dec", {tp})

	if self.dvars[op] then
		local stmts = {self:GetOperator(args, "seq", {})[1], 0}
		stmts[3] = {self:GetOperator(args, "ass", {tp})[1], "$" .. op, {self:GetOperator(args, "var", {})[1], op}}
		stmts[4] = {rt[1], op}
		return stmts
	else
		return {rt[1], op}
	end
end

function Compiler:InstrNEG(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt       = self:GetOperator(args, "neg", {tp1})
	return { rt[1], ex1 }, rt[2]
end


function Compiler:InstrNOT(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt       = self:GetOperator(args, "not", {rt1is[2]})
	return { rt[1], { rt1is[1], ex1 } }, rt[2]
end

function Compiler:InstrAND(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt2is    = self:GetOperator(args, "is", {tp2})
	local rt       = self:GetOperator(args, "and", {rt1is[2], rt2is[2]})
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end

function Compiler:InstrOR(args)
	local ex1, tp1 = self:Evaluate(args, 1)
	local ex2, tp2 = self:Evaluate(args, 2)
	local rt1is    = self:GetOperator(args, "is", {tp1})
	local rt2is    = self:GetOperator(args, "is", {tp2})
	local rt       = self:GetOperator(args, "or", {rt1is[2], rt2is[2]})
	return { rt[1], { rt1is[1], ex1 }, { rt2is[1], ex2 } }, rt[2]
end


function Compiler:InstrTRG(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "trg", {})
	return {rt[1], op}, rt[2]
end

function Compiler:InstrDLT(args)
	local op = args[3]
	local tp = self:GetVariableType(args, op)
	if !self.vars[op] then
		self:Error("Delta operator ($" .. E2Lib.limitString(op, 10) .. ") cannot be used on temporary variables", args)
	end
	self.dvars[op] = true
	self:AssertOperator(args, "sub", "dlt", {tp, tp})
	local rt = self:GetOperator(args, "sub", {tp, tp})
	local rtvar = self:GetOperator(args, "var", {})
	return {rt[1], {rtvar[1], op}, {rtvar[1], "$" .. op}}, rt[2]
end

function Compiler:InstrIWC(args)
	local op = args[3]

	if !self.inputs[op] then
		self:Error("Connected operator (->" .. E2Lib.limitString(op, 10) .. ") can only be used on inputs", args)
	end

	local tp = self:GetVariableType(args, op)
	local rt = self:GetOperator(args, "iwc", {})
	return {rt[1], op}, rt[2]
end

function Compiler:InstrNUM(args)
	self.prfcounter = self.prfcounter + 0.5
	RunString("Compiler.native = function() return " .. args[3] .. " end")
	return {Compiler.native}, "n"
end

function Compiler:InstrNUMI(args)
	self.prfcounter = self.prfcounter + 1
	Compiler.native = { 0, tonumber(args[3]) }
	RunString("local value = Compiler.native Compiler.native = function() return value end")
	return {Compiler.native}, "c"
end

function Compiler:InstrNUMJ(args)
	self.prfcounter = self.prfcounter + 1
	Compiler.native = { 0, 0, tonumber(args[3]), 0 }
	RunString("local value = Compiler.native Compiler.native = function() return value end")
	return {Compiler.native}, "q"
end

function Compiler:InstrNUMK(args)
	self.prfcounter = self.prfcounter + 1
	Compiler.native = { 0, 0, 0, tonumber(args[3]) }
	RunString("local value = Compiler.native Compiler.native = function() return value end")
	return {Compiler.native}, "q"
end

function Compiler:InstrSTR(args)
	self.prfcounter = self.prfcounter + 1.0
	RunString(string.format("Compiler.native = function() return %q end", args[3]))
	return {Compiler.native}, "s"
end

function Compiler:InstrVAR(args)
	self.prfcounter = self.prfcounter + 1.0
	local tp = self:GetVariableType(args, args[3])
	RunString(string.format("Compiler.native = function(self) return self.vars[%q] end", args[3]))
	return {Compiler.native}, tp
end
