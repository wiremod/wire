/******************************************************************************\
  Matrix support
\******************************************************************************/

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
	nil,
	function(v)
		return !istable(v) or #v ~= 4
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

e2function matrix2 matrix2()
	return { 0, 0,
			 0, 0 }
end

__e2setcost(5) -- temporary

e2function matrix2 matrix2(vector2 rv1, vector2 rv2)
	return { rv1[1], rv2[1],
			 rv1[2], rv2[2] }
end

e2function matrix2 rowMatrix2(vector2 rv1, vector2 rv2)
	return { rv1[1], rv1[2],
			 rv2[1], rv2[2] }
end

e2function matrix2 matrix2(rv1, rv2, rv3, rv4)
	return { rv1, rv2,
			 rv3, rv4 }
end

e2function matrix2 matrix2(matrix rv1)
	return { rv1[1], rv2[2],
			 rv1[4], rv2[5] }
end

e2function matrix2 identity2()
	return { 1, 0,
			 0, 1 }
end

e2function number operator_is(matrix2 this)
	return (this[1] ~= 0
		or this[2] ~= 0
		or this[3] ~= 0)
		and 1 or 0
end


e2function number operator==(matrix2 rv1, matrix2 rv2)
	return (rv1[1] == rv2[1]
		and rv1[2] == rv2[2]
		and rv1[3] == rv2[3]
		and rv1[4] == rv2[4])
		and 1 or 0
end

/******************************************************************************/
// Basic operations

e2function matrix2 operator_neg(matrix2 rv1)
	return { -rv1[1], -rv1[2],
			 -rv1[3], -rv1[4] }
end

e2function matrix2 operator+(matrix2 rv1, matrix2 rv2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2],
			 rv1[3] + rv2[3], rv1[4] + rv2[4] }
end

e2function matrix2 operator-(matrix2 rv1, matrix2 rv2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2],
			 rv1[3] - rv2[3], rv1[4] - rv2[4] }
end

e2function matrix2 operator*(rv1, matrix2 rv2)
	return { rv1 * rv2[1], rv1 * rv2[2],
			 rv1 * rv2[3], rv1 * rv2[4] }
end

e2function matrix2 operator*(matrix2 rv1, rv2)
	return { rv1[1] * rv2, rv1[2] * rv2,
			 rv1[3] * rv2, rv1[4] * rv2 }
end

e2function vector2 operator*(matrix2 rv1, vector2 rv2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2],
			 rv1[3] * rv2[1] + rv1[4] * rv2[2] }
end

e2function matrix2 operator*(matrix2 rv1, matrix2 rv2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[3],
			 rv1[1] * rv2[2] + rv1[2] * rv2[4],
			 rv1[3] * rv2[1] + rv1[4] * rv2[3],
			 rv1[3] * rv2[2] + rv1[4] * rv2[4] }
end

e2function matrix2 operator/(matrix2 rv1, rv2)
	return { rv1[1] / rv2, rv1[2] / rv2,
			 rv1[3] / rv2, rv1[4] / rv2 }
end

e2function matrix2 operator^(matrix2 rv1, rv2)

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
end

/******************************************************************************/
// Row/column/element manipulation

e2function vector2 matrix2:row(rv2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local x = this[k * 2 - 1]
	local y = this[k * 2]
	return { x, y }
end

e2function vector2 matrix2:column(rv2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local x = this[k]
	local y = this[k + 2]
	return { x, y }
end

e2function matrix2 matrix2:setRow(rv2, rv3, rv4)
	local k

	if rv2 < 1 then k = 2
	elseif rv2 > 2 then k = 4
	else k = (rv2 - rv2 % 1)*2 end

	local a = clone(this)
	a[k - 1] = rv3
	a[k] = rv4
	return a
end

e2function matrix2 matrix2:setRow(rv2, vector2 rv3)
	local k

	if rv2 < 1 then k = 2
	elseif rv2 > 2 then k = 4
	else k = (rv2 - rv2 % 1)*2 end

	local a = clone(this)
	a[k - 1] = rv3[1]
	a[k] = rv3[2]
	return a
end


e2function matrix2 matrix2:setColumn(rv2, rv3, rv4)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k] = rv3
	a[k + 2] = rv4
	return a
end

e2function matrix2 matrix2:setColumn(rv2, vector2 rv3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 2 then k = 2
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k] = rv3[1]
	a[k + 2] = rv3[2]
	return a
end

e2function matrix2 matrix2:swapRows()

	this = { this[3], this[4],
			this[1], this[2] }
	return this
end

e2function matrix2 matrix2:swapColumns()

	this = { this[2], this[1],
			this[4], this[3] }
	return this
end

e2function number matrix2:element(rv2, rv3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 2
	return this[k]
end

e2function matrix2 matrix2:setElement(rv2, rv3, rv4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 2 then i = 2
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 2 then j = 2
	else j = rv3 - rv3 % 1 end

	local a = clone(this)
	a[i + (j - 1) * 2] = rv4
	return a
end

e2function matrix2 matrix2:swapElements(rv2, rv3, rv4, rv5)
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
	local a = clone(this)
	a[k1], a[k2] = this[k2], this[k1]
	return a
end

/******************************************************************************/
// Useful matrix maths functions

e2function vector2 diagonal(matrix2 rv1)
	return { rv1[1], rv1[4] }
end

e2function number trace(matrix2 rv1)
	return ( rv1[1] + rv[4] )
end

e2function number det(matrix2 rv1)
	return ( det2(rv1) )
end

e2function matrix2 transpose(matrix2 rv1)
	return { rv1[1], rv1[3],
			 rv1[2], rv1[4] }
end

e2function matrix2 adj(matrix2 rv1)
	return {  rv1[4], -rv1[2],
			 -rv1[3],  rv1[1] }
end


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
	nil,
	function(v)
		return !istable(v) or #v ~= 9
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

// Converts a rotation matrix to angle form (assumes matrix is orthogonal)
local rad2deg = 180 / math.pi

local function toEulerZYX(a1, a4, a7, a8, a9)
	local pitch = math.asin( -a7 ) * rad2deg
	local yaw = math.atan2( a4, a1 ) * rad2deg
	local roll = math.atan2( a8, a9 ) * rad2deg
	return Angle(pitch, yaw, roll)
end

/******************************************************************************/

__e2setcost(1) -- approximated

e2function matrix matrix()
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end

__e2setcost(5) -- temporary

e2function matrix matrix(vector rv1, vector rv2, vector rv3)
	return { rv1[1], rv2[1], rv3[1],
			 rv1[2], rv2[2], rv3[2],
			 rv1[3], rv2[3], rv3[3] }
end

e2function matrix rowMatrix(vector rv1, vector rv2, vector rv3)
	return { rv1[1], rv1[2], rv1[3],
			 rv2[1], rv2[2], rv2[3],
			 rv3[1], rv3[2], rv3[3],}
end

e2function matrix matrix(rv1, rv2, rv3, rv4, rv5, rv6, rv7, rv8, rv9)
	return { rv1, rv2, rv3,
			 rv4, rv5, rv6,
			 rv7, rv8, rv9 }
end

e2function matrix matrix(matrix2 rv1)
	return { rv1[1], rv1[2], 0,
			 rv1[3], rv1[4], 0,
			 0,		 0,		 0 }
end

e2function matrix identity()
	return { 1, 0, 0,
			 0, 1, 0,
			 0, 0, 1 }
end

e2function number operator_is(matrix this)
	return (
		this[1] ~= 0 or this[2] ~= 0 or this[3] ~= 0
		or this[4] ~= 0 or this[5] ~= 0 or this[6] ~= 0
		or this[7] ~= 0 or this[8] ~= 0 or this[9] ~= 0
	) and 1 or 0
end

e2function number operator==(matrix rv1, matrix rv2)
	return (rv1[1] == rv2[1]
		and rv1[2] == rv2[2]
		and rv1[3] == rv2[3]
		and rv1[4] == rv2[4]
		and rv1[5] == rv2[5]
		and rv1[6] == rv2[6]
		and rv1[7] == rv2[7]
		and rv1[8] == rv2[8]
		and rv1[9] == rv2[9])
		and 1 or 0
end

/******************************************************************************/
// Basic operations

e2function matrix operator_neg(matrix rv1)
	return { -rv1[1], -rv1[2], -rv1[3],
			 -rv1[4], -rv1[5], -rv1[6],
			 -rv1[7], -rv1[8], -rv1[9] }
end

e2function matrix operator+(matrix rv1, matrix rv2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3],
			 rv1[4] + rv2[4], rv1[5] + rv2[5], rv1[6] + rv2[6],
			 rv1[7] + rv2[7], rv1[8] + rv2[8], rv1[9] + rv2[9] }
end

e2function matrix operator-(matrix rv1, matrix rv2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3],
			 rv1[4] - rv2[4], rv1[5] - rv2[5], rv1[6] - rv2[6],
			 rv1[7] - rv2[7], rv1[8] - rv2[8], rv1[9] - rv2[9] }
end

e2function matrix operator*(rv1, matrix rv2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3],
			 rv1 * rv2[4], rv1 * rv2[5], rv1 * rv2[6],
			 rv1 * rv2[7], rv1 * rv2[8], rv1 * rv2[9] }
end

e2function matrix operator*(matrix rv1, rv2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2,
			 rv1[4] * rv2, rv1[5] * rv2, rv1[6] * rv2,
			 rv1[7] * rv2, rv1[8] * rv2, rv1[9] * rv2 }
end

e2function vector operator*(matrix rv1, vector rv2)
	return Vector( rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3],
			 rv1[4] * rv2[1] + rv1[5] * rv2[2] + rv1[6] * rv2[3],
			 rv1[7] * rv2[1] + rv1[8] * rv2[2] + rv1[9] * rv2[3] )
end

e2function matrix operator*(matrix rv1, matrix rv2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[4] + rv1[3] * rv2[7],
			 rv1[1] * rv2[2] + rv1[2] * rv2[5] + rv1[3] * rv2[8],
			 rv1[1] * rv2[3] + rv1[2] * rv2[6] + rv1[3] * rv2[9],
			 rv1[4] * rv2[1] + rv1[5] * rv2[4] + rv1[6] * rv2[7],
			 rv1[4] * rv2[2] + rv1[5] * rv2[5] + rv1[6] * rv2[8],
			 rv1[4] * rv2[3] + rv1[5] * rv2[6] + rv1[6] * rv2[9],
			 rv1[7] * rv2[1] + rv1[8] * rv2[4] + rv1[9] * rv2[7],
			 rv1[7] * rv2[2] + rv1[8] * rv2[5] + rv1[9] * rv2[8],
			 rv1[7] * rv2[3] + rv1[8] * rv2[6] + rv1[9] * rv2[9] }
end

e2function matrix operator/(matrix rv1, rv2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2,
			 rv1[4] / rv2, rv1[5] / rv2, rv1[6] / rv2,
			 rv1[7] / rv2, rv1[8] / rv2, rv1[9] / rv2 }
end

e2function matrix operator^(matrix rv1, rv2)

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
end

/******************************************************************************/
// Row/column/element manipulation

e2function vector matrix:row(rv2)
	local k

	if rv2 < 1 then k = 3
	elseif rv2 > 3 then k = 9
	else k = (rv2 - rv2 % 1)*3 end

	local x = this[k - 2]
	local y = this[k - 1]
	local z = this[k]
	return Vector(x, y, z)
end

e2function vector matrix:column(rv2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local x = this[k]
	local y = this[k + 3]
	local z = this[k + 6]
	return Vector(x, y, z)
end

e2function matrix matrix:setRow(rv2, rv3, rv4, rv5)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k * 3 - 2] = rv3
	a[k * 3 - 1] = rv4
	a[k * 3] = rv5
	return a
end

e2function matrix matrix:setRow(rv2, vector rv3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k * 3 - 2] = rv3[1]
	a[k * 3 - 1] = rv3[2]
	a[k * 3] = rv3[3]
	return a
end

e2function matrix matrix:setColumn(rv2, rv3, rv4, rv5)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k] = rv3
	a[k + 3] = rv4
	a[k + 6] = rv5
	return a
end

e2function matrix matrix:setColumn(rv2, vector rv3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 3 then k = 3
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k] = rv3[1]
	a[k + 3] = rv3[2]
	a[k + 6] = rv3[3]
	return a
end

e2function matrix matrix:swapRows(rv2, rv3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return this
	elseif (r1 == 1 and r2 == 2) or (r1 == 2 and r2 == 1) then
		this = { this[4], this[5], this[6],
				this[1], this[2], this[3],
				this[7], this[8], this[9] }
	elseif (r1 == 2 and r2 == 3) or (r1 == 3 and r2 == 2) then
		this = { this[1], this[2], this[3],
				this[7], this[8], this[9],
				this[4], this[5], this[6] }
	elseif (r1 == 1 and r2 == 3) or (r1 == 3 and r2 == 1) then
		this = { this[7], this[8], this[9],
				this[4], this[5], this[6],
				this[1], this[2], this[3] }
	end
	return this
end

e2function matrix matrix:swapColumns(rv2, rv3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 3 then r1 = 3
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 3 then r2 = 3
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return this
	elseif (r1 == 1 and r2 == 2) or (r1 == 2 and r2 == 1) then
		this = { this[2], this[1], this[3],
				this[5], this[4], this[6],
				this[8], this[7], this[9] }
	elseif (r1 == 2 and r2 == 3) or (r1 == 3 and r2 == 2) then
		this = { this[1], this[3], this[2],
				this[4], this[6], this[5],
				this[7], this[9], this[8] }
	elseif (r1 == 1 and r2 == 3) or (r1 == 3 and r2 == 1) then
		this = { this[3], this[2], this[1],
				this[6], this[5], this[4],
				this[9], this[8], this[7] }
	end
	return this
end

e2function number matrix:element(rv2, rv3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 3
	return this[k]
end

e2function matrix matrix:setElement(rv2, rv3, rv4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 3 then i = 3
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 3 then j = 3
	else j = rv3 - rv3 % 1 end

	local a = clone(this)
	a[i + (j - 1) * 3] = rv4
	return a
end

e2function matrix matrix:swapElements(rv2, rv3, rv4, rv5)
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
	local a = clone(this)
	a[k1], a[k2] = this[k2], this[k1]
	return a
end

e2function matrix matrix:setDiagonal(vector rv2)
	return { rv2[1], this[4], this[7],
			 this[2], rv2[2], this[8],
			 this[3], this[6], rv2[3] }
end

e2function matrix matrix:setDiagonal(rv2, rv3, rv4)
	return { rv2, this[4], this[7],
			 this[2], rv3, this[8],
			 this[3], this[6], rv4 }
end

/******************************************************************************/
// Useful matrix maths functions

e2function vector diagonal(matrix rv1)
	return Vector(rv1[1], rv1[5], rv1[9])
end

e2function number trace(matrix rv1)
	return ( rv1[1] + rv1[5] + rv1[9] )
end

e2function number det(matrix rv1)
	return ( det3(rv1) )
end

e2function matrix transpose(matrix rv1)
	return { rv1[1], rv1[4], rv1[7],
			 rv1[2], rv1[5], rv1[8],
			 rv1[3], rv1[6], rv1[9] }
end

e2function matrix adj(matrix rv1)
	return { rv1[5] * rv1[9] - rv1[8] * rv1[6],	rv1[8] * rv1[3] - rv1[2] * rv1[9],	rv1[2] * rv1[6] - rv1[5] * rv1[3],
			 rv1[7] * rv1[6] - rv1[4] * rv1[9],	rv1[1] * rv1[9] - rv1[7] * rv1[3],	rv1[4] * rv1[3] - rv1[1] * rv1[6],
			 rv1[4] * rv1[8] - rv1[7] * rv1[5],	rv1[7] * rv1[2] - rv1[1] * rv1[8],	rv1[1] * rv1[5] - rv1[4] * rv1[2] }
end

/******************************************************************************/
// Extra functions

e2function matrix matrix(entity rv1)
	if(!IsValid(rv1)) then
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
end

e2function vector matrix:x()
	return Vector(this[1], this[4], this[7])
end

e2function vector matrix:y()
	return Vector(this[2], this[5], this[8])
end

e2function vector matrix:z()
	return Vector(this[3], this[6], this[9])
end

// Returns a 3x3 reference frame matrix as described by the angle <ang>. Multiplying by this matrix will be the same as rotating by the given angle.
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

e2function angle matrix:toAngle()
  return toEulerZYX(this[1], this[4], this[7], this[8], this[9])
end

// Create a rotation matrix in the format (v,n) where v is the axis direction vector and n is degrees (right-handed rotation)
e2function matrix mRotation(vector rv1, rv2)

	local vec
	local len = rv1:Length()
	if len == 1 then vec = rv1
	elseif len > 0 then vec = Vector(rv1[1] / len, rv1[2] / len, rv1[3] / len)
	else return { 0, 0, 0,
				  0, 0, 0,
				  0, 0, 0 }
	end

	local vec2 = Vector( vec[1] * vec[1], vec[2] * vec[2], vec[3] * vec[3] )
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
end

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
	nil,
	function(v)
		return !istable(v) or #v ~= 16
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

e2function matrix4 matrix4()
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end

__e2setcost(5) -- temporary

e2function matrix4 matrix4(vector4 rv1, vector4 rv2, vector4 rv3, vector4 rv4)
	return { rv1[1], rv2[1], rv3[1], rv4[1],
			 rv1[2], rv2[2], rv3[2], rv4[2],
			 rv1[3], rv2[3], rv3[3], rv4[3],
			 rv1[4], rv2[4], rv3[4], rv4[4] }
end

e2function matrix4 rowMatrix4(vector4 rv1, vector4 rv2, vector4 rv3, vector4 rv4)
	return { rv1[1], rv1[2], rv1[3], rv1[4],
			 rv2[1], rv2[2], rv2[3], rv2[4],
			 rv3[1], rv3[2], rv3[3], rv3[4],
			 rv4[1], rv4[2], rv4[3], rv4[4] }
end

e2function matrix4 matrix4(rv1, rv2, rv3, rv4, rv5, rv6, rv7, rv8, rv9, rv10, rv11, rv12, rv13, rv14, rv15, rv16)
	return { rv1, rv2, rv3, rv4,
			 rv5, rv6, rv7, rv8,
			 rv9, rv10, rv11, rv12,
			 rv13, rv14, rv15, rv16 }
end

e2function matrix4 matrix4(matrix2 rv1)
	return { rv1[1], rv1[2], 0, 0,
			 rv1[3], rv1[4], 0, 0,
			 0,		 0,		 0, 0,
			 0,		 0,		 0, 0 }
end

e2function matrix4 matrix4(matrix2 rv1, matrix2 rv2, matrix2 rv3, matrix2 rv4)
	return { rv1[1], rv1[2], rv2[1], rv2[2],
			 rv1[3], rv1[4], rv2[3], rv2[4],
			 rv3[1], rv3[2], rv4[1], rv4[2],
			 rv3[3], rv3[4], rv4[3], rv4[4] }
end

e2function matrix4 matrix4(matrix rv1)
	return { rv1[1], rv1[2], rv1[3], 0,
			 rv1[4], rv1[5], rv1[6], 0,
			 rv1[7], rv1[8], rv1[9], 0,
			 0,		 0,		 0,		 0 }
end

e2function matrix4 identity4()
	return { 1, 0, 0, 0,
			 0, 1, 0, 0,
			 0, 0, 1, 0,
			 0, 0, 0, 1 }
end

e2function number operator_is(matrix4 this)
	return (
		this[1] ~= 0 or this[2] ~= 0 or this[3] ~= 0 or this[4] ~= 0
		or this[5] ~= 0 or this[6] ~= 0 or this[7] ~= 0 or this[8] ~= 0
		or this[9] ~= 0 or this[10] ~= 0 or this[11] ~= 0 or this[12] ~= 0
		or this[13] ~= 0 or this[14] ~= 0 or this[15] ~= 0 or this[16] ~= 0
	) and 1 or 0
end

e2function number operator==(matrix4 rv1, matrix4 rv2)
	return (rv1[1] == rv2[1]
		and rv1[2] == rv2[2]
		and rv1[3] == rv2[3]
		and rv1[4] == rv2[4]
		and rv1[5] == rv2[5]
		and rv1[6] == rv2[6]
		and rv1[7] == rv2[7]
		and rv1[8] == rv2[8]
		and rv1[9] == rv2[9]
		and rv1[10] == rv2[10]
		and rv1[11] == rv2[11]
		and rv1[12] == rv2[12]
		and rv1[13] == rv2[13]
		and rv1[14] == rv2[14]
		and rv1[15] == rv2[15]
		and rv1[16] == rv2[16])
		and 1 or 0
end

/******************************************************************************/
// Basic operations

e2function matrix4 operator_neg(matrix4 rv1)
	return { -rv1[1],	-rv1[2],	-rv1[3],	-rv1[4],
			 -rv1[5],	-rv1[6],	-rv1[7],	-rv1[8],
			 -rv1[9],	-rv1[10],	-rv1[11],	-rv1[12],
			 -rv1[13],	-rv1[14],	-rv1[15],	-rv1[16] }
end

e2function matrix4 operator+(matrix4 rv1, matrix4 rv2)
	return { rv1[1] + rv2[1],	rv1[2] + rv2[2],	rv1[3] + rv2[3],	rv1[4] + rv2[4],
			 rv1[5] + rv2[5],	rv1[6] + rv2[6],	rv1[7] + rv2[7],	rv1[8] + rv2[8],
			 rv1[9] + rv2[9],	rv1[10] + rv2[10],	rv1[11] + rv2[11],	rv1[12] + rv2[12],
			 rv1[13] + rv2[13],	rv1[14] + rv2[14],	rv1[15] + rv2[15],	rv1[16] + rv2[16] }
end

e2function matrix4 operator-(matrix4 rv1, matrix4 rv2)
	return { rv1[1] - rv2[1],	rv1[2] - rv2[2],	rv1[3] - rv2[3],	rv1[4] - rv2[4],
			 rv1[5] - rv2[5],	rv1[6] - rv2[6],	rv1[7] - rv2[7],	rv1[8] - rv2[8],
			 rv1[9] - rv2[9],	rv1[10] - rv2[10],	rv1[11] - rv2[11],	rv1[12] - rv2[12],
			 rv1[13] - rv2[13],	rv1[14] - rv2[14],	rv1[15] - rv2[15],	rv1[16] - rv2[16] }
end

e2function matrix4 operator*(rv1, matrix4 rv2)
	return { rv1 * rv2[1],	rv1 * rv2[2],	rv1 * rv2[3],	rv1 * rv2[4],
			 rv1 * rv2[5],	rv1 * rv2[6],	rv1 * rv2[7],	rv1 * rv2[8],
			 rv1 * rv2[9],	rv1 * rv2[10],	rv1 * rv2[11],	rv1 * rv2[12],
			 rv1 * rv2[13],	rv1 * rv2[14],	rv1 * rv2[15],	rv1 * rv2[16] }
end

e2function matrix4 operator*(matrix4 rv1, rv2)
	return { rv1[1] * rv2,	rv1[2] * rv2,	rv1[3] * rv2,	rv1[4] * rv2,
			 rv1[5] * rv2,	rv1[6] * rv2,	rv1[7] * rv2,	rv1[8] * rv2,
			 rv1[9] * rv2,	rv1[10] * rv2,	rv1[11] * rv2,	rv1[12] * rv2,
			 rv1[13] * rv2,	rv1[14] * rv2,	rv1[15] * rv2,	rv1[16] * rv2 }
end

e2function vector4 operator*(matrix4 rv1, vector4 rv2)
	return { rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3] + rv1[4] * rv2[4],
			 rv1[5] * rv2[1] + rv1[6] * rv2[2] + rv1[7] * rv2[3] + rv1[8] * rv2[4],
			 rv1[9] * rv2[1] + rv1[10] * rv2[2] + rv1[11] * rv2[3] + rv1[12] * rv2[4],
			 rv1[13] * rv2[1] + rv1[14] * rv2[2] + rv1[15] * rv2[3] + rv1[16] * rv2[4] }
end

e2function matrix4 operator*(matrix4 lhs, matrix4 rhs)
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
end

e2function matrix4 operator/(matrix4 rv1, rv2)
	return { rv1[1] / rv2,	rv1[2] / rv2,	rv1[3] / rv2,	rv1[4] / rv2,
			 rv1[5] / rv2,	rv1[6] / rv2,	rv1[7] / rv2,	rv1[8] / rv2,
			 rv1[9] / rv2,	rv1[10] / rv2,	rv1[11] / rv2,	rv1[12] / rv2,
			 rv1[13] / rv2,	rv1[14] / rv2,	rv1[15] / rv2,	rv1[16] / rv2 }
end

e2function matrix4 operator^(matrix4 lhs, rhs)

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
end

/******************************************************************************/
// Row/column/element manipulation

e2function vector4 matrix4:row(rv2)
	local k

	if rv2 < 1 then k = 4
	elseif rv2 > 4 then k = 16
	else k = (rv2 - rv2 % 1)*4 end

	local x = this[k - 3]
	local y = this[k - 2]
	local z = this[k - 1]
	local w = this[k]
	return { x, y, z, w }
end

e2function vector4 matrix4:column(rv2)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local x = this[k]
	local y = this[k + 4]
	local z = this[k + 8]
	local w = this[k + 12]
	return { x, y, z, w }
end

e2function matrix4 matrix4:setRow(rv2, rv3, rv4, rv5, rv6)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k * 4 - 3] = rv3
	a[k * 4 - 2] = rv4
	a[k * 4 - 1] = rv5
	a[k * 4]	 = rv6
	return a
end

e2function matrix4 matrix4:setRow(rv2, vector4 rv3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k * 4 - 3] = rv3[1]
	a[k * 4 - 2] = rv3[2]
	a[k * 4 - 1] = rv3[3]
	a[k * 4]	 = rv3[4]
	return a
end

e2function matrix4 matrix4:setColumn(rv2, rv3, rv4, rv5, rv6)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k]		= rv3
	a[k + 4]	= rv4
	a[k + 8]	= rv5
	a[k + 12]	= rv6
	return a
end

e2function matrix4 matrix4:setColumn(rv2, vector4 rv3)
	local k

	if rv2 < 1 then k = 1
	elseif rv2 > 4 then k = 4
	else k = rv2 - rv2 % 1 end

	local a = clone(this)
	a[k]		= rv3[1]
	a[k + 4]	= rv3[2]
	a[k + 8]	= rv3[3]
	a[k + 12]	= rv3[4]
	return a
end

e2function matrix matrix:swapRows(rv2, rv3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 4 then r1 = 4
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 4 then r2 = 4
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return this
	elseif (r1 == 1 and r2 == 2) or (r1 == 2 and r2 == 1) then
		this = { this[5], this[6], this[7], this[8],
				this[1], this[2], this[3], this[4],
				this[9], this[10], this[11], this[12],
				this[13], this[14], this[15], this[16] }
	elseif (r1 == 2 and r2 == 3) or (r1 == 3 and r2 == 2) then
		this = { this[1], this[2], this[3], this[4],
				this[9], this[10], this[11], this[12],
				this[5], this[6], this[7], this[8],
				this[13], this[14], this[15], this[16] }
	elseif (r1 == 3 and r2 == 4) or (r1 == 4 and r2 == 3) then
		this = { this[1], this[2], this[3], this[4],
				this[5], this[6], this[7], this[8],
				this[13], this[14], this[15], this[16],
				this[9], this[10], this[11], this[12] }
	elseif (r1 == 1 and r2 == 3) or (r1 == 3 and r2 == 1) then
		this = { this[9], this[10], this[11], this[12],
				this[5], this[6], this[7], this[8],
				this[1], this[2], this[3], this[4],
				this[13], this[14], this[15], this[16] }
	elseif (r1 == 2 and r2 == 4) or (r1 == 4 and r2 == 2) then
		this = { this[1], this[2], this[3], this[4],
				this[13], this[14], this[15], this[16],
				this[9], this[10], this[11], this[12],
				this[5], this[6], this[7], this[8] }
	elseif (r1 == 1 and r2 == 4) or (r1 == 4 and r2 == 1) then
		this = { this[13], this[14], this[15], this[16],
				this[5], this[6], this[7], this[8],
				this[9], this[10], this[11], this[12],
				this[1], this[2], this[3], this[4] }
	end
	return this
end

e2function matrix4 matrix4:swapColumns(rv2, rv3)
	local r1, r2

	if rv2 < 1 then r1 = 1
	elseif rv2 > 4 then r1 = 4
	else r1 = rv2 - rv2 % 1 end
	if rv3 < 1 then r2 = 1
	elseif rv3 > 4 then r2 = 4
	else r2 = rv3 - rv3 % 1 end

	if r1 == r2 then return this
	elseif (r1 == 1 and r2 == 2) or (r1 == 2 and r2 == 1) then
		this = { this[2], this[1], this[3], this[4],
				this[6], this[5], this[7], this[8],
				this[10], this[9], this[11], this[12],
				this[14], this[13], this[15], this[16] }
	elseif (r1 == 2 and r2 == 3) or (r1 == 3 and r2 == 2) then
		this = { this[1], this[3], this[2], this[4],
				this[5], this[7], this[6], this[8],
				this[9], this[11], this[10], this[12],
				this[13], this[15], this[14], this[16] }
	elseif (r1 == 3 and r2 == 4) or (r1 == 4 and r2 == 3) then
		this = { this[1], this[2], this[4], this[3],
				this[5], this[6], this[8], this[7],
				this[9], this[10], this[12], this[11],
				this[13], this[14], this[16], this[15] }
	elseif (r1 == 1 and r2 == 3) or (r1 == 3 and r2 == 1) then
		this = { this[3], this[2], this[1], this[4],
				this[7], this[6], this[5], this[8],
				this[11], this[10], this[9], this[12],
				this[15], this[14], this[13], this[16] }
	elseif (r1 == 2 and r2 == 4) or (r1 == 4 and r2 == 2) then
		this = { this[1], this[4], this[3], this[2],
				this[5], this[8], this[7], this[6],
				this[9], this[12], this[11], this[10],
				this[13], this[16], this[15], this[14] }
	elseif (r1 == 1 and r2 == 4) or (r1 == 4 and r2 == 1) then
		this = { this[4], this[2], this[3], this[1],
				this[8], this[6], this[7], this[5],
				this[12], this[10], this[11], this[9],
				this[16], this[14], this[15], this[13] }
	end
	return this
end

e2function number matrix4:element(rv2, rv3)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 4 then i = 4
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 4 then j = 4
	else j = rv3 - rv3 % 1 end

	local k = i + (j - 1) * 4
	return this[k]
end

e2function matrix4 matrix4:setElement(rv2, rv3, rv4)
	local i, j

	if rv2 < 1 then i = 1
	elseif rv2 > 4 then i = 4
	else i = rv2 - rv2 % 1 end
	if rv3 < 1 then j = 1
	elseif rv3 > 4 then j = 4
	else j = rv3 - rv3 % 1 end

	local a = clone(this)
	a[i + (j - 1) * 4] = rv4
	return a
end

e2function matrix4 matrix4:swapElements(rv2, rv3, rv4, rv5)
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
	local a = clone(this)
	a[k1], a[k2] = this[k2], this[k1]
	return a
end

e2function matrix4 matrix4:setDiagonal(vector4 rv2)
	return { rv2[1], this[2], this[3], this[4],
			 this[5], rv2[2], this[7], this[8],
			 this[9], this[10], rv2[3], this[12],
			 this[13], this[14], this[15], rv2[4] }
end

e2function matrix4 matrix4:setDiagonal(rv2, rv3, rv4, rv5)
	return { rv2, this[2], this[3], this[4],
			 this[5], rv3, this[7], this[8],
			 this[9], this[10], rv4, this[12],
			 this[13], this[14], this[15], rv5 }
end

/******************************************************************************/
// Useful matrix maths functions

e2function vector4 diagonal(matrix4 rv1)
	return { rv1[1], rv1[6], rv1[11], rv1[16] }
end

e2function number trace(matrix4 rv1)
	return ( rv1[1] + rv1[6] + rv1[11] + rv1[16] )
end

e2function matrix4 transpose(matrix4 rv1)
	return { rv1[1], rv1[5], rv1[9], rv1[13],
			 rv1[2], rv1[6], rv1[10], rv1[14],
			 rv1[3], rv1[7], rv1[11], rv1[15],
			 rv1[4], rv1[8], rv1[12], rv1[16] }
end

// find the inverse for a standard affine transformation matix
e2function matrix4 inverseA(matrix4 rv1)
	local t1 = rv1[1] * rv1[4] + rv1[5] * rv1[8] + rv1[9] * rv1[12]
	local t2 = rv1[2] * rv1[4] + rv1[6] * rv1[8] + rv1[10] * rv1[12]
	local t3 = rv1[3] * rv1[4] + rv1[7] * rv1[8] + rv1[11] * rv1[12]
	return { rv1[1], rv1[5], rv1[9],  -t1,
			 rv1[2], rv1[6], rv1[10], -t2,
			 rv1[3], rv1[7], rv1[11], -t3,
			 0, 0, 0, 1 }
end

/******************************************************************************/
// Extra functions

e2function matrix4 matrix4(entity rv1)
	if(!IsValid(rv1)) then
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
end

e2function vector matrix4:x()
	return Vector(this[1], this[5], this[9])
end

e2function vector matrix4:y()
	return Vector(this[2], this[6], this[10])
end

e2function vector matrix4:z()
	return Vector(this[3], this[7], this[11])
end

e2function vector matrix4:pos()
	return Vector(this[4], this[8], this[12])
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

e2function angle matrix4:toAngle()
  return toEulerZYX(this[1], this[5], this[9], this[10], this[11])
end

e2function matrix matrix4:rotationMatrix()
  return {
    this[1], this[2], this[3],
    this[5], this[6], this[7],
    this[9], this[10], this[11],
  }
end
