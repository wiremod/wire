/******************************************************************************\
  Unit conversion
\******************************************************************************/

__e2setcost(2) -- approximated

local unitconv = WireLib.UnitConv

e2function number toUnit(string rv1, rv2)
    for _, tbl in pairs(unitconv) do
        if tbl[rv1] then
            return rv2 * tbl[rv1]
        end
    end
    return -1
end

e2function number fromUnit(string rv1, rv2)
    for _, tbl in pairs(unitconv) do
        if tbl[rv1] then
            return rv2 / tbl[rv1]
        end
    end
    return -1
end

e2function number convertUnit(string rv1, string rv2, rv3)
    local factor = WireLib.ConvertUnit(rv1, rv2)
    if factor then return rv3 * factor end
    return -1
end
