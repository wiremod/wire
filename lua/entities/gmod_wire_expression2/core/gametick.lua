/******************************************************************************\
  Game tick callback support
\******************************************************************************/

local registered_chips = {}
local tickrun = 0

registerCallback("destruct",function(self)
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

local function Expression2TickClock()
	local ents = {}

	-- this additional step is needed because we cant modify registered_chips while it is being iterated.
	local i = 1
	for entity,_ in pairs(registered_chips) do
		if entity:IsValid() then
			ents[i] = entity
			i = i + 1
		end
	end

	for _,entity in ipairs(ents) do
		entity.context.data.tickrun = true
		entity:Execute()
		entity.context.data.tickrun = nil
	end

	E2Lib.triggerEvent("tick")
end
hook.Add("Think", "Expression2TickClock", Expression2TickClock)
timer.Create("Expression2TickClock", 5, 0, function()
	hook.Add("Think", "Expression2TickClock", Expression2TickClock)
end)

E2Lib.registerEvent("tick")