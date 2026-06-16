--[[
		Unit Conversion
]]

GateActions("Unit Conversion")

GateActions["unit_tounit"] = {
    name = "To Unit",
    description = "Converts a value from Source units (inches) to the specified unit. Supports speed (m/s, km/h, mph...), length (m, cm, ft...) and weight (kg, lb, oz...).",
    inputs = { "Value", "Unit" },
    inputtypes = { "NORMAL", "STRING" },
    outputtypes = { "NORMAL" },
    output = function(gate, Value, Unit)
        for _, tbl in pairs(WireLib.UnitConv) do
            if tbl[Unit] then
                return Value * tbl[Unit]
            end
        end
        return 0
    end,
    label = function(Out, Value, Unit)
        return string.format("toUnit(%s, %q) = %f", tostring(Value), tostring(Unit), Out)
    end
}

GateActions["unit_fromunit"] = {
    name = "From Unit",
    description = "Converts a value from the specified unit back to Source units (inches). Supports speed, length and weight.",
    inputs = { "Value", "Unit" },
    inputtypes = { "NORMAL", "STRING" },
    outputtypes = { "NORMAL" },
    output = function(gate, Value, Unit)
        for _, tbl in pairs(WireLib.UnitConv) do
            if tbl[Unit] then
                return Value / tbl[Unit]
            end
        end
        return 0
    end,
    label = function(Out, Value, Unit)
        return string.format("fromUnit(%s, %q) = %f", tostring(Value), tostring(Unit), Out)
    end
}

GateActions["unit_convertunit"] = {
    name = "Convert Unit",
    description = "Returns the conversion factor between two units. Both units must be of the same type (speed, length or weight).",
    inputs = { "From", "To" },
    inputtypes = { "STRING", "STRING" },
    outputtypes = { "NORMAL" },
    output = function(gate, From, To)
        local factor = WireLib.ConvertUnit(From, To)
        return factor or 0
    end,
    label = function(Out, From, To)
        return string.format("convertUnit(%q → %q) = %f", tostring(From), tostring(To), Out)
    end
}

GateActions()