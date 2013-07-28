include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

local function Include(e2, directives, includes, scripts)
	if scripts[e2] then
		return
	end
	
	local code
	
	if CLIENT then
		code = file.Read("expression2/" .. e2 .. ".txt")
	end
	
	if !code then
		return false, "Could not find include '" .. e2 .. ".txt'"
	end
	
	local status, err, buffer = PreProcessor.Execute(code, directives)
	if not status then
		return "include '" .. e2 .. "' -> " .. err
	end
	
	local status, tokens = Tokenizer.Execute(buffer)
	if not status then
		return "include '" .. e2 .. "' -> " .. tokens
	end
	
	local status, tree, dvars, files = Parser.Execute(tokens)
	if not status then
		return "include '" .. e2 .. "' -> " .. tree
	end
	
	includes[e2] = code
	
	scripts[e2] = {tree}
	
	for i = 1, #files do
		local error = Include(files[i], directives, includes, scripts)
		if error then return error end
	end
	
end

function wire_expression2_validate(buffer)
	if CLIENT and not e2_function_data_received then return "Loading extensions. Please try again in a few seconds..." end

	-- invoke preprocessor
	local status, directives, buffer = PreProcessor.Execute(buffer)
	if not status then return directives end

	-- decompose directives
	local inports, outports, persists = directives.inputs, directives.outputs, directives.persist
	if CLIENT then RunConsoleCommand("wire_expression2_scriptmodel", directives.model or "") end

	-- invoke tokenizer (=lexer)
	local status, tokens = Tokenizer.Execute(buffer)
	if not status then return tokens end

	-- invoke parser
	local status, tree, dvars, files = Parser.Execute(tokens)
	if not status then return tree end
	
	-- prepare includes
	local includes, scripts = {}, {}
	for i = 1, #files do
		local error = Include(files[i], directives, includes, scripts)
		if error then return error end
	end
	
	-- invoke compiler
	local status, script, instance = Compiler.Execute(tree, inports[3], outports[3], persists[3], dvars, scripts)
	if not status then return script end
	
	return nil, includes
end

-- On the server we need errors instead of return values, so we wrap and throw errors.
if SERVER then
	local _wire_expression2_validate = wire_expression2_validate
	function wire_expression2_validate(...)
		local msg = _wire_expression2_validate(...)
		if msg then error(msg,0) end
	end
end
