/******************************************************************************\
  Core language support
\******************************************************************************/

local delta = wire_expression2_delta

__e2setcost(1) -- approximation

registerOperator("dat", "", "", function(self, args)
	return args[2]
end)

__e2setcost(2) -- approximation

registerOperator("var", "", "", function(self, args)
	return self.vars[args[2]]
end)

/******************************************************************************/

__e2setcost(0)

registerOperator("seq", "", "", function(self, args)
	local n = #args
	if n == 2 then return end

	self.prf = self.prf + args[2]
	if self.prf > e2_tickquota then error("perf", 0) end

	for i=3,n-1 do
		local op = args[i]
		op[1](self, op)
	end

	local op = args[n]
	return op[1](self, op)
end)

/******************************************************************************/

__e2setcost(0) -- approximation

registerOperator("whl", "", "", function(self, args)
	local op1, op2 = args[2], args[3]

	self.prf = self.prf + args[4] + 3
	while op1[1](self, op1) != 0 do
		local ok, msg = pcall(op2[1], self, op2)
		if !ok then
			if msg == "break" then break
			elseif msg == "continue" then
			else error(msg, 0) end
		end

		self.prf = self.prf + args[4] + 3
	end
end)

registerOperator("for", "", "", function(self, args)
	local var, op1, op2, op3, op4 = args[2], args[3], args[4], args[5], args[6]

	local rstart, rend, rstep
	rstart = op1[1](self, op1)
	rend = op2[1](self, op2)
	local rdiff = rend - rstart
	local rdelta = delta

	self.vars[var] = rstart
	self.vclk[var] = true

	if op3 then
		rstep = op3[1](self, op3)

		if rdiff > -delta then
			if rstep < delta then return end
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
		self.vars[var] = I
		self.vclk[var] = true

		local ok, msg = pcall(op4[1], self, op4)
		if !ok then
			if msg == "break" then break
			elseif msg == "continue" then
			else error(msg, 0) end
		end

		self.prf = self.prf + 3
	end
end)

__e2setcost(2) -- approximation

registerOperator("brk", "", "", function(self, args)
	error("break", 0)
end)

registerOperator("cnt", "", "", function(self, args)
	error("continue", 0)
end)

/******************************************************************************/

__e2setcost(3) -- approximation

registerOperator("if", "n", "", function(self, args)
	local op1 = args[3]
	self.prf = self.prf + args[2]
	if op1[1](self, op1) != 0 then
		local op2 = args[4]
		op2[1](self, op2)
		return
	else
		local op3 = args[5]
		op3[1](self, op3)
		return
	end
end)

registerOperator("def", "n", "", function(self, args)
	local op1 = args[2]
	local op2 = args[3]
	local rv2 = op2[1](self, op2)

	-- sets the argument for the DAT-operator
	op1[2][2] = rv2
	local rv1 = op1[1](self, op1)

	if rv1 != 0 then
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
	if rv1 != 0 then
		self.prf = self.prf + args[5]
		local op2 = args[3]
		return op2[1](self, op2)
	else
		self.prf = self.prf + args[6]
		local op3 = args[4]
		return op3[1](self, op3)
	end
end)

/******************************************************************************/

__e2setcost(1) -- approximation

registerOperator("trg", "", "n", function(self, args)
	local op1 = args[2]
	return self.triggerinput == op1 and 1 or 0
end)


registerOperator("iwc", "", "n", function(self, args)
	local op1 = args[2]
	return validEntity(self.entity.Inputs[op1].Src) and 1 or 0
end)

/******************************************************************************/

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

/******************************************************************************/

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

--- Returns 1 if this is the last() execution and caused by the entity being removed.
e2function number removing()
	return self.entity.removing and 1 or 0
end

--- If <activate> != 0, the chip will run once when it is removed, setting the last() flag when it does.
e2function void runOnLast(activate)
	if self.data.last then return end
	self.data.runOnLast = activate ~= 0
end

/******************************************************************************/

__e2setcost(2) -- approximation

e2function void exit()
	error("exit", 0)
end

/******************************************************************************/

__e2setcost(100) -- approximation

e2function void reset()
	if self.data.last or self.entity.first then error("exit", 0) end

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

/******************************************************************************/

local floor  = math.floor
local ceil   = math.ceil
local round  = math.Round

__e2setcost(1) -- approximation

e2function number ops()
	return round(self.prfbench)
end

e2function number opcounter()
	return ceil(self.prf + self.prfcount)
end

--- If used as a while loop condition, stabilizes the expression around <maxexceed> hardquota used.
e2function number perf()
	if self.prf + self.prfcount >= e2_hardquota-e2_tickquota then return 0 end
	if self.prf >= e2_softquota*2 then return 0 end
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
