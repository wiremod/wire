-- Load shared/clientside stuff
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_spuvm.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "ZSPU"

--------------------------------------------------------------------------------
WireSPU_MaxChannels = 32

--------------------------------------------------------------------------------
function ENT:Initialize()
  -- Physics properties
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  -- Inputs/outputs
  self.Inputs = Wire_CreateInputs(self, { "Clk", "Reset", "IOBus", "SoundOut" })
  self.Outputs = Wire_CreateOutputs(self, { "Memory" })

  -- Setup platform settings
  self.Clk = 1
  self.MemBusScanAddress = 65536
  self.SerialNo = CPULib.GenerateSN("SPU")
  self:SetMemoryModel("128k",true)

  -- Create serverside memory and cache
  self.Memory = {}
  self.Cache = GPUCacheManager(self)

  -- Connected sound emitters
  self.SoundEmitters = {}

  -- Sound sources
  self.SoundSources = {}
  for i=0,WireSPU_MaxChannels-1 do
    self.SoundSources[i] = ents.Create("prop_physics")
    self.SoundSources[i]:SetParent(self)
    self.SoundSources[i]:SetModel("models/cheeze/wires/nano_math.mdl")
    self.SoundSources[i]:SetNotSolid(true)
    self.SoundSources[i]:SetPos(self:GetPos())
    self.SoundSources[i]:Spawn()
  end

  timer.Create("wire_spu_soundsources_"..math.floor(math.random()*1000000),0.1+math.random()*0.3,1,
    function()
      umsg.Start("wire_spu_soundsources")
        umsg.Long(self:EntIndex())
         for i=0,WireSPU_MaxChannels-1 do
           umsg.Long(self.SoundSources[i]:EntIndex())
         end
      umsg.End()

--      for i=0,WireSPU_MaxChannels-1 do
--        self.SoundSources[i]:SetModelScale(Vector(0))
--        self.SoundSources[i]:SetNoDraw(true)
--      end
    end)
end

function ENT:OnRemove()
  for i=0,WireSPU_MaxChannels-1 do
    self.SoundSources[i]:Remove()
  end
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
    timer.Create("wire_spu_modelupdate_"..math.floor(math.random()*1000000),0.1+math.random()*0.3,1,
      function()
        umsg.Start("wire_spu_memorymodel")
          umsg.Long(self:EntIndex())
          umsg.Long (self.RAMSize)
          umsg.Float(self.SerialNo)
          umsg.Short(self.ChipType)
        umsg.End()
      end)
  end
end


--------------------------------------------------------------------------------
-- Resend all SPU cache to newly spawned player
--------------------------------------------------------------------------------
function ENT:ResendCache(player)
  timer.Create("wire_spu_resendtimer_"..math.floor(math.random()*1000000),0.4+math.random()*1.2,1,
    function()
      self.Cache:Flush()
      for address,value in pairs(self.Memory) do
        self:WriteCell(address,value,player)
      end
      self.Cache:Flush(player)

      self:WriteCell(65534,1,player) -- Reset SPU
      self:WriteCell(65535,self.Clk,player) -- Update Clk
    end)
end

local function SPU_PlayerRespawn(player)
  for _,Entity in pairs(ents.FindByClass("gmod_wire_spu")) do
    Entity:ResendCache(player)
  end
end
hook.Add("PlayerInitialSpawn", "SPUPlayerRespawn", SPU_PlayerRespawn)
concommand.Add("wire_spu_resendcache", SPU_PlayerRespawn)


--------------------------------------------------------------------------------
-- Read cell from SPU memory
--------------------------------------------------------------------------------
function ENT:ReadCell(Address)
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
-- Write cell to SPU memory
--------------------------------------------------------------------------------
function ENT:WriteCell(Address, Value, Player)
  if (Address < 0) or (Address >= self.RAMSize) then
    return false
  else
    if (Address ~= 65535) and (Address ~= 65534) then
      -- Write to internal memory
      self.Memory[Address] = Value

      -- Add address to cache if cache is not big enough yet
      self.Cache:Write(Address,Value,Player)
      return true
    else
      self.Cache:WriteNow(Address,Value,Player)
    end
    return true
  end
end


--------------------------------------------------------------------------------
-- Write advanced dupe
--------------------------------------------------------------------------------
function ENT:BuildDupeInfo()
  local info = self.BaseClass.BuildDupeInfo(self) or {}

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
  self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

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
-- Find out all sound emitters connected to the SPU
--------------------------------------------------------------------------------
function ENT:QuerySoundEmitters(entity)
  self.QueryRecurseCounter = self.QueryRecurseCounter + 1
  if self.QueryRecurseCounter > 128 then return end
  if (not entity) or (not entity:IsValid()) then return end

  if entity:GetClass() == "gmod_wire_spu" then -- VideoOut connected to a GPU
    table.insert(self.QueryResult,entity:EntIndex())
  elseif entity.MySocket then -- VideoOut connected to a plug
    self:QuerySoundEmitters(entity.MySocket.Inputs.Memory.Src)
  elseif entity.MyPlug then -- VideoOut connected to a socket
    self:QuerySoundEmitters(entity.MyPlug.Inputs.Memory.Src)
  elseif entity.Ply and entity.Ply:IsValid() then -- VideoOut connected to pod
    table.insert(self.QueryResult,entity.Ply:EntIndex())
  elseif entity:GetClass() == "gmod_wire_addressbus" then -- VideoOut connected to address bus
    self:QuerySoundEmitters(entity.Inputs.Memory1.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory2.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory3.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory4.Src)
  elseif entity:GetClass() == "gmod_wire_extbus" then -- VideoOut connected to ext bus
    self:QuerySoundEmitters(entity.Inputs.Memory1.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory2.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory3.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory4.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory5.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory6.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory7.Src)
    self:QuerySoundEmitters(entity.Inputs.Memory8.Src)
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

  -- Flush any data in cache
  self.Cache:Flush()

  -- Update video output, and send any changes to client
  if self.Inputs.SoundOut.Src then
    self.QueryRecurseCounter = 0
    self.QueryResult = { }
    self:QuerySoundEmitters(self.Inputs.SoundOut.Src)

    -- Check if sound emitters setup has changed
    local soundEmittersChanged = false
    for k,v in pairs(self.QueryResult) do
      if self.SoundEmitters[k] ~= v then
        soundEmittersChanged = true
        break
      end
    end

    if not soundEmittersChanged then
      for k,v in pairs(self.SoundEmitters) do
        if self.QueryResult[k] ~= v then
          soundEmittersChanged = true
          break
        end
      end
    end

    if #self.QueryResult ~= #self.SoundEmitters then soundEmittersChanged = true end

    if soundEmittersChanged then
      self.SoundEmitters = self.QueryResult
    end

    -- Send update to all clients
    if soundEmittersChanged then
      umsg.Start("wire_spu_soundstate")
        umsg.Long(self:EntIndex())
        umsg.Short(#self.SoundEmitters)
        for idx=1,#self.SoundEmitters do
          umsg.Long(self.SoundEmitters[idx])
        end
      umsg.End()
    end
  end

  self:NextThink(CurTime()+0.05)
  return true
end

duplicator.RegisterEntityClass("gmod_wire_spu", WireLib.MakeWireEnt, "Data")
