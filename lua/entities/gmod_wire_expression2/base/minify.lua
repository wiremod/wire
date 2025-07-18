AddCSLuaFile()

local Warning, Error = E2Lib.Debug.Warning, E2Lib.Debug.Error
local Token, TokenVariant = E2Lib.Tokenizer.Token, E2Lib.Tokenizer.Variant
local Node, NodeVariant = E2Lib.Parser.Node, E2Lib.Parser.Variant
local Keyword, KeywordNames = E2Lib.Keyword, E2Lib.KeywordNames

local pairs, ipairs = pairs, ipairs

local function printTableRecursive(t, printedTables, indent)
    printedTables = printedTables or {}
    indent = indent or ""
    
    if printedTables[t] then
        print(indent .. "(already printed)")
        return
    end
    
    printedTables[t] = true
    
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. k .. ": {")
            printTableRecursive(v, printedTables, indent .. "    ")
            print(indent .. "},")
        else
            print(indent .. k .. ": " .. tostring(v) .. ",")
        end
    end
end

local Operators = {
	"+",
	"-",
	"*",
	"/",
	"%",
	"^",
	"=",
	"+=",
	"-=",
	"*=",
	"/=",
	"++",
	"--",
	"==",
	"!=",
	"<",
	">=",
	"<=",
	">",
	"&&",
	"||",
	"^^",
	">>",
	"<<",
	"!",
	"&",
	"|",
	"?",
	":",
	"?:",
	"$",
	"~",
	"->",
	"..."
}

local MinifyTokenFuncs = {}
local MinifyNodeFuncs = {}

local function minifyNode(node,variable_names)
	if type(node) ~= "table" then
		print(node)
	end
	
    local func = MinifyNodeFuncs[node.variant]
    if func == nil then
        printTableRecursive(node)
        error("missing node variant [" .. node.variant .. "]")
    end
    return func(node,variable_names)
end

local function minifyToken(token,variable_names)
    local func = MinifyTokenFuncs[token.variant]
    if func == nil then 
        printTableRecursive(token)
        error("missing token variant [" .. token.variant .. "]")
    end
    return func(token,variable_names)
end

local function generateVariableName(variable_names)
	local lkup_vars = {}
	for k, v in pairs(variable_names) do
		lkup_vars[v] = k
	end
	
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	
	local name = "A"
	local length = 1
	
	repeat
        if lkup_vars[name] then
            local newName = ""
            local carry = true
            for i = #name, 1, -1 do
                local char = name:sub(i, i)
                if carry then
                    if char == "Z" then
                        newName = "A" .. newName
                    else
                        newName = charset:sub(charset:find(char) + 1, charset:find(char) + 1) .. newName
                        carry = false
                    end
                else
                    newName = char .. newName
                end
            end
            if carry then
                newName = "A" .. newName
            end
            name = newName
        else
            break
        end
    until false
	
	return name
end

MinifyTokenFuncs = {
    [TokenVariant.Keyword] = function(token,variable_names)
        return KeywordNames[token.value]:lower()
    end,
    [TokenVariant.Ident] = function(token,variable_names)
		if token.value == "This" then
			return "This"
		end
		
		if token.value == "_" then
			return "_"
		end
		
		if variable_names[token.value] ~= nil then
			return variable_names[token.value]
		end
		
		variable_names[token.value] = generateVariableName(variable_names)
        
		return variable_names[token.value]
    end,
    [TokenVariant.LowerIdent] = function(token,variable_names)
        return token.value
    end,
	[TokenVariant.Constant] = function(token,variable_names)
        return token.value
    end
}

MinifyNodeFuncs = {
    [NodeVariant.Block] = function(node,variable_names)
        local code = ""
        local count = #node.data
        for k, node in pairs(node.data) do
            code = code .. minifyNode(node,variable_names) .. (k < count and "," or "")
        end
        return code
    end,
    [NodeVariant.If] = function(node,variable_names)
        local code = ""
        for k, chain in pairs(node.data) do
            local cond = chain[1]
            local block = chain[2]
			code = code .. (cond ~= nil and ((k == 1 and "if(" or "elseif(") .. minifyNode(cond,variable_names) .. "){" .. minifyNode(block,variable_names) .. "}") or ("else{" .. minifyNode(block,variable_names) .. "}"))
        end
        return code
    end,
	[NodeVariant.While] = function(node,variable_names)
		local code = ""
		local cond = node.data[1]
		local block = node.data[2]
		local dowhile = node.data[3]
		return dowhile and ("do{" .. minifyNode(block,variable_names) .. "}while(" .. minifyNode(cond,variable_names) .. ")") or ("while(" .. minifyNode(cond,variable_names) .. "){" .. minifyNode(block,variable_names) .. "}")
	end,
	[NodeVariant.For] = function(node,variable_names)
		local var = node.data[1]
		local start = node.data[2]
		local stop = node.data[3]
		local step = node.data[4]
		local block = node.data[5]
		return "for(" .. minifyToken(var,variable_names) .. "=" .. minifyNode(start,variable_names) .. "," .. minifyNode(stop,variable_names) .. (step ~= nil and "," .. minifyNode(step,variable_names) or "") .. "){" .. minifyNode(block,variable_names) .. "}"
	end,
	[NodeVariant.Foreach] = function(node,variable_names)
		local key = node.data[1]
		local key_type = node.data[2]
		local value = node.data[3]
		local value_type = node.data[4]
		local container = node.data[5]
		local block = node.data[6]
		return "foreach(" .. minifyToken(key,variable_names) .. (key_type ~= nil and ":" .. minifyToken(key_type,variable_names) or "") .. "," .. minifyToken(value,variable_names) .. (value_type ~= nil and ":" .. minifyToken(value_type,variable_names) or "") .. "=" .. minifyNode(container,variable_names) .. "){" .. minifyNode(block,variable_names) .. "}"
	end,
	[NodeVariant.Break] = function(node,variable_names)
		return "break"
	end,
	[NodeVariant.Continue] = function(node,variable_names)
		return "continue"
	end,
	[NodeVariant.Return] = function(node,variable_names)
		if node.data ~= nil then
			return "return " .. minifyNode(node.data,variable_names)
		end
		return "return"
	end,
	[NodeVariant.Increment] = function(node,variable_names)
		return minifyToken(node.data,variable_names) .. "++"
	end,
	[NodeVariant.Decrement] = function(node,variable_names)
		return minifyToken(node.data,variable_names) .. "--"
	end,
	[NodeVariant.CompoundArithmetic] = function(node,variable_names)
		return minifyToken(node.data[1],variable_names) .. Operators[node.data[2]] .. "=" .. minifyNode(node.data[3],variable_names)
	end,
    [NodeVariant.Assignment] = function(node,variable_names)
        local code = ""
		
        local is_local = node.data[1]
        if is_local ~= nil then
            code = code .. minifyToken(is_local,variable_names) .. " "
        end
		
        local assignments = node.data[2]
        for k, assignment in pairs(assignments) do
            local token = assignment[1]
			local indices = assignment[2]
			
			code = code .. minifyToken(token,variable_names)
			if indices ~= nil then
				for i, index in pairs(indices) do
					code = code .. "[" .. minifyNode(index[1],variable_names) .. (index[2] ~= nil and "," .. minifyToken(index[2],variable_names) or "") .. "]"
				end
				code = code .. "="
			else
				code = code .. minifyToken(token,variable_names) .. "="
			end
        end
		
        local expr = node.data[3]
        code = code .. minifyNode(expr,variable_names)
		
        return code
    end,
	[NodeVariant.Const] = function(node,variable_names)
		return "const " .. minifyToken(node.data[1],variable_names) .. "=" .. minifyNode(node.data[2],variable_names)
	end,
	[NodeVariant.Switch] = function(node,variable_names)
		local expr = node.data[1]
		local cases = node.data[2]
		local default = node.data[3]

		local code = "switch(" .. minifyNode(expr,variable_names) .. "){"
        for k, case in pairs(cases) do
            code = code .. "case " .. minifyNode(case[1],variable_names) .. "," .. minifyNode(case[2],variable_names) .. " "
        end

		if default ~= nil then
			code = code .. "default," .. minifyNode(default,variable_names) .. " "
		end

        return code .. "}"
	end,
	[NodeVariant.Function] = function(node,variable_names)
		local code = "function" .. 
			(node.data[1] ~= nil and (" " .. minifyToken(node.data[1],variable_names)) or "")  .. 
			(node.data[2] ~= nil and (" " .. minifyToken(node.data[2],variable_names) .. ":") or "") .. 
			" " .. minifyToken(node.data[3],variable_names) .. "("

		local count = #node.data[4]
		for k, param in pairs(node.data[4]) do
			code = code .. minifyToken(param.name,variable_names) .. ":" .. minifyToken(param.type,variable_names) .. (k < count and "," or "")
		end
		code = code .. "){" .. minifyNode(node.data[5],variable_names) .. "}"
		return code
	end,
	--TODO: handle including other files
	[NodeVariant.Include] = function(node,variable_names)
		return "#include \"" .. node.data .. "\""
	end,
	[NodeVariant.Try] = function(node,variable_names)
		local ty = node.data[3]
		return "try{" .. minifyNode(node.data[1],variable_names) .. "}catch(" .. minifyToken(node.data[2],variable_names) .. (node.data[3] ~= nil and ":" .. minifyToken(node.data[3],variable_names) or "") .. "){" .. minifyNode(node.data[4],variable_names) .. "}"
	end,
	[NodeVariant.Event] = function(node,variable_names)
		local code = "event " .. minifyToken(node.data[1],variable_names) .. "("
		local count = #node.data[2]
		for k, param in pairs(node.data[2]) do
			code = code .. minifyToken(param.name,variable_names) .. ":" .. minifyToken(param.type,variable_names) .. (k < count and "," or "")
		end
		code = code .. "){" .. minifyNode(node.data[3],variable_names) .. "}"
		return code
	end,
	[NodeVariant.ExprTernary] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. "?" .. minifyNode(node.data[2],variable_names) .. " :" .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprDefault] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. "?:" .. minifyNode(node.data[2],variable_names) .. ")"
	end,
	[NodeVariant.ExprLogicalOp] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprBinaryOp] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprComparison] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprEquals] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprBitShift] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")"
	end,
	[NodeVariant.ExprArithmetic] = function(node,variable_names)
		return "(" .. minifyNode(node.data[1],variable_names) .. Operators[node.data[2]] .. minifyNode(node.data[3],variable_names) .. ")" 
	end,
	[NodeVariant.ExprUnaryOp] = function(node,variable_names)
		return "(" .. Operators[node.data[1]] .. minifyNode(node.data[2],variable_names)  .. ")"
	end,
	[NodeVariant.ExprMethodCall] = function(node,variable_names)
		local code = minifyNode(node.data[1],variable_names) .. ":" .. minifyToken(node.data[2],variable_names) .. "("
		local arguments = node.data[3]
        for k, arg in pairs(arguments) do
            code = code .. minifyNode(arg,variable_names) .. (k < #arguments and "," or "")
        end
		return code .. ")"
	end,
	[NodeVariant.ExprIndex] = function(node,variable_names)
		local code = minifyNode(node.data[1],variable_names)
		for i, index in pairs(node.data[2]) do
			code = code .. "[" .. minifyNode(index[1],variable_names) .. (index[2] ~= nil and "," .. minifyToken(index[2],variable_names) or "") .. "]"
		end
		return code
	end,
    [NodeVariant.ExprCall] = function(node,variable_names)
        local code = ""
        code = code .. minifyToken(node.data[1],variable_names) .. "("
        
        local arguments = node.data[2]
        for k, arg in pairs(arguments) do
            code = code .. minifyNode(arg,variable_names) .. (k < #arguments and "," or "")
        end
        return code .. ")"
    end,
	[NodeVariant.ExprDynCall] = function(node,variable_names)
        local code = ""
        code = code .. minifyNode(node.data[1],variable_names) .. "("
        
        local arguments = node.data[2]
        for k, arg in pairs(arguments) do
            code = code .. minifyNode(arg,variable_names) .. (k < #arguments and "," or "")
        end
        return code .. ")" .. (node.data[3] ~= nil and ("[" .. minifyToken(node.data[3],variable_names) .. "]") or "")
    end,
	[NodeVariant.ExprUnaryWire] = function(node,variable_names)
		return Operators[node.data[1]] .. minifyToken(node.data[2],variable_names)
	end,
	[NodeVariant.ExprArray] = function(node,variable_names)
		local code = "array("
		local count = #node.data
		for k, keypair in pairs(node.data) do
			if keypair[2] == nil then
				code = code .. minifyNode(keypair,variable_names) .. (k < count and "," or "")
			else
				code = code .. minifyNode(keypair[1],variable_names) .. "=" .. minifyNode(keypair[2],variable_names) .. (k < count and "," or "")
			end
		end
		return code .. ")"
	end,
	[NodeVariant.ExprTable] = function(node,variable_names)
		local code = "table("
		local count = #node.data
		for k, keypair in pairs(node.data) do
			if keypair[2] == nil then
				code = code .. minifyNode(keypair,variable_names) .. (k < count and "," or "")
			else
				code = code .. minifyNode(keypair[1],variable_names) .. "=" .. minifyNode(keypair[2],variable_names) .. (k < count and "," or "")
			end
		end
		return code .. ")"
	end,
	[NodeVariant.ExprFunction] = function(node,variable_names)
		local code = "function("
		local count = #node.data[1]
		for k, param in pairs(node.data[1]) do
			code = code .. minifyToken(param.name,variable_names) .. ":" .. minifyToken(param.type,variable_names) .. (k < count and "," or "")
		end
		code = code .. "){" .. minifyNode(node.data[2],variable_names) .. "}"
		return code
	end,
	[NodeVariant.ExprLiteral] = function(node,variable_names)
        local type = node.data[1]
        local value = node.data[2]
		
        if type == "s" then
            return "\"" .. value .. "\""
        elseif type == "n" then
            return value 
        end
		
        return value
    end,
    [NodeVariant.ExprIdent] = function(node,variable_names)
        return minifyToken(node.data,variable_names)
    end,
	[NodeVariant.ExprConstant] = function(node,variable_names)
        return minifyToken(node.data,variable_names)
    end
}

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

function E2Lib.Minify(buffer)
	if not e2_function_data_received then return "" end
	
	local status, directives, buffer, preprocessor = E2Lib.PreProcessor.Execute(buffer)
	if not status then return "" end
	
	RunConsoleCommand("wire_expression2_scriptmodel", directives.model or "")
	
	local status, tokens, tokenizer = E2Lib.Tokenizer.Execute(buffer)
	if not status then return "" end
	
	local status, tree, dvars, files, parser = E2Lib.Parser.Execute(tokens)
	if not status then return "" end
	
	local strdirectives = ""
	strdirectives = strdirectives .. (trim(directives.name) ~= "" and "@name " .. trim(directives.name) or "")
	
	local lkup_types = {}
	for name, etype in pairs(wire_expression_types) do
		lkup_types[etype[1]] = name:lower()
	end
	lkup_types["n"] = nil
	
	local variable_names = {}
	
	if #directives.inputs[1] > 0 then
		strdirectives = strdirectives .. (strdirectives ~= "" and "\n" or "") .. "@inputs "
		local count = #directives.inputs[2]
		for k, name in pairs(directives.inputs[1]) do
			if variable_names[name] == nil then
				variable_names[name] = name
			end
			strdirectives = strdirectives .. variable_names[name] .. (lkup_types[directives.inputs[2][k]] ~= nil and ":" .. lkup_types[directives.inputs[2][k]] or "") .. (k < count and " " or "")
		end
	end
	
	if #directives.outputs[1] > 0 then
		strdirectives = strdirectives .. (strdirectives ~= "" and "\n" or "") .. "@outputs "
		local count = #directives.outputs[2]
		for k, name in pairs(directives.outputs[1]) do
			if variable_names[name] == nil then
				variable_names[name] = name
			end
			strdirectives = strdirectives .. variable_names[name] .. (lkup_types[directives.outputs[2][k]] ~= nil and ":" .. lkup_types[directives.outputs[2][k]] or "") .. (k < count and " " or "")
		end
	end
	
	if #directives.persist[1] > 0 then
		strdirectives = strdirectives .. (strdirectives ~= "" and "\n" or "") .. "@persist "
		local count = #directives.persist[2]
		for k, name in pairs(directives.persist[1]) do
			if variable_names[name] == nil then
				variable_names[name] = name
			end
			strdirectives = strdirectives .. variable_names[name] .. (lkup_types[directives.persist[2][k]] ~= nil and ":" .. lkup_types[directives.persist[2][k]] or "") .. (k < count and " " or "")
		end
	end
	
	if directives.trigger[1] == false then
		strdirectives = strdirectives .. (strdirectives ~= "" and "\n" or "") .. "@trigger "
		local count = #directives.trigger[2]
		local k = 1
		for name, _ in pairs(directives.trigger[2]) do
			if variable_names[name] == nil then
				variable_names[name] = name
			end
			strdirectives = strdirectives .. variable_names[name] .. (k < count and " " or "")
			k = k + 1
		end
		strdirectives = strdirectives
	end
	
	local code = MinifyNodeFuncs[tree.variant](tree,variable_names)
	if strdirectives == "" then
		return code
	else
		return strdirectives .. "\n" .. code
	end
end