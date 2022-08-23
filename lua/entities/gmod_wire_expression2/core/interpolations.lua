__e2setcost(2)

--This seemed faster then manually typing out all 30 e2functions
local from_easings = {"OutElastic","OutCirc","InOutQuint","InCubic","InOutCubic","InOutBounce","InOutSine","OutQuad","InOutCirc","InElastic","OutBack","InQuint","InSine","InBounce","InQuart","OutSine","OutExpo","InOutExpo","InQuad","InOutElastic","InOutQuart","InExpo","OutCubic","OutQuint","OutBounce","InCirc","InBack","InOutQuad","OutQuart","InOutBack"}

for k, v in pairs(from_easings) do
	local function_call = math.ease[v]
	local name = "ease" .. v
	registerFunction(name, "n", "n", function(self, args)
		local op1 = args[2]
		local rv1 = op1[1](self, op1)
		return function_call(rv1)
	end)
end
