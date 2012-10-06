TOOL.Category   = "Wire - Advanced"
TOOL.Name       = "Chip - SPU"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if CLIENT then
  language12.Add("Tool_wire_spu_name", "SPU Tool (Wire)")
  language12.Add("Tool_wire_spu_desc", "Spawns a sound processing unit")
  language12.Add("Tool_wire_spu_0",    "Primary: create/reflash ZSPU, Secondary: open editor")
  language12.Add("sboxlimit_wire_spu", "You've hit ZSPU limit!")
  language12.Add("undone_wire_spu",    "Undone the ZSPU")
  language12.Add("ToolWirespu_Model",  "Model:" )
end

if SERVER then CreateConVar("sbox_maxwire_spus", 7) end
cleanup.Register("wire_spus")

TOOL.ClientConVar = {
  model             = "models/cheeze/wires/cpu.mdl",
  filename          = "",
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
  -- ZSPU entity factory
  ------------------------------------------------------------------------------
  local function MakeWireSPU(player, Pos, Ang, model)
if (player!=nil) then     if (pl!=nil) then if !player:CheckLimit("wire_spus") then return false end end end

    local self = ents.Create("gmod_wire_spu")
    if !self:IsValid() then return false end

    self:SetModel(model)
    self:SetAngles(Ang)
    self:SetPos(Pos)
    self:Spawn()
    self:SetPlayer(player)
    self.player = player

if (player!=nil) then     player:AddCount("wire_spus", self) end
if (player!=nil) then     player:AddCleanup("wire_spus", self) end
    return self
  end
  duplicator.RegisterEntityClass("gmod_wire_spu", MakeWireSPU, "Pos", "Ang", "Model")


  ------------------------------------------------------------------------------
  -- Reload: wipe ROM/RAM and reset memory model
  ------------------------------------------------------------------------------
  function TOOL:Reload(trace)
    if trace.Entity:IsPlayer() then return false end

    local player = self:GetOwner()
    if (trace.Entity:IsValid()) and
       (trace.Entity:GetClass() == "gmod_wire_spu") and
       (trace.Entity.player == player) then
      trace.Entity:SetMemoryModel(self:GetClientInfo("memorymodel"))
      return true
    end
  end


  ------------------------------------------------------------------------------
  -- Left click: spawn SPU or upload current program into it
  ------------------------------------------------------------------------------
  function TOOL:LeftClick(trace)
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

    local player = self:GetOwner()
    local model = self:GetModel()
    local pos = trace.HitPos
    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    -- Re-upload data to SPU or a hispeed device
    if (trace.Entity:IsValid()) and
       ((trace.Entity:GetClass() == "gmod_wire_spu") or
        (trace.Entity.WriteCell)) and
       (trace.Entity.player == player) then
      CPULib.SetUploadTarget(trace.Entity,player)
      player:SendLua("ZSPU_RequestCode()")
      return true
    end

    if (pl!=nil) then if !self:GetSWEP():CheckLimit("wire_spus") then return false end end

    local entity = ents.Create("gmod_wire_spu")
    if !entity:IsValid() then return false end

if (player!=nil) then     player:AddCount("wire_spus", entity) end

    entity:SetModel(model)
    entity:SetAngles(ang)
    entity:SetPos(pos)
    entity:Spawn()
    entity:SetPlayer(player)
    entity.player = player

    entity:SetPos(trace.HitPos - trace.HitNormal * entity:OBBMins().z)
    local constraint = WireLib.Weld(entity, trace.Entity, trace.PhysicsBone, true)

    undo.Create("wire_spu")
      undo.AddEntity(entity)
      undo.SetPlayer(player)
      undo.AddEntity(constraint)
    undo.Finish()

    entity:SetMemoryModel(self:GetClientInfo("memorymodel"))

if (player!=nil) then     player:AddCleanup("wire_spus", entity) end
    CPULib.SetUploadTarget(entity,player)
    player:SendLua("ZSPU_RequestCode()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Right click: open editor
  ------------------------------------------------------------------------------
  function TOOL:RightClick(trace)
    self:GetOwner():SendLua("ZSPU_OpenEditor()")
    return true
  end


  ------------------------------------------------------------------------------
  -- Update ghost entity
  ------------------------------------------------------------------------------
  function TOOL:UpdateGhostWireSPU(ent, player)
    if not ent then return end
    if not ent:IsValid() then return end

    local tr = util.GetPlayerTrace(player)
    local trace = util.TraceLine(tr)
    if not trace.Hit then return end

    if  (trace.Entity) and
       ((trace.Entity:GetClass() == "gmod_wire_spu") or
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
    local model = self:GetModel()

    if (not self.GhostEntity) or
       (not self.GhostEntity:IsValid()) or
       (self.GhostEntity:GetModel() ~= model) or
       (not self.GhostEntity:GetModel()) then
      self:MakeGhostEntity(model, Vector(0,0,0), Angle(0,0,0))
    end

    self:UpdateGhostWireSPU(self.GhostEntity, self:GetOwner())
  end


  ------------------------------------------------------------------------------
  -- Get currently selected model
  ------------------------------------------------------------------------------
  function TOOL:GetModel()
    local model = self:GetClientInfo("model")

    if model then
      local modelname, modelext = model:match("(.*)(%..*)")
      if not modelext then return model end
      local newmodel = modelname .. modelext
	  if not util.IsValidModel( newmodel ) or not util.IsValidProp( newmodel ) then return "models/cheeze/wires/cpu.mdl" end
      return Model(newmodel)
    end
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
    GAMEMODE:AddNotify(errorText,NOTIFY_GENERIC,7)
  end


  ------------------------------------------------------------------------------
  -- Request code to be compiled (called remotely from server)
  ------------------------------------------------------------------------------
  function ZSPU_RequestCode()
    if ZSPU_Editor then
      CPULib.Debugger.SourceTab = ZSPU_Editor:GetActiveTab()
      CPULib.Compile(ZSPU_Editor:GetCode(),ZSPU_Editor:GetChosenFile(),compile_success,compile_error)
    end
  end


  ------------------------------------------------------------------------------
  -- Open ZSPU editor
  ------------------------------------------------------------------------------
  function ZSPU_OpenEditor()
    if not ZSPU_Editor then
      ZSPU_Editor = vgui.Create("Expression2EditorFrame")
      ZSPU_Editor:Setup("ZSPU Editor", "SPUChip", "SPU")
    end
    ZSPU_Editor:Open()
  end


  ------------------------------------------------------------------------------
  -- Build tool control panel
  ------------------------------------------------------------------------------
  function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "#Tool_wire_spu_name", Description = "#Tool_wire_spu_desc" })


    ----------------------------------------------------------------------------
    local Button = vgui.Create("DButton" , panel)
    panel:AddPanel(Button)
    Button:SetText("Online ZSPU documentation")
    Button.DoClick = function(button) CPULib.ShowDocumentation("ZSPU") end

    local Button = vgui.Create("DButton" , panel)
    panel:AddPanel(Button)
    Button:SetText("Open Sound Browser")
    Button.DoClick = function()
      RunConsoleCommand("wire_sound_browser_open")
    end


    ----------------------------------------------------------------------------
    local currentDirectory
    local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
    panel:AddPanel(FileBrowser)
    FileBrowser:Setup("SPUChip")
    FileBrowser:SetSize(235,400)
    function FileBrowser:OnFileClick()
      local lastClickTime = CurTime()
      if not ZSPU_Editor then
        ZSPU_Editor = vgui.Create("Expression2EditorFrame")
        ZSPU_Editor:Setup("ZSPU Editor", "SPUChip", "SPU")
      end

      if (currentDirectory == self.File.FileDir) and (CurTime() - lastClickTime < 1) then
        ZSPU_Editor:Open(currentDirectory)
      else
        lastClickTime = CurTime()
        currentDirectory = self.File.FileDir
        ZSPU_Editor:LoadFile(currentDirectory)
      end
    end


    ----------------------------------------------------------------------------
    local New = vgui.Create("DButton" , panel)
    panel:AddPanel(New)
    New:SetText("New file")
    New.DoClick = function(button)
      ZSPU_OpenEditor()
      ZSPU_Editor:AutoSave()
      ZSPU_Editor:NewScript(false)
    end
    panel:AddControl("Label", {Text = ""})

    ----------------------------------------------------------------------------
    local OpenEditor = vgui.Create("DButton", panel)
    panel:AddPanel(OpenEditor)
    OpenEditor:SetText("Open Editor")
    OpenEditor.DoClick = ZSPU_OpenEditor


    ----------------------------------------------------------------------------
    WireDermaExts.ModelSelect(panel, "wire_spu_model", list.Get("Wire_gate_Models"), 2)
    panel:AddControl("Label", {Text = ""})
  end

  ------------------------------------------------------------------------------
  -- Tool screen
  ------------------------------------------------------------------------------
  function TOOL:RenderToolScreen()
    cam.Start2D()
      CPULib.RenderCPUTool(1,"ZSPU")
    cam.End2D()
  end
end
