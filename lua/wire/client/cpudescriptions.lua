// CPU & GPU Helper Descriptions - by Drunkie

local AddDesc = E2Helper.AddCPUDesc

// CPU opcodes
//----------------------------------------------------------------------------------------------------------------------------------
AddDesc( "jne", "label", "Jump to label if comparison is not equal to value (Requires a comparison first)", "CPU/GPU", "opcode[1]" )
AddDesc( "jnz", "label", "Jump if bit is not zero (See BIT opcode)", "CPU/GPU", "opcode[1]" )
AddDesc( "jmp", "label", "Jump directly to label", "CPU/GPU", "opcode[2]" )
AddDesc( "jg", "label", "Jump to label if comparison is greater than value (Requires a comparison first)", "CPU/GPU", "opcode[3]" )
AddDesc( "jnle", "label", "Jump to label if comparison is not less than or equal to value (Requires a comparison first)", "CPU/GPU", "opcode[3]" )
AddDesc( "jge", "label", "Jump to label if comparison is greater than or equal to value (Requires a comparison first)", "CPU/GPU", "opcode[4]" )
AddDesc( "jnl", "label", "Jump to label if comparison is not less than value (Requires a comparison first)", "CPU/GPU", "opcode[4]" )
AddDesc( "jl", "label", "Jump to label if comparison is less than value (Requires a comparison first)", "CPU/GPU", "opcode[5]" )
AddDesc( "jnge", "label", "Jump to label if comparison is not greater than or equal to value (Requires a comparison first)", "CPU/GPU", "opcode[5]" )
AddDesc( "jle", "label", "Jump to label if comparison is less than or equal to value (Requires a comparison first)", "CPU/GPU", "opcode[6]" )
AddDesc( "jng", "label", "Jump to label if comparison is not greater than value (Requires a comparison first)", "CPU/GPU", "opcode[6]" )
AddDesc( "je", "label", "Jump to label if comparison is equal to value (Requires a comparison first)", "CPU/GPU", "opcode[7]" )
AddDesc( "jz", "label", "Jump if bit is zero (See BIT opcode)", "CPU/GPU", "opcode[7]" )
AddDesc( "cpuid", "", "", "CPU/GPU", "opcode[8]" ) // Describe me
AddDesc( "push", "number", "Push a value onto the stack (You must pop it off the stack as well)", "CPU/GPU", "opcode[9]" )
AddDesc( "add", "number,number", "Add both parameters and store the value in the 1st parameter", "CPU/GPU", "opcode[10]" )
AddDesc( "sub", "number,number", "Subtract 2nd parameter from 1st parameter store the value in the 1st parameter", "CPU/GPU", "opcode[11]" )
AddDesc( "mul", "number,number", "Multiply both parameters and store the value in the 1st parameter", "CPU/GPU", "opcode[12]" )
AddDesc( "div", "number,number", "Divide 1st parameter by 2nd parameter and store the value in the 1st parameter", "CPU/GPU", "opcode[13]" )
AddDesc( "mov", "number,number", "Make the 1st parameter equal the 2nd parameter", "CPU/GPU", "opcode[14]" )
AddDesc( "cmp", "number,number", "Compare the 1st parameter to the 2nd parameter (Used with calls and jumps)", "CPU/GPU", "opcode[15]" )
AddDesc( "rd", "", "Read value from internal CPU RAM (Obsolete)", "CPU", "opcode[16]" )
AddDesc( "wd", "", "Write value to internal CPU RAM (Obsolete)", "CPU", "opcode[17]" )
AddDesc( "min", "number,number", "If the 2nd parameter is less than the 1st parameter, 1st parameter = 2nd parameter", "CPU/GPU", "opcode[18]" )
AddDesc( "max", "number,number", "If the 2nd parameter is greater than the 1st parameter, 1st parameter = 2nd parameter", "CPU/GPU", "opcode[19]" )
AddDesc( "inc", "number", "Increment number by 1", "CPU/GPU", "opcode[20]" )
AddDesc( "dec", "number", "Decrement number by 1", "CPU/GPU", "opcode[21]" )
AddDesc( "neg", "number", "Negate a number", "CPU/GPU", "opcode[22]" )
AddDesc( "rand", "number", "Create a random number between 0 and 1", "CPU/GPU", "opcode[23]" )
AddDesc( "loop", "label", "If register ECX is not equal to 0, then jump to label", "CPU/GPU", "opcode[24]" )
AddDesc( "loopa", "label", "If register EAX is not equal to 0, then jump to label", "CPU/GPU", "opcode[25]" )
AddDesc( "loopb", "label", "If register EBX is not equal to 0, then jump to label", "CPU/GPU", "opcode[26]" )
AddDesc( "loopd", "label", "If register EDX is not equal to 0, then jump to label", "CPU/GPU", "opcode[27]" )
AddDesc( "spg", "", "Make RAM page readonly", "CPU", "opcode[28]" )
AddDesc( "cpg", "", "Make RAM page readable and writeable", "CPU", "opcode[29]" )
AddDesc( "pop", "number", "Pop a value off the stack and store it in the 1st parameter (You must first push a value onto the stack)", "CPU/GPU", "opcode[30]" )
AddDesc( "call", "label", "Call a label/subroutine. (Requires the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[31]" )
AddDesc( "bnot", "number", "Per-bit NOT (48-bit NOT)", "CPU/GPU", "opcode[32]" )
AddDesc( "fint", "number", "Floors the number parameter", "CPU/GPU", "opcode[33]" )
AddDesc( "frnd", "number", "Rounds the number parameter", "CPU/GPU", "opcode[34]" )
AddDesc( "ffrac", "number", "Returns the fractional part of the parameter", "CPU/GPU", "opcode[35]" )
AddDesc( "finv", "number", "Returns 1 divided by the parameter", "CPU/GPU", "opcode[36]" )
AddDesc( "halt", "", "Obsolete", "CPU", "opcode[37]" )
AddDesc( "fshl", "number", "Returns parameter multiplied by 2", "CPU/GPU", "opcode[38]" )
AddDesc( "fshr", "number", "Returns parameter divided by 2", "CPU/GPU", "opcode[39]" )
AddDesc( "ret", "", "Returns back to where a label was called from (Must call a label first)", "CPU/GPU", "opcode[40]" )
AddDesc( "iret", "", "Return from interrupt", "CPU", "opcode[41]" )
AddDesc( "sti", "", "Enable interrupts", "CPU", "opcode[42]" )
AddDesc( "cli", "", "Disable interrupts", "CPU", "opcode[43]" )
AddDesc( "stp", "", "Obsolete", "CPU", "opcode[44]" )
AddDesc( "clp", "", "Obselete", "CPU", "opcode[45]" )
AddDesc( "retf", "", "Return from far call", "CPU/GPU", "opcode[47]" )
AddDesc( "stef", "", "Enable extended mode", "CPU", "opcode[48]" )
AddDesc( "clef", "", "Disable extended mode", "CPU", "opcode[49]" )
AddDesc( "and", "number,number", "If the 1st parameter and the 2nd parameter are greater than 0, the 1st parameter equals 1", "CPU/GPU", "opcode[50]" )
AddDesc( "or", "number,number", "If the 1st parameter or the 2nd parameter are greater than 0, the 1st parameter equals 1", "CPU/GPU", "opcode[51]" )
AddDesc( "xor", "number,number", "If the 1st parameter is not equal to the 2nd parameter, the 1st parameter equals 1", "CPU/GPU", "opcode[52]" )
AddDesc( "fsin", "number,number", "1st parameter equals the sine of the 2nd parameter", "CPU/GPU", "opcode[53]" )
AddDesc( "fcos", "number,number", "1st parameter equals the cosine of the 2nd parameter", "CPU/GPU", "opcode[54]" )
AddDesc( "ftan", "number,number", "1st parameter equals the tangent of the 2nd parameter", "CPU/GPU", "opcode[55]" )
AddDesc( "fasin", "number,number", "1st parameter equals the inverse sine of the 2nd parameter", "CPU/GPU", "opcode[56]" )
AddDesc( "facos", "number,number", "1st parameter equals the inverse cosine of the 2nd parameter", "CPU/GPU", "opcode[57]" )
AddDesc( "fatan", "number,number", "1st parameter equals the inverse tangent of the 2nd parameter", "CPU/GPU", "opcode[58]" )
AddDesc( "mod", "number,number", "1st parameter equals the modulus of the 2nd parameter", "CPU/GPU", "opcode[59]" )
AddDesc( "bit", "number,number", "", "CPU/GPU", "opcode[60]" )
AddDesc( "sbit", "number,number", "Check bit of value specified by 1st parameter (Use jz/jnz to check)", "CPU/GPU", "opcode[61]" )
AddDesc( "cbit", "number,number", "Clear bit of value...", "CPU/GPU", "opcode[62]" )
AddDesc( "tbit", "number,number", "Toggle bit", "CPU/GPU", "opcode[63]" )
AddDesc( "band", "number,number", "Binary 'AND' operation on two values, result stored in 1st parameter", "CPU/GPU", "opcode[64]" )
AddDesc( "bor", "number,number", "Binary 'OR' operation on two values, result stored in 1st parameter", "CPU/GPU", "opcode[65]" )
AddDesc( "bxor", "number,number", "Binary 'exclusive-OR' operation on two values, result stored in 1st parameter", "CPU/GPU", "opcode[66]" )
AddDesc( "bshl", "number,number", "Binary shift", "CPU/GPU", "opcode[67]" )
AddDesc( "bshr", "number,number", "Binary shift", "CPU/GPU", "opcode[68]" )
AddDesc( "jmpf", "", "Far jump (changes CS and IP)", "CPU/GPU", "opcode[69]" )
AddDesc( "nmiint", "", "Trigger NMI interrupt", "CPU", "opcode[70]" )
AddDesc( "cne", "label", "Call label if comparison is not equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[71]" )
AddDesc( "cnz", "label", "Call if bit is not zero (See BIT opcode)", "CPU/GPU", "opcode[71]" )
AddDesc( "cg", "label", "Call label if comparison is greater than value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[73]" )
AddDesc( "cnle", "label", "Call label if comparison is not less than or equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[73]" )
AddDesc( "cge", "label", "Call label if comparison is greater than or equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[74]" )
AddDesc( "cnl", "label", "Call label if comparison is not less than value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[74]" )
AddDesc( "cl", "label", "Call label if comparison is less than value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[75]" )
AddDesc( "cnge", "label", "Call label if comparison is not greater than or equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[75]" )
AddDesc( "cle", "label", "Call label if comparison is less than or equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[76]" )
AddDesc( "cng", "label", "Call label if comparison is not greater than value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[76]" )
AddDesc( "ce", "label", "Call label if comparison is equal to value (Requires comparison and the opcode 'ret' at the end of the label to return to where it was called from)", "CPU/GPU", "opcode[77]" )
AddDesc( "cz", "label", "Call if bit is zero (See BIT opcode)", "CPU/GPU", "opcode[77]" )
AddDesc( "mcopy", "number", "Copy a number of bytes from pointer specified by ESI to pointer specified by EDI", "CPU/GPU", "opcode[78]" )
AddDesc( "mxchg", "number", "Exchange two areas in same manner as mcopy copies", "CPU/GPU", "opcode[79]" )
AddDesc( "fpwr", "number,number", "1st parameter equals the 1st parameter to the power of the 2nd parameter", "CPU/GPU", "opcode[80]" )
AddDesc( "xchg", "number,number", "1st parameter equals the 2nd parameter, 2nd parameter equals the 1st (Exchanges values)", "CPU/GPU", "opcode[81]" )
AddDesc( "flog", "number,number", "1st parameter equals the log of the 2nd parameter", "CPU/GPU", "opcode[82]" )
AddDesc( "flog10", "number,number", "1st parameter equals the log10 of the 2nd parameter", "CPU/GPU", "opcode[83]" )
AddDesc( "in", "number,port", "Input the port value (port0, port1, port2, etc) to 1st parameter", "CPU/GPU", "opcode[84]" )
AddDesc( "out", "number,port", "Output the 2nd parameters value to a port (port0, port1, port2, etc)", "CPU", "opcode[85]" )
AddDesc( "fabs", "number,number", "1st parameter equals the absolute value of the 2nd parameter", "CPU/GPU", "opcode[86]" )
AddDesc( "fsgn", "number,number", "1st parameter equals the sign of the 2nd parameter", "CPU/GPU", "opcode[87]" )
AddDesc( "fexp", "number,number", "1st parameter equals the exponent of the 2nd parameter", "CPU/GPU", "opcode[88]" )
AddDesc( "callf", "", "Far call (changes CS and IP)", "CPU/GPU", "opcode[89]" )
AddDesc( "fpi", "number", "Store the value of pi in the 1st parameter", "CPU/GPU", "opcode[90]" )
AddDesc( "fe", "number", "Stores value of E (2.718281828) in 1st parameter", "CPU/GPU", "opcode[91]" )
AddDesc( "int", "", "Triggers a CPU interrupt", "CPU/GPU", "opcode[92]" )
AddDesc( "tpg", "", "Test page (Comparison operation, if page is faulty, then JZ never executes)", "CPU/GPU", "opcode[93]" )
AddDesc( "fceil", "number", "Ceil the 1st parameter", "CPU/GPU", "opcode[94]" )
AddDesc( "erpg", "", "Erase RAM page from ROM", "CPU", "opcode[95]" )
AddDesc( "wrpg", "", "Write RAM page to CPU ROM", "CPU", "opcode[96]" )
AddDesc( "rdpg", "", "Restore RAM page from CPU ROM", "CPU", "opcode[97]" )
AddDesc( "timer", "number", "Assign the curtime value to the 1st parameter", "CPU/GPU", "opcode[98]" )
AddDesc( "lidtr", "", "Specify pointer to interrupt table", "CPU", "opcode[99]" )
AddDesc( "jner", "", "", "CPU/GPU", "opcode[101]" ) // Describe me
AddDesc( "jnzr", "", "", "CPU/GPU", "opcode[101]" ) // Describe me
AddDesc( "jmpr", "", "", "CPU/GPU", "opcode[102]" ) // Describe me
AddDesc( "jgr", "", "", "CPU/GPU", "opcode[103]" ) // Describe me
AddDesc( "jnler", "", "", "CPU/GPU", "opcode[103]" ) // Describe me
AddDesc( "jger", "", "", "CPU/GPU", "opcode[104]" ) // Describe me
AddDesc( "jnlr", "", "", "CPU/GPU", "opcode[104]" ) // Describe me
AddDesc( "jlr", "", "", "CPU/GPU", "opcode[105]" ) // Describe me
AddDesc( "jnger", "", "", "CPU/GPU", "opcode[105]" ) // Describe me
AddDesc( "jler", "", "", "CPU/GPU", "opcode[106]" ) // Describe me
AddDesc( "jngr", "", "", "CPU/GPU", "opcode[106]" ) // Describe me
AddDesc( "jer", "", "", "CPU/GPU", "opcode[107]" ) // Describe me
AddDesc( "jzr", "", "", "CPU/GPU", "opcode[107]" ) // Describe me
AddDesc( "lneg", "", "", "CPU/GPU", "opcode[108]" ) // Describe me
AddDesc( "nmiret", "", "Return from interrupt", "CPU", "opcode[110]" )
AddDesc( "idle", "", "Makes CPU skip instructions which remain to be executed in this server frame", "CPU", "opcode[111]" )
AddDesc( "nop", "", "Does absolutely fucking nothing", "CPU", "opcode[112]" )
AddDesc( "cpuget", "", "Reads any CPU register, including internal ones", "CPU/GPU", "opcode[120]" )
AddDesc( "cpuset", "", "Writes to any CPU register, including internal ones", "CPU/GPU", "opcode[121]" )
AddDesc( "spp", "", "Set page parameter", "CPU", "opcode[122]" )
AddDesc( "cpp", "", "Clear page parameter", "CPU", "opcode[123]" )
AddDesc( "srl", "", "Set page runlevel", "CPU", "opcode[124]" )
AddDesc( "grl", "", "Read page runlevel", "CPU", "opcode[125]" )
AddDesc( "lea", "", "Load effective address (lea eax,ES:#value gives you absolute address of value, basically EAX = ES+VALUE)", "CPU/GPU", "opcode[126]" )
AddDesc( "block", "", "Specify RAM block for page operations (If it is specified, next page operation ignores 1st parameter)", "CPU/GPU", "opcode[127]" )
AddDesc( "cmpand", "number,number", "Like a CMP, but it accounts for previous result of CMP operation. CMP A,B; CMPAND C,D; equals to (A !=  && (C <any operation> D)", "CPU/GPU", "opcode[128]" )
AddDesc( "cmpor", "number,number", "Like a CMP, but it accounts for previous result of CMP operation. CMP A,B; CMPAND C,D; equals to (A !=  && (C <any operation> D)", "CPU/GPU", "opcode[129]" )
AddDesc( "mshift", "", "Shift all bytes by a value. Pointer in ESI, number to shift by in X. It actually rolls the bytes", "CPU/GPU", "opcode[130]" )
AddDesc( "smap", "", "Remap one RAM page to another", "CPU/GPU", "opcode[131]" )
AddDesc( "gmap", "", "Remap one RAM page to another", "CPU/GPU", "opcode[132]" )


// GPU opcodes
//----------------------------------------------------------------------------------------------------------------------------------
AddDesc( "drect_test", "", "Perform GPU graphics test", "GPU", "opcode[200]" )
AddDesc( "dexit", "", "Exit current frame (Must always be used to end program execution)", "GPU", "opcode[201]" )
AddDesc( "dclr", "", "Clear GPU background color to black", "GPU", "opcode[202]" )
--AddDesc( "dclrtex", "", "", "GPU", "opcode[203]" ) // Non-functional opcode
AddDesc( "dvxflush", "", "Flush vertex buffer to screen", "GPU", "opcode[204]" )
AddDesc( "dvxclear", "", "Clear vertex buffer", "GPU", "opcode[205]" )
AddDesc( "derrorexit", "", "Exit error handler", "GPU", "opcode[206]" )
--AddDesc( "dsetbuf_spr", "", "", "GPU", "opcode[207]" ) // Non-functional opcode
--AddDesc( "dsetbuf_fbo", "", "", "GPU", "opcode[208]" ) // Non-functional opcode
--AddDesc( "dbindbuf_spr", "", "", "GPU", "opcode[209]" ) // Non-functional opcode
AddDesc( "dvxpipe", "number", "Set vertex pipe to number ID [0-5]", "GPU", "opcode[210]" )
AddDesc( "dcvxpipe", "number", "Set coordinate vertex pipe to number ID [0-4]", "GPU", "opcode[211]" )
AddDesc( "denable", "number", "Enable control flags [0 = VERTEX_ZSORT, 1 = VERTEX_LIGHTING, 2 = VERTEX_BUFFER, 3 = VERTEX_CULLING]", "GPU", "opcode[212]" )
AddDesc( "ddisable", "number", "Disable control flags [0 = VERTEX_ZSORT, 1 = VERTEX_LIGHTING, 2 = VERTEX_BUFFER, 3 = VERTEX_CULLING]", "GPU", "opcode[213]" )
AddDesc( "dclrscr", "color", "Clear GPU background color to color variable", "GPU", "opcode[214]" )
AddDesc( "dcolor", "color", "Set GPU draw color to color variable", "GPU", "opcode[215]" )
--AddDesc( "dbindtexture", "string", "Bind a texture to a string", "GPU", "opcode[216]" ) // Non-functional opcode
AddDesc( "dsetfont", "number", "Set font type to number ID [0-4]", "GPU", "opcode[217]" )
AddDesc( "dsetsize", "number", "Set text size to number value", "GPU", "opcode[218]" )
AddDesc( "dmove", "vec2f", "Set offset position to vec2f variable", "GPU", "opcode[219]" )
AddDesc( "dvxdata_2f", "label,number", "Draw solid 2D polygon", "GPU", "opcode[220]" )
AddDesc( "dvxpoly", "label,number", "Draw solid 2D polygon", "GPU", "opcode[220]" )
--AddDesc( "dvxdata_2f_tex", "", "Draw textured 2D polygon", "GPU", "opcode[221]" ) // Non-functional opcode
--AddDesc( "dvxtexpoly", "", "Draw textured 2D polygon", "GPU", "opcode[221]" ) // Non-functional opcode
AddDesc( "dvxdata_3f", "label,number", "Draw solid 3D polygon", "GPU", "opcode[222]" )
--AddDesc( "dvxdata_3f_tex", "", "Draw textured 3D polygon", "GPU", "opcode[223]" ) // Non-functional opcode
--AddDesc( "dvxdata_wf", "", "Draw wireframe 3D polygon", "GPU", "opcode[224]" ) // Non-functional opcode
AddDesc( "drect", "vec2f,vec2f", "Draw rectangle from 1st vec2f variable to 2nd vec2f variable", "GPU", "opcode[225]" )
AddDesc( "dcircle", "vec2f,number", "Draw circle at vec2f variable with a number radius", "GPU", "opcode[226]" )
AddDesc( "dline", "vec2f,vec2f", "Draw line from 1st vec2f variable to 2nd vec2f variable", "GPU", "opcode[227]" )
AddDesc( "drectwh", "vec2f,vec2f", "Draw rectangle from 1st vec2f variable to 2nd vec2f variable with specified width and height", "GPU", "opcode[228]" )
--AddDesc( "drectwh", "vec2f,vec2f", "Draw textured rectangle", "GPU", "opcode[229]" ) // Non-functional opcode
AddDesc( "dtransform2f", "", "", "GPU", "opcode[230]" ) // Describe me
AddDesc( "dtransform3f", "", "", "GPU", "opcode[231]" ) // Describe me
AddDesc( "dscrsize", "number,number", "Set screen size (Must set dcvxpipe 1 first)", "GPU", "opcode[232]" )
AddDesc( "drotatescale", "number,number", "Rotate screen with 1st parameter and scale the screen with 2nd parameter", "GPU", "opcode[233]" )
AddDesc( "dorectwh", "vec2f,vec2f", "Draw outlined rectangle from 1st vec2f variable to 2nd vec2f variable with specified width and height", "GPU", "opcode[234]" )
--AddDesc( "docircle", "vec2f,vec2f", "Draw outlined circle", "GPU", "opcode[235]" ) // Non-functional opcode
AddDesc( "dwrite", "vec2f,string", "Write string at vec2f variable position", "GPU", "opcode[240]" )
AddDesc( "dwritei", "vec2f,number", "Write integer at vec2f variable position", "GPU", "opcode[241]" )
AddDesc( "dwritef", "vec2f,number", "Write number (float) at vec2f variable position", "GPU", "opcode[242]" )
AddDesc( "dentrypoint", "number,number", "Set startpoint of specific operation", "GPU", "opcode[243]" )
AddDesc( "dsetlight", "number,label", "Set light number and label containing vec3f(lightpos) and color definition", "GPU", "opcode[244]" )
AddDesc( "dgetlight", "number,label", "Get light number and label containing vec3f(lightpos) and color definition", "GPU", "opcode[245]" )
AddDesc( "dwritefmt", "vec2f,string", "Write formatted string at vec2f variable position with a string containing special parameters", "GPU", "opcode[246]" )
AddDesc( "dwritefix", "vec2f,number", "Write fixed number to vec2f variable position", "GPU", "opcode[247]" )
--AddDesc( "dhaschanged", "number,number", "", "GPU", "opcode[258]" ) // Non-functional opcode
--AddDesc( "dloopxy", "number,number", "", "GPU", "opcode[259]" ) // Describe me
AddDesc( "mload", "matrix", "Load matrix into view matrix", "GPU", "opcode[271]" )
AddDesc( "mread", "matrix", "Write view matrix into matrix variable", "GPU", "opcode[272]" )
AddDesc( "dt", "number", "Store frame delta time in number variable", "GPU", "opcode[274]" )
AddDesc( "dstrprecache", "string", "Read and cache string", "GPU", "opcode[275]" )
AddDesc( "dshade", "number", "Shade current draw color by number [0-255]", "GPU", "opcode[276]" )
AddDesc( "dsetwidth", "number", "Set line width to number", "GPU", "opcode[277]" )
--AddDesc( "ddframe", "", "Draw bordered frame", "GPU", "opcode[280]" ) // Non-functional opcode
--AddDesc( "ddbar", "", "Draw progress bar", "GPU", "opcode[281]" ) // Non-functional opcode
--AddDesc( "ddgauge", "", "Draw gauge needle	", "GPU", "opcode[282]" ) // Non-functional opcode
--AddDesc( "dspritesize", "", "", "GPU", "opcode[290]" ) // Non-functional opcode
--AddDesc( "dtosprite", "", "", "GPU", "opcode[291]" ) // Non-functional opcode
--AddDesc( "dfromsprite", "", "", "GPU", "opcode[292]" ) // Non-functional opcode
--AddDesc( "dsprite", "", "", "GPU", "opcode[293]" ) // Non-functional opcode
AddDesc( "dmuldt", "vec2f,vec2f", "Multiply by delta-time", "GPU", "opcode[294]" )
AddDesc( "drotate", "vec4f", "", "GPU", "opcode[300]" ) // Describe me
AddDesc( "dtranslate", "vec4f", "", "GPU", "opcode[301]" ) // Describe me
AddDesc( "dscale", "vec4f", "", "GPU", "opcode[302]" ) // Describe me


// AdvMath opcodes
//----------------------------------------------------------------------------------------------------------------------------------
AddDesc( "vadd", "vec2f,vec2f", "Adds the 2nd vector to the 1st vector", "CPU/GPU", "opcode[250]" )
AddDesc( "vadd", "vec3f,vec3f", "Adds the 2nd vector to the 1st vector (Must set vmode 3 first)", "CPU/GPU", "opcode[250]" )
AddDesc( "vsub", "vec2f,vec2f", "Subtracts the 2nd vector from the 1st vector", "CPU/GPU", "opcode[251]" )
AddDesc( "vsub", "vec3f,vec3f", "Subtracts the 2nd vector from the 1st vector (Must set vmode 3 first)", "CPU/GPU", "opcode[251]" )
AddDesc( "vmul", "vec2f,vec2f", "Multiplies the 1st vector by the 2nd vector", "CPU/GPU", "opcode[252]" )
AddDesc( "vmul", "vec3f,vec3f", "Multiplies the 1st vector by the 2nd vector (Must set vmode 3 first)", "CPU/GPU", "opcode[252]" )
AddDesc( "vdot", "vec2f,vec2f", "1st vector equals the dot product of the 2nd vector", "CPU/GPU", "opcode[253]" )
AddDesc( "vdot", "vec3f,vec3f", "1st vector equals the dot product of the 2nd vector (Must set vmode 3 first)", "CPU/GPU", "opcode[253]" )
AddDesc( "vcross", "vec2f,vec2f", "1st vector equals the cross product of the 2nd vector", "CPU/GPU", "opcode[254]" )
AddDesc( "vcross", "vec3f,vec3f", "1st vector equals the cross product of the 2nd vector (Must set vmode 3 first)", "CPU/GPU", "opcode[254]" )
AddDesc( "vmov", "vec2f,vec2f", "Assign the 1st vector to the 2nd vector's value", "CPU/GPU", "opcode[255]" )
AddDesc( "vmov", "vec3f,vec3f", "Assign the 1st vector to the 2nd vector's value (Must set vmode 3 first)", "CPU/GPU", "opcode[255]" )
AddDesc( "vnorm", "vec2f,vec2f", "Gets the normalized vector of the 2nd parameter", "CPU/GPU", "opcode[256]" )
AddDesc( "vnorm", "vec3f,vec3f", "Gets the normalized vector of the 2nd parameter (Must set vmode 3 first)", "CPU/GPU", "opcode[256]" )
--AddDesc( "vcolornorm", "", "", "CPU/GPU", "opcode[257]" ) // Non-functional opcode
AddDesc( "madd", "matrix,matrix", "Adds the 2nd matrix to the 1st matrix", "CPU/GPU", "opcode[260]" )
AddDesc( "msub", "matrix,matrix", "Subtracts the 2nd matrix from the 1st matrix", "CPU/GPU", "opcode[261]" )
AddDesc( "mmul", "matrix,matrix", "Multiplies the 2nd matrix by the 1st matrix", "CPU/GPU", "opcode[262]" )
AddDesc( "mrotate", "matrix,vec4f", "Rotate a matrix by a vec4f variable (X, Y, Z, W)", "CPU/GPU", "opcode[263]" )
AddDesc( "mscale", "matrix,vec4f", "Scale a matrix by a vec4f variable", "CPU/GPU", "opcode[264]" )
AddDesc( "mperspective", "matrix,vec4f", "Create a perspective matrix from a vec4f variable (FOV, ASPECT RATIO, ZNEAR, ZFAR)", "CPU/GPU", "opcode[265]" )
AddDesc( "mtranslate", "matrix,vec4f", "Create a translation matrix from a vec4f variable (X, Y, Z, <none>) ", "CPU/GPU", "opcode[266]" )
AddDesc( "mlookat", "matrix,label", "Look at a matrix based upon a label containing (CAM POS, VIEW CENTER, UP DIRECTION)", "CPU/GPU", "opcode[267]" )
AddDesc( "mmov", "matrix,matrix", "Assign the 1st matrix to the 2nd matrix", "CPU/GPU", "opcode[268]" )
AddDesc( "vlen", "number,vec2f", "Gets the length of a vector", "CPU/GPU", "opcode[269]" )
AddDesc( "vlen", "number,vec3f", "Gets the length of a vector (Must set vmode 3 first)", "CPU/GPU", "opcode[269]" )
AddDesc( "mident", "matrix", "Load identity matrix into the matrix variable given in the 1st parameter", "CPU/GPU", "opcode[270]" )
AddDesc( "vmode", "number", "Set vector mode for opcodes prefixed with 'v' (2 = 2D Vector, 3 = 3D Vector)", "CPU/GPU", "opcode[273]" )
AddDesc( "vdiv", "vec2f,vec2f", "Divide the 1st vector by the 2nd vector", "CPU/GPU", "opcode[295]" )
AddDesc( "vdiv", "vec3f,vec3f", "Divide the 1st vector by the 2nd vector (Must set vmode 3 first)", "CPU/GPU", "opcode[295]" )
AddDesc( "vtransform", "vec2f,matrix", "Multiply 1st vector by matrix", "CPU/GPU", "opcode[296]" )
AddDesc( "vtransform", "vec3f,matrix", "Multiply 1st vector by matrix (Must set vmode 3 first)", "CPU/GPU", "opcode[296]" )
