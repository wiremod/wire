/******************************************************************************\
  Unit conversion
\******************************************************************************/

/*
	u   - source unit
	A Source Unit is 0.75 Inch long, more info here:
	http://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference

	mm  - millimeter
	cm  - centimeter
	dm  - decimeter
	m   - meter
	km  - kilometer
	in  - inch
	ft  - foot
	yd  - yard
	mi  - mile
	nmi - nautical mile

	g   - gram
	kg  - kilogram
	t   - tonne
	oz  - ounce
	lb  - pound
*/

local speed = {
	["u/s"]   = 1 / 0.75,
	["u/m"]   = 60 * (1 / 0.75),
	["u/h"]   = 3600 * (1 / 0.75),

	["mm/s"]  = 25.4,
	["cm/s"]  = 2.54,
	["dm/s"]  = 0.254,
	["m/s"]   = 0.0254,
	["km/s"]  = 0.0000254,
	["in/s"]  = 1,
	["ft/s"]  = 1 / 12,
	["yd/s"]  = 1 / 36,
	["mi/s"]  = 1 / 63360,
	["nmi/s"] = 127 / 9260000,

	["mm/m"]  = 60 * 25.4,
	["cm/m"]  = 60 * 2.54,
	["dm/m"]  = 60 * 0.254,
	["m/m"]   = 60 * 0.0254,
	["km/m"]  = 60 * 0.0000254,
	["in/m"]  = 60,
	["ft/m"]  = 60 / 12,
	["yd/m"]  = 60 / 36,
	["mi/m"]  = 60 / 63360,
	["nmi/m"] = 60 * 127 / 9260000,

	["mm/h"]  = 3600 * 25.4,
	["cm/h"]  = 3600 * 2.54,
	["dm/h"]  = 3600 * 0.254,
	["m/h"]   = 3600 * 0.0254,
	["km/h"]  = 3600 * 0.0000254,
	["in/h"]  = 3600,
	["ft/h"]  = 3600 / 12,
	["yd/h"]  = 3600 / 36,
	["mi/h"]  = 3600 / 63360,
	["nmi/h"] = 3600 * 127 / 9260000,

	["mph"]   = 3600 / 63360,
	["knots"] = 3600 * 127 / 9260000,
	["mach"]  = 0.0254 / 295,
}

local length = {
	["u"]   = 1 / 0.75,

	["mm"]  = 25.4,
	["cm"]  = 2.54,
	["dm"]  = 0.254,
	["m"]   = 0.0254,
	["km"]  = 0.0000254,
	["in"]  = 1,
	["ft"]  = 1 / 12,
	["yd"]  = 1 / 36,
	["mi"]  = 1 / 63360,
	["nmi"] = 127 / 9260000,
}

local weight = {
	["g"]  = 1000,
	["kg"] = 1,
	["t"]  = 0.001,
	["oz"] = 1 / 0.028349523125,
	["lb"] = 1 / 0.45359237,
}

__e2setcost(2) -- approximated

e2function number toUnit(string rv1, rv2)

	if speed[rv1] then
		return (rv2 * 0.75) * speed[rv1]
	elseif length[rv1] then
		return (rv2 * 0.75) * length[rv1]
	elseif weight[rv1] then
		return rv2 * weight[rv1]
	end

	return -1
end

e2function number fromUnit(string rv1, rv2)

	if speed[rv1] then
		return (rv2 / 0.75) / speed[rv1]
	elseif length[rv1] then
		return (rv2 / 0.75) / length[rv1]
	elseif weight[rv1] then
		return rv2 / weight[rv1]
	end

	return -1
end

e2function number convertUnit(string rv1, string rv2, rv3)

	if speed[rv1] and speed[rv2] then
		return rv3 * (speed[rv2] / speed[rv1])
	elseif length[rv1] and length[rv2] then
		return rv3 * (length[rv2] / length[rv1])
	elseif weight[rv1] and weight[rv2] then
		return rv3 * (weight[rv2] / weight[rv1])
	end

	return -1
end
