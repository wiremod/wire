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

registerCallback("construct", function(self) self.strfunc_cache = {} end)

local insert = table.insert
local concat = table.concat
local function findFunc( self, funcname, typeids, typeids_str )
	local func, func_return_type, vararg
	
	self.prf = self.prf + 40
	
	local str = funcname .. "(" .. typeids_str .. ")"
	for i=1,#self.strfunc_cache do
		local t = self.strfunc_cache[i]
		if t[1] == str then
			return t[2], t[3], t[4]
		end
	end
	
	self.prf = self.prf + 40
	
	if #typeids > 0 then
		if not func then
			func, func_return_type = checkFuncName( self, str )
		end
		
		if not func then
			func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" .. concat(typeids,"",2) .. ")" )
		end
		
		if not func then
			for i=#typeids,1,-1 do
				func, func_return_type = checkFuncName( self, funcname .. "(" .. concat(typeids,"",1,i) .. "...)" )
				if func then vararg = true break end
			end
			
			if not func then
				func, func_return_type = checkFuncName( self, funcname .. "(...)" )
				if func then vararg = true end
			end
		end
		
		if not func then
			for i=#typeids,2,-1 do
				func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" ..  concat(typeids,"",2,i) .. "...)" )
				if func then vararg = true break end
			end
			
			if not func then
				func, func_return_type = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":...)" )
				if func then vararg = true end
			end
		end
	else
		func, func_return_type = checkFuncName( self, funcname .. "()" )
	end
	
	if func then
		local t = { str, func, func_return_type, vararg }
		insert( self.strfunc_cache, 1, t )
		if #self.strfunc_cache == 21 then self.strfunc_cache[21] = nil end
	end
	
	return func, func_return_type, vararg
end

__e2setcost(20)

registerOperator( "sfun", "", "", function(self, args)
	local op1, funcargs, typeids, typeids_str, returntype = args[2], args[3], args[4], args[5], args[6]
	local funcname = op1[1](self,op1)

	local func, func_return_type, vararg = findFunc( self, funcname, typeids, typeids_str )
	
	if not func then error( "No such function: " .. funcname .. "(" .. tps_pretty( typeids_str ) .. ")", 0 ) end
	
	if returntype ~= "" and func_return_type ~= returntype then
		error( "Mismatching return types. Got " .. nicename(wire_expression_types2[returntype][1]) .. ", expected " .. nicename(wire_expression_types2[func_return_type][1] ), 0 )
	end
	
	self.prf = self.prf + 40
	
	if vararg then funcargs[#funcargs+1] = typeids end -- if this is a vararg func, we need to send the typeids as well
	
	if returntype ~= "" then
		local ret = func( self, funcargs )
		if vararg then funcargs[#funcargs] = nil end -- clean up
		return ret
	else
		func( self, funcargs )
		if vararg then funcargs[#funcargs] = nil end -- clean up
	end
end)
