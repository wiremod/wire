-- Load shared/clientside stuff
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "ZCPU"


--------------------------------------------------------------------------------
function ENT:Initialize()
  -- Physics properties
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  -- Inputs/outputs
  self.Inputs = Wire_CreateInputs(self.Entity, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "Interrupt"})
  self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" })

  -- CPU platform settings
  self.Clk = 0
  self.Frequency = 2000

  -- Create virtual machine
  self.VM = CPULib.VirtualMachine()
  self.VM.SerialNo = CPULib.GenerateSN("CPU")
  self.VM:Reset()

  self:SetCPUName()
  self:SetMemoryModel("64krom")
  self.VM.SignalError = function(VM,errorCode)
    Wire_TriggerOutput(self, "Error", errorCode)
  end
  self.VM.SignalShutdown = function(VM)
    self.Clk = 0
  end
  self.VM.ExternalWrite = function(VM,Address,Value)
    if Address >= 0 then -- Use MemBus
      local MemBusSource = self.Inputs.MemBus.Src
      if MemBusSource then
        if MemBusSource.ReadCell then
          local result = MemBusSource:WriteCell(Address-self.VM.RAMSize,Value)
          if result then return true
          else VM:Interrupt(7,Address) return false end
        else VM:Interrupt(8,Address) return false end
      else VM:Interrupt(7,Address) return false end
    else -- Use IOBus
      local IOBusSource = self.Inputs.IOBus.Src
      if IOBusSource then
        if IOBusSource.ReadCell then
          local result = IOBusSource:WriteCell(-Address-1,Value)
          if result then return true
          else VM:Interrupt(10,-Address-1) return false end
        else VM:Interrupt(8,Address+1) return false end
      else return true end
    end
  end
  self.VM.ExternalRead = function(VM,Address)
    if Address >= 0 then -- Use MemBus
      local MemBusSource = self.Inputs.MemBus.Src
      if MemBusSource then
        if MemBusSource.ReadCell then
          local result = MemBusSource:ReadCell(Address-self.VM.RAMSize)
          if result then return result
          else VM:Interrupt(7,Address) return end
        else VM:Interrupt(8,Address) return end
      else VM:Interrupt(7,Address) return end
    else -- Use IOBus
      local IOBusSource = self.Inputs.IOBus.Src
      if IOBusSource then
        if IOBusSource.ReadCell then
          local result = IOBusSource:ReadCell(-Address-1)
          if result then return result
          else VM:Interrupt(10,-Address-1) return end
        else VM:Interrupt(8,Address+1) return end
      else return 0 end
    end
  end

  -- Player that debugs the processor
  self.DebuggerPlayer = nil
end


--------------------------------------------------------------------------------
-- Highspeed link support
--------------------------------------------------------------------------------
function ENT:ReadCell(Address)
  return self.VM:ReadCell(Address)
end

function ENT:WriteCell(Address,Value)
  return self.VM:WriteCell(Address,tonumber(Value) or 0)
end


--------------------------------------------------------------------------------
-- Set memory model
--------------------------------------------------------------------------------
local memoryModels = {
  ["64krom"]  = {  65536, 65536  },
  ["64k"]     = {  65536, 0      },
  ["128krom"] = { 131072, 131072 },
  ["128rom"]  = {      0, 128    },
  ["128"]     = {    128, 128    },
  ["flat"]    = {      0, 0      },
}

function ENT:SetMemoryModel(model)
  self.VM.RAMSize = memoryModels[model][1] or 65536
  self.VM.ROMSize = memoryModels[model][2] or 65536
end


--------------------------------------------------------------------------------
-- Execute ZCPU virtual machine
--------------------------------------------------------------------------------
function ENT:Run()
  -- Do not run if debugging is active
  if self.DebuggerPlayer then return end

  -- Calculate time-related variables
  local CurrentTime = CurTime()
  local DeltaTime = math.min(1/30,CurrentTime - (self.PreviousTime or 0))
  self.PreviousTime = CurrentTime

  -- Check if need to run till specific instruction
  if self.BreakpointInstructions then
    self.VM.TimerDT = DeltaTime
    self.VM.CPUIF = self
    self.VM:Step(8,function(self)
--      self:Emit("VM.IP = "..(self.PrecompileIP or 0))
--      self:Emit("VM.XEIP = "..(self.PrecompileTrueXEIP or 0))

      self:Dyn_Emit("if (VM.CPUIF.Clk == 1) and (VM.CPUIF.OnVMStep) then")
        self:Dyn_EmitState()
        self:Emit("VM.CPUIF.OnVMStep()")
      self:Emit("end")
      self:Emit("if VM.CPUIF.BreakpointInstructions[VM.IP] then")
        self:Dyn_EmitState()
        self:Emit("VM.CPUIF.OnBreakpointInstruction(VM.IP)")
        self:Emit("VM.CPUIF.Clk = 0")
        self:Emit("VM.TMR = VM.TMR + "..self.PrecompileInstruction)
        self:Emit("VM.CODEBYTES = VM.CODEBYTES + "..self.PrecompileBytes)
        self:Emit("if true then return end")
      self:Emit("end")
      self:Emit("if VM.CPUIF.LastInstruction and ((VM.IP > VM.CPUIF.LastInstruction) or VM.CPUIF.ForceLastInstruction) then")
        self:Dyn_EmitState()
        self:Emit("VM.CPUIF.ForceLastInstruction = nil")
        self:Emit("VM.CPUIF.OnLastInstruction()")
        self:Emit("VM.CPUIF.Clk = 0")
        self:Emit("VM.TMR = VM.TMR + "..self.PrecompileInstruction)
        self:Emit("VM.CODEBYTES = VM.CODEBYTES + "..self.PrecompileBytes)
        self:Emit("if true then return end")
      self:Emit("end")
    end)
    self.VM.CPUIF = nil
  else
    -- How many steps VM must make to keep up with execution
    local Cycles = math.max(1,math.floor(self.Frequency*DeltaTime*0.5))
    self.VM.TimerDT = (DeltaTime/Cycles)

    while (Cycles > 0) and (self.Clk > 0) and (self.VM.Idle == 0) do
      -- Run VM step
      local previousTMR = self.VM.TMR
      self.VM:Step()
      Cycles = Cycles - (self.VM.TMR - previousTMR)
    end
  end

  -- Update VM timer
  self.VM.TIMER = self.VM.TIMER + DeltaTime

  -- Reset idle register
  self.VM.Idle = 0
end


--------------------------------------------------------------------------------
-- Think loop
--------------------------------------------------------------------------------
function ENT:Think()
  self:Run()
  if self.Clk >= 1.0 then self.Entity:NextThink(CurTime()) end
  return true
end


--------------------------------------------------------------------------------
-- Write data to RAM and then flash ROM if required
--------------------------------------------------------------------------------
function ENT:FlashData(data)
  self.VM:Reset()
  for k,v in pairs(data) do
    self.VM:WriteCell(k,tonumber(v) or 0)
    if (k >= 0) and (k < self.VM.ROMSize) then
      self.VM.ROM[k] = tonumber(v) or 0
    end
  end
end


--------------------------------------------------------------------------------
-- Update CPU name
--------------------------------------------------------------------------------
function ENT:SetCPUName(name)
  local overlayStr = ""
  if name and (name ~= "") then
    self:SetOverlayText(string.format("%s\nS/N %d",name,self.VM.SerialNo))
  else
    self:SetOverlayText(string.format("Zyelios CPU\nS/N %d",self.VM.SerialNo))
  end
  self.CPUName = name
end


--------------------------------------------------------------------------------
-- Write advanced dupe
--------------------------------------------------------------------------------
function ENT:BuildDupeInfo()
  local info = self.BaseClass.BuildDupeInfo(self) or {}

  info.SerialNo = self.VM.SerialNo
  info.InternalRAMSize = self.VM.RAMSize
  info.InternalROMSize = self.VM.ROMSize
  info.CPUName         = self.CPUName

  if self.VM.ROMSize > 0 then
    info.Memory = {}
    for k,v in pairs(self.VM.ROM) do if v ~= 0 then info.Memory[k] = v end end
  end

  return info
end


--------------------------------------------------------------------------------
-- Read from advanced dupe
--------------------------------------------------------------------------------
function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
  -- Compatibility with old NMI input
  if info.Wires and info.Wires.NMI then
    info.Wires.Interrupt = info.Wires.NMI
    info.Wires.NMI = nil
  end

  self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

  self.VM.SerialNo = info.SerialNo or CPULib.GenerateSN("UNK")
  self.VM.RAMSize  = info.InternalRAMSize or 65536
  self.VM.ROMSize  = info.InternalROMSize or 65536
  self:SetCPUName(info.CPUName)

  if info.Memory then--and
     --(((info.UseROM) and (info.UseROM == true)) or
     -- ((info.InternalROMSize) and (info.InternalROMSize > 0))) then
    self.VM.ROM = {}
    for k,v in pairs(info.Memory) do self.VM.ROM[k] = tonumber(v) or 0 end
    self.VM:Reset()
  end
end


--------------------------------------------------------------------------------
-- Handle external input
--------------------------------------------------------------------------------
function ENT:TriggerInput(iname, value)
      if iname == "Clk" then
    self.Clk = value
    if self.Clk >= 1.0 then self.Entity:NextThink(CurTime()) end
  elseif iname == "Frequency" then
    if (not game.SinglePlayer()) and (value > 1400000) then self.Frequency = 1400000 return end
    if value > 0 then self.Frequency = math.floor(value) end
  elseif iname == "Reset" then   --VM may be nil
    if self.VM.HWDEBUG ~= 0 then
      self.VM.DBGSTATE = math.floor(value)
      if (value > 0) and (value <= 1.0) then self.VM:Reset() end
    else
      if value >= 1.0 then self.VM:Reset() end
    end
    Wire_TriggerOutput(self, "Error", 0)
  elseif iname == "Interrupt" then
    if (value >= 32) && (value < 256) then
      if (self.Clk >= 1.0) then self.VM:ExternalInterrupt(math.floor(value)) end
    end
  end
end
