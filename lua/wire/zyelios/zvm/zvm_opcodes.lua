--------------------------------------------------------------------------------
-- Zyelios VM (Zyelios CPU/GPU virtual machine)
--
-- Primary opcode set
--------------------------------------------------------------------------------




-- Initialize opcode count lookup table
ZVM.OperandCount = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  ZVM.OperandCount[instruction.Opcode] = instruction.OperandCount
end




-- Initialize runlevel lookup table
ZVM.OpcodeRunLevel = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  if instruction.Privileged then
    ZVM.OpcodeRunLevel[instruction.Opcode] = 0
  end
end




--------------------------------------------------------------------------------
-- Hand-leg guide to writing ZCPU microcode
-- self:Dyn_Emit(code)
--   Emits microcode to output stream
--
-- self:Dyn_EmitOperand(OP,code,emitNow)
-- self:Dyn_EmitOperand(code)
--   Emits write to specific operand (if no operant specified - then operand #1)
--   Passing emitNow as true will emit operand at the current spot in microcode,
--   and set it later (must be done if operand is set inside block).
--
-- self:Dyn_EmitState()
--   Pushes state update - all global registers are set to their local values
--
-- self:Dyn_EmitBreak(emitIP)
--   Emits a return (does not push state). Emits new IP if required
--
-- self:Dyn_EmitForceRegisterGlobal(register)
--   Forces a specific register to be global (so VM.EAX has valid value)
--
-- self:Dyn_EmitForceRegisterLocal(register)
--   Forces a specific register to be local (so EAX has valid value)
--   Marks register as changed
--
-- self:Dyn_EmitRegisterValueChanged(register)
--   Marks that there now exists local state for the register
--
-- self:Dyn_EmitInterrupt(intNo,intParam)
--   Emits interrupt call
--
-- self:Dyn_EmitInterruptCheck()
--   Emits interrupt check



--------------------------------------------------------------------------------
-- Load all opcodes
ZVM.OpcodeTable = {}

ZVM.OpcodeTable[0] = function(self)  --END (STOP)
  self:Dyn_EmitInterrupt("2","0")
  self.PrecompileBreak = true -- Stop precompiler from following further
end
ZVM.OpcodeTable[1] = function(self)  --JNE
  self:Dyn_Emit("if VM.CMPR ~= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[2] = function(self)  --JMP
  self:Dyn_Emit("VM:Jump($1)")
  self:Dyn_EmitState()
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true -- Stop precompiler from following further
end
ZVM.OpcodeTable[3] = function(self)  --JG
  self:Dyn_Emit("if VM.CMPR > 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[4] = function(self)  --JGE
  self:Dyn_Emit("if VM.CMPR >= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[5] = function(self)  --JL
  self:Dyn_Emit("if VM.CMPR < 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
--  self.PrecompileBreak = true
end
ZVM.OpcodeTable[6] = function(self)  --JLE
  self:Dyn_Emit("if VM.CMPR <= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[7] = function(self)  --JE
  self:Dyn_Emit("if VM.CMPR == 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[8] = function(self)  --CPUID
  self:Dyn_Emit("EAX = VM:CPUID($1)")
  self:Dyn_EmitRegisterValueChanged("EAX")
end
ZVM.OpcodeTable[9] = function(self)  --PUSH
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("VM:Push($1)")
  self:Dyn_EmitInterruptCheck()
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[10] = function(self)  --ADD
  self:Dyn_EmitOperand("$1 + $2")
end
ZVM.OpcodeTable[11] = function(self)  --SUB
  self:Dyn_EmitOperand("$1 - $2")
end
ZVM.OpcodeTable[12] = function(self)  --MUL
  self:Dyn_EmitOperand("$1 * $2")
end
ZVM.OpcodeTable[13] = function(self)  --DIV
  self:Dyn_Emit("$L OP = $2")
  self:Dyn_EmitOperand("$1 / OP")
  self:Dyn_Emit("if math.abs(OP) < 1e-12 then")
    self:Dyn_EmitInterrupt("3","0")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[14] = function(self)  --MOV
  self:Dyn_EmitOperand("$2")
end
ZVM.OpcodeTable[15] = function(self)  --CMP
  self:Dyn_Emit("VM.CMPR = $1 - $2")
end
ZVM.OpcodeTable[16] = function(self)  --RD
  self:Dyn_Emit("$L OP,ANS = $2,0")
  self:Dyn_EmitOperand("ANS")
  self:Dyn_Emit("if VM.Memory[OP] then")
    self:Dyn_Emit("ANS = VM.Memory[OP]")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[17] = function(self)  --WD
  self:Dyn_Emit("$L ADDR = math.floor($1)")
  self:Dyn_Emit("if (ADDR >= 0) and (ADDR <= 65535) then")
    self:Dyn_Emit("VM.Memory[ADDR] = $2")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[18] = function(self)  --MIN
  self:Dyn_EmitOperand("math.min($1,$2)")
end
ZVM.OpcodeTable[19] = function(self)  --MAX
  self:Dyn_EmitOperand("math.max($1,$2)")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[20] = function(self)  --INC
  self:Dyn_EmitOperand("$1 + 1")
end
ZVM.OpcodeTable[21] = function(self)  --DEC
  self:Dyn_EmitOperand("$1 - 1")
end
ZVM.OpcodeTable[22] = function(self)  --NEG
  self:Dyn_EmitOperand("-$1")
end
ZVM.OpcodeTable[23] = function(self)  --RAND
  self:Dyn_EmitOperand("math.random()")
end
ZVM.OpcodeTable[24] = function(self)  --LOOP
  self:Dyn_EmitForceRegisterLocal("ECX")
  self:Dyn_Emit("ECX = ECX - 1")
  self:Dyn_Emit("if ECX ~= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[25] = function(self)  --LOOPA
  self:Dyn_EmitForceRegisterLocal("EAX")
  self:Dyn_Emit("EAX = EAX - 1")
  self:Dyn_Emit("if EAX ~= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[26] = function(self)  --LOOPB
  self:Dyn_EmitForceRegisterLocal("EBX")
  self:Dyn_Emit("EBX = EBX - 1")
  self:Dyn_Emit("if VM.EBX ~= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[27] = function(self)  --LOOPD
  self:Dyn_EmitForceRegisterLocal("EDX")
  self:Dyn_Emit("EDX = EDX - 1")
  self:Dyn_Emit("if EDX ~= 0 then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[28] = function(self)  --SPG
  self:Dyn_Emit("$L IDX = math.floor($1 / 128)")
  self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("if VM.CurrentPage.RunLevel <= PAGE.RunLevel then")
    self:Dyn_Emit("PAGE.Read = 1")
    self:Dyn_Emit("PAGE.Write = 0")
    self:Dyn_Emit("VM:SetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("else")
    self:Dyn_EmitInterrupt("11","IDX")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[29] = function(self)  --CPG
  self:Dyn_Emit("$L idx = math.floor($1 / 128)")
  self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("if VM.CurrentPage.RunLevel <= VM.Page[idx].RunLevel then")
    self:Dyn_Emit("PAGE.Read = 1")
    self:Dyn_Emit("PAGE.Write = 1")
    self:Dyn_Emit("VM:SetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("else")
    self:Dyn_EmitInterrupt("11","IDX")
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[30] = function(self)  --POP
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_EmitOperand(1,"VM:Pop()",true)
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[31] = function(self)  --CALL
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
  self:Dyn_EmitInterruptCheck()

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[32] = function(self)  --BNOT
  self:Dyn_EmitOperand("VM:BinaryNot($1)")
end
ZVM.OpcodeTable[33] = function(self)  --FINT
  self:Dyn_EmitOperand("math.floor($1)")
end
ZVM.OpcodeTable[34] = function(self)  --RND
  self:Dyn_EmitOperand("math.Round($1)")
end
ZVM.OpcodeTable[35] = function(self)  --FFRAC
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_EmitOperand("OP - math.floor(OP)")
end
ZVM.OpcodeTable[36] = function(self)  --FINV
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_EmitOperand("1 / OP")
  self:Dyn_Emit("if math.abs(OP) < 1e-12 then")
    self:Dyn_EmitInterrupt("3","1")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[37] = function(self)  --HALT
  self:Dyn_Emit("VM.HaltPort = math.floor($1)")
end
ZVM.OpcodeTable[38] = function(self)  --FSHL
  self:Dyn_EmitOperand("$1 * 2")
end
ZVM.OpcodeTable[39] = function(self)  --FSHR
  self:Dyn_EmitOperand("$1 / 2")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[40] = function(self)  --RET
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("$L IP = VM:Pop()")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Jump(IP)")
  self:Dyn_EmitState()
  self:Dyn_EmitBreak()

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[41] = function(self)  --IRET
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.EF == 1 then")
    self:Dyn_Emit("$L CS = VM:Pop()")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("$L IP = VM:Pop()")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:Jump(IP,CS)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("else")
    self:Dyn_Emit("$L IP = VM:Pop()")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:Jump(IP,CS)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[42] = function(self)  --STI
  self:Dyn_Emit("VM.NIF = 1")
end
ZVM.OpcodeTable[43] = function(self)  --CLI
  self:Dyn_Emit("VM.IF = 0")
end
ZVM.OpcodeTable[44] = function(self)  --STP
  self:Dyn_Emit("VM.PF = 1")
end
ZVM.OpcodeTable[45] = function(self)  --CLP
  self:Dyn_Emit("VM.PF = 0")
end
ZVM.OpcodeTable[46] = function(self)  --STD
  if self.MicrocodeDebug then
    self:Dyn_Emit("VM.Debug = true")
  end
end
ZVM.OpcodeTable[47] = function(self)  --RETF
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("$L IP = VM:Pop()")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("$L CS = VM:Pop()")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Jump(IP,CS)")
  self:Dyn_EmitState()
  self:Dyn_EmitBreak()

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[48] = function(self)  --STEF
  self:Dyn_Emit("VM.EF = 1")
end
ZVM.OpcodeTable[49] = function(self)  --CLEF
  self:Dyn_Emit("VM.EF = 0")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[50] = function(self)  --AND
  self:Dyn_Emit("$L OP = 0")
  self:Dyn_EmitOperand("OP")
  self:Dyn_Emit("if ($1 > 0) and ($2 > 0) then")
    self:Dyn_Emit("OP = 1")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[51] = function(self)  --OR
  self:Dyn_Emit("$L OP = 0")
  self:Dyn_EmitOperand("OP")
  self:Dyn_Emit("if ($1 > 0) or ($2 > 0) then")
    self:Dyn_Emit("OP = 1")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[52] = function(self)  --XOR
  self:Dyn_Emit("$L OP1,OP2 = $1,$2")
  self:Dyn_Emit("$L OP = 0")
  self:Dyn_EmitOperand("OP")
  self:Dyn_Emit("if ((OP1 >  0) and (OP2 <= 0)) or")
  self:Dyn_Emit("   ((OP1 <= 0) and (OP2 >  0)) then")
    self:Dyn_Emit("OP = 1")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[53] = function(self)  --FSIN
  self:Dyn_EmitOperand("math.sin($2)")
end
ZVM.OpcodeTable[54] = function(self)  --FCOS
  self:Dyn_EmitOperand("math.cos($2)")
end
ZVM.OpcodeTable[55] = function(self)  --FTAN
  self:Dyn_EmitOperand("math.tan($2)")
end
ZVM.OpcodeTable[56] = function(self)  --FASIN
  self:Dyn_EmitOperand("math.asin($2)")
end
ZVM.OpcodeTable[57] = function(self)  --FACOS
  self:Dyn_EmitOperand("math.acos($2)")
end
ZVM.OpcodeTable[58] = function(self)  --FATAN
  self:Dyn_EmitOperand("math.atan($2)")
end
ZVM.OpcodeTable[59] = function(self)  --MOD
  self:Dyn_EmitOperand("math.fmod($1,$2)")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[60] = function(self)  --BIT
  self:Dyn_Emit("$L BITS = VM:IntegerToBinary($1)")
  self:Dyn_Emit("VM.CMPR = BITS[math.floor($2)] or 0")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[61] = function(self)  --SBIT
  self:Dyn_Emit("$L BITS = VM:IntegerToBinary($1)")
  self:Dyn_Emit("BITS[math.floor($2)] = 1")
  self:Dyn_EmitOperand("VM:BinaryToInteger(BITS)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 20")
end
ZVM.OpcodeTable[62] = function(self)  --CBIT
  self:Dyn_Emit("$L BITS = VM:IntegerToBinary($1)")
  self:Dyn_Emit("BITS[math.floor($2)] = 0")
  self:Dyn_EmitOperand("VM:BinaryToInteger(BITS)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 20")
end
ZVM.OpcodeTable[63] = function(self)  --TBIT
  self:Dyn_Emit("$L BITS = VM:IntegerToBinary($1)")
  self:Dyn_Emit("BITS[math.floor($2)] = 1 - (BITS[math.floor($2)] or 0)")
  self:Dyn_EmitOperand("VM:BinaryToInteger(BITS)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[64] = function(self)   --BAND
  self:Dyn_EmitOperand("VM:BinaryAnd($1,$2)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[65] = function(self)  --BOR
  self:Dyn_EmitOperand("VM:BinaryOr($1,$2)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[66] = function(self)   --BXOR
  self:Dyn_EmitOperand("VM:BinaryXor($1,$2)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[67] = function(self)  --BSHL
  self:Dyn_EmitOperand("VM:BinarySHL($1,$2)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[68] = function(self)  --BSHR
  self:Dyn_EmitOperand("VM:BinarySHR($1,$2)")
  self:Dyn_Emit("VM.TMR = VM.TMR + 30")
end
ZVM.OpcodeTable[69] = function(self)  --JMPF
  self:Dyn_Emit("VM:Jump($1,$2)")
  self:Dyn_EmitState()
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[70] = function(self)  --EXTINT
  self:Dyn_EmitState()
  self:Emit("VM.IP = "..(self.PrecompileIP or 0))
  self:Emit("VM.XEIP = "..(self.PrecompileTrueXEIP or 0))
  self:Dyn_Emit("VM:ExternalInterrupt(math.floor($1))")
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
ZVM.OpcodeTable[71] = function(self)  --CNE
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR ~= 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[72] = function(self)  --CJMP
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
    self:Dyn_Emit("VM:Jump($1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[73] = function(self)  --CG
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR > 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[74] = function(self)  --CGE
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR >= 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[75] = function(self)  --CL
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR < 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[76] = function(self)  --CLE
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR <= 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[77] = function(self)  --CE
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM.CMPR == 0 then")
    self:Dyn_Emit("if VM:Push("..self.PrecompileIP..") then")
      self:Dyn_Emit("VM:Jump($1)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[78] = function(self)  --MCOPY
  self:Dyn_EmitForceRegisterLocal("ESI")
  self:Dyn_EmitForceRegisterLocal("EDI")
  self:Dyn_Emit("for i = 1,math.Clamp($1,0,8192) do")
    self:Dyn_Emit("$L VAL")
    self:Dyn_Emit("VAL = VM:ReadCell(ESI)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell(EDI,VAL)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("EDI = EDI + 1")
    self:Dyn_Emit("ESI = ESI + 1")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[79] = function(self)  --MXCHG
  self:Dyn_EmitForceRegisterLocal("ESI")
  self:Dyn_EmitForceRegisterLocal("EDI")
  self:Dyn_Emit("for i = 1,math.Clamp($1,0,8192) do")
    self:Dyn_Emit("$L VAL1,VAL2")
    self:Dyn_Emit("VAL1 = VM:ReadCell(ESI)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VAL2 = VM:ReadCell(EDI)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell(EDI,VAL1)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell(ESI,VAL2)")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("EDI = EDI + 1")
    self:Dyn_Emit("ESI = ESI + 1")
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[80] = function(self)  --FPWR
  self:Dyn_EmitOperand("$1^$2")
end
ZVM.OpcodeTable[81] = function(self)  --XCHG
  self:Dyn_Emit("$L L0,L1 = $1,$2")
  self:Dyn_EmitOperand(1,"L1")
  self:Dyn_EmitOperand(2,"L0")
end
ZVM.OpcodeTable[82] = function(self)  --FLOG
  self:Dyn_EmitOperand("math.log($2)")
end
ZVM.OpcodeTable[83] = function(self)  --FLOG10
  self:Dyn_EmitOperand("math.log10($2)")
end
ZVM.OpcodeTable[84] = function(self)  --IN
  self:Dyn_EmitOperand("VM:ReadPort($2)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[85] = function(self)  --OUT
  self:Dyn_Emit("VM:WritePort($1,$2)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[86] = function(self)  --FABS
  self:Dyn_EmitOperand("math.abs($2)")
end
ZVM.OpcodeTable[87] = function(self)  --FSGN
  self:Dyn_Emit("$L OP = $2")
  self:Dyn_Emit("if OP > 0 then")
    self:Dyn_EmitOperand(1,"1",true)
  self:Dyn_Emit("elseif OP < 0 then")
    self:Dyn_EmitOperand(1,"-1",true)
  self:Dyn_Emit("else")
    self:Dyn_EmitOperand(1,"0",true)
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[88] = function(self)  --FEXP
  self:Dyn_EmitOperand("math.exp($2)")
end
ZVM.OpcodeTable[89] = function(self)  --CALLF
  self:Dyn_EmitForceRegisterGlobal("CS")
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("if VM:Push(VM.CS) and VM:Push("..self.PrecompileIP..") then")
    self:Dyn_Emit("VM:Jump($1,$2)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
  self:Dyn_EmitInterruptCheck()

  self.PrecompileBreak = true
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[90] = function(self) --FPI
  self:Dyn_EmitOperand("3.141592653589793")
end
ZVM.OpcodeTable[91] = function(self) --FE
  self:Dyn_EmitOperand("2.718281828459045")
end
ZVM.OpcodeTable[92] = function(self)  --INT
  self:Dyn_EmitInterrupt("$1","0")
end
ZVM.OpcodeTable[93] = function(self)  --TPG
  self:Dyn_Emit("$L TADD = math.floor($1*128)")
  self:Dyn_Emit("$L OLDIF = VM.IF")
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_Emit("VM.IF = 0")
  self:Dyn_Emit("VM.CMPR = 0")
  self:Dyn_Emit("while TADD < OP*128+128 do")
    self:Dyn_Emit("$L VAL = VM:ReadCell(TADD)")
    self:Dyn_Emit("if VM.INTR == 1 then")
      self:Dyn_Emit("VM.CMPR = TADD")
      self:Dyn_Emit("TADD = OP*128+128")
    self:Dyn_Emit("end")
    self:Dyn_Emit("TADD = TADD+1")
  self:Dyn_Emit("end")
  self:Dyn_Emit("VM.INTR = 0")
  self:Dyn_Emit("VM.IF = OLDIF")
end
ZVM.OpcodeTable[94] = function(self)  --FCEIL
  self:Dyn_EmitOperand("math.ceil($1)")
end
ZVM.OpcodeTable[95] = function(self) --ERPG
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_Emit("if (OP >= 0) and (OP < VM.ROMSize/128) then")
    self:Dyn_Emit("$L TADD = OP*128")
    self:Dyn_Emit("while TADD < OP*128+128 do")
      self:Dyn_Emit("VM.ROM[TADD] = nil")
      self:Dyn_Emit("TADD = TADD+1")
    self:Dyn_Emit("end")
  self:Dyn_Emit("else")
    self:Dyn_EmitInterrupt("12","0")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[96] = function(self)  --WRPG
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_Emit("if (OP >= 0) and (OP < VM.ROMSize/128) then")
    self:Dyn_Emit("$L TADD = OP*128")
    self:Dyn_Emit("while TADD < OP*128+128 do")
      self:Dyn_Emit("VM.ROM[TADD] = VM.Memory[TADD]")
      self:Dyn_Emit("TADD = TADD+1")
    self:Dyn_Emit("end")
  self:Dyn_Emit("else")
    self:Dyn_EmitInterrupt("12","0")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[97] = function(self) --RDPG
  self:Dyn_Emit("$L OP = $1")
  self:Dyn_Emit("if (OP >= 0) and (OP < VM.ROMSize/128) then")
    self:Dyn_Emit("$L TADD = OP*128")
    self:Dyn_Emit("while TADD < OP*128+128 do")
      self:Dyn_Emit("VM.Memory[TADD] = VM.ROM[TADD]")
      self:Dyn_Emit("TADD = TADD+1")
    self:Dyn_Emit("end")
  self:Dyn_Emit("else")
    self:Dyn_EmitInterrupt("12","0")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[98] = function(self)  --TIMER
  self:Dyn_EmitOperand("(VM.TIMER+"..(self.PrecompileInstruction or 0).."*VM.TimerDT)")
end
ZVM.OpcodeTable[99] = function(self)  --LIDTR
  self:Dyn_Emit("VM.IDTR = $1")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[100] = function(self)  --STATESTORE
  self:Dyn_EmitState()
  self:Dyn_Emit("VM:WriteCell($1 + 00,"..self.PrecompileIP..")")

  self:Dyn_Emit("VM:WriteCell($1 + 01,VM.EAX)")
  self:Dyn_Emit("VM:WriteCell($1 + 02,VM.EBX)")
  self:Dyn_Emit("VM:WriteCell($1 + 03,VM.ECX)")
  self:Dyn_Emit("VM:WriteCell($1 + 04,VM.EDX)")
  self:Dyn_Emit("VM:WriteCell($1 + 05,VM.ESI)")
  self:Dyn_Emit("VM:WriteCell($1 + 06,VM.EDI)")
  self:Dyn_Emit("VM:WriteCell($1 + 07,VM.ESP)")
  self:Dyn_Emit("VM:WriteCell($1 + 08,VM.EBP)")

  self:Dyn_Emit("VM:WriteCell($1 + 09,VM.CS)")
  self:Dyn_Emit("VM:WriteCell($1 + 10,VM.SS)")
  self:Dyn_Emit("VM:WriteCell($1 + 11,VM.DS)")
  self:Dyn_Emit("VM:WriteCell($1 + 12,VM.ES)")
  self:Dyn_Emit("VM:WriteCell($1 + 13,VM.GS)")
  self:Dyn_Emit("VM:WriteCell($1 + 14,VM.FS)")

  self:Dyn_Emit("VM:WriteCell($1 + 15,VM.CMPR)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[101] = function(self)  --JNER
  self:Dyn_Emit("if VM.CMPR ~= 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[102] = function(self)  --JMPR
  self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
  self:Dyn_EmitState()
  self:Dyn_EmitBreak()

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[103] = function(self)  --JGR
  self:Dyn_Emit("if VM.CMPR > 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[104] = function(self)  --JGER
  self:Dyn_Emit("if VM.CMPR >= 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[105] = function(self)  --JLR
  self:Dyn_Emit("if VM.CMPR < 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[106] = function(self)  --JLER
  self:Dyn_Emit("if VM.CMPR <= 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[107] = function(self)  --JER
  self:Dyn_Emit("if VM.CMPR == 0 then")
    self:Dyn_Emit("VM:Jump("..self.PrecompileIP.." + $1)")
    self:Dyn_EmitState()
    self:Dyn_EmitBreak()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[108] = function(self)  --LNEG
  self:Dyn_EmitOperand("1-math.Clamp($1,0,1)")
end
ZVM.OpcodeTable[109] = function(self)   --STATERESTORE
  self:Dyn_Emit("          VM:ReadCell($1 + 00)")

  self:Dyn_Emit("EAX =     VM:ReadCell($1 + 01) or 0")
  self:Dyn_Emit("EBX =     VM:ReadCell($1 + 02) or 0")
  self:Dyn_Emit("ECX =     VM:ReadCell($1 + 03) or 0")
  self:Dyn_Emit("EDX =     VM:ReadCell($1 + 04) or 0")
  self:Dyn_Emit("ESI =     VM:ReadCell($1 + 05) or 0")
  self:Dyn_Emit("EDI =     VM:ReadCell($1 + 06) or 0")
  self:Dyn_Emit("ESP =     VM:ReadCell($1 + 07) or 0")
  self:Dyn_Emit("EBP =     VM:ReadCell($1 + 08) or 0")

  self:Dyn_Emit("CS  =     VM:ReadCell($1 + 09) or 0")
  self:Dyn_Emit("SS  =     VM:ReadCell($1 + 10) or 0")
  self:Dyn_Emit("DS  =     VM:ReadCell($1 + 11) or 0")
  self:Dyn_Emit("ES  =     VM:ReadCell($1 + 12) or 0")
  self:Dyn_Emit("GS  =     VM:ReadCell($1 + 13) or 0")
  self:Dyn_Emit("FS  =     VM:ReadCell($1 + 14) or 0")

  self:Dyn_Emit("VM.CMPR = VM:ReadCell($1 + 15) or 0")

  self:Dyn_EmitInterruptCheck()

  self:Dyn_EmitRegisterValueChanged("EAX")
  self:Dyn_EmitRegisterValueChanged("EBX")
  self:Dyn_EmitRegisterValueChanged("ECX")
  self:Dyn_EmitRegisterValueChanged("EDX")
  self:Dyn_EmitRegisterValueChanged("ESI")
  self:Dyn_EmitRegisterValueChanged("EDI")
  self:Dyn_EmitRegisterValueChanged("ESP")
  self:Dyn_EmitRegisterValueChanged("EBP")

  self:Dyn_EmitRegisterValueChanged("CS")
  self:Dyn_EmitRegisterValueChanged("SS")
  self:Dyn_EmitRegisterValueChanged("DS")
  self:Dyn_EmitRegisterValueChanged("ES")
  self:Dyn_EmitRegisterValueChanged("GS")
  self:Dyn_EmitRegisterValueChanged("FS")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[110] = function(self)  --EXTRET
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("$L V = 0")
  self:Dyn_EmitState()
  
  self:Dyn_Emit("V = VM:Pop()") -- IRET CS
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("V = VM:Pop()") -- IRET EIP
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("$L IP = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.CMPR = V")

  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.EAX = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.EBX = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.ECX = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.EDX = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.EBP = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  -- Do not set ESP right now
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.ESI = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.EDI = V")

  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("$L CS = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  -- Do not set SS right now
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.DS = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.FS = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.GS = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.ES = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.KS = V")
  self:Dyn_Emit("V = VM:Pop()")  self:Dyn_EmitInterruptCheck()  self:Dyn_Emit("VM.LS = V")

  self:Dyn_Emit("VM:Jump(IP,CS)")
  self:Dyn_EmitBreak()

  self.PrecompileBreak = true
end
ZVM.OpcodeTable[111] = function(self)  --IDLE
  self:Dyn_Emit("VM.Idle = 1")
end
ZVM.OpcodeTable[112] = function(self)  --NOP
end
ZVM.OpcodeTable[113] = function(self)  --RLADD
  self:Dyn_Emit("EAX = VM.LADD")
  self:Dyn_EmitRegisterValueChanged("EAX")
end
ZVM.OpcodeTable[114] = function(self)  --PUSHA
  self:Dyn_EmitForceRegisterLocal("EAX")
  self:Dyn_EmitForceRegisterLocal("EBX")
  self:Dyn_EmitForceRegisterLocal("ECX")
  self:Dyn_EmitForceRegisterLocal("EDX")
  self:Dyn_EmitForceRegisterLocal("ESI")
  self:Dyn_EmitForceRegisterLocal("EDI")
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_EmitForceRegisterLocal("EBP")

  self:Dyn_Emit("VM:Push(EDI)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(ESI)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(EBP)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(VM.ESP)") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(EDX)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(ECX)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(EBX)")    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:Push(EAX)")    self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[115] = function(self)  --POPA
  self:Dyn_EmitForceRegisterGlobal("ESP")

  self:Dyn_Emit("EAX = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("EBX = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("ECX = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("EDX = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("$L SP = VM:Pop()") self:Dyn_EmitInterruptCheck() -- Do not write stack pointer
  self:Dyn_Emit("EBP = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("ESI = VM:Pop()") self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("EDI = VM:Pop()") self:Dyn_EmitInterruptCheck()

  self:Dyn_EmitRegisterValueChanged("EAX")
  self:Dyn_EmitRegisterValueChanged("EBX")
  self:Dyn_EmitRegisterValueChanged("ECX")
  self:Dyn_EmitRegisterValueChanged("EDX")
  self:Dyn_EmitRegisterValueChanged("ESI")
  self:Dyn_EmitRegisterValueChanged("EDI")
  self:Dyn_EmitRegisterValueChanged("EBP")
end
ZVM.OpcodeTable[116] = function(self)  --STD2
  self:Dyn_Emit("VM.HWDEBUG = 1")
  self:Dyn_Emit("VM.DBGSTATE = 0")
end
ZVM.OpcodeTable[117] = function(self)  --LEAVE
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_EmitForceRegisterGlobal("EBP")
  self:Dyn_Emit("VM.ESP = VM.EBP-1")

  self:Dyn_Emit("EBP = VM:Pop()")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_EmitRegisterValueChanged("EBP")
end
ZVM.OpcodeTable[118] = function(self)  --STM
  self:Dyn_Emit("VM.MF = 1")
end
ZVM.OpcodeTable[119] = function(self)  --CLM
  self:Dyn_Emit("VM.MF = 0")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[120] = function(self)  --CPUGET
  self:Dyn_Emit("$L REG = $2")
  self:Dyn_Emit("$L OP = 0")
  self:Dyn_EmitState()
  self:Dyn_EmitOperand("OP")
  self:Dyn_Emit("if VM.InternalRegister[REG] then")
    self:Dyn_Emit("OP = VM[VM.InternalRegister[REG]]")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[121] = function(self)  --CPUSET
  self:Dyn_Emit("$L REG = $1")
  self:Dyn_Emit("if VM.InternalRegister[REG] and (not VM.ReadOnlyRegister[REG]) then")
    self:Dyn_Emit("$L OP = $2")
    self:Dyn_Emit("VM[VM.InternalRegister[REG]] = OP")
    self:Dyn_Emit("if (REG == 0) or (REG == 16) then")
      self:Dyn_Emit("VM:Jump("..self.PrecompileIP..",VM.CS)")
      self:Dyn_EmitState()
      self:Dyn_EmitBreak()
    self:Dyn_Emit("else")
      self:Dyn_Emit("if REG == 1 then EAX = OP end")
      self:Dyn_Emit("if REG == 2 then EBX = OP end")
      self:Dyn_Emit("if REG == 3 then ECX = OP end")
      self:Dyn_Emit("if REG == 4 then EDX = OP end")
      self:Dyn_Emit("if REG == 5 then ESI = OP end")
      self:Dyn_Emit("if REG == 6 then EDI = OP end")
      self:Dyn_Emit("if REG == 7 then ESP = OP end")
      self:Dyn_Emit("if REG == 8 then EBP = OP end")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")

  -- FIXME: registers must be properly synced
end
ZVM.OpcodeTable[122] = function(self)  --SPP
  self:Dyn_Emit("$L FirstAddr")
  self:Dyn_Emit("$L LastAddr")
  self:Dyn_Emit("if VM.BlockSize > 0 then")
    self:Dyn_Emit("FirstAddr = VM.BlockStart")
    self:Dyn_Emit("LastAddr = FirstAddr + math.Clamp(VM.BlockSize,0,8192)")
    self:Dyn_Emit("VM.BlockSize = 0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("FirstAddr = $1 * 128")
    self:Dyn_Emit("LastAddr = $1 * 128 + 127")
  self:Dyn_Emit("end")

  self:Dyn_Emit("$L ADDR = FirstAddr")
  self:Dyn_Emit("$L FLAG = $2")
  self:Dyn_Emit("while ADDR < LastAddr do")
    self:Dyn_Emit("$L IDX = math.floor(ADDR / 128)")
    self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()

    self:Dyn_Emit("if VM.CurrentPage.RunLevel <= PAGE.RunLevel then")
      self:Dyn_Emit("    if FLAG == 0 then PAGE.Read     = 1")
      self:Dyn_Emit("elseif FLAG == 1 then PAGE.Write    = 1")
      self:Dyn_Emit("elseif FLAG == 2 then PAGE.Execute  = 1")
      self:Dyn_Emit("elseif FLAG == 3 then PAGE.RunLevel = 1 end")
      self:Dyn_Emit("VM:SetPageByIndex(IDX)")
      self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("else")
      self:Dyn_EmitInterrupt("11","IDX")
    self:Dyn_Emit("end")
    self:Dyn_Emit("ADDR = ADDR + 128")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[123] = function(self)  --CPP
  self:Dyn_Emit("$L FirstAddr")
  self:Dyn_Emit("$L LastAddr")
  self:Dyn_Emit("if VM.BlockSize > 0 then")
    self:Dyn_Emit("FirstAddr = VM.BlockStart")
    self:Dyn_Emit("LastAddr = FirstAddr + math.Clamp(VM.BlockSize,0,8192)")
    self:Dyn_Emit("VM.BlockSize = 0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("FirstAddr = $1 * 128")
    self:Dyn_Emit("LastAddr = $1 * 128 + 127")
  self:Dyn_Emit("end")

  self:Dyn_Emit("$L ADDR = FirstAddr")
  self:Dyn_Emit("$L FLAG = $2")
  self:Dyn_Emit("while ADDR < LastAddr do")
    self:Dyn_Emit("$L IDX = math.floor(ADDR / 128)")
    self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()

    self:Dyn_Emit("if VM.CurrentPage.RunLevel <= PAGE.RunLevel then")
      self:Dyn_Emit("    if FLAG == 0 then PAGE.Read     = 0")
      self:Dyn_Emit("elseif FLAG == 1 then PAGE.Write    = 0")
      self:Dyn_Emit("elseif FLAG == 2 then PAGE.Execute  = 0")
      self:Dyn_Emit("elseif FLAG == 3 then PAGE.RunLevel = 0 end")
      self:Dyn_Emit("VM:SetPageByIndex(IDX)")
      self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("else")
      self:Dyn_EmitInterrupt("11","IDX")
    self:Dyn_Emit("end")
    self:Dyn_Emit("ADDR = ADDR + 128")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[124] = function(self)  --SRL
  self:Dyn_Emit("$L FirstAddr")
  self:Dyn_Emit("$L LastAddr")
  self:Dyn_Emit("if VM.BlockSize > 0 then")
    self:Dyn_Emit("FirstAddr = VM.BlockStart")
    self:Dyn_Emit("LastAddr = FirstAddr + math.Clamp(VM.BlockSize,0,8192)")
    self:Dyn_Emit("VM.BlockSize = 0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("FirstAddr = $1 * 128")
    self:Dyn_Emit("LastAddr = $1 * 128 + 127")
  self:Dyn_Emit("end")

  self:Dyn_Emit("$L ADDR = FirstAddr")
  self:Dyn_Emit("while ADDR < LastAddr do")
    self:Dyn_Emit("$L IDX = math.floor(ADDR / 128)")
    self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()

    self:Dyn_Emit("if VM.CurrentPage.RunLevel <= PAGE.RunLevel then")
      self:Dyn_Emit("PAGE.RunLevel = $2")
      self:Dyn_Emit("VM:SetPageByIndex(IDX)")
      self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("else")
      self:Dyn_EmitInterrupt("11","IDX")
    self:Dyn_Emit("end")
    self:Dyn_Emit("ADDR = ADDR + 128")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[125] = function(self)  --GRL
  self:Dyn_Emit("$L IDX = math.floor($2 / 128)")
  self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_EmitOperand("PAGE.RunLevel")
end
ZVM.OpcodeTable[126] = function(self)  --LEA
  local emitText = self.OperandEffectiveAddress[self.EmitOperandRM[2]] or "0"
  emitText = string.gsub(emitText,"$BYTE",self.EmitOperandByte[2] or "0")
  emitText = string.gsub(emitText,"$SEG","VM."..(self.EmitOperandSegment[2] or "DS"))
  self:Dyn_EmitOperand(emitText)
end
ZVM.OpcodeTable[127] = function(self)  --BLOCK
  self:Dyn_Emit("VM.BlockStart = $1")
  self:Dyn_Emit("VM.BlockSize = $2")
end
ZVM.OpcodeTable[128] = function(self)  --CMPAND
  self:Dyn_Emit("if VM.CMPR ~= 0 then")
    self:Dyn_Emit("VM.CMPR = $1 - $2")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[129] = function(self)  --CMPOR
  self:Dyn_Emit("if VM.CMPR == 0 then")
    self:Dyn_Emit("VM.CMPR = $1 - $2")
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[130] = function(self)  --MSHIFT  FIXME: Inoperative
  self:Dyn_EmitForceRegisterLocal("ESI")
  self:Dyn_Emit("$L Count = math.Clamp($1,0,8192)")
  self:Dyn_Emit("if Count ~= 0 then")
    self:Dyn_Emit("$L Offset = $2")
    self:Dyn_Emit("$L Buffer = {}")

    self:Dyn_Emit("if Offset > 0 then")
      self:Dyn_Emit("for i = 0,math.Clamp(Count-1-Offset,0,8191) do") --Shifted part
        self:Dyn_Emit("Buffer[i] = VM:ReadCell(ESI+i+Offset)")
      self:Dyn_Emit("end")
      self:Dyn_EmitInterruptCheck()
      self:Dyn_Emit("for i = math.Clamp(Count-1-Offset+1,0,8191),math.Clamp(Count,0,8191) do") --Remaining part
        self:Dyn_Emit("Buffer[i] = VM:ReadCell(ESI+i-(Count-1-Offset+1))")
      self:Dyn_Emit("end")
      self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("else")
      self:Dyn_Emit("for i = math.Clamp(-Offset,0,8191),math.Clamp(Count,0,8191) do") --Shifted part
        self:Dyn_Emit("Buffer[i] = VM:ReadCell(ESI+i+Offset)")
      self:Dyn_Emit("end")
      self:Dyn_EmitInterruptCheck()
      self:Dyn_Emit("for i = 0,math.Clamp(-Offset-1,0,8191) do") --Remaining part
        self:Dyn_Emit("Buffer[i] = VM:ReadCell(ESI+i+(Count-1+Offset+1))")
      self:Dyn_Emit("end")
      self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("end")

    self:Dyn_Emit("for i = 0,Count-1 do")
      self:Dyn_Emit("VM:WriteCell(ESI+i,Buffer[i] or 32)")
    self:Dyn_Emit("end")
    self:Dyn_EmitInterruptCheck()

    self:Dyn_Emit("ESI = ESI + Count")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[131] = function(self)  --SMAP
  self:Dyn_Emit("$L FirstAddr")
  self:Dyn_Emit("$L LastAddr")
  self:Dyn_Emit("if VM.BlockSize > 0 then")
    self:Dyn_Emit("FirstAddr = VM.BlockStart")
    self:Dyn_Emit("LastAddr = FirstAddr + math.Clamp(VM.BlockSize,0,8192)")
    self:Dyn_Emit("VM.BlockSize = 0")
  self:Dyn_Emit("else")
    self:Dyn_Emit("FirstAddr = $1 * 128")
    self:Dyn_Emit("LastAddr = $1 * 128 + 127")
  self:Dyn_Emit("end")

  self:Dyn_Emit("$L ADDR = FirstAddr")
  self:Dyn_Emit("while ADDR < LastAddr do")
    self:Dyn_Emit("$L IDX = math.floor(ADDR / 128)")
    self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
    self:Dyn_EmitInterruptCheck()

    self:Dyn_Emit("if VM.CurrentPage.RunLevel <= PAGE.RunLevel then")
      self:Dyn_Emit("PAGE.MappedIndex = $2")
      self:Dyn_Emit("PAGE.Remapped = 1")
      self:Dyn_Emit("VM:SetPageByIndex(IDX)")
      self:Dyn_EmitInterruptCheck()

      self:Dyn_Emit("for address=IDX*128,IDX*128+127 do")
        self:Dyn_Emit("if VM.IsAddressPrecompiled[address] then")
          self:Dyn_Emit("for k,v in ipairs(VM.IsAddressPrecompiled[address]) do")
            self:Dyn_Emit("VM.PrecompiledData[v] = nil")
            self:Dyn_Emit("VM.IsAddressPrecompiled[address][k] = nil")
          self:Dyn_Emit("end")
        self:Dyn_Emit("end")
      self:Dyn_Emit("end")
    self:Dyn_Emit("else")
      self:Dyn_EmitInterrupt("11","IDX")
    self:Dyn_Emit("end")
    self:Dyn_Emit("ADDR = ADDR + 128")
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[132] = function(self)  --GMAP
  self:Dyn_Emit("$L IDX = math.floor(ADDR / 128)")
  self:Dyn_Emit("$L PAGE = VM:GetPageByIndex(IDX)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_EmitOperand("PAGE.MappedIndex")
end
ZVM.OpcodeTable[133] = function(self)  --RSTACK
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_EmitOperand("VM:ReadFromStack($2)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[134] = function(self)  --SSTACK
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("VM:WriteToStack($1,$2)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[135] = function(self)  --ENTER
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_EmitForceRegisterLocal("EBP")

  self:Dyn_Emit("VM:Push(EBP)")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("EBP = VM.ESP+1")
  self:Dyn_Emit("VM.ESP = VM.ESP-$1")
end
ZVM.OpcodeTable[136] = function(self)  --IRETP
  self:Dyn_Emit("VM.PTBL = $1")
  self.OpcodeTable[41](self) -- as IRET
end
ZVM.OpcodeTable[137] = function(self)  --EXTRETP
  self:Dyn_Emit("VM.PTBL = $1")
  self.OpcodeTable[110](self) -- as EXTRET
end
ZVM.OpcodeTable[139] = function(self)  --CLD
  if self.MicrocodeDebug then
    self:Dyn_Emit("VM.Debug = false")
  end
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[140] = function(self) --EXTRETA
  self:Dyn_EmitForceRegisterGlobal("ESP")
  self:Dyn_Emit("$L V = 0")
  self:Dyn_EmitState()
 
  self:Dyn_Emit("V = VM:Pop()") -- IRET CS
  self:Dyn_EmitInterruptCheck()
 
  self:Dyn_Emit("V = VM:Pop()") -- IRET EIP
  self:Dyn_EmitInterruptCheck()
 
  for i=0,31 do
    self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.R"..i.." = V")
  end
 
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("$L IP = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.CMPR = V")
 
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.EAX = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.EBX = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.ECX = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.EDX = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.EBP = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() -- Do not set ESP right now
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.ESI = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.EDI = V")
 
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("$L CS = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() -- Do not set SS right now
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.DS = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.FS = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.GS = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.ES = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.KS = V")
  self:Dyn_Emit("V = VM:Pop()") self:Dyn_EmitInterruptCheck() self:Dyn_Emit("VM.LS = V")
  self:Dyn_Emit("VM:Jump(IP,CS)")
 
  self:Dyn_EmitBreak()
  self.PrecompileBreak = true
end
ZVM.OpcodeTable[141] = function(self) --EXTRETPA
  self:Dyn_Emit("VM.PTBL = $1")
  self.OpcodeTable[140](self) -- as EXTRETP
end


--------------------------------------------------------------------------------
ZVM.OpcodeTable[250] = function(self)  --VADD
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x+V2.x, y=V1.y+V2.y, z=0})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x+V2.x, y=V1.y+V2.y, z=V1.z+V2.z})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[251] = function(self)  --VSUB
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x-V2.x, y=V1.y-V2.y, z=0})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x-V2.x, y=V1.y-V2.y, z=V1.z-V2.z})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[252] = function(self)  --VMUL
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = $2")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x*V2, y=V1.y*V2, z=0})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = $2")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.x*V2, y=V1.y*V2, z=V1.z*V2})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[253] = function(self)  --VDOT
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell($1 + VM."..self.EmitOperandSegment[1]..",")
      self:Dyn_Emit("V1.x*V2.x+V1.y*V2.y)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("V1.x*V2.x+V1.y*V2.y+V1.z*V2.z)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[254] = function(self)  --VCROSS
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteCell($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("V1.x*V2.y-V1.y*V2.x)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V1 = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_Emit("$L V2 = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V1.y*V2.z-V1.z*V2.y, y=V1.z*V2.x-V1.x*V2.z, z=V1.x*V2.y-V1.y*V2.x})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[255] = function(self)  --VMOV
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",V)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",V)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[256] = function(self)  --VNORM
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("$L D = (V.x^2+V.y^2)^(1/2)+1e-8")
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V.x/D, y = V.y/D, z = 0})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("$L D = (V.x^2+V.y^2+V.z^2)^(1/2)+1e-8")
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",")
      self:Dyn_Emit("{x = V.x/D, y = V.y/D, z = V.z/D})")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[257] = function(self)  --VCOLORNORM
  self:Dyn_Emit("$L V = VM:ReadVector4f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("V.x = math.min(255,math.max(0,V.x))")
  self:Dyn_Emit("V.y = math.min(255,math.max(0,V.y))")
  self:Dyn_Emit("V.z = math.min(255,math.max(0,V.z))")
  self:Dyn_Emit("V.w = math.min(255,math.max(0,V.w))")
  self:Dyn_Emit("VM:WriteVector4f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",V)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[259] = function(self)  --LOOPXY
  self:Dyn_EmitForceRegisterLocal("ECX")
  self:Dyn_EmitForceRegisterLocal("EDX")

--  self:Dyn_Emit("
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[260] = function(self)  --MADD
  self:Dyn_Emit("$L M1 = VM:ReadMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
  self:Dyn_Emit("$L M2 = VM:ReadMatrix($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L RM = {}")
  self:Dyn_Emit("for i=0,15 do RM[i] = M1[i]+M2[i] end")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[261] = function(self)   --MSUB
  self:Dyn_Emit("$L M1 = VM:ReadMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
  self:Dyn_Emit("$L M2 = VM:ReadMatrix($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L RM = {}")
  self:Dyn_Emit("for i=0,15 do RM[i] = M1[i]-M2[i] end")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[262] = function(self)   --MMUL
  self:Dyn_Emit("$L M1 = VM:ReadMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
  self:Dyn_Emit("$L M2 = VM:ReadMatrix($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L RM = {}")
  self:Dyn_Emit("for i=0,3 do")
    self:Dyn_Emit("for j=0,3 do")
      self:Dyn_Emit("RM[i*4+j] = M1[i*4+0]*M2[0*4+j] +")
      self:Dyn_Emit("            M1[i*4+1]*M2[1*4+j] +")
      self:Dyn_Emit("            M1[i*4+2]*M2[2*4+j] +")
      self:Dyn_Emit("            M1[i*4+3]*M2[3*4+j]")
    self:Dyn_Emit("end")
  self:Dyn_Emit("end")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[263] = function(self)   --MROTATE
  self:Dyn_Emit("$L VEC = VM:ReadVector4f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L MAG = math.sqrt(VEC.x^2+VEC.y^2+VEC.z^2)+1e-7")
  self:Dyn_Emit("VEC.x = VEC.x / MAG")
  self:Dyn_Emit("VEC.y = VEC.y / MAG")
  self:Dyn_Emit("VEC.z = VEC.z / MAG")

  self:Dyn_Emit("$L SIN = math.sin(VEC.w)")
  self:Dyn_Emit("$L COS = math.cos(VEC.w)")

  self:Dyn_Emit("$L ab = VEC.x * VEC.y * (1 - COS)")
  self:Dyn_Emit("$L bc = VEC.y * VEC.z * (1 - COS)")
  self:Dyn_Emit("$L ca = VEC.z * VEC.x * (1 - COS)")
  self:Dyn_Emit("$L tx = VEC.x * VEC.x")
  self:Dyn_Emit("$L ty = VEC.y * VEC.y")
  self:Dyn_Emit("$L tz = VEC.z * VEC.z")

  self:Dyn_Emit("$L RM = {}")
  self:Dyn_Emit("RM[0]  = tx + COS * (1 - tx)")
  self:Dyn_Emit("RM[1]  = ab + VEC.z * SIN")
  self:Dyn_Emit("RM[2]  = ca - VEC.y * SIN")
  self:Dyn_Emit("RM[3]  = 0")
  self:Dyn_Emit("RM[4]  = ab - VEC.z * SIN")
  self:Dyn_Emit("RM[5]  = ty + COS * (1 - ty)")
  self:Dyn_Emit("RM[6]  = bc + VEC.x * SIN")
  self:Dyn_Emit("RM[7]  = 0")
  self:Dyn_Emit("RM[8]  = ca + VEC.y * SIN")
  self:Dyn_Emit("RM[9]  = bc - VEC.x * SIN")
  self:Dyn_Emit("RM[10] = tz + COS * (1 - tz)")
  self:Dyn_Emit("RM[11] = 0")
  self:Dyn_Emit("RM[12] = 0")
  self:Dyn_Emit("RM[13] = 0")
  self:Dyn_Emit("RM[14] = 0")
  self:Dyn_Emit("RM[15] = 1")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[264] = function(self)   --MSCALE
  self:Dyn_Emit("$L VEC = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L RM  = {}")
  self:Dyn_Emit("RM[0]  = VEC.x")
  self:Dyn_Emit("RM[1]  = 0")
  self:Dyn_Emit("RM[2]  = 0")
  self:Dyn_Emit("RM[3]  = 0")

  self:Dyn_Emit("RM[4]  = 0")
  self:Dyn_Emit("RM[5]  = VEC.y")
  self:Dyn_Emit("RM[6]  = 0")
  self:Dyn_Emit("RM[7]  = 0")

  self:Dyn_Emit("RM[8]  = 0")
  self:Dyn_Emit("RM[9]  = 0")
  self:Dyn_Emit("RM[10] = VEC.z")
  self:Dyn_Emit("RM[11] = 0")

  self:Dyn_Emit("RM[12] = 0")
  self:Dyn_Emit("RM[13] = 0")
  self:Dyn_Emit("RM[14] = 0")
  self:Dyn_Emit("RM[15] = 1")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[265] = function(self)   --MPERSPECTIVE
  self:Dyn_Emit("$L VEC = VM:ReadVector4f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L DZ = VEC.w - VEC.z")
  self:Dyn_Emit("$L RADS = (VEC.x / 2.0) * math.pi / 180")
  self:Dyn_Emit("$L SIN = math.sin(RADS)")
  self:Dyn_Emit("$L CTG = math.cos(RADS)/SIN")

  self:Dyn_Emit("$L RM = {}")
  self:Dyn_Emit("RM[0]  = CTG / VEC.y")
  self:Dyn_Emit("RM[4]  = 0")
  self:Dyn_Emit("RM[8]  = 0")
  self:Dyn_Emit("RM[12] = 0")

  self:Dyn_Emit("RM[1]  = 0")
  self:Dyn_Emit("RM[5]  = CTG")
  self:Dyn_Emit("RM[9]  = 0")
  self:Dyn_Emit("RM[13] = 0")

  self:Dyn_Emit("RM[2]  = 0")
  self:Dyn_Emit("RM[6]  = 0")
  self:Dyn_Emit("RM[10] = -(VEC.z + VEC.w) / DZ")
  self:Dyn_Emit("RM[14] = -2*VEC.z*VEC.w / DZ")

  self:Dyn_Emit("RM[3]  = 0")
  self:Dyn_Emit("RM[7]  = 0")
  self:Dyn_Emit("RM[11] = -1")
  self:Dyn_Emit("RM[15] = 0")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[266] = function(self)   --MTRANSLATE
  self:Dyn_Emit("$L VEC = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L RM  = {}")
  self:Dyn_Emit("RM[0]  = 1")
  self:Dyn_Emit("RM[1]  = 0")
  self:Dyn_Emit("RM[2]  = 0")
  self:Dyn_Emit("RM[3]  = VEC.x")

  self:Dyn_Emit("RM[4]  = 0")
  self:Dyn_Emit("RM[5]  = 1")
  self:Dyn_Emit("RM[6]  = 0")
  self:Dyn_Emit("RM[7]  = VEC.y")

  self:Dyn_Emit("RM[8]  = 0")
  self:Dyn_Emit("RM[9]  = 0")
  self:Dyn_Emit("RM[10] = 1")
  self:Dyn_Emit("RM[11] = VEC.z")

  self:Dyn_Emit("RM[12] = 0")
  self:Dyn_Emit("RM[13] = 0")
  self:Dyn_Emit("RM[14] = 0")
  self:Dyn_Emit("RM[15] = 1")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[267] = function(self)   --MLOOKAT
  self:Dyn_Emit("$L EYE    = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS").."+0)")
  self:Dyn_Emit("$L CENTER = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS").."+3)")
  self:Dyn_Emit("$L UP     = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS").."+6)")
  self:Dyn_EmitInterruptCheck()

  self:Dyn_Emit("$L X = { 0, 0, 0 }")
  self:Dyn_Emit("$L Y = { UP.x, UP.y, UP.z }")
  self:Dyn_Emit("$L Z = { EYE.x - CENTER.x, EYE.y - CENTER.y, EYE.z - CENTER.z }")

  self:Dyn_Emit("$L ZMAG = math.sqrt(Z[1]^2+Z[2]^2+Z[3]^2)+1e-7")
  self:Dyn_Emit("Z[1] = Z[1] / ZMAG")
  self:Dyn_Emit("Z[2] = Z[2] / ZMAG")
  self:Dyn_Emit("Z[3] = Z[3] / ZMAG")

  self:Dyn_Emit("X[1] =  Y[2]*Z[3] - Y[3]*Z[2]")
  self:Dyn_Emit("X[2] = -Y[1]*Z[3] + Y[3]*Z[1]")
  self:Dyn_Emit("X[3] =  Y[1]*Z[2] - Y[2]*Z[1]")

  self:Dyn_Emit("Y[1] =  Z[2]*X[3] - Z[3]*X[2]")
  self:Dyn_Emit("Y[2] = -Z[1]*X[3] + Z[3]*X[1]")
  self:Dyn_Emit("Y[3] =  Z[1]*X[2] - Z[2]*X[1]")

  self:Dyn_Emit("$L XMAG = math.sqrt(X[1]^2+X[2]^2+X[3]^2)+1e-7")
  self:Dyn_Emit("X[1] = X[1] / XMAG")
  self:Dyn_Emit("X[2] = X[2] / XMAG")
  self:Dyn_Emit("X[3] = X[3] / XMAG")

  self:Dyn_Emit("$L YMAG = math.sqrt(Y[1]^2+Y[2]^2+Y[3]^2)+1e-7")
  self:Dyn_Emit("Y[1] = Y[1] / YMAG")
  self:Dyn_Emit("Y[2] = Y[2] / YMAG")
  self:Dyn_Emit("Y[3] = Y[3] / YMAG")

  self:Dyn_Emit("$L RM  = {}")
  self:Dyn_Emit("RM[0]  = X[1]")
  self:Dyn_Emit("RM[1]  = X[2]")
  self:Dyn_Emit("RM[2]  = X[3]")
  self:Dyn_Emit("RM[3]  = -X[1]*EYE.x + -X[2]*EYE.y + -X[3]*EYE.z")

  self:Dyn_Emit("RM[4]  = Y[1]")
  self:Dyn_Emit("RM[5]  = Y[2]")
  self:Dyn_Emit("RM[6]  = Y[3]")
  self:Dyn_Emit("RM[7]  = -Y[1]*EYE.x + -Y[2]*EYE.y + -Y[3]*EYE.z")

  self:Dyn_Emit("RM[8]  = Z[1]")
  self:Dyn_Emit("RM[9]  = Z[2]")
  self:Dyn_Emit("RM[10] = Z[3]")
  self:Dyn_Emit("RM[11] = -Z[1]*EYE.x + -Z[2]*EYE.y + -Z[3]*EYE.z")

  self:Dyn_Emit("RM[12] = 0")
  self:Dyn_Emit("RM[13] = 0")
  self:Dyn_Emit("RM[14] = 0")
  self:Dyn_Emit("RM[15] = 1")

  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",RM)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[268] = function(self)   --MMOV
  self:Dyn_Emit("$L M = VM:ReadMatrix($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
  self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",M)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[269] = function(self)   --VLEN
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V = VM:ReadVector2f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_EmitOperand(1,"(V.x^2+V.y^2)^0.5",true)
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V = VM:ReadVector3f($2 + VM."..(self.EmitOperandSegment[2] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_EmitOperand(1,"(V.x^2+V.y^2+V.z^2)^0.5",true)
  self:Dyn_Emit("end")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[270] = function(self)   --MIDENT
  self:Dyn_Emit("$L M = {}")
  self:Dyn_Emit("M[ 0]=1  M[ 1]=0  M[ 2]=0  M[ 3]=0")
  self:Dyn_Emit("M[ 4]=0  M[ 5]=1  M[ 6]=0  M[ 7]=0")
  self:Dyn_Emit("M[ 8]=0  M[ 9]=0  M[10]=1  M[11]=0")
  self:Dyn_Emit("M[12]=0  M[13]=0  M[14]=0  M[15]=1")
  self:Dyn_Emit("VM:WriteMatrix($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",M)")
  self:Dyn_EmitInterruptCheck()
end
ZVM.OpcodeTable[273] = function(self)   --VMODE
  self:Dyn_Emit("VM.VMODE = $1")
end
--------------------------------------------------------------------------------
ZVM.OpcodeTable[295] = function(self)  --VDIV
  self:Dyn_Emit("$L SCALAR = $2")
  self:Dyn_Emit("if VM.VMODE == 2 then")
    self:Dyn_Emit("$L V = VM:ReadVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("V.x = V.x / SCALAR")
    self:Dyn_Emit("V.y = V.y / SCALAR")
    self:Dyn_Emit("VM:WriteVector2f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",V)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("elseif VM.VMODE == 3 then")
    self:Dyn_Emit("$L V = VM:ReadVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..")")
    self:Dyn_EmitInterruptCheck()
    self:Dyn_Emit("V.x = V.x / SCALAR")
    self:Dyn_Emit("V.y = V.y / SCALAR")
    self:Dyn_Emit("V.z = V.z / SCALAR")
    self:Dyn_Emit("VM:WriteVector3f($1 + VM."..(self.EmitOperandSegment[1] or "DS")..",V)")
    self:Dyn_EmitInterruptCheck()
  self:Dyn_Emit("end")
end
ZVM.OpcodeTable[296] = function(self)  --VTRANSFORM
--[[  if (self.VMODE == 2) then
    local vec = self:Read2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
    local mx = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])

    local tmp = {}
    for i=0,3 do
      tmp[i] = mx[i*4+0] * vec.x +
         mx[i*4+1] * vec.y +
         mx[i*4+2] * 0 +
         mx[i*4+3] * 1
    end


    self:Write2f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
      {x = tmp[0], y = tmp[1], z = 0})
  else
    local vec = self:Read3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1])
    local mx = self:ReadMatrix(Param2 + self[self.PrecompileData[self.XEIP].Segment2])

    local tmp = {}
    for i=0,3 do
      tmp[i] = mx[i*4+0] * vec.x +
         mx[i*4+1] * vec.y +
         mx[i*4+2] * vec.z +
         mx[i*4+3] * 1
    end


    self:Write3f(Param1 + self[self.PrecompileData[self.XEIP].Segment1],
      {x = tmp[0], y = tmp[1], z = tmp[2]})
  end ]]--
end
