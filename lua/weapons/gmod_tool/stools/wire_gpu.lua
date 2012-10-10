TOOL.Category   = "Wire - Advanced"
TOOL.Name       = "Display - GPU"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if CLIENT then
  language.Add("Tool.wire_gpu.name", "GPU Tool (Wire)")
  language.Add("Tool.wire_gpu.desc", "Spawns a central processing unit")
  language.Add("Tool.wire_gpu.0",    "Primary: create/reflash ZGPU or other hispeed device, Secondary: open editor and/or attach debugger to the ZGPU")
  language.Add("sboxlimit_wire_gpu", "You've hit ZGPU limit!")
  language.Add("undone_wire_gpu",    "Undone the ZGPU")
  language.Add("ToolWiregpu_Model",  "Model:" )
end

if SERVER then CreateConVar("sbox_maxwire_gpus", 7) end
cleanup.Register("wire_gpus")

TOOL.ClientConVar = {
  model             = "models/cheeze/wires/cpu.mdl",
  filename          = "",
  memorymodel       = "64k",
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
  -- ZGPU entity factory
  ------------------------------------------------------------------------------
  local function MakeWireGPU(player, Pos, Ang, model)
    if !player:CheckLimit("wire_gpus") then return false end

    local self = ents.Create("gmod_wire_gpu")
    if !self:IsValid() then return false end

    self:SetModel(model)
    self:SetAngles(Ang)
    self:SetPos(Pos)
    self:Spawn()
    self:SetPlayer(player)
    self.player = player

    player:AddCount("wire_gpus", self)
    player:AddCleanup("wire_gpus", self)
    return self
  end
  duplicator.RegisterEntityClass("gmod_wire_gpu", MakeWireGPU, "Pos", "Ang", "Model")


  ------------------------------------------------------------------------------
  -- Reload: wipe ROM/RAM and reset memory model
  ------------------------------------------------------------------------------
  function TOOL:Reload(trace)
    if trace.Entity:IsPlayer() then return false end

    local player = self:GetOwner()
    if (trace.Entity:IsValid()) and
       (trace.Entity:GetClass() == "gmod_wire_gpu") and
       (trace.Entity.player == player) then
      trace.Entity:SetMemoryModel(self:GetClientInfo("memorymodel"))
      return true
    end
  end


  ------------------------------------------------------------------------------
  -- Left click: spawn GPU or upload current program into it
  ------------------------------------------------------------------------------
  function TOOL:LeftClick(trace)
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

    local player = self:GetOwner()
    local model = self:GetClientInfo("model")
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

    local pos = trace.HitPos
    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    -- Re-upload data to GPU or a hispeed device
    if (trace.Entity:IsValid()) and
       ((trace.Entity:GetClass() == "gmod_wire_gpu") or
        (trace.Entity.WriteCell)) and
       (trace.Entity.player == player) then
      CPULib.SetUploadTarget(trace.Entity,player)
      player:SendLua("ZGPU_RequestCode()")
      return true
    end

    if !self:GetSWEP():CheckLimit("wire_gpus") then return false end

    local entity = ents.Create("gmod_wire_gpu")
    if !entity:IsValid() then return false end

    player:AddCount("wire_gpus", entity)

    entity:SetModel(model)
    entity:SetAngles(ang)
    entity:SetPos(pos)
    entity:Spawn()
    entity:SetPlayer(player)
    entity.player = player

    entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
    local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)

    undo.Create("wire_gpu")
      undo.AddEntity(entity)
      undo.SetPlayer(player)
      undo.AddEntity(constraint)
    undo.Finish()

    entity:SetMemoryModel(self:GetClientInfo("memorymodel"))

    player:AddCleanup("wire_gpus", entity)
    CPULib.SetUploadTarget(entity,player)
    player:SendLua("ZGPU_RequestCode()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Right click: open editor
  ------------------------------------------------------------------------------
  function TOOL:RightClick(trace)
    self:GetOwner():SendLua("ZGPU_OpenEditor()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Update ghost entity
  ------------------------------------------------------------------------------
  function TOOL:UpdateGhostWireGPU(ent, player)
    if not ent then return end
    if not ent:IsValid() then return end

    local tr = util.GetPlayerTrace(player)
    local trace = util.TraceLine(tr)
    if not trace.Hit then return end

    if  (trace.Entity) and
       ((trace.Entity:GetClass() == "gmod_wire_gpu") or
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
    local model = Model(self:GetClientInfo("model"))

    if (not self.GhostEntity) or
       (not self.GhostEntity:IsValid()) or
       (self.GhostEntity:GetModel() ~= model) or
       (not self.GhostEntity:GetModel()) then
      self:MakeGhostEntity(model, Vector(0,0,0), Angle(0,0,0))
    end

    self:UpdateGhostWireGPU(self.GhostEntity, self:GetOwner())
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
  function ZGPU_RequestCode()
    if ZGPU_Editor then
      CPULib.Debugger.SourceTab = ZGPU_Editor:GetActiveTab()
      CPULib.Compile(ZGPU_Editor:GetCode(),ZGPU_Editor:GetChosenFile(),compile_success,compile_error,"GPU")
    end
  end


  ------------------------------------------------------------------------------
  -- Open ZGPU editor
  ------------------------------------------------------------------------------
  function ZGPU_OpenEditor()
    if not ZGPU_Editor then
      ZGPU_Editor = vgui.Create("Expression2EditorFrame")
      ZGPU_Editor:Setup("ZGPU Editor", "GPUChip", "GPU")
    end
    ZGPU_Editor:Open()
  end


  ------------------------------------------------------------------------------
  -- Build tool control panel
  ------------------------------------------------------------------------------
  function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "#Tool_wire_gpu_name", Description = "#Tool_wire_gpu_desc" })


    ----------------------------------------------------------------------------
    local Button = vgui.Create("DButton" , panel)
    panel:AddPanel(Button)
    Button:SetText("Online ZGPU documentation")
    Button.DoClick = function(button) CPULib.ShowDocumentation("ZGPU") end


    ----------------------------------------------------------------------------
    local currentDirectory
    local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
    panel:AddPanel(FileBrowser)
    FileBrowser:Setup("GPUChip")
    FileBrowser:SetSize(235,400)
    function FileBrowser:OnFileClick()
      local lastClickTime = CurTime()
      if not ZGPU_Editor then
        ZGPU_Editor = vgui.Create("Expression2EditorFrame")
        ZGPU_Editor:Setup("ZGPU Editor", "GPUChip", "GPU")
      end

      if (currentDirectory == self.File.FileDir) and (CurTime() - lastClickTime < 1) then
        ZGPU_Editor:Open(currentDirectory)
      else
        lastClickTime = CurTime()
        currentDirectory = self.File.FileDir
        ZGPU_Editor:LoadFile(currentDirectory)
      end
    end


    ----------------------------------------------------------------------------
    local New = vgui.Create("DButton" , panel)
    panel:AddPanel(New)
    New:SetText("New file")
    New.DoClick = function(button)
      ZGPU_OpenEditor()
      ZGPU_Editor:AutoSave()
      ZGPU_Editor:NewScript(false)
    end
    panel:AddControl("Label", {Text = ""})

    ----------------------------------------------------------------------------
    local OpenEditor = vgui.Create("DButton", panel)
    panel:AddPanel(OpenEditor)
    OpenEditor:SetText("Open Editor")
    OpenEditor.DoClick = ZGPU_OpenEditor


    ----------------------------------------------------------------------------
    local modelPanel = WireDermaExts.ModelSelect(panel, "wire_gpu_model", list.Get("WireScreenModels"), 2)
    modelPanel:SetModelList(list.Get("Wire_gate_Models"),"wire_gpu_model")
    panel:AddControl("Label", {Text = ""})


    ----------------------------------------------------------------------------
    panel:AddControl("ComboBox", {
      Label = "Memory model",
      Options = {
        ["128K"]                      = {wire_gpu_memorymodel = "128k"},
        ["128K chip"]                 = {wire_gpu_memorymodel = "128kc"},
        ["256K"]                      = {wire_gpu_memorymodel = "256k"},
        ["256K chip"]                 = {wire_gpu_memorymodel = "256kc"},
        ["512K"]                      = {wire_gpu_memorymodel = "512k"},
        ["512K chip"]                 = {wire_gpu_memorymodel = "512kc"},
        ["1024K"]                     = {wire_gpu_memorymodel = "1024k"},
        ["1024K chip"]                = {wire_gpu_memorymodel = "1024kc"},
        ["2048K"]                     = {wire_gpu_memorymodel = "2048k"},
        ["2048K chip"]                = {wire_gpu_memorymodel = "2048kc"},

        ["64K (compatibility mode)"]  = {wire_gpu_memorymodel = "64k"},
        ["64K chip"]                  = {wire_gpu_memorymodel = "64kc"},
      }
    })
    panel:AddControl("Label", {Text = "Memory model selects GPU memory size and its operation mode"})


    ----------------------------------------------------------------------------
--    panel:AddControl("Button", {
--      Text = "ZGPU documentation (online)"
--    })
--    panel:AddControl("Label", {
--      Text = "Loads online GPU documentation and tutorials"
--    })
  end

  ------------------------------------------------------------------------------
  -- Tool screen
  ------------------------------------------------------------------------------
  function TOOL:RenderToolScreen()
    cam.Start2D()
      CPULib.RenderCPUTool(1,"ZGPU")
    cam.End2D()
  end
end
