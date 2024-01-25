local Test = {}


function Test.Run(CPU,TestSuite)
	TestSuite.Compile("MOV R0,1", "internal", nil, Test.CompileError)
	local buff = TestSuite.GetCompileBuffer()
	local bus = TestSuite.CreateVirtualMemBus(#buff) -- get external ram device large enough to hold program
	TestSuite.FlashData(bus, buff) -- upload compiled to membus
	CPU.RAMSize = 0
	CPU.ROMSize = 0
	TestSuite.Initialize(CPU, bus, nil) -- reinitialize the CPU with the membus
	CPU.Clk = 1
	for i = 0, 16 do
		CPU:RunStep()
	end

	assert(CPU.R0 == 1, "CPU with no ram/rom failed to execute code from bus! R0 = " .. CPU.R0)
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test