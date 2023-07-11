AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Extended Bus"
ENT.WireDebugName = "Extended Bus"

if CLIENT then return end -- No more client

function ENT:Initialize()
  self:PhysicsInit( SOLID_VPHYSICS)
  self:SetMoveType( MOVETYPE_VPHYSICS)
  self:SetSolid( SOLID_VPHYSICS)
  self:SetUseType( SIMPLE_USE)
  self.Outputs = Wire_CreateOutputs(self, {"Memory"})
  self.Inputs = Wire_CreateInputs(self,{"Memory1","Memory2","Memory3","Memory4","Memory5","Memory6","Memory7","Memory8"})

  self.DataRate = 0
  self.DataBytes = 0
  self.PerformRecursiveScan = 1
  self.ControlDataSize = 32
  self.ControlData = {}

  self.Memory = {}
  self.MemStart = {}
  self.MemEnd = {}
  for i = 1,8 do
    self.Memory[i] = nil
    self.MemStart[i] = 0
    self.MemEnd[i] = 0
  end
  self:SetOverlayText("Data rate: 0 bps")
end

function ENT:Think()
  BaseClass.Think(self)

  self.DataRate = self.DataBytes
  self.DataBytes = 0

  Wire_TriggerOutput(self, "Memory", self.DataRate)
  self:SetOverlayText("Data rate: "..math.floor(self.DataRate*2).." bps")
  self:NextThink(CurTime()+0.5)
end

function ENT:ReadCell(Address)
  Address = math.floor(Address)
  if (Address >= 0) and (Address < self.ControlDataSize) then
    if Address < 16 then
      if Address % 2 == 0 then
        return self.MemStart[Address/2+1]
      else
        return self.MemEnd[(Address-1)/2+1]
      end
    elseif Address == 16 then
      return self.ControlDataSize
    elseif Address == 18 then
      return self.DataRate
	elseif Address == 20 then
	  return self.PerformRecursiveScan
    elseif Address >= 32 then
      return self.ControlData[Address-31] or 0
    end
    return 0
  else
    for i = 1,8 do
      if (Address-self.ControlDataSize >= self.MemStart[i]) and
         (Address-self.ControlDataSize <= self.MemEnd[i]) then
        if self.Memory[i] then
          if self.Memory[i].ReadCell then
            self.DataBytes = self.DataBytes + 1
            local val = self.Memory[i]:ReadCell(Address-self.ControlDataSize-self.MemStart[i])
            return val or 0
          end
        else
          return 0
        end
      end
    end
  end
  return nil
end

local DeviceType = {
  ["gmod_wire_extbus"]        = 2,
  ["gmod_wire_addressbus"]    = 3,
  ["gmod_wire_cpu"]           = 4,
  ["gmod_wire_gpu"]           = 5,
  ["gmod_wire_spu"]           = 6,
  ["gmod_wire_hdd"]           = 7,
  ["gmod_wire_dhdd"]          = 8,
  ["gmod_wire_datarate"]      = 9,
  ["gmod_wire_cd_ray"]        = 10,
  ["gmod_wire_consolescreen"] = 11,
  ["gmod_wire_digitalscreen"] = 12,
  ["gmod_wire_dataplug"]      = 13,
  ["gmod_wire_datasocket"]    = 14,
  ["gmod_wire_keyboard"]      = 15,
  ["gmod_wire_oscilloscope"]  = 16,
  ["gmod_wire_soundemitter"]  = 17,
  ["gmod_wire_value"]         = 18,
  ["gmod_wire_dataport"]      = 19,
  ["gmod_wire_gate"]          = 20,
}

local function getDeviceType(class)
  return DeviceType[class] or 1
end

local recursiveCounter = 0
function ENT:GetDeviceInfo(deviceEnt)
  local deviceType = getDeviceType(deviceEnt:GetClass())
  if deviceEnt.Socket then
    if deviceEnt.Socket.Inputs.Memory.Src then
      self:GetDeviceInfo(deviceEnt.Socket.Inputs.Memory.Src)
    else
      table.insert(self.ControlData,14)
    end
    return
  elseif deviceEnt.Plug then
    if deviceEnt.Plug.Inputs.Memory.Src then
      self:GetDeviceInfo(deviceEnt.Plug.Inputs.Memory.Src)
    else
      table.insert(self.ControlData,13)
    end
    return
  end

  table.insert(self.ControlData,deviceType)

  if self.PerformRecursiveScan >= 1 then
    recursiveCounter = recursiveCounter + 1
    if recursiveCounter < 256 then
      if (deviceEnt:GetClass() == "gmod_wire_addressbus") or
         (deviceEnt:GetClass() == "gmod_wire_extbus") then
        for i = 1,8 do
          if deviceEnt.Memory[i] then
            self:GetDeviceInfo(deviceEnt.Memory[i])
          else
            table.insert(self.ControlData,0)
          end
        end
      end
    end
  end
end

function ENT:WriteCell(Address, Value)
  Address = math.floor(Address)
  if (Address >= 0) and (Address < self.ControlDataSize) then
    -- [0..15] Address bus settings
    -- [16] Control data area size
    -- [17] Write to request device info
    -- [18] Data transfer rate
    -- [19] Override returned device type (0: no override)
    -- [20] Perform recursive scan
    -- [32..] Device types
    if Address < 16 then
      if Address % 2 == 0 then
        self.MemStart[Address/2+1] = math.floor(Value)
      else
        self.MemEnd[(Address-1)/2+1] = math.floor(Value)
      end
    elseif Address == 16 then
      self.ControlDataSize = math.max(32,math.floor(Value))
    elseif Address == 17 then
      recursiveCounter = 0
      self.ControlData = {}
      for i = 1,8 do
        if self.Memory[i] then
          self:GetDeviceInfo(self.Memory[i])
        else
          table.insert(self.ControlData,0)
        end
      end
    elseif Address == 20 then
      self.PerformRecursiveScan = Value
    end
    return true
  else
    local res = false
    for i = 1,8 do
      if (Address-self.ControlDataSize >= self.MemStart[i]) and
         (Address-self.ControlDataSize <= self.MemEnd[i]) then
        if self.Memory[i] then
          if self.Memory[i].WriteCell then
            self.Memory[i]:WriteCell(Address-self.ControlDataSize-self.MemStart[i], Value)
          end
        end
        self.DataBytes = self.DataBytes + 1
        res = true
      end
    end
    return res
  end
end

function ENT:TriggerInput(iname, value)
  for i = 1,8 do
    if iname == "Memory"..i then
          self.Memory[i] = self.Inputs["Memory"..i].Src
    end
  end
end

duplicator.RegisterEntityClass("gmod_wire_extbus", WireLib.MakeWireEnt, "Data")
