include("cl_gpuvm.lua")
include("shared.lua")

local Monitors = {}
local MonitorLookup = {}
local HUDLookup = {}

--------------------------------------------------------------------------------
-- Update monitors certain GPU is linked to
--------------------------------------------------------------------------------
local function recalculateMonitorLookup()
  MonitorLookup = {}
  HUDLookup = {}
  for gpuIdx,linkedGPUs in pairs(Monitors) do
    for _,linkedGPUIdx in pairs(linkedGPUs) do
      local linkedEnt = ents.GetByIndex(linkedGPUIdx)
      if linkedEnt and linkedEnt:IsValid() then
        if linkedEnt:IsPlayer() then
          HUDLookup[linkedGPUIdx] = gpuIdx
        else
          MonitorLookup[linkedGPUIdx] = gpuIdx
        end
      end
    end
  end
end

local function GPU_MonitorState(um)
  -- Read monitors for this GPU
  local gpuIdx = um:ReadLong()
  Monitors[gpuIdx] = {}

  -- Fetch all monitors
  local count = um:ReadShort()
  for i=1,count do
    Monitors[gpuIdx][i] = um:ReadLong()
  end

  -- Recalculate small lookup table for monitor system
  recalculateMonitorLookup()
end
usermessage.Hook("wire_gpu_monitorstate", GPU_MonitorState)


--------------------------------------------------------------------------------
-- Update GPU features/memory model
--------------------------------------------------------------------------------
local function GPU_MemoryModel(um)
  local GPU = ents.GetByIndex(um:ReadLong())
  if not GPU then return end
  if not GPU:IsValid() then return end

  if GPU.VM then
    GPU.VM.ROMSize = um:ReadLong()
    GPU.VM.SerialNo = um:ReadFloat()
    GPU.VM.RAMSize = GPU.VM.ROMSize
  else
    GPU.ROMSize = um:ReadLong()
    GPU.SerialNo = um:ReadFloat()
  end
  GPU.ChipType = um:ReadShort()
end
usermessage.Hook("wire_gpu_memorymodel", GPU_MemoryModel)

local wire_gpu_frameratio = CreateClientConVar("wire_gpu_frameratio",4)

function ENT:Initialize()
  -- Create virtual machine
  self.VM = CPULib.VirtualMachine()
  self.VM.SerialNo = CPULib.GenerateSN("GPU")
  self.VM.RAMSize = 65536
  self.VM.ROMSize = 65536
  self.VM.PCAP    = 0
  self.VM.RQCAP   = 0
  self.VM.CPUVER  = 1.0 -- Beta GPU by default
  self.VM.CPUTYPE = 1 -- ZGPU
  self.ChipType   = 0

  -- Hard-reset VM and override it
  self:OverrideVM()
  self.VM:HardReset()

  -- Special variables
  self.VM.CurrentBuffer = 2
  self.VM.LastBuffer = 2
  self.VM.RenderEnable = 0
  self.VM.VertexMode = 0
  self.VM.MemBusBuffer = {}
  self.VM.MemBusCount = 0

  -- Create GPU
  self.GPU = WireGPU(self)
  self.In3D2D = false
  self.In2D = false

  -- Setup caching
  GPULib.ClientCacheCallback(self,function(Address,Value)
    self.VM:WriteCell(Address,Value)
    self.VM.ROM[Address] = Value
  end)

  -- Draw outlines in chip mode
  local tempDrawOutline = self.DrawEntityOutline
  self.DrawEntityOutline = function(self) if self.ChipType ~= 0 then tempDrawOutline(self) end end
end

-- Assert that sprite buffer exists and is available for any operations on it
function ENT:AssertSpriteBufferExists()
  if not self.SpriteGPU then self.SpriteGPU = WireGPU(self) end
end




--------------------------------------------------------------------------------
-- Entity deleted
function ENT:OnRemove()
  GPULib.ClientCacheCallback(self,nil)
  self.GPU:Finalize()
  if self.SpriteGPU then self.SpriteGPU:Finalize() end
end




--------------------------------------------------------------------------------
-- Run GPU execution (isAsync: should be running async thread)
function ENT:Run(isAsync)
  -- How many steps VM must make to keep up with execution
  local Cycles
  if isAsync then
    -- Limit frequency
    self.VM.Memory[65527] = math.Clamp(self.VM.Memory[65527],1,1200000)

    -- Calculate timing
    Cycles = math.max(1,math.floor(self.VM.Memory[65527]*self.DeltaTime*0.5))
    self.VM.TimerDT = self.DeltaTime/Cycles
    self.VM.TIMER = self.CurrentTime
    self.VM.ASYNC = 1
  else
    Cycles = 50000
    self.VM:Reset()
    self.VM.TimerDT = self.DeltaTime
    self.VM.TIMER = self.CurrentTime

    if self.VM.INIT == 0 then
      self.VM.IP = self.VM.EntryPoint1
      self.VM.INIT = 1
    else
      self.VM.IP = self.VM.EntryPoint0
    end

    self.VM.ASYNC = 0
  end

  -- Run until interrupt, or if async thread then until async thread stops existing
  while (Cycles > 0) and (self.VM.INTR == 0) do -- and (not (isAsync and (self.VM.Entrypoint4 == 0)))
    local previousTMR = self.VM.TMR
    self.VM:Step()
    Cycles = Cycles - (self.VM.TMR - previousTMR)

    if (self.VM.ASYNC == 0) and (Cycles < 0) then self.VM:Interrupt(17,0) end
  end

  -- Reset INTR register for async thread
  if self.VM.ASYNC == 1 then self.VM.INTR = 0 end
end




--------------------------------------------------------------------------------
-- Request rendering to rendertarget
function ENT:SetRendertarget(ID)
  if ID == 1 then self:AssertSpriteBufferExists() end

  if not ID then -- Restore state
    if self.In2D == true then self.In2D = false cam.End2D() end
    if self.ScreenRTSet then
      render.SetViewPort(0,0,self.ScreenRTWidth,self.ScreenRTHeight)
      render.SetRenderTarget(self.ScreenRT)

      self.ScreenRTSet = nil
      self.ScreenRT = nil

      self.VM.ScreenWidth = self.VM.VertexScreenWidth or 512
      self.VM.ScreenHeight = self.VM.VertexScreenHeight or 512
    end
    if self.VertexCamSettings and (not self.In3D2D) then
      cam.Start3D2D(self.VertexCamSettings[1],self.VertexCamSettings[2],self.VertexCamSettings[3])
      self.In3D2D = true
    end
    self.VM.CurrentBuffer = 2
    if self.VM.VertexMode == 0 then self.VM.RenderEnable = 0 end
  else
    -- Remember screen RT if this is the first switch
    local noRT = true
    if not self.ScreenRTSet then
      self.ScreenRT = render.GetRenderTarget()
      self.ScreenRTWidth = ScrW()
      self.ScreenRTHeight = ScrH()
      self.ScreenRTSet = true
      noRT = false
    end

    -- Bind correct rendertarget
    local newRT
    if ID == 0
    then newRT = self.GPU.RT
    else newRT = self.SpriteGPU.RT
    end

    if not newRT then return end

    -- Start drawing to the RT
    if self.In2D == true then self.In2D = false cam.End2D() end
    -- Get out of the 2D3D camera if its set
    if self.In3D2D == true then self.In3D2D = false cam.End3D2D() end

    render.SetRenderTarget(newRT)
    render.SetViewPort(0,0,512,512)
    cam.Start2D()
    self.In2D = true

    -- RT size
    self.VM.ScreenWidth = 512
    self.VM.ScreenHeight = 512
    self.VM.CurrentBuffer = ID

    if self.VM.VertexMode == 0 then self.VM.RenderEnable = 1 end
  end
end




--------------------------------------------------------------------------------
-- Render GPU to rendertarget
function ENT:RenderGPU()
  self.VM.VertexMode = 0
  self:SetRendertarget(0)

  if self.VM:ReadCell(65531) == 0 then -- Halt register
    if self.VM:ReadCell(65533) == 1 then -- Hardware clear
      surface.SetDrawColor(0,0,0,255)
      surface.DrawRect(0,0,self.VM.ScreenWidth,self.VM.ScreenHeight)
    end
    if self.VM:ReadCell(65535) == 1 then -- Clk
      self:Run(false)
    end
  end

  -- Restore screen rendertarget
  self:SetRendertarget()
end

-- Render GPU to world
function ENT:RenderVertex(width,height)
  self.VM.VertexMode = 1
  self.VM.RenderEnable = 1
  self:SetRendertarget()

  self.VM.ScreenWidth = width or 512
  self.VM.ScreenHeight = height or 512
  self.VM.VertexScreenWidth = self.VM.ScreenWidth
  self.VM.VertexScreenHeight = self.VM.ScreenHeight

  if self.VM:ReadCell(65531) == 0 then -- Halt register
    if self.VM:ReadCell(65533) == 1 then -- Hardware clear
      surface.SetDrawColor(0,0,0,255)
      surface.DrawRect(0,0,self.VM.ScreenWidth,self.VM.ScreenHeight)
    end
    if self.VM:ReadCell(65535) == 1 then -- Clk
      self:Run(false)
    end
  end

  self.VM.VertexScreenWidth = nil
  self.VM.VertexScreenHeight = nil
  self.VM.VertexMode = 0
  self:SetRendertarget()
end

-- Process misc GPU stuff
function ENT:RenderMisc(pos, ang, resolution, aspect, monitor)
  self.VM:WriteCell(65513, aspect)
  local ply = LocalPlayer()
  local trace = ply:GetEyeTraceNoCursor()
  if (trace.Entity and trace.Entity:IsValid() and trace.Entity == self) then
    local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*(-16384)
    dist = math.max(dist, trace.Fraction*16384-self:BoundingRadius())

    if (dist < 256) then
      local pos = WorldToLocal( trace.HitPos, Angle(), pos, ang )
      local x = 0.5+pos.x/(monitor.RS*(512/monitor.RatioX))
      local y = 0.5-pos.y/(monitor.RS*512)

      local cursorOffset = 0
      if self.VM:ReadCell(65532) == 1 then -- Check for vertex mode to counter the faulty offset
        cursorOffset = 0.5
      end

	  self.VM:WriteCell(65505,x - cursorOffset)
      self.VM:WriteCell(65504,y - cursorOffset)

      if (self.VM:ReadCell(65503) == 1) then
        surface.SetDrawColor(255,255,255,255)
        surface.SetTexture(surface.GetTextureID("gui/arrow"))
        x = math.Clamp(x,0 + cursorOffset, 1 + cursorOffset)
        y = math.Clamp(y,0 + cursorOffset, 1 + cursorOffset)
        surface.DrawTexturedRectRotated(-256*aspect+x*512*aspect+10,-256+y*512+12,32,32,45)
      end
    end
  end
end



--------------------------------------------------------------------------------
-- Entity drawing function
function ENT:Draw()
  -- Calculate time-related variables
  self.CurrentTime = CurTime()
  self.DeltaTime = math.min(1/30,self.CurrentTime - (self.PreviousTime or 0))
  self.PreviousTime = self.CurrentTime

  -- Draw GPU itself
  self:DrawModel()

  -- Draw image from another GPU
  local videoSource = MonitorLookup[self:EntIndex()]
  if videoSource then
    videoGPU = ents.GetByIndex(videoSource)
    if videoGPU and videoGPU:IsValid() and videoGPU.GPU then
      videoGPU.GPU.Entity = self
      videoGPU.GPU:Render(
       videoGPU.VM:ReadCell(65522), videoGPU.VM:ReadCell(65523)-videoGPU.VM:ReadCell(65518)/512, -- rotation, scale
        512*math.Clamp(videoGPU.VM:ReadCell(65525),0,1), 512*math.Clamp(videoGPU.VM:ReadCell(65524),0,1)
      )
      videoGPU.GPU.Entity = videoGPU
    end
    Wire_Render(self)
    return
  end

  if self.DeltaTime > 0 then
    -- Run the per-frame GPU thread
    if self.VM.Memory[65532] == 0 then
      local FrameRate = wire_gpu_frameratio:GetFloat() or 4
      self.FramesSinceRedraw = (self.FramesSinceRedraw or 0) + 1
      self.FrameInstructions = 0
      if self.FramesSinceRedraw >= FrameRate then
        self.FramesSinceRedraw = 0
        self:RenderGPU()
      end
    end

    -- Run asynchronous thread
    if self.VM.Memory[65528] == 1 then
      self.VM.VertexMode = 0
      if self.VM.LastBuffer < 2
      then self:SetRendertarget(self.VM.LastBuffer)
      else self:SetRendertarget()
      end

      self.VM:RestoreAsyncThread()
      self:Run(true)
      self.VM:SaveAsyncThread()

      self:SetRendertarget()
    end
  end

  -- Draw GPU to world
  if self.ChipType == 0 then -- Not a microchip
    if self.VM.Memory[65532] == 0 then
      self.GPU:Render(
        self.VM:ReadCell(65522), self.VM:ReadCell(65523)-self.VM:ReadCell(65518)/512, -- rotation, scale
        512*math.Clamp(self.VM:ReadCell(65525),0,1), 512*math.Clamp(self.VM:ReadCell(65524),0,1), -- width, height
        function(pos, ang, resolution, aspect, monitor) -- postrenderfunction
          self:RenderMisc(pos, ang, resolution, aspect, monitor)
        end
      )
    else
      -- Custom render to world
      local monitor, pos, ang = self.GPU:GetInfo()

      --pos = pos + ang:Up()*zoffset
      pos = pos - ang:Right()*(monitor.y2-monitor.y1)/2
      pos = pos - ang:Forward()*(monitor.x2-monitor.x1)/2

      local width,height = 512*math.Clamp(self.VM.Memory[65525],0,1),
                           512*math.Clamp(self.VM.Memory[65524],0,1)

      local h = width and width*monitor.RatioX or height or 512
      local w = width or h/monitor.RatioX
      local x = -w/2
      local y = -h/2

      local res = monitor.RS*512/h
      self.VertexCamSettings = { pos, ang, res }
      cam.Start3D2D(pos, ang, res)
      self.In3D2D = true
        local ok, err = xpcall(function()
          self:RenderVertex(512,512*monitor.RatioX)
          self:RenderMisc(pos, ang, res, 1/monitor.RatioX, monitor)
          end, debug.traceback)
		if not ok then WireLib.ErrorNoHalt(err) end
      if self.In3D2D then self.In3D2D = false cam.End3D2D() end
      self.VertexCamSettings = nil
    end
  end

  Wire_Render(self)
end



--------------------------------------------------------------------------------
-- Think function
function ENT:Think()
  for k,v in pairs(self.VM.MemBusBuffer) do
    RunConsoleCommand("wgm", self:EntIndex(), k, v)
  end
  self.VM.MemBusBuffer = {}
  self.VM.MemBusCount = 0
end




--------------------------------------------------------------------------------
-- HUD drawing function
local function GPU_DrawHUD()
  local videoSource = HUDLookup[LocalPlayer():EntIndex()]
  if videoSource then
    local videoGPU = ents.GetByIndex(videoSource)
    if videoGPU and videoGPU:IsValid() and videoGPU.RenderVertex then
      local screenWidth = ScrW()
      local screenHeight = ScrH()

      videoGPU:RenderVertex(screenWidth,screenHeight)
    end
  end
end
hook.Add("HUDPaint","wire_gpu_drawhud",GPU_DrawHUD)
