--[[----------------------------------------------------------------------------
	Game tick callback support
------------------------------------------------------------------------------]]

local registered_chips = {}

registerCallback("destruct", function(self)
	registered_chips[self.entity] = nil
end)

__e2setcost(1)

--- If <activate> != 0 the expression will execute once every game tick
[deprecated = "Use the tick event instead"]
e2function void runOnTick(activate)
	if activate ~= 0 then
		registered_chips[self.entity] = true
	else
		registered_chips[self.entity] = nil
	end
end

--- Returns 1 if the current execution was caused by "runOnTick"
[nodiscard, deprecated = "Use the tick event instead"]
e2function number tickClk()
	return self.data.tickrun and 1 or 0
end

E2Lib.registerEvent("tick")

hook.Add("Think", "Expression2TickClock", function()
	for entity in pairs(registered_chips) do
		local tab = entity:GetTable()
		local data = tab.context.data

		data.tickrun = true
		tab.Execute(entity)
		data.tickrun = nil
	end

	E2Lib.triggerEvent("tick")
end)
