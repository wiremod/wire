local Test = {}

Test.Files = {
	["includes_1.txt"] = [[
#include <includes_2.txt>
ADD R0,1
]],

	["includes_2.txt"] = [[
MOV R0,1
]]
}

function Test.Run(CPU,TestSuite)
	local src = TestSuite:LoadFile("includes_1.txt")
	TestSuite:Deploy(CPU, src, Test.CompileError)
	CPU.Clk = 1
	for i = 0, 16 do
		CPU:RunStep()
	end

	assert(CPU.R0 == 2, "R0 is not 2! R0 is " .. tostring(CPU.R0))
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test