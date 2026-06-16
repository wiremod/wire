local Test = {}

function Test.Run(CPU,TestSuite)
	TestSuite.Compile("MOV R0,6 ADD R0,R0 MUL R0,2 DB 0", "internal", nil, Test.CompileError)
	-- end result of the above code should be R0 = 24
	local buff = TestSuite.GetCompileBuffer()
	local IOBus = TestSuite.CreateVirtualIOBus(#buff + 1) -- create an IOBus large enough to hold this code
	-- reverse the compiled code, the CPU will read them in reverse if it's in the IOBus
	-- because CS will be negative, and IP only increments

	-- ipairs won't index 0 and the cpu compile buffer uses 0
	for i = 0, #buff do
		IOBus.InPorts[#buff-i] = buff[i]
	end

	-- JMPF jumps to 0 IP, CS = (code length+1)*-1 because first index of IOBus is "cell -1" of extern read/write
	local generatedcode = "CMP R0,0 JNER -3 JMPF 0," .. (#buff + 1) * -1

	TestSuite:Deploy(CPU, generatedcode, Test.CompileError)
	TestSuite.Initialize(CPU, nil, IOBus) -- reinitialize the CPU with the IOBus
	CPU.Clk = 1
	for i = 0, 32 do
		CPU:RunStep()
	end

	-- On false, will cause test to fail with message
	assert(CPU.R0 == 24, "R0 != 24, R0 = " .. tostring(CPU.R0))
end


function Test.CompileError(msg)
	assert(false, "compile time error " .. msg)
end

return Test