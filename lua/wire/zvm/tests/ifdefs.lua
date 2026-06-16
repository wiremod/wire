local Test = {}

Test.Files = {
	["ifdefs.txt"] = [[
/*defs will be added programatically*/

#ifdef x
#define z
#pragma cpuname Test X
    ALLOC 1
#ifdef y
#ifdef x
#pragma cpuname Test X and Y
#endif
    ALLOC 2
#endif
//not x
#else 
    ALLOC 4
#endif

#ifdef y
#ifndef x
#pragma cpuname Test Y
#endif
ALLOC 8
#endif
/*
#ifdef y
    ALLOC 8
#endif
*/
//above comment intentional for making sure ifdef handler doesn't skip into the middle of a comment
]]
}

--not x and y = 14, name "Test Y"
-- x and y = 11, name "Test Y"
-- x and not y = 1, name "Test Y"

-- culling update
-- not x and y = 12, name "Test Y"
-- x and y = 11, name "Test X and Y"
-- x and not y = 1, name "Test X"

Test.ExpectedVariations1 = {"X", "Y", "X and Y", "Y", "Y", "Y"} -- CPU Name vars
Test.ExpectedVariations2 = {1, 12, 11, 1, 14, 11}
Test.ResultVariations1 = {}
Test.ResultVariations2 = {}

Test.Variations1 = {"true", "false"}
Test.Variations2 = {"#define x\n", "#define y\n", "#define x\n#define y\n"}
Test.Variation1Index = 1
Test.Variation2Index = 1

function Test.Run(CPU,TestSuite)
	Test.TestSuite = TestSuite
	Test.Src = TestSuite:LoadFile("ifdefs.txt")
	Test.CompileNext()
end

function Test.CompileNext()
	local cursrc
	if Test.Variation1Index <= #Test.Variations1 then
		cursrc = "#pragma set NewIfDefs " .. Test.Variations1[Test.Variation1Index] .. "\n"
	else
		return Test.CompareResults()
	end
	if Test.Variation2Index <= #Test.Variations2 then
		cursrc = cursrc .. Test.Variations2[Test.Variation2Index] .. "\n" .. Test.Src
		Test.TestSuite.Compile(cursrc,nil,Test.LogResults,Test.CompileError)
	else
		Test.Variation1Index = Test.Variation1Index + 1
		Test.Variation2Index = 1
		Test.CompileNext()
	end
end

function Test.LogResults()
	Test.ResultVariations1[Test.Variation2Index + #Test.Variations2*(Test.Variation1Index-1)] = Test.TestSuite.GetCPUName() or "ERROR"
	Test.ResultVariations2[Test.Variation2Index + #Test.Variations2*(Test.Variation1Index-1)] = #Test.TestSuite.GetCompileBuffer() + 1 or "ERROR"
	Test.Variation2Index = Test.Variation2Index + 1
	Test.CompileNext()
end

function Test.CompareResults()
	local fail, results1, results2 = false, {}, {}
	for ind, i in ipairs(Test.ExpectedVariations1) do
		if Test.ResultVariations1[ind] == "Test " .. i then
				results1[ind] = true
			else
				fail = true
				results1[ind] = false
		end
	end
	for ind, i in ipairs(Test.ExpectedVariations2) do
		if Test.ResultVariations2[ind] == i then
			results2[ind] = true
		else
			fail = true
			results2[ind] = false
		end
	end
	if fail then
		PrintTable({Test.ResultVariations1, results1, Test.ResultVariations2, results2})
		assert(false, "Unexpected Test Results!")
	end
	return
end

function Test.CompileError(msg)
	assert(false, "compile time error: " .. msg)
end

return Test