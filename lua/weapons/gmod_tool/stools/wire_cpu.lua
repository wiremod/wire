TOOL.Category   = "Wire - Control"
TOOL.Name       = "Chip - CPU"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if (CLIENT) then
	language.Add("Tool_wire_cpu_name", "CPU Tool (Wire)")
	language.Add("Tool_wire_cpu_desc", "Spawns a central processing unit")
	language.Add("Tool_wire_cpu_0", "Primary: Create / Update CPU, Secondary: Open editor")//; Secondary: Debug the CPU
	language.Add("sboxlimit_wire_cpu", "You've hit CPU limit!")
	language.Add("undone_wirecpu", "Undone the wire CPU")
	language.Add( "ToolWirecpu_Model", "Model:" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cpus', 20)
end

TOOL.ClientConVar = {
	model             = "models/cheeze/wires/cpu.mdl",
	filename          = "",
	packet_bandwidth  = 300,
	packet_rate_sp    = 0.05,
	packet_rate_mp    = 0.4,
	compile_rate      = 0.05,
	compile_bandwidth = 200,
	rom               = 1,
	rom_present       = 1,
	dump_data         = 0
}

cleanup.Register("wire_cpus")

//=============================================================================
if (SERVER) then
	CPU_SourceCode = {}

	local function AddSourceLine(pl, command, args)
		CPU_SourceCode[tonumber(args[1])] = tostring(args[2])
	end
	concommand.Add("wire_cpu_addsrc", AddSourceLine)

	local function ClearSource(pl, command, args)
		CPU_SourceCode = {}
	end
	concommand.Add("wire_cpu_clearsrc", ClearSource)
end
//=============================================================================

local function CPUStool_Version()
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

	local SendLinesMax = tool.LineNumber + tool:GetOwner():GetInfo("wire_cpu_compile_bandwidth")
	if (SendLinesMax > table.Count(CPU_SourceCode)) then SendLinesMax = table.Count(CPU_SourceCode) end
	local Rate = 0

	if (CPU_SourceCode[tostring(tool.LineNumber)]) then
		if (string.len(CPU_SourceCode[tostring(tool.LineNumber)]) > 256) then
			SendLinesMax = tool.LineNumber
		end
	end

	while (tool.LineNumber <= SendLinesMax) and (tool.CPU_Entity) do
		local line = CPU_SourceCode[tonumber(tool.LineNumber)]
		if (line) then
			if (string.len(line) > 254) then
				tool:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Line "..tool.LineNumber.." too long! I compile it, but it may trigger infinite loop thing.\n")
			end
			if (tool.CPU_Entity.ParseProgram_ASM) then
				tool.CPU_Entity:ParseProgram_ASM(line,tool.LineNumber)
			end
		end

		tool.LineNumber = tool.LineNumber + 1
		Rate = Rate + 1
	end

	local TimeLeft = (table.Count(CPU_SourceCode)*2 - tool.LineNumber) / Rate
	if (not firstpass) then
		TimeLeft = (table.Count(CPU_SourceCode) - tool.LineNumber) / Rate
	end
	tool.PrevRate = (tool.PrevRate*1.5+TimeLeft*0.5) / 2
	TimeLeft = math.floor(tool.PrevRate / 10)

	local TempPercent = ((tool.LineNumber-1)/table.Count(CPU_SourceCode))*100
	if (firstpass) then
		if (!tool.FirstPassDone) then
			tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(TempPercent/2)..'"')
		end
	else
		if (!tool.SecondPassDone) then
			tool:GetOwner():ConCommand('wire_cpu_vgui_status "Compiling ('.. TimeLeft ..' seconds left), '..tool.LineNumber..' lines processed"')
			tool:GetOwner():ConCommand('wire_cpu_vgui_progress "'..math.floor(50+TempPercent/2)..'"')
		end
	end

	if (tool.LineNumber > table.Count(CPU_SourceCode)) || (TempPercent >= 100) then
		if (!tool.FirstPassDone) then
			tool.FirstPassDone = true
			tool:Compile_Pass2()
		end
		if (!firstpass) && (!tool.SecondPassDone) then
			tool.SecondPassDone = true
			tool:Compile_End()
		end
	end

	if (tool.CPU_Entity.FatalError == true) then
		timer.Destroy("CPUCompileTimer1")
		timer.Destroy("CPUCompileTimer2")
		tool:Compile_End()
	end
end

//=============================================================================

-- TODO: shouldn't this take ent instead of pl? since pl = self:GetOwner()
function TOOL:StartCompile(pl)
	local ent = self.CPU_Entity
	if table.Count(CPU_SourceCode) == 0 then return end

	pl:PrintMessage(HUD_PRINTCONSOLE,"----> ZyeliosASM compiler - Version 2.0 (SVN REV "..CPUStool_Version().."/"..ent:CPUID_Version()..") <----\n")
	pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compiling...\n")

	pl:ConCommand('wire_cpu_vgui_open')
	pl:ConCommand('wire_cpu_vgui_title "ZyeliosASM - Compiling"')
	pl:ConCommand('wire_cpu_vgui_status "Initializing"')
	pl:ConCommand('wire_cpu_vgui_progress "0"')

	ent.UseROM = self:GetClientInfo("rom") == "1"

	if (self:GetClientInfo("dump_data") == "1") then
		ent.MakeDump = true
		ent.Dump = "Code listing:\n"
	else
		ent.MakeDump = false
	end


	self.FirstPassDone = false
	self.SecondPassDone = false

	timer.Destroy("CPUCompileTimer1")
	timer.Destroy("CPUCompileTimer2")

	ent:Compiler_Stage0(pl)
	self:Compile_Pass1()
end

function TOOL:Compile_Pass1()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 1\n")

	self.Compiling = true
	self.CPU_Entity:Compiler_Stage1()

	self.LineNumber = 1
	self.PrevRate = 0
	timer.Create("CPUCompileTimer1",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,self,true)
end

function TOOL:Compile_Pass2()
	if (!self:GetOwner()) then return end
	self:GetOwner():PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Pass 2\n")

	self.Compiling = true
	self.CPU_Entity:Compiler_Stage2()

	self.LineNumber = 1
	timer.Create("CPUCompileTimer2",self:GetOwner():GetInfo("wire_cpu_compile_rate"),0,CompileProgram_Timer,self,false)
end


function TOOL:Compile_End()
	local pl = self:GetOwner()
	local ent = self.CPU_Entity

	if (ent.FatalError) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile aborted: fatal error has occured\n")
	else
		pl:PrintMessage(HUD_PRINTCONSOLE,"-> ZyeliosASM: Compile succeded! "..(table.Count(CPU_SourceCode)-1).." lines, "..ent.WIP.." bytes, "..table.Count(ent.Labels).." definitions.\n")
	end

	pl:ConCommand('wire_cpu_vgui_close')

	if ((self:GetClientInfo("dump_data") == "1") && (SinglePlayer())) then
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumping data\n")
		local codedump = ""
		for i = 0,ent.WIP do
			if (ent.Memory[i]) then
				codedump = codedump.."db "..ent.Memory[i].."\n"
			end
		end
		file.Write("cdump.txt",codedump)
		file.Write("ldump.txt",ent.Dump)
		pl:PrintMessage(HUD_PRINTCONSOLE,"ZyeliosASM: Dumped!\n")
	end

	ent:Reset()
	ent.Compiling = false
end

local last_error = "Press Ctrl-Space to go to the last CPU/GPU error."

usermessage.Hook("wire_cpu_error", function(um)
	last_error = um:ReadString()
end)

function wire_cpu_validate(buffer)
	return last_error
end

//=============================================================================
function TOOL:Reload(trace)
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cpu" && trace.Entity.pl == ply) then
		trace.Entity.Memory = {}
		trace.Entity.ROMMemory = {}
		trace.Entity.PrecompileData = {}
		trace.Entity.PrecompileMemory = {}
		return true
	end
end

function TOOL:LeftClick(trace)
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	self.CPU_Entity = trace.Entity

	if not trace.Entity:IsValid() or trace.Entity:GetClass() ~= "gmod_wire_cpu" or trace.Entity.pl ~= ply then

		if (!self:GetSWEP():CheckLimit("wire_cpus")) 		then return false end
		if (not util.IsValidModel(self:GetClientInfo("model"))) then return false end
		if (not util.IsValidProp(self:GetClientInfo("model"))) 	then return false end

		local ang   = trace.HitNormal:Angle()
		local model = self:GetClientInfo("model")
		ang.pitch = ang.pitch + 90

		wire_cpu = MakeWireCpu(ply, trace.HitPos, ang, model)
		local min = wire_cpu:OBBMins()
		wire_cpu:SetPos(trace.HitPos - trace.HitNormal * min.z)

		local const = WireLib.Weld(wire_cpu, trace.Entity, trace.PhysicsBone, true)

		undo.Create("Wire CPU")
			undo.AddEntity(wire_cpu)
			undo.AddEntity(const)
			undo.SetPlayer(ply)
		undo.Finish()

		ply:AddCleanup("wire_cpus", wire_cpu)
		ply:AddCleanup("wire_cpus", const)

		self.CPU_Entity = wire_cpu
	end

	self:StartCompile(ply)
	return true
end

function TOOL:RightClick(trace)
	if SERVER then self:GetOwner():SendLua("wire_cpu_OpenEditor()") end
end

if (SERVER) then
	function MakeWireCpu(pl, Pos, Ang, model)
		if (!pl:CheckLimit("wire_cpus")) then return false end

		local wire_cpu = ents.Create("gmod_wire_cpu")
		if (!wire_cpu:IsValid()) then return false end
		wire_cpu:SetModel(model)

		wire_cpu:SetAngles(Ang)
		wire_cpu:SetPos(Pos)
		wire_cpu:Spawn()

		wire_cpu:SetPlayer(pl)

		local ttable = {
			pl = pl,
		}
		table.Merge(wire_cpu:GetTable(), ttable) -- TODO: remove maybe?
		pl:AddCount("wire_cpus", wire_cpu)

		return wire_cpu
	end
	duplicator.RegisterEntityClass("gmod_wire_cpu", MakeWireCpu, "Pos", "Ang", "Model")
end

function TOOL:UpdateGhostWireCpu(ent, player)
	if (!ent) then return end
	if (!ent:IsValid()) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_cpu" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireCpu(self.GhostEntity, self:GetOwner())
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
	concommand.Add("wire_cpu_vgui_open", VGUI_Open)

	local function VGUI_Close(pl, command, args)
		Frame:SetVisible(false);
	end
	concommand.Add("wire_cpu_vgui_close", VGUI_Close)

	local function VGUI_Title(pl, command, args)
		Frame:PostMessage("SetTitle", "text", args[1]);
	end
	concommand.Add("wire_cpu_vgui_title", VGUI_Title)

	local function VGUI_Status(pl, command, args)
		StatusLabel:PostMessage("SetText", "text", args[1]);
	end
	concommand.Add("wire_cpu_vgui_status", VGUI_Status)

	local function VGUI_Progress(pl, command, args)
		if (args[1]) then
			ProgressBar:PostMessage("SetValue", "Float", tonumber(args[1])/100);
			PLabel:PostMessage("SetText", "text", args[1] .. "%");
		end
	end
	concommand.Add("wire_cpu_vgui_progress", VGUI_Progress)
end

if (CLIENT) then

	SourceLines = {}
	SourceLineNumbers = {}
	SourceLinesSent = 0
	SourcePrevCharRate = 0
	SourceTotalChars = 0
	SourceLoadedChars = 0

	function wire_cpu_OpenEditor()
		if not CPU_Editor then
			CPU_Editor = vgui.Create( "Expression2EditorFrame")
			CPU_Editor:Setup("CPU Editor", "CPUChip", "CPU")
		end
		CPU_Editor:Open()
	end

	function CPU_UploadProgram(pl)
		local SendLinesMax = SourceLinesSent + pl:GetInfo("wire_cpu_packet_bandwidth")
		local TotalChars = 0
		if SendLinesMax > table.Count(SourceLines) then
			SendLinesMax = table.Count(SourceLines)
		end

		while (SourceLinesSent <= SendLinesMax) && (TotalChars < 1024) do
			SourceLinesSent = SourceLinesSent + 1
			local line = SourceLines[SourceLinesSent]
			local linen = SourceLinesSent

			if (line) && (line ~= "\n") && (string.gsub(line, "\n", "") ~= "") then
				RunConsoleCommand("wire_cpu_addsrc",linen,string.gsub(line, "\n", ""))
				TotalChars = TotalChars + string.len(line)
			else
				RunConsoleCommand("wire_cpu_addsrc",linen,"")
			end
		end
		SourceLoadedChars = SourceLoadedChars + TotalChars

		local CharRate = (SourcePrevCharRate*1.95 + TotalChars*0.05) / 2
		SourcePrevCharRate = CharRate

		if SinglePlayer() then
			CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_sp")
		else
			CharRate = CharRate / pl:GetInfo("wire_cpu_packet_rate_mp")
		end

		local TimeLeft = math.floor((SourceTotalChars - SourceLoadedChars) / CharRate)
		local TempPercent = math.floor(((SourceLinesSent-1)/table.Count(SourceLines))*100)

		pl:ConCommand('wire_cpu_vgui_status "Uploading @ '..math.floor(CharRate / 1024)..' kb/sec, avg. '..TimeLeft..' sec left, '..SourceLinesSent..' lines sent"')
		pl:ConCommand('wire_cpu_vgui_progress "'..TempPercent..'"')

		if (SourceLinesSent > table.Count(SourceLines)) then
			pl:ConCommand('wire_cpu_vgui_close')
			timer.Remove("CPUSendTimer")
		end
	end

	-- FIXME: REMOVE THIS AFTER GMOD UPDATE FIXES STRING.EXLODE
local function string_Asplode( seperator, str )
	local tbl = {}
	local i = 1

	if ( seperator == "" ) then
		return string.ToTable( str )
	elseif ( #seperator > 1 or seperator == "%" ) then
		local newpos, pos, start = 0
		repeat
			pos = newpos + 1
			start, newpos = str:find( seperator, pos, true )
			tbl[i] = str:sub( pos, ( start or 0 ) - 1 )
			i = i + 1
		until not start
	else
		for s in string.gmatch( str, "([^" .. seperator .. "]*)" .. seperator .. "?" ) do
			tbl[i] = s
			i = i + 1
		end
	end

	return tbl
end

	function CPU_LoadProgram(pl, command, args)
		local fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename")
		if (!file.Exists(fname)) then
			fname = "CPUChip\\"..pl:GetInfo("wire_cpu_filename")..".txt"
		end

		if (!file.Exists(fname)) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! Requested file was not found\n")
			return
		end

		pl:ConCommand('wire_cpu_clearsrc')

		local filedata = file.Read(fname)
		if (!filedata) then
			pl:PrintMessage(HUD_PRINTTALK,"CPU -> Sorry! File was found, but leprechauns prevented it from getting read!\n") //This message occurs rarely enough to put something fun here
			return
		end

		SourceLines = string_Asplode("\n", filedata)
		SourceLinesSent = 0
		SourceTotalChars = string.len(filedata)

		//Parse include files
		if (string.find(filedata,"##include##", 1, true)) then
			for i=1,#SourceLines do
				if (string.sub(SourceLines[i],1,12) == "##include## ") then
					local fname2 = string.sub(SourceLines[i],13)
					if (file.Exists("CPUChip\\"..fname2)) then
						SourceLines[i] = "asmfile "..fname.."\n"..file.Read("CPUChip\\"..fname2).."\nasmend\n"
					else
						SourceLines[i] = ""
					end
				end
			end

			filedata = string.Implode("\n", SourceLines)
			SourceLines = string.Explode("\n", filedata)
			SourceLinesSent = 0
			SourceTotalChars = string.len(filedata)
		end

		SourcePrevCharRate = string.len(SourceLines[1])
		SourceLoadedChars = 0

		pl:ConCommand('wire_cpu_vgui_open')
		pl:ConCommand('wire_cpu_vgui_title "CPU - Uploading program"')
		pl:ConCommand('wire_cpu_vgui_status "Initializing"')
		pl:ConCommand('wire_cpu_vgui_progress "0"')

		//Send 50 lines
		if (SinglePlayer()) then
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_sp"),0,CPU_UploadProgram,pl,false)
		else
			timer.Create("CPUSendTimer",pl:GetInfo("wire_cpu_packet_rate_mp"),0,CPU_UploadProgram,pl,false)
		end
	end

end

local function LoadProgram(pl, command, args)
	if (SERVER) then
		pl:SendLua("CPU_LoadProgram(LocalPlayer())")
	else
		CPU_LoadProgram(pl, command, args)
	end
end
concommand.Add("wire_cpu_load", LoadProgram)

local function ClearProgram(pl, command, args)
	pl:ConCommand('wire_cpu_clearsrc')
end
concommand.Add("wire_cpu_clear", ClearProgram)

//end

//=============================================================================
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cpu_name", Description = "#Tool_wire_cpu_desc" })

	panel:AddControl("TextBox", {
		Label = "Source code file name",
		Command = "wire_cpu_filename",
		MaxLength = "128"
	})

	local dir
	local FileBrowser = vgui.Create("wire_expression2_browser" , panel)
	panel:AddPanel(FileBrowser)
	FileBrowser:Setup("CPUChip")
	FileBrowser:SetSize(235,400)
	function FileBrowser:OnFileClick()
		local lastclick = CurTime()
		if not CPU_Editor then
			CPU_Editor = vgui.Create( "Expression2EditorFrame")
			CPU_Editor:Setup("CPU Editor", "CPUChip", "CPU")
		end

		if(dir == self.File.FileDir and CurTime() - lastclick < 1) then
			CPU_Editor:Open(dir)
		else
			lastclick = CurTime()
			dir = self.File.FileDir
			LocalPlayer():ConCommand("wire_cpu_filename "..string.Right(dir, string.len(dir)-8))
		end
	end

	panel:AddControl("Button", {
		Text = "Load into compiler",
		Name = "Load",
		Command = "wire_cpu_load"
	})
	local New = vgui.Create("DButton" , panel)
	panel:AddPanel(New)
	New:SetText("New file")
	New.DoClick = function(button)
		wire_cpu_OpenEditor()
		CPU_Editor:AutoSave()
		CPU_Editor:ChosenFile()
		CPU_Editor:SetCode("\n\n")
	end

	panel:AddControl("Label", {Text = ""})

	//panel:AddControl("Button", {
	//	Text = "Code editor"
	//})

	local OpenEditor = vgui.Create("DButton", panel)
	panel:AddPanel(OpenEditor)
	OpenEditor:SetText("Code Editor")
	OpenEditor.DoClick = wire_cpu_OpenEditor

	panel:AddControl("Label", {Text = ""})

	panel:AddControl("Label", {
		Text = "CPU settings:"
	})


	panel:AddControl("CheckBox", {
		Label = "Use CPU ROM",
		Command = "wire_cpu_rom"
	})
	panel:AddControl("Label", {
		Text = "ROM data is saved with advanced duplicator and is stored between CPU resets"
	})

	panel:AddControl("ComboBox", {
		Label = "CPU Model",
		Options = {
			["AMD64"]    	    = { wire_cpu_model = "models/cheeze/wires/cpu.mdl" },
			["AMD64 Mini"]    = { wire_cpu_model = "models/cheeze/wires/mini_cpu.mdl" },
		["WireCPU"]    = { wire_cpu_model = "models/cheeze/wires/cpu2.mdl" },
		["WireCPU Mini"]    = { wire_cpu_model = "models/cheeze/wires/mini_cpu2.mdl"},

		}
	})

	panel:AddControl("Label", {Text = ""})

	panel:AddControl("Label", {
		Text = "These do not work yet:"
	})

	panel:AddControl("CheckBox", {
		Label = "CPU ROM Present",
		Command = "wire_cpu_rom_present"
	})
	panel:AddControl("Label", {
		Text = "CPU can be without internal ROM/RAM (you need to attach RAM/ROM manually)"
	})


	panel:AddControl("CheckBox", {
		Label = "Dump CPU data",
		Command = "wire_cpu_dump_data"
	})
	panel:AddControl("Label", {
		Text = "Dumps CPU information and compiled code to pdump/cdump/ldump files in DATA folder (server host, or singleplayer only)"
	})


	panel:AddControl("Button", {
		Text = "ZCPU documentation (online)"
	})
	panel:AddControl("Label", {
		Text = "Loads online CPU documentation and tutorials"
	})
end
