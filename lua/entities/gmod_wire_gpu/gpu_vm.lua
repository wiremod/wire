if (EmuFox) then
	include('gmod_wire_cpu/cpu_vm.lua')		//Include ZCPU VM
	include('gmod_wire_cpu/cpu_opcodes.lua')	//Include ZCPU opcodes
	include('gmod_wire_cpu/cpu_bitwise.lua')	//Include bitwise operations

	include('gmod_wire_gpu/gpu_opcodes.lua')	//Override ZCPU opcodes
	include('gmod_wire_gpu/gpu_clientbus.lua')	//Own GPU bus
	include('gmod_wire_gpu/gpu_interrupt.lua')	//Own GPU interrupts
else
	include('entities/gmod_wire_cpu/cpu_vm.lua')		//Include ZCPU VM
	include('entities/gmod_wire_cpu/cpu_opcodes.lua')	//Include ZCPU opcodes
	include('entities/gmod_wire_cpu/cpu_bitwise.lua')	//Include bitwise operations

	include('gpu_opcodes.lua')				//Override ZCPU opcodes
	include('gpu_clientbus.lua')				//Own GPU bus
	include('gpu_interrupt.lua')				//Own GPU interrupts
end

function ENT:GPUHardReset()
	self.HandleError = 0
	self:GPUFrameReset()

	self.EntryPoint = {}
	self.EntryPoint[0] = 0

	self.Memory[65533] = 1
	self.Memory[65531] = 0
end

function ENT:GPURAMReset()
	self.Memory = {}
	self.ROMMemory = {}

	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self:GPUMathInit()
end

function ENT:GPUFrameReset()
	self:Reset()

	//Remove junk:
	self.Page = nil
	self.IDTR = nil
	self.EF = nil
	self.PF = nil
	self.IF = nil
	self.LADD = nil
	self.BusLock = nil
	self.Idle = nil
	self.CPAGE = nil

	self.ESP = 32767

	self.TIMER = self.PrevTime

	//Initialize GPU
	self:GPUResetRegisters()
	self:GPUMathReset()
end

function ENT:GPUResetRegisters()
	//self:WriteCell(65533,0) //Restore first page

	//Hardware control registers:
	//[65535] - CLK
	//[65534] - RESET
	//[65533] - HARDWARE CLEAR
	//[65532] - Vertex mode (render vertex instead of RT)
	//[65531] - HALT
	//[65530] - RAM_RESET

	self.Memory[65535] = 1
	self.Memory[65534] = 0
	//self.Memory[65533] = 1
	self.Memory[65532] = 0
	//self.Memory[65531] = 0

	//Image control:
	//[65525] - Horizontal image scale
	//[65524] - Vertical image scale
	//[65523] - Hardware scale
	//[65522] - Rotation (0 - 0*, 1 - 90*, 2 - 180*, 3 - 270*)
	//[65521] - Sprite/texture size [32]
	//[65520] - Pointer to texture data
	//[65519] - Size of texture data
	//[65518] - Raster quality

	self.Memory[65525] = 1
	self.Memory[65524] = 1
	self.Memory[65523] = 0
	self.Memory[65522] = 0
	self.Memory[65521] = 32
	self.Memory[65520] = 0
	self.Memory[65519] = 0
	self.Memory[65518] = 0

	//Vertex pipe controls:
	//[65515] - Image width (800)
	//[65514] - Image height (600)
	//[65513] - Real screen ratio
	//[65512] - Parameter list address (for dwritefmt)

	self.Memory[65515] = 800
	self.Memory[65514] = 600
	//self.Memory[65513] = 0
	self.Memory[65512] = 0

	//Cursor control:
	//[65505] - Cursor X (0..1)
	//[65504] - Cursor Y (0..1)
	//[65503] - Cursor visible

	//self.Memory[65505] = 0
	//self.Memory[65504] = 0
	self.Memory[65503] = 0

	//Brightness control:
	//[65495] - Brightness W
	//[65494] - Brightness R
	//[65493] - Brightness G
	//[65492] - Brightness B
	//[65491] - Contrast W
	//[65490] - Contrast R
	//[65489] - Contrast G
	//[65488] - Contrast B

	self.Memory[65495] = 1
	self.Memory[65494] = 1
	self.Memory[65493] = 1
	self.Memory[65492] = 1
	self.Memory[65491] = 0
	self.Memory[65490] = 0
	self.Memory[65489] = 0
	self.Memory[65488] = 0

	//Rendering settings
	//[65485] - Circle quality (3..128)
	//[65484] - Offset Point X
	//[65483] - Offset Point Y
	//[65482] - Rotation (rad)
	//[65481] - Scale
	//[65480] - Center point X
	//[65479] - Center point Y
	//[65478] - Circle start (rad)
	//[65477] - Circle end (rad)
	//[65476] - Line width (1)
	//[65475] - Scale X
	//[65474] - Scale Y
	//[65473] - Font align
	//[65472] - ZOffset

	self.Memory[65485] = 32
	self.Memory[65484] = 0
	self.Memory[65483] = 0
	self.Memory[65482] = 0
	self.Memory[65481] = 1
	self.Memory[65480] = 0
	self.Memory[65479] = 0
	self.Memory[65478] = 0
	self.Memory[65477] = 3.141592*2
	self.Memory[65476] = 1
	self.Memory[65475] = 1
	self.Memory[65474] = 1
	self.Memory[65473] = 0
	self.Memory[65472] = 0


	//=================================
	//[64512] - last register
	//Ports:
	//[63488]..[64511] - External ports
end

function ENT:InitializeGPUVariableSet()
	self:InitializeCPUVariableSet()

	self.CPUVariable[24] = nil	//IDTR
	self.CPUVariable[27] = nil	//LADD

	self.CPUVariable[32] = nil	//IF
	self.CPUVariable[33] = nil	//PF
	self.CPUVariable[34] = nil	//EF

	self.CPUVariable[45] = nil	//BusLock
	self.CPUVariable[46] = nil	//IDLE
	self.CPUVariable[47] = nil	//INTR

	self.CPUVariable[52] = nil	//NIDT
end

function ENT:InitializeGPULookupTables()
	self:InitializeLookupTables()

	for i=1000,2024 do
		self.ParamFunctions_1[i] = function() return self:ReadCell(63488+self.PrecompileData[self.XEIP].dRM1-1000) end
		self.ParamFunctions_2[i] = function() return self:ReadCell(63488+self.PrecompileData[self.XEIP].dRM2-1000) end
		self.WriteBackFunctions[i] = function(Result) self:WriteCell(63488+self.PrecompileData[self.XEIP].dRM1-1000,Result) end
		self.WriteBackFunctions2[i] = function(Result) self:WriteCell(63488+self.PrecompileData[self.XEIP].dRM2-1000,Result) end
	end

end

function ENT:GPUExecute()
//	self.TIMER = self.TIMER + self.DeltaTime
	self.TMR = self.TMR + 1

	if (not self.IP) then
		self:Interrupt(5,0)
		return
	end

	self.XEIP = self.IP+self.CS
	self.CPAGE = math.floor(self.XEIP / 128)

	//Dynamic precompiler: check if opcode was precompiled
	if (self.PrecompileData[self.XEIP]) then
		//Simulate read
		self.IP = self.IP + self.PrecompileData[self.XEIP].Size
		self.CODEBYTES = self.CODEBYTES + self.PrecompileData[self.XEIP].Size

		//Verify opcode
		if (self.PrecompileData[self.XEIP].Valid) then
			//Execute
			local Result = self.PrecompileData[self.XEIP].Execute()
			if (Result) then
				if (Result == "Read error") then
					self:Interrupt(5,1) //Read error during execute
				else
					self.PrecompileData[self.XEIP].WriteBack(Result)
				end
			end
		else
			if (self.PrecompileData[self.XEIP].UnknownOpcode) then
				self:Interrupt(4,self.PrecompileData[self.XEIP].Opcode) //Unknown Opcode
			else
				self:Interrupt(5,2) //Internal/opcode read error
			end
		end
	else
		self:Precompile(self.XEIP)
	end
end

function ENT:GPUMathInit()
	self.FontNames = {}
	self.FontNames[0] = "Lucida Console"
	self.FontNames[1] = "Courier New"
	self.FontNames[2] = "Trebuchet"
	self.FontNames[3] = "Arial"
	self.FontNames[4] = "Times New Roman"

	self:GPUMathReset()
end

function ENT:GPUMathReset()
	self.StringCache = {}

	//CVertex pipes:
	//0 - direct (0..512 or 0..1024 range)
	//1 - mapped to screen (set by special registers in GPU)
	//2 - mapped to 0..1 range
	//3 - mapped to -1..1 range

	//Vertex pipes:
	//0 - XY mapping
	//1 - YZ mapping
	//2 - XZ mapping
	//3 - XYZ projective mapping
	//4 - XY mapping + matrix
	//5 - XYZ projective mapping + matrix

	//Entry points:
	//[0] 	DRAW	Called when screen is being drawn
	//[1]	INIT	Called when screen is initialized (reuploaded)
	//[2]	USE	Called when screen is used
	//[3]   ERROR   Called when GPU error occurs (instead of DRAW)
	//[4]	ASYNC	Called when GPU is reset, for running asynchrounous thread

	//DDisable/DEnable parameters:
	//[0]	VERTEX_ZSORT		Enable or disable ZSorting in vertex buffer (sorted on flush)
	//[1]	VERTEX_LIGHTING		Enable or disable vertex lighting
	//[2]	VERTEX_BUFFER		Enable or disable vertex buffer
	//[3]	VERTEX_CULLING		Enable or disable culling on faces
	//[4]

	self.CVertexPipe = 0
	self.VertexPipe = 0

	self.VertexBufEnabled = false
	self.VertexBufZSort = false
	self.VertexLighting = false
	self.VertexCulling = false

	self.VertexBuffer = {}
	self.VertexBufferCount = 0

	self.Lights = {}

	self.CurFont = 0
	self.CurFontSize = 12
	self.CurColor = {x = 0, y = 0, z = 0, w = 255}

	//Model transform matrix
	self.ModelMatrix = {}

	self.ModelMatrix[0]  = 1
	self.ModelMatrix[1]  = 0
	self.ModelMatrix[2]  = 0
	self.ModelMatrix[3]  = 0

	self.ModelMatrix[4]  = 0
	self.ModelMatrix[5]  = 1
	self.ModelMatrix[6]  = 0
	self.ModelMatrix[7]  = 0

	self.ModelMatrix[8]  = 0
	self.ModelMatrix[9]  = 0
	self.ModelMatrix[10] = 1
	self.ModelMatrix[11] = 0

	self.ModelMatrix[12] = 0
	self.ModelMatrix[13] = 0
	self.ModelMatrix[14] = 0
	self.ModelMatrix[15] = 1

	//View transform matrix
	self.ProjectionMatrix = {}

	self.ProjectionMatrix[0]  = 1
	self.ProjectionMatrix[1]  = 0
	self.ProjectionMatrix[2]  = 0
	self.ProjectionMatrix[3]  = 0

	self.ProjectionMatrix[4]  = 0
	self.ProjectionMatrix[5]  = 1
	self.ProjectionMatrix[6]  = 0
	self.ProjectionMatrix[7]  = 0

	self.ProjectionMatrix[8]  = 0
	self.ProjectionMatrix[9]  = 0
	self.ProjectionMatrix[10] = 1
	self.ProjectionMatrix[11] = 0

	self.ProjectionMatrix[12] = 0
	self.ProjectionMatrix[13] = 0
	self.ProjectionMatrix[14] = 0
	self.ProjectionMatrix[15] = 1
end

function ENT:Transform(x,y)
	local transx = x
	local transy = y

	if ((self:ReadCell(65482) != 0) || (self:ReadCell(65481) != 1)) then
		local centerx = self:ReadCell(65480)
		local centery = self:ReadCell(65479)

		local vd = math.sqrt((x-centerx)*(x-centerx)+(y-centery)*(y-centery)) + 0.0001
		local vx = x / vd
		local vy = y / vd

		local atan = math.atan2(vx,vy)

		atan = atan + self:ReadCell(65482)

		transx = math.cos(atan) * vd * self:ReadCell(65481) * self:ReadCell(65475) + centerx
		transy = math.sin(atan) * vd * self:ReadCell(65481) * self:ReadCell(65474) + centery
	end

	transx = transx+self:ReadCell(65484)
	transy = transy+self:ReadCell(65483)

	if     (self.CVertexPipe == 0) then
		transx = transx
	elseif (self.CVertexPipe == 1) then
		transx = (transx/self:ReadCell(65515))*512
	elseif (self.CVertexPipe == 2) then
		transx = transx*512
	elseif (self.CVertexPipe == 3) then
		transx = 256+transx*256
	elseif (self.CVertexPipe == 4) then
		transx = 256+transx
	end

	if     (self.CVertexPipe == 0) then
		transy = transy
	elseif (self.CVertexPipe == 1) then
		transy = (transy/self:ReadCell(65514))*512
	elseif (self.CVertexPipe == 2) then
		transy = transy*512
	elseif (self.CVertexPipe == 3) then
		transy = 256+transy*256
	elseif (self.CVertexPipe == 4) then
		transy = 256+transy
	end

	local trans = {}
	local rasterq = self:ReadCell(65518)

	if (rasterq > 0) then
		trans.x = (transx-256)*(1-(rasterq/256))+256
		trans.y = (transy-256)*(1-(rasterq/256))+256
	else
		trans.x = transx
		trans.y = transy
	end
	return trans
end

function ENT:VertexTransform(coord)
	//Make sure coordinate is in full form
	if (not coord)   then coord = {}  end
	if (not coord.x) then coord.x = 0 end
	if (not coord.y) then coord.y = 0 end
	if (not coord.z) then coord.z = 0 end
	if (not coord.w) then coord.w = 1 end
	if (not coord.u) then coord.u = 0 end
	if (not coord.v) then coord.v = 0 end

	local resultcoord = {}
	resultcoord.x = coord.x
	resultcoord.y = coord.y
	resultcoord.z = coord.z
	resultcoord.w = coord.w
	resultcoord.u = coord.u
	resultcoord.v = coord.v

	//Prepare result
	resultcoord.transformed = {} //Transformed 3d point
	resultcoord.transformed.x = 0
	resultcoord.transformed.y = 0
	resultcoord.transformed.z = 0
	resultcoord.transformed.w = 0
	resultcoord.transformed.u = coord.u
	resultcoord.transformed.v = coord.v

	//Add Z offset
	coord.z = coord.z + self:ReadCell(65472)

	if (self.VertexPipe == 0) then
		resultcoord = self:Transform(coord.x,coord.y)
	elseif (self.VertexPipe == 1) then
		resultcoord = self:Transform(coord.y,coord.z)
	elseif (self.VertexPipe == 2) then
		resultcoord = self:Transform(coord.x,coord.z)
	elseif (self.VertexPipe == 3) then
		local transx = (coord.x+self:ReadCell(65512))/(coord.z+self:ReadCell(65512))
		local transy = (coord.y+self:ReadCell(65512))/(coord.z+self:ReadCell(65512))

		resultcoord = self:Transform(transx,transy)
	elseif (self.VertexPipe == 4) then
		local transx = self.ModelMatrix[0*4+0] * coord.x +
		               self.ModelMatrix[0*4+1] * coord.y +
		               self.ModelMatrix[0*4+2] * 0 +
		               self.ModelMatrix[0*4+3] * 1

		local transy = self.ModelMatrix[1*4+0] * coord.x +
		               self.ModelMatrix[1*4+1] * coord.y +
		               self.ModelMatrix[1*4+2] * 0 +
		               self.ModelMatrix[1*4+3] * 1

		resultcoord = self:Transform(transx,transy)
	elseif (self.VertexPipe == 5) then //3d matrix transformation
		//1. Transform into world coordinates
		local world_coord = {}

		for i=0,3 do
			world_coord[i] = self.ModelMatrix[i*4+0] * coord.x +
			                 self.ModelMatrix[i*4+1] * coord.y +
			                 self.ModelMatrix[i*4+2] * coord.z +
			                 self.ModelMatrix[i*4+3] * coord.w
		end

		resultcoord.transformed.x = world_coord[0]
		resultcoord.transformed.y = world_coord[1]
		resultcoord.transformed.z = world_coord[2]
		resultcoord.transformed.w = world_coord[3]

		//2. Transform into screen coordinates
		local screen_coord = {}

		for i=0,3 do
			screen_coord[i] = self.ProjectionMatrix[i*4+0] * world_coord[0] +
			                  self.ProjectionMatrix[i*4+1] * world_coord[1] +
			                  self.ProjectionMatrix[i*4+2] * world_coord[2] +
			                  self.ProjectionMatrix[i*4+3] * world_coord[3]
		end

		if (screen_coord[3] == 0) then screen_coord[3] = 1 end
		for i=0,3 do
			screen_coord[i] = screen_coord[i] / screen_coord[3]
		end

		local transcoord = self:Transform(screen_coord[0],screen_coord[1])
		resultcoord.x = transcoord.x
		resultcoord.y = transcoord.y
		resultcoord.z = screen_coord[2]
		resultcoord.w = screen_coord[3]
	end

	return resultcoord
end

function ENT:TransformColor(color)
	local tcolor = color
	tcolor.x = color.x * self:ReadCell(65495) * self:ReadCell(65494)
	tcolor.y = color.y * self:ReadCell(65495) * self:ReadCell(65493)
	tcolor.z = color.z * self:ReadCell(65495) * self:ReadCell(65492)
	tcolor.w = color.w
	return tcolor
end

function ENT:ReadStr(addr)
	local str = ""
	local cnt = 0
	local chr = 255
	while (chr != 0) do
		chr = self:ReadCell(addr+cnt)
		if ((chr > 0) && (chr < 256)) then
			str = str..string.char(chr)
		else
			if (chr != 0) then
				self:Interrupt(23,chr)
				return ""
			end
		end
		cnt = cnt + 1
		if (cnt > 8192) then
			self:Interrupt(23,0)
			return ""
		end
	end
	return str
end

function ENT:FontWrite(posaddr,text)
	local vertexbuf = {}
	vertexbuf.x = self:ReadCell(posaddr+0)
	vertexbuf.y = self:ReadCell(posaddr+1)
	vertexbuf = self:VertexTransform(vertexbuf)

	surface.CreateFont(self.FontNames[self.CurFont], self.CurFontSize, 800, true, false,
			   "WireGPU_"..self.FontNames[self.CurFont]..self.CurFontSize)
	draw.DrawText(text,"WireGPU_"..self.FontNames[self.CurFont]..self.CurFontSize,
	              vertexbuf.x,vertexbuf.y,Color(self.CurColor.x,self.CurColor.y,self.CurColor.z,255),
	              self:ReadCell(65473))
end

function ENT:DrawLine(point1,point2)
	local vertexbuf = {}
	for i=1,4 do vertexbuf[i] = {} end

	local center = {}
	center.x = (point1.x + point2.x) / 2
	center.y = (point1.y + point2.y) / 2

	local width = self:ReadCell(65476)

	local len = math.sqrt((point1.x-point2.x)*(point1.x-point2.x)+
	                      (point1.y-point2.y)*(point1.y-point2.y)) + 0.0001
	local dx = (point2.x-point1.x) / len
	local dy = (point2.y-point1.y) / len
	local angle = math.atan2(dy,dx)//+3.1415926/2
	local dangle = math.atan2(width,len/2)

	vertexbuf[1].x = center.x - 0.5 * len * math.cos(angle-dangle)
	vertexbuf[1].y = center.y - 0.5 * len * math.sin(angle-dangle)
	vertexbuf[1].u = 0
	vertexbuf[1].v = 0

	vertexbuf[2].x = center.x + 0.5 * len * math.cos(angle+dangle)
	vertexbuf[2].y = center.y + 0.5 * len * math.sin(angle+dangle)
	vertexbuf[2].u = 1
	vertexbuf[2].v = 1

	vertexbuf[3].x = center.x + 0.5 * len * math.cos(angle-dangle)
	vertexbuf[3].y = center.y + 0.5 * len * math.sin(angle-dangle)
	vertexbuf[3].u = 0
	vertexbuf[3].v = 1

	vertexbuf[4].x = center.x - 0.5 * len * math.cos(angle+dangle)
	vertexbuf[4].y = center.y - 0.5 * len * math.sin(angle+dangle)
	vertexbuf[4].u = 1
	vertexbuf[4].v = 0

	self:VertexBuffer_Add(vertexbuf)
end

ENT.VertexSortFunc = function(a,b)
	local z1 = (a.vertexbuft[1].z + a.vertexbuft[2].z + a.vertexbuft[3].z) / 3
	local z2 = (b.vertexbuft[1].z + b.vertexbuft[2].z + b.vertexbuft[3].z) / 3

	return z1 > z2
end


function ENT:VertexBuffer_Flush()
	if (self.VertexBufEnabled == true) then
		//1. Transform vertexes (FIXME: THEY ARE TRANSFORMED WHEN PASSED)
		--[[for i=1,self.VertexBufferCount do
			//print(i)
			//print("        input  xyz: ("..self.VertexBuffer[1].vertexbuf[1].x..",")//
			//print("                     "..self.VertexBuffer[1].vertexbuf[1].y..",")//
			//print("                     "..self.VertexBuffer[1].vertexbuf[1].z..")")

			self.VertexBuffer[i].vertexbuft = {}
			for j=1,#self.VertexBuffer[i].vertexbuf do
				//print(i.."  "..j)
				//print("        input  xyz: ("..self.VertexBuffer[i].vertexbuf[j].x..",")
				//print("                     "..self.VertexBuffer[i].vertexbuf[j].y..",")//
				//print("                     "..self.VertexBuffer[i].vertexbuf[j].z..")")

				self.VertexBuffer[i].vertexbuft[j] = self:VertexTransform(self.VertexBuffer[i].vertexbuf[j])
			end
			if (#self.VertexBuffer[i].vertexbuf < 3) then
				return
			end
		end]]--

		//2. Perform ZSort
		if self.VertexBufZSort == true then
			table.sort(self.VertexBuffer,self.VertexSortFunc)
		end

		//3. Render each vertex
		for i=1,self.VertexBufferCount do
			if (self.VertexBuffer[i].color) then
				self.CurColor = self.VertexBuffer[i].color
			end

			local Cull = false //We dont want this vertex?
			if (self.VertexCulling == true) || (self.VertexLighting == true) then
				local v1 = Vector(self.VertexBuffer[i].vertexbuft[1].transformed.x,
						  self.VertexBuffer[i].vertexbuft[1].transformed.y,
						  self.VertexBuffer[i].vertexbuft[1].transformed.z)
				local v2 = Vector(self.VertexBuffer[i].vertexbuft[2].transformed.x,
						  self.VertexBuffer[i].vertexbuft[2].transformed.y,
						  self.VertexBuffer[i].vertexbuft[2].transformed.z)
				local v3 = Vector(self.VertexBuffer[i].vertexbuft[3].transformed.x,
						  self.VertexBuffer[i].vertexbuft[3].transformed.y,
						  self.VertexBuffer[i].vertexbuft[3].transformed.z)

				local t1 = Vector(self.VertexBuffer[i].vertexbuft[1].x,
						  self.VertexBuffer[i].vertexbuft[1].y,
						  self.VertexBuffer[i].vertexbuft[1].z)
				local t2 = Vector(self.VertexBuffer[i].vertexbuft[2].x,
						  self.VertexBuffer[i].vertexbuft[2].y,
						  self.VertexBuffer[i].vertexbuft[2].z)

				//local vpos = (v1+v2+v3) * 1/3
				local vpos = {
					x = (v1.x+v2.x) * 1/3,
					y = (v1.y+v2.y) * 1/3,
					z = (v1.z+v2.z) * 1/3
				}

				//local tpos = (t1+t2+t3) * 1/3
				local tpos = {
					x = (t1.x+t2.x) * 1/3,
					y = (t1.y+t2.y) * 1/3,
					z = (t1.z+t2.z) * 1/3
				}

				//local normal = (v1 - v2):Cross(v2 - v3)
				local normal = {
					x = (v1.y - v2.y)*(v2.z - v3.z) - (v1.z - v2.z)*(v2.y - v3.y),
					y = (v1.z - v2.z)*(v2.x - v3.x) - (v1.x - v2.x)*(v2.z - v3.z),
					z = (v1.x - v2.x)*(v2.y - v3.y) - (v1.y - v2.y)*(v2.x - v3.x)
				}

				//normal:Normalize()
				local d = (normal.x^2 + normal.y^2 + normal.z^2)^(0.5)+1e-7
				normal.x = normal.x / d
				normal.y = normal.y / d
				normal.z = normal.z / d


				if (self.VertexCulling == true) then
					local cullval = (self.VertexBuffer[i].vertexbuft[1].x - self.VertexBuffer[i].vertexbuft[2].x)*
							(self.VertexBuffer[i].vertexbuft[2].y - self.VertexBuffer[i].vertexbuft[3].y) -
							(self.VertexBuffer[i].vertexbuft[1].y - self.VertexBuffer[i].vertexbuft[2].y)*
							(self.VertexBuffer[i].vertexbuft[2].x - self.VertexBuffer[i].vertexbuft[3].x)
					if (cullval > 0) then Cull = true end
				end


				//if ((self.VertexBuffer[i].vertexbuft[1].z < 0.5) and
				//    (self.VertexBuffer[i].vertexbuft[2].z < 0.5) and
				//    (self.VertexBuffer[i].vertexbuft[3].z < 0.5)) then Cull = true end

				if ((self.VertexBuffer[i].vertexbuft[1].transformed.z > -1) or
				    (self.VertexBuffer[i].vertexbuft[2].transformed.z > -1) or
				    (self.VertexBuffer[i].vertexbuft[3].transformed.z > -1)) then Cull = true end

				//Perform face shading on this vertex
				if ((self.VertexLighting == true) && (Cull == false)) then
					local diffuse_color = {}
					diffuse_color.x = 0
					diffuse_color.y = 0
					diffuse_color.z = 0
					diffuse_color.w = 255

					for i=0,7 do //Apply lights
						if (self.Lights[i]) then
							local plight = self.Lights[i].pos//self:VertexTransform(self.Lights[i].pos)
							local vlight = Vector(plight.x,plight.y,plight.z)//.transformed

							//local vvec = (tpos - vlight):Normalize()
							local vvec = {
								x = tpos.x - vlight.x,
								y = tpos.y - vlight.y,
								z = tpos.z - vlight.z
							}
							local dv = (vvec.x^2 + vvec.y^2 + vvec.z^2)^(0.5)+0.0001
							vvec.x = vvec.x / dv
							vvec.y = vvec.y / dv
							vvec.z = vvec.z / dv

							local brightness = self.Lights[i].col.w

							//local diffuse = normal:Dot(vvec)
							local diffuse = -(vvec.x*normal.x+vvec.y*normal.y+vvec.z*normal.z)

							//diffuse < 0 = invisible face (to light)
							//could be shaded...
							//if (diffuse < 0) then diffuse = 0 end
							diffuse = math.abs(diffuse * brightness)

							diffuse_color.x = math.Clamp(diffuse_color.x + self.Lights[i].col.x * diffuse,0,255)
							diffuse_color.y = math.Clamp(diffuse_color.y + self.Lights[i].col.y * diffuse,0,255)
							diffuse_color.z = math.Clamp(diffuse_color.z + self.Lights[i].col.z * diffuse,0,255)
						end
					end

					//FIXME: support for object color
					//self.CurColor.x = diffuse_color.x * (self.CurColor.x / 255)
					//self.CurColor.y = diffuse_color.y * (self.CurColor.y / 255)
					//self.CurColor.z = diffuse_color.z * (self.CurColor.z / 255)
					self.CurColor = diffuse_color
				end
			end
			if (Cull == false) then
				//self.CurColor.x = math.Clamp( self.VertexBuffer[i].vertexbuft[1].transformed.z * 0.1,0,255)
				//self.CurColor.y = 0
				//self.CurColor.z = math.Clamp(-self.VertexBuffer[i].vertexbuft[1].transformed.z * 0.1,0,255)

				surface.SetDrawColor(self.CurColor.x,self.CurColor.y,self.CurColor.z,self.CurColor.w)
				surface.DrawPoly(self.VertexBuffer[i].vertexbuft)
			end
		end

 		self.VertexBuffer = {}
		self.VertexBufferCount = 0
	end
end

function ENT:VertexBuffer_SetColor(color)
	if (self.VertexBufEnabled == true) then
		if (self.VertexBufferCount > 0) then
			if (not self.VertexBuffer[self.VertexBufferCount]) then	self.VertexBuffer[self.VertexBufferCount] = {} end
			self.VertexBuffer[self.VertexBufferCount].color = self:TransformColor(color)
		else
			if (not self.VertexBuffer[self.VertexBufferCount+1]) then self.VertexBuffer[self.VertexBufferCount+1] = {} end
			self.VertexBuffer[self.VertexBufferCount+1].color = self:TransformColor(color)
		end
	else
		local tcolor = self:TransformColor(color)
		self.CurColor = tcolor
 		surface.SetDrawColor(tcolor.x,tcolor.y,tcolor.z,tcolor.w)
		surface.SetTexture(0)
	end
end

function ENT:VertexBuffer_Add(vertexbuf)
	if (self.VertexBufEnabled == true) then
		self.VertexBufferCount = self.VertexBufferCount + 1
		if (not self.VertexBuffer[self.VertexBufferCount]) then	self.VertexBuffer[self.VertexBufferCount] = {} end

		self.VertexBuffer[self.VertexBufferCount].vertexbuf = {}
		self.VertexBuffer[self.VertexBufferCount].vertexbuft = {}
		for i=1,#vertexbuf do
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i] = {}
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i].x = vertexbuf[i].x
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i].y = vertexbuf[i].y
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i].z = vertexbuf[i].z
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i].u = vertexbuf[i].u
			self.VertexBuffer[self.VertexBufferCount].vertexbuf[i].v = vertexbuf[i].v

			self.VertexBuffer[self.VertexBufferCount].vertexbuft[i] = self:VertexTransform(vertexbuf[i])
		end

		//FIXME: why directly setting does not work??
		//self.VertexBuffer[self.VertexBufferCount].vertexbuf = vertexbuf
	else
		for i=1,#vertexbuf do
			vertexbuf[i] = self:VertexTransform(vertexbuf[i])
		end

		surface.DrawPoly(vertexbuf)
	end
end
