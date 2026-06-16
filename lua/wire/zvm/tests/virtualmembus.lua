local Test = {}

function Test.Run(CPU,TestSuite)
	TestSuite:Deploy(CPU,"CPUGET R0,43 MOV [R0],1 MOV R1,[R0]",Test.CompileError)
	local bus = TestSuite.CreateVirtualMemBus(4) -- get external ram device of size 4
	TestSuite.Initialize(CPU, bus, nil) -- reinitialize the CPU with the membus
	CPU.Clk = 1
	for i = 0, 16 do
		CPU:RunStep()
	end

	assert(bus:ReadCell(0) == 1, "CPU failed to write to bus! " .. tostring(bus:ReadCell(0)))
	assert(CPU.R1 == 1, "CPU failed to read the bus! R1 was " .. CPU.R1)
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test