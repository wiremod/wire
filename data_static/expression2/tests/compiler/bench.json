local t = {}
for i = 1, 600 do
	t[i] = i
end

local script = "array(" .. table.concat(t, ",") .. ")"

local o1, o2, o3 = debug.gethook()

debug.sethook(error, "", 1e6)

local _, code_ok, compiled = pcall(E2Lib.compileScript, script)

debug.sethook(o1, o2, o3)

assert(code_ok, "Took too long to compile!")

debug.sethook(error, "", 1e6)

local ok = pcall(compiled)

debug.sethook(o1, o2, o3)

assert(ok, "Took too long to run!")