WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "spu", "Chip - SPU", "gmod_wire_spu", nil, "SPUs" )

if CLIENT then
  language.Add("Tool.wire_spu.name", "SPU Tool (Wire)")
  language.Add("Tool.wire_spu.desc", "Spawns a sound processing unit")
  language.Add("Tool.wire_spu.0",    "Primary: create/reflash ZSPU, Secondary: open editor")
  language.Add("sboxlimit_wire_spu", "You've hit ZSPU limit!")
  language.Add("undone_wire_spu",    "Undone the ZSPU")
  language.Add("ToolWirespu_Model",  "Model:" )
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
  util.AddNetworkString("ZSPU_RequestCode")
  util.AddNetworkString("ZSPU_OpenEditor")
  ------------------------------------------------------------------------------
  -- ZSPU entity factory
  ------------------------------------------------------------------------------
  local function MakeWireSPU(player, Pos, Ang, model)
    if !player:CheckLimit("wire_spus") then return false end

    local self = ents.Create("gmod_wire_spu")
    if !self:IsValid() then return false end

    self:SetModel(model)
    self:SetAngles(Ang)
    self:SetPos(Pos)
    self:Spawn()
    self:SetPlayer(player)
    self.player = player

    player:AddCount("wire_spus", self)
    player:AddCleanup("wire_spus", self)
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
      net.Start("ZSPU_RequestCode") net.Send(player)
      return true
    end

    if !self:GetSWEP():CheckLimit("wire_spus") then return false end

    local entity = ents.Create("gmod_wire_spu")
    if !entity:IsValid() then return false end

    player:AddCount("wire_spus", entity)

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

    player:AddCleanup("wire_spus", entity)
    CPULib.SetUploadTarget(entity,player)
    net.Start("ZSPU_RequestCode") net.Send(player)
    return true
  end


  ------------------------------------------------------------------------------
  -- Right click: open editor
  ------------------------------------------------------------------------------
  function TOOL:RightClick(trace)
    net.Start("ZSPU_OpenEditor") net.Send(self:GetOwner())
    return true
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
  net.Receive("ZSPU_RequestCode", ZSPU_RequestCode)

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
  net.Receive("ZSPU_OpenEditor", ZSPU_OpenEditor)

  ------------------------------------------------------------------------------
  -- Build tool control panel
  ------------------------------------------------------------------------------
  function TOOL.BuildCPanel(panel)
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
  function TOOL:DrawToolScreen(width, height)
    cam.Start2D()
      CPULib.RenderCPUTool(1,"ZSPU")
    cam.End2D()
  end
end
