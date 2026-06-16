local Test = {}

-- If Test.Files is present, the compiler and suite will read files from it instead of the test directory
Test.Files = {
	["file_example.txt"] = [[
x:
INC R0
JMP x
	]]
}

function Test.Run(CPU,TestSuite)
	-- Use the suite to load the file from our provided files table
	local code = TestSuite:LoadFile("file_example.txt")
	TestSuite:Deploy(CPU,code,Test.CompileError)
	CPU.Clk = 1
	-- Run the VM for 4096 cycles
	for i = 0, 4096 do
		CPU:RunStep()
	end

	-- On false, will cause test to fail with message
	assert(CPU.R0 == 4096, "R0 is not 4096! R0 is " .. tostring(CPU.R0))
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test