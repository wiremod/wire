__e2setcost(2)
e2function number lerp(number fraction, number from, number to)
	return Lerp(t, from, to)
end

e2function vector lerpVec(number fraction, vector from, vector to)
	return LerpVector(fraction, Vector(from[1], from[2], from[3]), Vector(to[1], to[2], to[3]))
end

e2function vector2 lerpVec2(number fraction, vector2 from, vector2 to)
	return {Lerp(fraction, from[1], to[1]), Lerp(fraction, from[2], to[2])}
end

e2function vector4 lerpVec4(number fraction, vector4 from, vector4 to)
	return {
		Lerp(fraction, from[1], to[1]),
		Lerp(fraction, from[2], to[2]),
		Lerp(fraction, from[3], to[3]),
		Lerp(fraction, from[4], to[4])
	}
end

e2function vector lerpAng(number fraction, angle from, angle to)
	return LerpAngle(ratio, Angle(from[1], from[2], from[3]), Angle(to[1], to[2], to[3]))
end

--This seemed faster then manually typing out all 30 e2functions
local from_easings = {"OutElastic","OutCirc","InOutQuint","InCubic","InOutCubic","InOutBounce","InOutSine","OutQuad","InOutCirc","InElastic","OutBack","InQuint","InSine","InBounce","InQuart","OutSine","OutExpo","InOutExpo","InQuad","InOutElastic","InOutQuart","InExpo","OutCubic","OutQuint","OutBounce","InCirc","InBack","InOutQuad","OutQuart","InOutBack"}

for k, v in pairs(from_easings) do
	local function_call = math.ease[v]
	--Player(4):ChatPrint(v .. tostring(function_call))
	local name = "ease" .. v
	registerFunction(name, "n", "n", function(self, args)
		local op1 = args[2]
		local rv1 = op1[1](self, op1)
		return function_call(rv1)
	end)
end
