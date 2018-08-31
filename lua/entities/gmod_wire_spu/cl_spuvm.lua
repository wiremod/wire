--------------------------------------------------------------------------------
-- Override virtual machine functions and features
--------------------------------------------------------------------------------
local VM = {}

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

  self.VM.Entity = self

  self.VM.Interrupt = function(self,interruptNo,interruptParameter,isExternal,cascadeInterrupt)
    self.IP = self.EntryPoint1
    self.LADD = interruptParameter
    self.LINT = interruptNo
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
    if Address == 65534 then
      VM:Reset()
    elseif Address == 65530 then
      VM.ROM = {}
    end
  end

  -- Add internal registers
  self.VM.InternalRegister[128] = "EntryPoint0"
  self.VM.InternalRegister[129] = "EntryPoint1"

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

  self.EntryPoint0 = 0
  self.EntryPoint1 = 0

  -- Reset internal SPU registers
  -- Hardware control registers:
  --  [65535] - CLK
  --  [65534] - RESET
  --  [65527] - Async thread frequency

  if self.Channel then
    for k,v in pairs(self.Channel) do
      v.Sound:Stop()
    end
  end

  self.Waveform = {}
  self.Channel = {}

  self.Waveform[0] = WireSPU_GetSound("synth/square.wav")
  self.Waveform[1] = WireSPU_GetSound("synth/saw.wav")
  self.Waveform[2] = WireSPU_GetSound("synth/tri.wav")
  self.Waveform[3] = WireSPU_GetSound("synth/sine.wav")

  for chan=0,3 do
    self.Channel[chan] = {
      Sound = CreateSound(self.Entity.SoundSources[chan],self.Waveform[chan]),
      Volume = 1.0,
      Pitch = 100,
    }
  end
end

WireSPU_SoundCache = {}
function WireSPU_GetSound(name)
  if not WireSPU_SoundCache[name] then
    WireSPU_SoundCache[name] = Sound(name)
  end
  return WireSPU_SoundCache[name]
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

    if (currentChar > 0) and (currentChar < 255) then
      charString = charString .. string.char(currentChar)
    else
      if currentChar ~= 0 then
        self:Interrupt(23,currentChar)
        return ""
      end
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
-- SPU instruction set implementation
--------------------------------------------------------------------------------
VM.OpcodeTable = {}
VM.OpcodeTable[111] = function(self)  --IDLE
--  self:Dyn_Emit("VM.INTR = 1")
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
--------------------------------------------------------------------------------
VM.OpcodeTable[320] = function(self)  --CHRESET
  self:Dyn_Emit("$L CHAN = math.floor($1)")

  self:Dyn_Emit("if CHAN == -1 then")
    self:Dyn_Emit("for channel=0,WireSPU_MaxChannels-1 do")
      self:Dyn_Emit("if VM.Channel[channel] then")
        self:Dyn_Emit("VM.Channel[channel].Sound:Stop()")
        self:Dyn_Emit("VM.Channel[channel].Pitch = 100")
        self:Dyn_Emit("VM.Channel[channel].Volume = 1.0")
      self:Dyn_Emit("end")
    self:Dyn_Emit("end")
  self:Dyn_Emit("else")
    self:Dyn_Emit("if VM.Channel[CHAN] then")
      self:Dyn_Emit("VM.Channel[CHAN].Sound:Stop()")
      self:Dyn_Emit("VM.Channel[CHAN].Pitch = 100")
      self:Dyn_Emit("VM.Channel[CHAN].Volume = 1.0")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[321] = function(self)  --CHSTART
  self:Dyn_Emit("$L CHAN = math.floor($1)")

  self:Dyn_Emit("if (CHAN >= 0) and (CHAN < WireSPU_MaxChannels) then")
    self:Dyn_Emit("if VM.Channel[CHAN] then")
      self:Dyn_Emit("VM.Channel[CHAN].Sound:PlayEx(VM.Channel[CHAN].Volume,VM.Channel[CHAN].Pitch)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[322] = function(self)  --CHSTOP
  self:Dyn_Emit("$L CHAN = math.floor($1)")

  self:Dyn_Emit("if (CHAN >= 0) and (CHAN < WireSPU_MaxChannels) then")
    self:Dyn_Emit("if VM.Channel[CHAN] then")
      self:Dyn_Emit("VM.Channel[CHAN].Sound:Stop()")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
VM.OpcodeTable[330] = function(self)  --WSET
  self:Dyn_Emit("$L WAVE = math.floor($1)")
  self:Dyn_Emit("$L NAME = VM:ReadString($2)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("if (WAVE >= 0) and (WAVE < 8192) then")
    self:Dyn_Emit("VM.Waveform[WAVE] = WireSPU_GetSound(NAME)")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[331] = function(self)  --CHWAVE
  self:Dyn_Emit("$L CHAN = math.floor($1)")
  self:Dyn_Emit("$L WAVE = math.floor($2)")

  self:Dyn_Emit("if (WAVE >= 0) and (WAVE < 8192) and (CHAN >= 0) and (CHAN < WireSPU_MaxChannels) then")
    self:Dyn_Emit("if VM.Waveform[WAVE] then")
      self:Dyn_Emit("VM.Channel[CHAN] = { Sound = CreateSound(VM.Entity.SoundSources[CHAN],VM.Waveform[WAVE]), Pitch = 100, Volume = 1.0 }")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[332] = function(self)  --CHLOOP
end
VM.OpcodeTable[333] = function(self)  --CHVOLUME
  self:Dyn_Emit("$L CHAN = math.floor($1)")
  self:Dyn_Emit("$L X = $2")

  self:Dyn_Emit("if (CHAN >= 0) and (CHAN < WireSPU_MaxChannels) then")
    self:Dyn_Emit("if VM.Channel[CHAN] then")
      self:Dyn_Emit("VM.Channel[CHAN].Sound:ChangeVolume(math.Clamp(X,0,1),0)")
      self:Dyn_Emit("VM.Channel[CHAN].Volume = math.Clamp(X,0,1)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[334] = function(self)  --CHPITCH
  self:Dyn_Emit("$L CHAN = math.floor($1)")
  self:Dyn_Emit("$L X = $2")

  self:Dyn_Emit("if (CHAN >= 0) and (CHAN < WireSPU_MaxChannels) then")
    self:Dyn_Emit("if VM.Channel[CHAN] then")
      self:Dyn_Emit("VM.Channel[CHAN].Sound:ChangePitch(math.Clamp(X*100,0,255),0)")
      self:Dyn_Emit("VM.Channel[CHAN].Pitch = math.Clamp(X*100,0,255)")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")
end
VM.OpcodeTable[335] = function(self)  --CHMODT
end
VM.OpcodeTable[336] = function(self)  --CHMODA
end
VM.OpcodeTable[337] = function(self)  --CHMODF
end
VM.OpcodeTable[338] = function(self)  --CHADSR
end
