WireToolSetup.setCategory("Chips, Gates", "Advanced")
WireToolSetup.open("fpga", "FPGA", "gmod_wire_fpga", nil, "FPGAs")

if CLIENT then
	language.Add("Tool.wire_fpga.name", "FPGA Tool (Wire)")
	language.Add("Tool.wire_fpga.desc", "Spawns a field programmable gate array for use with the wire system.")
  language.Add("ToolWirecpu_Model",  "Model:" )
	TOOL.Information = {
    { name = "left", text = "Upload program to FPGA" },
    { name = "right", text = "Open editor" },
    { name = "reload", text = "Reset" }
  }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(7)

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
  util.AddNetworkString("FPGA_OpenEditor")

  -- Reset
  function TOOL:Reload(trace)
    if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

    local player = self:GetOwner()

    if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_fpga" then
      trace.Entity:Reset()
			return true
		else
			return false
		end
  end

  -- Spawn or upload
  function TOOL:CheckHitOwnClass(trace)
    return trace.Entity:IsValid() and (trace.Entity:GetClass() == "gmod_wire_fpga")
  end
  function TOOL:LeftClick_Update(trace)
    trace.Entity:Upload()
  end
  function TOOL:MakeEnt(ply, model, Ang, trace)
    local ent = WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model})
    ent:Upload()
    return ent
  end

  -- Open editor
  function TOOL:RightClick(trace)
    net.Start("FPGA_OpenEditor") net.Send(self:GetOwner())
    return true
  end
end

if CLIENT then

  ------------------------------------------------------------------------------
  -- Open FPGA editor
  ------------------------------------------------------------------------------
  function FPGA_OpenEditor()
    if not FPGA_Editor then
      FPGA_Editor = vgui.Create("FPGAEditorFrame")
      FPGA_Editor:Setup("FPGA Editor", "fpgachip")
    end
    FPGA_Editor:Open()
  end
  net.Receive("FPGA_OpenEditor", FPGA_OpenEditor)

  ------------------------------------------------------------------------------
  -- Build tool control panel
  ------------------------------------------------------------------------------
  function TOOL.BuildCPanel(panel)
    local currentDirectory
    local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
    panel:AddPanel(FileBrowser)
    FileBrowser:Setup("fpgachip")
    FileBrowser:SetSize(235,400)
    function FileBrowser:OnFileOpen(filepath, newtab)
      if not FPGA_Editor then
        FPGA_Editor = vgui.Create("FPGAEditorFrame")
        FPGA_Editor:Setup("FPGA Editor", "fpgachip")
      end
      FPGA_Editor:Open(filepath, nil, newtab)
    end


    ----------------------------------------------------------------------------
    local New = vgui.Create("DButton" , panel)
    panel:AddPanel(New)
    New:SetText("New file")
    New.DoClick = function(button)
      FPGA_OpenEditor()
      FPGA_Editor:AutoSave()
      FPGA_Editor:NewScript(false)
    end
    panel:AddControl("Label", {Text = ""})

    ----------------------------------------------------------------------------
    local OpenEditor = vgui.Create("DButton", panel)
    panel:AddPanel(OpenEditor)
    OpenEditor:SetText("Open Editor")
    OpenEditor.DoClick = FPGA_OpenEditor


    ----------------------------------------------------------------------------
    panel:AddControl("Label", {Text = ""})
    panel:AddControl("Label", {Text = "FPGA settings:"})


    ----------------------------------------------------------------------------
    local modelPanel = WireDermaExts.ModelSelect(panel, "wire_fpga_model", list.Get("Wire_gate_Models"), 2)
    panel:AddControl("Label", {Text = ""})
  end
end