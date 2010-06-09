local opcodes = {}
opcodes["jne"]    = 1   //JNE X      : IP = X, IF CMPR ~= 0
opcodes["jnz"]    = 1   //JNZ X      : IP = X, IF CMPR ~= 0
opcodes["jmp"]    = 2   //JMP X      : IP = X
opcodes["jg"]     = 3   //JG X       : IP = X, IF CMPR > 0
opcodes["jnle"]   = 3   //JNLE X     : IP = X, IF !(CMPR <= 0)
opcodes["jge"]    = 4   //JGE X      : IP = X, IF CMPR >= 0
opcodes["jnl"]    = 4   //JNL X      : IP = X, IF !(CMPR < 0)
opcodes["jl"]     = 5   //JL X       : IP = X, IF CMPR < 0
opcodes["jnge"]   = 5   //JNGE X     : IP = X, IF !(CMPR >= 0)
opcodes["jle"]    = 6   //JLE X      : IP = X, IF CMPR <= 0
opcodes["jng"]    = 6   //JNG X      : IP = X, IF !(CMPR > 0)
opcodes["je"]     = 7   //JE X       : IP = X, IF CMPR = 0
opcodes["jz"]     = 7   //JZ X       : IP = X, IF CMPR = 0
opcodes["cpuid"]  = 8   //CPUID X    : EAX -> CPUID[X]
opcodes["push"]   = 9   //PUSH X     : WRITE(ESP+SS,X); ESP = ESP - 1
opcodes["add"]    = 10  //ADD X,Y    : X = X + Y
opcodes["sub"]    = 11  //SUB X,Y    : X = X - Y
opcodes["mul"]    = 12  //MUL X,Y    : X = X * Y
opcodes["div"]    = 13  //DIV X,Y    : X = X / Y
opcodes["mov"]    = 14  //MOV X,Y    : X = y
opcodes["cmp"]    = 15  //CMP X,Y    : CMPR = X - Y
opcodes["rd"]     = 16  //RD X,Y     : X = MEMORY[Y]
opcodes["wd"]     = 17  //WD X,Y     : MEMORY[X] = Y
opcodes["min"]    = 18  //MIN X,Y    : MIN(X,Y)
opcodes["max"]    = 19  //MAX X,Y    : MAX(X,Y)
opcodes["inc"]    = 20  //INC X      : X = X + 1
opcodes["dec"]    = 21  //DEC X      : X = X - 1
opcodes["neg"]    = 22  //NEG X      : X = -X
opcodes["rand"]   = 23  //RAND X     : X = Random(0..1)
opcodes["loop"]   = 24  //LOOP X     : IF ECX ~= 0 THEN JUMP X    	2.00
opcodes["loopa"]  = 25  //LOOPA X    : IF EAX ~= 0 THEN JUMP X    	2.00
opcodes["loopb"]  = 26  //LOOPB X    : IF EBX ~= 0 THEN JUMP X    	2.00
opcodes["loopd"]  = 27  //LOOPD X    : IF EDX ~= 0 THEN JUMP X    	2.00
opcodes["spg"]    = 28  //SPG X      : PAGE(X) = READ ONLY	    	2.00
opcodes["cpg"]    = 29  //CPG X      : PAGE(X) = READ AND WRITE   	2.00
opcodes["pop"]    = 30  //POP X      : X = READ(ESP+SS); ESP = ESP + 1
opcodes["call"]   = 31  //CALL X     : IP -> STACK; IP = X
opcodes["bnot"]   = 32  //BNOT X     : X = BINARY NOT X
opcodes["fint"]   = 33  //FINT X     : X = FLOOR(X)
opcodes["frnd"]   = 34  //FRND X     : X = ROUND(X)
opcodes["ffrac"]  = 35  //FFRAC X    : X = X - FLOOR(X)
opcodes["finv"]   = 36  //FINV X     : X = 1 / X
opcodes["halt"]   = 37  //HALT X     : HALT UNTIL PORT[X]
opcodes["fshl"]   = 38  //FSHL X     : X = X * 2		   	2.00
opcodes["fshr"]   = 39  //FSHR X     : X = X / 2		   	2.00
opcodes["ret"]    = 40  //RET        : IP <- STACK
opcodes["iret"]   = 41  //IRET       : IP <- STACK 		   	2.00
opcodes["sti"]    = 42  //STI        : IF = TRUE		   	2.00
opcodes["cli"]    = 43  //CLI        : IF = FALSE		   	2.00
opcodes["stp"]    = 44  //STP        : PF = TRUE		   	2.00
opcodes["clp"]    = 45  //CLP        : PF = FALSE		   	2.00
opcodes["retf"]   = 47  //RETF       : IP,CS <- STACK		   	2.00
opcodes["stef"]   = 48  //STEF       : EF = TRUE		   	4.00
opcodes["clef"]   = 49  //CLEF       : EF = FALSE		   	4.00
opcodes["and"]    = 50  //FAND X,Y   : X = X AND Y
opcodes["or"]     = 51  //FOR X,Y    : X = X OR Y
opcodes["xor"]    = 52  //FXOR X,Y   : X = X XOR Y
opcodes["fsin"]   = 53  //FSIN X,Y   : X = SIN Y
opcodes["fcos"]   = 54  //FCOS X,Y   : X = COS Y
opcodes["ftan"]   = 55  //FTAN X,Y   : X = TAN Y
opcodes["fasin"]  = 56  //FASIN X,Y  : X = ASIN Y
opcodes["facos"]  = 57  //FACOS X,Y  : X = ACOS Y
opcodes["fatan"]  = 58  //FATAN X,Y  : X = ATAN Y
opcodes["mod"]    = 59  //MOD X,Y    : X = X MOD Y		   	2.00
opcodes["bit"]    = 60  //BIT X,Y    : CMPR = BIT(X,Y)	   	2.00
opcodes["sbit"]   = 61  //SBIT X,Y   : BIT(X,Y) = 1		   	2.00
opcodes["cbit"]   = 62  //CBIT X,Y   : BIT(X,Y) = 0		   	2.00
opcodes["tbit"]   = 63  //TBIT X,Y   : BIT(X,Y) = ~BIT(X,Y)	   	2.00
opcodes["band"]   = 64  //BAND X,Y   : X = X BAND Y		   	2.00
opcodes["bor"]    = 65  //BOR X,Y    : X = X BOR Y		   	2.00
opcodes["bxor"]   = 66  //BXOR X,Y   : X = X BXOR Y		   	2.00
opcodes["bshl"]   = 67  //BSHL X,Y   : X = X BSHL Y		   	2.00
opcodes["bshr"]   = 68  //BSHR X,Y   : X = X BSHR Y		   	2.00
opcodes["jmpf"]   = 69  //JMPF X,Y   : CS = Y; IP = X		   	2.00
opcodes["nmiint"] = 70  //NMIINT X   : NMIINTERRUPT(X);	   	4.00
opcodes["cne"]    = 71  //CNE X      : CALL(X), IF CMPR ~= 0	   	2.00
opcodes["cnz"]    = 71  //CNZ X      : CALL(X), IF CMPR ~= 0	   	2.00
opcodes["cg"]     = 73  //CG X       : CALL(X), IF CMPR > 0	   	2.00
opcodes["cnle"]   = 73  //CNLE X     : CALL(X), IF !(CMPR <= 0)  	2.00
opcodes["cge"]    = 74  //CGE X      : CALL(X), IF CMPR >= 0	   	2.00
opcodes["cnl"]    = 74  //CNL X      : CALL(X), IF !(CMPR < 0)   	2.00
opcodes["cl"]     = 75  //CL X       : CALL(X), IF CMPR < 0	   	2.00
opcodes["cnge"]   = 75  //CNGE X     : CALL(X), IF !(CMPR >= 0)  	2.00
opcodes["cle"]    = 76  //CLE X      : CALL(X), IF CMPR <= 0	   	2.00
opcodes["cng"]    = 76  //CNG X      : CALL(X), IF !(CMPR > 0)   	2.00
opcodes["ce"]     = 77  //CE X       : CALL(X), IF CMPR = 0	   	2.00
opcodes["cz"]     = 77  //CZ X       : CALL(X), IF CMPR = 0	   	2.00
opcodes["mcopy"]  = 78  //MCOPY X    : X BYTES(ESI) -> EDI	   	2.00
opcodes["mxchg"]  = 79  //MXCHG X    : X BYTES(ESI) <> EDI	   	2.00
opcodes["fpwr"]   = 80  //FPWR X,Y   : X = X ^ Y		   	2.00
opcodes["xchg"]   = 81  //XCHG X,Y   : X,Y = Y,X		   	2.00
opcodes["flog"]   = 82  //FLOG X,Y   : X = LOG(Y)		   	2.00
opcodes["flog10"] = 83  //FLOG10 X,Y : X = LOG10(Y)		   	2.00
opcodes["in"]     = 84  //IN X,Y     : X = PORT[Y]		   	2.00
opcodes["out"]    = 85  //OUT X,Y    : PORT[X] = Y		   	2.00
opcodes["fabs"]   = 86  //FABS X,Y   : X = ABS(Y)		   	2.00
opcodes["fsgn"]   = 87  //FSGN X,Y   : X = SIGN(Y)		   	2.00
opcodes["fexp"]   = 88  //FEXP X,Y   : X = EXP(Y)		   	2.00
opcodes["callf"]  = 89  //CALLF X,Y  : CS = Y; CALL(X)	   	2.00
opcodes["fpi"]    = 90  //FPI X      : X = PI			   	2.00
opcodes["fe"]     = 91  //FE X       : X = E			   	2.00
opcodes["int"]    = 92  //INT X      : INTERRUPT(X)		   	2.00
opcodes["tpg"]    = 93  //TPG X      : CMPR = 1 IF PAGE READS, ELSE 0	2.00
opcodes["fceil"]  = 94  //FCEIL X    : X = CEIL(X)		   	2.00
opcodes["erpg"]   = 95  //ERPG X     : ERASE ROM PAGE(X)	   	2.00
opcodes["wrpg"]   = 96  //WRPG X     : WRITE ROM PAGE(X)	   	2.00
opcodes["rdpg"]   = 97  //RDPG X     : READ ROM PAGE(X)	   	2.00
opcodes["timer"]  = 98  //TIMER X    : X = TIMER		   	2.00
opcodes["lidtr"]  = 99  //LIDTR X    : IDTR = X		   	2.00
opcodes["jner"]   = 101 //JNER X     : IP = IP+X, IF CMPR ~= 0
opcodes["jnzr"]   = 101 //JNZR X     : IP = IP+X, IF CMPR ~= 0
opcodes["jmpr"]   = 102 //JMPR X     : IP = IP+X
opcodes["jgr"]    = 103 //JGR X      : IP = IP+X, IF CMPR > 0
opcodes["jnler"]  = 103 //JNLER X    : IP = IP+X, IF !(CMPR <= 0)
opcodes["jger"]   = 104 //JGER X     : IP = IP+X, IF CMPR >= 0
opcodes["jnlr"]   = 104 //JNLR X     : IP = IP+X, IF !(CMPR < 0)
opcodes["jlr"]    = 105 //JLR X      : IP = IP+X, IF CMPR < 0
opcodes["jnger"]  = 105 //JNGER X    : IP = IP+X, IF !(CMPR >= 0)
opcodes["jler"]   = 106 //JLER X     : IP = IP+X, IF CMPR <= 0
opcodes["jngr"]   = 106 //JNGR X     : IP = IP+X, IF !(CMPR > 0)
opcodes["jer"]    = 107 //JER X      : IP = IP+X, IF CMPR = 0
opcodes["jzr"]    = 107 //JZR X      : IP = IP+X, IF CMPR = 0
opcodes["lneg"]   = 108 //LNEG X     : X = LOGic NEGATE(X)	   	3.00
opcodes["nmiret"] = 110 //NMIRET     : NMIRESTORE;		   	2.00
opcodes["idle"]   = 111 //IDLE       : FORCE_CPU_IDLE;	   	4.00
opcodes["nop"]    = 112 //NOP        : <does nothing>		   	5.00
opcodes["cpuget"] = 120 //CPUGET X,Y : X = CPU[Y]		   	5.00
opcodes["cpuset"] = 121 //CPUSET X,Y : CPU[X] = Y		   	5.00
opcodes["spp"]    = 122 //SPP X,Y    : PAGE[X].Y = 1		   	5.00 [BLOCK]
opcodes["cpp"]    = 123 //CPP X,Y    : PAGE[X].Y = 0		   	5.00 [BLOCK]
opcodes["srl"]    = 124 //SRL X,Y    : PAGE[X].RunLevel = Y	   	5.00 [BLOCK]
opcodes["grl"]    = 125 //GRL X,Y    : X = PAGE[Y].RunLevel	   	5.00
opcodes["lea"]    = 126 //LEA X,Y    : X = ADDRESS(Y)		   	5.00
opcodes["block"]  = 127 //BLOCK X,Y  : SETUP_DATA_BLOCK([X..X+Y-1])	6.00
opcodes["cmpand"] = 128 //CMPAND X,Y : CMPR = CMPR AND (X - Y)   	6.00
opcodes["cmpor"]  = 129 //CMPOR X,Y  : CMPR = CMPR OR (X - Y)    	6.00
opcodes["mshift"] = 130 //MSHIFT X   : SHIFT DATA (look in lua)	7.00
opcodes["smap"]   = 131 //SMAP X,Y   : PAGE[X].MappedTo = Y	   	8.00 [BLOCK]
opcodes["gmap"]   = 132 //GMAP X,Y   : X = PAGE[Y].MappedTo		8.00

local gpuopcodes = {}
gpuopcodes["drect_test"]     = 200 //DRECT_TEST		: Draw retarded stuff
gpuopcodes["dexit"]          = 201 //DEXIT		: End current frame execution
gpuopcodes["dclr"]           = 202 //DCLR		: Clear screen color to black
gpuopcodes["dclrtex"]        = 203 //DCLRTEX		: Clear background with texture
gpuopcodes["dvxflush"]       = 204 //DVXFLUSH		: Flush current vertex buffer to screen
gpuopcodes["dvxclear"]       = 205 //DVXCLEAR		: Clear vertex buffer
gpuopcodes["derrorexit"]     = 206 //DERROREXIT		: Exit error handler
gpuopcodes["dsetbuf_spr"]    = 207 //DSETBUF_SPR		: Set frame buffer to sprite buffer
gpuopcodes["dsetbuf_fbo"]    = 208 //DSETBUF_FBO		: Set frame buffer to view buffer
gpuopcodes["dbindbuf_spr"]   = 209 //DBINDBUF_SPR	: Bind sprite buffer as texture
gpuopcodes["dvxpipe"]        = 210 //DVXPIPE X		: Vertex pipe = X					[INT]
gpuopcodes["dcvxpipe"]       = 211 //DCVXPIPE X		: Coordinate vertex pipe = X				[INT]
gpuopcodes["denable"]        = 212 //DENABLE X		: Enable parameter X					[INT]
gpuopcodes["ddisable"]       = 213 //DDISABLE X		: Disable parameter X					[INT]
gpuopcodes["dclrscr"]        = 214 //DCLRSCR X		: Clear screen with color X				[COLOR]
gpuopcodes["dcolor"]         = 215 //DCOLOR X		: Set current color to X				[COLOR]
gpuopcodes["dbindtexture"]   = 216 //DBINDTEXTURE X	: Bind texture						[STRING]
gpuopcodes["dsetfont"]	    = 217 //DSETFONT X		: Set current font to X					[FONTID]
gpuopcodes["dsetsize"]	    = 218 //DSETSIZE X		: Set font size to X					[INT]
gpuopcodes["dmove"]	    = 219 //DMOVE X		: Set offset position to X				[2F]
gpuopcodes["dvxdata_2f"]     = 220 //DVXDATA_2F X,Y	: Draw solid 2d polygon    (OFFSET,NUMVALUES)		[2F,INT]
gpuopcodes["dvxpoly"]        = 220 //
gpuopcodes["dvxdata_2f_tex"] = 221 //DVXDATA_2F_TEX X,Y	: Draw textured 2d polygon (OFFSET,NUMVALUES)		[2F+UV,INT]
gpuopcodes["dvxtexpoly"]     = 221 //
gpuopcodes["dvxdata_3f"]     = 222 //DVXDATA_3F X,Y	: Draw solid 3d polygon    (OFFSET,NUMVALUES)		[3F,INT]
gpuopcodes["dvxdata_3f_tex"] = 223 //DVXDATA_3F_TEX X,Y	: Draw textured 3d polygon (OFFSET,NUMVALUES)		[3F+UV,INT]
gpuopcodes["dvxdata_wf"]     = 224 //DVXDATA_WF X,Y	: Draw wireframe 3d polygon    (OFFSET,NUMVALUES)	[3F,INT]
gpuopcodes["drect"]          = 225 //DRECT X,Y		: Draw rectangle (XY1,XY2)				[2F,2F]
gpuopcodes["dcircle"]        = 226 //DCIRCLE X,Y		: Draw circle (XY,R)					[2F,F]
gpuopcodes["dline"]          = 227 //DLINE X,Y		: Draw line (XY1,XY2)					[2F,2F]
gpuopcodes["drectwh"]        = 228 //DRECTWH X,Y		: Draw rectangle (XY,WH)				[2F,2F]
gpuopcodes["dtrectwh"]       = 229 //DTRECTWH X,Y	: Draw textured rectangle (XY1,XY2)			[2F,2F]
gpuopcodes["dtransform2f"]   = 230 //DTRANSFORM2F X,Y	: Transform Y, save to X				[2F,2F]
gpuopcodes["dtransform3f"]   = 231 //DTRANSFORM3F X,Y	: Transform Y, save to X				[3F,3F]
gpuopcodes["dscrsize"]       = 232 //DSCRSIZE X,Y	: Set screen size					[F,F]
gpuopcodes["drotatescale"]   = 233 //DROTATESCALE X,Y	: Rotate and scale
gpuopcodes["dorectwh"]       = 234 //DORECTWH X,Y	: Draw outlined rectangle (XY1,XY2)			[2F,2F]
gpuopcodes["docircle"]       = 235 //DOCIRCLE X,Y	: Draw outlined circle (XY1,XY2)			[2F,2F]
gpuopcodes["dwrite"]         = 240 //DWRITE X,Y		: Write Y to coordinates X				[2F,STRING]
gpuopcodes["dwritei"]        = 241 //DWRITEI X,Y		: Write INT Y to coordinates X 				[2F,I]
gpuopcodes["dwritef"]        = 242 //DWRITEF X,Y		: Write 1F Y to coordinates X 				[2F,F]
gpuopcodes["dentrypoint"]    = 243 //DENTRYPOINT X,Y	: Set entry point X to address Y			[INT,INT]
gpuopcodes["dsetlight"]      = 244 //DSETLIGHT X,Y	: Set light X to Y (Y points to [pos,color])		[INT,3F+COLOR]
gpuopcodes["dgetlight"]      = 245 //DGETLIGHT X,Y	: Get light Y to X (X points to [pos,color])		[INT,3F+COLOR]
gpuopcodes["dwritefmt"]      = 246 //DWRITEFMT X,Y	: Write formatted string Y to coordinates X		[2F,STRING+PARAMS]
gpuopcodes["dwritefix"]      = 247 //DWRITEFIX X,Y	: Write fixed value Y to coordinates X			[2F,F]
gpuopcodes["dtextwidth"]     = 248 //DTEXTWIDTH X,Y	: Return text width of Y				[INT,STRING]
gpuopcodes["dtextheight"]    = 249 //DTEXTHEIGHT X,Y	: Return text height of Y				[INT,STRING]
gpuopcodes["dhaschanged"]    = 258 //DHASCHANGED X,Y	: CMPR = HasChanged(Memory[X...Y])			[INT,INT]
gpuopcodes["dloopxy"]        = 259 //DLOOPXY X,Y		: IF DX>0 {IP=X;IF CX>0{CX--}ELSE{DX--;CX=Y}}		[INT,INT]
gpuopcodes["mload"]          = 271 //MLOAD X		: Load matrix X into view matrix			[MATRIX]
gpuopcodes["mread"]          = 272 //MREAD X		: Write view matrix into matrix X			[MATRIX]
gpuopcodes["dt"]             = 274 //DT X		: X -> Frame DeltaTime					[F]
gpuopcodes["dstrprecache"]   = 275 //DSTRPRECACHE X	: Read and cache string					[STRING]
gpuopcodes["dshade"]         = 276 //DSHADE X		: COLOR = COLOR * X					[F]
gpuopcodes["dsetwidth"]      = 277 //DSETWIDTH X		: LINEWIDTH = X						[F]
gpuopcodes["ddframe"]        = 280 //DDFRAME X		: Draw bordered frame					[BORDER_STRUCT]
gpuopcodes["ddbar"]          = 281 //DDBAR X		: Draw progress bar					[BAR_STRUCT]
gpuopcodes["ddgauge"]        = 282 //DDGAUGE X		: Draw gauge needle					[GAUGE_STRUCT]
gpuopcodes["dsettextbox"]	 = 288 //DSETTEXTBOX X	: Set textbox dimensions					[2F]
gpuopcodes["dsettextwrap"]	 = 289 //DSETTEXTWRAP X	: Toggle text wrapping					[INT]
gpuopcodes["dspritesize"]    = 290 //DSPRITESIZE X,Y	: Set sprite size in X,Y				[INT,INT]
gpuopcodes["dtosprite"]      = 291 //DTOSPRITE X,Y	: Copy region Y to sprite X				[INT,4F]
gpuopcodes["dfromsprite"]    = 292 //DFROMSPRITE X,Y	: Copy sprite Y	to region X				[4F,INT]
gpuopcodes["dsprite"]        = 293 //DSPRITE X,Y		: Draw sprite Y to position X				[2F,INT]
gpuopcodes["dmuldt"]         = 294 //DMULDT X,Y		: X = Y * dT						[2F,2F]
gpuopcodes["drotate"]        = 300 //DROTATE X		: Rotate(X)						[4F]
gpuopcodes["dtranslate"]     = 301 //DTRANSLATE X	: Translate(X)						[4F]
gpuopcodes["dscale"]         = 302 //DSCALE X		: Scale(X)						[4F]

local registers = {}
registers["eax"] = 0
registers["ebx"] = 1
registers["ecx"] = 2
registers["edx"] = 3
registers["esi"] = 4
registers["edi"] = 5
registers["esp"] = 6
registers["ebp"] = 7
registers["cs"] = 8
registers["ss"] = 9
registers["ds"] = 10
registers["es"] = 11
registers["gs"] = 12
registers["fs"] = 13
registers["ks"] = 14
registers["ls"] = 15

WireLib.CPU = {
	opcodes = opcodes,
	gpuopcodes = gpuopcodes,
	registers = registers,
}
