local Test = {}

function Test.Run(CPU,TestSuite)
	return TestSuite.Compile("MOV R0,", nil, Test.CompileSucceed)
end

function Test.CompileSucceed()
	assert(false, "Compiler should have errored!")
end

return Test