--------------------------------------------------------------------------------
-- Zyelios VM (Zyelios CPU/GPU virtual machine)
--
-- Implementation for most default ZCPU features (including the data bus)
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Default configuration
ZVM.RAMSize = 65536 -- Internal RAM size
ZVM.ROMSize = 65536 -- Internal ROM size
ZVM.PCAP    = 1     -- Paging capability
ZVM.RQCAP   = 1     -- Memory request delaying capability
ZVM.CPUVER  = 1000  -- Version reported by CPUID
ZVM.CPUTYPE = 0     -- Processor type
ZVM.ROM = {}

-- CPUID instruction result
function ZVM:CPUID(index)
  if index == 0 then
    return self.CPUVER  -- CPU version
  elseif index == 1 then
    return self.RAMSize -- Amount of internal RAM
  elseif index == 2 then
    return self.CPUTYPE -- 0: ZCPU, 1: ZGPU, 2: ZSPU
  elseif index == 3 then
    return self.ROMSize -- Amount of internal ROM
  end
end




--------------------------------------------------------------------------------
-- VM state reset
function ZVM:Reset()
  self.IP = 0        -- Instruction pointer

  self.EAX = 0       -- General purpose registers
  self.EBX = 0
  self.ECX = 0
  self.EDX = 0
  self.ESI = 0
  self.EDI = 0
  self.ESP = math.max(0,self.RAMSize-1)
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

  -- Stack size register
  self.ESZ = math.max(0,self.RAMSize-1)

  self.IDTR = 0      -- Interrupt descriptor table register
  self.NIDT = 256    -- Size of interrupt descriptor table
  self.EF = 0        -- Extended mode flag
  self.PF = 0        -- Protected mode flag
  self.MF = 0        -- Memory extended mode flag
  self.IF = 1        -- Interrupts enabled flag
  self.NIF = nil     -- Value of IF flag for next frame

  self.PTBL = 0      -- Page table offset
  self.PTBE = 0      -- Page table size

  self.CMPR = 0      -- Compare register
  self.XEIP = 0      -- Current instruction address register
  self.LADD = 0      -- Last interrupt parameter
  self.LINT = 0      -- Last interrupt number
  self.TMR = 0       -- Internal timer
  self.TIMER = 0     -- Internal clock
  self.CPAGE = 0     -- Current page ID
  self.PPAGE = 0     -- Previous page ID

  self.BPREC = 48    -- Binary precision for integer emulation mode (default: 48)
  self.IPREC = 48    -- Integer precision (48 - floating point mode, 8, 16, 32, 64 - integer mode)
  self.VMODE = 2     -- Vector mode (2D, 3D)

  self.CODEBYTES = 0 -- Executed size of code
  self.HWDEBUG = 0   -- Hardware debug mode
  self.DBGSTATE = 0  -- 0: halt; 1: reset; 2: step fwd and halt; 3: run; 4: read registers; 5: write registers
  self.DBGADDR = 0   -- 0: external ports, everything else: absolute memory address

  -- Timer system registers
  self.TimerMode = 0      -- 0: disable; NMI: 1: every X seconds; 2: every N ticks
  self.TimerRate = 0      -- Seconds or ticks
  self.TimerPrevTime = 0  -- Previous fire time
  self.TimerAddress  = 32 -- Interrupt number to call (modes 1,2)
  self.TimerPrevMode = 0  -- Previous timer mode

  -- Internal operation registers
  self.MEMRQ = 0           -- Handling a memory request (1: delayed request, 2: read request, 3: write request)
  self.MEMADDR = 0         -- Address of the memory request
  self.INTR = 0            -- Handling an interrupt
  self.BusLock = 0         -- Bus is locked for read/write
  self.Idle = 0            -- Idle flag
  self.External = 0        -- External IO operation

  -- Misc registers
  self.BlockStart = 0      -- Start of the block
  self.BlockSize = 0       -- Size of the block
  self.HaltPort = 0        -- Unused/obsolete
  self.TimerDT = 0         -- Timer deltastep within cached instructions block

  -- Runlevel registers
  self.CRL  = 0            -- Current runlevel
  self.XTRL = 1            -- Runlevel for external IO

  -- Reset internal memory, precompiler data, page table
  self.Memory = {}
  self.PrecompiledData = {}
  self.IsAddressPrecompiled = {}
  self.PageData = {}

  -- Restore ROM to memory
  self.INTR = 1
  if self.ROMSize > 0 then
    for address,value in pairs(self.ROM) do
      self:WriteCell(address,value)
    end
  end

  -- Reset pages
  self:SetCurrentPage(0)
  self:SetPreviousPage(0)
  self.INTR = 0
end




--------------------------------------------------------------------------------
-- Checks if address is valid
local function IsValidAddress(n)
  return n and (math.floor(n) == n) and (n >= -140737488355327) and (n <= 140737488355328)
end




--------------------------------------------------------------------------------
function ZVM:SignalError(errorCode)

end

function ZVM:SignalShutdown()

end

function ZVM:ExternalWrite(Address,Value)
  if Address >= 0
  then self:Interrupt(7,Address) return false -- MemBus
  else return true                            -- IOBus
  end
end

function ZVM:ExternalRead(Address,Value)
  if Address >= 0
  then self:Interrupt(7,Address) return -- MemBus
  else return 0                         -- IOBus
  end
end




--------------------------------------------------------------------------------
-- Default WritePort handler
function ZVM:WritePort(Port,Value)
  self:WriteCell(-Port-1,Value)
end




--------------------------------------------------------------------------------
-- Default ReadPort handler
function ZVM:ReadPort(Port)
  return self:ReadCell(-Port-1)
end




--------------------------------------------------------------------------------
-- Default ReadCell handler
function ZVM:ReadCell(Address)
  -- Check bus lock flag
  if self.BusLock == 1 then return end

  -- Cycles required to perform memory read
  self.TMR = self.TMR + 5

  -- Check if address is valid
  if not IsValidAddress(Address) then
    self:Interrupt(15,Address)
    return
  end

  -- Do we need to perform page checking
  if self.PCAP == 1 then
    -- Fetch page
    local PageIndex = math.floor(Address / 128)
    local Page = self:GetPageByIndex(PageIndex)

    -- Check if page is disabled
    if Page.Disabled == 1 then
      self:Interrupt(7,Address)
      return
    end

    -- Check if page is overriden
    if Page.Override == 1 then
      if self.MEMRQ == 2 then -- Data available
        self.MEMRQ = 0
        return self.LADD
      else -- No data: generate a request
        self.MEMRQ = 2
        self.MEMADDR = Address

        -- Extra cycles for early termination
        self.TMR = self.TMR + 10
        return
      end
    end

    -- Page permissions
    if (self.EF == 1) and (self.CurrentPage.RunLevel > Page.RunLevel) and (Page.Read == 0) then
      self:Interrupt(12,Address)
      return
    end

    -- Page remapping
    if (Page.Remapped == 1) and (Page.MappedIndex ~= PageIndex) then
      Address = Address % 128 + Page.MappedIndex * 128
    end
  end

  -- Perform I/O operation
  if (Address >= 0) and (Address < self.RAMSize) then
    return self.Memory[Address] or 0
  else
    -- Extra cycles for the external operation
    self.TMR = self.TMR + 15
    return self:ExternalRead(Address)
  end
end




--------------------------------------------------------------------------------
-- Default WriteCell handler
function ZVM:WriteCell(Address,Value)
  -- Check bus lock flag
  if self.BusLock == 1 then return false end

  -- Cycles required to perform memory write
  self.TMR = self.TMR + 5

  -- Check if address is valid
  if not IsValidAddress(Address) then
    self:Interrupt(15,Address)
    return false
  end

  -- Invalidate precompiled data
  if self.IsAddressPrecompiled[Address] then
    for k,v in ipairs(self.IsAddressPrecompiled[Address]) do
      self.PrecompiledData[v] = nil
      self.IsAddressPrecompiled[Address][k] = nil
    end
  end

  -- Do we need to perform page checking
  if self.PCAP == 1 then
    -- Fetch page
    local PageIndex = math.floor(Address / 128)
    local Page = self:GetPageByIndex(PageIndex)

    -- Check if page is disabled
    if Page.Disabled == 1 then
      self:Interrupt(7,Address)
      return false
    end

    -- Check if page is overriden
    if Page.Override == 1 then
      if self.MEMRQ == 3 then -- Data was written
        self.MEMRQ = 0
        return true
      else
        self.MEMRQ = 3
        self.MEMADDR = Address
        self.LADD = Value

        -- Extra cycles for early termination
        self.TMR = self.TMR + 10
        return false
      end
    end

    -- Page permissions
    if (self.EF == 1) and (self.CurrentPage.RunLevel > Page.RunLevel) and (Page.Write == 0) then
      self:Interrupt(9,Address)
      return false
    end

    -- Page remapping
    if (Page.Remapped == 1) and (Page.MappedIndex ~= PageIndex) then
      Address = Address % 128 + Page.MappedIndex * 128
    end
  end

  -- Perform I/O operation
  if (Address >= 0) and (Address < self.RAMSize) then
    self.Memory[Address] = Value
  else
    -- Extra cycles for the external operation
    self.TMR = self.TMR + 15
    return self:ExternalWrite(Address,Value)
  end
end




--------------------------------------------------------------------------------
function ZVM:Push(Value)
  -- Check bus lock flag
  if self.BusLock == 1 then return false end

  -- Write to stack
  self:WriteCell(self.ESP+self.SS, Value)
  self.ESP = self.ESP - 1

  -- Stack check
  if self.ESP < 0 then
    self.ESP = 0
    self:Interrupt(6,self.ESP)
    return false
  end
  return true
end




--------------------------------------------------------------------------------
function ZVM:Pop()
  -- Check bus lock flag
  if self.BusLock == 1 then return 0 end

  -- Read from stack
  self.ESP = self.ESP + 1
  if self.ESP > self.ESZ then
    self.ESP = self.ESZ
    self:Interrupt(6,self.ESP)
    return 0
  end

  local Value = self:ReadCell(self.ESP+self.SS)
  if Value then return Value
  else self:Interrupt(6,self.ESP) return 0 end
end




--------------------------------------------------------------------------------
-- Write value to stack (SSTACK implementation)
function ZVM:WriteToStack(Index,Value)
  -- Check bus lock flag
  if self.BusLock == 1 then return false end

  -- Write to stack
  if (Index > self.ESZ) or (Index < 0) then self:Interrupt(6,Index) return false end
  self:WriteCell(self.SS + Index,Value)
end




--------------------------------------------------------------------------------
-- Read a value from stack (RSTACK implementation)
function ZVM:ReadFromStack(Index)
  -- Check bus lock flag
  if self.BusLock == 1 then return 0 end

  -- Read from stack
  if (Index > self.ESZ) or (Index < 0) then self:Interrupt(6,Index) return 0 end
  local Value = self:ReadCell(self.SS + Index)
  if Value then return Value else self:Interrupt(6,Index) return 0 end
end




--------------------------------------------------------------------------------
-- Extended mode stuff
local defaultPage = {
  Disabled = 0,    -- 00 Is page disabled? Set to 1 to disable this page
  Remapped = 0,    -- 01 Is page remapped? Set to 1 to remap this page
  Trapped = 0,     -- 02 Page must generate NMI 30 (page trap) upon access
  Override = 0,    -- 03 Page overrides reading/writing from it
  Read = 0,        -- 05 Read permissions (0: allowed, 1: disabled)
  Write = 0,       -- 06 Write permissions (0: allowed, 1: disabled)
  Execute = 0,     -- 07 Execute permissions (0: allowed, 1: disabled)
  RunLevel = 0,
  MappedIndex = 0,
}

local errorPage = {
  Disabled = 1,
  Remapped = 0,
  Trapped = 0,
  Override = 0,
  Read = 0,
  Write = 0,
  Execute = 0,
  RunLevel = 0,
  MappedIndex = 0,
}

function ZVM:ResetPage(index)
  local newPage = {}
  newPage.Disabled    = 0
  newPage.Remapped    = 0
  newPage.Trapped     = 0
  newPage.Override    = 0
  newPage.Read        = 1
  newPage.Write       = 1
  newPage.Execute     = 1
  newPage.RunLevel    = 0
  newPage.MappedIndex = 0

  self.PageData[index] = newPage
end

function ZVM:SetPagePermissions(index,permissionMask,mappedPage)
  if not self.PageData[index] then self:ResetPage(index) end
  local targetPage = self.PageData[index]

  local permissionBits = self:IntegerToBinary(permissionMask)
  local runlevel = math.floor(permissionMask / 256) % 256

  targetPage.Disabled    = permissionBits[0]
  targetPage.Remapped    = permissionBits[1]
  targetPage.Trapped     = permissionBits[2]
  targetPage.Override    = permissionBits[3]
  targetPage.Read        = 1-permissionBits[5]
  targetPage.Write       = 1-permissionBits[6]
  targetPage.Execute     = 1-permissionBits[7]
  targetPage.RunLevel    = runlevel
  targetPage.MappedIndex = mappedPage
end

function ZVM:GetPagePermissions(index)
  if not self.PageData[index] then self:ResetPage(index) end
  local sourcePage = self.PageData[index]

  local permissionBits = {}
  permissionBits[0] = sourcePage.Disabled
  permissionBits[1] = sourcePage.Remapped
  permissionBits[2] = sourcePage.Trapped
  permissionBits[3] = sourcePage.Override
  permissionBits[5] = 1-sourcePage.Read
  permissionBits[6] = 1-sourcePage.Write
  permissionBits[7] = 1-sourcePage.Execute

  return self:BinaryToInteger(permissionBits) + sourcePage.RunLevel * 256,sourcePage.MappedIndex
end




--------------------------------------------------------------------------------
function ZVM:GetPageByIndex(index)
  if self.PCAP == 1 then
    if self.MF == 1 then
      -- Find page entry offset
      local pageEntryOffset
      if (index >= self.PTBE) or (index < 0)
      then pageEntryOffset = self.PTBL
      else pageEntryOffset = self.PTBL+(index+1)*2
      end

      -- Read page entry
      self.PCAP = 0 -- Stop infinite recursive page table lookup
      local pagePermissionMask = self:ReadCell(pageEntryOffset+0)
      local pageMappedTo = self:ReadCell(pageEntryOffset+1)
      self.PCAP = 1

      if (not pagePermissionMask) or (not pageMappedTo) then
        self:Interrupt(13,8)
        return errorPage
      end

      self:SetPagePermissions(index,pagePermissionMask,pageMappedTo)
      return self.PageData[index]
    else
      if not self.PageData[index] then self:ResetPage(index) end
      return self.PageData[index]
    end
  else
    return defaultPage
  end
end




--------------------------------------------------------------------------------
function ZVM:SetPageByIndex(index)
  if self.PCAP == 1 then
    if self.MF == 1 then
      -- Find page entry offset
      local pageEntryOffset
      if (index >= self.PTBE) or (index < 0)
      then pageEntryOffset = self.PTBL
      else pageEntryOffset = self.PTBL+(index+1)*2
      end

      -- Write page entry
      local pagePermissionMask,pageMappedTo = self:GetPagePermissions(index)
      self.PCAP = 0 -- Stop possible infinite recursive page redirection
      self:WriteCell(pageEntryOffset+0,pagePermissionMask)
      self:WriteCell(pageEntryOffset+1,pageMappedTo)
      self.PCAP = 1
    end
  end
end




--------------------------------------------------------------------------------
function ZVM:SetCurrentPage(index)
  if self.PCAP == 1 then
    self.CurrentPage = self:GetPageByIndex(index)
  else
    self.CurrentPage = defaultPage
  end
end




--------------------------------------------------------------------------------
function ZVM:SetPreviousPage(index)
  if self.PCAP == 1 then
    self.PreviousPage = self:GetPageByIndex(index)
  else
    self.PreviousPage = defaultPage
  end
end




--------------------------------------------------------------------------------
function ZVM:Jump(newIP,newCS)
  local targetXEIP = newIP + (newCS or self.CS)
  local targetPage = self:GetPageByIndex(math.floor(targetXEIP/128))

  -- Do not allow execution if not calling from kernel page
  if (self.PCAP == 1) and (targetPage.Execute == 0) and (self.CurrentPage.RunLevel ~= 0) then
    self:Interrupt(14,self.CPAGE)
    return -- Jump failed
  end

  self.IP = newIP
  if newCS then
    self.CS = newCS
  end
end




--------------------------------------------------------------------------------
function ZVM:ExternalInterrupt(interruptNo)
  if ((self.IF == 1) and
       self:Push(self.LS) and
       self:Push(self.KS) and
       self:Push(self.ES) and
       self:Push(self.GS) and
       self:Push(self.FS) and
       self:Push(self.DS) and
       self:Push(self.SS) and
       self:Push(self.CS) and

       self:Push(self.EDI) and
       self:Push(self.ESI) and
       self:Push(self.ESP) and
       self:Push(self.EBP) and
       self:Push(self.EDX) and
       self:Push(self.ECX) and
       self:Push(self.EBX) and
       self:Push(self.EAX) and

       self:Push(self.CMPR) and
       self:Push(self.IP)) then
      self:Interrupt(interruptNo,0,1)
  end
end




--------------------------------------------------------------------------------
function ZVM:Interrupt(interruptNo,interruptParameter,isExternal,cascadeInterrupt)
  -- Do not allow cascade interrupts unless they are explicty stated as such
  if (not cascadeInterrupt) and (self.INTR == 1) then return end

  -- Interrupt is active, lock the bus to prevent any further read/write
  self.INTR = 1

  -- Set registers
  self.LINT = interruptNo
  self.LADD = interruptParameter or self.XEIP

  -- Output an error externally
  local fractionalParameter = self.LADD * (10^math.floor(-math.log10(math.abs(self.LADD)+1e-12)-1))
  self:SignalError(fractionalParameter+interruptNo)

  -- Check if interrupts handling is enabled
  if self.IF == 1 then
    if self.EF == 1 then -- Extended mode
      -- Boundary check
      if (interruptNo < 0) or (interruptNo > 255) then
        if not cascadeInterrupt then self:Interrupt(13,3,false,true) end
        return
      end

      -- Check if basic logic must be used
      if interruptNo > self.NIDT-1 then
        if interruptNo == 0 then
          self:Reset()
        end
        if interruptNo == 1 then
          self:SignalShutdown()
        end
        return
      end

      -- Calculate absolute offset in the interrupt table
      local interruptOffset = self.IDTR + interruptNo*4

      -- Disable bus lock, set the current page for read operations to succeed
      self.BusLock = 0
      self:SetCurrentPage(interruptOffset)

      self.IF = 0
      self.INTR = 0
      local prevPCAP = self.PCAP
      self.PCAP = 0 -- Use absolute addressing
      local IP     =                      self:ReadCell(interruptOffset+0)
      local CS     =                      self:ReadCell(interruptOffset+1)
      local NewPTB =                      self:ReadCell(interruptOffset+2)
      local FLAGS  = self:IntegerToBinary(self:ReadCell(interruptOffset+3))
      self.PCAP = prevPCAP
      self.IF = 1
      if self.INTR == 1 then
        if not cascadeInterrupt then self:Interrupt(13,2,false,true) end
        return
      else
        self.INTR = 1
      end

      -- Set previous page to trigger same logic as if CALL-ing from a privilegied page
      self:SetCurrentPage(self.XEIP)
      self:SetPreviousPage(interruptOffset)
      self.BusLock = 1

      --Flags:
      --3  [8 ] = CMPR shows if interrupt occured
      --4  [16] = Interrupt does not set CS
      --5  [32] = Interrupt enabled
      --6  [64] = NMI interrupt
      --7  [128] = Replace PTBL with NewPTE (overrides #8)
      --8  [256] = Replace PTBE with NewPTE
      --9  [512] = Push extended registers (R0-R31)

      if isExternal and (FLAGS[6] ~= 1) then
        if not cascadeInterrupt then self:Interrupt(13,4,false,true) end
        return
      end

      if FLAGS[5] == 1 then -- Interrupt enabled
        -- Push extended registers
        self.BusLock = 0
        if FLAGS[9] == 1 then
          for i=31,0,-1 do
            self:Push(self["R"..i])
          end
        end

        -- Push return data
        self.IF = 0
        self.INTR = 0
        self:Push(self.IP)
        self:Push(self.CS)
        self.IF = 1
        if self.INTR == 1 then
          if not cascadeInterrupt then self:Interrupt(13,6,false,true) end
          return
        else
          self.INTR = 1
        end
        self.BusLock = 1

        -- Perform a short or a long jump
        self.IF = 0
        self.INTR = 0
        if FLAGS[4] == 0
        then self:Jump(IP,CS)
        else self:Jump(IP)
        end
        self.IF = 1
        if self.INTR == 1 then
          if not cascadeInterrupt then self:Interrupt(13,7,false,true) end
          return
        else
          self.INTR = 1
        end

        -- Set CMPR
        if FLAGS[3] == 1 then
          self.CMPR = 1
        end
      else
        if interruptNo == 0 then
          self:Reset()
        end
        if interruptNo == 1 then
          self:SignalShutdown()
        end
        if FLAGS[3] == 1 then
          self.CMPR = 1
        end
      end

      if FLAGS[7] == 1 then
        self.PTBL = NewPTE
      elseif FLAGS[8] == 1 then
        self.PTBE = 1
      end
      
    elseif self.PF == 1 then -- Compatibility extended mode
      -- Boundary check
      if (interruptNo < 0) or (interruptNo > 255) then
        if not cascadeInterrupt then self:Interrupt(13,3,false,true) end
        return
      end

      -- Memory size check
      if self.RAMSize < 512 then
        if not cascadeInterrupt then self:Interrupt(13,5,false,true) end
        return
      end

      -- Calculate absolute offset in the interrupt table
      local interruptOffset = self.IDTR + interruptNo*2

      if interruptOffset > self.RAMSize-2 then interruptOffset = self.RAMSize-2 end
      if interruptOffset < 0              then interruptOffset = 0 end

      local interruptOffset = self.Memory[interruptOffset]
      local interruptFlags = self.Memory[interruptOffset+1]
      if (interruptFlags == 32) or (interruptFlags == 96) then
        self.BusLock = 0
        self.IF = 0
        self.INTR = 0
        if (interruptNo == 4 ) or
           (interruptNo == 7 ) or
           (interruptNo == 9 ) or
           (interruptNo == 10) then
          self:Push(self.LADD)
        end
        if (interruptNo == 4 ) or
           (interruptNo == 31) then
          self:Push(self.LINT)
        end
        if self:Push(self.IP) and self:Push(self.XEIP) then
          self:Jump(interruptOffset)
        end
        self.IF = 1
        if self.INTR == 1 then
          if not cascadeInterrupt then self:Interrupt(13,6,false,true) end
          return
        else
          self.INTR = 1
        end
        self.CMPR = 0
        self.BusLock = 1
      else
        if interruptNo == 1 then
          self:SignalShutdown()
        end
        self.CMPR = 1
      end
    else
      if (interruptNo < 0) or (interruptNo > 255) or (interruptNo > self.NIDT-1) then
        -- Interrupt not handled
        return
      end
      if interruptNo == 0 then
        self:Reset()
        return
      end
      if interruptNo ~= 31 then --Don't die on the debug trap
        self:SignalShutdown()
      end
    end
  end

  -- Unlock the bus
  self.BusLock = 0
end




--------------------------------------------------------------------------------
-- Timer firing checks
function ZVM:TimerLogic()
  if self.TimerMode ~= self.TimerPrevMode then
    if self.TimerMode == 1 then
      self.TimerPrevTime = self.TIMER
    elseif self.TimerMode == 2 then
      self.TimerPrevTime = self.TMR
    end
    self.TimerPrevMode = self.TimerMode
  end

  if self.TimerMode ~= 0 then
    if self.TimerMode == 1 then
      if (self.TIMER - self.TimerPrevTime) >= self.TimerRate then
        self:ExternalInterrupt(math.floor(self.TimerAddress))
        self.TimerPrevTime = self.TIMER
      end
    elseif self.TimerMode == 2 then
      if (self.TMR - self.TimerPrevTime) >= self.TimerRate then
        self:ExternalInterrupt(math.floor(self.TimerAddress))
        self.TimerPrevTime = self.TMR
      end
    end
  end
end




--------------------------------------------------------------------------------
-- Vector reading/writing instructions
function ZVM:ReadVector2f(address)
  if address == 0 then
    return { x = 0, y = 0, z = 0, w = 0 }
  else
    return { x = self:ReadCell(address+0) or 0,
             y = self:ReadCell(address+1) or 0,
             z = 0,
             w = 0 }
  end
end

function ZVM:ReadVector3f(address)
  if address == 0 then
    return { x = 0, y = 0, z = 0, w = 0 }
  else
    return { x = self:ReadCell(address+0) or 0,
             y = self:ReadCell(address+1) or 0,
             z = self:ReadCell(address+2) or 0,
             w = 0 }
  end
end

function ZVM:ReadVector4f(address)
  if address == 0 then
    return { x = 0, y = 0, z = 0, w = 0 }
  else
    return { x = self:ReadCell(address+0) or 0,
             y = self:ReadCell(address+1) or 0,
             z = self:ReadCell(address+2) or 0,
             w = self:ReadCell(address+3) or 0 }
  end
end

function ZVM:ReadMatrix(address)
  local resultMatrix = {}
  for i= 0,15 do resultMatrix[i] = self:ReadCell(address+i) or 0 end
  return resultMatrix
end

function ZVM:WriteVector2f(address,vector)
  self:WriteCell(address+0,vector.x)
  self:WriteCell(address+1,vector.y)
end

function ZVM:WriteVector3f(address,vector)
  self:WriteCell(address+0,vector.x)
  self:WriteCell(address+1,vector.y)
  self:WriteCell(address+2,vector.z)
end

function ZVM:WriteVector4f(address,vector)
  self:WriteCell(address+0,vector.x)
  self:WriteCell(address+1,vector.y)
  self:WriteCell(address+2,vector.z)
  self:WriteCell(address+3,vector.w)
end

function ZVM:WriteMatrix(address,matrix)
  for i=0,15 do self:WriteCell(address+i,matrix[i]) end
end




--------------------------------------------------------------------------------
-- Converts integer to binary representation
function ZVM:IntegerToBinary(n)
  -- Check sign
  n = math.floor(n or 0)
  if n < 0 then
    local bits = self:IntegerToBinary(2^self.IPREC + n)
    bits[self.IPREC-1] = 1
    return bits
  end

  -- Convert to binary
  local bits = {}
  local cnt = 0
  while (n > 0) and (cnt < self.IPREC) do
    local bit = n % 2
    bits[cnt] = bit

    n = (n-bit)/2
    cnt = cnt + 1
  end

  -- Fill in missing zero bits
  while cnt < self.IPREC do
    bits[cnt] = 0
    cnt = cnt + 1
  end

  return bits
end




--------------------------------------------------------------------------------
-- Converts binary representation back to integer
function ZVM:BinaryToInteger(bits)
  local n = #bits
  local result = 0

  -- Convert to integer
  for i = 0, self.IPREC-2 do
    result = result + (bits[i] or 0) * (2 ^ i)
  end

  -- Add sign
  if bits[self.IPREC-1] == 1 then
    return -2^(self.IPREC-1)+result
  else
    return result
  end
end




--------------------------------------------------------------------------------
-- Binary OR
function ZVM:BinaryOr(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, self.IPREC-1 do
    bits[i] = math.min(1,bits_m[i]+bits_n[i])
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary AND
function ZVM:BinaryAnd(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, self.IPREC-1 do
    bits[i] = bits_m[i]*bits_n[i]
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary NOT
function ZVM:BinaryNot(n)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, self.IPREC-1 do
    bits[i] = 1-bits_n[i]
  end
  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary XOR
function ZVM:BinaryXor(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, self.IPREC-1 do
    bits[i] = (bits_m[i]+bits_n[i]) % 2
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary shift right
function ZVM:BinarySHR(n,cnt)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  local rslt = #bits_n
  for i = 0, self.IPREC-cnt-1 do
    bits[i] = bits_n[i+cnt]
  end
  for i = self.IPREC-cnt,rslt-1 do
    bits[i] = 0
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary shift left
function ZVM:BinarySHL(n,cnt)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = cnt,self.IPREC-1 do
    bits[i] = bits_n[i-cnt]
  end
  for i = 0,cnt-1 do
    bits[i] = 0
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Reset to initial state
ZVM:Reset()
