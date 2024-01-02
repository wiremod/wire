--[[
	Lambdas for Expression 2
		Format: fun(args: any[], sig: string): ret_ty string?, ret any
		Format: { arg_sig: string, ret: string, fn: fun(args: any[]): any }
]]

registerType("function", "f", nil,
	function(self) self.entity:Error("You may not input a function") end,
	function(self) self.entity:Error("You may not output a function") end,
	nil,
	function(v)
		return not istable(v) or getmetatable(v) ~= E2Lib.Lambda
	end
)

__e2setcost(1)

e2function number operator_is(function f)
	return f and 1 or 0
end

local function splitTypeFast(sig)
	local i, r, count, len = 1, {}, 0, #sig
	while i <= len do
		count = count + 1
		if string.sub(sig, i, i) == "x" then
			r[count] = string.sub(sig, i, i + 2)
			i = i + 3
		else
			r[count] = string.sub(sig, i, i)
			i = i + 1
		end
	end
	return r
end

__e2setcost(5)

e2function array function:getParameterTypes()
	return splitTypeFast(this.arg_sig)
end

__e2setcost(1)

e2function string function:getReturnType()
	return this.ret or ""
end

e2function string toString(function func)
	return tostring(func)
end

e2function string function:toString() = e2function string toString(function func)