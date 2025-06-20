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

hook.Add("Think", "Expression2TickClock", function()
	-- This additional step is needed because we cant modify registered_chips while it is being iterated.
	local entities = {}
	local i = 1

	for entity in pairs(registered_chips) do
		if entity:IsValid() then
			entities[i] = entity
			i = i + 1
		end
	end

	for _, entity in ipairs(entities) do
		entity.context.data.tickrun = true
		entity:Execute()
		entity.context.data.tickrun = nil
	end

	E2Lib.triggerEvent("tick")
end)

E2Lib.registerEvent("tick")
