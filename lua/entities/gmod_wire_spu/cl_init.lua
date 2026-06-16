include("cl_spuvm.lua")
include("shared.lua")



--------------------------------------------------------------------------------
WireSPU_MaxChannels = 32

local SoundEmitters = {}
local SoundEmitterLookup = {}
local HUDLookup = {}




--------------------------------------------------------------------------------
-- Update sound emitters certain SPU is linked to
--------------------------------------------------------------------------------
local function recalculateSoundEmitterLookup()
  SoundEmitterLookup = {}
  HUDLookup = {}
  for gpuIdx,linkedSPUs in pairs(SoundEmitters) do
    for _,linkedSPUIdx in pairs(linkedSPUs) do
      local linkedEnt = ents.GetByIndex(linkedSPUIdx)
      if linkedEnt and linkedEnt:IsValid() then
        if linkedEnt:IsPlayer() then
          HUDLookup[linkedSPUIdx] = gpuIdx
        else
          SoundEmitterLookup[linkedSPUIdx] = gpuIdx
        end
      end
    end
  end
end

local function SPU_SoundEmitterState(um)
  -- Read sound emitters for this SPU
  local gpuIdx = um:ReadLong()
  SoundEmitters[gpuIdx] = {}

  -- Fetch all sound emitters
  local count = um:ReadShort()
  for i=1,count do
    SoundEmitters[gpuIdx][i] = um:ReadLong()
  end

  -- Recalculate small lookup table for sound emitter system
  recalculateSoundEmitterLookup()
end
usermessage.Hook("wire_spu_soundstate", SPU_SoundEmitterState)

local function SPU_SoundSources(um)
  local SPU = ents.GetByIndex(um:ReadLong())
  if not SPU then return end
  if not SPU:IsValid() then return end

  for i=0,WireSPU_MaxChannels-1 do
    local soundsource = ents.GetByIndex(um:ReadLong())

    if soundsource:IsValid() then
      SPU.SoundSources[i] = soundsource
      SPU.SoundSources[i]:SetNoDraw(true)
      SPU.SoundSources[i]:SetModelScale(0,0)
    end
  end

  -- Reset VM
  SPU.VM:Reset()
  SPU.VM.Memory[65535] = 1
  SPU.VM.Memory[65527] = 300000
end
usermessage.Hook("wire_spu_soundsources", SPU_SoundSources)




--------------------------------------------------------------------------------
-- Update SPU features/memory model
--------------------------------------------------------------------------------
local function SPU_MemoryModel(um)
  local SPU = ents.GetByIndex(um:ReadLong())
  if not SPU then return end
  if not SPU:IsValid() then return end

  if SPU.VM then
    SPU.VM.ROMSize = um:ReadLong()
    SPU.VM.SerialNo = um:ReadFloat()
    SPU.VM.RAMSize = SPU.VM.ROMSize
  else
    SPU.ROMSize = um:ReadLong()
    SPU.SerialNo = um:ReadFloat()
  end
  SPU.ChipType = um:ReadShort()
end
usermessage.Hook("wire_spu_memorymodel", SPU_MemoryModel)

local function SPU_SetExtensions(um)
  local SPU = ents.GetByIndex(um:ReadLong())
  if not SPU then return end
  if not SPU:IsValid() then return end
  local extstr = um:ReadString()
  local extensions = CPULib:FromExtensionString(extstr,"SPU")
  if SPU.VM then
    SPU.VM.Extensions = extensions
    CPULib:LoadExtensions(SPU.VM,"SPU")
  end
  SPU.ZVMExtensions = extstr
end
usermessage.Hook("wire_spu_extensions", SPU_SetExtensions)



--------------------------------------------------------------------------------
function ENT:Initialize()
  -- Create virtual machine
  self.VM = CPULib.VirtualMachine()
  self.VM.SerialNo = CPULib.GenerateSN("SPU")
  self.VM.RAMSize = 65536
  self.VM.ROMSize = 65536
  self.VM.PCAP    = 0
  self.VM.RQCAP   = 0
  self.VM.CPUVER  = 1.0 -- Beta SPU by default
  self.VM.CPUTYPE = 2 -- ZSPU
  self.ChipType   = 0
  self.VM.Extensions = CPULib:FromExtensionString(self.ZVMExtensions,"SPU")

  -- Create fake sound sources
  self.SoundSources = {}

  -- Hard-reset VM and override it
  self:OverrideVM()
  self.VMReset = 0

  -- Setup caching
  GPULib.ClientCacheCallback(self,function(Address,Value)
    self.VM:WriteCell(Address,Value)
    self.VM.ROM[Address] = Value
  end)
end




--------------------------------------------------------------------------------
-- Entity deleted
function ENT:OnRemove()
  GPULib.ClientCacheCallback(self,nil)
  if self.VM.Channel then
    for k,v in pairs(self.VM.Channel) do
      v.Sound:Stop()
    end
  end
end




--------------------------------------------------------------------------------
-- Run SPU execution
function ENT:Run()
  -- Limit frequency
  self.VM.Memory[65527] = math.Clamp(self.VM.Memory[65527],1,1200000)

  -- Calculate timing
  local Cycles = math.max(1,math.floor(self.VM.Memory[65527]*self.DeltaTime*0.5))
  self.VM.TimerDT = self.DeltaTime/Cycles
  self.VM.TIMER = self.CurrentTime

  -- Run until interrupt, or if async thread then until async thread stops existing
  while (Cycles > 0) and (self.VM.INTR == 0) do
    local previousTMR = self.VM.TMR
    self.VM.QuotaSupported = 1
    self.VM.Quota = self.VM.TMR+Cycles
    if self.VM.QuotaOverrunFunc then
      self.VM:QuotaOverrunFunc()
    else
      self.VM:Step()
    end
    self.QuotaSupported = 0
    Cycles = Cycles - (self.VM.TMR - previousTMR)
  end

  -- Reset INTR register for async thread
  self.VM.INTR = 0
end

--------------------------------------------------------------------------------
-- Think function
function ENT:Think()
  -- Calculate time-related variables
  self.CurrentTime = CurTime()
  self.DeltaTime = math.min(1/30,self.CurrentTime - (self.PreviousTime or 0))
  self.PreviousTime = self.CurrentTime

  -- Dont run until all sound sources are init
  if #self.SoundSources == 0 then return end

  -- Run asynchronous thread
  if self.VM.Memory[65535] == 1 then
    self:Run()
    -- Calculate ADSR
    self.VM:CalculateADSR(self.DeltaTime)
  end
end
