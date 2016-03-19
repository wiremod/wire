--------------------------------------------------------------------------------
-- Override virtual machine functions and features
--------------------------------------------------------------------------------
local VM = {}

surface.CreateFont( "WireGPU_ErrorFont",{
	font="Coolvetica",
	size = 26,
	weight = 200,
	antialias = true,
	additive = false
})

function ENT:OverrideVM()
  -- Store VM calls that will be overriden
  self.VM.BaseReset = self.VM.Reset

  -- Add additional VM functionality
  for k,v in pairs(VM) do
    if k == "OpcodeTable" then
      for k2,v2 in pairs(v) do
        self.VM.OpcodeTable[k2] = v2
      end
    else
      self.VM[k] = v
    end
  end

  self.VM.ErrorText = {}
  self.VM.ErrorText[2]  = "Program ended unexpectedly"
  self.VM.ErrorText[3]  = "Arithmetic division by zero"
  self.VM.ErrorText[4]  = "Unknown instruction detected"
  self.VM.ErrorText[5]  = "Internal GPU error"
  self.VM.ErrorText[6]  = "Stack violation error"
  self.VM.ErrorText[7]  = "Memory I/O fault"
  self.VM.ErrorText[13] = "General fault"
  self.VM.ErrorText[15] = "Address space violation"
  self.VM.ErrorText[16] = "Pants integrity violation"
  self.VM.ErrorText[17] = "Frame instruction limit"
  self.VM.ErrorText[23] = "Error reading string data"

  self.VM.Interrupt = function(self,interruptNo,interruptParameter,isExternal,cascadeInterrupt)
    if self.ASYNC == 1 then
      if self.EntryPoint5 > 0 then
        self.IP = self.EntryPoint5
        self.LADD = interruptParameter or self.XEIP
        self.LINT = interruptNo
      else
        -- Shutdown asynchronous thread
        self.Memory[65528] = 0
      end
    else
      if self.EntryPoint3 > 0 then
        self.IP = self.EntryPoint3
        self.LADD = interruptParameter or self.XEIP
        self.LINT = interruptNo
      else
        if (interruptNo == 2) and (self.XEIP == 0) then self.INTR = 1 return end

        if self.RenderEnable == 1 then
          surface.SetTexture(0)
          surface.SetDrawColor(0,0,0,120)
          surface.DrawRect(0,0,self.ScreenWidth,self.ScreenHeight)
		  
          draw.DrawText("Error in the instruction stream","WireGPU_ErrorFont",48,16,Color(255,255,255,255))
          draw.DrawText((self.ErrorText[interruptNo] or "Unknown error").." (#"..interruptNo..")","WireGPU_ErrorFont",16,16+32*2,Color(255,255,255,255))
          draw.DrawText("Parameter: "..(interruptParameter or 0),"WireGPU_ErrorFont",16,16+32*3,Color(255,255,255,255))
          draw.DrawText("Address: "..self.XEIP,"WireGPU_ErrorFont",16,16+32*4,Color(255,255,255,255))

          local errorPosition = CPULib.Debugger.PositionByPointer[self.XEIP]
          if errorPosition then
            local posText = HCOMP:formatPrefix(errorPosition.Line,errorPosition.Col,errorPosition.File)

            draw.DrawText("Debugging data present (may be invalid):","WireGPU_ErrorFont",16,16+32*6,Color(255,255,255,255))
            draw.DrawText("Error at "..posText,"WireGPU_ErrorFont",16,16+32*7,Color(255,255,255,255))
            draw.DrawText("Line: <not available>","WireGPU_ErrorFont",16,16+32*9,Color(255,255,255,255))
          end
        end
        self.INTR = 1
      end
    end
  end

  -- Override ports
  self.VM.WritePort = function(VM,Port,Value)
    VM:WriteCell(63488+Port,Value)
  end
  self.VM.ReadPort = function(VM,Port)
    return VM:ReadCell(63488+Port)
  end

  -- Override writecell
  self.VM.BaseWriteCell = self.VM.WriteCell
  self.VM.WriteCell = function(VM,Address,Value)
    VM:BaseWriteCell(Address,Value)
    if (Address >= 65536) and (Address <= 131071) then
      if VM.MemBusCount < 8 then
        VM.MemBusCount = VM.MemBusCount + 1
        VM.MemBusBuffer[Address] = Value
      end
    elseif Address == 65534 then
      VM:HardReset()
    elseif Address == 65530 then
      VM.ROM = {}
    elseif Address == 65529 then
      VM.AsyncState = {}
    end
  end

  -- Add internal registers
  self.VM.InternalRegister[128] = "EntryPoint0"
  self.VM.InternalRegister[129] = "EntryPoint1"
  self.VM.InternalRegister[130] = "EntryPoint2"
  self.VM.InternalRegister[131] = "EntryPoint3"
  self.VM.InternalRegister[132] = "EntryPoint4"
  self.VM.InternalRegister[133] = "EntryPoint5"
  self.VM.InternalRegister[134] = "EntryPoint6"
  self.VM.InternalRegister[135] = "EntryPoint7"
  self.VM.InternalRegister[136] = "CoordinatePipe"
  self.VM.InternalRegister[137] = "VertexPipe"
  self.VM.InternalRegister[138] = "VertexBufZSort"
  self.VM.InternalRegister[139] = "VertexLighting"
  self.VM.InternalRegister[140] = "VertexBufEnabled"
  self.VM.InternalRegister[141] = "VertexCulling"
  self.VM.InternalRegister[142] = "DistanceCulling"
  self.VM.InternalRegister[143] = "Font"
  self.VM.InternalRegister[144] = "FontSize"
  self.VM.InternalRegister[145] = "WordWrapMode"
  self.VM.InternalRegister[146] = "ASYNC"
  self.VM.InternalRegister[147] = "INIT"

  -- Remove internal registers
  self.VM.InternalRegister[24] = nil --IDTR
  self.VM.InternalRegister[32] = nil --IF
  self.VM.InternalRegister[33] = nil --PF
  self.VM.InternalRegister[34] = nil --EF
  self.VM.InternalRegister[45] = nil --BusLock
  self.VM.InternalRegister[46] = nil --IDLE
  self.VM.InternalRegister[47] = nil --INTR
  self.VM.InternalRegister[52] = nil --NIDT

  -- Remove some instructions
  self.VM.OperandCount[16]  = nil --RD
  self.VM.OperandCount[17]  = nil --WD
  self.VM.OperandCount[28]  = nil --SPG
  self.VM.OperandCount[29]  = nil --CPG
  self.VM.OperandCount[37]  = nil --HALT
  self.VM.OperandCount[41]  = nil --IRET
  self.VM.OperandCount[42]  = nil --STI
  self.VM.OperandCount[43]  = nil --CLI
  self.VM.OperandCount[44]  = nil --STP
  self.VM.OperandCount[45]  = nil --CLP
  self.VM.OperandCount[46]  = nil --STD
  self.VM.OperandCount[48]  = nil --STEF
  self.VM.OperandCount[49]  = nil --CLEF
  self.VM.OperandCount[70]  = nil --EXTINT
  self.VM.OperandCount[95]  = nil --ERPG
  self.VM.OperandCount[96]  = nil --WRPG
  self.VM.OperandCount[97]  = nil --RDPG
  self.VM.OperandCount[99]  = nil --LIDTR
  self.VM.OperandCount[100] = nil --STATESTORE
  self.VM.OperandCount[109] = nil --STATERESTORE
  self.VM.OperandCount[110] = nil --EXTRET
  self.VM.OperandCount[113] = nil --RLADD
  self.VM.OperandCount[116] = nil --STD2
  self.VM.OperandCount[118] = nil --STM
  self.VM.OperandCount[119] = nil --CLM
  self.VM.OperandCount[122] = nil --SPP
  self.VM.OperandCount[123] = nil --CPP
  self.VM.OperandCount[124] = nil --SRL
  self.VM.OperandCount[125] = nil --GRL
  self.VM.OperandCount[131] = nil --SMAP
  self.VM.OperandCount[132] = nil --GMAP

  -- Add some extra lookups
  self.VM.FontName = {}
  self.VM.FontName[0] = "Lucida Console"
  self.VM.FontName[1] = "Courier New"
  self.VM.FontName[2] = "Trebuchet"
  self.VM.FontName[3] = "Arial"
  self.VM.FontName[4] = "Times New Roman"
  self.VM.FontName[5] = "Coolvetica"
  self.VM.FontName[6] = "Akbar"
  self.VM.FontName[7] = "csd"

  -- Add text layouter
  self.VM.Layouter = MakeTextScreenLayouter()
  self.VM.Entity = self
end



--------------------------------------------------------------------------------
-- Switches to a font, creating it if it does not exist
--------------------------------------------------------------------------------
local fontcache = {}
function VM:SetFont()
	local name, size = self.FontName[self.Font], self.FontSize
	if not fontcache[name] or not fontcache[name][size] then
		if not fontcache[name] then fontcache[name] = {} end
		
		surface.CreateFont("WireGPU_"..name..size, {
			font = name,
			size = size,
			weight = 800,
			antialias = true,
			additive = false,
		})
		fontcache[name][size] = true
	end
	
	surface.SetFont("WireGPU_"..name..size)
end




--------------------------------------------------------------------------------
-- Reset state each GPU frame
--------------------------------------------------------------------------------
function VM:Reset()
  -- Reset VM
  self.IP = 0        -- Instruction pointer

  self.EAX = 0       -- General purpose registers
  self.EBX = 0
  self.ECX = 0
  self.EDX = 0
  self.ESI = 0
  self.EDI = 0
  self.ESP = 32767
  self.EBP = 0

  self.CS = 0        -- Segment pointer registers
  self.SS = 0
  self.DS = 0
  self.ES = 0
  self.GS = 0
  self.FS = 0
  self.KS = 0
  self.LS = 0

  -- Extended registers
  for reg=0,31 do self["R"..reg] = 0 end

  self.ESZ = 32768    -- Stack size register
  self.CMPR = 0       -- Compare register
  self.XEIP = 0       -- Current instruction address register
  self.LADD = 0       -- Last interrupt parameter
  self.LINT = 0       -- Last interrupt number
  self.BPREC = 48     -- Binary precision for integer emulation mode (default: 48)
  self.IPREC = 48     -- Integer precision (48 - floating point mode, 8, 16, 32, 64 - integer mode)
  self.VMODE = 2      -- Vector mode (2D, 3D)
  self.INTR = 0       -- Handling an interrupt
  self.BlockStart = 0 -- Start of the block
  self.BlockSize = 0  -- Size of the block

  -- Reset internal GPU registers
  --  [131072]..[2097151] - Extended GPU memory (2MB GPU)
  --  [131072]..[1048576] - Extended GPU memory (1MB GPU)
  --  [131072]..[524287]  - Extended GPU memory (512K GPU)
  --  [131072]..[262143]  - Extended GPU memory (256K GPU)
  --                        No extended memory  (128K GPU)
  --  [65536]..[131071]   - MemBus mapped memory (read/write)
  --                        No extra memory beyond 65536 (64K GPU)
  --
  -- Hardware control registers:
  --  [65535] - CLK
  --  [65534] - RESET
  --  [65533] - HARDWARE CLEAR
  --  [65532] - Vertex mode (render vertex instead of RT)
  --  [65531] - HALT
  --  [65530] - RAM_RESET
  --  [65529] - Async thread reset
  --  [65528] - Async thread clk
  --  [65527] - Async thread frequency
  --  [65526] - Player index (0 to 31)
  --
  -- Image control:
  --  [65525] - Horizontal image scale
  --  [65524] - Vertical image scale
  --  [65523] - Hardware scale
  --  [65522] - Rotation (0 - 0*, 1 - 90*, 2 - 180*, 3 - 270*)
  --  [65521] - Sprite/texture size
  --  [65520] - Pointer to texture data
  --  [65519] - Size of texture data
  --  [65518] - Raster quality
  --  [65517] - Texture buffer (1: sprite buffer, 0: front buffer)
  --
  -- Vertex pipe controls:
  --  [65515] - Image width (800)
  --  [65514] - Image height (600)
  --  [65513] - Real screen ratio
  --  [65512] - Parameter list address (for dwritefmt)
  --
  -- Cursor control:
  --  [65505] - Cursor X (0..1)
  --  [65504] - Cursor Y (0..1)
  --  [65503] - Cursor visible
  --  [65502] - Cursor buttons (bits)
  --
  -- Brightness control:
  --  [65495] - Brightness W
  --  [65494] - Brightness R
  --  [65493] - Brightness G
  --  [65492] - Brightness B
  --  [65491] - Contrast W
  --  [65490] - Contrast R
  --  [65489] - Contrast G
  --  [65488] - Contrast B
  --
  -- Rendering settings
  --  [65485] - Circle quality (3..128)
  --  [65484] - Offset Point X
  --  [65483] - Offset Point Y
  --  [65482] - Rotation (rad)
  --  [65481] - Scale
  --  [65480] - Center point X
  --  [65479] - Center point Y
  --  [65478] - Circle start (rad)
  --  [65477] - Circle end (rad)
  --  [65476] - Line width (1)
  --  [65475] - Scale X
  --  [65474] - Scale Y
  --  [65473] - Font horizontal align
  --  [65472] - ZOffset
  --  [65471] - Font vertical align
  --  [65470] - Culling distance
  --  [65469] - Culling mode (0: front, 1: back)
  --  [65468] - Single-side lighting (1: front, -1: back)
  --  [65467] - Memory offset of vertex data (non-zero means poly ops take indexes into this array)
  --  [65466] - Texture rotation (rad)
  --  [65465] - Texture scale
  --  [65464] - Texture center point U
  --  [65463] - Texture center point V
  --  [65462] - Texture offset U
  --  [65461] - Texture offset V
  --
  -- Misc:
  --  [64512] - Last register
  --  [63488]..[64511] - External ports

  self.Memory[65535] = 1
  self.Memory[65534] = 0
--self.Memory[65533] = 1   (value persists over reset)
--self.Memory[65532] = 0
--self.Memory[65531] = 0   (value persists over reset)
--self.Memory[65530] = 0
--self.Memory[65529] = 0
--self.Memory[65528] = 0
--self.Memory[65527] = 0
  self.Memory[65526] = (LocalPlayer():UserID() % 32)
  ----------------------
  self.Memory[65525] = 1
  self.Memory[65524] = 1
  self.Memory[65523] = 0
  self.Memory[65522] = 0
  self.Memory[65521] = 512
  self.Memory[65520] = 0
  self.Memory[65519] = 0
  self.Memory[65518] = 0
  self.Memory[65517] = 1
  ----------------------
  self.Memory[65515] = 800
  self.Memory[65514] = 600
--self.Memory[65513] = 0   (set elsewhere)
  self.Memory[65512] = 0
  ----------------------
--self.Memory[65505] = 0   (set elsewhere)
--self.Memory[65504] = 0   (set elsewhere)
  self.Memory[65503] = 0
--self.Memory[65502] = 0
  ----------------------
  self.Memory[65495] = 1
  self.Memory[65494] = 1
  self.Memory[65493] = 1
  self.Memory[65492] = 1
  self.Memory[65491] = 0
  self.Memory[65490] = 0
  self.Memory[65489] = 0
  self.Memory[65488] = 0
  ----------------------
  self.Memory[65485] = 32
  self.Memory[65484] = 0
  self.Memory[65483] = 0
  self.Memory[65482] = 0
  self.Memory[65481] = 1
  self.Memory[65480] = 0
  self.Memory[65479] = 0
  self.Memory[65478] = 0
  self.Memory[65477] = 6.28318530717
  self.Memory[65476] = 1
  self.Memory[65475] = 1
  self.Memory[65474] = 1
  self.Memory[65473] = 0
  self.Memory[65472] = 0
  self.Memory[65471] = 0
  self.Memory[65470] = 0
  self.Memory[65469] = 0
  self.Memory[65468] = 0
  self.Memory[65467] = 0
  self.Memory[65466] = 0
  self.Memory[65465] = 1
  self.Memory[65464] = 0.5
  self.Memory[65463] = 0.5
  self.Memory[65462] = 0
  self.Memory[65461] = 0

  -- Coordinate pipe
  --  0 - direct (0..512 or 0..1024 range)
  --  1 - mapped to screen
  --  2 - mapped to 0..1 range
  --  3 - mapped to -1..1 range
  self.CoordinatePipe = 0

  -- Vertex pipes:
  --  0 - XY mapping
  --  1 - YZ mapping
  --  2 - XZ mapping
  --  3 - XYZ projective mapping
  --  4 - XY mapping + matrix
  --  5 - XYZ projective mapping + matrix
  self.VertexPipe = 0

  -- Flags that can be ddisable/ddenable-d
  -- 0 VERTEX_ZSORT     Enable or disable ZSorting in vertex buffer (sorted on flush)
  self.VertexBufZSort = 0
  -- 1 VERTEX_LIGHTING  Enable or disable vertex lighting
  self.VertexLighting = 0
  -- 2 VERTEX_BUFFER    Enable or disable vertex buffer
  self.VertexBufEnabled = 0
  -- 3 VERTEX_CULLING   Enable or disable culling on faces
  self.VertexCulling = 0
  -- 4 VERTEX_DCULLING  Enable or disable distance culling
  self.DistanceCulling = 0
  -- 5 VERTEX_TEXTURING Enable texturing from sprite buffer
  self.VertexTexturing = 0

  -- Font layouter related
  self.Font = 0
  self.FontSize = 12
  self.TextBox = { x = 512, y = 512, z = 0, w = 0 }
  self.WordWrapMode = 0

  -- Current color
  self.Color = {x = 0, y = 0, z = 0, w = 255}
  self.Material = nil
  self.Texture = 0

  -- Model transform matrix
  self.ModelMatrix = self.ModelMatrix or {}
  self.ModelMatrix[0]  = 1  self.ModelMatrix[1]  = 0  self.ModelMatrix[2]  = 0  self.ModelMatrix[3]  = 0
  self.ModelMatrix[4]  = 0  self.ModelMatrix[5]  = 1  self.ModelMatrix[6]  = 0  self.ModelMatrix[7]  = 0
  self.ModelMatrix[8]  = 0  self.ModelMatrix[9]  = 0  self.ModelMatrix[10] = 1  self.ModelMatrix[11] = 0
  self.ModelMatrix[12] = 0  self.ModelMatrix[13] = 0  self.ModelMatrix[14] = 0  self.ModelMatrix[15] = 1

  --View transform matrix
  self.ProjectionMatrix = self.ProjectionMatrix or {}
  self.ProjectionMatrix[0]  = 1  self.ProjectionMatrix[1]  = 0  self.ProjectionMatrix[2]  = 0  self.ProjectionMatrix[3]  = 0
  self.ProjectionMatrix[4]  = 0  self.ProjectionMatrix[5]  = 1  self.ProjectionMatrix[6]  = 0  self.ProjectionMatrix[7]  = 0
  self.ProjectionMatrix[8]  = 0  self.ProjectionMatrix[9]  = 0  self.ProjectionMatrix[10] = 1  self.ProjectionMatrix[11] = 0
  self.ProjectionMatrix[12] = 0  self.ProjectionMatrix[13] = 0  self.ProjectionMatrix[14] = 0  self.ProjectionMatrix[15] = 1

  -- Reset buffers:
  self.StringCache = {}
  self.VertexBuffer = {}
  self.Lights = {}
end



--------------------------------------------------------------------------------
-- Save asynchronous thread state
--------------------------------------------------------------------------------
local asyncPreservedVariables = {
  "IP","EAX","EBX","ECX","EDX","ESI","EDI","ESP","EBP","CS","SS","DS","ES","GS",
  "FS","KS","LS","ESZ","CMPR","XEIP","LADD","LINT","BPREC","IPREC","VMODE","INTR",
  "BlockStart","BlockSize","CoordinatePipe","VertexPipe","VertexBufZSort","VertexLighting",
  "VertexBufEnabled","VertexCulling","DistanceCulling","VertexTexturing","Font",
  "FontSize","WordWrapMode","Material","Texture","VertexBuffer","Lights",
}
for reg=0,31 do table.insert(asyncPreservedVariables,"R"..reg) end

local asyncPreservedMemory = {
  65525,65524,65523,65522,65521,65520,65519,65518,65517,
  65515,65514,65512,65503,65495,65494,65493,65492,65491,
  65490,65489,65488,65485,65484,65483,65482,65481,65480,
  65479,65478,65477,65476,65475,65474,65473,65472,65471,
  65470,65469,65468,65467,65466,65465,65464,65463,65462,
  65461
}

function VM:SaveAsyncThread_Util()
  for _,var in pairs(asyncPreservedVariables) do self.AsyncState[var] = self[var] end
  for _,mem in pairs(asyncPreservedMemory) do self.AsyncState[mem] = self.Memory[mem] end

  self.AsyncState.TextBox = { x = self.TextBox.x, y = self.TextBox.y, z = self.TextBox.z, w = self.TextBox.w }
  self.AsyncState.Color = { x = self.Color.x, y = self.Color.y, z = self.Color.z, w = self.Color.w }
  self.AsyncState.ModelMatrix = {}
  self.AsyncState.ProjectionMatrix = {}
  for k,v in pairs(self.ModelMatrix) do self.AsyncState.ModelMatrix[k] = v end
  for k,v in pairs(self.ProjectionMatrix) do self.AsyncState.ProjectionMatrix[k] = v end
end

function VM:SaveAsyncThread()
  if not self.AsyncState then
    self.AsyncState = {}
    self:Reset()

    self:SaveAsyncThread_Util()
    self.AsyncState.IP = self.EntryPoint4
    return
  end

  self:SaveAsyncThread_Util()
end



--------------------------------------------------------------------------------
-- Restore asynchronous thread state
--------------------------------------------------------------------------------
function VM:RestoreAsyncThread_Util()
  for _,var in pairs(asyncPreservedVariables) do self[var] = self.AsyncState[var] end
  for _,mem in pairs(asyncPreservedMemory) do self.Memory[mem] = self.AsyncState[mem] end

  self.TextBox = { x = self.AsyncState.TextBox.x, y = self.AsyncState.TextBox.y, z = self.AsyncState.TextBox.z, w = self.AsyncState.TextBox.w }
  self.Color = { x = self.AsyncState.Color.x, y = self.AsyncState.Color.y, z = self.AsyncState.Color.z, w = self.AsyncState.Color.w }
  self.ModelMatrix = {}
  self.ProjectionMatrix = {}
  for k,v in pairs(self.AsyncState.ModelMatrix) do self.ModelMatrix[k] = v end
  for k,v in pairs(self.AsyncState.ProjectionMatrix) do self.ProjectionMatrix[k] = v end
end

function VM:RestoreAsyncThread()
  if not self.AsyncState then
    self.AsyncState = {}
    self:Reset()

    self:SaveAsyncThread_Util()
    self.AsyncState.IP = self.EntryPoint4
  end

  self:RestoreAsyncThread_Util()
end



--------------------------------------------------------------------------------
-- Reset GPU state and clear all persisting registers
--------------------------------------------------------------------------------
function VM:HardReset()
  self:Reset()

  -- Reset registers that usually persist over normal reset
  self.Memory[65533] = 1
  self.Memory[65532] = 0
  self.Memory[65531] = 0
  self.Memory[65535] = 1

  self.Memory[65529] = 0
  self.Memory[65528] = 0
  self.Memory[65527] = 60000

  self.Memory[65502] = 0

  -- Entrypoints to special calls
  --  0  DRAW   Called when screen is being drawn
  --  1  INIT   Called when screen is hard reset
  --  2  USE    Called when screen is used
  --  3  ERROR  Called when GPU error has occured
  --  4  ASYNC  Asynchronous thread entrypoint
  self.EntryPoint0 = 0
  self.EntryPoint1 = self.EntryPoint1 or 0
  self.EntryPoint2 = 0
  self.EntryPoint3 = 0
  self.EntryPoint4 = 0
  self.EntryPoint5 = 0
  self.EntryPoint6 = 0
  self.EntryPoint7 = 0

  -- Is running asynchronous thread
  self.ASYNC = 0

  -- Has initialized already
  self.INIT = 0
  
  -- Reset async thread
  self.AsyncState = nil
end



--------------------------------------------------------------------------------
-- Compute UV
--------------------------------------------------------------------------------
function VM:ComputeTextureUV(vertex,u,v)
  local texturesOnSide = math.floor(512/self.Memory[65521])
  local textureX = (1/texturesOnSide) *           (self.Texture % texturesOnSide)
  local textureY = (1/texturesOnSide) * math.floor(self.Texture / texturesOnSide)

  local uvStep = (1/512)
  local du,dv = u,v

  if (self.Memory[65466] ~= 0) or (self.Memory[65465] ~= 1) then
    local cu,cv = self.Memory[65464],self.Memory[65463]
    local tu,tv = u-cu,v-cv
    local angle,scale = self.Memory[65466],self.Memory[65465]
    du = scale*(tu*math.cos(angle) - tv*math.sin(angle)) + cu + self.Memory[65462]
    dv = scale*(tv*math.cos(angle) + tu*math.sin(angle)) + cv + self.Memory[65461]
  end

  vertex.u = textureX+(1/texturesOnSide)*du*(1-2*uvStep)+uvStep
  vertex.v = textureY+(1/texturesOnSide)*dv*(1-2*uvStep)+uvStep
end



--------------------------------------------------------------------------------
-- Transform coordinates through coordinate pipe
--------------------------------------------------------------------------------
function VM:CoordinateTransform(x,y)
  -- Transformed coordinates
  local tX = x
  local tY = y

  -- Is rotation/scale register set
  if (self.Memory[65482] ~= 0) or (self.Memory[65481] ~= 1) then
    -- Centerpoint of rotation
    local cX = self.Memory[65480]
    local cY = self.Memory[65479]

    -- Calculate normalized direction to rotated point
    local vD = math.sqrt((x-cX)^2+(y-cY)^2) + 1e-7
    local vX = x / vD
    local vY = y / vD

    -- Calculate angle of rotation for the point
    local A
    if self.RAMSize == 65536 then A = math.atan2(vX,vY) -- Old GPU
    else                          A = math.atan2(vY,vX)
    end

    -- Rotate point by a certain angle
    A = A + self.Memory[65482]

    -- Generate new coordinates
    tX = cX + math.cos(A) * vD * self.Memory[65481] * self.Memory[65475]
    tY = cY + math.sin(A) * vD * self.Memory[65481] * self.Memory[65474]
  end

  -- Apply DMOVE offset
  tX = tX + self.Memory[65484]
  tY = tY + self.Memory[65483]

  if     self.CoordinatePipe == 0 then
    tX = self.ScreenWidth*(tX/512)
    tY = self.ScreenHeight*(tY/512)
  elseif self.CoordinatePipe == 1 then
    tX = self.ScreenWidth*tX/self.Memory[65515]
    tY = self.ScreenHeight*tY/self.Memory[65514]
  elseif self.CoordinatePipe == 2 then
    tX = tX*self.ScreenWidth
    tY = tY*self.ScreenHeight
  elseif self.CoordinatePipe == 3 then
    tX = 0.5*self.ScreenWidth*(1+tX)
    tY = 0.5*self.ScreenHeight*(1+tY)
  elseif self.CoordinatePipe == 4 then
    tX = 0.5*self.ScreenWidth+tX
    tY = 0.5*self.ScreenHeight+tY
  end

  -- Apply raster quality transform
  local transformedCoordinate = { x = tX, y = tY}
  local rasterQuality = self.Memory[65518]

  if rasterQuality > 0 then
    local W,H = self.ScreenWidth/2,self.ScreenHeight/2
    transformedCoordinate.x = (tX-W)*(1-(rasterQuality/W))+W
    transformedCoordinate.y = (tY-H)*(1-(rasterQuality/H))+H
  end

  return transformedCoordinate
end




--------------------------------------------------------------------------------
-- Transform coordinate via vertex pipe
--------------------------------------------------------------------------------
function VM:VertexTransform(inVertex,toScreen)
  -- Make sure the coordinate is complete
  local vertex = inVertex or {}
  vertex.x = vertex.x or 0
  vertex.y = vertex.y or 0
  vertex.z = vertex.z or 0
  vertex.w = vertex.w or 1
  vertex.u = vertex.u or 0
  vertex.v = vertex.v or 0

  -- Create the resulting coordinate
  local resultVertex = {
    x = vertex.x,
    y = vertex.y,
    z = vertex.z,
    w = vertex.w,
    u = vertex.u,
    v = vertex.v }

  -- Transformed world coordinates
  local worldVertex = {
    x = 0,
    y = 0,
    z = 0,
    w = 1,
    u = vertex.u,
    v = vertex.v }

  -- Add Z offset to input coordinate
  vertex.z = vertex.z + self.Memory[65472]

  -- Do the transformation
      if self.VertexPipe == 0 then -- XY plane
    local resultCoordinate = self:CoordinateTransform(vertex.x,vertex.y)
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
  elseif self.VertexPipe == 1 then -- YZ plane
    local resultCoordinate = self:CoordinateTransform(vertex.y,vertex.z)
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
  elseif self.VertexPipe == 2 then -- XZ plane
    local resultCoordinate = self:CoordinateTransform(vertex.x,vertex.z)
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
  elseif self.VertexPipe == 3 then -- Perspective transform
    local tX = (vertex.x + self.Memory[65512])/(vertex.z + self.Memory[65512])
    local tY = (vertex.y + self.Memory[65512])/(vertex.z + self.Memory[65512])

    local resultCoordinate = self:CoordinateTransform(tX,tY)
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
  elseif self.VertexPipe == 4 then -- 2D matrix
    local tX = self.ModelMatrix[0*4+0] * vertex.x +
               self.ModelMatrix[0*4+1] * vertex.y +
               self.ModelMatrix[0*4+2] * 0 +
               self.ModelMatrix[0*4+3] * 1

    local tY = self.ModelMatrix[1*4+0] * vertex.x +
               self.ModelMatrix[1*4+1] * vertex.y +
               self.ModelMatrix[1*4+2] * 0 +
               self.ModelMatrix[1*4+3] * 1

    local resultCoordinate = self:CoordinateTransform(tX,tY)
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
  elseif self.VertexPipe == 5 then -- 3D matrix
    local world
    if not toScreen then
      -- Transform into world coordinates
      world = {}

      for i=0,3 do
        world[i] = self.ModelMatrix[i*4+0] * vertex.x +
                   self.ModelMatrix[i*4+1] * vertex.y +
                   self.ModelMatrix[i*4+2] * vertex.z +
                   self.ModelMatrix[i*4+3] * vertex.w
      end

      worldVertex.x = world[0]
      worldVertex.y = world[1]
      worldVertex.z = world[2]
      worldVertex.w = world[3]
    else
      worldVertex = vertex
      world = {}
      world[0] = vertex.x
      world[1] = vertex.y
      world[2] = vertex.z
      world[3] = vertex.w
    end

    -- Transform into screen coordinates
    local screen = {}

    for i=0,3 do
      screen[i] = self.ProjectionMatrix[i*4+0] * world[0] +
                  self.ProjectionMatrix[i*4+1] * world[1] +
                  self.ProjectionMatrix[i*4+2] * world[2] +
                  self.ProjectionMatrix[i*4+3] * world[3]
    end

    -- Project to screen
    if screen[3] == 0 then screen[3] = 1 end
    for i=0,3 do screen[i] = screen[i] / screen[3] end

    -- Transform coordinates
    local resultCoordinate = self:CoordinateTransform(screen[0],screen[1])
    resultVertex.x = resultCoordinate.x
    resultVertex.y = resultCoordinate.y
    resultVertex.z = screen[2]
    resultVertex.w = screen[3]
  end

  return resultVertex,worldVertex
end




--------------------------------------------------------------------------------
-- Transform color
--------------------------------------------------------------------------------
function VM:ColorTransform(color)
  color.x = color.x * self.Memory[65495] * self.Memory[65494]
  color.y = color.y * self.Memory[65495] * self.Memory[65493]
  color.z = color.z * self.Memory[65495] * self.Memory[65492]
  return color
end




--------------------------------------------------------------------------------
-- Read a string by offset
--------------------------------------------------------------------------------
function VM:ReadString(address)
  local charString = ""
  local charCount = 0
  local currentChar = 255

  while currentChar ~= 0 do
    currentChar = self:ReadCell(address + charCount)
    -- Reading failed
    if not currentChar then
    	return
    elseif currentChar > 0 and currentChar < 255 then
      charString = charString .. string.char(currentChar)
    elseif currentChar ~= 0 then
        self:Interrupt(23,currentChar)
        return ""
    end

    charCount = charCount + 1
    if charCount > 8192 then
      self:Interrupt(23,0)
      return ""
    end
  end
  return charString
end




--------------------------------------------------------------------------------
-- Get text size (by sk89q)
--------------------------------------------------------------------------------
function VM:TextSize(text)
  self:SetFont()

  if self.WordWrapMode == 1 then
    return self.Layouter:GetTextSize(text, self.TextBox.x, self.TextBox.y)
  else
    return surface.GetTextSize(text)
  end
end




--------------------------------------------------------------------------------
-- Output font to screen (word wrap update by sk89q)
--------------------------------------------------------------------------------
function VM:FontWrite(posaddr,text)
  -- Read position
  local vertex = {}
  vertex.x = self:ReadCell(posaddr+0)
  vertex.y = self:ReadCell(posaddr+1)
  vertex = self:VertexTransform(vertex)

  self:SetFont()

  -- Draw text
  if self.RenderEnable == 1 then
    if self.WordWrapMode == 1 then
      surface.SetTextColor(self.Color.x,self.Color.y,self.Color.z,self.Color.w)
      self.Layouter:DrawText(tostring(text), vertex.x, vertex.y, self.TextBox.x,
                       self.TextBox.y, self.Memory[65473], self.Memory[65471])
    else
      draw.DrawText(text,"WireGPU_"..self.FontName[self.Font]..self.FontSize,
              vertex.x,vertex.y,Color(self.Color.x,self.Color.y,self.Color.z,self.Color.w),
              self.Memory[65473])
    end
  end
end




--------------------------------------------------------------------------------
-- Draw line between two points
--------------------------------------------------------------------------------
function VM:DrawLine(point1,point2,drawNow)
  -- Line centerpoint
  local cX = (point1.x + point2.x) / 2
  local cY = (point1.y + point2.y) / 2

  -- Line width
  local W = self.Memory[65476]

  -- Line length and angle
  local L = math.sqrt((point1.x-point2.x)^2+(point1.y-point2.y)^2) + 1e-7
  local dX = (point2.x-point1.x) / L
  local dY = (point2.y-point1.y) / L
  local A = math.atan2(dY,dX)
  local dA = math.atan2(W,L/2)

  -- Generate vertexes
  local vertexBuffer = { {}, {}, {}, {} }

  vertexBuffer[1].x = cX - 0.5 * L * math.cos(A-dA)
  vertexBuffer[1].y = cY - 0.5 * L * math.sin(A-dA)
  vertexBuffer[1].u = 0
  vertexBuffer[1].v = 0

  vertexBuffer[2].x = cX + 0.5 * L * math.cos(A+dA)
  vertexBuffer[2].y = cY + 0.5 * L * math.sin(A+dA)
  vertexBuffer[2].u = 1
  vertexBuffer[2].v = 1

  vertexBuffer[3].x = cX + 0.5 * L * math.cos(A-dA)
  vertexBuffer[3].y = cY + 0.5 * L * math.sin(A-dA)
  vertexBuffer[3].u = 0
  vertexBuffer[3].v = 1

  vertexBuffer[4].x = cX - 0.5 * L * math.cos(A+dA)
  vertexBuffer[4].y = cY - 0.5 * L * math.sin(A+dA)
  vertexBuffer[4].u = 1
  vertexBuffer[4].v = 0

  -- Draw vertexes
  if drawNow then
    surface.DrawPoly(vertexBuffer)
  else
    self:DrawToBuffer(vertexBuffer)
  end
end




--------------------------------------------------------------------------------
-- Flush vertex buffer. Based on code by Nick
--------------------------------------------------------------------------------
local function triangleSortFunction(triA,triB)
  local z1 = (triA.vertex[1].z + triA.vertex[2].z + triA.vertex[3].z) / 3
  local z2 = (triB.vertex[1].z + triB.vertex[2].z + triB.vertex[3].z) / 3

  return z1 < z2
end

function VM:FlushBuffer()
  -- Projected vertex data:
  --   vertexData.transformedVertex [SCREEN SPACE]
  -- Vertex data in world space:
  --   vertexData.vertex [WORLD SPACE]
  -- Triangle color:
  --   vertexData.color
  --
  -- Light positions: [WORLD SPACE]

  if self.VertexBufEnabled == 1 then
    -- Do not flush color-only buffer
    if (#self.VertexBuffer == 1) and (not self.VertexBuffer[1].vertex) then
      self.VertexBuffer = {}
      return
    end

    -- Sort triangles by distance
    if self.VertexBufZSort == 1 then
      table.sort(self.VertexBuffer,triangleSortFunction)
    end

    -- Render each triangle
    for vertexID,vertexData in ipairs(self.VertexBuffer) do
      -- Should this polygon be culled
      local cullVertex = false

      -- Generate output
      local resultTriangle
      local resultTriangle2
      local resultColor = {
        x = vertexData.color.x,
        y = vertexData.color.y,
        z = vertexData.color.z,
        w = vertexData.color.w,
      }
      local resultMaterial = vertexData.material
      if vertexData.rt then
        WireGPU_matBuffer:SetTexture("$basetexture", vertexData.rt)
        resultMaterial = WireGPU_matBuffer
      end


      if vertexData.vertex then
        resultTriangle  = {}

        resultTriangle[1] = {}
        resultTriangle[1].x = vertexData.transformedVertex[1].x
        resultTriangle[1].y = vertexData.transformedVertex[1].y
        resultTriangle[1].u = vertexData.transformedVertex[1].u
        resultTriangle[1].v = vertexData.transformedVertex[1].v

        resultTriangle[2] = {}
        resultTriangle[2].x = vertexData.transformedVertex[2].x
        resultTriangle[2].y = vertexData.transformedVertex[2].y
        resultTriangle[2].u = vertexData.transformedVertex[2].u
        resultTriangle[2].v = vertexData.transformedVertex[2].v

        resultTriangle[3] = {}
        resultTriangle[3].x = vertexData.transformedVertex[3].x
        resultTriangle[3].y = vertexData.transformedVertex[3].y
        resultTriangle[3].u = vertexData.transformedVertex[3].u
        resultTriangle[3].v = vertexData.transformedVertex[3].v

        -- Additional processing
        if (self.VertexCulling == 1) or (self.VertexLighting == 1) then
          -- Get vertices (world space)
          local v1 = vertexData.vertex[1]
          local v2 = vertexData.vertex[2]
          local v3 = vertexData.vertex[3]

          -- Compute barycenter (world space)
          local vpos = {
            x = (v1.x+v2.x) * 1/3,
            y = (v1.y+v2.y) * 1/3,
            z = (v1.z+v2.z) * 1/3
          }

          -- Compute normal (world space)
          local x1 = v2.x - v1.x
          local y1 = v2.y - v1.y
          local z1 = v2.z - v1.z

          local x2 = v3.x - v1.x
          local y2 = v3.y - v1.y
          local z2 = v3.z - v1.z

          local normal = {
            x = y1*z2-y2*z1,
            y = z1*x2-z2*x1,
            z = x1*y2-x2*y1
          }

          -- Normalize it
          local d = (normal.x^2 + normal.y^2 + normal.z^2)^(1/2)+1e-7
          normal.x = normal.x / d
          normal.y = normal.y / d
          normal.z = normal.z / d

          -- Perform culling
          if self.VertexCulling == 1 then
            if self.Memory[65469] == 0 then
              cullVertex = (normal.x*v1.x + normal.y*v1.y + normal.z*v1.z) <= 0
            else
              cullVertex = (normal.x*v1.x + normal.y*v1.y + normal.z*v1.z) >= 0
            end
          end

          -- Perform vertex lighting
          if (self.VertexLighting == 1) and (not cullVertex) then
            -- Extra color generated by lights
            local lightColor = { x = 0, y = 0, z = 0, w = 255}

            -- Apply all lights (world space calculations)
            for i=0,7 do
              if self.Lights[i] then
                local lightPosition = {
                  x = self.Lights[i].Position.x,
                  y = self.Lights[i].Position.y,
                  z = self.Lights[i].Position.z
                }
                local lightLength = (lightPosition.x^2+lightPosition.y^2+lightPosition.z^2)^(1/2)+1e-7
                lightPosition.x = lightPosition.x / lightLength
                lightPosition.y = lightPosition.y / lightLength
                lightPosition.z = lightPosition.z / lightLength

                local lightDot
                if self.Memory[65468] == 0 then
                  lightDot = math.abs(lightPosition.x*normal.x +
                                      lightPosition.y*normal.y +
                                      lightPosition.z*normal.z)*self.Lights[i].Color.w
                else
                  lightDot = math.max(0,self.Memory[65468]*(lightPosition.x*normal.x +
                                      lightPosition.y*normal.y +
                                      lightPosition.z*normal.z))*self.Lights[i].Color.w

                end

                lightColor.x = math.min(lightColor.x + self.Lights[i].Color.x * lightDot,255)
                lightColor.y = math.min(lightColor.y + self.Lights[i].Color.y * lightDot,255)
                lightColor.z = math.min(lightColor.z + self.Lights[i].Color.z * lightDot,255)
              end
            end

            -- Modulate object color with light color
            resultColor.x = (1/255) * resultColor.x * lightColor.x
            resultColor.y = (1/255) * resultColor.y * lightColor.y
            resultColor.z = (1/255) * resultColor.z * lightColor.z
          end

          -- Perform distance culling
          if (self.DistanceCulling == 1) and (not cullVertex) then
            local Infront = {}
            local Behind = {}

            local frontCullDistance = self.Memory[65470]
            local K = -frontCullDistance

            -- Generate list of vertices which go behind the camera
            if v1.z - K >= 0
            then Behind [#Behind  + 1] = v1
            else Infront[#Infront + 1] = v1
            end

            if v2.z - K >= 0
            then Behind [#Behind  + 1] = v2
            else Infront[#Infront + 1] = v2
            end

            if v3.z - K >= 0
            then Behind [#Behind  + 1] = v3
            else Infront[#Infront + 1] = v3
            end

            if #Behind == 1 then
              local Point1 = Infront[1]
              local Point2 = Infront[2]
              local Point3 = Behind[1]
              local Point4 = {}

              local D1 = {
                x = Point3.x - Point1.x,
                y = Point3.y - Point1.y,
                z = Point3.z - Point1.z,
              }
              local D2 = {
                x = Point3.x - Point2.x,
                y = Point3.y - Point2.y,
                z = Point3.z - Point2.z,
              }

              local T1 = D1.z
              local T2 = D2.z

              if (T1 ~= 0) and (T2 ~= 0) then
                local S1 = (K - Point1.z)/T1
                local S2 = (K - Point2.z)/T2

                -- Calculate the new UV values
                Point4.u = Point2.u + S2 * (Point3.u - Point2.u)
                Point4.v = Point2.v + S2 * (Point3.v - Point2.v)

                Point3.u = Point1.u + S1 * (Point3.u - Point1.u)
                Point3.v = Point1.v + S1 * (Point3.v - Point1.v)

                -- Calculate new coordinates
                Point3.x = Point1.x + S1 * D1.x
                Point3.y = Point1.y + S1 * D1.y
                Point3.z = Point1.z + S1 * D1.z

                Point4.x = Point2.x + S2 * D2.x
                Point4.y = Point2.y + S2 * D2.y
                Point4.z = Point2.z + S2 * D2.z

                -- Transform the points (from world space to screen space)
                local P1t = self:VertexTransform(Point1,true)
                local P2t = self:VertexTransform(Point2,true)
                local P3t = self:VertexTransform(Point3,true)
                local P4t = self:VertexTransform(Point4,true)

                resultTriangle[1] = P1t
                resultTriangle[2] = P2t
                resultTriangle[3] = P3t

                resultTriangle2 = {}
                resultTriangle2[1] = P2t
                resultTriangle2[2] = P3t
                resultTriangle2[3] = P4t
              end
            elseif #Behind == 2 then
              local Point1 = Infront[1]
              local Point2 = Behind[1]
              local Point3 = Behind[2]

              local D1 = {
                x = Point2.x - Point1.x,
                y = Point2.y - Point1.y,
                z = Point2.z - Point1.z,
              }
              local D2 = {
                x = Point3.x - Point1.x,
                y = Point3.y - Point1.y,
                z = Point3.z - Point1.z,
              }

              local T1 = D1.z
              local T2 = D2.z

              if (T1 ~= 0) and (T2 ~= 0) then
                local S1 = (K - Point1.z)/T1
                local S2 = (K - Point1.z)/T2

                --Calculate the new UV values
                Point2.u = Point1.u + S1 * (Point2.u - Point1.u)
                Point2.v = Point1.v + S1 * (Point2.v - Point1.v)

                Point3.u = Point1.u + S2 * (Point3.u - Point1.u)
                Point3.v = Point1.v + S2 * (Point3.v - Point1.v)

                -- Calculate new coordinates
                Point2.x = Point1.x + S1 * D1.x
                Point2.y = Point1.y + S1 * D1.y
                Point2.z = Point1.z + S1 * D1.z

                Point3.x = Point1.x + S2 * D2.x
                Point3.y = Point1.y + S2 * D2.y
                Point3.z = Point1.z + S2 * D2.z

                -- Transform the points (from world space to screen space)
                local P1t = self:VertexTransform(Point1,true)
                local P2t = self:VertexTransform(Point2,true)
                local P3t = self:VertexTransform(Point3,true)

                resultTriangle[1] = P1t
                resultTriangle[2] = P2t
                resultTriangle[3] = P3t
              end
            elseif #Behind == 3 then
              cullVertex = true
            end
          end
        end -- End additional processing
      end


      if not cullVertex then
        -- self:FixDrawDirection(DrawInfo)
        if self.RenderEnable == 1 then
          if resultMaterial then
            surface.SetMaterial(resultMaterial)
            resultTriangle = {
              [1] = resultTriangle[3],
              [2] = resultTriangle[2],
              [3] = resultTriangle[1],
            }
          else
            surface.SetTexture(0)
          end
          surface.SetDrawColor(resultColor.x,resultColor.y,resultColor.z,resultColor.w)
          if vertexData.wireframe then
            if resultTriangle  then
              for i=1,#resultTriangle do
                local point1 = resultTriangle[i]
                local point2 = resultTriangle[i+1]
                if not point2 then point2 = resultTriangle[1] end
                self:DrawLine(point1,point2,true)
              end
            end

            if resultTriangle2  then
              for i=1,#resultTriangle2 do
                local point1 = resultTriangle2[i]
                local point2 = resultTriangle2[i+1]
                if not point2 then point2 = resultTriangle2[1] end
                self:DrawLine(point1,point2,true)
              end
            end
          else
            if resultTriangle  then surface.DrawPoly(resultTriangle)  end
            if resultTriangle2 then surface.DrawPoly(resultTriangle2) end
          end
        end
      end
    end

    self.VertexBuffer = {}
  end
end




--------------------------------------------------------------------------------
-- Set current color
--------------------------------------------------------------------------------
function VM:SetColor(color)
  if self.VertexBufEnabled == 1 then
    if #self.VertexBuffer > 0 then
      self.VertexBuffer[#self.VertexBuffer].color = self:ColorTransform(color)
    else
      self.VertexBuffer[1] = {
        color = self:ColorTransform(color),
      }
    end
  end

  self.Color = self:ColorTransform(color)
end




--------------------------------------------------------------------------------
-- Set current material
--------------------------------------------------------------------------------
function VM:SetMaterial(material)
  if self.VertexBufEnabled == 1 then
    if #self.VertexBuffer > 0 then
      self.VertexBuffer[#self.VertexBuffer].material = material
    else
      self.VertexBuffer[1] = {
        material = material,
      }
    end
  end

  self.Material = material
end



--------------------------------------------------------------------------------
-- Bind rendering state (color, texture)
--------------------------------------------------------------------------------
function VM:BindState()
  surface.SetDrawColor(self.Color.x,self.Color.y,self.Color.z,self.Color.w)
  if self.VertexTexturing == 1 then
    if self.Memory[65517] == 1 then
      --[@entities\gmod_wire_gpu\cl_gpuvm.lua:1276] bad argument #2 to 'SetTexture' (ITexture expected, got nil)
      self.Entity:AssertSpriteBufferExists()
      if self.Entity.SpriteGPU.RT then
        WireGPU_matBuffer:SetTexture("$basetexture", self.Entity.SpriteGPU.RT)
      end
    else
      if self.Entity.GPU.RT then
        WireGPU_matBuffer:SetTexture("$basetexture", self.Entity.GPU.RT)
      end
    end
    surface.SetMaterial(WireGPU_matBuffer)
  else
    if self.Material then
      surface.SetMaterial(self.Material)
    else
      surface.SetTexture(0)
    end
  end
end



--------------------------------------------------------------------------------
-- Draw a buffer (or add it to vertex buffer)
--------------------------------------------------------------------------------
function VM:DrawToBuffer(vertexData,isWireframe)
  if self.VertexBufEnabled == 1 then
    -- Add new entry
    if (not self.VertexBuffer[#self.VertexBuffer]) or self.VertexBuffer[#self.VertexBuffer].vertex then
      self.VertexBuffer[#self.VertexBuffer+1] = {
        color = self.Color,
        material = self.Material,
        vertex = {},
        transformedVertex = {},
        wireframe = isWireframe,
      }
    else
      self.VertexBuffer[#self.VertexBuffer].vertex = {}
      self.VertexBuffer[#self.VertexBuffer].transformedVertex = {}
      self.VertexBuffer[#self.VertexBuffer].wireframe = isWireframe
    end

    -- Add RT material if required
    if self.VertexTexturing == 1 then
      if self.Memory[65517] == 1 then
        self.Entity:AssertSpriteBufferExists()
        self.VertexBuffer[#self.VertexBuffer].rt = self.Entity.SpriteGPU.RT
      else
        self.VertexBuffer[#self.VertexBuffer].rt = self.Entity.GPU.RT
      end
    end


    -- Add all vertices
    for _,vertex in ipairs(vertexData) do
      local screenVertex,worldVertex = self:VertexTransform(vertex)
      table.insert(self.VertexBuffer[#self.VertexBuffer].vertex,worldVertex)
      table.insert(self.VertexBuffer[#self.VertexBuffer].transformedVertex,screenVertex)
    end
  else
    local resultPoly = {}

    -- Transform vertices
    for _,vertex in ipairs(vertexData) do
      local screenVertex,worldVertex = self:VertexTransform(vertex)
      table.insert(resultPoly,screenVertex)
    end

    -- Draw
    if self.RenderEnable == 1 then
      self:BindState()
      if isWireframe then
        for i=1,#resultPoly do
          local point1 = resultPoly[i]
          local point2 = resultPoly[i+1]
          if not point2 then point2 = resultPoly[1] end
          self:DrawLine(point1,point2,true)
        end
      else
        surface.DrawPoly(resultPoly)
      end
    end
  end
end









--------------------------------------------------------------------------------
-- GPU instruction set implementation
--------------------------------------------------------------------------------
VM.OpcodeTable = {}
VM.OpcodeTable[98] = function(self)  --TIMER
  self:Dyn_Emit("if VM.ASYNC == 1 then")
    self:Dyn_EmitOperand(1,"(VM.TIMER+"..(self.PrecompileInstruction or 0).."*VM.TimerDT)",true)
  self:Dyn_Emit("else")
    self:Dyn_EmitOperand(1,"VM.TIMER",true)
  self:Dyn_Emit("end")
end
VM.OpcodeTable[111] = function(self)  --IDLE
  self:Dyn_Emit("VM.INTR = 1")
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
--------------------------------------------------------------------------------
VM.OpcodeTable[200] = function(self)  --DRECT_TEST
  self:Dyn_Emit("if VM.RenderEnable == 1 then")
    self:Dyn_Emit("$L W = VM.ScreenWidth")
    self:Dyn_Emit("$L H = VM.ScreenHeight")

    self:Dyn_Emit("surface.SetTexture(0)")
    self:Dyn_Emit("surface.SetDrawColor(200,200,200,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*0,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(200,200,000,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*1,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(000,200,200,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*2,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(000,200,000,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*3,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(200,000,200,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*4,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(200,000,000,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*5,0,W*0.125,H*0.80)")
    self:Dyn_Emit("surface.SetDrawColor(000,000,200,255)")
    self:Dyn_Emit("surface.DrawRect(W*0.125*6,0,W*0.125,H*0.80)")

    self:Dyn_Emit("for gray=0,7 do")
      self:Dyn_Emit("surface.SetDrawColor(31*gray,31*gray,31*gray,255)")
      self:Dyn_Emit("surface.DrawRect(W*0.125*gray,H*0.80,W*0.125,H*0.20)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[201] = function(self)  --DEXIT
  self:Dyn_Emit("VM.INTR = 1")
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
VM.OpcodeTable[202] = function(self)  --DCLR
  self:Dyn_Emit("if VM.RenderEnable == 1 then")
    self:Dyn_Emit("surface.SetTexture(0)")
    self:Dyn_Emit("surface.SetDrawColor(0,0,0,255)")
    self:Dyn_Emit("surface.DrawRect(0,0,VM.ScreenWidth,VM.ScreenHeight)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[203] = function(self)  --DCLRTEX
  self:Dyn_Emit("if VM.RenderEnable == 1 then")
    self:Dyn_Emit("VM:BindState()")
    self:Dyn_Emit("surface.SetDrawColor(255,255,255,255)")
    self:Dyn_Emit("surface.DrawTexturedRect(0,0,VM.ScreenWidth,VM.ScreenHeight)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[204] = function(self)  --DVXFLUSH
  self:Dyn_Emit("VM:FlushBuffer()")
end
VM.OpcodeTable[205] = function(self)  --DVXCLEAR
  self:Dyn_Emit("VM.VertexBuffer = {}")
end
VM.OpcodeTable[206] = function(self)  --DSETBUF_VX
  self:Dyn_Emit("VM.Entity:SetRendertarget()")
  self:Dyn_Emit("VM.LastBuffer = 2")
end
VM.OpcodeTable[207] = function(self)  --DSETBUF_SPR
  self:Dyn_Emit("VM.Entity:SetRendertarget(1)")
  self:Dyn_Emit("VM.LastBuffer = 1")
end
VM.OpcodeTable[208] = function(self)  --DSETBUF_FBO
  self:Dyn_Emit("VM.Entity:SetRendertarget(0)")
  self:Dyn_Emit("VM.LastBuffer = 0")
end
VM.OpcodeTable[209] = function(self)  --DSWAP
  self:Dyn_Emit("if VM.RenderEnable == 1 then")
    self:Dyn_Emit("VM.Entity:AssertSpriteBufferExists()")
    self:Dyn_Emit("if VM.Entity.SpriteGPU.RT and VM.Entity.GPU.RT then")
      self:Dyn_Emit("render.CopyTexture(VM.Entity.SpriteGPU.RT,VM.Entity.GPU.RT)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[210] = function(self)  --DVXPIPE
  self:Dyn_Emit("VM.VertexPipe = $1")
end
VM.OpcodeTable[211] = function(self)  --DCVXPIPE
  self:Dyn_Emit("VM.CoordinatePipe = $1")
end
VM.OpcodeTable[212] = function(self)  --DENABLE
  self:Dyn_Emit("$L IDX = $1")
  self:Dyn_Emit("if IDX == 0 then VM.VertexBufEnabled = 1 end")
  self:Dyn_Emit("if IDX == 1 then VM.VertexBufZSort   = 1 end")
  self:Dyn_Emit("if IDX == 2 then VM.VertexLighting   = 1 end")
  self:Dyn_Emit("if IDX == 3 then VM.VertexCulling    = 1 end")
  self:Dyn_Emit("if IDX == 4 then VM.DistanceCulling  = 1 end")
  self:Dyn_Emit("if IDX == 5 then VM.VertexTexturing  = 1 end")
end
VM.OpcodeTable[213] = function(self)  --DDISABLE
  self:Dyn_Emit("$L IDX = $1")
  self:Dyn_Emit("if IDX == 0 then VM.VertexBufEnabled = 0 end")
  self:Dyn_Emit("if IDX == 1 then VM.VertexBufZSort   = 0 end")
  self:Dyn_Emit("if IDX == 2 then VM.VertexLighting   = 0 end")
  self:Dyn_Emit("if IDX == 3 then VM.VertexCulling    = 0 end")
  self:Dyn_Emit("if IDX == 4 then VM.DistanceCulling  = 0 end")
  self:Dyn_Emit("if IDX == 5 then VM.VertexTexturing  = 0 end")
end
VM.OpcodeTable[214] = function(self)  --DCLRSCR
  self:Dyn_Emit("if VM.RenderEnable == 1 then")
    self:Dyn_Emit("VM:SetColor(VM:ReadVector4f($1))")
    self:Dyn_Emit("VM:BindState()")
    self:Dyn_Emit("surface.SetTexture(0)")
    self:Dyn_Emit("surface.DrawRect(0,0,VM.ScreenWidth,VM.ScreenHeight)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[215] = function(self)  --DCOLOR
  self:Dyn_Emit("VM:SetColor(VM:ReadVector4f($1))")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[216] = function(self)  --DTEXTURE
  self:Dyn_Emit("VM.Texture = $1")
end
VM.OpcodeTable[217] = function(self)  --DSETFONT
  self:Dyn_Emit("VM.Font = math.Clamp(math.floor($1),0,7)")
  end
VM.OpcodeTable[218] = function(self)  --DSETSIZE
  self:Dyn_Emit("VM.FontSize = math.floor(math.max(4,math.min($1,200)))")
end
VM.OpcodeTable[219] = function(self)  --DMOVE
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("if ADDR == 0 then")
    self:Dyn_Emit("VM:WriteCell(65484,0)")
    self:Dyn_Emit("VM:WriteCell(65483,0)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("else")
    self:Dyn_Emit("VM:WriteCell(65484,VM:ReadCell(ADDR+0))")
    self:Dyn_Emit("VM:WriteCell(65483,VM:ReadCell(ADDR+1))")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[220] = function(self)  --DVXDATA_2F
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L VDATA = VM:ReadCell(65467)")
  self:Dyn_Emit("for IDX=1,math.min(128,$2) do")
    self:Dyn_Emit("if VDATA > 0 then")
      self:Dyn_Emit("$L VIDX = VM:ReadCell(ADDR+IDX-1)")
      self:Dyn_Emit("VD[IDX] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX*2+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX*2+1),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VD[IDX] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*2+0),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*2+1),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("end")

    self:Dyn_Emit("VM:ComputeTextureUV(VD[IDX],VD[IDX].x/512,VD[IDX].y/512)")
  self:Dyn_Emit("end")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawToBuffer(VD)")
end
VM.OpcodeTable[221] = function(self)  --DVXDATA_2F_TEX
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L VDATA = VM:ReadCell(65467)")
  self:Dyn_Emit("for IDX=1,math.min(128,$2) do")
    self:Dyn_Emit("if VDATA > 0 then")
      self:Dyn_Emit("$L VIDX = VM:ReadCell(ADDR+IDX-1)")
      self:Dyn_Emit("VD[IDX] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX*4+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX*4+1),")
      self:Dyn_Emit("}")

      self:Dyn_Emit("VM:ComputeTextureUV(VD[IDX],VM:ReadCell(VDATA+VIDX*4+2),VM:ReadCell(VDATA+VIDX*4+3))")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VD[IDX] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*4+0),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*4+1),")
      self:Dyn_Emit("}")

      self:Dyn_Emit("VM:ComputeTextureUV(VD[IDX],VM:ReadCell(ADDR+(IDX-1)*4+2),VM:ReadCell(ADDR+(IDX-1)*4+3))")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawToBuffer(VD)")
end
VM.OpcodeTable[222] = function(self)  --DVXDATA_3F
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L VDATA = VM:ReadCell(65467)")
  self:Dyn_Emit("for IDX=1,math.min(128,$2) do")
    self:Dyn_Emit("if VDATA > 0 then")
      self:Dyn_Emit("$L VIDX1 = VM:ReadCell(ADDR+(IDX-1)*3+0)")
      self:Dyn_Emit("$L VIDX2 = VM:ReadCell(ADDR+(IDX-1)*3+1)")
      self:Dyn_Emit("$L VIDX3 = VM:ReadCell(ADDR+(IDX-1)*3+2)")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX1*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX1*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX1*3+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX2*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX2*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX2*3+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX3*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX3*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX3*3+2),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+0),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+1),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+3),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+4),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+5),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+6),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+7),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+8),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("end")

    self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
    self:Dyn_Emit("VM:ComputeTextureUV(VD[2],1,0)")
    self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")

    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:DrawToBuffer(VD)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[223] = function(self)  --DVXDATA_3F_TEX
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L VDATA = VM:ReadCell(65467)")
  self:Dyn_Emit("for IDX=1,math.min(128,$2) do")
    self:Dyn_Emit("if VDATA > 0 then")
      self:Dyn_Emit("$L VIDX1 = VM:ReadCell(ADDR+(IDX-1)*3+0)")
      self:Dyn_Emit("$L VIDX2 = VM:ReadCell(ADDR+(IDX-1)*3+1)")
      self:Dyn_Emit("$L VIDX3 = VM:ReadCell(ADDR+(IDX-1)*3+2)")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX1*5+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX1*5+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX1*5+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX2*5+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX2*5+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX2*5+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX3*5+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX3*5+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX3*5+2),")
      self:Dyn_Emit("}")

      self:Dyn_Emit("VM:ComputeTextureUV(VD[1],VM:ReadCell(VDATA+VIDX1*5+3),VM:ReadCell(VDATA+VIDX1*5+4))")
      self:Dyn_Emit("VM:ComputeTextureUV(VD[2],VM:ReadCell(VDATA+VIDX2*5+3),VM:ReadCell(VDATA+VIDX2*5+4))")
      self:Dyn_Emit("VM:ComputeTextureUV(VD[3],VM:ReadCell(VDATA+VIDX3*5+3),VM:ReadCell(VDATA+VIDX3*5+4))")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*15+0),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*15+1),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*15+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*15+5),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*15+6),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*15+7),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*15+10),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*15+11),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*15+12),")
      self:Dyn_Emit("}")

      self:Dyn_Emit("VM:ComputeTextureUV(VD[1],VM:ReadCell(ADDR+(IDX-1)*15+ 3),VM:ReadCell(ADDR+(IDX-1)*15+ 4))")
      self:Dyn_Emit("VM:ComputeTextureUV(VD[2],VM:ReadCell(ADDR+(IDX-1)*15+ 8),VM:ReadCell(ADDR+(IDX-1)*15+ 9))")
      self:Dyn_Emit("VM:ComputeTextureUV(VD[3],VM:ReadCell(ADDR+(IDX-1)*15+13),VM:ReadCell(ADDR+(IDX-1)*15+14))")
    self:Dyn_Emit("end")

    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:DrawToBuffer(VD)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[224] = function(self)  --DVXDATA_3F_WF
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L VDATA = VM:ReadCell(65467)")
  self:Dyn_Emit("for IDX=1,math.min(128,$2) do")
    self:Dyn_Emit("if VDATA > 0 then")
      self:Dyn_Emit("$L VIDX1 = VM:ReadCell(ADDR+(IDX-1)*3+0)")
      self:Dyn_Emit("$L VIDX2 = VM:ReadCell(ADDR+(IDX-1)*3+1)")
      self:Dyn_Emit("$L VIDX3 = VM:ReadCell(ADDR+(IDX-1)*3+2)")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX1*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX1*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX1*3+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX2*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX2*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX2*3+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(VDATA+VIDX3*3+0),")
      self:Dyn_Emit("  y = VM:ReadCell(VDATA+VIDX3*3+1),")
      self:Dyn_Emit("  z = VM:ReadCell(VDATA+VIDX3*3+2),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VD[1] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+0),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+1),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+2),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[2] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+3),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+4),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+5),")
      self:Dyn_Emit("}")
      self:Dyn_Emit("VD[3] = {")
      self:Dyn_Emit("  x = VM:ReadCell(ADDR+(IDX-1)*9+6),")
      self:Dyn_Emit("  y = VM:ReadCell(ADDR+(IDX-1)*9+7),")
      self:Dyn_Emit("  z = VM:ReadCell(ADDR+(IDX-1)*9+8),")
      self:Dyn_Emit("}")
    self:Dyn_Emit("end")

    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:DrawToBuffer(VD,true)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[225] = function(self)  --DRECT
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR1 = $1")
  self:Dyn_Emit("$L ADDR2 = $2")

  self:Dyn_Emit("VD[1] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[2] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[3] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR2+1)}")
  self:Dyn_Emit("VD[4] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR2+1)}")

  self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[2],1,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[4],0,1)")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawToBuffer(VD)")
end
VM.OpcodeTable[226] = function(self)  --DCIRCLE
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L R = $2")
  self:Dyn_Emit("$L SIDES = math.max(3,math.min(64,VM:ReadCell(65485)))")
  self:Dyn_Emit("$L START = VM:ReadCell(65478)")
  self:Dyn_Emit("$L END = VM:ReadCell(65477)")
  self:Dyn_Emit("$L STEP = (END-START)/SIDES")

  self:Dyn_Emit("$L VEC = VM:ReadVector2f($1)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("for IDX=1,SIDES do")
    self:Dyn_Emit("VD[1] = {")
    self:Dyn_Emit("  x = VEC.x + R*math.sin(START+STEP*(IDX+0)),")
    self:Dyn_Emit("  y = VEC.y + R*math.cos(START+STEP*(IDX+0))}")
    self:Dyn_Emit("VD[2] = {")
    self:Dyn_Emit("  x = VEC.x,")
    self:Dyn_Emit("  y = VEC.y}")
    self:Dyn_Emit("VD[3] = {")
    self:Dyn_Emit("  x = VEC.x + R*math.sin(START+STEP*(IDX+1)),")
    self:Dyn_Emit("  y = VEC.y + R*math.cos(START+STEP*(IDX+1))}")

    self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
    self:Dyn_Emit("VM:ComputeTextureUV(VD[2],1,0)")
    self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")

    self:Dyn_Emit("VM:DrawToBuffer(VD)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[227] = function(self)  --DLINE
  self:Dyn_Emit("VM:DrawLine(VM:ReadVector2f($1),VM:ReadVector2f($2))")
end
VM.OpcodeTable[228] = function(self)  --DRECTWH
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR1 = $1")
  self:Dyn_Emit("$L ADDR2 = $2")

  self:Dyn_Emit("VD[1] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[2] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0)+VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[3] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0)+VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)+VM:ReadCell(ADDR2+1)}")
  self:Dyn_Emit("VD[4] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)+VM:ReadCell(ADDR2+1)}")

  self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[2],1,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD[4],0,1)")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawToBuffer(VD)")
end
VM.OpcodeTable[229] = function(self)  --DORECT
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR1 = $1")
  self:Dyn_Emit("$L ADDR2 = $2")

  self:Dyn_Emit("VD[1] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[2] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[3] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR2+1)}")
  self:Dyn_Emit("VD[4] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR2+1)}")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawLine(VD[1],VD[2])")
  self:Dyn_Emit("VM:DrawLine(VD[2],VD[3])")
  self:Dyn_Emit("VM:DrawLine(VD[3],VD[4])")
  self:Dyn_Emit("VM:DrawLine(VD[4],VD[1])")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[230] = function(self)  --DTRANSFORM2F
  self:Dyn_Emit("$L VEC = VM:ReadVector2f($2)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VEC = VM:VertexTransform(VEC)")
  self:Dyn_Emit("VM:WriteVector2f($1,VEC)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[231] = function(self)  --DTRANSFORM3F
  self:Dyn_Emit("$L VEC = VM:ReadVector3f($2)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VEC = VM:VertexTransform(VEC)")
  self:Dyn_Emit("VM:WriteVector3f($1,VEC)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[232] = function(self)  --DSCRSIZE
  self:Dyn_Emit("VM:WriteCell(65515,$1)")
  self:Dyn_Emit("VM:WriteCell(65514,$2)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[233] = function(self)  --DROTATESCALE
  self:Dyn_Emit("VM:WriteCell(65482,$1)")
  self:Dyn_Emit("VM:WriteCell(65481,$2)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[234] = function(self)  --DORECTWH
  self:Dyn_Emit("$L VD = {}")
  self:Dyn_Emit("$L ADDR1 = $1")
  self:Dyn_Emit("$L ADDR2 = $2")

  self:Dyn_Emit("VD[1] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[2] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0)+VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)}")
  self:Dyn_Emit("VD[3] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0)+VM:ReadCell(ADDR2+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)+VM:ReadCell(ADDR2+1)}")
  self:Dyn_Emit("VD[4] = {")
  self:Dyn_Emit("  x = VM:ReadCell(ADDR1+0),")
  self:Dyn_Emit("  y = VM:ReadCell(ADDR1+1)+VM:ReadCell(ADDR2+1)}")

  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:DrawLine(VD[1],VD[2])")
  self:Dyn_Emit("VM:DrawLine(VD[2],VD[3])")
  self:Dyn_Emit("VM:DrawLine(VD[3],VD[4])")
  self:Dyn_Emit("VM:DrawLine(VD[4],VD[1])")
end
VM.OpcodeTable[235] = function(self)  --DCULLMODE
  self:Dyn_Emit("VM:WriteCell(65469,$1)")
  self:Dyn_Emit("VM:WriteCell(65468,$2)")
end
VM.OpcodeTable[236] = function(self)  --DARRAY

end
VM.OpcodeTable[237] = function(self)  --DDTERMINAL

end
VM.OpcodeTable[238] = function(self)  --DPIXEL
  self:Dyn_Emit("$L COLOR = VM:ColorTransform(VM:ReadVector4f($2))")
  self:Dyn_Emit("$L POS = VM:ReadVector2f($1)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("surface.SetTexture(0)")
  self:Dyn_Emit("surface.SetDrawColor(COLOR.x,COLOR.y,COLOR.z,COLOR.w)")
  self:Dyn_Emit("surface.DrawRect(math.floor(POS.x),math.floor(POS.y),1,1)")
end
VM.OpcodeTable[239] = function(self)  --RESERVED

end
--------------------------------------------------------------------------------
VM.OpcodeTable[240] = function(self)  --DWRITE
  self:Dyn_Emit("$L TEXT = VM:ReadString($2)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:FontWrite($1,TEXT)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[241] = function(self)  --DWRITEI
  self:Dyn_Emit("VM:FontWrite($1,math.floor($2))")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[242] = function(self)  --DWRITEF
  self:Dyn_Emit("VM:FontWrite($1,$2)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[243] = function(self)  --DENTRYPOINT
  self:Dyn_Emit("$L IDX = $1")
  self:Dyn_Emit("if IDX == 0 then VM.EntryPoint0 = $2 end")
  self:Dyn_Emit("if IDX == 1 then VM.EntryPoint1 = $2 end")
  self:Dyn_Emit("if IDX == 2 then VM.EntryPoint2 = $2 end")
  self:Dyn_Emit("if IDX == 3 then VM.EntryPoint3 = $2 end")
  self:Dyn_Emit("if IDX == 4 then VM.EntryPoint4 = $2 end")
end
VM.OpcodeTable[244] = function(self)  --DSETLIGHT
  self:Dyn_Emit("$L IDX = math.floor($1)")
  self:Dyn_Emit("$L ADDR = $2")
  self:Dyn_Emit("if (IDX < 0) or (IDX > 7) then")
    self:Dyn_EmitInterrupt("19","0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("VM.Lights[IDX] = {")
    self:Dyn_Emit("  Position = VM:ReadVector4f(ADDR+0),")
    self:Dyn_Emit("  Color    = VM:ReadVector4f(ADDR+4)}")
  self:Dyn_Emit("end")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[245] = function(self)  --DGETLIGHT
  self:Dyn_Emit("$L IDX = math.floor($1)")
  self:Dyn_Emit("$L ADDR = $2")
  self:Dyn_Emit("if (IDX < 0) or (IDX > 7) then")
    self:Dyn_EmitInterrupt("19","0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("if VM.Lights[IDX] then")
      self:Dyn_Emit("VM:WriteVector4f(ADDR+0,VM.Lights[IDX].Position)")
      self:Dyn_Emit("VM:WriteVector4f(ADDR+4,VM.Lights[IDX].Color)")
    self:Dyn_Emit("else")
      self:Dyn_Emit("VM:WriteVector4f(ADDR+0,0)")
      self:Dyn_Emit("VM:WriteVector4f(ADDR+4,0)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[246] = function(self)  --DWRITEFMT string.format(
  self:Dyn_Emit("$L text = VM:ReadString($2)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L ptr = $2 + #text + 1")
  self:Dyn_Emit("$L ptr2 = VM.Memory[65512] or 0")
  self:Dyn_Emit("if ptr2 ~= 0 then ptr = ptr2 end")

  self:Dyn_Emit("local finaltext = \"\"")

  self:Dyn_Emit("local inparam = false")
  self:Dyn_Emit("local lengthmod = nil")

  self:Dyn_Emit("while (text ~= \"\") do")
    self:Dyn_Emit("local chr = string.sub(text,1,1)")
    self:Dyn_Emit("text = string.sub(text,2,65536)")

    self:Dyn_Emit("if (inparam == false) then")
      self:Dyn_Emit("if (chr == \"%\") then")
        self:Dyn_Emit("inparam = true")
      self:Dyn_Emit("else")
        self:Dyn_Emit("finaltext = finaltext .. chr")
      self:Dyn_Emit("end")
    self:Dyn_Emit("else")
      self:Dyn_Emit("if (chr == \".\") then")
        self:Dyn_Emit("chr = string.sub(text,1,1)")
        self:Dyn_Emit("text = string.sub(text,2,65536)")

        self:Dyn_Emit("if (tonumber(chr)) then")
          self:Dyn_Emit("lengthmod = tonumber(chr)")
        self:Dyn_Emit("end")
      self:Dyn_Emit("elseif (chr == \"i\") or (chr == \"d\") then")
        self:Dyn_Emit("if (lengthmod) then")
          self:Dyn_Emit("local digits = 0")
          self:Dyn_Emit("local num =  math.floor(VM:ReadCell(ptr))")
          self:Dyn_Emit("local temp = num")
          self:Dyn_Emit("while (temp > 0) do")
            self:Dyn_Emit("digits = digits + 1")
            self:Dyn_Emit("temp = math.floor(temp / 10)")
          self:Dyn_Emit("end")
          self:Dyn_Emit("if (num == 0) then")
            self:Dyn_Emit("digits = 1")
          self:Dyn_Emit("end")

          self:Dyn_Emit("local fnum = tostring(num)")
          self:Dyn_Emit("while (digits < lengthmod) do")
            self:Dyn_Emit("digits = digits + 1")
            self:Dyn_Emit("fnum = \"0\"..fnum")
          self:Dyn_Emit("end")

          self:Dyn_Emit("finaltext = finaltext ..fnum")
        self:Dyn_Emit("else")
          self:Dyn_Emit("finaltext = finaltext .. math.floor(VM:ReadCell(ptr))")
        self:Dyn_Emit("end")
        self:Dyn_Emit("ptr = ptr + 1")
        self:Dyn_Emit("inparam = false")
        self:Dyn_Emit("lengthmod = nil")
      self:Dyn_Emit("elseif (chr == \"f\") then")
        self:Dyn_Emit("finaltext = finaltext .. VM:ReadCell(ptr)")
        self:Dyn_Emit("ptr = ptr + 1")
        self:Dyn_Emit("inparam = false")
        self:Dyn_Emit("lengthmod = nil")
      self:Dyn_Emit("elseif (chr == \"s\") then")
        self:Dyn_Emit("local addr = VM:ReadCell(ptr)")
        self:Dyn_Emit("local str = VM:ReadString(addr)")
        self:Dyn_Emit("finaltext = finaltext .. str")
        self:Dyn_Emit("ptr = ptr + 1")
        self:Dyn_Emit("inparam = false")
        self:Dyn_Emit("lengthmod = nil")
      self:Dyn_Emit("elseif (chr == \"t\") then")
        self:Dyn_Emit("while (string.len(finaltext) % (lengthmod or 6) != 0) do")
          self:Dyn_Emit("finaltext = finaltext..\" \"")
        self:Dyn_Emit("end")
        self:Dyn_Emit("inparam = false")
        self:Dyn_Emit("lengthmod = nil")
      self:Dyn_Emit("elseif (chr == \"%\") then")
        self:Dyn_Emit("finaltext = finaltext .. \"%\"")
        self:Dyn_Emit("inparam = false")
        self:Dyn_Emit("lengthmod = nil")
      self:Dyn_Emit("end")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")

  self:Dyn_Emit("VM:FontWrite($1,finaltext)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[247] = function(self)  --DWRITEFIX
  self:Dyn_Emit("$L TEXT = $2")
  self:Dyn_Emit("if TEXT == math.floor(TEXT) then TEXT = TEXT .. \"0\" end")
  self:Dyn_Emit("VM:FontWrite($1,TEXT)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[248] = function(self)  --DTEXTWIDTH
  self:Dyn_Emit("$L TEXT = VM:ReadString($2)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("$L W,H = VM:TextSize(TEXT)")
  self:Dyn_EmitOperand("W")
end
VM.OpcodeTable[249] = function(self)  --DTEXTHEIGHT
  self:Dyn_Emit("$L TEXT = VM:ReadString($2)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("$L W,H = VM:TextSize(TEXT)")
  self:Dyn_EmitOperand("H")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[271] = function(self)   --MLOADPROJ
  self:Dyn_Emit("VM.ProjectionMatrix = VM:ReadMatrix($1)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[272] = function(self)   --MREAD
  self:Dyn_Emit("VM:WriteMatrix($1,VM.ModelMatrix)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[274] = function(self)  --DT
  self:Dyn_EmitOperand("VM.TimerDT")
end
VM.OpcodeTable[276] = function(self)  --DSHADE
  self:Dyn_Emit("$L SHADE = $1")
  self:Dyn_Emit("VM.Color.x = VM.Color.x*SHADE")
  self:Dyn_Emit("VM.Color.y = VM.Color.y*SHADE")
  self:Dyn_Emit("VM.Color.z = VM.Color.z*SHADE")
  self:Dyn_Emit("VM:SetColor(VM.Color)")
end
VM.OpcodeTable[277] = function(self)  --DSETWIDTH
  self:Dyn_Emit("VM:WriteCell(65476,$1)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[278] = function(self)   --MLOAD
  self:Dyn_Emit("VM.ModelMatrix = VM:ReadMatrix($1)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[279] = function(self)  --DSHADENORM
  self:Dyn_Emit("$L SHADE = $1")
  self:Dyn_Emit("VM.Color.x = math.Clamp(VM.Color.x*SHADE,0,255)")
  self:Dyn_Emit("VM.Color.y = math.Clamp(VM.Color.y*SHADE,0,255)")
  self:Dyn_Emit("VM.Color.z = math.Clamp(VM.Color.z*SHADE,0,255)")
  self:Dyn_Emit("VM:SetColor(VM.Color)")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[280] = function(self)  --DDFRAME
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L V1 = VM:ReadVector2f(ADDR+0)") -- X,Y
  self:Dyn_Emit("$L V2 = VM:ReadVector2f(ADDR+2)") -- W,H
  self:Dyn_Emit("$L V3 = VM:ReadVector4f(ADDR+4)") -- C1,C2,C3,BorderSize
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L CSHADOW    = VM:ReadVector3f(V3.x)")
  self:Dyn_Emit("$L CHIGHLIGHT = VM:ReadVector3f(V3.y)")
  self:Dyn_Emit("$L CFACE      = VM:ReadVector3f(V3.z)")

  -- Shadow rectangle
  self:Dyn_Emit("$L VD1 = {}")
  self:Dyn_Emit("VD1[1] = {")
  self:Dyn_Emit("  x = V3.w + V1.x,")
  self:Dyn_Emit("  y = V3.w + V1.y}")
  self:Dyn_Emit("VD1[2] = {")
  self:Dyn_Emit("  x = V3.w + V1.x + V2.x,")
  self:Dyn_Emit("  y = V3.w + V1.y}")
  self:Dyn_Emit("VD1[3] = {")
  self:Dyn_Emit("  x = V3.w + V1.x + V2.x,")
  self:Dyn_Emit("  y = V3.w + V1.y + V2.y}")
  self:Dyn_Emit("VD1[4] = {")
  self:Dyn_Emit("  x = V3.w + V1.x,")
  self:Dyn_Emit("  y = V3.w + V1.y + V2.y}")

  -- Highlight rectangle
  self:Dyn_Emit("$L VD2 = {}")
  self:Dyn_Emit("VD2[1] = {")
  self:Dyn_Emit("  x = -V3.w + V1.x,")
  self:Dyn_Emit("  y = -V3.w + V1.y}")
  self:Dyn_Emit("VD2[2] = {")
  self:Dyn_Emit("  x = -V3.w + V1.x + V2.x,")
  self:Dyn_Emit("  y = -V3.w + V1.y}")
  self:Dyn_Emit("VD2[3] = {")
  self:Dyn_Emit("  x = -V3.w + V1.x + V2.x,")
  self:Dyn_Emit("  y = -V3.w + V1.y + V2.y}")
  self:Dyn_Emit("VD2[4] = {")
  self:Dyn_Emit("  x = -V3.w + V1.x,")
  self:Dyn_Emit("  y = -V3.w + V1.y + V2.y}")

  -- Face rectangle
  self:Dyn_Emit("$L VD3 = {}")
  self:Dyn_Emit("VD3[1] = {")
  self:Dyn_Emit("  x = V1.x,")
  self:Dyn_Emit("  y = V1.y}")
  self:Dyn_Emit("VD3[2] = {")
  self:Dyn_Emit("  x = V1.x + V2.x,")
  self:Dyn_Emit("  y = V1.y}")
  self:Dyn_Emit("VD3[3] = {")
  self:Dyn_Emit("  x = V1.x + V2.x,")
  self:Dyn_Emit("  y = V1.y + V2.y}")
  self:Dyn_Emit("VD3[4] = {")
  self:Dyn_Emit("  x = V1.x,")
  self:Dyn_Emit("  y = V1.y + V2.y}")

  self:Dyn_Emit("VM:ComputeTextureUV(VD1[1],0,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD1[2],1,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD1[3],1,1)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD1[4],0,1)")

  self:Dyn_Emit("VM:ComputeTextureUV(VD2[1],0,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD2[2],1,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD2[3],1,1)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD2[4],0,1)")

  self:Dyn_Emit("VM:ComputeTextureUV(VD3[1],0,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD3[2],1,0)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD3[3],1,1)")
  self:Dyn_Emit("VM:ComputeTextureUV(VD3[4],0,1)")

  self:Dyn_Emit("VM:SetColor(CSHADOW)")
  self:Dyn_Emit("VM:DrawToBuffer(VD1)")
  self:Dyn_Emit("VM:SetColor(CHIGHLIGHT)")
  self:Dyn_Emit("VM:DrawToBuffer(VD2)")
  self:Dyn_Emit("VM:SetColor(CFACE)")
  self:Dyn_Emit("VM:DrawToBuffer(VD3)")
end
VM.OpcodeTable[283] = function(self)  --DRASTER
  self:Dyn_Emit("VM:WriteCell(65518,$1)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[285] = function(self)  --DDTERRAIN
  self:Dyn_Emit("$L ADDR = $1")
  self:Dyn_Emit("$L W = VM:ReadCell(ADDR+0)") -- Total width/height of the terrain
  self:Dyn_Emit("$L H = VM:ReadCell(ADDR+1)")
  self:Dyn_Emit("$L R = math.Clamp(math.floor(VM:ReadCell(ADDR+2)),0,16)") -- Visibility radius
  self:Dyn_Emit("$L U = VM:ReadCell(ADDR+3)") -- Point around which terrain must be drawn
  self:Dyn_Emit("$L V = VM:ReadCell(ADDR+4)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L VD = {}")

  -- Terrain size
  self:Dyn_Emit("$L MinX = math.Clamp(math.floor(W/2 + U - R),1,W-1)")
  self:Dyn_Emit("$L MinY = math.Clamp(math.floor(H/2 + V - R),1,H-1)")
  self:Dyn_Emit("$L MaxX = math.Clamp(math.floor(W/2 + U + R),1,W-1)")
  self:Dyn_Emit("$L MaxY = math.Clamp(math.floor(H/2 + V + R),1,H-1)")

  -- Draw terrain
  self:Dyn_Emit("for X=MinX,MaxX do")
    self:Dyn_Emit("for Y=MinY,MaxY do")
      self:Dyn_Emit("$L XPOS = X - W/2 - U - 0.5")
      self:Dyn_Emit("$L YPOS = Y - H/2 - U - 0.5")

      self:Dyn_Emit("if (X > 0) and (X <= W-1) and (Y > 0) and (Y <= H-1) and (XPOS^2+YPOS^2 <= R^2) then")
        self:Dyn_Emit("$L Z1 = VM:ReadCell(ADDR+16+(Y-1)*W+(X-1)")
        self:Dyn_Emit("$L Z2 = VM:ReadCell(ADDR+16+(Y-1)*W+(X-0)")
        self:Dyn_Emit("$L Z3 = VM:ReadCell(ADDR+16+(Y-0)*W+(X-0)")
        self:Dyn_Emit("$L Z4 = VM:ReadCell(ADDR+16+(Y-0)*W+(X-1)")

        self:Dyn_Emit("VD[1] = {")
        self:Dyn_Emit("  x = XPOS,")
        self:Dyn_Emit("  y = YPOS,")
        self:Dyn_Emit("  y = Z1}")
        self:Dyn_Emit("VD[2] = {")
        self:Dyn_Emit("  x = XPOS+1,")
        self:Dyn_Emit("  y = YPOS,")
        self:Dyn_Emit("  y = Z2}")
        self:Dyn_Emit("VD[3] = {")
        self:Dyn_Emit("  x = XPOS+1,")
        self:Dyn_Emit("  y = YPOS+1,")
        self:Dyn_Emit("  y = Z3}")

        self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
        self:Dyn_Emit("VM:ComputeTextureUV(VD[2],1,0)")
        self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")
        self:Dyn_Emit("VM:DrawToBuffer(VD)")

        self:Dyn_Emit("VD[1] = {")
        self:Dyn_Emit("  x = XPOS,")
        self:Dyn_Emit("  y = YPOS,")
        self:Dyn_Emit("  y = Z1}")
        self:Dyn_Emit("VD[2] = {")
        self:Dyn_Emit("  x = XPOS,")
        self:Dyn_Emit("  y = YPOS+1,")
        self:Dyn_Emit("  y = Z4}")
        self:Dyn_Emit("VD[3] = {")
        self:Dyn_Emit("  x = XPOS+1,")
        self:Dyn_Emit("  y = YPOS+1,")
        self:Dyn_Emit("  y = Z3}")

        self:Dyn_Emit("VM:ComputeTextureUV(VD[1],0,0)")
        self:Dyn_Emit("VM:ComputeTextureUV(VD[2],0,1)")
        self:Dyn_Emit("VM:ComputeTextureUV(VD[3],1,1)")
        self:Dyn_Emit("VM:DrawToBuffer(VD)")
      self:Dyn_Emit("end")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[288] = function(self)  --DSETTEXTBOX
  self:Dyn_Emit("VM.Textbox = VM:ReadVector2f($1)")
  self:Dyn_EmitInterruptCheck()
end
VM.OpcodeTable[289] = function(self)  --DSETTEXTWRAP
  self:Dyn_Emit("VM.WordWrapMode = $1")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[294] = function(self)  --DMULDT
  self:Dyn_EmitOperand("$2*VM.TimerDT")
end
VM.OpcodeTable[297] = function(self)  --DMULDT
  self:Dyn_EmitOperand("$2*VM.TimerDT")
end
VM.OpcodeTable[298] = function(self)  --DBEGIN
  self:Dyn_Emit("VM.Entity:SetRendertarget(1)")
  self:Dyn_Emit("VM.LastBuffer = 1")
end
VM.OpcodeTable[299] = function(self)  --DEND
  self:Dyn_Emit("VM:FlushBuffer()")
  self:Dyn_Emit("VM.Entity:AssertSpriteBufferExists()")
  self:Dyn_Emit("if VM.Entity.SpriteGPU.RT and VM.Entity.GPU.RT then")
    self:Dyn_Emit("render.CopyTexture(VM.Entity.SpriteGPU.RT,VM.Entity.GPU.RT)")
  self:Dyn_Emit("end")
  self:Dyn_Emit("VM.Entity:SetRendertarget()")
  self:Dyn_Emit("VM.LastBuffer = 2")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[303] = function(self)  --DXTEXTURE
  self:Dyn_Emit("$L PTR = $1")
  self:Dyn_Emit("if PTR > 0 then")
    self:Dyn_Emit("$L NAME = VM:ReadString($1)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:SetMaterial(GPULib.Material(NAME))")
  self:Dyn_Emit("else")
    self:Dyn_Emit("VM:SetMaterial(nil)")
  self:Dyn_Emit("end")
end






--------------------------------------------------------------------------------
--ENT._VM = {}
--for k,v in pairs(VM) do ENT._VM[k] = v end
--VM = nil
