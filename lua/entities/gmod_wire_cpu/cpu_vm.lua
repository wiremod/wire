function ENT:Reset()
	self.IP = 0	 //Instruction pointer

	self.Page = {}

	self.EAX = 0	 //General purpose registers
	self.EBX = 0
	self.ECX = 0
	self.EDX = 0
	self.ESI = 0
	self.EDI = 0
	self.ESP = 65535
	self.EBP = 0

	self.CS	= 0	 //Segment pointer registers
	self.SS = 0
	self.DS = 0
	self.ES = 0
	self.GS = 0
	self.FS = 0
	self.KS = 0
	self.LS = 0

	self.ESZ = 65535 //Stack size register

	self.IDTR = 0	 //Interrupt descriptor table register
	self.NIDT = 256	 //Size of interrupt descriptor table
	self.EF = 0	 //Enhanced mode flag
	self.PF = 0	 //Protected mode flag
	self.IF = 1	 //Interrupts enabled flag
	self.NextIF = nil

	self.CMPR = 0	 //Compare register
	self.XEIP = 0	 //Current instruction address register
	self.LADD = 0	 //Last interrupt parameter
	self.LINT = 0	 //Last interrupt number
	self.TMR = 0	 //Internal timer
	self.TIMER = 0	 //Internal clock
	self.CPAGE = 0	 //Current page ID

	self.BPREC = 48	 //Binary precision for integer emulation mode
	self.IPREC = 48	 //Integer precision
	self.VMODE = 2	 //Vector mode (2D)

	self.CODEBYTES = 0 //Executed size of code

	self.INTR = 0
	self.BusLock = 0
	self.Idle = 0

	self.BlockStart = 0
	self.BlockSize = 0
	self.XTRL = 1	 //Runlevel for external IO

	self.CurrentPage = nil

	self.Clk = self.InputClk

	if (not self.IsGPU) then
		if (self.UseROM == true) then
			for i = 0, 65535 do
				if (self.ROMMemory[i]) then
					self:WriteCell(i,self.ROMMemory[i])
				end
			end
		end
	end

	self.HaltPort = -1

	if (self.Debug) then self:DebugMessage("CPU RESET") end
	if (not self.IsGPU) then Wire_TriggerOutput(self.Entity, "Error", 0.0) end
end

function ENT:InitializeCPUVariableSet()
	self.CPUVariable = {}
	self.CPUVariableReadonly = {}

	self.CPUVariable[0 ] = "IP"

	self.CPUVariable[1 ] = "EAX"
	self.CPUVariable[2 ] = "EBX"
	self.CPUVariable[3 ] = "ECX"
	self.CPUVariable[4 ] = "EDX"
	self.CPUVariable[5 ] = "ESI"
	self.CPUVariable[6 ] = "EDI"
	self.CPUVariable[7 ] = "ESP"
	self.CPUVariable[8 ] = "EBP"

	self.CPUVariable[9 ] = "ESZ"

	self.CPUVariable[16] = "CS"
	self.CPUVariable[17] = "SS"
	self.CPUVariable[18] = "DS"
	self.CPUVariable[19] = "ES"
	self.CPUVariable[20] = "GS"
	self.CPUVariable[21] = "FS"
	self.CPUVariable[22] = "KS"
	self.CPUVariable[23] = "LS"

	self.CPUVariable[24] = "IDTR"
	self.CPUVariable[25] = "CMPR"
	self.CPUVariable[26] = "XEIP" 		self.CPUVariableReadonly[26] = true
	self.CPUVariable[27] = "LADD"
	self.CPUVariable[28] = "LINT"
	self.CPUVariable[29] = "TMR"
	self.CPUVariable[30] = "TIMER"
	self.CPUVariable[31] = "CPAGE" 		self.CPUVariableReadonly[31] = true

	self.CPUVariable[32] = "IF"
	self.CPUVariable[33] = "PF"
	self.CPUVariable[34] = "EF"

	self.CPUVariable[45] = "BusLock"
	self.CPUVariable[46] = "Idle"
	self.CPUVariable[47] = "INTR"

	self.CPUVariable[48] = "SerialNo"	self.CPUVariableReadonly[48] = true
	self.CPUVariable[49] = "CODEBYTES"	self.CPUVariableReadonly[49] = true
	self.CPUVariable[50] = "BPREC"
	self.CPUVariable[51] = "IPREC"
	self.CPUVariable[52] = "NIDT"
	self.CPUVariable[53] = "BlockStart"
	self.CPUVariable[54] = "BlockSize"
	self.CPUVariable[55] = "VMODE"
	self.CPUVariable[56] = "XTRL"
	self.CPUVariable[57] = "HaltPort"
end

function ENT:InitializeLookupTables()
	self.SegmentType = {}
	self.SegmentType[-2 ] = "CS"
	self.SegmentType[-3 ] = "SS"
	self.SegmentType[-4 ] = "DS"
	self.SegmentType[-5 ] = "ES"
	self.SegmentType[-6 ] = "GS"
	self.SegmentType[-7 ] = "FS"
	self.SegmentType[-8 ] = "KS"
	self.SegmentType[-9 ] = "LS"
	self.SegmentType[-10] = "EAX"
	self.SegmentType[-11] = "EBX"
	self.SegmentType[-12] = "ECX"
	self.SegmentType[-13] = "EDX"
	self.SegmentType[-14] = "ESI"
	self.SegmentType[-15] = "EDI"
	self.SegmentType[-16] = "ESP"
	self.SegmentType[-17] = "EBP"

	self.ParamFunctions_1     = {}
	self.ParamFunctions_1[0]  = function() return self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[1]  = function() return self.EAX end
	self.ParamFunctions_1[2]  = function() return self.EBX end
	self.ParamFunctions_1[3]  = function() return self.ECX end
	self.ParamFunctions_1[4]  = function() return self.EDX end
	self.ParamFunctions_1[5]  = function() return self.ESI end
	self.ParamFunctions_1[6]  = function() return self.EDI end
	self.ParamFunctions_1[7]  = function() return self.ESP end
	self.ParamFunctions_1[8]  = function() return self.EBP end

	self.ParamFunctions_1[9]  = function() return self.CS end
	self.ParamFunctions_1[10] = function() return self.SS end
	self.ParamFunctions_1[11] = function() return self.DS end
	self.ParamFunctions_1[12] = function() return self.ES end
	self.ParamFunctions_1[13] = function() return self.GS end
	self.ParamFunctions_1[14] = function() return self.FS end
	self.ParamFunctions_1[15] = function() return self.KS end
	self.ParamFunctions_1[16] = function() return self.LS end

	self.ParamFunctions_1[17] = function() return self:ReadCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[18] = function() return self:ReadCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[19] = function() return self:ReadCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[20] = function() return self:ReadCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[21] = function() return self:ReadCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[22] = function() return self:ReadCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[23] = function() return self:ReadCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment1]) end
	self.ParamFunctions_1[24] = function() return self:ReadCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment1]) end

	self.ParamFunctions_1[25] = function() return self:ReadCell(self.PrecompileData[self.XEIP].PeekByte1 + self[self.PrecompileData[self.XEIP].Segment1]) end

	self.ParamFunctions_1[26] = function() return self.EAX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[27] = function() return self.EBX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[28] = function() return self.ECX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[29] = function() return self.EDX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[30] = function() return self.ESI + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[31] = function() return self.EDI + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[32] = function() return self.ESP + self[self.PrecompileData[self.XEIP].Segment1] end
	self.ParamFunctions_1[33] = function() return self.EBP + self[self.PrecompileData[self.XEIP].Segment1] end

	self.ParamFunctions_1[34] = function() return self:ReadCell(self.EAX + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[35] = function() return self:ReadCell(self.EBX + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[36] = function() return self:ReadCell(self.ECX + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[37] = function() return self:ReadCell(self.EDX + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[38] = function() return self:ReadCell(self.ESI + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[39] = function() return self:ReadCell(self.EDI + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[40] = function() return self:ReadCell(self.ESP + self.PrecompileData[self.XEIP].PeekByte1) end
	self.ParamFunctions_1[41] = function() return self:ReadCell(self.EBP + self.PrecompileData[self.XEIP].PeekByte1) end

	self.ParamFunctions_1[42] = function() return self.EAX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[43] = function() return self.EBX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[44] = function() return self.ECX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[45] = function() return self.EDX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[46] = function() return self.ESI + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[47] = function() return self.EDI + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[48] = function() return self.ESP + self.PrecompileData[self.XEIP].PeekByte1 end
	self.ParamFunctions_1[49] = function() return self.EBP + self.PrecompileData[self.XEIP].PeekByte1 end
	for i=1000,2024 do
		self.ParamFunctions_1[i] = function() return self:ReadPort(self.PrecompileData[self.XEIP].dRM1-1000) end
	end

	self.NeedPeekByte = {}
	self.NeedPeekByte[0]  = true
	self.NeedPeekByte[25] = true
	self.NeedPeekByte[34] = true
	self.NeedPeekByte[35] = true
	self.NeedPeekByte[36] = true
	self.NeedPeekByte[37] = true
	self.NeedPeekByte[38] = true
	self.NeedPeekByte[39] = true
	self.NeedPeekByte[40] = true
	self.NeedPeekByte[41] = true
	self.NeedPeekByte[42] = true
	self.NeedPeekByte[43] = true
	self.NeedPeekByte[44] = true
	self.NeedPeekByte[45] = true
	self.NeedPeekByte[46] = true
	self.NeedPeekByte[47] = true
	self.NeedPeekByte[48] = true
	self.NeedPeekByte[49] = true

	self.ParamFunctions_2     = {}
	self.ParamFunctions_2[0]  = function() return self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[1]  = function() return self.EAX end
	self.ParamFunctions_2[2]  = function() return self.EBX end
	self.ParamFunctions_2[3]  = function() return self.ECX end
	self.ParamFunctions_2[4]  = function() return self.EDX end
	self.ParamFunctions_2[5]  = function() return self.ESI end
	self.ParamFunctions_2[6]  = function() return self.EDI end
	self.ParamFunctions_2[7]  = function() return self.ESP end
	self.ParamFunctions_2[8]  = function() return self.EBP end
	self.ParamFunctions_2[9]  = function() return self.CS end
	self.ParamFunctions_2[10] = function() return self.SS end
	self.ParamFunctions_2[11] = function() return self.DS end
	self.ParamFunctions_2[12] = function() return self.ES end
	self.ParamFunctions_2[13] = function() return self.GS end
	self.ParamFunctions_2[14] = function() return self.FS end
	self.ParamFunctions_2[15] = function() return self.KS end
	self.ParamFunctions_2[16] = function() return self.LS end

	self.ParamFunctions_2[17] = function() return self:ReadCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[18] = function() return self:ReadCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[19] = function() return self:ReadCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[20] = function() return self:ReadCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[21] = function() return self:ReadCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[22] = function() return self:ReadCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[23] = function() return self:ReadCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment2]) end
	self.ParamFunctions_2[24] = function() return self:ReadCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment2]) end

	self.ParamFunctions_2[25] = function() return self:ReadCell(self.PrecompileData[self.XEIP].PeekByte2 + self[self.PrecompileData[self.XEIP].Segment2]) end

	self.ParamFunctions_2[26] = function() return self.EAX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[27] = function() return self.EBX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[28] = function() return self.ECX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[29] = function() return self.EDX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[30] = function() return self.ESI + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[31] = function() return self.EDI + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[32] = function() return self.ESP + self[self.PrecompileData[self.XEIP].Segment2] end
	self.ParamFunctions_2[33] = function() return self.EBP + self[self.PrecompileData[self.XEIP].Segment2] end

	self.ParamFunctions_2[34] = function() return self:ReadCell(self.EAX + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[35] = function() return self:ReadCell(self.EBX + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[36] = function() return self:ReadCell(self.ECX + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[37] = function() return self:ReadCell(self.EDX + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[38] = function() return self:ReadCell(self.ESI + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[39] = function() return self:ReadCell(self.EDI + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[40] = function() return self:ReadCell(self.ESP + self.PrecompileData[self.XEIP].PeekByte2) end
	self.ParamFunctions_2[41] = function() return self:ReadCell(self.EBP + self.PrecompileData[self.XEIP].PeekByte2) end

	self.ParamFunctions_2[42] = function() return self.EAX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[43] = function() return self.EBX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[44] = function() return self.ECX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[45] = function() return self.EDX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[46] = function() return self.ESI + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[47] = function() return self.EDI + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[48] = function() return self.ESP + self.PrecompileData[self.XEIP].PeekByte2 end
	self.ParamFunctions_2[49] = function() return self.EBP + self.PrecompileData[self.XEIP].PeekByte2 end

	for i=1000,2024 do
		self.ParamFunctions_2[i] = function() return self:ReadPort(self.PrecompileData[self.XEIP].dRM2-1000) end
	end

	self.WriteBackFunctions = {}
	self.WriteBackFunctions[0]  = function(Result) end
	self.WriteBackFunctions[1]  = function(Result) self.EAX = Result end
	self.WriteBackFunctions[2]  = function(Result) self.EBX = Result end
	self.WriteBackFunctions[3]  = function(Result) self.ECX = Result end
	self.WriteBackFunctions[4]  = function(Result) self.EDX = Result end
	self.WriteBackFunctions[5]  = function(Result) self.ESI = Result end
	self.WriteBackFunctions[6]  = function(Result) self.EDI = Result end
	self.WriteBackFunctions[7]  = function(Result) self.ESP = Result end
	self.WriteBackFunctions[8]  = function(Result) self.EBP = Result end
	self.WriteBackFunctions[9]  = function(Result) self:Interrupt(13,1) end
	self.WriteBackFunctions[10] = function(Result) self.SS = Result end
	self.WriteBackFunctions[11] = function(Result) self.DS = Result end
	self.WriteBackFunctions[12] = function(Result) self.ES = Result end
	self.WriteBackFunctions[13] = function(Result) self.GS = Result end
	self.WriteBackFunctions[14] = function(Result) self.FS = Result end
	self.WriteBackFunctions[15] = function(Result) self.KS = Result end
	self.WriteBackFunctions[16] = function(Result) self.LS = Result end
	self.WriteBackFunctions[17] = function(Result) self:WriteCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[18] = function(Result) self:WriteCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[19] = function(Result) self:WriteCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[20] = function(Result) self:WriteCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[21] = function(Result) self:WriteCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[22] = function(Result) self:WriteCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[23] = function(Result) self:WriteCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[24] = function(Result) self:WriteCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment1],Result) end
	self.WriteBackFunctions[25] = function(Result) self:WriteCell(self.PrecompileData[self.XEIP].PeekByte1 + self[self.PrecompileData[self.XEIP].Segment1],Result) end

	for i=1000,2024 do
		self.WriteBackFunctions[i] = function(Result) self:WritePort(self.PrecompileData[self.XEIP].dRM1-1000,Result) end
	end

	self.WriteBackFunctions2 = {}
	self.WriteBackFunctions2[0]  = function(Result) end
	self.WriteBackFunctions2[1]  = function(Result) self.EAX = Result end
	self.WriteBackFunctions2[2]  = function(Result) self.EBX = Result end
	self.WriteBackFunctions2[3]  = function(Result) self.ECX = Result end
	self.WriteBackFunctions2[4]  = function(Result) self.EDX = Result end
	self.WriteBackFunctions2[5]  = function(Result) self.ESI = Result end
	self.WriteBackFunctions2[6]  = function(Result) self.EDI = Result end
	self.WriteBackFunctions2[7]  = function(Result) self.ESP = Result end
	self.WriteBackFunctions2[8]  = function(Result) self.EBP = Result end
	self.WriteBackFunctions2[9]  = function(Result) self:Interrupt(13,1) end
	self.WriteBackFunctions2[10] = function(Result) self.SS = Result end
	self.WriteBackFunctions2[11] = function(Result) self.DS = Result end
	self.WriteBackFunctions2[12] = function(Result) self.ES = Result end
	self.WriteBackFunctions2[13] = function(Result) self.GS = Result end
	self.WriteBackFunctions2[14] = function(Result) self.FS = Result end
	self.WriteBackFunctions2[15] = function(Result) self.KS = Result end
	self.WriteBackFunctions2[16] = function(Result) self.LS = Result end
	self.WriteBackFunctions2[17] = function(Result) self:WriteCell(self.EAX + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[18] = function(Result) self:WriteCell(self.EBX + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[19] = function(Result) self:WriteCell(self.ECX + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[20] = function(Result) self:WriteCell(self.EDX + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[21] = function(Result) self:WriteCell(self.ESI + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[22] = function(Result) self:WriteCell(self.EDI + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[23] = function(Result) self:WriteCell(self.ESP + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[24] = function(Result) self:WriteCell(self.EBP + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	self.WriteBackFunctions2[25] = function(Result) self:WriteCell(self.PrecompileData[self.XEIP].PeekByte2 + self[self.PrecompileData[self.XEIP].Segment2],Result) end
	for i=1000,2024 do
		self.WriteBackFunctions2[i] = function(Result) self:WritePort(self.PrecompileData[self.XEIP].dRM2-1000,Result) end
	end

	self.EffectiveAddress1 = {}
	self.EffectiveAddress1[17] = function() return self.EAX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[18] = function() return self.EBX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[19] = function() return self.ECX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[20] = function() return self.EDX + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[21] = function() return self.ESI + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[22] = function() return self.EDI + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[23] = function() return self.ESP + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[24] = function() return self.EBP + self[self.PrecompileData[self.XEIP].Segment1] end
	self.EffectiveAddress1[24] = function() return self.EBP + self[self.PrecompileData[self.XEIP].Segment1] end

	self.EffectiveAddress1[25] = function() return self.PrecompileData[self.XEIP].PeekByte1 + self[self.PrecompileData[self.XEIP].Segment1] end

	self.EffectiveAddress1[34] = function() return self.EAX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[35] = function() return self.EBX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[36] = function() return self.ECX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[37] = function() return self.EDX + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[38] = function() return self.ESI + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[39] = function() return self.EDI + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[40] = function() return self.ESP + self.PrecompileData[self.XEIP].PeekByte1 end
	self.EffectiveAddress1[41] = function() return self.EBP + self.PrecompileData[self.XEIP].PeekByte1 end

	for i=1000,2024 do
		self.EffectiveAddress1[i] = function(Result) return -(self.PrecompileData[self.XEIP].dRM2-1000)-1 end
	end


	self.EffectiveAddress2 = {}
	self.EffectiveAddress2[17] = function() return self.EAX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[18] = function() return self.EBX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[19] = function() return self.ECX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[20] = function() return self.EDX + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[21] = function() return self.ESI + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[22] = function() return self.EDI + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[23] = function() return self.ESP + self[self.PrecompileData[self.XEIP].Segment2] end
	self.EffectiveAddress2[24] = function() return self.EBP + self[self.PrecompileData[self.XEIP].Segment2] end

	self.EffectiveAddress2[25] = function() return self.PrecompileData[self.XEIP].PeekByte2 + self[self.PrecompileData[self.XEIP].Segment2] end

	self.EffectiveAddress2[34] = function() return self.EAX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[35] = function() return self.EBX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[36] = function() return self.ECX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[37] = function() return self.EDX + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[38] = function() return self.ESI + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[39] = function() return self.EDI + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[40] = function() return self.ESP + self.PrecompileData[self.XEIP].PeekByte2 end
	self.EffectiveAddress2[41] = function() return self.EBP + self.PrecompileData[self.XEIP].PeekByte2 end

	for i=1000,2024 do
		self.EffectiveAddress2[i] = function(Result) return -(self.PrecompileData[self.XEIP].dRM2-1000)-1 end
	end
end

function ENT:PRead(IP)
	self.PrecompileMemory[self.TempIP] = IP
	self.TempIP = self.TempIP + 1
	return self:ReadCell(self.TempIP-1)
end

function ENT:Precompile(IP)
	self.SkipIterations = true

	self.TempIP = IP
	if (self.Debug) then self:DebugMessage("Precompiling instruction at address "..IP) end

	self.PrecompileData[IP] = {}
	self.PrecompileData[IP].Size = 0

	local Opcode = self:PRead(IP)
	local RM = self:PRead(IP)
	self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 2

	local Disp1 = 0
	local Disp2 = 0

	self.PrecompileData[IP].Valid = true
	self.PrecompileData[IP].UnknownOpcode = false
	self.PrecompileData[IP].ErrorCode = 0

	if (Opcode == nil) || (RM == nil) then
		if (self.Debug) then Msg("Precompile failed (invalid opcode/RM)\n") end
		self.PrecompileData[IP].Valid = false
		self.PrecompileData[IP].ErrorCode = 1
		return
	end

	Opcode = tonumber(Opcode)

	local dRM2 = math.floor(RM / 10000)
	local dRM1 = RM - dRM2*10000

	local Segment1 = -4
	local Segment2 = -4

	if (Opcode > 1000) then
		if (Opcode > 10000) then
			Segment2 = self:PRead(IP)
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			Opcode = Opcode-10000
			if (Opcode > 1000) then
				Segment1 = self:PRead(IP)
				self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

				Opcode = Opcode-1000

				local Temp = Segment2
				Segment2 = Segment1
				Segment1 = Temp
			end
		else
			Segment1 = self:PRead(IP)
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			Opcode = Opcode-1000
		end
	end

	self.PrecompileData[IP].Opcode = Opcode

	Segment1 = self.SegmentType[Segment1]
	Segment2 = self.SegmentType[Segment2]

	self.PrecompileData[IP].Segment1 = Segment1
	self.PrecompileData[IP].Segment2 = Segment2

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		if self.NeedPeekByte[dRM1] then
			self.PrecompileData[IP].PeekByte1 = self:PRead(IP)
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			if (self.PrecompileData[IP].PeekByte1 == nil) then
				if (self.Debug) then Msg("Precompile failed (could not peek next byte)\n") end
				self.PrecompileData[IP].Valid = false
				self.PrecompileData[IP].ErrorCode = 2
				return
			end
		end
	end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
		if self.NeedPeekByte[dRM2] then
			self.PrecompileData[IP].PeekByte2 = self:PRead(IP)
			self.PrecompileData[IP].Size = self.PrecompileData[IP].Size + 1

			if (self.PrecompileData[IP].PeekByte2 == nil) then
				if (self.Debug) then Msg("Precompile failed (could not peek next byte)\n") end
				self.PrecompileData[IP].Valid = false
				self.PrecompileData[IP].ErrorCode = 3
				return
			end
		end
	end

	local Param1 = nil
	local Param2 = nil

	self.PrecompileData[IP].dRM1 = dRM1
	self.PrecompileData[IP].dRM2 = dRM2

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		Param1 = self.ParamFunctions_1[dRM1]
		self.PrecompileData[IP].Param1 = Param1
		self.PrecompileData[IP].EffectiveAddress1 = self.EffectiveAddress1[dRM1]

		if (not Param1) then
			if (self.Debug) then Msg("Precompile failed (Parameter 1 calling function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			self.PrecompileData[IP].ErrorCode = 4
			return
		end
	end

	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
		Param2 = self.ParamFunctions_2[dRM2]
		self.PrecompileData[IP].Param2 = Param2
		self.PrecompileData[IP].EffectiveAddress2 = self.EffectiveAddress2[dRM2]

		if (not Param2) then
			if (self.Debug) then Msg("Precompile failed (Parameter 2 calling function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			self.PrecompileData[IP].ErrorCode = 5
			return
		end
	end


	if (self.OpcodeTable[Opcode]) then
		self.PrecompileData[IP].Execute = function() //Most of magic is done here
			if (self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode]) then
				if (self.PrecompileData[self.XEIP].Param1) then
					if (self.PrecompileData[self.XEIP].Param2) then
						local param1 = tonumber(self.PrecompileData[self.XEIP].Param1())
						local param2 = tonumber(self.PrecompileData[self.XEIP].Param2())
						if (param1 and param2) then
							return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](param1,param2)
						else
							return "Read error"
						end
					else
						local param1 = tonumber(self.PrecompileData[self.XEIP].Param1())
						if (param1) then
							return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](param1,0)
						else
							return "Read error"
						end
					end
				else
					return self.OpcodeTable[self.PrecompileData[self.XEIP].Opcode](0,0)
				end
			else
				if (self.Debug) then Msg("Error: something gone terribly wrong, trying to call non-existing opcode ("..self.PrecompileData[self.XEIP].Opcode..") function without interrupt 4 triggered\n") end
				self.PrecompileData[IP].Valid = false
				self.PrecompileData[IP].ErrorCode = 8
				return
			end
		end
	else
		if (self.Debug) then Msg("Precompile almost failed (Unknown opcode "..Opcode..")\n") end
		self.PrecompileData[IP].UnknownOpcode = true
		self.PrecompileData[IP].Valid = false
		return
	end

	//First destanation
	if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 0)) then
		self.PrecompileData[IP].WriteBack = self.WriteBackFunctions[dRM1]

		if (self.PrecompileData[IP].WriteBack == nil) then
			if (self.Debug) then Msg("Precompile failed (Writeback function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			self.PrecompileData[IP].ErrorCode = 6
			return
		end
	end

	//Second destanation (for XCHG)
	//if (self.OpcodeCount[Opcode] && (self.OpcodeCount[Opcode] > 1)) then
	if (Opcode == 81) then //Special case for XCHG - double writeback
		self.PrecompileData[IP].WriteBack2 = self.WriteBackFunctions2[dRM2]

		if (self.PrecompileData[IP].WriteBack2 == nil) then
			if (self.Debug) then Msg("Precompile failed (Writeback2 function invalid)\n") end
			self.PrecompileData[IP].Valid = false
			self.PrecompileData[IP].ErrorCode = 7
			return
		end
	end

	if (self.Debug) then Msg("Precompile successful\n") end
end

function ENT:PrintState()
	Msg("TMR="..self.TMR.."  TIMER="..self.TIMER.."  XEIP="..self.XEIP.."  CMPR="..self.CMPR.."\n")
	Msg("EAX="..self.EAX.."  EBX="..self.EBX.."  ECX="..self.ECX.."  EDX="..self.EDX.."\n")
	Msg("ESI="..self.ESI.."  EDI="..self.EDI.."  ESP="..self.ESP.."  EBP="..self.EBP.."  ESZ="..self.ESZ.."\n")

	 Msg("CS="..self.CS)
	Msg(" SS="..self.SS)
	Msg(" DS="..self.DS)
	Msg(" FS="..self.FS)
	Msg(" GS="..self.GS)
	Msg(" ES="..self.ES)
	Msg(" KS="..self.KS)
	Msg(" LS="..self.LS.."\n")
end

function ENT:SetCurrentPage(address)
	self.CPAGE = math.floor(address / 128)

	if (not self.Page[self.CPAGE]) then
		self.Page[self.CPAGE] = {}
		self.Page[self.CPAGE].Read = 1
		self.Page[self.CPAGE].Write = 1
		self.Page[self.CPAGE].Execute = 1
		self.Page[self.CPAGE].RunLevel = 0
		self.Page[self.CPAGE].MappedTo = self.CPAGE
	end
	self.CurrentPage = self.Page[self.CPAGE]
end

function ENT:Execute()
	self.AuxIO = 0
	self.DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+self.DeltaTime

	self.TIMER = self.TIMER + self.DeltaTime
	self.TMR = self.TMR + 1

	if (self.BusLock == 1) then
		if (self.Debug) then
			print("Warning: execution while bus is locked")
		end
	end

	if (not self.IP) then
		self:Reset()
		Wire_TriggerOutput(self.Entity, "Error", 5.0)
		return
	end

	self.XEIP = self.IP+self.CS
	self:SetCurrentPage(self.XEIP)

	if (self.CurrentPage.Execute == 0) then
		self:Interrupt(14,self.CPAGE)
		return
	end

	if (self.NextIF) then
		self.IF = self.NextIF
		self.NextIF = nil
	end

	if (self.Debug) then
		self:DebugMessage("CPU EXECUTION STEP")
	end

	//Dynamic precompiler: check if opcode was precompiled
	if (self.PrecompileData[self.XEIP]) then
		//Simulate read
		self.IP = self.IP + self.PrecompileData[self.XEIP].Size
		self.CODEBYTES = self.CODEBYTES + self.PrecompileData[self.XEIP].Size

		//Verify opcode
		if (self.PrecompileData[self.XEIP].Valid) then
			if (self.OpcodeRunLevel[self.PrecompileData[self.XEIP].Opcode]) then
				if (self.OpcodeRunLevel[self.PrecompileData[self.XEIP].Opcode] == 0) then
					if (self.Page[self.CPAGE].RunLevel ~= 0) then
						self:Interrupt(13,self.PrecompileData[self.XEIP].Opcode)
					end
				end
			end

			//Execute
			local Result = self.PrecompileData[self.XEIP].Execute()
			if (Result) then
				if (Result == "Read error") then
					self:Interrupt(5,1) //Read error during execute
				else
					self.PrecompileData[self.XEIP].WriteBack(Result)
				end
			end
		else
			if (self.PrecompileData[self.XEIP].UnknownOpcode) then
				self:Interrupt(4,self.PrecompileData[self.XEIP].Opcode) //Unknown Opcode
			else
				self:Interrupt(5,2+(self.PrecompileData[self.XEIP].ErrorCode or 0)*10) //Internal/opcode read error
			end
		end
	else
		self:Precompile(self.XEIP)
		self.TMR = self.TMR + 29
	end

	if (self.Debug) then
		if (self.INTR == 0) then
			self:DebugMessage("")
		end
		self:PrintState()

		Msg("Memory at XEIP: ")
		for i=self.XEIP,self.XEIP+6 do
			local oldlock = self.BusLock
			self.BusLock = 0
			local val = self:ReadCell(i)
			self.BusLock = oldlock
			if (val) then
				Msg("["..val.."] ")
			end
		end
		Msg("\n")

		if (self.DebugData[self.XEIP]) then
			print("")
			if (self.DebugLines[self.DebugData[self.XEIP]-2]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]-2].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]-1]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]-1].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]]) then
				print(self.DebugLines[self.DebugData[self.XEIP]])
			end
			if (self.DebugLines[self.DebugData[self.XEIP]+1]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]+1].."\n")
			end
			if (self.DebugLines[self.DebugData[self.XEIP]+2]) then
				Msg(self.DebugLines[self.DebugData[self.XEIP]+2].."\n")
			end
			print("")
		end
	end

	self.INTR = 0
	self.AuxIO = 1
end
