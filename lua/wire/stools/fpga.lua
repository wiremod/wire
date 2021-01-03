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
  util.AddNetworkString("FPGA_Upload")
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
    self:Upload(trace.Entity)
  end
  function TOOL:MakeEnt(ply, model, Ang, trace)
    local ent = WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model})
    return ent
  end
  function TOOL:PostMake(ent)
    self:Upload(ent)
  end

  -- Open editor
  function TOOL:RightClick(trace)
    --check if hit chip, download the nodes off that chip
    net.Start("FPGA_OpenEditor") net.Send(self:GetOwner())
    return true
  end



  ------------------------------------------------------------------------------
  -- Uploading (Server -> Client -> Server)
  ------------------------------------------------------------------------------
  -- Send request to client for FPGA data
  function TOOL:Upload(ent)
    net.Start("FPGA_Upload")
			net.WriteInt(ent:EntIndex(), 32)
		net.Send(self:GetOwner())
  end
end
if CLIENT then
  --------------------------------------------------------------
	-- Clientside Send
  --------------------------------------------------------------
  function WireLib.FPGAUpload(targetEnt, data)
		if type(targetEnt) == "number" then targetEnt = Entity(targetEnt) end
		targetEnt = targetEnt or LocalPlayer():GetEyeTrace().Entity
    
		if (not IsValid(targetEnt) or targetEnt:GetClass() ~= "gmod_wire_fpga") then
			WireLib.AddNotify("Invalid FPGA entity specified!", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end
		
    data = data or FPGA_Editor:GetData()
    
    data = WireLib.FPGACompile(data)
		
    net.Start("FPGA_Upload")
      net.WriteEntity(targetEnt)
      net.WriteString(data)
    net.SendToServer()
	end
  
  -- Received request to upload
	net.Receive("FPGA_Upload", function(len, ply)
    local entid = net.ReadInt(32)
		timer.Create("FPGA_Upload_Delay",0.03,30,function() -- The new net library is so fast sometimes the chip gets fully uploaded before the entity even exists.
			if IsValid(Entity(entid)) then
				WireLib.FPGAUpload(entid)
				timer.Remove("FPGA_Upload_Delay")
				timer.Remove("FPGA_Upload_Delay_Error")
			end
		end)
		timer.Create("FPGA_Upload_Delay_Error",0.03*31,1,function() WireLib.AddNotify("Invalid FPGA entity specified!", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3) end)
  end)
  
  -- Node 'compiler'
  -- Flip connections, generate input output tabels
  function WireLib.FPGACompile(data)


    return data
  end
end

if SERVER then
  --------------------------------------------------------------
	-- Serverside Receive
  --------------------------------------------------------------
  -- Receive FPGA data from client
	net.Receive("FPGA_Upload",function(len, ply)
		local chip = net.ReadEntity()
		--local numpackets = net.ReadUInt(16)
	
		if not IsValid(chip) or chip:GetClass() ~= "gmod_wire_fpga" then
			WireLib.AddNotify(ply, "Invalid FPGA chip specified. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			return
		end

		-- if not E2Lib.isFriend(toent.player,ply) then
		-- 	WireLib.AddNotify(ply, "You are not allowed to upload to the target FPGA chip. Upload aborted.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
		-- 	return
		-- end
		
    local data = net.ReadString()
    local ok, ret = pcall(WireLib.von.deserialize, data)
    
    if ok then
      chip:Upload(ret)
    else
      WireLib.AddNotify(ply, "FPGA upload failed! Error message:\n" .. ret, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
    end
	end)

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