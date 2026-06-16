local Test = {}


-- This is a real ZCPU program written in HLZASM syntax that compiles human readable code to ZASM bytecode.
-- Uses multiple lookup tables including alphabetical sorting to reduce search time for name => instruction.
--
-- Written by Huh in the Wiremod Discord
Test.Files = {
	["assembler.txt"] = [[
#pragma CRT ZCRT
#define inst_lookup_K 0
#define inst_lookup_U 0
#define inst_lookup_V 0
#define inst_lookup_Y 0
#define inst_lookup_Z 0

void main() {
	char textToAssemble = "MOV EAX, EBX"
	float start
	float end
	timer start
	assemble(textToAssemble, ASMOutput)
	timer end
	port0 = end - start
} 

void assemble(char asm, float output) {
	char word = asm
	float k = 0
	while(word[0]) {
		word = getNextWord(asm)
		float inst = isInstruction(asm)
		asm = word + 1
		if(inst[0] == 999) {
			asm = handleDB(asm, &k, output)
			word = asm
			continue
		}
		float reg
		float i = inst[inst[1] + 3]
		float ic = i
		float rm1 = 0
		float rm2 = 0
		float v
		output[k++] = inst[0]
		while(i) {
			word = getNextWord(asm)
			reg = isRegister(asm)
			if(i == 2) {
				if(reg) {
					rm1 = reg[0]
				} else if(asm[0] == 35) {
					reg = isRegister(asm + 1)
					rm1 = reg[0] + 16
					//k++
				}
				//k++
				asm = word + 2
			} else {
				v = k
				if(reg) {
					rm2 = reg[0]
				} else if(asm[0] == 35) {
					reg = isRegister(asm + 1)
					rm2 = reg[0] + 16
					//k++
				} else {
					rm2 = 0
					output[++k] = atof(asm)
				}
				if(ic == 1) {
					rm1 = rm2
					rm2 = 0
				}
				output[v] = rm1 + (10000 * rm2)
				k++
				asm = word + 1
			}
			i--
		}
	}
	//port0 = word[0]
}

float atof(char str) {
	zap R0 R1 R2 R3 R4
	register float res = 0;
	register float i;
	register float cur = str[0]
	for (i = 0; cur && (cur != 32) && (cur != 44) && (cur != 46); i++) {
		res = res * 10 + cur - '0';
		cur = str[i + 1]
	}
	if(str[i] == 46) {
		register float res2 = 0
		register float k = 0
		register float p = 10
		cur = str[++i]
		for (i = i; cur && (cur != 32) && (cur != 44); ++i) {
			res2 = res2 * 10 + cur - '0';
			k++
			cur = str[i]
		}
		FPWR p, k
		res += res2 / p
	}
	return res;
}

char getNextWord(char asm) {
	register float i = 0
	register float cur = asm[i]
	while(cur && (cur != 32) && (cur != 44)) {
		i++
		cur = asm[i]
	}
	return i + asm
}

char handleDB(char asm, float* k, char output) {
	float i = 0
	float p = asm
	while(p[0] && (p[0] != 32)) {
		p = getNextWord(asm)
		output[k[0] + i] = atof(asm)
		asm = p + 1
		i++
	}
	k[0] += i
	if(p[0]) {
		p++
	}
	return p
}

float isRegister(char* x) {
	//preserve ECX
	zap R0 R1 R2 R3 R4 R5
	register float i = 0;
	register float k = 0;
	while(i < 20) {
		register float y = 0;
		register float v = 0;
		register char cur = x[v];
		while(cur && (cur != 32) && (cur != 44)) {
			if(cur == registers[k + 2 + v]) {
				y++
			} else {
				y--
			}
			v++
			cur = x[v];
		}
		if(y == registers[k + 1]) {
			break
		}
		k += registers[k + 1] + 3
		i++
	}
	
	if(i == 20) {
		return 0
	} else {
		return k + registers
	}
}

float isInstruction(char* x) {
	//preserve ECX
	zap R0 R1 R2 R3 R4 R5
	register float i = 0;
	register float k = 0;
	register float lookup = x[0] - 65 + optable
	lookup = lookup[0]
	register float maxItems = lookup[0]
	maxItems++
	lookup++
	while(i < maxItems) {
		register float y = 0;
		register float v = 0;
		register char cur = x[v];
		while(cur && (cur != 32) && (cur != 44)) {
			if(cur == lookup[k + 2 + v]) {
				y++
			} else {
				y--
			}
			v++
			cur = x[v];
		}
		if(y == lookup[k + 1]) {
			break
		}
		k += lookup[k + 1] + 4
		i++
	}
	
	if(i == maxItems) {
		return 0
	} else {
		return k + lookup
	}
}

registers: // 1: Opcode, 2: Register name length, 3: Register name
DB 1, 3, "EAX",0
DB 2, 3, "EBX",0
DB 3, 3, "ECX",0
DB 4, 3, "EDX",0
DB 5, 3, "ESI",0
DB 6, 3, "EDI",0
DB 7, 3, "ESP",0
DB 8, 3, "EBP",0
DB 9, 2, "CS",0
DB 10, 2, "SS",0
DB 11, 2, "DS",0
DB 12, 2, "ES",0
DB 13, 2, "GS",0
DB 14, 2, "FS",0
DB 15, 2, "KS",0
DB 16, 2, "LS",0
DB 1000, 5, "PORT0",0
DB 1001, 5, "PORT1",0
DB 1002, 5, "PORT2",0
DB 1003, 5, "PORT3",0

optable:
DB 
inst_lookup_A,
inst_lookup_B,
inst_lookup_C,
inst_lookup_D,
inst_lookup_E,
inst_lookup_F,
inst_lookup_G,
inst_lookup_H,
inst_lookup_I,
inst_lookup_J,
inst_lookup_K,
inst_lookup_L,
inst_lookup_M,
inst_lookup_N,
inst_lookup_O,
inst_lookup_P,
inst_lookup_Q,
inst_lookup_R,
inst_lookup_S,
inst_lookup_T,
inst_lookup_U,
inst_lookup_V,
inst_lookup_W,
inst_lookup_X,
inst_lookup_Y,
inst_lookup_Z
inst_lookup_A:
db 2
db 10, 3, "ADD",0, 2
db 50, 3, "AND",0, 2
inst_lookup_B:
db 8
db 32, 4, "BNOT",0, 1
db 60, 3, "BIT",0, 2
db 64, 4, "BAND",0, 2
db 65, 3, "BOR",0, 2
db 66, 4, "BXOR",0, 2
db 67, 4, "BSHL",0, 2
db 68, 4, "BSHR",0, 2
db 127, 5, "BLOCK",0, 2
inst_lookup_C:
db 28
db 8, 5, "CPUID",0, 1
db 15, 3, "CMP",0, 2
db 29, 3, "CPG",0, 1
db 31, 4, "CALL",0, 1
db 43, 3, "CLI",0, 0
db 45, 3, "CLP",0, 0
db 49, 4, "CLEF",0, 0
db 62, 4, "CBIT",0, 2
db 71, 3, "CNE",0, 1
db 71, 3, "CNZ",0, 1
db 73, 2, "CG",0, 1
db 73, 4, "CNLE",0, 1
db 74, 3, "CGE",0, 1
db 74, 3, "CNL",0, 1
db 75, 2, "CL",0, 1
db 75, 4, "CNGE",0, 1
db 76, 3, "CLE",0, 1
db 76, 3, "CNG",0, 1
db 77, 2, "CE",0, 1
db 77, 2, "CZ",0, 1
db 89, 5, "CALLF",0, 2
db 119, 3, "CLM",0, 0
db 120, 6, "CPUGET",0, 2
db 121, 6, "CPUSET",0, 2
db 123, 3, "CPP",0, 2
db 125, 3, "CRL",0, 2
db 128, 6, "CMPAND",0, 2
db 129, 5, "CMPOR",0, 2
db 151, 5, "CLERR",0, 0
inst_lookup_D:
db 2
db 13, 3, "DIV",0, 2
db 21, 3, "DEC",0, 1
db 999, 2, "DB",0, 0
inst_lookup_E:
db 7
db 70, 6, "EXTINT",0, 1
db 95, 4, "ERPG",0, 1
db 110, 6, "EXTRET",0, 0
db 135, 5, "ENTER",0, 1
db 137, 7, "EXTRETP",0, 1
db 140, 7, "EXTRETA",0, 0
db 141, 8, "EXTRETPA",0, 1
inst_lookup_F:
db 21
db 33, 4, "FINT",0, 1
db 34, 4, "FRND",0, 1
db 35, 5, "FFRAC",0, 1
db 36, 4, "FINV",0, 1
db 38, 4, "FSHL",0, 1
db 39, 4, "FSHR",0, 1
db 53, 4, "FSIN",0, 2
db 54, 4, "FCOS",0, 2
db 55, 4, "FTAN",0, 2
db 56, 5, "FASIN",0, 2
db 57, 5, "FACOS",0, 2
db 58, 5, "FATAN",0, 2
db 80, 4, "FPWR",0, 2
db 82, 4, "FLOG",0, 2
db 82, 3, "FLN",0, 2
db 83, 6, "FLOG10",0, 2
db 86, 4, "FABS",0, 2
db 87, 4, "FSGN",0, 2
db 88, 4, "FEXP",0, 2
db 90, 3, "FPI",0, 1
db 91, 2, "FE",0, 1
db 94, 5, "FCEIL",0, 1
inst_lookup_G:
db 1
db 132, 4, "GMAP",0, 2
inst_lookup_H:
db 1
db 37, 4, "HALT",0, 1
inst_lookup_I:
db 6
db 20, 3, "INC",0, 1
db 41, 4, "IRET",0, 0
db 84, 2, "IN",0, 2
db 92, 3, "INT",0, 1
db 111, 4, "IDLE",0, 0
db 136, 5, "IRETP",0, 1
inst_lookup_J:
db 26
db 1, 3, "JNE",0, 1
db 1, 3, "JNZ",0, 1
db 2, 3, "JMP",0, 1
db 3, 2, "JG",0, 1
db 3, 4, "JNLE",0, 1
db 4, 3, "JGE",0, 1
db 4, 3, "JNL",0, 1
db 5, 2, "JL",0, 1
db 5, 4, "JNGE",0, 1
db 6, 3, "JLE",0, 1
db 6, 3, "JNG",0, 1
db 7, 2, "JE",0, 1
db 7, 2, "JZ",0, 1
db 69, 4, "JMPF",0, 2
db 101, 4, "JNER",0, 1
db 101, 4, "JNZR",0, 1
db 102, 4, "JMPR",0, 1
db 103, 3, "JGR",0, 1
db 103, 5, "JNLER",0, 1
db 104, 4, "JGER",0, 1
db 104, 4, "JNLR",0, 1
db 105, 3, "JLR",0, 1
db 105, 5, "JNGER",0, 1
db 106, 4, "JLER",0, 1
db 106, 4, "JNGR",0, 1
db 107, 3, "JER",0, 1
db 107, 3, "JZR",0, 1
inst_lookup_L:
db 13
db 24, 4, "LOOP",0, 1
db 24, 5, "LOOPC",0, 1
db 25, 5, "LOOPA",0, 1
db 26, 5, "LOOPB",0, 1
db 27, 5, "LOOPD",0, 1
db 50, 4, "LAND",0, 2
db 51, 3, "LOR",0, 2
db 52, 4, "LXOR",0, 2
db 99, 5, "LIDTR",0, 1
db 108, 4, "LNEG",0, 1
db 108, 4, "LNOT",0, 1
db 117, 5, "LEAVE",0, 0
db 126, 3, "LEA",0, 2
inst_lookup_M:
db 8
db 12, 3, "MUL",0, 2
db 14, 3, "MOV",0, 2
db 18, 3, "MIN",0, 2
db 19, 3, "MAX",0, 2
db 59, 3, "MOD",0, 2
db 78, 5, "MCOPY",0, 1
db 79, 5, "MXCHG",0, 1
db 130, 6, "MSHIFT",0, 2
inst_lookup_N:
db 4
db 22, 3, "NEG",0, 1
db 70, 6, "NMIINT",0, 1
db 110, 6, "NMIRET",0, 0
db 112, 3, "NOP",0, 0
inst_lookup_O:
db 2
db 51, 2, "OR",0, 2
db 85, 3, "OUT",0, 2
inst_lookup_P:
db 4
db 9, 4, "PUSH",0, 1
db 30, 3, "POP",0, 1
db 114, 5, "PUSHA",0, 0
db 115, 4, "POPA",0, 0
inst_lookup_Q:
db 2
db 152, 6, "QUOCMP",0, 0
db 153, 8, "QUOTIMER",0, 1
inst_lookup_R:
db 12
db 0, 8, "RESERVED",0, 0
db 16, 2, "RD",0, 2
db 23, 4, "RAND",0, 1
db 34, 3, "RND",0, 1
db 40, 3, "RET",0, 0
db 46, 8, "RESERVED",0, 0
db 47, 4, "RETF",0, 0
db 72, 8, "RESERVED",0, 1
db 97, 4, "RDPG",0, 1
db 100, 8, "RESERVED",0, 1
db 109, 8, "RESERVED",0, 1
db 113, 8, "RESERVED",0, 0
db 133, 6, "RSTACK",0, 2
inst_lookup_S:
db 12
db 11, 3, "SUB",0, 2
db 28, 3, "SPG",0, 1
db 42, 3, "STI",0, 0
db 44, 3, "STP",0, 0
db 48, 4, "STEF",0, 0
db 61, 4, "SBIT",0, 2
db 116, 4, "STD2",0, 0
db 118, 3, "STM",0, 0
db 122, 3, "SPP",0, 2
db 124, 3, "SRL",0, 2
db 131, 4, "SMAP",0, 2
db 134, 6, "SSTACK",0, 2
db 150, 5, "STERR",0, 2
inst_lookup_T:
db 3
db 63, 4, "TBIT",0, 2
db 93, 3, "TPG",0, 1
db 98, 5, "TIMER",0, 1
inst_lookup_W:
db 2
db 17, 2, "WD",0, 2
db 96, 4, "WRPG",0, 1
inst_lookup_X:
db 2
db 52, 3, "XOR",0, 2
db 81, 4, "XCHG",0, 2

ASMOutput:
]]
}

function Test.Run(CPU,TestSuite)
	CPU.RAMSize = 131072
	CPU.ROMSize = 131072
	CPU.Frequency = 1e6
	TestSuite:Deploy(CPU,TestSuite:LoadFile("assembler.txt"),Test.CompileError)
	CPU.Clk = 1
	for i = 0, 65536 do
		CPU:RunStep()
	end
	-- On false, will cause test to fail with message
	-- Expecting LINT 1 aka HLZASM main returned.
	assert(not CPU.VMStopped or CPU.LINT == 1,"VM Stopped at end of execution, likely an unhandled interrupt caused an error. LINT = "..CPU.LINT.." LADD ="..CPU.LADD)
end

function Test.CompileError(msg)
	assert(false,"compile time error: " .. msg)
end

return Test