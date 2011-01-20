TOOL.Category	= "Wire - Advanced"
TOOL.Name	= "Display - GPU"
TOOL.Command	= nil
TOOL.ConfigName	= ""
TOOL.Tab			= "Wire"

if (CLIENT) then
	language.Add("Tool_wire_gpu_name", "GPU Tool (Wire)")
	language.Add("Tool_wire_gpu_desc", "Spawns a graphics processing unit")
	language.Add("Tool_wire_gpu_0", "Primary: Create / update GPU, Secondary: Open editor")//; Secondary: Debug the GPU
	language.Add("sboxlimit_wire_gpu", "You've hit GPU limit!")
	language.Add("undone_wiregpu", "Undone the wire GPU")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gpus', 20)
end

TOOL.ClientConVar["model"]             = "models/props_lab/monitor01b.mdl"
TOOL.ClientConVar["filename"]          = ""
TOOL.ClientConVar["packet_bandwidth"]  = 60
TOOL.ClientConVar["packet_rate_sp"]    = 0.05
TOOL.ClientConVar["packet_rate_mp"]    = 0.4
TOOL.ClientConVar["compile_rate"]      = 0.05
TOOL.ClientConVar["compile_bandwidth"] = 200
TOOL.ClientConVar["rom"]               = 1
TOOL.ClientConVar["rom_present"]       = 1
TOOL.ClientConVar["dump_data"]         = 0

cleanup.Register("wire_gpus")

//=============================================================================
if (SERVER) then
	GPU_SourceCode = {}

	local function AddSourceLine(pl, command, args)
		GPU_SourceCode[tonumber(args[1])] = tostring(args[2])
	end
	concommand.Add("wire_gpu_addsrc", AddSourceLine)

	local function ClearSource(pl, command, args)
		GPU_SourceCode = {}
	end
	concommand.Add("wire_gpu_clearsrc", ClearSource)
end
//=============================================================================

local function GPUStool_Version()
	local SVNString = "$Revision$"
	local rev = tonumber(string.sub(SVNString,12,14))
	if (rev) then
		return rev
	else
		return 0
	end
end

//=============================================================================

local function CompileProgram_Timer(tool,firstpass)
	if (firstpass && tool.FirstPassDone) then return end
	if (!firstpass && tool.SecondPassDone) then return end
	if (!tool:GetOwner()) then return end
	if (!tool.LineNumber) then return end

	local SendLinesMax = tool.LineNumber + tool:GetOwner():GetInfo("wire_gpu_compile_bandwidth")
	if (SendLinesMax > table.Count(GPU_SourceCode)) then SendLinesMax = table.Count(GPU_SourceCode) end
	local Rate = 0

	if (GPU_SourceCode[tostring(tool.LineNumber)]) then
		if (string.len(GPU_SourceCode[tostring(tool.LineNumber)]) > 256) then
			SendLinesMax = tool.LineNumber
		end
	end

	while (tool.LineNumber <= SendLinesMax) and (tool.GPU_Entity) do
		local line = GPU_SourceCode[tonumber(tool.LineNumber)]
		if (line) then
			if (string.len(line) > 254) then
				tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line "..tool.LineNumber.." too long! I compile it, but it may trigger infinite loop thing.\n")
			end
			if (tool.GPU_Entity.ParseProgram_ASM) then
				tool.GPU_Entity:ParseProgram_ASM(line,tool.LineNumber)
			end
		end

		tool.LineNumber = tool.LineNumber + 1
		Rate = Rate + 1
	end

	local TimeLeft = (table.Count(GPU_SourceCode)*2 - tool.LineNumber) / Rate
	if (not firstpass) then
		TimeLeft = (table.Count(GPU_SourceCode) - tool.LineNumber) / Rate
	end
	tool.PrevRate = (tool.PrevRate*1.5+TimeLeft*0.5) / 2
	TimeLeft = math.floor(tool.PrevRate / 10)

	local TempPercent = ((tool.LineNumber-1)/table.Count(GPU_SourceCode))*100
	if (firstpass) then
		if (!tool.FirstPassDone) then
			tool:GetOwner():ConCommand('wire_gpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_gpu_vgui_progress "'..math.floor(TempPercent/2)..'"')
		end
	else
		if (!tool.SecondPassDone) then
			tool:GetOwner():ConCommand('wire_gpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_gpu_vgui_progress "'..math.floor(50+TempPercent/2)..'"')
		end
	end

	if (tool.LineNumber > table.Count(GPU_SourceCode)) || (TempPercent >= 100) then
		if (!tool.FirstPassDone) then
			tool.FirstPassDone = true
			tool:Compile_Pass2()
		end
		if (!firstpass) && (!tool.SecondPassDone) then
			tool.SecondPassDone = true
			tool:Compile_End()
		end
	end

	if (tool.GPU_Entity.FatalError == true) then
		timer.Destroy("GPUCompileTimer1")
		timer.Destroy("GPUCompileTimer2")
		tool:Compile_End()
	end
end

//=============================================================================

function TOOL:StartCompile(pl)
	local ent = self.GPU_Entity
	if table.Count(GPU_SourceCode) == 0 then return end

	pl:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 2.0 (SVN REV "..GPUStool_Version()..") <----\n")
	pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")

	pl:ConCommand('wire_gpu_vgui_open')
	pl:ConCommand('wire_gpu_vgui_title "ZyeliosASM - Compiling"')
	pl:ConCommand('wire_gpu_vgui_status "Initializing"')
	pl:ConCommand('wire_gpu_vgui_progress "0"')

	ent.UseROM = self:GetClientInfo("rom") == "1"

	if (self:GetClientInfo("dump_data") == "1") then
		ent.MakeDump = true
		ent.Dump = "Code listing:\n"
	else
		ent.MakeDump = false
	end


	self.FirstPassDone = false
	self.SecondPassDone = false

	timer.Destroy("GPUCompileTimer1")
	timer.Destroy("GPUCompileTimer2")

	ent:WriteCell(65535,0)
	ent:Compiler_Stage0(pl)
	self:Compile_Pass1()
end

function TOOL:Compile_Pass1()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")

	self.Compiling = true
	self.GPU_Entity:Compiler_Stage1()

	self.LineNumber = 1
	self.PrevRate = 0
	timer.Create("GPUCompileTimer1",self:GetOwner():GetInfo("wire_gpu_compile_rate"),0,CompileProgram_Timer,self,true)
end

function TOOL:Compile_Pass2()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")

	self.Compiling = true
	self.GPU_Entity:Compiler_Stage2()

	self.LineNumber = 1
	timer.Create("GPUCompileTimer2",self:GetOwner():GetInfo("wire_gpu_compile_rate"),0,CompileProgram_Timer,self,false)
end


function TOOL:Compile_End()
	local pl = self:GetOwner()
	local ent = self.GPU_Entity

	if (ent.FatalError) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")
	else
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..(table.Count(GPU_SourceCode)-1).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.\n")
	end

	pl:ConCommand('wire_gpu_vgui_close')

	ent:WriteCell(65535,1)
	ent:FlushCache()

	//if (self:GetClientInfo("dump_data") == "1") then
	//	pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
	//	local codedump = "Count: "..ent.WIP.."\n"
	//	//local pointerdump = "Count: "..table.Count(ent.Labels).."\n"
	//	for i = 0,ent.WIP do
	//		if (ent.Memory[i]) then
	//			codedump = codedump.."["..i.."]".."="..ent.Memory[i].."\n"
	//		end
	//	end
	//	/*for k,v in pairs(ent.Labels) do
	//		pointerdump = pointerdump.."#pointer "..k.." "..v.."\n"
	//	end*/
	//	file.Write("cdump.txt",codedump)
	//	file.Write("ldump.txt",ent.Dump)
	//	//file.Write("pdump.txt",pointerdump)
	//	pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
	//end

	if ((self:GetClientInfo("dump_data") == "1") && (SinglePlayer())) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
		local codedump = "db "
		for i = 0,ent.WIP do
			if (i % 32 == 31) then
				if (!ent.Memory[i]) then
					codedump = codedump.."0\ndb "
				else
					codedump = codedump..ent.Memory[i].."\ndb "
				end
			else
				if (!ent.Memory[i]) then
					codedump = codedump.."0,"
				else
					codedump = codedump..ent.Memory[i]..","
				end
			end
		end

		file.Write("cdump.txt",codedump)
		file.Write("ldump.txt",ent.Dump)
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
	end

	--if (self:GetClientInfo("dump_data") == "1") then
	--	pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
	--	local codedump = ""
	--	for i = 0,ent.WIP do
	--		if (ent.Memory[i]) then
	--			codedump = codedump.."db "..ent.Memory[i].."\n"
	--		end
	--	end
	--	file.Write("cdump.txt",codedump)
	--	pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
	--end

	ent:Reset()
	ent.Compiling = false
end

//=============================================================================
function TOOL:Reload(trace)
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gpu" && trace.Entity.pl == ply) then
		trace.Entity.Memory = {}
		return true
	end
end

function TOOL:LeftClick(trace)
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	self.GPU_Entity = trace.Entity

	if not trace.Entity:IsValid() or trace.Entity:GetClass() ~= "gmod_wire_gpu" or trace.Entity.pl ~= ply then

		if not self:GetSWEP():CheckLimit("wire_gpus") then return false end
		if not util.IsValidModel(self:GetClientInfo("model")) then return false end
		if not util.IsValidProp(self:GetClientInfo("model")) then return false end

		local ang   = trace.HitNormal:Angle()
		local model = self:GetClientInfo("model")
		ang.pitch = ang.pitch + 90

		wire_gpu = MakeWireGpu(ply, trace.HitPos, ang, model)
		local min = wire_gpu:OBBMins()
		wire_gpu:SetPos(trace.HitPos - trace.HitNormal * min.z)

		local const = WireLib.Weld(wire_gpu, trace.Entity, trace.PhysicsBone, true)

		undo.Create("Wire GPU")
			undo.AddEntity(wire_gpu)
			undo.AddEntity(const)
			undo.SetPlayer(ply)
		undo.Finish()

		ply:AddCleanup("wire_gpus", wire_gpu)
		ply:AddCleanup("wire_gpus", const)
		self.GPU_Entity = wire_gpu
	end

	self:StartCompile(ply)
	return true
end

function TOOL:RightClick(trace)
	if SERVER then self:GetOwner():SendLua("wire_gpu_OpenEditor()") end
end

if (SERVER) then
	function MakeWireGpu(pl, Pos, Ang, model)
		if (!pl:CheckLimit("wire_gpus")) then return false end

		local wire_gpu = ents.Create("gmod_wire_gpu")
		if (!wire_gpu:IsValid()) then return false end
		wire_gpu:SetModel(model)

		wire_gpu:SetAngles(Ang)
		wire_gpu:SetPos(Pos)
		wire_gpu:Spawn()

		wire_gpu:SetPlayer(pl)

		local ttable = {
			pl = pl,
			model = model,
		}
		table.Merge(wire_gpu:GetTable(), ttable)
		pl:AddCount("wire_gpus", wire_gpu)

		return wire_gpu
	end
	duplicator.RegisterEntityClass("gmod_wire_gpu", MakeWireGpu, "Pos", "Ang", "Model")
end

function TOOL:UpdateGhostWireGpu(ent, player)
	if (!ent) then return end
	if (!ent:IsValid()) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_gpu" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw(true)
		return
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("model") || (not self.GhostEntity:GetModel())) then
		self:MakeGhostEntity(self:GetClientInfo("model"), Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireGpu(self.GhostEntity, self:GetOwner())
end

//=============================================================================
// Code sending
//=============================================================================
if (CLIENT) then
	local Frame
	local StatusLabel
	local PLabel
	local ProgressBar
	local BGBar

	function wire_gpu_OpenEditor()
		if not GPU_Editor then
			GPU_Editor = vgui.Create( "Expression2EditorFrame")
			GPU_Editor:Setup("GPU Editor", "GPUChip", "GPU")
		end
		GPU_Editor:Open()
	end

	local function VGUI_Open(pl, command, args)
		if (Frame) then
			Frame:SetVisible(false)
		end

		Frame = vgui.Create("Panel")
		Frame:SetSize(400,50)
		Frame:SetPos(150,150)
		Frame:SetVisible(true)

		BGBar = vgui.Create("ProgressBar",Frame)
		BGBar:SetVisible(true)
		BGBar:SetSize(400,100)
		BGBar:SetPos(0,0)

		StatusLabel = vgui.Create("Label",Frame)
		StatusLabel:SetSize(380,30)
		StatusLabel:SetPos(10,10)
		StatusLabel:SetVisible(true)

		PLabel = vgui.Create("Label",Frame)
		PLabel:SetSize(30,30)
		PLabel:SetPos(360,10)
		PLabel:SetVisible(true)

		ProgressBar = vgui.Create("ProgressBar",Frame)
		ProgressBar:SetSize(280,30)
		ProgressBar:SetPos(10,60)
		ProgressBar:SetVisible(false)
	end
	concommand.Add("wire_gpu_vgui_open", VGUI_Open)

	local function VGUI_Close(pl, command, args)
		Frame:SetVisible(false);
	end
	concommand.Add("wire_gpu_vgui_close", VGUI_Close)

	local function VGUI_Title(pl, command, args)
		Frame:PostMessage("SetTitle", "text", args[1]);
	end
	concommand.Add("wire_gpu_vgui_title", VGUI_Title)

	local function VGUI_Status(pl, command, args)
		StatusLabel:PostMessage("SetText", "text", args[1]);
	end
	concommand.Add("wire_gpu_vgui_status", VGUI_Status)

	local function VGUI_Progress(pl, command, args)
		if (args[1]) then
			ProgressBar:PostMessage("SetValue", "Float", tonumber(args[1])/100);
			PLabel:PostMessage("SetText", "text", args[1] .. "%");
		end
	end
	concommand.Add("wire_gpu_vgui_progress", VGUI_Progress)
end

if (CLIENT) then

SourceLines = {}
SourceLineNumbers = {}
SourceLinesSent = 0
SourcePrevCharRate = 0
SourceTotalChars = 0
SourceLoadedChars = 0

function GPU_UploadProgram(pl)
	local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_gpu_packet_bandwidth")
	local TotalChars = 0
	if SendLinesMax > table.Count(SourceLines) then
		SendLinesMax = table.Count(SourceLines)
	end

	while (SourceLinesSent <= SendLinesMax) && (TotalChars < 1024) do
		SourceLinesSent = SourceLinesSent + 1
		local line = SourceLines[SourceLinesSent]
		local linen = SourceLinesSent

		if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
			RunConsoleCommand("wire_gpu_addsrc",linen,string.gsub(line, "\n", ""))
			TotalChars = TotalChars + string.len(line)
		else
			RunConsoleCommand("wire_gpu_addsrc",linen,"")
		end
	end
	SourceLoadedChars = SourceLoadedChars + TotalChars

	local CharRate = (SourcePrevCharRate*1.95 + TotalChars*0.05) / 2
	SourcePrevCharRate = CharRate

	if SinglePlayer() then
		CharRate = CharRate / pl:GetInfo("wire_gpu_packet_rate_sp")
	else
		CharRate = CharRate / pl:GetInfo("wire_gpu_packet_rate_mp")
	end

	local TimeLeft = math.floor((SourceTotalChars - SourceLoadedChars) / CharRate)
	local TempPercent = math.floor(((SourceLinesSent-1)/table.Count(SourceLines))*100)

	pl:ConCommand('wire_gpu_vgui_status "Uploading @ '..math.floor(CharRate / 1024)..' kb/sec, avg. '..TimeLeft..' sec left, '..SourceLinesSent..' lines sent"')
	pl:ConCommand('wire_gpu_vgui_progress "'..TempPercent..'"')

	if (SourceLinesSent > table.Count(SourceLines)) then
		pl:ConCommand('wire_gpu_vgui_close')
		timer.Remove("GPUSendTimer")
	end
end

function GPU_LoadProgram(pl, command, args)
	local fname = "GPUChip\\"..pl:GetInfo("wire_gpu_filename");
	if (!file.Exists(fname)) then
		fname = "GPUChip\\"..pl:GetInfo("wire_gpu_filename")..".txt";
	end

	if (!file.Exists(fname)) then
		pl:PrintMessage(HUD_PRINTTALK,"GPU -> Sorry! Requested file was not found\n")
		return
	end

	pl:ConCommand('wire_gpu_clearsrc')

	local filedata = file.Read(fname)
	if (!filedata) then
		return
	end

	SourceLines = string.Explode("\n", filedata)
	SourceLinesSent = 0
	SourceTotalChars = string.len(filedata)

	SourcePrevCharRate = string.len(SourceLines[1])
	SourceLoadedChars = 0

	pl:ConCommand('wire_gpu_vgui_open')
	pl:ConCommand('wire_gpu_vgui_title "GPU - Uploading program"')
	pl:ConCommand('wire_gpu_vgui_status "Initializing"')
	pl:ConCommand('wire_gpu_vgui_progress "0"')

	//Send 50 lines
	if (SinglePlayer()) then
		timer.Create("GPUSendTimer",pl:GetInfo("wire_gpu_packet_rate_sp"),0,GPU_UploadProgram,pl,false)
	else
		timer.Create("GPUSendTimer",pl:GetInfo("wire_gpu_packet_rate_mp"),0,GPU_UploadProgram,pl,false)
	end
end

end

local function LoadProgram(pl, command, args)
	if (SERVER) then
		pl:SendLua("GPU_LoadProgram(LocalPlayer())")
	else
		GPU_LoadProgram(pl, command, args)
	end
end
concommand.Add("wire_gpu_load", LoadProgram)

local function ClearProgram(pl, command, args)
	pl:ConCommand('wire_gpu_clearsrc')
end
concommand.Add("wire_gpu_clear", ClearProgram)

//=============================================================================
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gpu_name", Description = "#Tool_wire_gpu_desc" })

	panel:AddControl("TextBox", {
		Label = "Source code file name",
		Command = "wire_gpu_filename",
		MaxLength = "128"
	})

	local dir
	local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
	panel:AddPanel(FileBrowser)
	FileBrowser:Setup("GPUChip")
	FileBrowser:SetSize(235,400)
	function FileBrowser:OnFileClick()
		local lastclick = CurTime()
		if not GPU_Editor then
			GPU_Editor = vgui.Create( "Expression2EditorFrame")
			GPU_Editor:Setup("GPU Editor", "GPUChip", "GPU")
		end

		if(dir == self.File.FileDir and CurTime() - lastclick < 1) then
			GPU_Editor:Open(dir)
		else
			lastclick = CurTime()
			dir = self.File.FileDir
			LocalPlayer():ConCommand("wire_gpu_filename "..string.Right(dir, string.len(dir)-8))
		end
	end

	panel:AddControl("Button", {
		Text = "Quick Load",
		Name = "Load",
		Command = "wire_gpu_load"
	})
	local New = vgui.Create("DButton" , panel)
	panel:AddPanel(New)
	New:SetText("New file")
	New.DoClick = function(button)
		wire_gpu_OpenEditor()
		GPU_Editor:AutoSave()
		GPU_Editor:ChosenFile()
		GPU_Editor:SetCode("\n\n")
	end

	panel:AddControl("Label", {Text = ""})

	local OpenEditor = vgui.Create("DButton", panel)
	panel:AddPanel(OpenEditor)
	OpenEditor:SetText("Code Editor")
	OpenEditor.DoClick = wire_gpu_OpenEditor

	panel:AddControl("Label", {Text = ""})

	WireDermaExts.ModelSelect(panel, "wire_gpu_model", list.Get( "WireScreenModels" ), 2)
	panel:AddControl("Label", {
		Text = ""
	})
	panel:AddControl("Button", {
		Text = "ZGPU documentation (online)"
	})
	panel:AddControl("Label", {
		Text = "Loads online GPU documentation and tutorials (WILL WORK SOON)"
	})
end
