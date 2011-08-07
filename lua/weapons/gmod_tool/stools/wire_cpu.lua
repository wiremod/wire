TOOL.Category   = "Wire - Control"
TOOL.Name       = "Chip - CPU"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if CLIENT then
  language.Add("Tool_wire_cpu_name", "CPU Tool (Wire)")
  language.Add("Tool_wire_cpu_desc", "Spawns a central processing unit")
  language.Add("Tool_wire_cpu_0",    "Primary: upload program to hispeed device, Reload: attach debugger, Shift+Reload: clear, Secondary: open editor")
  language.Add("sboxlimit_wire_cpu", "You've hit ZCPU limit!")
  language.Add("undone_wire_cpu",    "Undone the ZCPU")
  language.Add("ToolWirecpu_Model",  "Model:" )
end

if SERVER then CreateConVar("sbox_maxwire_cpus", 7) end
cleanup.Register("wire_cpus")

TOOL.ClientConVar = {
  model             = "models/cheeze/wires/cpu.mdl",
  filename          = "",
  memorymodel       = "64krom",
}

if CLIENT then
  ------------------------------------------------------------------------------
  -- Make sure firing animation is displayed clientside
  ------------------------------------------------------------------------------
  function TOOL:LeftClick()  return true end
  function TOOL:Reload()     return true end
  function TOOL:RightClick() return false end
end




if SERVER then
  ------------------------------------------------------------------------------
  -- ZCPU entity factory
  ------------------------------------------------------------------------------
  local function MakeWireCPU(player, Pos, Ang, model)
    if !player:CheckLimit("wire_cpus") then return false end

    local self = ents.Create("gmod_wire_cpu")
    if !self:IsValid() then return false end

    self:SetModel(model)
    self:SetAngles(Ang)
    self:SetPos(Pos)
    self:Spawn()
    self:SetPlayer(player)
    self.player = player

    player:AddCount("wire_cpus", self)
    player:AddCleanup("wire_cpus", self)
    return self
  end
  duplicator.RegisterEntityClass("gmod_wire_cpu", MakeWireCPU, "Pos", "Ang", "Model")


  ------------------------------------------------------------------------------
  -- Reload: wipe ROM/RAM and reset memory model, or attach debugger
  ------------------------------------------------------------------------------
  function TOOL:Reload(trace)
    if trace.Entity:IsPlayer() then return false end
    local player = self:GetOwner()

    if player:KeyDown(IN_SPEED) then
      if (trace.Entity:IsValid()) and
         (trace.Entity:GetClass() == "gmod_wire_cpu") and
         (trace.Entity.player == player) then
        trace.Entity:SetMemoryModel(self:GetClientInfo("memorymodel"))
        trace.Entity:FlashData({})
        player:SendLua("CPULib.InvalidateDebugger()")
      end
    else
      if (not trace.Entity:IsPlayer()) and
         (trace.Entity:IsValid()) and
         (trace.Entity:GetClass() == "gmod_wire_cpu") and
         (trace.Entity.player == player) then
        CPULib.AttachDebugger(trace.Entity,player)
        CPULib.SendDebugData(trace.Entity.VM,nil,player)
        player:SendLua("CPULib.DebuggerAttached = true")
        player:SendLua("CPULib.InvalidateDebugger()")
        player:SendLua("GAMEMODE:AddNotify(\"CPU debugger has been attached!\",NOTIFY_GENERIC,7)")
      else
        CPULib.AttachDebugger(nil,player)
        player:SendLua("CPULib.DebuggerAttached = false")
        player:SendLua("CPULib.InvalidateDebugger()")
        player:SendLua("GAMEMODE:AddNotify(\"CPU debugger deattached!\",NOTIFY_GENERIC,7)")
      end
    end
    return true
  end


  ------------------------------------------------------------------------------
  -- Left click: spawn CPU or upload current program into it
  ------------------------------------------------------------------------------
  function TOOL:LeftClick(trace)
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

    local player = self:GetOwner()
    local model = self:GetClientInfo("model")
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end
    local pos = trace.HitPos
    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    -- Re-upload data to CPU or a hispeed device
    if (trace.Entity:IsValid()) and
       ((trace.Entity:GetClass() == "gmod_wire_cpu") or
        (trace.Entity.WriteCell)) and
       (trace.Entity:GetPlayer() == player) then
      CPULib.SetUploadTarget(trace.Entity,player)
      player:SendLua("ZCPU_RequestCode()")
      player:SendLua("CPULib.InvalidateDebugger()")
      return true
    end

    if !self:GetSWEP():CheckLimit("wire_cpus") then return false end

    local entity = ents.Create("gmod_wire_cpu")
    if !entity:IsValid() then return false end

    player:AddCount("wire_cpus", entity)

    entity:SetModel(model)
    entity:SetAngles(ang)
    entity:SetPos(pos)
    entity:Spawn()
    entity:SetPlayer(player)
    entity.player = player

    entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
    local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)

    undo.Create("wire_cpu")
      undo.AddEntity(entity)
      undo.SetPlayer(player)
      undo.AddEntity(constraint)
    undo.Finish()

    entity:SetMemoryModel(self:GetClientInfo("memorymodel"))

    player:AddCleanup("wire_cpus", entity)
    CPULib.SetUploadTarget(entity,player)
    player:SendLua("ZCPU_RequestCode()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Right click: open editor
  ------------------------------------------------------------------------------
  function TOOL:RightClick(trace)
    local player = self:GetOwner()
    player:SendLua("ZCPU_OpenEditor()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Update ghost entity
  ------------------------------------------------------------------------------
  function TOOL:UpdateGhostWireCPU(ent, player)
    if not ent then return end
    if not ent:IsValid() then return end

    local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
    local trace = util.TraceLine(tr)
    if not trace.Hit then return end

    if  (trace.Entity) and
       ((trace.Entity:GetClass() == "gmod_wire_cpu") or
        (trace.Entity:IsPlayer()) or
        (trace.Entity.WriteCell)) then
      ent:SetNoDraw(true)
      return
    end

    local Ang = trace.HitNormal:Angle()
    Ang.pitch = Ang.pitch + 90

    local min = ent:OBBMins()
    ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
    ent:SetAngles(Ang)

    ent:SetNoDraw(false)
  end


  ------------------------------------------------------------------------------
  -- Think loop
  ------------------------------------------------------------------------------
  function TOOL:Think()
    local model = self:GetClientInfo("model")

    if (not self.GhostEntity) or
       (not self.GhostEntity:IsValid()) or
       (self.GhostEntity:GetModel() ~= model) or
       (not self.GhostEntity:GetModel()) then
      self:MakeGhostEntity(model, Vector(0,0,0), Angle(0,0,0))
    end

    self:UpdateGhostWireCPU(self.GhostEntity, self:GetOwner())
  end
end






--------------------------------------------------------------------------------
if CLIENT then
  ------------------------------------------------------------------------------
  -- Compiler callbacks on the compiling state
  ------------------------------------------------------------------------------
  local function compile_success()
    CPULib.Upload()
  end

  local function compile_error(errorText)
    print(errorText)
    GAMEMODE:AddNotify(errorText,NOTIFY_GENERIC,7)
  end


  ------------------------------------------------------------------------------
  -- Request code to be compiled (called remotely from server)
  ------------------------------------------------------------------------------
  function ZCPU_RequestCode()
    if ZCPU_Editor then
      CPULib.Compile(ZCPU_Editor:GetCode(),ZCPU_Editor:GetChosenFile(),compile_success,compile_error)
    end
  end


  ------------------------------------------------------------------------------
  -- Open ZCPU editor
  ------------------------------------------------------------------------------
  function ZCPU_OpenEditor()
    if not ZCPU_Editor then
      ZCPU_Editor = vgui.Create("Expression2EditorFrame")
      ZCPU_Editor:Setup("ZCPU Editor", "CPUChip", "CPU")
    end
    ZCPU_Editor:Open()
  end


  ------------------------------------------------------------------------------
  -- Build tool control panel
  ------------------------------------------------------------------------------
  function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "#Tool_wire_cpu_name", Description = "#Tool_wire_cpu_desc" })


    ----------------------------------------------------------------------------
    local Button = vgui.Create("DButton" , panel)
    panel:AddPanel(Button)
    Button:SetText("Online ZCPU documentation")
    Button.DoClick = function(button) CPULib.ShowDocumentation("ZCPU") end


    ----------------------------------------------------------------------------
    local currentDirectory
    local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
    panel:AddPanel(FileBrowser)
    FileBrowser:Setup("CPUChip")
    FileBrowser:SetSize(235,400)
    function FileBrowser:OnFileClick()
      local lastClickTime = CurTime()
      if not ZCPU_Editor then
        ZCPU_Editor = vgui.Create("Expression2EditorFrame")
        ZCPU_Editor:Setup("ZCPU Editor", "CPUChip", "CPU")
      end

      if (currentDirectory == self.File.FileDir) and (CurTime() - lastClickTime < 1) then
        ZCPU_Editor:Open(currentDirectory)
      else
        lastClickTime = CurTime()
        currentDirectory = self.File.FileDir
        ZCPU_Editor:LoadFile(currentDirectory)
      end
    end


    ----------------------------------------------------------------------------
    local New = vgui.Create("DButton" , panel)
    panel:AddPanel(New)
    New:SetText("New file")
    New.DoClick = function(button)
      ZCPU_OpenEditor()
      ZCPU_Editor:AutoSave()
      ZCPU_Editor:NewScript(false)
    end
    panel:AddControl("Label", {Text = ""})

    ----------------------------------------------------------------------------
    local OpenEditor = vgui.Create("DButton", panel)
    panel:AddPanel(OpenEditor)
    OpenEditor:SetText("Open Editor")
    OpenEditor.DoClick = ZCPU_OpenEditor


    ----------------------------------------------------------------------------
    panel:AddControl("Label", {Text = ""})
    panel:AddControl("Label", {Text = "CPU settings:"})


    ----------------------------------------------------------------------------
    local modelPanel = WireDermaExts.ModelSelect(panel, "wire_cpu_model", list.Get("Wire_gate_Models"), 2)
    panel:AddControl("Label", {Text = ""})


    ----------------------------------------------------------------------------
    panel:AddControl("ComboBox", {
      Label = "Memory model",
      Options = {
        ["128 bytes ROM only"]  = {wire_cpu_memorymodel = "128rom"},
        ["128 bytes RAM/ROM"]   = {wire_cpu_memorymodel = "128"},
        ["64KB RAM/ROM"]        = {wire_cpu_memorymodel = "64krom"},
        ["64KB RAM only"]       = {wire_cpu_memorymodel = "64k"},
        ["128KB RAM/ROM"]       = {wire_cpu_memorymodel = "128krom"},
        ["No internal RAM/ROM"] = {wire_cpu_memorymodel = "flat"},
      }
    })
    panel:AddControl("Label", {Text = "Sets the processor memory model (determines iteraction with the external devices)"})
  end


  ------------------------------------------------------------------------------
  -- Tool screen
  ------------------------------------------------------------------------------
  surface.CreateFont("Lucida Console", 30, 1000, true, false, "ZCPUToolScreenFont")
  surface.CreateFont("Lucida Console", 26, 1000, true, false, "ZCPUToolScreenFontSmall")

  local function outc(text,y,color) draw.DrawText(text,"ZCPUToolScreenFont",2,32*y,color,0) end
  local prevStateTime = RealTime()
  local prevState = nil
  local consoleHistory = { "", "", "", "", "", "" }
  local stageName = {"Preprocessing","Tokenizing","Parsing","Generating","Optimizing","Resolving","Outputting"}
  local stageNameShort = {"Preproc","Tokenize","Parse","Generate","Optimize","Resolve","Output"}

  local function outform(x,y,w,h,title)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(x*28-3,y*32-3,w*28,h*32)

    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(x*28+3,y*32+3,w*28,h*32)

    surface.SetDrawColor(192, 220, 192, 255)
    surface.DrawRect(x*28,y*32,w*28-3,h*32-3)

    surface.SetDrawColor(192, 192, 192, 255)
    surface.DrawRect(x*28,y*32,w*28,h*32)

    if title then
      surface.SetDrawColor(0, 0, 128, 255)
      surface.DrawRect(x*28+4,y*32+4,w*28-4,1*32-4)
      draw.DrawText(title,"ZCPUToolScreenFontSmall",x*28+4,y*32+4,Color(255,255,255,255),0)
    end
  end

  function CPULib.RenderCPUTool(screenIndex,toolName)
    if screenIndex == 0 then
      surface.SetDrawColor(0, 0, 128, 255)
      surface.DrawRect(0, 0, 256, 256)

      surface.SetDrawColor(240, 240, 0, 255)
      surface.DrawRect(0,0,256,32)
      outc(" ToolOS r"..VERSION.." ",0,Color(0,0,0,255))

      if CPULib.Uploading then
        outc("Program size:",2,Color(255,255,255,255))
        outc(string.format("%d bytes",CPULib.TotalUploadData),3,Color(255,255,255,255))
        outc(string.format("Uploading %2d%%",100-100*CPULib.RemainingUploadData/(CPULib.TotalUploadData+1e-12)),5,Color(255,255,255,255))
        outc(string.format("%d bytes",CPULib.RemainingUploadData),6,Color(255,255,255,255))
        prevStateTime = RealTime()
      elseif CPULib.ServerUploading then
        outc("Program size:",2,Color(255,255,255,255))
        outc(string.format("%d bytes",#CPULib.Buffer),3,Color(255,255,255,255))
        outc("Uploading 100",5,Color(255,255,255,255))
        outc("   Standby   ",6,Color(255,255,255,255))
        prevStateTime = RealTime()
      elseif CPULib.Compiling then
        outc(string.format("Stage %2d/7",HCOMP.Stage+1),2,Color(255,255,255,255))
        outc(stageName[HCOMP.Stage+1],3,Color(255,255,255,255))
        prevStateTime = RealTime()
      else
        if RealTime() - prevStateTime > 0.15 then
          outc("Flash utility",1,Color(255,255,255,255))
          outc("(C) 2007-2011",2,Color(255,255,255,255))
          outc("Black Phoenix",3,Color(255,255,255,255))

          outc(string.format("RAM: %5d KB",collectgarbage("count") or 0),7,Color(255,255,255,255))
        else
          surface.SetDrawColor(0, 0, 0, 255)
          surface.DrawRect(0, 0, 256, 256)
        end
      end
    elseif screenIndex == 1 then
      surface.SetDrawColor(0, 0, 0, 255)
      surface.DrawRect(0, 0, 256, 256)

      surface.SetDrawColor(240, 120, 0, 255)
      surface.DrawRect(16*(#toolName+1),32*0+14,256,4)
      outc(toolName,0,Color(240, 120,0,255))
      outc(string.format(" RAM %5d KB",collectgarbage("count") or 0),1,Color(255,255,255,255))

      surface.SetDrawColor(240, 120, 0, 255)
      surface.DrawRect(16*(5),32*2+14,256,4)
      outc("TASK",2,Color(240, 120,0,255))
      outc("       STATUS",3,Color(255,255,255,255))

      surface.SetDrawColor(240, 120, 0, 255)
      surface.DrawRect(16*(4),32*6+14,256,4)
      outc("NET",6,Color(240, 120,0,255))
      if CPULib.Uploading then
        outc(string.format("UP %.3f KB",CPULib.RemainingUploadData/1024),7,Color(255,255,255,255))
        outc(string.format("ROMUPL [%3d%%]",100-100*CPULib.RemainingUploadData/(CPULib.TotalUploadData+1e-12)),4,Color(255,255,255,255))
        outc("UPLMON [ OK ]",5,Color(255,255,255,255))
      elseif CPULib.ServerUploading then
        outc("UPLMON [ OK ]",4,Color(255,255,255,255))
        outc("DOWN SYNC",7,Color(255,255,255,255))
      elseif CPULib.Compiling then
        outc(string.format("HCOMP  [%2d/7]",HCOMP.Stage),4,Color(255,255,255,255))
        outc("IDLE",7,Color(255,255,255,255))
      else
        outc("IDLE",7,Color(255,255,255,255))
      end
    elseif screenIndex == 2 then
      surface.SetDrawColor(0, 0, 0, 255)
      surface.DrawRect(0, 0, 256, 256)

      outc("TL-UNIX "..(VERSION/100),0,Color(200,200,200,255))

      outc(consoleHistory[1],2,Color(200,200,200,255))
      outc(consoleHistory[2],3,Color(200,200,200,255))
      outc(consoleHistory[3],4,Color(200,200,200,255))
      outc(consoleHistory[4],5,Color(200,200,200,255))
      outc(consoleHistory[5],6,Color(200,200,200,255))
      outc(consoleHistory[6],7,Color(200,200,200,255))

      if CPULib.Uploading then
        if prevState ~= 0 then
          consoleHistory[1] = consoleHistory[2]
          consoleHistory[2] = consoleHistory[3]
          consoleHistory[3] = consoleHistory[4]
          consoleHistory[4] = string.lower(toolName).."@:/# upl"
        end

        consoleHistory[5] = string.format("  %3d%%",100-100*CPULib.RemainingUploadData/(CPULib.TotalUploadData+1e-12))
        consoleHistory[6] = string.format("  %d B",CPULib.RemainingUploadData)

        prevState = 0
      elseif CPULib.ServerUploading then
        consoleHistory[5] = "  ###"
        consoleHistory[6] = "  0 B"
        prevState = 0
      elseif CPULib.Compiling then
         if prevState ~= 1 then
          consoleHistory[1] = consoleHistory[2]
          consoleHistory[2] = consoleHistory[3]
          consoleHistory[3] = consoleHistory[4]
          consoleHistory[4] = consoleHistory[5]
          consoleHistory[5] = string.lower(toolName).."@:/# hcmp"
        end
        consoleHistory[6] = string.format("Stage %2d/7",HCOMP.Stage+1)
        prevState = 1
      else
         if prevState ~= 2 then
          consoleHistory[1] = consoleHistory[2]
          consoleHistory[2] = consoleHistory[3]
          consoleHistory[3] = consoleHistory[4]
          consoleHistory[4] = consoleHistory[5]
          consoleHistory[5] = consoleHistory[6]
          consoleHistory[6] = string.lower(toolName).."@:/# "
        end
        prevState = 2
      end
    elseif screenIndex == 3 then
      surface.SetDrawColor(0, 128, 128, 255)
      surface.DrawRect(0, 0, 256, 256)

      outform(0,7,12,1)

      outform(0,7,3,1)
      outc("MENU",7,Color(0,0,0,255))

      if CPULib.Uploading then
        outform(1,1,7,5,"Upload")
        outc(string.format("  %.3f kb",CPULib.RemainingUploadData/1024),3,Color(0,0,0,255))
        outc(string.format("  %3d%% done",100-100*CPULib.RemainingUploadData/(CPULib.TotalUploadData+1e-12)),4,Color(0,0,0,255))

        outform(1,5,7,0.9)
        surface.SetDrawColor(0, 0, 128, 255)
        surface.DrawRect(1*28+4,5*32+4,
          math.floor((7*28-4)*(1-CPULib.RemainingUploadData/(CPULib.TotalUploadData+1e-12))/14)*14,
          1*32-8)
      elseif CPULib.ServerUploading then
        outform(1,3,7,3,"Upload")
        outc("  Standby",5,Color(0,0,0,255))
      elseif CPULib.Compiling then
        outform(1,1,7,5,"HL-ZASM")
        outc(string.format("  Stage %d/7",HCOMP.Stage+1),3,Color(0,0,0,255))
        outc("  "..stageNameShort[HCOMP.Stage+1],4,Color(0,0,0,255))
      else
        --
      end
    end
  end

  function TOOL:RenderToolScreen()
    cam.Start2D()
      local currentTime = os.date("*t")
      CPULib.RenderCPUTool(currentTime.yday % 4,"CPU")
    cam.End2D()
  end
end
