local Test = {}

function Test.Run(CPU,TestSuite)
	TestSuite:Deploy(CPU,"x: INC R0 JMP x",Test.CompileError)
	CPU.Clk = 1
	-- Run the VM for 4096 cycles
	for i = 0, 4096 do
		CPU:RunStep()
	end

	-- On false, will cause test to fail with message
	assert(CPU.R0 == 4096,"R0 is not 4096! R0 is " .. tostring(CPU.R0))
end

function Test.CompileError(msg)
	assert(false,"compile time error: " .. msg)
end

return Test