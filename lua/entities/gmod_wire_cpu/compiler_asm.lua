function ENT:InitializeRegisterNames()
	self.RegisterName = {}
	self.RegisterName["eax"] = 0
	self.RegisterName["ebx"] = 1
	self.RegisterName["ecx"] = 2
	self.RegisterName["edx"] = 3
	self.RegisterName["esi"] = 4
	self.RegisterName["edi"] = 5
	self.RegisterName["esp"] = 6
	self.RegisterName["ebp"] = 7

	self.RegisterName["cs"] = 8
	self.RegisterName["ss"] = 9
	self.RegisterName["ds"] = 10
	self.RegisterName["es"] = 11
	self.RegisterName["gs"] = 12
	self.RegisterName["fs"] = 13
	self.RegisterName["ks"] = 14
	self.RegisterName["ls"] = 15

	for i=0,1023 do
		self.RegisterName["port"..i] = 1000+i-1
	end

	self.SegmentName = {}
	self.SegmentName["eax"] = -10
	self.SegmentName["ebx"] = -11
	self.SegmentName["ecx"] = -12
	self.SegmentName["edx"] = -13
	self.SegmentName["esi"] = -14
	self.SegmentName["edi"] = -15
	self.SegmentName["esp"] = -16
	self.SegmentName["ebp"] = -17

	self.SegmentName["cs"] = -2
	self.SegmentName["ss"] = -3
	self.SegmentName["ds"] = -4
	self.SegmentName["es"] = -5
	self.SegmentName["gs"] = -6
	self.SegmentName["fs"] = -7
	self.SegmentName["ks"] = -8
	self.SegmentName["ls"] = -9

	self.GeneralRegister = {}
	self.GeneralRegister["eax"] = true
	self.GeneralRegister["ebx"] = true
	self.GeneralRegister["ecx"] = true
	self.GeneralRegister["edx"] = true
	self.GeneralRegister["esi"] = true
	self.GeneralRegister["edi"] = true
	self.GeneralRegister["esp"] = true
	self.GeneralRegister["ebp"] = true
end

function ENT:InitializeOptimizer()
	//
end

function ENT:Message(msg)
	self.Player:PrintMessage(HUD_PRINTCONSOLE,"-> "..msg)
	self.Player:ConCommand("wire_cpu_editor_addlog \""..msg.."\"")
end

function ENT:Error(msg)
	if (EmuFox) then //Override for EmuFox
		print("-> Error at line "..self.Line..": "..msg)
	end

	local errmsg
	if (self.CurrentFile == "") then
		errmsg = "Error: "..msg..", at line "..self.Line
	else
		errmsg = self.CurrentFile..": Error: "..msg..", at line "..(self.Line-self.FileStartLine)
	end
	if ValidEntity(self.Player) then
		self.Player:PrintMessage(HUD_PRINTCONSOLE,"-> "..errmsg)

		-- last error thing for the editor (temporary)
		umsg.Start("wire_cpu_error", self.Player)
			umsg.String(errmsg)
		umsg.End()
	end

	--self.Player:ConCommand("wire_cpu_editor_addlog \"".."-> Error at line "..self.Line..": "..msg.."\"") FIXME
	self.FatalError = true
end

function ENT:_whitespace()
	while ((string.sub(self.CurrentLine,1,1) == " ") ||
	       (string.sub(self.CurrentLine,1,1) == "\t")) do
		self.CurrentLine = string.sub(self.CurrentLine,2)
	end
end

function ENT:_need(char)
	if (string.sub(self.CurrentLine,1,1) ~= char) then
		return false
	else
		self.CurrentLine = string.sub(self.CurrentLine,2)
		self:_whitespace()
		return true
	end
end

function ENT:_need_with_whitespace(char)
	if (string.sub(self.CurrentLine,1,1) ~= char) then
		return false
	else
		self.CurrentLine = string.sub(self.CurrentLine,2)
		return true
	end
end

function ENT:_char()
	local char = string.sub(self.CurrentLine,1,1)
	self.CurrentLine = string.sub(self.CurrentLine,2)
	return char
end

function ENT:_peek()
	return string.sub(self.CurrentLine,2,2)
end

function ENT:_getc()
	return string.sub(self.CurrentLine,1,1)
end

function ENT:_getstring(sepchar)
	local str = ""
	self:_whitespace()
	while ((self.CurrentLine ~= "") && (self:_getc() ~= sepchar) && (self:_getc() ~= ")")) do //fixme isalphanum
		str = str .. self:_char()
	end
	return string.lower(str)
end

function ENT:_word()
	local word = ""
	while self.CurrentLine:match("^[^ ();#:,'\"!%^&*\t]") do //FIXME: isalphanum
		word = word .. string.sub(self.CurrentLine,1,1)
		self.CurrentLine = string.sub(self.CurrentLine,2)
	end
	return word
end


function ENT:_keyword()
	return string.lower(self:_word())
end

function ENT:Compiler_Stage0(pl)
	self.Player = pl

	self.FatalError = false
	self.Compiling = false
	self.MakeDump = false

	self.PrecompileData = {}
	self.DebugLines = {}
	self.DebugData = {}

	self.Dump = ""

	self.LocalVarRange = 128
	self.ReturnVariable = "eax"
end

function ENT:Compiler_SetExtraLabels()
	self:SetLabel("__date_year__",	tonumber(os.date("%Y")))
	self:SetLabel("__date_month__",	tonumber(os.date("%m")))
	self:SetLabel("__date_day__",	tonumber(os.date("%d")))

	self:SetLabel("__date_hour__",	tonumber(os.date("%H")))
	self:SetLabel("__date_minute__",tonumber(os.date("%M")))
	self:SetLabel("__date_second__",tonumber(os.date("%S")))

	if (self.IsGPU) then
		self:SetLabel("regclk",		65535)
		self:SetLabel("regreset",	65534)
		self:SetLabel("reghwclear",	65533)
		self:SetLabel("regvertexmode",	65532)
		self:SetLabel("reghalt",	65531)
		self:SetLabel("regram_reset",	65530)

		self:SetLabel("reghscale",	65525)
		self:SetLabel("regvscale",	65524)
		self:SetLabel("reghwscale",	65523)
		self:SetLabel("regrotation",	65522)
		self:SetLabel("regsprsize",	65521)
		self:SetLabel("regtexdataptr",	65520)
		self:SetLabel("regtexdatasz",	65519)
		self:SetLabel("regrasterq",	65518)

		self:SetLabel("regwidth",	65515)
		self:SetLabel("regheight",	65514)
		self:SetLabel("regratio",	65513)
		self:SetLabel("regparamlist",	65512)

		self:SetLabel("regcursorx",	65505)
		self:SetLabel("regcursory",	65504)
		self:SetLabel("regcursor",	65503)

		self:SetLabel("regbrightnessw",	65495)
		self:SetLabel("regbrightnessr",	65494)
		self:SetLabel("regbrightnessg",	65493)
		self:SetLabel("regbrightnessb",	65492)
		self:SetLabel("regcontrastw",	65491)
		self:SetLabel("regcontrastr",	65490)
		self:SetLabel("regcontrastg",	65489)
		self:SetLabel("regcontrastb",	65488)

		self:SetLabel("regcirclequality",65485)
		self:SetLabel("regoffsetx",	65484)
		self:SetLabel("regoffsety",	65483)
		self:SetLabel("regrotation",	65482)
		self:SetLabel("regscale",	65481)
		self:SetLabel("regcenterx",	65480)
		self:SetLabel("regcentery",	65479)
		self:SetLabel("regcirclestart",	65478)
		self:SetLabel("regcircleend",	65477)
		self:SetLabel("reglinewidth",	65476)
		self:SetLabel("regscalex",	65475)
		self:SetLabel("regscaley",	65474)
		self:SetLabel("regfontalign",	65473)
		self:SetLabel("regzoffset",	65472)
	end
end

function ENT:Compiler_Stage1()
	self.WIP = 0
	self.OffsetWIP = 0
	self.Labels = {}
	self.FunctionParams = {}
	self.FirstPass = true

	self.LastKeyword = ""
	self.Dump = ""
	self.CurrentFunction = nil

	self.CurrentFile = ""
	self.FileStartLine = 0

	self:SetLabel("programsize",0)
	self:Compiler_SetExtraLabels()
end

function ENT:Compiler_Stage2()
	iterator = function (labelk,labelv)
		self.Labels[labelk].Ignore = nil
	end
	table.foreach(self.Labels,iterator)

	self:SetLabel("programsize",self.WIP)
	self:Compiler_SetExtraLabels()

	self.WIP = 0
	self.OffsetWIP = 0
	self.FirstPass = false

	self.LastKeyword = ""
	self.Dump = ""
	self.CurrentFunction = nil

	self.CurrentFile = ""
	self.FileStartLine = 0
end

function ENT:ParseProgram_ASM(programtext,programline)
	if (programtext == "") then
		return
	end

	self.CurrentLine = programtext
	self.Line = programline

	local comment = string.find(self.CurrentLine,"//", 1, true)
	if (comment) then self.CurrentLine = string.sub(self.CurrentLine,1,comment-1) end

	self:Compile()
end

function ENT:GenerateASM(code)
	local templine = self.CurrentLine
	self.CurrentLine = code
	self:GenerateCode()
	self.CurrentLine = templine
end

function ENT:ParseOpcodeParameter(keyword)
	local result = {}

	if (keyword == "") then //#EAX
		if (self:_need("#")) then
			keyword = self:_keyword()
			if (self.RegisterName[keyword]) then //#EAX
				if (self.GeneralRegister[keyword]) then
					result.RM = 17+self.RegisterName[keyword]
				else
					self:Error("Expected general register for memory reference, got '"..keyword.."' instead!")
				end
			else
				if ((self.FunctionParams[keyword]) && (self.Labels[self.CurrentFunction.Name].Param[keyword])) then //#functparam
					result.RM = 49
					result.Byte = self.CurrentFunction.ArgCount - self.Labels[self.CurrentFunction.Name].Param[keyword].Arg + 2
				else
					result.RM = 25
					result.Byte = self:GetValidValue(keyword) //#123
				end
			end
		else
			--[[
			if (self:_need("(")) then //(1,2,3,4) FIXME
				self:_whitespace()
				while (not self:_peek(')')) do
					result.RM = 25
					result.Byte = self:GetValidValue("programsize")

					if (self:_peek(',')) then
						self:_need(',')
					end
					self:_whitespace()
				end
			else
			]]
				self:Error("Expected '#' for memory reference")
			--end
		end
	else
		if (self:_need(":")) then //Segment prefix
			if (self:_need("#")) then //EAX:#EBX
				if (self.RegisterName[keyword]) then //EAX:#EBX
					local register = self:_keyword()
					if (self.RegisterName[register]) then
						if (self.GeneralRegister[register]) then
							result.RM = 17+self.RegisterName[register]
							result.Segment = self.SegmentName[keyword]
						else
							self:Error("Expected general register for parameter with offset")
						end
					else
						result.RM = 25
						result.Byte = self:GetValidValue(register) //EAX:#123
						result.Segment = self.SegmentName[keyword]
					end
				else
					local register = self:_keyword()
					if (self.RegisterName[register]) then //123:#EBX
						if (self.GeneralRegister[register]) then
							result.RM = 34+self.RegisterName[register]
							result.Byte = self:GetValidValue(keyword)
						else
							self:Error("Expected general register name parameter with offset")
						end
					else
						self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
					end
				end
			else //EAX:EBX
				if (self.RegisterName[keyword]) then //EAX:EBX
					local register = self:_keyword()
					if (self.RegisterName[register]) then
						if (self.GeneralRegister[register]) then
							result.RM = 26+self.RegisterName[register]
							result.Segment = self.SegmentName[keyword]
						else
							self:Error("Expected general register for parameter with offset")
						end
					else
						if (tonumber(register)) then //EAX:123
							if (self.GeneralRegister[keyword]) then
								result.RM = 42+self.RegisterName[keyword]
								result.Byte = self:GetValidValue(register)
							else
								self:Error("Expected general register name parameter with offset")
							end
						else
							self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
						end
					end
				else
					local register = self:_keyword()
					if (self.RegisterName[register]) then //123:EBX
						if (self.GeneralRegister[register]) then
							result.RM = 42+self.RegisterName[register]
							result.Byte = self:GetValidValue(keyword)
						else
							self:Error("Expected general register name parameter with offset")
						end
					else
						self:Error("Expected register name for parameter with offset, got '"..keyword.."' instead!")
					end
				end
			end
		else //No segment prefix, no memory reference
			if (self.RegisterName[keyword]) then //EAX
				result.RM = self.RegisterName[keyword]+1
			else
				if ((self.FunctionParams[keyword]) && (self.Labels[self.CurrentFunction.Name].Param[keyword])) then //functparam
					result.RM = 49
					result.Byte = self.CurrentFunction.ArgCount - self.Labels[self.CurrentFunction.Name].Param[keyword].Arg + 2
				else
					result.RM = 0
					result.Byte = self:GetValidValue(keyword) //123
				end
			end
		end
	end

	return result
end

function ENT:GenerateCode(keyword)
	//#EBX< >,< >EAX:#EBX< >
	local dRM1 = {}
	local dRM2 = {}
	if (keyword == nil) then
	 	self:_whitespace()
		keyword = self:_keyword()
		self:_whitespace()
	end

	if (self.OpcodeCount[self.DecodeOpcode[keyword]] > 0) then
		dRM1 = self:ParseOpcodeParameter(self:_keyword())
		if (self.FatalError) then return end
	end
	if (self.OpcodeCount[self.DecodeOpcode[keyword]] > 1) then
		self:_whitespace()
		if (not self:_need(",")) then
			self:Error("Expected second operand for opcode '"..keyword.."'!")
		end
		self:_whitespace()
		dRM2 = self:ParseOpcodeParameter(self:_keyword())
		if (self.FatalError) then return end
	end

	local XEIP = self.WIP
	local RM = 0
	local Opcode = self.DecodeOpcode[keyword]

	if (dRM1.RM) then RM = RM + dRM1.RM end
	if (dRM2.RM) then RM = RM + dRM2.RM*10000 end
	if (dRM1.Segment) then Opcode = Opcode + 1000 end
	if (dRM2.Segment) then Opcode = Opcode + 10000 end

	self:Write(Opcode)
	self:Write(RM)

	if (dRM1.Segment) then self:Write(dRM1.Segment) end
	if (dRM2.Segment) then self:Write(dRM2.Segment) end

	if (dRM1.Byte) then self:Write(dRM1.Byte) end
	if (dRM2.Byte) then self:Write(dRM2.Byte) end

	if (self.FirstPass == false) then
		if (not self.IsGPU) then
			self:Precompile(XEIP)
		end
	end
end

function ENT:ParseDB()
	local ParsingString = false
	while (self.FatalError == false) and (self.CurrentLine ~= "") and not ((not ParsingString) and (self:_need(";"))) do
		if (self:_need_with_whitespace("'")) then
			if (ParsingString == true) then
				if (self:_peek() == "'") then
					self:_char()
					self:Write(string.byte("'"))
				else
					ParsingString = false
					self:_whitespace()
					if (self:_need(",") == false) then return end
					self:_whitespace()
				end
			else
				ParsingString = true
			end
		end
		if (ParsingString == false) then
			if (self:_need("$")) then //Offset...
				local value = self:_keyword()
				self:Write(self.WIP+self:GetValidValue(value))
			else
				local value = self:_keyword()
				self:Write(self:GetValidValue(value))
			end
			self:_whitespace()
			if (self:_need(",") == false) then return end
			self:_whitespace()
		else
			local char = self:_char()
			if (char == "\\") then
				local char2 = self:_char()
				if (char2 == "n") then
					self:Write(10)
				elseif (char2 == "r") then
					self:Write(10)
				elseif (char2 == "0") then
					self:Write(0)
				else
					self:Write(string.byte(char2))
				end
			else
				self:Write(string.byte(char))
			end

		end
	end
end

function ENT:Compile()
	if (self.Debug) && (not self.FirstPass) then
		self.DebugLines[self.Line] = "["..self.Line.."]"..self.CurrentLine
		self.DebugData[self.WIP] = self.Line
	end
	self.Dump = self.Dump.."["..(self.WIP+self.OffsetWIP).."]["..self.Line.."]["..self.WIP.."]"..self.CurrentLine.."\n"

	local prevline = self.CurrentLine.."_"
	while (self.FatalError == false) && (self.CurrentLine ~= "") do
		//< >MOV< >
		if (self.WIP < 0) then
			self:Error("Write pointer out of range")
		end
		if (self.CurrentLine == prevline) then
			self:Error("Infinite loop in parser, you must have done something wrong")
			return
		end
		prevline = self.CurrentLine

		self:_whitespace()
		local word = self:_word()
		local keyword = string.lower(word)
		self:_whitespace()

		if (self.DecodeOpcode[keyword]) then
			self:GenerateCode(keyword)
		elseif (keyword == "db") then
			self:ParseDB()
		elseif (keyword == "alloc") then
			local aword = self:_keyword()
			self:_whitespace()
			if (self:_need(",")) then
				if (aword == "") then
					self.Error("Missing first parameter for 'alloc' macro!")
					return
				end

				local bword = self:_keyword()
				self:_whitespace()
				if (self:_need(",")) then
					local cword = self:_keyword()

					if (bword == "") then
						self.Error("Missing second parameter for 'alloc' macro!")
						return
					end

					if (cword ~= "") then
						local size = 0
						local value = 0

						size = self:GetAlwaysValidValue(bword)
						value = self:GetValidValue(cword)

						self:AddLabel(aword)
						for i=0,size-1 do
							self:Write(value)
						end
					else
						self:Error("Missing third parameter for 'alloc' macro!")
					end
				else
					if (bword ~= "") then //alloc mylabel,123;
						self:AddLabel(aword)
						self:Write(self:GetValidValue(bword))
					else
						self:Error("Missing second parameter for 'alloc' macro!")
					end
				end
			else
				if (aword ~= "") then //alloc mylabel;
					if (tonumber(aword)) then
						for i=0,aword-1 do
							self:Write(0)
						end
					else
						self:AddLabel(aword)
						self:Write(0)
					end
				else //alloc;
					self:Write(0)
				end
			end
		elseif (keyword == "define") then
			local definename = self:_keyword()
			self:_whitespace()
			if (self:_need(",")) then
				local definevalue = self:_keyword()
				if (self.FirstPass) then
					if (self.Labels[definename]) then
						self:Error("Label '"..definename.."' already exists (previously defined at line "..self.Labels[definename].DefineLine..")")
					else
						self.Labels[definename] = {}
						self.Labels[definename].WIP = self:GetValidValue(definevalue)
						self.Labels[definename].DefineLine = self.Line
					end
				end
			else
				self:Error("Error in 'define' macro syntax: missing second parameter (define value)")
			end
		elseif (keyword == "string") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				self:ParseDB()
			end
			self:Write(0)
		elseif (keyword == "matrix") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			self:Write(1) self:Write(0) self:Write(0) self:Write(0)
			self:Write(0) self:Write(1) self:Write(0) self:Write(0)
			self:Write(0) self:Write(0) self:Write(1) self:Write(0)
			self:Write(0) self:Write(0) self:Write(0) self:Write(1)
		elseif (keyword == "float") || (keyword == "scalar") || (keyword == "vector1f") || (keyword == "vec1f") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				local x = self:_keyword()
				self:_whitespace()
				self:AddLabel(name..".x")
				self:Write(self:GetValidValue(x))
			else
				self:AddLabel(name..".x")
				self:Write(0)
			end
		elseif (keyword == "vector2f") || (keyword == "uv") || (keyword == "vector") || (keyword == "vec2f") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				local x = self:_keyword()
				self:_whitespace()
				self:AddLabel(name..".x")
				self:AddLabel(name..".u")
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:_whitespace()
					self:AddLabel(name..".y")
					self:AddLabel(name..".v")
					self:Write(self:GetValidValue(y))
				else
					self:AddLabel(name..".v")
					self:Write(0)
				end
			else
				self:AddLabel(name..".x")
				self:AddLabel(name..".u")
				self:Write(0)
				self:AddLabel(name..".y")
				self:AddLabel(name..".v")
				self:Write(0)
			end
		elseif (keyword == "vector3f") || (keyword == "vec3f") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				local x = self:_keyword()
				self:_whitespace()
				self:AddLabel(name..".x")
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:_whitespace()
					self:AddLabel(name..".y")
					self:Write(self:GetValidValue(y))
					if (self:_need(",")) then
						local z = self:_keyword()
						self:_whitespace()
						self:AddLabel(name..".z")
						self:Write(self:GetValidValue(z))
					else
						self:AddLabel(name..".z")
						self:Write(0)
					end
				else
					self:AddLabel(name..".y")
					self:Write(0)
					self:AddLabel(name..".z")
					self:Write(0)
				end
			else
				self:AddLabel(name..".x")
				self:Write(0)
				self:AddLabel(name..".y")
				self:Write(0)
				self:AddLabel(name..".z")
				self:Write(0)
			end
		elseif (keyword == "vector4f") || (keyword == "vec4f") then
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				local x = self:_keyword()
				self:_whitespace()
				self:AddLabel(name..".x")
				self:AddLabel(name..".r")
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:_whitespace()
					self:AddLabel(name..".y")
					self:AddLabel(name..".g")
					self:Write(self:GetValidValue(y))
					if (self:_need(",")) then
						local z = self:_keyword()
						self:_whitespace()
						self:AddLabel(name..".z")
						self:AddLabel(name..".b")
						self:Write(self:GetValidValue(z))
						if (self:_need(",")) then
							local w = self:_keyword()
							self:_whitespace()
							self:AddLabel(name..".w")
							self:AddLabel(name..".a")
							self:Write(self:GetValidValue(w))
						else
							self:AddLabel(name..".w")
							self:AddLabel(name..".a")
							self:Write(0)
						end
					else
						self:AddLabel(name..".z")
						self:AddLabel(name..".b")
						self:Write(0)
						self:AddLabel(name..".w")
						self:AddLabel(name..".a")
						self:Write(0)
					end
				else
					self:AddLabel(name..".y")
					self:AddLabel(name..".g")
					self:Write(0)
					self:AddLabel(name..".z")
					self:AddLabel(name..".b")
					self:Write(0)
					self:AddLabel(name..".w")
					self:AddLabel(name..".a")
					self:Write(0)
				end
			else
				self:AddLabel(name..".x")
				self:AddLabel(name..".r")
				self:Write(0)
				self:AddLabel(name..".y")
				self:AddLabel(name..".g")
				self:Write(0)
				self:AddLabel(name..".z")
				self:AddLabel(name..".b")
				self:Write(0)
				self:AddLabel(name..".w")
				self:AddLabel(name..".a")
				self:Write(0)
			end
		elseif (keyword == "color") then //copypasta from vector4f
			local name = self:_keyword()
			self:_whitespace()
			self:AddLabel(name)
			if (self:_need(",")) then
				local x = self:_keyword()
				self:_whitespace()
				self:AddLabel(name..".x")
				self:AddLabel(name..".r")
				self:Write(self:GetValidValue(x))
				if (self:_need(",")) then
					local y = self:_keyword()
					self:_whitespace()
					self:AddLabel(name..".y")
					self:AddLabel(name..".g")
					self:Write(self:GetValidValue(y))
					if (self:_need(",")) then
						local z = self:_keyword()
						self:_whitespace()
						self:AddLabel(name..".z")
						self:AddLabel(name..".b")
						self:Write(self:GetValidValue(z))
						if (self:_need(",")) then
							local w = self:_keyword()
							self:_whitespace()
							self:AddLabel(name..".w")
							self:AddLabel(name..".a")
							self:Write(self:GetValidValue(w))
						else
							self:AddLabel(name..".w")
							self:AddLabel(name..".a")
							self:Write(255)
						end
					else
						self:AddLabel(name..".z")
						self:AddLabel(name..".b")
						self:Write(0)
						self:AddLabel(name..".w")
						self:AddLabel(name..".a")
						self:Write(255)
					end
				else
					self:AddLabel(name..".y")
					self:AddLabel(name..".g")
					self:Write(0)
					self:AddLabel(name..".z")
					self:AddLabel(name..".b")
					self:Write(0)
					self:AddLabel(name..".w")
					self:AddLabel(name..".a")
					self:Write(255)
				end
			else
				self:AddLabel(name..".x")
				self:AddLabel(name..".r")
				self:Write(0)
				self:AddLabel(name..".y")
				self:AddLabel(name..".g")
				self:Write(0)
				self:AddLabel(name..".z")
				self:AddLabel(name..".b")
				self:Write(0)
				self:AddLabel(name..".w")
				self:AddLabel(name..".a")
				self:Write(255)
			end
		elseif (keyword == "code") then
			self:AddLabel("codestart")
			if (not self.FirstPass) && (not self.Labels["datastart"]) then
				self:Error("No matching 'data' macro was found!")
			end
		elseif (keyword == "data") then
			self:AddLabel("datastart")
			if (not self.FirstPass) && (not self.Labels["codestart"]) then
				self:Error("No matching 'code' macro was found!")
			end

			self:Write(2)
			self:Write(0)
			self:Write(self:GetValidValue("codestart"))
		elseif (keyword == "org") then
			local value = self:_keyword()
			self.WIP = self:GetValidValue(value)
		elseif (keyword == "offset") then
			local value = self:_keyword()
			self.OffsetWIP = self:GetValidValue(value)
		elseif (keyword == "wipe_locals") then
			self:WipeLocals()
		elseif (keyword == "wipe_labels") then
			self:WipeLabels()
		elseif (keyword == "setvar") then
			local varname = self:_keyword()
			if (varname ~= "") then
				self:_whitespace()
				if (self:_need(",")) then
					local varvalue = self:_keyword()
					if (varvalue ~= "") then
						//Set compiler variables
						if (varname == "localrange") then
							if tonumber(varvalue) then self.LocalVarRange = tonumber(varvalue) end
						end
						if (varname == "returnregister") then
							if self.GeneralRegister[varvalue] then self.ReturnVariable = varvalue end
						end
					else
						self:Error("Missing variable value for 'setvar' macro")
					end
				end
			else
				self:Error("Missing variable name for 'setvar' macro")
			end
		elseif (keyword == "asmfile") then
			local filename  = self:_getstring(";")

			self.CurrentFile = filename
			self.FileStartLine = self.Line
		elseif (keyword == "asmend") then
			self.CurrentFile = ""
		elseif (keyword == "function") then
			if (self.CurrentFunction) then
				self:Error("Can't have function inside function!")
			end

			local fname = self:_keyword()
			local argscnt = 0

			self:AddLabel(fname)
			self:GenerateASM("push ebp")
			self:GenerateASM("mov ebp,esp")
			self:GenerateASM("inc ebp")

			if (self:_need("(")) then
				local argument = self:_getstring(",")
				while (argument ~= "") do
					self:AddFunctionArgument(fname,argument,argscnt)

					argscnt = argscnt + 1
					if (self:_need(",")) then
						argument = self:_getstring(",")
					else
						argument = ""
					end
				end
			end

			self.CurrentFunction = {}
			self.CurrentFunction.ArgCount = argscnt
			self.CurrentFunction.Name = fname
		elseif (keyword == "return") then
			local retval = self:_getstring(";")
			if (retval ~= "") then
				if (retval ~= "eax") then
					self:GenerateASM("mov "..self.ReturnVariable..","..retval)
				end
			end
			self:GenerateASM("add esp,2")
			self:GenerateASM("pop ebp")
			self:GenerateASM("ret")
		elseif (keyword == "end") then
			if (not self.CurrentFunction) then
				self:Error("END must be inside function")
			end

			if (self.LastKeyword ~= "return") then
				self:GenerateASM("add esp,2")
				self:GenerateASM("pop ebp")
				self:GenerateASM("ret")
			end
			self.CurrentFunction = nil
		elseif (keyword == "getarg") then
			if (not self.CurrentFunction) then
				self:Error("GETARG must be inside function")
			end

			if (self:_need("(")) then
				local where = self:_getstring(",")
				self:_need(",")
				local argno = self:GetValidValue(self:_keyword())
				self:GenerateASM("mov "..where..","..(self.CurrentFunction.ArgCount - argno + 2))
			else
				self:Error("GETARG: syntax error")
			end
		elseif (self:_need("(")) then //High-level function call
			//Function call
			local address = self:GetValidValue(keyword)
			local argscnt = 0

			local argument = self:_getstring(",")
			while (argument ~= "") do
				self:GenerateASM("push "..argument)

				argscnt = argscnt + 1
				if (self:_need(",")) then
					argument = self:_getstring(",")
				else
					argument = ""
				end
			end

			self:GenerateASM("mov ecx,"..argscnt)
			self:GenerateASM("call "..address)
			if (argscnt ~= 0) then
				self:GenerateASM("add esp,"..argscnt)
			end

			if (not self:_need(")")) then
				self:Error("Error in function call syntax")
			end
		else
			if (self:_need(":")) then
				if (string.sub(keyword,1,1) == "@") then
					self:AddLocalLabel(keyword)
				elseif (string.sub(keyword,1,1) == "$") then
					self:AddGlobalLabel(keyword)
				else
					self:AddLabel(keyword)
				end
			else
				if (keyword ~= "") then
					local peek = self:_peek()
					if (peek == ";") then
						self:Error("Invalid label definition or unknown keyword '"..keyword.."' (expecting ':' rather than ';')")
					else
						self:Error("Unknown keyword '"..keyword.."'")
					end
				else
					if (self.CurrentLine == "") then
						return
					else
						self:Error("Syntax error. This should not be here: \""..self.CurrentLine.."\"")
					end
				end
			end
		end

		self.LastKeyword = keyword

		self:_whitespace()
		self:_need(";")
	end
end

function ENT:GetLabel(labelname)
	local foundlabel = nil
	//for labelk,labelv in pairs(self.Labels) do
	iterator = function (labelk,labelv)
		if (self.Labels[labelk].Ignore == nil) then
			if (labelk == labelname) then
				if (labelv.Local == true) then
					if (math.abs(self.WIP - labelv.WIP) < self.LocalVarRange) then
						foundlabel = labelv
						return foundlabel
					end
				else
					foundlabel = labelv
					return foundlabel
				end
			end
		end
	end
	table.foreach(self.Labels,iterator)
	return foundlabel
end

function ENT:GetValidValue(labelname)
	local sign = 1
	if (labelname == "") then return 0 end
	if (string.sub(labelname,1,1) == "-") then
		labelname = string.sub(labelname,2)
		sign = -1
	end
	if (tonumber(labelname)) then
		return sign*(tonumber(labelname))
	else
		local foundlabel = self:GetLabel(labelname)

		if (foundlabel) then
			return sign*(foundlabel.WIP+self.OffsetWIP)
		else
			if (not self.FirstPass) then
				self:Error("Expected number or a valid label")
			end
			return 0
		end
	end
end

function ENT:GetAlwaysValidValue(labelname)
	local sign = 1
	if (labelname == "") then return 0 end
	if (string.sub(labelname,1,1) == "-") then
		labelname = string.sub(labelname,2)
		sign = -1
	end
	if (tonumber(labelname)) then
		return sign*(tonumber(labelname))
	else
		local foundlabel = self:GetLabel(labelname)

		if (foundlabel) then
			return sign*(foundlabel.WIP+self.OffsetWIP)
		else
			self:Error("Expected number or a valid label, defined BEFORE this line")
			return 0
		end
	end
end

function ENT:SetLabel(labelname,value)
	if (self.Labels[labelname]) then
		self.Labels[labelname].WIP = value
	else
		self.Labels[labelname] = {}
		self.Labels[labelname].WIP = self.WIP
		self.Labels[labelname].DefineLine = self.Line
	end
end

function ENT:AddLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:AddFunctionArgument(functionname,labelname,argno)
	if (self.FirstPass) then
		if (not self:GetLabel(functionname)) then
			self:Error("Internal error - report to black phoenix! (code AF8828Z8A)")
		end

		if (self.Labels[functionname].Param[labelname]) then
			self:Error("Function parameter '"..labelname.."' already exists)")
		else
			if (not self.Labels[functionname].Param) then
				self.Labels[functionname].Param = {}
			end
			self.Labels[functionname].Param[labelname] = {}
			self.Labels[functionname].Param[labelname].Arg = argno
			self.FunctionParams[labelname] = true
		end
	end
end

function ENT:AddLocalLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
			self.Labels[labelname].Local = true
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) && (math.abs(self.WIP - self.Labels[labelname].WIP) < self.LocalVarRange) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:AddGlobalLabel(labelname)
	if (self.FirstPass) then
		if (self:GetLabel(labelname)) then
			self:Error("Label '"..labelname.."' already exists (previously defined at line "..self.Labels[labelname].DefineLine..")")
		else
			self.Labels[labelname] = {}
			self.Labels[labelname].WIP = self.WIP
			self.Labels[labelname].DefineLine = self.Line
			self.Labels[labelname].Global = true
		end
	else
		if (self.Labels[labelname]) then
			if (self.Labels[labelname].WIP ~= self.WIP) then
				self.Labels[labelname].WIP = self.WIP
				self:Error("Label pointer changed between stages - report this to Black Phoenix!")
			end
		end
	end
end

function ENT:WipeLocals()
	for labelk,labelv in pairs(self.Labels) do
		if (labelv.Local) then
			self.Labels[labelk] = nil
		end
	end
end

function ENT:WipeLabels()
	//for labelk,labelv in pairs(self.Labels) do
	iterator = function (labelk,labelv)
		self.Labels[labelk].Ignore = true
	end
	table.foreach(self.Labels,iterator)
end
