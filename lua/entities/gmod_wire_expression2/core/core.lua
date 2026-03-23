--------------------------------------------------------------------------------
--  Core language support
--------------------------------------------------------------------------------

__e2setcost(0) -- cascaded

e2function number operator_is(number this)
	return (this ~= 0) and 1 or 0
end

--------------------------------------------------------------------------------

__e2setcost(1) -- approximation

[nodiscard]
e2function number first()
	return self.entity.first and 1 or 0
end

[nodiscard]
e2function number duped()
	return self.entity.duped and 1 or 0
end

[nodiscard, deprecated = "Use the input event instead"]
e2function number inputClk()
	return self.triggerinput and 1 or 0
end

[nodiscard, deprecated = "Use the input event instead"]
e2function string inputClkName()
	return self.triggerinput or ""
end

E2Lib.registerEvent("input", {
	{ "InputName", "s" }
})

-- This MUST be the first destruct hook!
registerCallback("destruct", function(self)
	local entity = self.entity
	if entity.error then return end
	if not entity.script then return end

	self.resetting = false
	entity:ExecuteEvent("removed", { entity.removing and 0 or 1 })

	if not self.data.runOnLast then return end
	self.data.runOnLast = false

	self.data.last = true
	entity:Execute()
	self.data.last = false
end)

--- Returns 1 if it is being called on the last execution of the expression gate before it is removed or reset. This execution must be requested with the runOnLast(1) command.
[nodiscard, deprecated = "Use the removed event instead"]
e2function number last()
	return self.data.last and 1 or 0
end

-- number (whether it is being reset or just removed)
E2Lib.registerEvent("removed", {
	{ "Resetting", "n" }
})

-- dupefinished()
-- Made by Divran

local function dupefinished( TimedPasteData, TimedPasteDataCurrent )
	for k,v in pairs( TimedPasteData[TimedPasteDataCurrent].CreatedEntities ) do
		if (isentity(v) and v:IsValid() and v:GetClass() == "gmod_wire_expression2") then
			v.dupefinished = true
			v:Execute()
			v.dupefinished = nil
		end
	end
end
hook.Add("AdvDupe_FinishPasting", "E2_dupefinished", dupefinished )

[nodiscard]
e2function number dupefinished()
	return self.entity.dupefinished and 1 or 0
end

--- Returns 1 if this is the last() execution and caused by the entity being removed.
[nodiscard, deprecated = "Use the removed event instead"]
e2function number removing()
	return self.entity.removing and 1 or 0
end

--- If <activate> != 0, the chip will run once when it is removed, setting the last() flag when it does.
[nodiscard, deprecated = "Use the removed event instead"]
e2function void runOnLast(activate)
	if self.data.last then return end
	self.data.runOnLast = activate ~= 0
end

--------------------------------------------------------------------------------

__e2setcost(2) -- approximation

e2function void exit()
	self.Scope, self.ScopeID, self.Scopes = self.GlobalScope, 0, { [0] = self.GlobalScope }
	error("exit", 0)
end

do
	[noreturn]
	e2function void error( string reason )
		self:forceThrow(reason)
	end

	e2function void assert(condition)
		if condition == 0 then
			self:forceThrow("assert failed")
		end
	end

	e2function void assert(condition, string reason)
		if condition == 0 then
			self:forceThrow(reason)
		end
	end

	e2function void assertSoft(condition)
		if condition == 0 then
			self:throw("assert failed")
		end
	end

	e2function void assertSoft(condition, string reason)
		if condition == 0 then
			self:throw(reason)
		end
	end

	[nodiscard]
	e2function number isStrict()
		return self.strict and 1 or 0
	end
end

--------------------------------------------------------------------------------

__e2setcost(100) -- approximation

[noreturn]
e2function void reset()
	self.Scope, self.ScopeID, self.Scopes = self.GlobalScope, 0, { [0] = self.GlobalScope }

	if self.data.last or self.entity.first then error("exit", 0) end

	if self.entity.last_reset and self.entity.last_reset == CurTime() then
		error("Attempted to reset the E2 twice in the same tick!", 2)
	end
	self.entity.last_reset = CurTime()

	self.data.reset = true

	error("exit", 0)
end

-- wrapping this in a postinit hook to make sure this is the last postexecute hook in the list
registerCallback("postinit", function()
	-- handle reset()
	registerCallback("postexecute", function(self)
		if self.data.reset then
			self.entity:Reset()
			self.data.reset = false

			-- do not execute any other postexecute hooks after this one.
			error("cancelhook", 0)
		end
	end)
end)

--------------------------------------------------------------------------------

local floor  = math.floor
local ceil   = math.ceil
local round  = math.Round

__e2setcost(1) -- approximation

[nodiscard]
e2function number ops()
	return round(self.prfbench)
end

[nodiscard]
e2function number entity:ops()
	if not IsValid(this) or this:GetClass() ~= "gmod_wire_expression2" or not this.context then return 0 end
	return round(this.context.prfbench)
end

[nodiscard]
e2function number opcounter()
	return ceil(self.prf + self.prfcount)
end

[nodiscard]
e2function number cpuUsage()
	return self.timebench
end

[nodiscard]
e2function number entity:cpuUsage()
	if not IsValid(this) or this:GetClass() ~= "gmod_wire_expression2" or not this.context then return 0 end
	return this.context.timebench
end

--- If used as a while loop condition, stabilizes the expression around <maxexceed> hardquota used.
[nodiscard]
e2function number perf()
	if self.prf >= e2_tickquota*0.95-200 then return 0 end
	if self.prf + self.prfcount >= e2_hardquota then return 0 end
	if self.prf >= e2_softquota*2 then return 0 end
	return 1
end

[nodiscard]
e2function number perf(number n)
	n = math.Clamp(n, 0, 100)
	if self.prf >= e2_tickquota*n*0.01 then return 0 end
	if self.prf + self.prfcount >= e2_hardquota * n * 0.01 then return 0 end
	if n == 100 then
		if self.prf >= e2_softquota * 2 then return 0 end
	else
		if self.prf >= e2_softquota * n * 0.01 then return 0 end
	end
	return 1
end

[nodiscard]
e2function number minquota()
	if self.prf < e2_softquota then
		return floor(e2_softquota - self.prf)
	else
		return 0
	end
end

[nodiscard]
e2function number maxquota()
	if self.prf < e2_tickquota then
		local tickquota = e2_tickquota - self.prf
		local hardquota = e2_hardquota - self.prfcount - self.prf + e2_softquota

		if hardquota < tickquota then
			return floor(hardquota)
		else
			return floor(tickquota)
		end
	else
		return 0
	end
end

[nodiscard]
e2function number softQuota()
	return e2_softquota
end

[nodiscard]
e2function number hardQuota()
	return e2_hardquota
end

[nodiscard]
e2function number timeQuota()
	return e2_timequota
end

__e2setcost(nil)

registerCallback("postinit", function()
	-- Returns the Nth value given after the index, the type's zero element otherwise. If you mix types, all non-matching arguments will be regarded as the 2nd argument's type's zero element.
	for name,id,zero in pairs_map(wire_expression_types, unpack) do
		registerFunction("select", "n"..id.."...", id, function(self, args)
			local index = args[2]
			index = index[1](self, index)

			index = math.Clamp(math.floor(index), 1, #args-3)

			if index ~= 1 and args[#args][index+1] ~= id then return zero end
			local value = args[index+2]
			value = value[1](self, value)
			return value
		end, 5, { "index", "argument1" })
	end
end)
