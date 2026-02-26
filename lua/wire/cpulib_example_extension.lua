if not CPULib then
	include("wire/cpulib.lua")	
end

-- Returns false if extension is already created/registered
local myCPUExtension = CPULib:CreateExtension("cpu_test","CPU")

if myCPUExtension then
	-- Creates a function using the raw ZVM API, make your function similar to the ones in zvm_opcodes.lua
	-- Args:
	-- Name, Operands, OpFunc, Flags, Documentation (missing entries are autofilled)
	myCPUExtension:RegisterInstruction(
		"CPU_TEST1",
		1,
		function(self)
			self:Dyn_EmitOperand("42")
		end,
		{"W1"},
		{
			Version = 0.42,
			Description = "Sets Register X to constant 42"
		}
	)

	-- Example of how to reassign the value of the first operand used to itself divided by 24
	local function myLuaInstruction(VM,Operands)
		if Operands[1] > 49 or Operands[1] < 40 then
			-- Call interrupt 5 with argument showing the value of Operand 1
			-- Error code to user would look something like 5.039 if Operand 1 = 39
			return 5, Operands[1]
		end
		Operands[1] = Operands[1]/24
	end

	-- Works like RegisterInstruction but it will call the passed lua function.
	-- Args:
	-- Name, Operands, LuaFunc, Flags, Documentation (missing entries are autofilled)
	myCPUExtension:InstructionFromLuaFunc(
		"CPU_TEST2",
		1,
		myLuaInstruction,
		{"W1"},
		{
			Version = 0.42,
			Description = "Divides Register X by constant 24, Produces Error 5 if not between 40 and 49"
		}
	)
end
-- Below is the structure of the actual extension, incase you'd rather register them yourself.
local myGPUExtension = {
	Platform = "GPU",
	Instructions = {{
		Name = "GPU_TEST1",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Sets Register X to constant 42",
		["OpFunc"] = function(self)
			-- The end value of the code in Dyn_EmitOperand will be assigned
			-- to the first/left hand register used in this instruction
			self:Dyn_EmitOperand("42")
		end
	},
	{
		Name = "GPU_TEST2",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Divides Register X by constant 24",
		["OpFunc"] = function(self)
			-- $1 and $2 refer to the first, and second operands of the instruction respectively
			self:Dyn_EmitOperand("$1/24")
		end
	}}
}

CPULib:RegisterExtension("gpu_test", myGPUExtension)
