--------------------------------------------------------------------------------
-- Zyelios VM (Zyelios CPU/GPU virtual machine)
--
-- Virtual machine lookup tables
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Internal registers mapped to names
ZVM.InternalRegister = {}
ZVM.InternalLimits = {IPREC = {1, 128}}
ZVM.ReadOnlyRegister = {}

ZVM.InternalRegister[00] = "IP"
ZVM.InternalRegister[01] = "EAX"
ZVM.InternalRegister[02] = "EBX"
ZVM.InternalRegister[03] = "ECX"
ZVM.InternalRegister[04] = "EDX"
ZVM.InternalRegister[05] = "ESI"
ZVM.InternalRegister[06] = "EDI"
ZVM.InternalRegister[07] = "ESP"
ZVM.InternalRegister[08] = "EBP"
ZVM.InternalRegister[09] = "ESZ"
----------------------------------
ZVM.InternalRegister[16] = "CS"
ZVM.InternalRegister[17] = "SS"
ZVM.InternalRegister[18] = "DS"
ZVM.InternalRegister[19] = "ES"
ZVM.InternalRegister[20] = "GS"
ZVM.InternalRegister[21] = "FS"
ZVM.InternalRegister[22] = "KS"
ZVM.InternalRegister[23] = "LS"
----------------------------------
ZVM.InternalRegister[24] = "IDTR"
ZVM.InternalRegister[25] = "CMPR"
ZVM.InternalRegister[26] = "XEIP"                ZVM.ReadOnlyRegister[26] = true
ZVM.InternalRegister[27] = "LADD"
ZVM.InternalRegister[28] = "LINT"
ZVM.InternalRegister[29] = "TMR"
ZVM.InternalRegister[30] = "TIMER"
ZVM.InternalRegister[31] = "CPAGE"               ZVM.ReadOnlyRegister[31] = true
ZVM.InternalRegister[32] = "IF"
ZVM.InternalRegister[33] = "PF"
ZVM.InternalRegister[34] = "EF"
ZVM.InternalRegister[35] = "NIF"
ZVM.InternalRegister[36] = "MF"
ZVM.InternalRegister[37] = "PTBL"
ZVM.InternalRegister[38] = "PTBE"
ZVM.InternalRegister[39] = "PCAP"
ZVM.InternalRegister[40] = "RQCAP"
----------------------------------
ZVM.InternalRegister[41] = "PPAGE"               ZVM.ReadOnlyRegister[41] = true
ZVM.InternalRegister[42] = "MEMRQ"
----------------------------------
ZVM.InternalRegister[43] = "RAMSize"             ZVM.ReadOnlyRegister[43] = true
ZVM.InternalRegister[44] = "External"
ZVM.InternalRegister[45] = "BusLock"
ZVM.InternalRegister[46] = "Idle"
ZVM.InternalRegister[47] = "INTR"
----------------------------------
ZVM.InternalRegister[48] = "SerialNo"            ZVM.ReadOnlyRegister[48] = true
ZVM.InternalRegister[49] = "CODEBYTES"           ZVM.ReadOnlyRegister[49] = true
ZVM.InternalRegister[50] = "BPREC"
ZVM.InternalRegister[51] = "IPREC"
ZVM.InternalRegister[52] = "NIDT"
ZVM.InternalRegister[53] = "BlockStart"
ZVM.InternalRegister[54] = "BlockSize"
ZVM.InternalRegister[55] = "VMODE"
ZVM.InternalRegister[56] = "XTRL"
ZVM.InternalRegister[57] = "HaltPort"
ZVM.InternalRegister[58] = "HWDEBUG"
ZVM.InternalRegister[59] = "DBGSTATE"
ZVM.InternalRegister[60] = "DBGADDR"
ZVM.InternalRegister[61] = "CRL"
ZVM.InternalRegister[62] = "TimerDT"             ZVM.ReadOnlyRegister[62] = true
ZVM.InternalRegister[63] = "MEMADDR"
----------------------------------
ZVM.InternalRegister[64] = "TimerMode"
ZVM.InternalRegister[65] = "TimerRate"
ZVM.InternalRegister[66] = "TimerPrevTime"
ZVM.InternalRegister[67] = "TimerAddress"
ZVM.InternalRegister[68] = "TimerPrevMode"
----------------------------------
for reg=0,31 do ZVM.InternalRegister[96+reg] = "R"..reg end




--------------------------------------------------------------------------------
-- Segment register index mapped to segment register
ZVM.SegmentLookup = {}

-- Old ZCPU format
ZVM.SegmentLookup[-02] = "CS"
ZVM.SegmentLookup[-03] = "SS"
ZVM.SegmentLookup[-04] = "DS"
ZVM.SegmentLookup[-05] = "ES"
ZVM.SegmentLookup[-06] = "GS"
ZVM.SegmentLookup[-07] = "FS"
ZVM.SegmentLookup[-08] = "KS"
ZVM.SegmentLookup[-09] = "LS"
ZVM.SegmentLookup[-10] = "EAX"
ZVM.SegmentLookup[-11] = "EBX"
ZVM.SegmentLookup[-12] = "ECX"
ZVM.SegmentLookup[-13] = "EDX"
ZVM.SegmentLookup[-14] = "ESI"
ZVM.SegmentLookup[-15] = "EDI"
ZVM.SegmentLookup[-16] = "ESP"
ZVM.SegmentLookup[-17] = "EBP"

-- New ZCPU format
ZVM.SegmentLookup[01] = "CS"
ZVM.SegmentLookup[02] = "SS"
ZVM.SegmentLookup[03] = "DS"
ZVM.SegmentLookup[04] = "ES"
ZVM.SegmentLookup[05] = "GS"
ZVM.SegmentLookup[06] = "FS"
ZVM.SegmentLookup[07] = "KS"
ZVM.SegmentLookup[08] = "LS"
ZVM.SegmentLookup[09] = "EAX"
ZVM.SegmentLookup[10] = "EBX"
ZVM.SegmentLookup[11] = "ECX"
ZVM.SegmentLookup[12] = "EDX"
ZVM.SegmentLookup[13] = "ESI"
ZVM.SegmentLookup[14] = "EDI"
ZVM.SegmentLookup[15] = "ESP"
ZVM.SegmentLookup[16] = "EBP"
for reg=0,31 do ZVM.SegmentLookup[17+reg] = "R"..reg end





--------------------------------------------------------------------------------
-- Functions to decode RM bytes (READ)
ZVM.OperandReadFunctions = {}

ZVM.OperandReadFunctions[00] = "$BYTE"
-- GP registers
ZVM.OperandReadFunctions[01] = "VM.EAX"
ZVM.OperandReadFunctions[02] = "VM.EBX"
ZVM.OperandReadFunctions[03] = "VM.ECX"
ZVM.OperandReadFunctions[04] = "VM.EDX"
ZVM.OperandReadFunctions[05] = "VM.ESI"
ZVM.OperandReadFunctions[06] = "VM.EDI"
ZVM.OperandReadFunctions[07] = "VM.ESP"
ZVM.OperandReadFunctions[08] = "VM.EBP"
-- Segment registers
ZVM.OperandReadFunctions[09] = "VM.CS"
ZVM.OperandReadFunctions[10] = "VM.SS"
ZVM.OperandReadFunctions[11] = "VM.DS"
ZVM.OperandReadFunctions[12] = "VM.ES"
ZVM.OperandReadFunctions[13] = "VM.GS"
ZVM.OperandReadFunctions[14] = "VM.FS"
ZVM.OperandReadFunctions[15] = "VM.KS"
ZVM.OperandReadFunctions[16] = "VM.LS"
-- Read from memory by GP
ZVM.OperandReadFunctions[17] = "(VM:ReadCell(VM.EAX+$SEG) or 0)"
ZVM.OperandReadFunctions[18] = "(VM:ReadCell(VM.EBX+$SEG) or 0)"
ZVM.OperandReadFunctions[19] = "(VM:ReadCell(VM.ECX+$SEG) or 0)"
ZVM.OperandReadFunctions[20] = "(VM:ReadCell(VM.EDX+$SEG) or 0)"
ZVM.OperandReadFunctions[21] = "(VM:ReadCell(VM.ESI+$SEG) or 0)"
ZVM.OperandReadFunctions[22] = "(VM:ReadCell(VM.EDI+$SEG) or 0)"
ZVM.OperandReadFunctions[23] = "(VM:ReadCell(VM.ESP+$SEG) or 0)"
ZVM.OperandReadFunctions[24] = "(VM:ReadCell(VM.EBP+$SEG) or 0)"
-- Read from memory by displacement
ZVM.OperandReadFunctions[25] = "(VM:ReadCell($BYTE+$SEG) or 0)"
-- Register plus segment
ZVM.OperandReadFunctions[26] = "(VM.EAX+$SEG)"
ZVM.OperandReadFunctions[27] = "(VM.EBX+$SEG)"
ZVM.OperandReadFunctions[28] = "(VM.ECX+$SEG)"
ZVM.OperandReadFunctions[29] = "(VM.EDX+$SEG)"
ZVM.OperandReadFunctions[30] = "(VM.ESI+$SEG)"
ZVM.OperandReadFunctions[31] = "(VM.EDI+$SEG)"
ZVM.OperandReadFunctions[32] = "(VM.ESP+$SEG)"
ZVM.OperandReadFunctions[33] = "(VM.EBP+$SEG)"
-- Read by register plus immediate
ZVM.OperandReadFunctions[34] = "(VM:ReadCell(VM.EAX+$BYTE) or 0)"
ZVM.OperandReadFunctions[35] = "(VM:ReadCell(VM.EBX+$BYTE) or 0)"
ZVM.OperandReadFunctions[36] = "(VM:ReadCell(VM.ECX+$BYTE) or 0)"
ZVM.OperandReadFunctions[37] = "(VM:ReadCell(VM.EDX+$BYTE) or 0)"
ZVM.OperandReadFunctions[38] = "(VM:ReadCell(VM.ESI+$BYTE) or 0)"
ZVM.OperandReadFunctions[39] = "(VM:ReadCell(VM.EDI+$BYTE) or 0)"
ZVM.OperandReadFunctions[40] = "(VM:ReadCell(VM.ESP+$BYTE) or 0)"
ZVM.OperandReadFunctions[41] = "(VM:ReadCell(VM.EBP+$BYTE) or 0)"
-- Register plus immediate
ZVM.OperandReadFunctions[42] = "(VM.EAX+$BYTE)"
ZVM.OperandReadFunctions[43] = "(VM.EBX+$BYTE)"
ZVM.OperandReadFunctions[44] = "(VM.ECX+$BYTE)"
ZVM.OperandReadFunctions[45] = "(VM.EDX+$BYTE)"
ZVM.OperandReadFunctions[46] = "(VM.ESI+$BYTE)"
ZVM.OperandReadFunctions[47] = "(VM.EDI+$BYTE)"
ZVM.OperandReadFunctions[48] = "(VM.ESP+$BYTE)"
ZVM.OperandReadFunctions[49] = "(VM.EBP+$BYTE)"
-- Constant plus segment
ZVM.OperandReadFunctions[50] = "($BYTE+$SEG)"
-- Ports
for i=1000,2023 do ZVM.OperandReadFunctions[i] = "(VM:ReadPort("..(i-1000)..") or 0)" end
-- Extended registers
for reg=0,31 do ZVM.OperandReadFunctions[2048+reg] = "VM.R"..reg end
for reg=0,31 do ZVM.OperandReadFunctions[2080+reg] = "(VM:ReadCell(VM.R"..reg.."+$SEG) or 0)" end
for reg=0,31 do ZVM.OperandReadFunctions[2112+reg] = "(VM.R"..reg.."+$SEG)" end
for reg=0,31 do ZVM.OperandReadFunctions[2144+reg] = "(VM:ReadCell(VM.R"..reg.."+$BYTE) or 0)" end
for reg=0,31 do ZVM.OperandReadFunctions[2176+reg] = "(VM.R"..reg.."+$BYTE)" end




--------------------------------------------------------------------------------
-- Registers required by read operation
ZVM.ReadInvolvedRegisterLookup = {}
for i= 1, 8 do ZVM.ReadInvolvedRegisterLookup[i] = i- 1+ 1 end
--for i= 9,16 do ZVM.ReadInvolvedRegisterLookup[i] = i- 9+16 end
for i=17,24 do ZVM.ReadInvolvedRegisterLookup[i] = i-17+ 1 end
for i=26,33 do ZVM.ReadInvolvedRegisterLookup[i] = i-26+ 1 end
for i=34,41 do ZVM.ReadInvolvedRegisterLookup[i] = i-34+ 1 end
for i=42,49 do ZVM.ReadInvolvedRegisterLookup[i] = i-42+ 1 end
for i=2048,2079 do ZVM.ReadInvolvedRegisterLookup[i] = i-2048+96 end
for i=2080,2111 do ZVM.ReadInvolvedRegisterLookup[i] = i-2080+96 end
for i=2112,2143 do ZVM.ReadInvolvedRegisterLookup[i] = i-2112+96 end
for i=2144,2175 do ZVM.ReadInvolvedRegisterLookup[i] = i-2144+96 end
for i=2176,2207 do ZVM.ReadInvolvedRegisterLookup[i] = i-2176+96 end





--------------------------------------------------------------------------------
-- Functions to decode RM bytes (WRITE)
ZVM.OperandWriteFunctions = {}
ZVM.OperandWriteFunctions[00] = ""
-- GP registers
ZVM.OperandWriteFunctions[01] = "VM.EAX = $EXPR"
ZVM.OperandWriteFunctions[02] = "VM.EBX = $EXPR"
ZVM.OperandWriteFunctions[03] = "VM.ECX = $EXPR"
ZVM.OperandWriteFunctions[04] = "VM.EDX = $EXPR"
ZVM.OperandWriteFunctions[05] = "VM.ESI = $EXPR"
ZVM.OperandWriteFunctions[06] = "VM.EDI = $EXPR"
ZVM.OperandWriteFunctions[07] = "VM.ESP = $EXPR"
ZVM.OperandWriteFunctions[08] = "VM.EBP = $EXPR"
-- Segment registers
ZVM.OperandWriteFunctions[10] = "VM.SS = $EXPR"
ZVM.OperandWriteFunctions[11] = "VM.DS = $EXPR"
ZVM.OperandWriteFunctions[12] = "VM.ES = $EXPR"
ZVM.OperandWriteFunctions[13] = "VM.GS = $EXPR"
ZVM.OperandWriteFunctions[14] = "VM.FS = $EXPR"
ZVM.OperandWriteFunctions[15] = "VM.KS = $EXPR"
ZVM.OperandWriteFunctions[16] = "VM.LS = $EXPR"
-- Write from memory by GP
ZVM.OperandWriteFunctions[17] = "VM:WriteCell(VM.EAX+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[18] = "VM:WriteCell(VM.EBX+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[19] = "VM:WriteCell(VM.ECX+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[20] = "VM:WriteCell(VM.EDX+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[21] = "VM:WriteCell(VM.ESI+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[22] = "VM:WriteCell(VM.EDI+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[23] = "VM:WriteCell(VM.ESP+$SEG,$EXPR)"
ZVM.OperandWriteFunctions[24] = "VM:WriteCell(VM.EBP+$SEG,$EXPR)"
-- Write from memory by displacement
ZVM.OperandWriteFunctions[25] = "VM:WriteCell($BYTE+$SEG,$EXPR)"
-- Write by register plus immediate
ZVM.OperandWriteFunctions[34] = "VM:WriteCell(VM.EAX+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[35] = "VM:WriteCell(VM.EBX+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[36] = "VM:WriteCell(VM.ECX+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[37] = "VM:WriteCell(VM.EDX+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[38] = "VM:WriteCell(VM.ESI+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[39] = "VM:WriteCell(VM.EDI+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[40] = "VM:WriteCell(VM.ESP+$BYTE,$EXPR)"
ZVM.OperandWriteFunctions[41] = "VM:WriteCell(VM.EBP+$BYTE,$EXPR)"
-- Ports
for i=1000,2023 do ZVM.OperandWriteFunctions[i] = "VM:WritePort("..(i-1000)..",$EXPR)" end
-- Extended registers
for reg=0,31 do ZVM.OperandWriteFunctions[2048+reg] = "VM.R"..reg.." = $EXPR" end
for reg=0,31 do ZVM.OperandWriteFunctions[2080+reg] = "VM:WriteCell(VM.R"..reg.."+$SEG,$EXPR)" end
for reg=0,31 do ZVM.OperandWriteFunctions[2144+reg] = "VM:WriteCell(VM.R"..reg.."+$BYTE,$EXPR)" end





--------------------------------------------------------------------------------
-- Registers changed by writeback
ZVM.WriteInvolvedRegisterLookup = {}
for i= 1, 8 do ZVM.WriteInvolvedRegisterLookup[i] = i end
for i=2048,2079 do ZVM.WriteInvolvedRegisterLookup[i] = i-2048+96 end




--------------------------------------------------------------------------------
-- Registers required by write operation
ZVM.WriteRequiredRegisterLookup = {}
for i=17,24 do ZVM.WriteRequiredRegisterLookup[i] = i-17+ 1 end
for i=34,41 do ZVM.WriteRequiredRegisterLookup[i] = i-34+ 1 end
for i=2080,2111 do ZVM.WriteRequiredRegisterLookup[i] = i-2080+96 end
for i=2144,2175 do ZVM.WriteRequiredRegisterLookup[i] = i-2144+96 end




--------------------------------------------------------------------------------
-- Functions to decode RM bytes (psuedo-WRITE)
ZVM.OperandFastWriteFunctions = {}
-- GP registers
ZVM.OperandFastWriteFunctions[01] = "EAX = $EXPR"
ZVM.OperandFastWriteFunctions[02] = "EBX = $EXPR"
ZVM.OperandFastWriteFunctions[03] = "ECX = $EXPR"
ZVM.OperandFastWriteFunctions[04] = "EDX = $EXPR"
ZVM.OperandFastWriteFunctions[05] = "ESI = $EXPR"
ZVM.OperandFastWriteFunctions[06] = "EDI = $EXPR"
ZVM.OperandFastWriteFunctions[07] = "ESP = $EXPR"
ZVM.OperandFastWriteFunctions[08] = "EBP = $EXPR"
-- Write from memory by GP
ZVM.OperandFastWriteFunctions[17] = "VM:WriteCell(EAX+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[18] = "VM:WriteCell(EBX+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[19] = "VM:WriteCell(ECX+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[20] = "VM:WriteCell(EDX+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[21] = "VM:WriteCell(ESI+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[22] = "VM:WriteCell(EDI+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[23] = "VM:WriteCell(ESP+$SEG,$EXPR)"
ZVM.OperandFastWriteFunctions[24] = "VM:WriteCell(EBP+$SEG,$EXPR)"
-- Write from memory by displacement
ZVM.OperandFastWriteFunctions[25] = "VM:WriteCell($BYTE+$SEG,$EXPR)"
-- Write by register plus immediate
ZVM.OperandFastWriteFunctions[34] = "VM:WriteCell(EAX+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[35] = "VM:WriteCell(EBX+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[36] = "VM:WriteCell(ECX+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[37] = "VM:WriteCell(EDX+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[38] = "VM:WriteCell(ESI+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[39] = "VM:WriteCell(EDI+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[40] = "VM:WriteCell(ESP+$BYTE,$EXPR)"
ZVM.OperandFastWriteFunctions[41] = "VM:WriteCell(EBP+$BYTE,$EXPR)"
-- Extended registers
for reg=0,31 do ZVM.OperandFastWriteFunctions[2048+reg] = "R"..reg.." = $EXPR" end
for reg=0,31 do ZVM.OperandFastWriteFunctions[2080+reg] = "VM:WriteCell(R"..reg.."+$SEG,$EXPR)" end
for reg=0,31 do ZVM.OperandFastWriteFunctions[2144+reg] = "VM:WriteCell(R"..reg.."+$BYTE,$EXPR)" end




--------------------------------------------------------------------------------
-- Functions to decode RM bytes (psuedo-READ)
ZVM.OperandFastReadFunctions = {}
-- GP registers
ZVM.OperandFastReadFunctions[01] = "EAX"
ZVM.OperandFastReadFunctions[02] = "EBX"
ZVM.OperandFastReadFunctions[03] = "ECX"
ZVM.OperandFastReadFunctions[04] = "EDX"
ZVM.OperandFastReadFunctions[05] = "ESI"
ZVM.OperandFastReadFunctions[06] = "EDI"
ZVM.OperandFastReadFunctions[07] = "ESP"
ZVM.OperandFastReadFunctions[08] = "EBP"
-- Read from memory by GP
ZVM.OperandFastReadFunctions[17] = "(VM:ReadCell(EAX+$SEG) or 0)"
ZVM.OperandFastReadFunctions[18] = "(VM:ReadCell(EBX+$SEG) or 0)"
ZVM.OperandFastReadFunctions[19] = "(VM:ReadCell(ECX+$SEG) or 0)"
ZVM.OperandFastReadFunctions[20] = "(VM:ReadCell(EDX+$SEG) or 0)"
ZVM.OperandFastReadFunctions[21] = "(VM:ReadCell(ESI+$SEG) or 0)"
ZVM.OperandFastReadFunctions[22] = "(VM:ReadCell(EDI+$SEG) or 0)"
ZVM.OperandFastReadFunctions[23] = "(VM:ReadCell(ESP+$SEG) or 0)"
ZVM.OperandFastReadFunctions[24] = "(VM:ReadCell(EBP+$SEG) or 0)"
-- Read from memory by displacement
ZVM.OperandFastReadFunctions[25] = "(VM:ReadCell($BYTE+$SEG) or 0)"
-- Register plus segment
ZVM.OperandFastReadFunctions[26] = "(EAX+$SEG)"
ZVM.OperandFastReadFunctions[27] = "(EBX+$SEG)"
ZVM.OperandFastReadFunctions[28] = "(ECX+$SEG)"
ZVM.OperandFastReadFunctions[29] = "(EDX+$SEG)"
ZVM.OperandFastReadFunctions[30] = "(ESI+$SEG)"
ZVM.OperandFastReadFunctions[31] = "(EDI+$SEG)"
ZVM.OperandFastReadFunctions[32] = "(ESP+$SEG)"
ZVM.OperandFastReadFunctions[33] = "(EBP+$SEG)"
-- Read by register plus immediate
ZVM.OperandFastReadFunctions[34] = "(VM:ReadCell(EAX+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[35] = "(VM:ReadCell(EBX+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[36] = "(VM:ReadCell(ECX+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[37] = "(VM:ReadCell(EDX+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[38] = "(VM:ReadCell(ESI+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[39] = "(VM:ReadCell(EDI+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[40] = "(VM:ReadCell(ESP+$BYTE) or 0)"
ZVM.OperandFastReadFunctions[41] = "(VM:ReadCell(EBP+$BYTE) or 0)"
-- Register plus immediate
ZVM.OperandFastReadFunctions[42] = "(EAX+$BYTE)"
ZVM.OperandFastReadFunctions[43] = "(EBX+$BYTE)"
ZVM.OperandFastReadFunctions[44] = "(ECX+$BYTE)"
ZVM.OperandFastReadFunctions[45] = "(EDX+$BYTE)"
ZVM.OperandFastReadFunctions[46] = "(ESI+$BYTE)"
ZVM.OperandFastReadFunctions[47] = "(EDI+$BYTE)"
ZVM.OperandFastReadFunctions[48] = "(ESP+$BYTE)"
ZVM.OperandFastReadFunctions[49] = "(EBP+$BYTE)"
-- Extended registers
for reg=0,31 do ZVM.OperandFastReadFunctions[2048+reg] = "R"..reg end
for reg=0,31 do ZVM.OperandFastReadFunctions[2080+reg] = "(VM:ReadCell(R"..reg.."+$SEG) or 0)" end
for reg=0,31 do ZVM.OperandFastReadFunctions[2112+reg] = "(R"..reg.."+$SEG)" end
for reg=0,31 do ZVM.OperandFastReadFunctions[2144+reg] = "(VM:ReadCell(R"..reg.."+$BYTE) or 0)" end
for reg=0,31 do ZVM.OperandFastReadFunctions[2176+reg] = "(R"..reg.."+$BYTE)" end




--------------------------------------------------------------------------------
-- Is byte fetch required for the RM
ZVM.NeedFetchByteLookup = {}
ZVM.NeedFetchByteLookup[0]  = true
ZVM.NeedFetchByteLookup[25] = true
ZVM.NeedFetchByteLookup[34] = true
ZVM.NeedFetchByteLookup[35] = true
ZVM.NeedFetchByteLookup[36] = true
ZVM.NeedFetchByteLookup[37] = true
ZVM.NeedFetchByteLookup[38] = true
ZVM.NeedFetchByteLookup[39] = true
ZVM.NeedFetchByteLookup[40] = true
ZVM.NeedFetchByteLookup[41] = true
ZVM.NeedFetchByteLookup[42] = true
ZVM.NeedFetchByteLookup[43] = true
ZVM.NeedFetchByteLookup[44] = true
ZVM.NeedFetchByteLookup[45] = true
ZVM.NeedFetchByteLookup[46] = true
ZVM.NeedFetchByteLookup[47] = true
ZVM.NeedFetchByteLookup[48] = true
ZVM.NeedFetchByteLookup[49] = true
ZVM.NeedFetchByteLookup[50] = true

-- Is interrupt check required for the RM
ZVM.NeedInterruptCheck = {}
ZVM.NeedInterruptCheck[17] = true
ZVM.NeedInterruptCheck[18] = true
ZVM.NeedInterruptCheck[19] = true
ZVM.NeedInterruptCheck[20] = true
ZVM.NeedInterruptCheck[21] = true
ZVM.NeedInterruptCheck[22] = true
ZVM.NeedInterruptCheck[23] = true
ZVM.NeedInterruptCheck[24] = true
ZVM.NeedInterruptCheck[25] = true
ZVM.NeedInterruptCheck[34] = true
ZVM.NeedInterruptCheck[35] = true
ZVM.NeedInterruptCheck[36] = true
ZVM.NeedInterruptCheck[37] = true
ZVM.NeedInterruptCheck[38] = true
ZVM.NeedInterruptCheck[39] = true
ZVM.NeedInterruptCheck[40] = true
ZVM.NeedInterruptCheck[41] = true
for i=1000,2023 do ZVM.NeedInterruptCheck[i] = true end
for i=2048,2207 do ZVM.NeedInterruptCheck[i] = true end

-- Register lookup table   FIXME: add segments
ZVM.NeedRegisterLookup = {}
ZVM.NeedRegisterLookup["EAX"] = 1
ZVM.NeedRegisterLookup["EBX"] = 2
ZVM.NeedRegisterLookup["ECX"] = 3
ZVM.NeedRegisterLookup["EDX"] = 4
ZVM.NeedRegisterLookup["ESI"] = 5
ZVM.NeedRegisterLookup["EDI"] = 6
ZVM.NeedRegisterLookup["ESP"] = 7
ZVM.NeedRegisterLookup["EBP"] = 8
for reg=0,31 do ZVM.NeedRegisterLookup["R"..reg] = reg+96 end




--------------------------------------------------------------------------------
-- Lookup for LEA instruction
ZVM.OperandEffectiveAddress = {}
-- Read from memory by GP
ZVM.OperandEffectiveAddress[17] = "(VM.EAX+$SEG)"
ZVM.OperandEffectiveAddress[18] = "(VM.EBX+$SEG)"
ZVM.OperandEffectiveAddress[19] = "(VM.ECX+$SEG)"
ZVM.OperandEffectiveAddress[20] = "(VM.EDX+$SEG)"
ZVM.OperandEffectiveAddress[21] = "(VM.ESI+$SEG)"
ZVM.OperandEffectiveAddress[22] = "(VM.EDI+$SEG)"
ZVM.OperandEffectiveAddress[23] = "(VM.ESP+$SEG)"
ZVM.OperandEffectiveAddress[24] = "(VM.EBP+$SEG)"
-- Read from memory by displacement
ZVM.OperandEffectiveAddress[25] = "($BYTE+$SEG)"
-- Read by register plus immediate
ZVM.OperandEffectiveAddress[34] = "(VM.EAX+$BYTE)"
ZVM.OperandEffectiveAddress[35] = "(VM.EBX+$BYTE)"
ZVM.OperandEffectiveAddress[36] = "(VM.ECX+$BYTE)"
ZVM.OperandEffectiveAddress[37] = "(VM.EDX+$BYTE)"
ZVM.OperandEffectiveAddress[38] = "(VM.ESI+$BYTE)"
ZVM.OperandEffectiveAddress[39] = "(VM.EDI+$BYTE)"
ZVM.OperandEffectiveAddress[40] = "(VM.ESP+$BYTE)"
ZVM.OperandEffectiveAddress[41] = "(VM.EBP+$BYTE)"
-- Ports
for i=1000,2024 do ZVM.OperandEffectiveAddress[i] = -i+1000-1 end
-- Extended registers
for reg=0,31 do ZVM.OperandEffectiveAddress[2080+reg] = "(VM.R"..reg.."+$SEG)" end
for reg=0,31 do ZVM.OperandEffectiveAddress[2144+reg] = "(VM.R"..reg.."+$BYTE)" end
