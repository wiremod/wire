/******************************************************************************\
Angle support
\******************************************************************************/

// wow... this is basically just vector-support, but renamed angle-support :P
// pitch, yaw, roll
registerType("angle", "a", { 0, 0, 0 },
	function(self, input) return { input.p, input.y, input.r } end,
	function(self, output) return Angle(output[1], output[2], output[3]) end,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 3 then error("Return value does not have exactly 3 entries!",0) end
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("ang", "", "a", function(self, args)
	return { 0, 0, 0 }
end)

__e2setcost(3) -- temporary

registerFunction("ang", "nnn", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1, rv2, rv3 }
end)

// Convert Vector -> Angle
registerFunction("ang", "v", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[1],rv1[2],rv1[3]}
end)

/******************************************************************************/

registerOperator("ass", "a", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "a", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] != 0 || rv1[2] != 0 || rv1[3] != 0
	   then return 1 else return 0 end
end)

registerOperator("eq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("geq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] <= delta &&
	   rv2[2] - rv1[2] <= delta &&
	   rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("leq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta &&
	   rv1[2] - rv2[2] <= delta &&
	   rv1[3] - rv2[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("gth", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta &&
	   rv1[2] - rv2[2] > delta &&
	   rv1[3] - rv2[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("lth", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] > delta &&
	   rv2[2] - rv1[2] > delta &&
	   rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("neg", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end)

registerOperator("add", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end)

registerOperator("sub", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("mul", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] }
end)

registerOperator("mul", "na", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end)

registerOperator("mul", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end)

registerOperator("div", "na", "a", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end)

registerOperator("div", "an", "a", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end)

/******************************************************************************/

__e2setcost(5) -- temporary

registerFunction("angnorm", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {(rv1[1] + 180) % 360 - 180,(rv1[2] + 180) % 360 - 180,(rv1[3] + 180) % 360 - 180}
end)

registerFunction("angnorm", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1 + 180) % 360 - 180
end)

registerFunction("pitch", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("yaw", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("roll", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

// SET methods that returns angles
registerFunction("setPitch", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2, rv1[2], rv1[3] }
end)

registerFunction("setYaw", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2, rv1[3] }
end)

registerFunction("setRoll", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2 }
end)

/******************************************************************************/

registerFunction("round", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local p = rv1[1] - (rv1[1] + 0.5) % 1 + 0.5
	local y = rv1[2] - (rv1[2] + 0.5) % 1 + 0.5
	local r = rv1[3] - (rv1[3] + 0.5) % 1 + 0.5
	return {p, y, r}
end)

registerFunction("round", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local p = rv1[1] - ((rv1[1] * shf + 0.5) % 1 + 0.5) / shf
	local y = rv1[2] - ((rv1[2] * shf + 0.5) % 1 + 0.5) / shf
	local r = rv1[3] - ((rv1[3] * shf + 0.5) % 1 + 0.5) / shf
	return {p, y, r}
end)

// ceil/floor on p,y,r separately
registerFunction("ceil", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local p = rv1[1] - rv1[1] % -1
	local y = rv1[2] - rv1[2] % -1
	local r = rv1[3] - rv1[3] % -1
	return {p, y, r}
end)

registerFunction("ceil", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local p = rv1[1] - ((rv1[1] * shf) % -1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % -1) / shf
	local r = rv1[3] - ((rv1[3] * shf) % -1) / shf
	return {p, y, r}
end)

registerFunction("floor", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local p = rv1[1] - rv1[1] % 1
	local y = rv1[2] - rv1[2] % 1
	local r = rv1[3] - rv1[3] % 1
	return {p, y, r}
end)

registerFunction("floor", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local p = rv1[1] - ((rv1[1] * shf) % 1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % 1) / shf
	local r = rv1[3] - ((rv1[3] * shf) % 1) / shf
	return {p, y, r}
end)

// Performs modulo on p,y,r separately
registerFunction("mod", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local p,y,r
	if rv1[1] >= 0 then
		p = rv1[1] % rv2
	else p = rv1[1] % -rv2 end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	if rv1[3] >= 0 then
		r = rv1[3] % rv2
	else r = rv1[3] % -rv2 end
	return {p, y, r}
end)

// Modulo where divisors are defined as an angle
registerFunction("mod", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local p,y,r
	if rv1[1] >= 0 then
		p = rv1[1] % rv2[1]
	else p = rv1[1] % -rv2[1] end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	if rv1[3] >= 0 then
		y = rv1[3] % rv2[3]
	else y = rv1[3] % -rv2[3] end
	return {p, y, r}
end)

// Clamp each p,y,r separately
registerFunction("clamp", "ann", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local p,y,r

	if rv1[1] < rv2 then p = rv2
	elseif rv1[1] > rv3 then p = rv3
	else p = rv1[1] end

	if rv1[2] < rv2 then y = rv2
	elseif rv1[2] > rv3 then y = rv3
	else y = rv1[2] end

	if rv1[3] < rv2 then r = rv2
	elseif rv1[3] > rv3 then r = rv3
	else r = rv1[3] end

	return {p, y, r}
end)

// Clamp according to limits defined by two min/max angles
registerFunction("clamp", "aaa", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local p,y,r

	if rv1[1] < rv2[1] then p = rv2[1]
	elseif rv1[1] > rv3[1] then p = rv3[1]
	else p = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	if rv1[3] < rv2[3] then r = rv2[3]
	elseif rv1[3] > rv3[3] then r = rv3[3]
	else r = rv1[3] end

	return {p, y, r}
end)

// Mix two angles by a given proportion (between 0 and 1)
registerFunction("mix", "aan", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local n
	if rv3 < 0 then n = 0
	elseif rv3 > 1 then n = 1
	else n = rv3 end
	local p = rv1[1] * n + rv2[1] * (1-n)
	local y = rv1[2] * n + rv2[2] * (1-n)
	local r = rv1[3] * n + rv2[3] * (1-n)
	return {p, y, r}
end)

// Circular shift function: shiftr(  p,y,r ) = ( r,p,y )
registerFunction("shiftR", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[3], rv1[1], rv1[2]}
end)

registerFunction("shiftL", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[2], rv1[3], rv1[1]}
end)

/******************************************************************************/

e2function vector angle:forward()
	return Angle(this[1], this[2], this[3]):Forward()
end

e2function vector angle:right()
	return Angle(this[1], this[2], this[3]):Right()
end

e2function vector angle:up()
	return Angle(this[1], this[2], this[3]):Up()
end

e2function string toString(angle a)
	return "[" .. tostring(a[1]) .. "," .. tostring(a[2]) .. "," .. tostring(a[3]) .. "]"
end

e2function string angle:toString() = e2function string toString(angle a)

__e2setcost(nil)
