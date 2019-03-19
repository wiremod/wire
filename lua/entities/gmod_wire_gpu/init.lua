-- Load shared/clientside stuff
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_gpuvm.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

DEFINE_BASECLASS("base_wire_entity")

ENT.WireDebugName = "ZGPU"


--------------------------------------------------------------------------------
function ENT:Initialize()
  -- Physics properties
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  -- Inputs/outputs
  self.Inputs = Wire_CreateInputs(self, { "Clk", "Reset", "IOBus", "MemBus", "VideoOut" })
  self.Outputs = Wire_CreateOutputs(self, { "Memory" })

  -- Setup platform settings
  self.Clk = 1
  self.MemBusScanAddress = 65536
  self.SerialNo = CPULib.GenerateSN("GPU")
  self:SetMemoryModel("64k",true)

  -- Create serverside memory and cache
  self.Memory = {}
  self.Cache = GPUCacheManager(self)

  -- Connected monitors
  self.Monitors = { }
  self:UpdateClientMonitorState()
end

function ENT:UpdateClientMonitorState()
  umsg.Start("wire_gpu_monitorstate")
    umsg.Long(self:EntIndex())
    umsg.Short(#self.Monitors)
    for idx=1,#self.Monitors do
      umsg.Long(self.Monitors[idx])
    end
  umsg.End()
end
--------------------------------------------------------------------------------
-- Set processor
--------------------------------------------------------------------------------
function ENT:SetMemoryModel(model,initial)
  if model then
    for i=6,11 do
      if model == (2^i).."k" then
        self.RAMSize = (2^i)*1024
        self.ChipType = 0
      elseif model == (2^i).."kc" then
        self.RAMSize = (2^i)*1024
        self.ChipType = 1
      end
    end
  end

  if not initial then
    timer.Create("wire_gpu_modelupdate_"..math.floor(math.random()*1000000),0.1+math.random()*0.3,1,
      function()
        umsg.Start("wire_gpu_memorymodel")
          umsg.Long(self:EntIndex())
          umsg.Long (self.RAMSize)
          umsg.Float(self.SerialNo)
          umsg.Short(self.ChipType)
        umsg.End()
      end)
  end
end


--------------------------------------------------------------------------------
-- Resend all GPU cache to newly spawned player
--------------------------------------------------------------------------------
function ENT:ResendCache(player)
  timer.Create("wire_gpu_resendtimer_"..math.floor(math.random()*1000000),0.4+math.random()*1.2,1,
    function()
      self.Cache:Flush()
      for address,value in pairs(self.Memory) do
        self:WriteCell(address,value,player)
      end
      self.Cache:Flush(player)

      self:WriteCell(65534,1,player) -- Reset GPU
      self:WriteCell(65535,self.Clk,player) -- Update Clk
    end)
end

local function GPU_PlayerRespawn(player)
  for _,Entity in pairs(ents.FindByClass("gmod_wire_gpu")) do
    Entity:ResendCache(player)
  end
end
hook.Add("PlayerInitialSpawn", "GPUPlayerRespawn", GPU_PlayerRespawn)
concommand.Add("wire_gpu_resendcache", GPU_PlayerRespawn)



--------------------------------------------------------------------------------
-- Checks if address is valid
--------------------------------------------------------------------------------
local function isValidAddress(n)
  return n and (math.floor(n) == n) and (n >= -140737488355327) and (n <= 140737488355328)
end



--------------------------------------------------------------------------------
-- Read cell from GPU memory
--------------------------------------------------------------------------------
function ENT:ReadCell(Address)
  Address = math.floor(Address)
  -- Check if address is valid
  if not isValidAddress(Address) then
    self:Interrupt(15,Address)
    return
  end

  if (Address < 0) or (Address >= self.RAMSize) then
    return nil
  else
    if self.Memory[Address] then
      return self.Memory[Address]
    else
      return 0
    end
  end
end


--------------------------------------------------------------------------------
-- Write cell to GPU memory
--------------------------------------------------------------------------------
function ENT:WriteCell(Address, Value, Player)
  Address = math.floor(Address)
  if (Address < 0) or (Address >= self.RAMSize) then
    return false
  else
    if (Address ~= 65535) and (Address ~= 65534) and (Address ~= 65502) then
      -- Write to internal memory
      self.Memory[Address] = Value

      -- Add address to cache if cache is not big enough yet
      self.Cache:Write(Address,Value,Player)
      return true
    else
      self.Cache:Flush(Player)
      self.Cache:WriteNow(Address,Value,Player)
    end
    return true
  end
end



--------------------------------------------------------------------------------
-- Use key support
--------------------------------------------------------------------------------
function ENT:Use(player)
--
end


--------------------------------------------------------------------------------
-- Write advanced dupe
--------------------------------------------------------------------------------
function ENT:BuildDupeInfo()
  local info = BaseClass.BuildDupeInfo(self) or {}

  info.SerialNo = self.SerialNo
  info.RAMSize = self.RAMSize
  info.ChipType = self.ChipType
  info.Memory = {}

  for address = 0,self.RAMSize-1 do
    if self.Memory[address] and (self.Memory[address] ~= 0) then info.Memory[address] = self.Memory[address] end
  end

  return info
end


--------------------------------------------------------------------------------
-- Read from advanced dupe
--------------------------------------------------------------------------------
function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
  BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

  self.SerialNo = info.SerialNo or 999999
  self.RAMSize  = info.RAMSize or 65536
  self.ChipType = info.ChipType or 0
  self.Memory = {}

  for address = 0,self.RAMSize-1 do
    if info.Memory[address] then self.Memory[address] = tonumber(info.Memory[address]) or 0 end
  end

  self:SetMemoryModel()
  self:ResendCache(nil)
end


--------------------------------------------------------------------------------
-- Handle external input
--------------------------------------------------------------------------------
function ENT:TriggerInput(iname, value)
  if iname == "Clk" then
    self.Clk = (value >= 1 and 1 or 0)
    self:WriteCell(65535,self.Clk)
  elseif iname == "Reset" then
    if value >= 1.0 then self:WriteCell(65534,1) end
  end
end


--------------------------------------------------------------------------------
-- Find out all monitors connected to the GPU
--------------------------------------------------------------------------------
function ENT:QueryMonitors(entity)
  self.QueryRecurseCounter = self.QueryRecurseCounter + 1
  if self.QueryRecurseCounter > 128 then return end
  if (not entity) or (not entity:IsValid()) then return end

  if entity:GetClass() == "gmod_wire_gpu" then -- VideoOut connected to a GPU
    table.insert(self.QueryResult,entity:EntIndex())
  elseif entity.Socket then -- VideoOut connected to a plug
    self:QueryMonitors(entity.Socket.Inputs.Memory.Src)
  elseif entity.Plug then -- VideoOut connected to a socket
    self:QueryMonitors(entity.Plug.Inputs.Memory.Src)
  elseif entity.Ply and entity.Ply:IsValid() then -- VideoOut connected to pod
    table.insert(self.QueryResult,entity.Ply:EntIndex())
  elseif entity:GetClass() == "gmod_wire_addressbus" then -- VideoOut connected to address bus
    self:QueryMonitors(entity.Inputs.Memory1.Src)
    self:QueryMonitors(entity.Inputs.Memory2.Src)
    self:QueryMonitors(entity.Inputs.Memory3.Src)
    self:QueryMonitors(entity.Inputs.Memory4.Src)
  elseif entity:GetClass() == "gmod_wire_extbus" then -- VideoOut connected to ext bus
    self:QueryMonitors(entity.Inputs.Memory1.Src)
    self:QueryMonitors(entity.Inputs.Memory2.Src)
    self:QueryMonitors(entity.Inputs.Memory3.Src)
    self:QueryMonitors(entity.Inputs.Memory4.Src)
    self:QueryMonitors(entity.Inputs.Memory5.Src)
    self:QueryMonitors(entity.Inputs.Memory6.Src)
    self:QueryMonitors(entity.Inputs.Memory7.Src)
    self:QueryMonitors(entity.Inputs.Memory8.Src)
  end
end


--------------------------------------------------------------------------------
-- Update cache and external connections
--------------------------------------------------------------------------------
function ENT:Think()
  -- Update IOBus
  if self.Inputs.IOBus.Src then
    -- Was there any update in that that would require flushing
    local DataUpdated = false

    -- Update any cells that must be updated
    for port = 0,1023 do
      if self.Inputs.IOBus.Src.ReadCell then
        local var = self.Inputs.IOBus.Src:ReadCell(port)
        if var then
          if self:ReadCell(port+63488) ~= var then
            self:WriteCell(port+63488,var)
            DataUpdated = true
          end
        end
      end
    end

    -- Flush updated data
    if DataUpdated then self.Cache:Flush() end
  end

  -- Update MemBus
  if self.Inputs.MemBus.Src then
    for address=self.MemBusScanAddress,self.MemBusScanAddress+1023 do
      local var = self.Inputs.MemBus.Src:ReadCell(address-65536)
      if var then
        if self:ReadCell(address) ~= var then
          self:WriteCell(address,var)
        end
      end
    end
    self.MemBusScanAddress = self.MemBusScanAddress + 1024
    if self.MemBusScanAddress >= 131072 then
      self.MemBusScanAddress = 65536
    end
  end

  -- Flush any data in cache
  self.Cache:Flush()

  -- Update video output, and send any changes to client
  if self.Inputs.VideoOut.Src then
    self.QueryRecurseCounter = 0
    self.QueryResult = { }
    self:QueryMonitors(self.Inputs.VideoOut.Src)

    -- Check if monitors setup has changed
    local monitorsChanged = false
    for k,v in pairs(self.QueryResult) do
      if self.Monitors[k] ~= v then
        monitorsChanged = true
        break
      end
    end

    if not monitorsChanged then
      for k,v in pairs(self.Monitors) do
        if self.QueryResult[k] ~= v then
          monitorsChanged = true
          break
        end
      end
    end

    if #self.QueryResult ~= #self.Monitors then monitorsChanged = true end

    if monitorsChanged then
      self.Monitors = self.QueryResult
    end

    -- Send update to all clients
    if monitorsChanged then
      self:UpdateClientMonitorState()
    end
  end

  -- Update serverside cursor
  local model = self:GetModel()
  local monitor = WireGPU_Monitors[model]
  local ang = self:LocalToWorldAngles(monitor.rot)
  local pos = self:LocalToWorld(monitor.offset)

  for _,player in pairs(player.GetAll()) do
    local trace = player:GetEyeTraceNoCursor()
    local ent = trace.Entity
    if ent:IsValid() then
      local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*(-16384)
      dist = math.max(dist, trace.Fraction*16384-ent:BoundingRadius())

      if dist < 64 and ent == self then
        if player:KeyDown(IN_ATTACK) or player:KeyDown(IN_USE) then
          self:WriteCell(65502,1)
        end
        local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)
        local cx = 0.5+cpos.x/(monitor.RS*(512/monitor.RatioX))
        local cy = 0.5-cpos.y/(monitor.RS*(512))

        self.Memory[65505] = cx
        self.Memory[65504] = cy
      end
    end
  end

  self:NextThink(CurTime()+0.05)
  return true
end


--------------------------------------------------------------------------------
-- GPU-to-MemBus support
--------------------------------------------------------------------------------
concommand.Add("wgm", function(player, command, args)
  -- Find the referenced GPU
  local GPU = ents.GetByIndex(args[1])
  if not GPU then return end
  if not GPU:IsValid() then return end

  -- Must be a valid GPU, and belong to the caller
--  if GPU.player ~= player then return end

  -- Write on membus
  local Address = tonumber(args[2]) or 0
  local Value = tonumber(args[3]) or 0

  -- Perform external write
  if GPU.Inputs.MemBus.Src then
    GPU.Inputs.MemBus.Src:WriteCell(Address-65536,Value)
  end
end)

duplicator.RegisterEntityClass("gmod_wire_gpu", WireLib.MakeWireEnt, "Data")
