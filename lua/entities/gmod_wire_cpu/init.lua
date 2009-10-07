if (EmuFox) then
	include('gmod_wire_cpu/compiler_asm.lua')

	include('gmod_wire_cpu/cpu_bitwise.lua')
	include('gmod_wire_cpu/cpu_vm.lua')
	include('gmod_wire_cpu/cpu_opcodes.lua')
	include('gmod_wire_cpu/cpu_bus.lua')
	include('gmod_wire_cpu/cpu_interrupt.lua')
else
	AddCSLuaFile("cl_init.lua")
	AddCSLuaFile("shared.lua")

	include('shared.lua')
	include('compiler_asm.lua')
	include('cpu_bitwise.lua')
	include('cpu_vm.lua')
	include('cpu_opcodes.lua')
	include('cpu_bus.lua')
	include('cpu_interrupt.lua')
end
ENT.WireDebugName = "CPU"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "NMI"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" })

	self.Debug = false //!!!GLOBAL DEBUG MODE SWITCH!!!

	//Debug mode is cool. All cool guys use it to debug their programs
	//It spams your console with step-by-step description of what your CPU does

	self.DebugLines = {}
	self.DebugData = {}

	self.Memory = {}
	self.ROMMemory = {}
	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self.SerialNo = math.floor(math.random()*1000000)

	self.UseROM = false

	self.Clk = 0
	self.InputClk = 0
	self.AuxIO = 0

	self:Reset()

	self.DeltaTime = 0
	self.Freq = 2000
	self.PrevThinkTime = CurTime()

	self.PrevTime = CurTime()
	self.SkipIterations = false

	self:SetOverlayText("CPU")
	self:InitializeOpcodeTable()
	self:InitializeLookupTables()
	self:InitializeOpcodeRunlevels()
	self:InitializeOpcodeNames()
	self:InitializeRegisterNames()
	self:InitializeOptimizer()
	self:InitializeCPUVariableSet()
	self:InitializeASMOpcodes()
end

function ENT:CPUID_Version()
	//SVN shit doesnt want to work!!
	local SVNString = "$Revision: 643 $"
	return 900//tonumber(string.sub(SVNString,12,14))
end

function ENT:DebugMessage(msg)
	if (self.CPUName) then
		Msg(self.CPUName.." ")
	end
	Msg("============================================\n")
	Msg(msg.."\n")
end


//CPUID
//Value | EAX
//--------------------------------------------
//0	| CPU Version
//1	| RAM Size
//--------------------------------------------

function ENT:RunExecute(Iterations)
	while (Iterations > 0) && (self.Clk >= 1.0) && (self.Idle == 0) do
		self:Execute()
		if (self.SkipIterations == true) then
			self.SkipIterations = false
			Iterations = Iterations - 30
		else
			Iterations = Iterations - 1
		end
	end

	//Restore current page for external bus reading
	self.CurrentPage = {}
	self.CurrentPage.Read = 1
	self.CurrentPage.Write = 1
	self.CurrentPage.Execute = 1
	self.CurrentPage.RunLevel = self.XTRL //External reads have runlevel 1

	if (self.Idle == 1) then
		self.Idle = 0
	end
end//self.Freq

function ENT:Think()
	local DeltaTime = CurTime() - self.PrevThinkTime
	local Iterations = math.floor(self.Freq*DeltaTime*0.5)
	self:RunExecute(Iterations)

	self.PrevThinkTime = CurTime()

	//Run every tick (or at least attempt to)
	if (self.Clk >= 1.0) then self.Entity:NextThink(CurTime()) end
	return true
end

//FIXME: remove this:
function ENT:SingleThink()
	if (self.Clk >= 1.0) then
		self:Execute()
	end

	//Restore current page for external bus reading
	self.CurrentPage = {}
	self.CurrentPage.Read = 1
	self.CurrentPage.Write = 1
	self.CurrentPage.Execute = 1
	self.CurrentPage.RunLevel = self.XTRL //External reads have runlevel 1

	if (self.Idle == 1) then
		self.Idle = 0
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.UseROM = self.UseROM
	info.SerialNo = self.SerialNo
	if (self.UseROM) then
		info.Memory = {}
		for i=0,65535 do
			if ((self.ROMMemory[i]) && (self.ROMMemory[i] ~= 0)) then
				info.Memory[i] = self.ROMMemory[i]
			end
		end
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.SerialNo = info.SerialNo
	if ((info.UseROM) && (info.UseROM == true)) then
		self.UseROM = info.UseROM
		self.ROMMemory = {}
		for i=0,65535 do
			if (info.Memory[i]) then
				self.ROMMemory[i] = info.Memory[i]
			end
		end


		self:Reset()
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self.InputClk = value
		self.PrevTime = CurTime()
		self.PrevThinkTime = CurTime()
		self.Entity:NextThink(CurTime())
	elseif (iname == "Frequency") then
		if (not SinglePlayer() && (value > 120000)) then
			self.Freq = 120000
			return
		end
		if (value > 0) then
			self.Freq = math.floor(value)
		end
	elseif (iname == "Reset") then
		if (value >= 1.0) then
			self:Reset()
		end
	elseif (iname == "NMI") then
		if (value >= 32) && (value < 256) then
			if (self.Clk >= 1.0) then
				self.AuxIO = 0
				self:NMIInterrupt(math.floor(value))
				self.AuxIO = 1
			end
		end
	end
end
