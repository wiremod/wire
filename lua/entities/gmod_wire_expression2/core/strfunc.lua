local function nicename( word )
	local ret = word:lower()
	if ret == "normal" then return "number" end
	return ret
end

local function checkFuncName( self, funcname )
	if self.funcs[funcname] then
		return self.funcs[funcname], self.funcs_ret[funcname]
	elseif wire_expression2_funcs[funcname] then
		return wire_expression2_funcs[funcname][3], wire_expression2_funcs[funcname][2]
	end
end

local function findFunc( self, funcname, typeids, typeids_str )
	local func, func_return_type = checkFuncName( self, funcname .. "()" )
	
	if #typeids > 0 then
		if not func then
			func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids_str .. ")" )
		end
		
		if not func then
			func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" .. table.concat(typeids,"",2) .. ")" )
		end
		
		if not func then
			for i=#typeids,1,-1 do
				func, func_return_type = checkFuncName( self, funcname .. "(" .. table.concat(typeids,"",1,i) .. "...)" )
				if func then break end
			end
			
			if not func then
				func, func_return_type = checkFuncName( self, funcname .. "(...)" )
			end
		end
		
		if not func then
			for i=#typeids,2,-1 do
				func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" ..  table.concat(typeids,"",2,i) .. "...)" )
				if func then break end
			end
			
			if not func then
				func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":...)" )
			end
		end
	end
	
	return func, func_return_type
end

registerOperator( "sfun", "", "", function(self, args)
	local op1, funcargs, typeids, typeids_str, returntype = args[2], args[3], args[4], args[5], args[6]
	local funcname = op1[1](self,op1)

	local func, func_return_type = findFunc( self, funcname, typeids, typeids_str )
	
	if not func then error( "No function with the specified arguments exists", 0 ) end
	
	if returntype ~= "" and func_return_type ~= returntype then
		error( "Mismatching return types. Got " .. nicename(wire_expression_types2[returntype][1]) .. ", expected " .. nicename(wire_expression_types2[func_return_type][1] ), 0 )
	end
	
	if returntype ~= "" then
		return func( self, funcargs )
	else
		func( self, funcargs )
	end
end)