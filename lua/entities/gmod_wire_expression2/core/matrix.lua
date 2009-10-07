/******************************************************************************\
  Matrix support
\******************************************************************************/

local delta  = wire_expression2_delta

local function clone(a)
	local b = {}
	for k,v in ipairs(a) do
		b[k] = v
	end
	return b
end


/******************************************************************************\
  2x2 Matrices
\******************************************************************************/

registerType("matrix2", "xm2", { 0, 0,
								 0, 0 },
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	nil,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 4 then error("Return value does not have exactly 4 entries!",0) end
	end
)

/******************************************************************************/
// Common functions - explicit matrix solvers

local function det2(a)
	return ( a[1] * a[4] - a[3] * a[2] )
end

local function inverse2(a)
	local det = det2(a)
	if det == 0 then return { 0, 0,
							  0, 0 }
	end
	return { a[4]/det,	-a[2]/det,
			-a[3]/det,	 a[1]/det }
end

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("matrix2", "", "xm2", function(self, args)
	return { 0, 0,
			 0, 0 }
end)

__e2setcost(5) -- temporary

registerFunction("matrix2", "xv2xv2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2[1],
			 rv1[2], rv2[2] }
end)

registerFunction("matrix2", "nnnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1, rv2,
			 rv3, rv4 }
end)

registerFunction("matrix2", "m", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv2[2],
			 rv1[4], rv2[5] }
end)

registerFunction("identity2", "", "xm2", function(self, args)
	return { 1, 0,
			 0, 1 }
end)

/******************************************************************************/

registerOperator("ass", "xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/
// Comparison

registerOperator("is", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xm2xm2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xm2xm2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta && rv2[1] - rv1[1] > delta &&
	   rv1[2] - rv2[2] > delta && rv2[2] - rv1[2] > delta &&
	   rv1[3] - rv2[3] > delta && rv2[3] - rv1[3] > delta &&
	   rv1[4] - rv2[4] > delta && rv2[4] - rv1[4] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/
// Basic operations

registerOperator("dlt", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2],
			 rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("neg", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2],
			 -rv1[3], -rv1[4] }
end)

registerOperator("add", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2],
			 rv1[3] + rv2[3], rv1[4] + rv2[4] }
end)

registerOperator("sub", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2],
			 rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("mul", "nxm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2],
			 rv1 * rv2[3], rv1 * rv2[4] }
end)

registerOperator("mul", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2,
			 rv1[3] * rv2, rv1[4] * rv2 }
end)

registerOperator("mul", "xm2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2],
			 rv1[3] * rv2[1] + rv1[4] * rv2[2] }
end)

registerOperator("mul", "xm2xm2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[3],
			 rv1[1] * rv2[2] + rv1[2] * rv2[4],
			 rv1[3] * rv2[1] + rv1[4] * rv2[3],
			 rv1[3] * rv2[2] + rv1[4] * rv2[4] }
end)

registerOperator("div", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2,
			 rv1[3] / rv2, rv1[4] / rv2 }
end)

registerOperator("exp", "xm2n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	if rv2 == -1 then return ( inverse2(rv1) )

	elseif rv2 == 0 then return { 1, 0,
								  0, 1 }

	elseif rv2 == 1 then return rv1

	elseif rv2 == 2 then
		return { rv1[1] * rv1[1] + rv1[2] * rv1[3],
				 rv1[1] * rv1[2] + rv1[2] * rv1[4],
				 rv1[3] * rv1[1] + rv1[4] * rv1[3],
				 rv1[3] * rv1[2] + rv1[4] * rv1[4] }

	else return { 0, 0,
				  0, 0 }
	end
end)

/******************************************************************************/
// Row/column/element manipulation

registerFunction("row", "xm2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local x = rv1[k * 2 - 1]
	local y = rv1[k * 2]
	return { x, y }
end)

registerFunction("column", "xm2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local x = rv1[k]
	local y = rv1[k + 2]
	return { x, y }
end)

registerFunction("setRow", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k

	if rv2 < 1 then k = 2
	elseif rv2 > 2 then k = 4
	else k = (rv2 - rv2 % 1)*2 end

	local a = clone(rv1)
	a[k - 1] = rv3
	a[k] = rv4
	return a
end)

registerFunction("setRow", "xm2:nxv2", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k

	if rv2 < 1 then k = 2
	elseif rv2 > 2 then k = 4
	else k = (rv2 - rv2 % 1)*2 end

	local a = clone(rv1)
	a[k - 1] = rv3[1]
	a[k] = rv3[2]
	return a
end)


registerFunction("setColumn", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k] = rv3
	a[k + 2] = rv4
	return a
end)

registerFunction("setColumn", "xm2:nxv2", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k] = rv3[1]
	a[k + 2] = rv3[2]
	return a
end)

registerFunction("swapRows", "xm2:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)

	rv1 = { rv1[3], rv1[4],
			rv1[1], rv1[2] }
	return rv1
end)

registerFunction("swapColumns", "xm2:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)

	rv1 = { rv1[2], rv1[1],
			rv1[4], rv1[3] }
	return rv1
end)

registerFunction("element", "xm2:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 2
	return rv1[k]
end)

registerFunction("setElement", "xm2:nnn", "xm2", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end

	local a = clone(rv1)
	a[i + (j - 1) * 2] = rv4
	return a
end)

registerFunction("swapElements", "xm2:nnnn", "xm2", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local i1, j1, i2, j2

	if rv2 < 1 then i1 = 1
	elseif rv2 > 3 then i1 = 3
	else i1 = rv2 - rv2 % 1 end

	if rv3 < 1 then j1 = 1
	elseif rv3 > 3 then j1 = 3
	else j1 = rv3 - rv3 % 1 end

	if rv4 < 1 then i2 = 1
	elseif rv4 > 3 then i2 = 3
	else i2 = rv4 - rv4 % 1 end

	if rv5 < 1 then j2 = 1
	elseif rv5 > 3 then j2 = 3
	else j2 = rv5 - rv5 % 1 end

	local k1 = i1 + (j1 - 1) * 2
	local k2 = i2 + (j2 - 1) * 2
	local a = clone(rv1)
	a[k1], a[k2] = rv1[k2], rv1[k1]
	return a
end)

/******************************************************************************/
// Useful matrix maths functions

registerFunction("diagonal", "xm2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[4] }
end)

registerFunction("trace", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( rv1[1] + rv[4] )
end)

registerFunction("det", "xm2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( det2(rv1) )
end)

registerFunction("transpose", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[3],
			 rv1[2], rv1[4] }
end)

registerFunction("adj", "xm2", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {  rv1[4], -rv1[2],
			 -rv1[3],  rv1[1] }
end)


/******************************************************************************\
  3x3 Matrices
\******************************************************************************/

registerType("matrix", "m", { 0, 0, 0,
							  0, 0, 0,
							  0, 0, 0 },
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	nil,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 9 then error("Return value does not have exactly 9 entries!",0) end
	end
)

/******************************************************************************/
// Common functions - matrix solvers

/*
-- Useful functions - may be used in the future? These have been written explicitly in the relevant commands for now.

local function transpose3(a)
	return { a[1], a[4], a[7],
			 a[2], a[5], a[8],
			 a[3], a[6], a[9] }
end

local function adj3(a)
	return { a[5] * a[9] - a[8] * a[6],	a[8] * a[3] - a[2] * a[9],	a[2] * a[6] - a[5] * a[3],
			a[7] * a[6] - a[4] * a[9],	a[1] * a[9] - a[7] * a[3],	a[4] * a[3] - a[1] * a[6],
			a[4] * a[8] - a[7] * a[5],	a[7] * a[2] - a[1] * a[8],	a[1] * a[5] - a[4] * a[2] }
end
*/

local function det3(a)
	return ( a[1] * (a[5] * a[9] - a[8] * a[6]) -
			 a[2] * (a[4] * a[9] - a[7] * a[6]) +
			 a[3] * (a[4] * a[8] - a[7] * a[5]) )
end

local function inverse3(a)
	local det = det3(a)
	if det == 0 then return { 0, 0, 0,
							  0, 0, 0,
							  0, 0, 0 }
	end
	return { (a[5] * a[9] - a[8] * a[6])/det,	(a[8] * a[3] - a[2] * a[9])/det,	(a[2] * a[6] - a[5] * a[3])/det,
			 (a[7] * a[6] - a[4] * a[9])/det,	(a[1] * a[9] - a[7] * a[3])/det,	(a[4] * a[3] - a[1] * a[6])/det,
			 (a[4] * a[8] - a[7] * a[5])/det,	(a[7] * a[2] - a[1] * a[8])/det,	(a[1] * a[5] - a[4] * a[2])/det }
end


/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("matrix", "", "m", function(self, args)
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

__e2setcost(5) -- temporary

registerFunction("matrix", "vvv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1[1], rv2[1], rv3[1],
			 rv1[2], rv2[2], rv3[2],
			 rv1[3], rv2[3], rv3[3] }
end)

registerFunction("matrix", "nnnnnnnnn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local op4, op5, op6 = args[5], args[6], args[7]
	local op7, op8, op9 = args[8], args[9], args[10]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local rv4, rv5, rv6 = op4[1](self, op4), op5[1](self, op5), op6[1](self, op6)
	local rv7, rv8, rv9 = op7[1](self, op7), op8[1](self, op8), op9[1](self, op9)
	return { rv1, rv2, rv3,
			 rv4, rv5, rv6,
			 rv7, rv8, rv9 }
end)

registerFunction("matrix", "xm2", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0,
			 rv1[3], rv1[4], 0,
			 0,		 0,		 0 }
end)

registerFunction("identity", "", "m", function(self, args)
	return { 1, 0, 0,
			 0, 1, 0,
			 0, 0, 1 }
end)

/******************************************************************************/

registerOperator("ass", "m", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/
// Comparison

registerOperator("is", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta ||
	   rv1[5] > delta || -rv1[5] > delta ||
	   rv1[6] > delta || -rv1[6] > delta ||
	   rv1[7] > delta || -rv1[7] > delta ||
	   rv1[8] > delta || -rv1[8] > delta ||
	   rv1[9] > delta || -rv1[9] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "mm", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta &&
	   rv1[5] - rv2[5] <= delta && rv2[5] - rv1[5] <= delta &&
	   rv1[6] - rv2[6] <= delta && rv2[6] - rv1[6] <= delta &&
	   rv1[7] - rv2[7] <= delta && rv2[7] - rv1[7] <= delta &&
	   rv1[8] - rv2[8] <= delta && rv2[8] - rv1[8] <= delta &&
	   rv1[9] - rv2[9] <= delta && rv2[9] - rv1[9] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "mm", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta && rv2[1] - rv1[1] > delta &&
	   rv1[2] - rv2[2] > delta && rv2[2] - rv1[2] > delta &&
	   rv1[3] - rv2[3] > delta && rv2[3] - rv1[3] > delta &&
	   rv1[4] - rv2[4] > delta && rv2[4] - rv1[4] > delta &&
	   rv1[5] - rv2[5] > delta && rv2[5] - rv1[5] > delta &&
	   rv1[6] - rv2[6] > delta && rv2[6] - rv1[6] > delta &&
	   rv1[7] - rv2[7] > delta && rv2[7] - rv1[7] > delta &&
	   rv1[8] - rv2[8] > delta && rv2[8] - rv1[8] > delta &&
	   rv1[9] - rv2[9] > delta && rv2[9] - rv1[9] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/
// Basic operations

registerOperator("dlt", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3],
			 rv1[4] - rv2[4], rv1[5] - rv2[5], rv1[6] - rv2[6],
			 rv1[7] - rv2[7], rv1[8] - rv2[8], rv1[9] - rv2[9]	}
end)

registerOperator("neg", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3],
			 -rv1[4], -rv1[5], -rv1[6],
			 -rv1[7], -rv1[8], -rv1[9] }
end)

registerOperator("add", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3],
			 rv1[4] + rv2[4], rv1[5] + rv2[5], rv1[6] + rv2[6],
			 rv1[7] + rv2[7], rv1[8] + rv2[8], rv1[9] + rv2[9] }
end)

registerOperator("sub", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3],
			 rv1[4] - rv2[4], rv1[5] - rv2[5], rv1[6] - rv2[6],
			 rv1[7] - rv2[7], rv1[8] - rv2[8], rv1[9] - rv2[9] }
end)

registerOperator("mul", "nm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3],
			 rv1 * rv2[4], rv1 * rv2[5], rv1 * rv2[6],
			 rv1 * rv2[7], rv1 * rv2[8], rv1 * rv2[9] }
end)

registerOperator("mul", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2,
			 rv1[4] * rv2, rv1[5] * rv2, rv1[6] * rv2,
			 rv1[7] * rv2, rv1[8] * rv2, rv1[9] * rv2 }
end)

registerOperator("mul", "mv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3],
			 rv1[4] * rv2[1] + rv1[5] * rv2[2] + rv1[6] * rv2[3],
			 rv1[7] * rv2[1] + rv1[8] * rv2[2] + rv1[9] * rv2[3] }
end)

registerOperator("mul", "mm", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[4] + rv1[3] * rv2[7],
			 rv1[1] * rv2[2] + rv1[2] * rv2[5] + rv1[3] * rv2[8],
			 rv1[1] * rv2[3] + rv1[2] * rv2[6] + rv1[3] * rv2[9],
			 rv1[4] * rv2[1] + rv1[5] * rv2[4] + rv1[6] * rv2[7],
			 rv1[4] * rv2[2] + rv1[5] * rv2[5] + rv1[6] * rv2[8],
			 rv1[4] * rv2[3] + rv1[5] * rv2[6] + rv1[6] * rv2[9],
			 rv1[7] * rv2[1] + rv1[8] * rv2[4] + rv1[9] * rv2[7],
			 rv1[7] * rv2[2] + rv1[8] * rv2[5] + rv1[9] * rv2[8],
			 rv1[7] * rv2[3] + rv1[8] * rv2[6] + rv1[9] * rv2[9] }
end)

registerOperator("div", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2,
			 rv1[4] / rv2, rv1[5] / rv2, rv1[6] / rv2,
			 rv1[7] / rv2, rv1[8] / rv2, rv1[9] / rv2 }
end)

registerOperator("exp", "mn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	if rv2 == -1 then return ( inverse3(rv1) )

	elseif rv2 == 0 then return { 1, 0, 0,
								  0, 1, 0,
								  0, 0, 1 }

	elseif rv2 == 1 then return rv1

	elseif rv2 == 2 then
		return { rv1[1] * rv1[1] + rv1[2] * rv1[4] + rv1[3] * rv1[7],
				 rv1[1] * rv1[2] + rv1[2] * rv1[5] + rv1[3] * rv1[8],
				 rv1[1] * rv1[3] + rv1[2] * rv1[6] + rv1[3] * rv1[9],
				 rv1[4] * rv1[1] + rv1[5] * rv1[4] + rv1[6] * rv1[7],
				 rv1[4] * rv1[2] + rv1[5] * rv1[5] + rv1[6] * rv1[8],
				 rv1[4] * rv1[3] + rv1[5] * rv1[6] + rv1[6] * rv1[9],
				 rv1[7] * rv1[1] + rv1[8] * rv1[4] + rv1[9] * rv1[7],
				 rv1[7] * rv1[2] + rv1[8] * rv1[5] + rv1[9] * rv1[8],
				 rv1[7] * rv1[3] + rv1[8] * rv1[6] + rv1[9] * rv1[9] }

	else return { 0, 0, 0,
				  0, 0, 0,
				  0, 0, 0 }
	end
end)

/******************************************************************************/
// Row/column/element manipulation

registerFunction("row", "m:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 3
	elseif rv2 > 3 then k = 9
	else k = (rv2 - rv2 % 1)*3 end

	local x = rv1[k - 2]
	local y = rv1[k - 1]
	local z = rv1[k]
	return { x, y, z }
end)

registerFunction("column", "m:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local x = rv1[k]
	local y = rv1[k + 3]
	local z = rv1[k + 6]
	return { x, y, z }
end)

registerFunction("setRow", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k * 3 - 2] = rv3
	a[k * 3 - 1] = rv4
	a[k * 3] = rv5
	return a
end)

registerFunction("setRow", "m:nv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k * 3 - 2] = rv3[1]
	a[k * 3 - 1] = rv3[2]
	a[k * 3] = rv3[3]
	return a
end)

registerFunction("setColumn", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k] = rv3
	a[k + 3] = rv4
	a[k + 6] = rv5
	return a
end)

registerFunction("setColumn", "m:nv", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k] = rv3[1]
	a[k + 3] = rv3[2]
	a[k + 6] = rv3[3]
	return a
end)

registerFunction("swapRows", "m:nn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[4], rv1[5], rv1[6],
				rv1[1], rv1[2], rv1[3],
				rv1[7], rv1[8], rv1[9] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[2], rv1[3],
				rv1[7], rv1[8], rv1[9],
				rv1[4], rv1[5], rv1[6] }
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[7], rv1[8], rv1[9],
				rv1[4], rv1[5], rv1[6],
				rv1[1], rv1[2], rv1[3] }
	end
	return rv1
end)

registerFunction("swapColumns", "m:nn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[2], rv1[1], rv1[3],
				rv1[5], rv1[4], rv1[6],
				rv1[8], rv1[7], rv1[9] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[3], rv1[2],
				rv1[4], rv1[6], rv1[5],
				rv1[7], rv1[9], rv1[8] }
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[3], rv1[2], rv1[1],
				rv1[6], rv1[5], rv1[4],
				rv1[9], rv1[8], rv1[7] }
	end
	return rv1
end)

registerFunction("element", "m:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 3
	return rv1[k]
end)

registerFunction("setElement", "m:nnn", "m", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end

	local a = clone(rv1)
	a[i + (j - 1) * 3] = rv4
	return a
end)

registerFunction("swapElements", "m:nnnn", "m", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local i1, j1, i2, j2

	if rv2 < 1 then i1 = 1
	elseif rv2 > 3 then i1 = 3
	else i1 = rv2 - rv2 % 1 end

	if rv3 < 1 then j1 = 1
	elseif rv3 > 3 then j1 = 3
	else j1 = rv3 - rv3 % 1 end

	if rv4 < 1 then i2 = 1
	elseif rv4 > 3 then i2 = 3
	else i2 = rv4 - rv4 % 1 end

	if rv5 < 1 then j2 = 1
	elseif rv5 > 3 then j2 = 3
	else j2 = rv5 - rv5 % 1 end

	local k1 = i1 + (j1 - 1) * 3
	local k2 = i2 + (j2 - 1) * 3
	local a = clone(rv1)
	a[k1], a[k2] = rv1[k2], rv1[k1]
	return a
end)

registerFunction("setDiagonal", "m:v", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2[1], rv1[4], rv1[7],
			 rv1[2], rv2[2], rv1[8],
			 rv1[3], rv1[6], rv2[3] }
end)

registerFunction("setDiagonal", "m:nnn", "m", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv2, rv1[4], rv1[7],
			 rv1[2], rv3, rv1[8],
			 rv1[3], rv1[6], rv4 }
end)

/******************************************************************************/
// Useful matrix maths functions

registerFunction("diagonal", "m", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[5], rv1[9] }
end)

registerFunction("trace", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( rv1[1] + rv1[5] + rv1[9] )
end)

registerFunction("det", "m", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( det3(rv1) )
end)

registerFunction("transpose", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[4], rv1[7],
			 rv1[2], rv1[5], rv1[8],
			 rv1[3], rv1[6], rv1[9] }
end)

registerFunction("adj", "m", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[5] * rv1[9] - rv1[8] * rv1[6],	rv1[8] * rv1[3] - rv1[2] * rv1[9],	rv1[2] * rv1[6] - rv1[5] * rv1[3],
			 rv1[7] * rv1[6] - rv1[4] * rv1[9],	rv1[1] * rv1[9] - rv1[7] * rv1[3],	rv1[4] * rv1[3] - rv1[1] * rv1[6],
			 rv1[4] * rv1[8] - rv1[7] * rv1[5],	rv1[7] * rv1[2] - rv1[1] * rv1[8],	rv1[1] * rv1[5] - rv1[4] * rv1[2] }
end)

/******************************************************************************/
// Extra functions

registerFunction("matrix", "e", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then
		return { 0, 0, 0,
				 0, 0, 0,
				 0, 0, 0 }
	end
	local factor = 10000
	local pos = rv1:GetPos()
	local x = rv1:LocalToWorld(Vector(factor,0,0)) - pos
	local y = rv1:LocalToWorld(Vector(0,factor,0)) - pos
	local z = rv1:LocalToWorld(Vector(0,0,factor)) - pos
	return { x.x/factor, y.x/factor, z.x/factor,
			 x.y/factor, y.y/factor, z.y/factor,
			 x.z/factor, y.z/factor, z.z/factor }
end)

registerFunction("x", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[4], rv1[7] }
end)

registerFunction("y", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[2], rv1[5], rv1[8] }
end)

registerFunction("z", "m:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[3], rv1[6], rv1[9] }
end)

// Create a rotation matrix in the format (v,n) where v is the axis direction vector and n is degrees (right-handed rotation)
registerFunction("mRotation", "vn", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	local vec
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
	if len == 1 then vec = rv1
	elseif len > delta then vec = { rv1[1] / len, rv1[2] / len, rv1[3] / len }
	else return { 0, 0, 0,
				  0, 0, 0,
				  0, 0, 0 }
	end

	local vec2 = { vec[1] * vec[1], vec[2] * vec[2], vec[3] * vec[3] }
	local a = rv2 * 3.14159265 / 180
	local cos = math.cos(a)
	local sin = math.sin(a)
	local cosmin = 1 - cos
	return { vec2[1] + (1 - vec2[1]) * cos,
			 vec[1] * vec[2] * cosmin - vec[3] * sin,
			 vec[1] * vec[3] * cosmin + vec[2] * sin,
			 vec[1] * vec[2] * cosmin + vec[3] * sin,
			 vec2[2] + (1 - vec2[2]) * cos,
			 vec[2] * vec[3] * cosmin - vec[1] * sin,
			 vec[1] * vec[3] * cosmin - vec[2] * sin,
			 vec[2] * vec[3] * cosmin + vec[1] * sin,
			 vec2[3] + (1 - vec2[3]) * cos }
end)

/******************************************************************************\
  4x4 Matrices
\******************************************************************************/

registerType("matrix4", "xm4", { 0, 0, 0, 0,
								 0, 0, 0, 0,
								 0, 0, 0, 0,
								 0, 0, 0, 0 },
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	nil,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 16 then error("Return value does not have exactly 16 entries!",0) end
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("matrix4", "", "xm4", function(self, args)
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end)

__e2setcost(5) -- temporary

registerFunction("matrix4", "xv4xv4xv4xv4", "xm4", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1[1], rv2[1], rv3[1], rv4[1],
			 rv1[2], rv2[2], rv3[2], rv4[2],
			 rv1[3], rv2[3], rv3[3], rv4[3],
			 rv1[4], rv2[4], rv3[4], rv4[4] }
end)

registerFunction("matrix4", "nnnnnnnnnnnnnnnn", "xm4", function(self, args)
	local op1, op2, op3, op4		= args[2], args[3], args[4], args[5]
	local op5, op6, op7, op8		= args[6], args[7], args[8], args[9]
	local op9, op10, op11, op12		= args[10], args[11], args[12], args[13]
	local op13, op14, op15, op16	= args[14], args[15], args[16], args[17]
	local rv1, rv2, rv3, rv4		= op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local rv5, rv6, rv7, rv8		= op5[1](self, op5), op6[1](self, op6), op7[1](self, op7), op8[1](self, op8)
	local rv9, rv10, rv11, rv12		= op9[1](self, op9), op10[1](self, op10), op11[1](self, op11), op12[1](self, op12)
	local rv13, rv14, rv15, rv16	= op13[1](self, op13), op14[1](self, op14), op15[1](self, op15), op16[1](self, op16)
	return { rv1, rv2, rv3, rv4,
			 rv5, rv6, rv7, rv8,
			 rv9, rv10, rv11, rv12,
			 rv13, rv14, rv15, rv16 }
end)

registerFunction("matrix4", "xm2", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0, 0,
			 rv1[3], rv1[4], 0, 0,
			 0,		 0,		 0, 0,
			 0,		 0,		 0, 0 }
end)

registerFunction("matrix4", "xm2xm2xm2xm2", "xm4", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1[1], rv1[2], rv2[1], rv2[2],
			 rv1[3], rv1[4], rv2[3], rv2[4],
			 rv3[1], rv3[2], rv4[1], rv4[2],
			 rv3[3], rv3[4], rv4[3], rv4[4] }
end)

registerFunction("matrix4", "m", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3], 0,
			 rv1[4], rv1[5], rv1[6], 0,
			 rv1[7], rv1[8], rv1[9], 0,
			 0,		 0,		 0,		 0 }
end)

registerFunction("identity4", "", "xm4", function(self, args)
	return { 1, 0, 0, 0,
			 0, 1, 0, 0,
			 0, 0, 1, 0,
			 0, 0, 0, 1 }
end)

/******************************************************************************/

registerOperator("ass", "xm4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/
// Comparison

registerOperator("is", "xm4", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta ||
	   rv1[5] > delta || -rv1[5] > delta ||
	   rv1[6] > delta || -rv1[6] > delta ||
	   rv1[7] > delta || -rv1[7] > delta ||
	   rv1[8] > delta || -rv1[8] > delta ||
	   rv1[9] > delta || -rv1[9] > delta ||
	   rv1[10] > delta || -rv1[10] > delta ||
	   rv1[11] > delta || -rv1[11] > delta ||
	   rv1[12] > delta || -rv1[12] > delta ||
	   rv1[13] > delta || -rv1[13] > delta ||
	   rv1[14] > delta || -rv1[14] > delta ||
	   rv1[15] > delta || -rv1[15] > delta ||
	   rv1[16] > delta || -rv1[16] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xm4xm4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta &&
	   rv1[5] - rv2[5] <= delta && rv2[5] - rv1[5] <= delta &&
	   rv1[6] - rv2[6] <= delta && rv2[6] - rv1[6] <= delta &&
	   rv1[7] - rv2[7] <= delta && rv2[7] - rv1[7] <= delta &&
	   rv1[8] - rv2[8] <= delta && rv2[8] - rv1[8] <= delta &&
	   rv1[9] - rv2[9] <= delta && rv2[9] - rv1[9] <= delta &&
	   rv1[10] - rv2[10] <= delta && rv2[10] - rv1[10] <= delta &&
	   rv1[11] - rv2[11] <= delta && rv2[11] - rv1[11] <= delta &&
	   rv1[12] - rv2[12] <= delta && rv2[12] - rv1[12] <= delta &&
	   rv1[13] - rv2[13] <= delta && rv2[13] - rv1[13] <= delta &&
	   rv1[14] - rv2[14] <= delta && rv2[14] - rv1[14] <= delta &&
	   rv1[15] - rv2[15] <= delta && rv2[15] - rv1[15] <= delta &&
	   rv1[16] - rv2[16] <= delta && rv2[16] - rv1[16] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xm4xm4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta && rv2[1] - rv1[1] > delta &&
	   rv1[2] - rv2[2] > delta && rv2[2] - rv1[2] > delta &&
	   rv1[3] - rv2[3] > delta && rv2[3] - rv1[3] > delta &&
	   rv1[4] - rv2[4] > delta && rv2[4] - rv1[4] > delta &&
	   rv1[5] - rv2[5] > delta && rv2[5] - rv1[5] > delta &&
	   rv1[6] - rv2[6] > delta && rv2[6] - rv1[6] > delta &&
	   rv1[7] - rv2[7] > delta && rv2[7] - rv1[7] > delta &&
	   rv1[8] - rv2[8] > delta && rv2[8] - rv1[8] > delta &&
	   rv1[9] - rv2[9] > delta && rv2[9] - rv1[9] > delta &&
	   rv1[10] - rv2[10] > delta && rv2[10] - rv1[10] > delta &&
	   rv1[11] - rv2[11] > delta && rv2[11] - rv1[11] > delta &&
	   rv1[12] - rv2[12] > delta && rv2[12] - rv1[12] > delta &&
	   rv1[13] - rv2[13] > delta && rv2[13] - rv1[13] > delta &&
	   rv1[14] - rv2[14] > delta && rv2[14] - rv1[14] > delta &&
	   rv1[15] - rv2[15] > delta && rv2[15] - rv1[15] > delta &&
	   rv1[16] - rv2[16] > delta && rv2[16] - rv1[16] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/
// Basic operations

registerOperator("dlt", "xm4", "xm4", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1],	rv1[2] - rv2[2],	rv1[3] - rv2[3],	rv1[4] - rv2[4],
			 rv1[5] - rv2[5],	rv1[6] - rv2[6],	rv1[7] - rv2[7],	rv1[8] - rv2[8],
			 rv1[9] - rv2[9],	rv1[10] - rv2[10],	rv1[11] - rv2[11],	rv1[12] - rv2[12],
			 rv1[13] - rv2[13],	rv1[14] - rv2[14],	rv1[15] - rv2[15],	rv1[16] - rv2[16] }
end)

registerOperator("neg", "xm4", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1],	-rv1[2],	-rv1[3],	-rv1[4],
			 -rv1[5],	-rv1[6],	-rv1[7],	-rv1[8],
			 -rv1[9],	-rv1[10],	-rv1[11],	-rv1[12],
			 -rv1[13],	-rv1[14],	-rv1[15],	-rv1[16] }
end)

registerOperator("add", "xm4xm4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1],	rv1[2] + rv2[2],	rv1[3] + rv2[3],	rv1[4] + rv2[4],
			 rv1[5] + rv2[5],	rv1[6] + rv2[6],	rv1[7] + rv2[7],	rv1[8] + rv2[8],
			 rv1[9] + rv2[9],	rv1[10] + rv2[10],	rv1[11] + rv2[11],	rv1[12] + rv2[12],
			 rv1[13] + rv2[13],	rv1[14] + rv2[14],	rv1[15] + rv2[15],	rv1[16] + rv2[16] }
end)

registerOperator("sub", "xm4xm4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1],	rv1[2] - rv2[2],	rv1[3] - rv2[3],	rv1[4] - rv2[4],
			 rv1[5] - rv2[5],	rv1[6] - rv2[6],	rv1[7] - rv2[7],	rv1[8] - rv2[8],
			 rv1[9] - rv2[9],	rv1[10] - rv2[10],	rv1[11] - rv2[11],	rv1[12] - rv2[12],
			 rv1[13] - rv2[13],	rv1[14] - rv2[14],	rv1[15] - rv2[15],	rv1[16] - rv2[16] }
end)

registerOperator("mul", "nxm4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1],	rv1 * rv2[2],	rv1 * rv2[3],	rv1 * rv2[4],
			 rv1 * rv2[5],	rv1 * rv2[6],	rv1 * rv2[7],	rv1 * rv2[8],
			 rv1 * rv2[9],	rv1 * rv2[10],	rv1 * rv2[11],	rv1 * rv2[12],
			 rv1 * rv2[13],	rv1 * rv2[14],	rv1 * rv2[15],	rv1 * rv2[16] }
end)

registerOperator("mul", "xm4n", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2,	rv1[2] * rv2,	rv1[3] * rv2,	rv1[4] * rv2,
			 rv1[5] * rv2,	rv1[6] * rv2,	rv1[7] * rv2,	rv1[8] * rv2,
			 rv1[9] * rv2,	rv1[10] * rv2,	rv1[11] * rv2,	rv1[12] * rv2,
			 rv1[13] * rv2,	rv1[14] * rv2,	rv1[15] * rv2,	rv1[16] * rv2 }
end)

registerOperator("mul", "xm4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3] + rv1[4] * rv2[4],
			 rv1[5] * rv2[1] + rv1[6] * rv2[2] + rv1[7] * rv2[3] + rv1[8] * rv2[4],
			 rv1[9] * rv2[1] + rv1[10] * rv2[2] + rv1[11] * rv2[3] + rv1[12] * rv2[4],
			 rv1[13] * rv2[1] + rv1[14] * rv2[2] + rv1[15] * rv2[3] + rv1[16] * rv2[4] }
end)

registerOperator("mul", "xm4xm4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local lhs, rhs = op1[1](self, op1), op2[1](self, op2)
	return {
		lhs[ 1] * rhs[ 1] + lhs[ 2] * rhs[ 5] + lhs[ 3] * rhs[ 9] + lhs[ 4] * rhs[13],
		lhs[ 1] * rhs[ 2] + lhs[ 2] * rhs[ 6] + lhs[ 3] * rhs[10] + lhs[ 4] * rhs[14],
		lhs[ 1] * rhs[ 3] + lhs[ 2] * rhs[ 7] + lhs[ 3] * rhs[11] + lhs[ 4] * rhs[15],
		lhs[ 1] * rhs[ 4] + lhs[ 2] * rhs[ 8] + lhs[ 3] * rhs[12] + lhs[ 4] * rhs[16],
		lhs[ 5] * rhs[ 1] + lhs[ 6] * rhs[ 5] + lhs[ 7] * rhs[ 9] + lhs[ 8] * rhs[13],
		lhs[ 5] * rhs[ 2] + lhs[ 6] * rhs[ 6] + lhs[ 7] * rhs[10] + lhs[ 8] * rhs[14],
		lhs[ 5] * rhs[ 3] + lhs[ 6] * rhs[ 7] + lhs[ 7] * rhs[11] + lhs[ 8] * rhs[15],
		lhs[ 5] * rhs[ 4] + lhs[ 6] * rhs[ 8] + lhs[ 7] * rhs[12] + lhs[ 8] * rhs[16],
		lhs[ 9] * rhs[ 1] + lhs[10] * rhs[ 5] + lhs[11] * rhs[ 9] + lhs[12] * rhs[13],
		lhs[ 9] * rhs[ 2] + lhs[10] * rhs[ 6] + lhs[11] * rhs[10] + lhs[12] * rhs[14],
		lhs[ 9] * rhs[ 3] + lhs[10] * rhs[ 7] + lhs[11] * rhs[11] + lhs[12] * rhs[15],
		lhs[ 9] * rhs[ 4] + lhs[10] * rhs[ 8] + lhs[11] * rhs[12] + lhs[12] * rhs[16],
		lhs[13] * rhs[ 1] + lhs[14] * rhs[ 5] + lhs[15] * rhs[ 9] + lhs[16] * rhs[13],
		lhs[13] * rhs[ 2] + lhs[14] * rhs[ 6] + lhs[15] * rhs[10] + lhs[16] * rhs[14],
		lhs[13] * rhs[ 3] + lhs[14] * rhs[ 7] + lhs[15] * rhs[11] + lhs[16] * rhs[15],
		lhs[13] * rhs[ 4] + lhs[14] * rhs[ 8] + lhs[15] * rhs[12] + lhs[16] * rhs[16]
	}
end)

registerOperator("div", "xm4n", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2,	rv1[2] / rv2,	rv1[3] / rv2,	rv1[4] / rv2,
			 rv1[5] / rv2,	rv1[6] / rv2,	rv1[7] / rv2,	rv1[8] / rv2,
			 rv1[9] / rv2,	rv1[10] / rv2,	rv1[11] / rv2,	rv1[12] / rv2,
			 rv1[13] / rv2,	rv1[14] / rv2,	rv1[15] / rv2,	rv1[16] / rv2 }
end)

registerOperator("exp", "xm4n", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local lhs, rhs = op1[1](self, op1), op2[1](self, op2)

	//if rhs == -1 then return ( inverse4(lhs) )

	if rhs == 0 then 	return { 1, 0, 0, 0,
								 0, 1, 0, 0,
								 0, 0, 1, 0,
								 0, 0, 0, 1 }

	elseif rhs == 1 then return lhs

	elseif rhs == 2 then
		return {
			lhs[ 1] * lhs[ 1] + lhs[ 2] * lhs[ 5] + lhs[ 3] * lhs[ 9] + lhs[ 4] * lhs[13],
			lhs[ 1] * lhs[ 2] + lhs[ 2] * lhs[ 6] + lhs[ 3] * lhs[10] + lhs[ 4] * lhs[14],
			lhs[ 1] * lhs[ 3] + lhs[ 2] * lhs[ 7] + lhs[ 3] * lhs[11] + lhs[ 4] * lhs[15],
			lhs[ 1] * lhs[ 4] + lhs[ 2] * lhs[ 8] + lhs[ 3] * lhs[12] + lhs[ 4] * lhs[16],
			lhs[ 5] * lhs[ 1] + lhs[ 6] * lhs[ 5] + lhs[ 7] * lhs[ 9] + lhs[ 8] * lhs[13],
			lhs[ 5] * lhs[ 2] + lhs[ 6] * lhs[ 6] + lhs[ 7] * lhs[10] + lhs[ 8] * lhs[14],
			lhs[ 5] * lhs[ 3] + lhs[ 6] * lhs[ 7] + lhs[ 7] * lhs[11] + lhs[ 8] * lhs[15],
			lhs[ 5] * lhs[ 4] + lhs[ 6] * lhs[ 8] + lhs[ 7] * lhs[12] + lhs[ 8] * lhs[16],
			lhs[ 9] * lhs[ 1] + lhs[10] * lhs[ 5] + lhs[11] * lhs[ 9] + lhs[12] * lhs[13],
			lhs[ 9] * lhs[ 2] + lhs[10] * lhs[ 6] + lhs[11] * lhs[10] + lhs[12] * lhs[14],
			lhs[ 9] * lhs[ 3] + lhs[10] * lhs[ 7] + lhs[11] * lhs[11] + lhs[12] * lhs[15],
			lhs[ 9] * lhs[ 4] + lhs[10] * lhs[ 8] + lhs[11] * lhs[12] + lhs[12] * lhs[16],
			lhs[13] * lhs[ 1] + lhs[14] * lhs[ 5] + lhs[15] * lhs[ 9] + lhs[16] * lhs[13],
			lhs[13] * lhs[ 2] + lhs[14] * lhs[ 6] + lhs[15] * lhs[10] + lhs[16] * lhs[14],
			lhs[13] * lhs[ 3] + lhs[14] * lhs[ 7] + lhs[15] * lhs[11] + lhs[16] * lhs[15],
			lhs[13] * lhs[ 4] + lhs[14] * lhs[ 8] + lhs[15] * lhs[12] + lhs[16] * lhs[16]
		}

	else return { 0, 0, 0, 0,
				  0, 0, 0, 0,
				  0, 0, 0, 0,
				  0, 0, 0, 0 }
	end
end)

/******************************************************************************/
// Row/column/element manipulation

registerFunction("row", "xm4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 4
	elseif rv2 > 4 then k = 16
	else k = (rv2 - rv2 % 1)*4 end

	local x = rv1[k - 3]
	local y = rv1[k - 2]
	local z = rv1[k - 1]
	local w = rv1[k]
	return { x, y, z, w }
end)

registerFunction("column", "xm4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local x = rv1[k]
	local y = rv1[k + 4]
	local z = rv1[k + 8]
	local w = rv1[k + 12]
	return { x, y, z, w }
end)

registerFunction("setRow", "xm4:nnnnn", "xm4", function(self, args)
	local op1, op2, op3, op4, op5, op6 = args[2], args[3], args[4], args[5], args[6], args[7]
	local rv1, rv2, rv3, rv4, rv5, rv6 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5), op6[1](self, op6)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k * 4 - 3] = rv3
	a[k * 4 - 2] = rv4
	a[k * 4 - 1] = rv5
	a[k * 4]	 = rv6
	return a
end)

registerFunction("setRow", "xm4:nxv4", "xm4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k * 4 - 3] = rv3[1]
	a[k * 4 - 2] = rv3[2]
	a[k * 4 - 1] = rv3[3]
	a[k * 4]	 = rv3[4]
	return a
end)

registerFunction("setColumn", "xm4:nnnnn", "xm4", function(self, args)
	local op1, op2, op3, op4, op5, op6 = args[2], args[3], args[4], args[5], args[6], args[7]
	local rv1, rv2, rv3, rv4, rv5, rv6 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5), op6[1](self, op6)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k]		= rv3
	a[k + 4]	= rv4
	a[k + 8]	= rv5
	a[k + 12]	= rv6
	return a
end)

registerFunction("setColumn", "xm4:nxv4", "xm4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(rv1)
	a[k]		= rv3[1]
	a[k + 4]	= rv3[2]
	a[k + 8]	= rv3[3]
	a[k + 12]	= rv3[4]
	return a
end)

registerFunction("swapRows", "m:nn", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 4 then r1 = 4
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 4 then r2 = 4
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[5], rv1[6], rv1[7], rv1[8],
				rv1[1], rv1[2], rv1[3], rv1[4],
				rv1[9], rv1[10], rv1[11], rv1[12],
				rv1[13], rv1[14], rv1[15], rv1[16] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[2], rv1[3], rv1[4],
				rv1[9], rv1[10], rv1[11], rv1[12],
				rv1[5], rv1[6], rv1[7], rv1[8],
				rv1[13], rv1[14], rv1[15], rv1[16] }
	elseif (r1 == 3 && r2 == 4) || (r1 == 4 && r2 == 3) then
		rv1 = { rv1[1], rv1[2], rv1[3], rv1[4],
				rv1[5], rv1[6], rv1[7], rv1[8],
				rv1[13], rv1[14], rv1[15], rv1[16],
				rv1[9], rv1[10], rv1[11], rv1[12] }
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[9], rv1[10], rv1[11], rv1[12],
				rv1[5], rv1[6], rv1[7], rv1[8],
				rv1[1], rv1[2], rv1[3], rv1[4],
				rv1[13], rv1[14], rv1[15], rv1[16] }
	elseif (r1 == 2 && r2 == 4) || (r1 == 4 && r2 == 2) then
		rv1 = { rv1[1], rv1[2], rv1[3], rv1[4],
				rv1[13], rv1[14], rv1[15], rv1[16],
				rv1[9], rv1[10], rv1[11], rv1[12],
				rv1[5], rv1[6], rv1[7], rv1[8] }
	elseif (r1 == 1 && r2 == 4) || (r1 == 4 && r2 == 1) then
		rv1 = { rv1[13], rv1[14], rv1[15], rv1[16],
				rv1[5], rv1[6], rv1[7], rv1[8],
				rv1[9], rv1[10], rv1[11], rv1[12],
				rv1[1], rv1[2], rv1[3], rv1[4] }
	end
	return rv1
end)

registerFunction("swapColumns", "xm4:nn", "xm4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 4 then r1 = 4
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 4 then r2 = 4
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return rv1
	elseif (r1 == 1 && r2 == 2) || (r1 == 2 && r2 == 1) then
		rv1 = { rv1[2], rv1[1], rv1[3], rv1[4],
				rv1[6], rv1[5], rv1[7], rv1[8],
				rv1[10], rv1[9], rv1[11], rv1[12],
				rv1[14], rv1[13], rv1[15], rv1[16] }
	elseif (r1 == 2 && r2 == 3) || (r1 == 3 && r2 == 2) then
		rv1 = { rv1[1], rv1[3], rv1[2], rv1[4],
				rv1[5], rv1[7], rv1[6], rv1[8],
				rv1[9], rv1[11], rv1[10], rv1[12],
				rv1[13], rv1[15], rv1[14], rv1[16] }
	elseif (r1 == 3 && r2 == 4) || (r1 == 4 && r2 == 3) then
		rv1 = { rv1[1], rv1[2], rv1[4], rv1[3],
				rv1[5], rv1[6], rv1[8], rv1[7],
				rv1[9], rv1[10], rv1[12], rv1[11],
				rv1[13], rv1[14], rv1[16], rv1[15] }
	elseif (r1 == 1 && r2 == 3) || (r1 == 3 && r2 == 1) then
		rv1 = { rv1[3], rv1[2], rv1[1], rv1[4],
				rv1[7], rv1[6], rv1[5], rv1[8],
				rv1[11], rv1[10], rv1[9], rv1[12],
				rv1[15], rv1[14], rv1[13], rv1[16] }
	elseif (r1 == 2 && r2 == 4) || (r1 == 4 && r2 == 2) then
		rv1 = { rv1[1], rv1[4], rv1[3], rv1[2],
				rv1[5], rv1[8], rv1[7], rv1[6],
				rv1[9], rv1[12], rv1[11], rv1[10],
				rv1[13], rv1[16], rv1[15], rv1[14] }
	elseif (r1 == 1 && r2 == 4) || (r1 == 4 && r2 == 1) then
		rv1 = { rv1[4], rv1[2], rv1[3], rv1[1],
				rv1[8], rv1[6], rv1[7], rv1[5],
				rv1[12], rv1[10], rv1[11], rv1[9],
				rv1[16], rv1[14], rv1[15], rv1[13] }
	end
	return rv1
end)

registerFunction("element", "xm4:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 4 then i = 4
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 4 then j = 4
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 4
	return rv1[k]
end)

registerFunction("setElement", "xm4:nnn", "xm4", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 4 then i = 4
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 4 then j = 4
	else j = rv3 - rv3 % 1 end

	local a = clone(rv1)
	a[i + (j - 1) * 4] = rv4
	return a
end)

registerFunction("swapElements", "xm4:nnnn", "xm4", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	local i1, j1, i2, j2

	if rv2 < 1 then i1 = 1
	elseif rv2 > 4 then i1 = 4
	else i1 = rv2 - rv2 % 1 end

	if rv3 < 1 then j1 = 1
	elseif rv3 > 4 then j1 = 4
	else j1 = rv3 - rv3 % 1 end

	if rv4 < 1 then i2 = 1
	elseif rv4 > 4 then i2 = 4
	else i2 = rv4 - rv4 % 1 end

	if rv5 < 1 then j2 = 1
	elseif rv5 > 4 then j2 = 4
	else j2 = rv5 - rv5 % 1 end

	local k1 = i1 + (j1 - 1) * 4
	local k2 = i2 + (j2 - 1) * 4
	local a = clone(rv1)
	a[k1], a[k2] = rv1[k2], rv1[k1]
	return a
end)

registerFunction("setDiagonal", "xm4:xv4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2[1], rv1[2], rv1[3], rv1[4],
			 rv1[5], rv2[2], rv1[7], rv1[8],
			 rv1[9], rv1[10], rv2[3], rv1[12],
			 rv1[13], rv1[14], rv1[15], rv2[4] }
end)

registerFunction("setDiagonal", "xm4:nnnn", "xm4", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local rv1, rv2, rv3, rv4, rv5 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)
	return { rv2, rv1[2], rv1[3], rv1[4],
			 rv1[5], rv3, rv1[7], rv1[8],
			 rv1[9], rv1[10], rv4, rv1[12],
			 rv1[13], rv1[14], rv1[15], rv5 }
end)

/******************************************************************************/
// Useful matrix maths functions

registerFunction("diagonal", "xm4", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[6], rv1[11], rv1[16] }
end)

registerFunction("trace", "xm4", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return ( rv1[1] + rv1[6] + rv1[11] + rv1[16] )
end)

registerFunction("transpose", "xm4", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[5], rv1[9], rv1[13],
			 rv1[2], rv1[6], rv1[10], rv1[14],
			 rv1[3], rv1[7], rv1[11], rv1[15],
			 rv1[4], rv1[8], rv1[12], rv1[16] }
end)

// find the inverse for a standard affine transformation matix
registerFunction("inverseA", "xm4", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local t1 = rv1[1] * rv1[4] + rv1[5] * rv1[8] + rv1[9] * rv1[12]
	local t2 = rv1[2] * rv1[4] + rv1[6] * rv1[8] + rv1[10] * rv1[12]
	local t3 = rv1[3] * rv1[4] + rv1[7] * rv1[8] + rv1[11] * rv1[12]
	return { rv1[1], rv1[5], rv1[9],  -t1,
			 rv1[2], rv1[6], rv1[10], -t2,
			 rv1[3], rv1[7], rv1[11], -t3,
			 0, 0, 0, 1 }
end)

/******************************************************************************/
// Extra functions

registerFunction("matrix4", "e", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then
		return { 0, 0, 0, 0,
				 0, 0, 0, 0,
				 0, 0, 0, 0,
				 0, 0, 0, 0 }
	end
	local factor = 10000
	local pos = rv1:GetPos()
	local x = rv1:LocalToWorld(Vector(factor,0,0)) - pos
	local y = rv1:LocalToWorld(Vector(0,factor,0)) - pos
	local z = rv1:LocalToWorld(Vector(0,0,factor)) - pos
	return { x.x/factor, y.x/factor, z.x/factor, pos.x,
			 x.y/factor, y.y/factor, z.y/factor, pos.y,
			 x.z/factor, y.z/factor, z.z/factor, pos.z,
			 0, 0, 0, 1 }
end)

registerFunction("x", "xm4:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[5], rv1[9] }
end)

registerFunction("y", "xm4:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[2], rv1[6], rv1[10] }
end)

registerFunction("z", "xm4:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[3], rv1[7], rv1[11] }
end)

registerFunction("pos", "xm4:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[4], rv1[8], rv1[12] }
end)

--- Returns a 3x3 reference frame matrix as described by the angle <ang>. Multiplying by this matrix will be the same as rotating by the given angle.
e2function matrix matrix(angle ang)
	ang = Angle(ang[1], ang[2], ang[3])
	local x = ang:Forward()
	local y = ang:Right() * -1
	local z = ang:Up()
	return {
		x.x, y.x, z.x,
		x.y, y.y, z.y,
		x.z, y.z, z.z
	}
end

--- Returns a 4x4 reference frame matrix as described by the angle <ang>. Multiplying by this matrix will be the same as rotating by the given angle.
e2function matrix4 matrix4(angle ang)
	ang = Angle(ang[1], ang[2], ang[3])
	local x = ang:Forward()
	local y = ang:Right() * -1
	local z = ang:Up()
	return {
		x.x, y.x, z.x, 0,
		x.y, y.y, z.y, 0,
		x.z, y.z, z.z, 0,
		0, 0, 0, 1
	}
end

--- Returns a 4x4 reference frame matrix as described by the angle <ang> and the position <pos>. Multiplying by this matrix will be the same as rotating by the given angle and offsetting by the given vector.
e2function matrix4 matrix4(angle ang, vector pos)
	ang = Angle(ang[1], ang[2], ang[3])
	local x = ang:Forward()
	local y = ang:Right() * -1
	local z = ang:Up()
	return {
		x.x, y.x, z.x, pos[1],
		x.y, y.y, z.y, pos[2],
		x.z, y.z, z.z, pos[3],
		0, 0, 0, 1
	}
end

__e2setcost(nil)
