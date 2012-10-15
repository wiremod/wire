AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "AddressBus"

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetUseType(SIMPLE_USE)
  self.Outputs = Wire_CreateOutputs(self, {"Memory"})
  self.Inputs = Wire_CreateInputs(self,{"Memory1","Memory2","Memory3","Memory4"})
  self.DataRate = 0
  self.DataBytes = 0

  self.Memory = {}
  self.MemStart = {}
  self.MemEnd = {}
  for i = 1,4 do
    self.Memory[i] = nil
    self.MemStart[i] = 0
    self.MemEnd[i] = 0
  end
  self:SetOverlayText("Data rate: 0 bps")
end

function ENT:Think()
  self.BaseClass.Think(self)

  self.DataRate = self.DataBytes
  self.DataBytes = 0

  Wire_TriggerOutput(self, "Memory", self.DataRate)
  self:SetOverlayText("Data rate: "..math.floor(self.DataRate*2).." bps")
  self:NextThink(CurTime()+0.5)
end

function ENT:ReadCell(Address)
  for i = 1,4 do
    if (Address >= self.MemStart[i]) and (Address <= self.MemEnd[i]) then
      if self.Memory[i] then
        if self.Memory[i].ReadCell then
          self.DataBytes = self.DataBytes + 1
          local val = self.Memory[i]:ReadCell(Address - self.MemStart[i])
          return val or 0
        end
      else
        return 0
      end
    end
  end
  return nil
end

function ENT:WriteCell(Address, value)
  local res = false
  for i = 1,4 do
    if (Address >= self.MemStart[i]) and (Address <= self.MemEnd[i]) then
      if self.Memory[i] then
        if self.Memory[i].WriteCell then
          self.Memory[i]:WriteCell(Address - self.MemStart[i], value)
        end
      end
      self.DataBytes = self.DataBytes + 1
      res = true
    end
  end
  return res
end


function ENT:TriggerInput(iname, value)
  for i = 1,4 do
    if iname == "Memory"..i then
          self.Memory[i] = self.Inputs["Memory"..i].Src
    end
  end
end
