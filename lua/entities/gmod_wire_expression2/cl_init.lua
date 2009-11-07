include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

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
	local status, tree, dvars = Parser.Execute(tokens)
	if not status then return tree end

	-- invoke compiler
	local status, result = Compiler.Execute(tree, inports[3], outports[3], persists[3], dvars)
	if not status then return result end
end

-- On the server we need errors instead of return values, so we wrap and throw errors.
if SERVER then
	local _wire_expression2_validate = wire_expression2_validate
	function wire_expression2_validate(...)
		local msg = _wire_expression2_validate(...)
		if msg then error(msg,0) end
	end
end
