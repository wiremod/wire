--[[
	Lambdas for Expression 2
		Format: fun(args: any[], sig: string): ret_ty string?, ret any
]]

local function DEFAULT_FUNCTION(state)
	state:forceThrow("Invalid function!")
end

registerType("function", "f", DEFAULT_FUNCTION,
	nil,
	nil,
	nil,
	function(v)
		return not isfunction(v)
	end
)