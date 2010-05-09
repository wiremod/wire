function ENT:InitializeAdvMathASMOpcodes()
	//- Vector math -------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["vadd"]           = 250 //VADD X,Y		: X = X + Y						[MODEF,MODEF]	7.00
	self.DecodeOpcode["vsub"]           = 251 //VSUB X,Y		: X = X - Y						[MODEF,MODEF]	7.00
	self.DecodeOpcode["vmul"]           = 252 //VMUL X,Y		: X = X * SCALAR Y					[MODEF,MODEF]	7.00
	self.DecodeOpcode["vdot"]           = 253 //VDOT X,Y		: X = X . Y						[MODEF,MODEF]	7.00
	self.DecodeOpcode["vcross"]         = 254 //VCROSS X,Y		: X = X x Y						[MODEF,MODEF]	7.00
	self.DecodeOpcode["vmov"]           = 255 //VMOV X,Y		: X = Y							[MODEF,MODEF]	7.00
	self.DecodeOpcode["vnorm"]          = 256 //VNORM X,Y		: X = NORMALIZE(Y)					[MODEF,MODEF]	7.00
	self.DecodeOpcode["vcolornorm"]     = 257 //VCOLORNORM X,Y	: X = COLOR_NORMALIZE(Y)				[MODEF,MODEF]	7.00
	//- Matrix math -------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["madd"]           = 260 //MADD X,Y		: X = X + Y						[MATRIX,MATRIX]	7.00
	self.DecodeOpcode["msub"]           = 261 //MSUB X,Y		: X = X - Y						[MATRIX,MATRIX]	7.00
	self.DecodeOpcode["mmul"]           = 262 //MMUL X,Y		: X = X * Y						[MATRIX,MATRIX]	7.00
	self.DecodeOpcode["mrotate"]        = 263 //MROTATE X,Y		: X = ROT(Y)						[MATRIX,4F]	7.00
	self.DecodeOpcode["mscale"]         = 264 //MSCALE X,Y		: X = SCALE(Y)						[MATRIX,4F]	7.00
	self.DecodeOpcode["mperspective"]   = 265 //MPERSPECTIVE X,Y	: X = PERSP(Y)						[MATRIX,4F]	7.00
	self.DecodeOpcode["mtranslate"]     = 266 //MTRANSLATE X,Y	: X = TRANS(Y)						[MATRIX,4F]	7.00
	self.DecodeOpcode["mlookat"]        = 267 //MLOOKAT X,Y		: X = LOOKAT(Y)						[MATRIX,4F]	7.00
	self.DecodeOpcode["mmov"]           = 268 //MMOV X,Y		: X = Y							[MATRIX,MATRIX]	7.00
	self.DecodeOpcode["vlen"]           = 269 //VLEN X,Y		: X = Sqrt(Y . Y)					[F,MODEF]	7.00
	self.DecodeOpcode["mident"]         = 270 //MIDENT X		: Load identity matrix into X				[MATRIX]	7.00
	self.DecodeOpcode["vmode"]          = 273 //VMODE X		: Vector mode = Y					[INT]		7.00
	self.DecodeOpcode["vdiv"]           = 295 //VDIV X,Y		: X = X / Y						[MODEF,MODEF]	7.00
	self.DecodeOpcode["vtransform"]     = 296 //VTRANSFORM X,Y	: X = X * Y						[MODEF,MATRIX]	8.00
	//---------------------------------------------------------------------------------------------------------------------
end

function ENT:InitializeAdvMathOpcodeTable()
	//------------------------------------------------------------
	self.OpcodeTable[250] = function (Param1, Param2)	//VADD
		if (self.VMODE == 2) then
			local vec1 = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local vec2 = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = 0})
		else
			local vec1 = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local vec2 = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				{x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = vec1.z + vec2.z})
		end
	end
	self.OpcodeTable[251] = function (Param1, Param2)	//VSUB
		if (self.VMODE == 2) then
			local vec1 = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local vec2 = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = 0})
		else
			local vec1 = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local vec2 = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				{x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z})
		end
	end
	self.OpcodeTable[252] = function (Param1, Param2)	//VMUL
		if (self.VMODE == 2) then
			local vec = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = vec.x*Param2, y = vec.y*Param2, z = 0})
		else
			local vec = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				{x = vec.x*Param2, y = vec.y*Param2, z = vec.z*Param2})
		end
	end
	self.OpcodeTable[253] = function (Param1, Param2)	//VDOT
		if (self.VMODE == 2) then
			local v1 = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local v2 = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:WriteCell(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				v1.x * v2.x + v1.y * v2.y)
		else
			local v1 = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local v2 = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:WriteCell(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				v1.x*v2.x + v1.y*v2.y + v1.z*v2.z)
		end
	end
	self.OpcodeTable[254] = function (Param1, Param2)	//VCROSS
		if (self.VMODE == 2) then
			local v1 = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local v2 = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			self:WriteCell(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				v1.x * v2.y - v1.y * v2.x)
		else
			local v1 = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local v2 = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment1])
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				{x = v1.y * v2.z - v1.z * v2.y, y = v1.z * v2.x - v1.x * v2.z, z = v1.x * v2.y - v1.y * v2.x})
		end
	end
	self.OpcodeTable[255] = function (Param1, Param2)	//VMOV
		if (self.VMODE == 2) then
			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment1]))
		else
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2]))
		end
	end
	self.OpcodeTable[256] = function (Param1, Param2)	//VNORM
		if (self.VMODE == 2) then
			local vec = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment1])
			local d = (vec.x * vec.x + vec.y * vec.y)^0.5 + 10e-9
			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = vec.x / d, y = vec.y / d})
		else
			local vec = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			local d = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)^0.5 + 10e-9
			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
				{x = vec.x / d, y = vec.y / d, z = vec.z / d})
		end
	end
	self.OpcodeTable[257] = function (Param1, Param2)	//VCOLORNORM

	end
	//------------------------------------------------------------
	self.OpcodeTable[260] = function (Param1, Param2)	//MADD
		local mx1 = self:ReadMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
		local mx2 = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rmx = {}

		for i=0,15 do
			rmx[i] = mx1[i] + mx2[i]
		end

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rmx)

	end
	self.OpcodeTable[261] = function (Param1, Param2) 	//MSUB
		local mx1 = self:ReadMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
		local mx2 = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rmx = {}

		for i=0,15 do
			rmx[i] = mx1[i] - mx2[i]
		end

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rmx)

	end
	self.OpcodeTable[262] = function (Param1, Param2) 	//MMUL
		local mx1 = self:ReadMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
		local mx2 = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rmx = {}

		for i=0,3 do
			for j=0,3 do
				rmx[i*4+j] = mx1[i*4+0] * mx2[0*4+j] +
				             mx1[i*4+1] * mx2[1*4+j] +
				             mx1[i*4+2] * mx2[2*4+j] +
				             mx1[i*4+3] * mx2[3*4+j]
			end
		end

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rmx)

	end
	self.OpcodeTable[263] = function (Param1, Param2) 	//MROTATE
		local vec = self:Read4f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rm = {}

		local axis = {}
		axis[0] = vec.x
		axis[1] = vec.y
		axis[2] = vec.z

		local angle = vec.w;

		local mag = math.sqrt(axis[0]*axis[0] + axis[1]*axis[1] + axis[2]*axis[2])
		if (mag > 0) then
			axis[0] = axis[0] / mag
			axis[1] = axis[1] / mag
			axis[2] = axis[2] / mag
		end

		local sine = math.sin(angle)
		local cosine = math.cos(angle)

		local ab = axis[0] * axis[1] * (1 - cosine)
		local bc = axis[1] * axis[2] * (1 - cosine)
		local ca = axis[2] * axis[0] * (1 - cosine)
		local tx = axis[0] * axis[0]
		local ty = axis[1] * axis[1]
		local tz = axis[2] * axis[2]

		rm[0]  = tx + cosine * (1 - tx)
		rm[1]  = ab + axis[2] * sine
		rm[2]  = ca - axis[1] * sine
		rm[3]  = 0
		rm[4]  = ab - axis[2] * sine
		rm[5]  = ty + cosine * (1 - ty)
		rm[6]  = bc + axis[0] * sine
		rm[7]  = 0
		rm[8]  = ca + axis[1] * sine
		rm[9]  = bc - axis[0] * sine
		rm[10] = tz + cosine * (1 - tz)
		rm[11] = 0
		rm[12] = 0
		rm[13] = 0
		rm[14] = 0
		rm[15] = 1

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rm)

	end
	self.OpcodeTable[264] = function (Param1, Param2) 	//MSCALE
		local vec = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rm = {}


		rm[0]  = vec.x
		rm[1]  = 0
		rm[2]  = 0
		rm[3]  = 0

		rm[4]  = 0
		rm[5]  = vec.y
		rm[6]  = 0
		rm[7]  = 0

		rm[8]  = 0
		rm[9]  = 0
		rm[10] = vec.z
		rm[11] = 0

		rm[12] = 0
		rm[13] = 0
		rm[14] = 0
		rm[15] = 1

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rm)

	end
	self.OpcodeTable[265] = function (Param1, Param2) 	//MPERSPECTIVE
		local vec = self:Read4f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rm = {}

		local sine
		local cotangent
		local deltaZ
		local radians = vec.x / 2.0 * 3.1415 / 180.0

		deltaZ = vec.w - vec.z
		sine = math.sin(radians)
		//Should be non-zero to avoid division by zero

		cotangent = math.cos(radians) / sine

		rm[0*4+0] = cotangent / vec.y
		rm[1*4+0] = 0.0;
		rm[2*4+0] = 0.0;
		rm[3*4+0] = 0.0;

		rm[0*4+1] = 0.0;
		rm[1*4+1] = cotangent;
		rm[2*4+1] = 0.0;
		rm[3*4+1] = 0.0;

		rm[0*4+2] = 0.0;
		rm[1*4+2] = 0.0;
		rm[2*4+2] = -(vec.z + vec.w) / deltaZ;
		rm[3*4+2] = -2 * vec.z * vec.w / deltaZ;

		rm[0*4+3] = 0.0;
		rm[1*4+3] = 0.0;
		rm[2*4+3] = -1;
		rm[3*4+3] = 0;

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rm)
	end
	self.OpcodeTable[266] = function (Param1, Param2) 	//MTRANSLATE
		local vec = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
		local rm = {}


		rm[0]  = 1
		rm[1]  = 0
		rm[2]  = 0
		rm[3]  = vec.x

		rm[4]  = 0
		rm[5]  = 1
		rm[6]  = 0
		rm[7]  = vec.y

		rm[8]  = 0
		rm[9]  = 0
		rm[10] = 1
		rm[11] = vec.z

		rm[12] = 0
		rm[13] = 0
		rm[14] = 0
		rm[15] = 1

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rm)
	end
	self.OpcodeTable[267] = function (Param1, Param2) 	//MLOOKAT
		local eye = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2]+0)
		local center = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2]+3)
		local up = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2]+6)
		local rm = {}

		local x = {}
		local y = {}
		local z = {}

		// Difference eye and center vectors to make Z vector
		z[0] = eye.x - center.x
		z[1] = eye.y - center.y
		z[2] = eye.z - center.z

		// Normalize Z
		local mag = math.sqrt(z[0]*z[0] + z[1]*z[1] + z[2]*z[2])
		if (mag > 0) then
			z[0] = z[0] / mag
			z[1] = z[1] / mag
			z[2] = z[2] / mag
		end

		// Up vector makes Y vector
		y[0] = up.x
		y[1] = up.y
		y[2] = up.z

		// X vector = Y cross Z.
		x[0] =	y[1]*z[2] - y[2]*z[1]
		x[1] = -y[0]*z[2] + y[2]*z[0]
		x[2] =	y[0]*z[1] - y[1]*z[0]

		// Recompute Y = Z cross X
		y[0] =	z[1]*x[2] - z[2]*x[1]
		y[1] = -z[0]*x[2] + z[2]*x[0]
		y[2] =	z[0]*x[1] - z[1]*x[0]

		// Normalize X
		mag = math.sqrt(x[0]*x[0] + x[1]*x[1] + x[2]*x[2])
		if (mag > 0) then
			x[0] = x[0] / mag
			x[1] = x[1] / mag
			x[2] = x[2] / mag
		end

		// Normalize Y
		mag = math.sqrt(y[0]*y[0] + y[1]*y[1] + y[2]*y[2])
		if (mag > 0) then
			y[0] = y[0] / mag
			y[1] = y[1] / mag
			y[2] = y[2] / mag
		end

		// Build resulting view matrix.
		rm[0*4+0] = x[0];	rm[0*4+1] = x[1];
		rm[0*4+2] = x[2];	rm[0*4+3] = -x[0]*eye.x + -x[1]*eye.y + -x[2]*eye.z;

		rm[1*4+0] = y[0];	rm[1*4+1] = y[1];
		rm[1*4+2] = y[2];	rm[1*4+3] = -y[0]*eye.x + -y[1]*eye.y + -y[2]*eye.z;

		rm[2*4+0] = z[0];	rm[2*4+1] = z[1];
		rm[2*4+2] = z[2];	rm[2*4+3] = -z[0]*eye.x + -z[1]*eye.y + -z[2]*eye.z;

		rm[3*4+0] = 0.0;	rm[3*4+1] = 0.0;  rm[3*4+2] = 0.0; rm[3*4+3] = 1.0;

		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],rm)
	end
	self.OpcodeTable[268] = function (Param1, Param2) 	//MMOV
		self:WriteMatrix(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
			self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2]))
	end
	self.OpcodeTable[269] = function (Param1, Param2) 	//VLEN
		if (self.VMODE == 2) then
			local vec = self:Read2f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			return (vec.x * vec.x + vec.y * vec.y)^(0.5)
		else
			local vec = self:Read3f(Param2 + self[self.PrecompileData[self.XEIP].Segment2])
			return (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)^(0.5)
		end
	end
	self.OpcodeTable[270] = function (Param1, Param2) 	//MIDENT
		local rm = {}

		rm[0]  = 1
		rm[1]  = 0
		rm[2]  = 0
		rm[3]  = 0

		rm[4]  = 0
		rm[5]  = 1
		rm[6]  = 0
		rm[7]  = 0

		rm[8]  = 0
		rm[9]  = 0
		rm[10] = 1
		rm[11] = 0

		rm[12] = 0
		rm[13] = 0
		rm[14] = 0
		rm[15] = 1

		self:WriteMatrix(Param1,rm)
	end
	self.OpcodeTable[273] = function (Param1, Param2) 	//VMODE
		self.VMODE = math.Clamp(math.floor(Param1),2,3)
	end
	self.OpcodeTable[295] = function (Param1, Param2)	//VDIV
		if (math.abs(Param2) < 1e-12) then
			self:Interrupt(3,0)
		else
			if (self.VMODE == 2) then
				local vec = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
				self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
					{x = vec.x/Param2, y = vec.y/Param2, z = 0})
			else
				local vec = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
				self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment2],
					{x = vec.x/Param2, y = vec.y/Param2, z = vec.z/Param2})
			end
		end
	end
	self.OpcodeTable[296] = function (Param1, Param2)	//VTRANSFORM
		if (self.VMODE == 2) then
			local vec = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local mx = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])

			local tmp = {}
			for i=0,3 do
				tmp[i] = mx[i*4+0] * vec.x +
					 mx[i*4+1] * vec.y +
					 mx[i*4+2] * 0 +
					 mx[i*4+3] * 1
			end


			self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = tmp[0], y = tmp[1], z = 0})
		else
			local vec = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
			local mx = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])

			local tmp = {}
			for i=0,3 do
				tmp[i] = mx[i*4+0] * vec.x +
					 mx[i*4+1] * vec.y +
					 mx[i*4+2] * vec.z +
					 mx[i*4+3] * 1
			end


			self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
				{x = tmp[0], y = tmp[1], z = tmp[2]})
		end
	end
end

function ENT:Read2f(addr)
	local resultcoord = {}
	if (addr == 0) then
		resultcoord.x = 0
		resultcoord.y = 0
		resultcoord.z = 0
		resultcoord.w = 0
	else
		resultcoord.x = self:ReadCell(addr+0)
		resultcoord.y = self:ReadCell(addr+1)
		resultcoord.z = 0
		resultcoord.w = 0
	end
	return resultcoord
end

function ENT:Read3f(addr)
	local resultcoord = {}
	if (addr == 0) then
		resultcoord.x = 0
		resultcoord.y = 0
		resultcoord.z = 0
		resultcoord.w = 0
	else
		resultcoord.x = self:ReadCell(addr+0)
		resultcoord.y = self:ReadCell(addr+1)
		resultcoord.z = self:ReadCell(addr+2)
		resultcoord.w = 0
	end
	return resultcoord
end

function ENT:Read4f(addr)
	local resultcoord = {}
	if (addr == 0) then
		resultcoord.x = 0
		resultcoord.y = 0
		resultcoord.z = 0
		resultcoord.w = 0
	else
		resultcoord.x = self:ReadCell(addr+0)
		resultcoord.y = self:ReadCell(addr+1)
		resultcoord.z = self:ReadCell(addr+2)
		resultcoord.w = self:ReadCell(addr+3)
	end
	return resultcoord
end

function ENT:ReadMatrix(addr)
	local resultmx = {}
	for i=0,15 do
		resultmx[i] = self:ReadCell(addr+i)
	end
	return resultmx
end

function ENT:WriteMatrix(addr,resultmx)
	for i=0,15 do
		self:WriteCell(addr+i,resultmx[i])
	end
end

function ENT:Write2f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
end

function ENT:Write3f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
	self:WriteCell(addr+2,coord.z)
end

function ENT:Write4f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
	self:WriteCell(addr+2,coord.z)
	self:WriteCell(addr+3,coord.w)
end
