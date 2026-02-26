local Test = {}

function Test.Run(CPU,TestSuite)
	TestSuite:Deploy(CPU, "MOV PORT0,1 MOV R0,PORT0",  Test.CompileError)
	local IOBus = TestSuite.CreateVirtualIOBus(4) -- get external IO device of size 4
	TestSuite.Initialize(CPU, nil, IOBus) -- reinitialize the CPU with the IOBus
	
	IOBus.InPorts[0] = 24
	CPU.Clk = 1
	for i = 0, 16 do
		CPU:RunStep()
	end

	-- False = no error, True = error
	assert(IOBus:ReadCell(0) == 24, "IOBus InPort 0 != 24! Possibly CPU's fault? InPort 0 = " .. IOBus:ReadCell(0))
	assert(IOBus.OutPorts[0] == 1, "CPU failed to write to output port! Port0 = " .. tostring(IOBus.OutPorts[0]))
	assert(CPU.R0 == 24, "CPU failed to read input port! R0 = " .. CPU.R0)
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test