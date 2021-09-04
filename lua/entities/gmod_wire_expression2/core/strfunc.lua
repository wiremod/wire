local function nicename( word )
	local ret = word:lower()
	if ret == "normal" then return "number" end
	return ret
end

local function checkFuncName( self, funcname )
	if self.funcs[funcname] then
		return self.funcs[funcname], self.funcs_ret[funcname], true
	elseif wire_expression2_funcs[funcname] then
		return wire_expression2_funcs[funcname][3], wire_expression2_funcs[funcname][2]
	end
end

registerCallback("construct", function(self) self.strfunc_cache = {{}, {}} end)

local insert = table.insert
local concat = table.concat
local function findFunc( self, funcname, typeids, typeids_str )
	local func, func_return_type, func_custom
	local cache = self.strfunc_cache[1]

	local str = funcname .. "(" .. typeids_str .. ")"

	if cache[str] then
		if cache[str][4] then self.prf = self.prf + 15 end
		return cache[str][1], cache[str][2]
	end

	local typeIDsLength = #typeids
	self.prf = self.prf + 5

	if typeIDsLength > 0 then
		if not func then
			func, func_return_type, func_custom = checkFuncName( self, str )
		end

		if not func then
			func, func_return_type, func_custom = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" .. concat(typeids,"",2) .. ")" )
		end

		if not func then
			for i = typeIDsLength, 1, -1 do
				func, func_return_type, func_custom = checkFuncName( self, funcname .. "(" .. concat(typeids,"",1,i) .. "...)" )
				if func then break end
			end

			if not func then
				func, func_return_type, func_custom = checkFuncName( self, funcname .. "(...)" )
			end
		end

		if not func then
			for i = typeIDsLength, 2, -1 do
				func, func_return_type, func_custom = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":" ..  concat(typeids,"",2,i) .. "...)" )
				if func then break end
			end

			if not func then
				func, func_return_type, func_custom = checkFuncName( self, funcname .. "(" .. typeids[1] .. ":...)" )
			end
		end
	else
		func, func_return_type, func_custom = checkFuncName( self, funcname .. "()" )
	end

	if func then
		self.prf = self.prf + 20
		if self.funcs[str] then self.prf = self.prf + 15 end

		local limiter = self.strfunc_cache[2]
		local limiterLength = #limiter + 1

		cache[str] = { func, func_return_type, limiterLength, func_custom }
		insert( limiter, 1, str )

		if limiterLength == 101 then
			self.strfunc_cache[1][ limiter[101] ] = nil
			self.strfunc_cache[2][101] = nil
		end
	end

	return func, func_return_type
end

__e2setcost(5)

registerOperator( "stringcall", "", "", function(self, args)
	local op1, funcargs, typeids, typeids_str, returntype = args[2], args[3], args[4], args[5], args[6]
	local funcname = op1[1](self,op1)

	local func, func_return_type = findFunc( self, funcname, typeids, typeids_str )

	if not func then E2Lib.raiseException( "No such function: " .. funcname .. "(" .. tps_pretty( typeids_str ) .. ")", 0 ) end

	if returntype ~= "" and func_return_type ~= returntype then
		error( "Mismatching return types. Got " .. nicename(wire_expression_types2[returntype][1]) .. ", expected " .. nicename(wire_expression_types2[func_return_type][1] ), 0 )
	end

	if returntype ~= "" then
		local ret = func( self, funcargs )
		return ret
	else
		func( self, funcargs )
	end
end)