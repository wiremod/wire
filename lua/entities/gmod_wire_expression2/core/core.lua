--------------------------------------------------------------------------------
--  Core language support
--------------------------------------------------------------------------------

local delta = wire_expression2_delta

__e2setcost(1) -- approximation

registerOperator("dat", "", "", function(self, args)
	return istable(args[2]) and table.Copy(args[2]) or args[2]
end)

__e2setcost(2) -- approximation

registerOperator("var", "", "", function(self, args)
	local op1, scope = args[2], args[3]
	local val = self.Scopes[scope][op1]
	return val
end)

--------------------------------------------------------------------------------

__e2setcost(0)

registerOperator("seq", "", "", function(self, args)
	self.prf = self.prf + args[2]
	if self.prf > e2_tickquota then error("perf", 0) end

	local n = #args
	if n == 2 then return end

	for i=3,n-1 do
		local op = args[i]
		op[1](self, op)
	end

	local op = args[n]
	return op[1](self, op)
end)

--------------------------------------------------------------------------------

__e2setcost(0) -- approximation

registerOperator("whl", "", "", function(self, args)
	local op1, op2 = args[2], args[3]

	self.prf = self.prf + args[4] + 3
	while op1[1](self, op1) ~= 0 do
		self:PushScope()
		local ok, msg = pcall(op2[1], self, op2)
		if not ok then
			if msg == "break" then self:PopScope() break
			elseif msg ~= "continue" then self:PopScope() error(msg, 0) end
		end

		self.prf = self.prf + args[4] + 3
		self:PopScope()
	end
end)

registerOperator("for", "", "", function(self, args)
	local var, op1, op2, op3, op4 = args[2], args[3], args[4], args[5], args[6]

	local rstart, rend, rstep
	rstart = op1[1](self, op1)
	rend = op2[1](self, op2)
	local rdiff = rend - rstart
	local rdelta = delta

	if op3 then
		rstep = op3[1](self, op3)

		if rdiff > -delta then
			if rstep < delta and rstep > -delta then return end
		elseif rdiff < delta then
			if rstep > -delta then return end
		else
			return
		end

		if rstep < 0 then
			rdelta = -delta
		end
	else
		if rdiff > -delta then
			rstep = 1
		else
			return
		end
	end

	self.prf = self.prf + 3
	for I=rstart,rend+rdelta,rstep do
		self:PushScope()
		self.Scope[var] = I
		self.Scope.vclk[var] = true

		local ok, msg = pcall(op4[1], self, op4)
		if not ok then
			if msg == "break" then self:PopScope() break
			elseif msg ~= "continue" then self:PopScope() error(msg, 0) end
		end

		self.prf = self.prf + 3
		self:PopScope()
	end

end)

registerOperator("fea","r","",function(self,args)
	local keyname,valname,valtypeid = args[2],args[3],args[4]
	local tbl = args[5]
	tbl = tbl[1](self,tbl)
	local statement = args[6]

	local typechecker = wire_expression_types2[valtypeid][6]

	local keys = {}
	local count = 0
	for key,value in pairs(tbl) do
		if not typechecker(value) then
			count = count + 1
			keys[count] = key
		end
	end

	for i=1,count do
		self:PushScope()
		local key = keys[i]
		if tbl[key] ~= nil then
			self.prf = self.prf + 3

			self.Scope[keyname] = key
			self.Scope[valname] = tbl[key]
			self.Scope.vclk[keyname] = true
			self.Scope.vclk[valname] = true

			local ok, msg = pcall(statement[1], self, statement)
			if not ok then
				if msg == "break" then
					self:PopScope()
					break
				elseif msg ~= "continue" then
					self:PopScope()
					error(msg, 0)
				end
			end
		end
		self:PopScope()
	end
end)

__e2setcost(2) -- approximation

registerOperator("brk", "", "", function(self, args)
	error("break", 0)
end)

registerOperator("cnt", "", "", function(self, args)
	error("continue", 0)
end)

--------------------------------------------------------------------------------

__e2setcost(3) -- approximation

registerOperator("if", "n", "", function(self, args)
	local op1 = args[3]
	self.prf = self.prf + args[2]

	local ok, result

	if op1[1](self, op1) ~= 0 then
		self:PushScope()
		local op2 = args[4]
		ok, result = pcall(op2[1],self, op2)
	else
		self:PushScope() -- for else statments, elseif staments will run the if opp again
		local op3 = args[5]
		ok, result = pcall(op3[1],self, op3)
	end

	self:PopScope()
	if not ok then
		error(result,0)
	end
end)

registerOperator("def", "n", "", function(self, args)
	local op1 = args[2]
	local op2 = args[3]
	local rv2 = op2[1](self, op2)

	-- sets the argument for the DAT-operator
	op1[2][2] = rv2
	local rv1 = op1[1](self, op1)

	if rv1 ~= 0 then
		return rv2
	else
		self.prf = self.prf + args[5]
		local op3 = args[4]
		return op3[1](self, op3)
	end
end)

registerOperator("cnd", "n", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 ~= 0 then
		self.prf = self.prf + args[5]
		local op2 = args[3]
		return op2[1](self, op2)
	else
		self.prf = self.prf + args[6]
		local op3 = args[4]
		return op3[1](self, op3)
	end
end)

--------------------------------------------------------------------------------

__e2setcost(1) -- approximation

registerOperator("trg", "", "n", function(self, args)
	local op1 = args[2]
	return self.triggerinput == op1 and 1 or 0
end)


registerOperator("iwc", "", "n", function(self, args)
	local op1 = args[2]
	return IsValid(self.entity.Inputs[op1].Src) and 1 or 0
end)

registerOperator("owc","","n",function(self,args)
	local op1 = args[2]
	local tbl = self.entity.Outputs[op1].Connected
	local ret = #tbl
	for i=1,ret do if (not IsValid(tbl[i].Entity)) then ret = ret - 1 end end
	return ret
end)

--------------------------------------------------------------------------------

__e2setcost(0) -- cascaded

registerOperator("is", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 ~= 0 and 1 or 0
end)

__e2setcost(1) -- approximation

registerOperator("not", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 == 0 and 1 or 0
end)

registerOperator("and", "nn", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == 0 then return 0 end

	local op2 = args[3]
	local rv2 = op2[1](self, op2)
	return rv2 ~= 0 and 1 or 0
end)

registerOperator("or", "nn", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 ~= 0 then return 1 end

	local op2 = args[3]
	local rv2 = op2[1](self, op2)
	return rv2 ~= 0 and 1 or 0
end)

--------------------------------------------------------------------------------

__e2setcost(1) -- approximation

e2function number first()
	return self.entity.first and 1 or 0
end

e2function number duped()
	return self.entity.duped and 1 or 0
end

e2function number inputClk()
	return self.triggerinput and 1 or 0
end

e2function string inputClkName()
	return self.triggerinput or ""
end

-- This MUST be the first destruct hook!
registerCallback("destruct", function(self)
	local entity = self.entity
	if entity.error then return end
	if not entity.script then return end
	if not self.data.runOnLast then return end

	self.resetting = false
	self.data.runOnLast = false

	self.data.last = true
	entity:Execute()
	self.data.last = false
end)

--- Returns 1 if it is being called on the last execution of the expression gate before it is removed or reset. This execution must be requested with the runOnLast(1) command.
e2function number last()
	return self.data.last and 1 or 0
end

-- dupefinished()
-- Made by Divran

local function dupefinished( TimedPasteData, TimedPasteDataCurrent )
	for k,v in pairs( TimedPasteData[TimedPasteDataCurrent].CreatedEntities ) do
		if (isentity(v) and v:IsValid() and v:GetClass() == "gmod_wire_expression2") then
			v.dupefinished = true
			v:Execute()
			v.dupefinished = nil
		end
	end
end
hook.Add("AdvDupe_FinishPasting", "E2_dupefinished", dupefinished )

e2function number dupefinished()
	return self.entity.dupefinished and 1 or 0
end

--- Returns 1 if this is the last() execution and caused by the entity being removed.
e2function number removing()
	return self.entity.removing and 1 or 0
end

--- If <activate> != 0, the chip will run once when it is removed, setting the last() flag when it does.
e2function void runOnLast(activate)
	if self.data.last then return end
	self.data.runOnLast = activate ~= 0
end

--------------------------------------------------------------------------------

__e2setcost(2) -- approximation

e2function void exit()
	error("exit", 0)
end

e2function void error( string reason )
	error(reason, 2)
end

--------------------------------------------------------------------------------

__e2setcost(100) -- approximation

e2function void reset()
	if self.data.last or self.entity.first then error("exit", 0) end

	if self.entity.last_reset and self.entity.last_reset == CurTime() then
		error("Attempted to reset the E2 twice in the same tick!", 2)
	end
	self.entity.last_reset = CurTime()

	self.data.reset = true
	error("exit", 0)
end

-- wrapping this in a postinit hook to make sure this is the last postexecute hook in the list
registerCallback("postinit", function()
	-- handle reset()
	registerCallback("postexecute", function(self)
		if self.data.reset then
			self.entity:Reset()
			self.data.reset = false

			-- do not execute any other postexecute hooks after this one.
			error("cancelhook", 0)
		end
	end)
end)

--------------------------------------------------------------------------------

local floor  = math.floor
local ceil   = math.ceil
local round  = math.Round

__e2setcost(1) -- approximation

e2function number ops()
	return round(self.prfbench)
end

e2function number entity:ops()
	if not IsValid(this) or this:GetClass() ~= "gmod_wire_expression2" or not this.context then return 0 end
	return round(this.context.prfbench)
end

e2function number opcounter()
	return ceil(self.prf + self.prfcount)
end

e2function number cpuUsage()
	return self.timebench
end

e2function number entity:cpuUsage()
	if not IsValid(this) or this:GetClass() ~= "gmod_wire_expression2" or not this.context then return 0 end
	return this.context.timebench
end

--- If used as a while loop condition, stabilizes the expression around <maxexceed> hardquota used.
e2function number perf()
	if self.prf >= e2_tickquota*0.95-200 then return 0 end
	if self.prf + self.prfcount >= e2_hardquota then return 0 end
	if self.prf >= e2_softquota*2 then return 0 end
	return 1
end

e2function number perf(number n)
	n = math.Clamp(n, 0, 100)
	if self.prf >= e2_tickquota*n*0.01 then return 0 end
	if self.prf + self.prfcount >= e2_hardquota * n * 0.01 then return 0 end
	if n == 100 then
		if self.prf >= e2_softquota * 2 then return 0 end
	else
		if self.prf >= e2_softquota * n * 0.01 then return 0 end
	end
	return 1
end

e2function number minquota()
	if self.prf < e2_softquota then
		return floor(e2_softquota - self.prf)
	else
		return 0
	end
end

e2function number maxquota()
	if self.prf < e2_tickquota then
		local tickquota = e2_tickquota - self.prf
		local hardquota = e2_hardquota - self.prfcount - self.prf + e2_softquota

		if hardquota < tickquota then
			return floor(hardquota)
		else
			return floor(tickquota)
		end
	else
		return 0
	end
end

e2function number softQuota()
	return e2_softquota
end

e2function number hardQuota()
	return e2_hardquota
end

__e2setcost(nil)

registerCallback("postinit", function()
	-- Returns the Nth value given after the index, the type's zero element otherwise. If you mix types, all non-matching arguments will be regarded as the 2nd argument's type's zero element.
	for name,id,zero in pairs_map(wire_expression_types, unpack) do
		registerFunction("select", "n"..id.."...", id, function(self, args)
			local index = args[2]
			index = index[1](self, index)

			index = math.Clamp(math.floor(index), 1, #args-3)

			if index ~= 1 and args[#args][index+1] ~= id then return zero end
			local value = args[index+2]
			value = value[1](self, value)
			return value
		end, 5, { "index", "argument1" })
	end
end)

--------------------------------------------------------------------------------

__e2setcost(3) -- approximation

registerOperator("switch", "", "", function(self, args)
	local cases, startcase = args[3], args[4]

	self:PushScope()

	for i=1, #cases do -- We figure out what we can run.
		local case = cases[i]
		local op1 = case[1]

		self.prf = self.prf + case[3]
		if self.prf > e2_tickquota then error("perf", 0) end

		if (op1 and op1[1](self, op1) == 1) then -- Equals operator
			startcase = i
			break
		end
	end

	if startcase then
		for i=startcase, #cases do
			local stmts = cases[i][2]
			local ok, msg = pcall(stmts[1], self, stmts)
			if not ok then
				if msg == "break" then
					break
				elseif msg ~= "continue" then
					self:PopScope()
					error(msg, 0)
				end
			end
		end
	end

	self:PopScope()
end)

registerOperator("include", "", "", function(self, args)
	local Include = self.includes[ args[2] ]

	if Include and Include[2] then
		local Script = Include[2]

		local OldScopes = self:SaveScopes()
		self:InitScope() -- Create a new Scope Enviroment
		self:PushScope()

		Script[1](self, Script)

		self:PopScope()
		self:LoadScopes(OldScopes)
	end
end)
