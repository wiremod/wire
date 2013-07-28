-- Copied from the gmod base entity, it's changed to work with wire map interface.
-- It's only changed for this entity.

-- This function is used to store an output.
function ENT:StoreOutput(name, info)
	local rawData = string.Explode(",", info)

	local Output = {}
	Output.entities = rawData[1] or ""
	Output.input = rawData[2] or ""
	Output.param = rawData[3] or ""
	Output.delay = tonumber(rawData[4]) or 0
	Output.times = tonumber(rawData[5]) or -1

	self._OutputsToMap = self._OutputsToMap or {}
	self._OutputsToMap[name] = self._OutputsToMap[name] or {}
	table.insert(self._OutputsToMap[name], Output)
end


-- Nice helper function, this does all the work.
-- Returns false if the output should be removed from the list.
local function FireSingleOutput(output, this, activator, value, delayoffset)
	if (output.times == 0) then return false end
	local delay = output.delay + (delayoffset or 0)
	local entitiesToFire = {}

	if (output.entities == "!activator") then
		entitiesToFire = {activator}
	elseif (output.entities == "!self") then
		entitiesToFire = {this}
	elseif (output.entities == "!player") then
		entitiesToFire = player.GetAll()
	else
		entitiesToFire = ents.FindByName(output.entities)
	end

	for _,ent in pairs(entitiesToFire) do
		if (IsValid(ent)) then
			if (delay == 0) then
				ent:Input(output.input, activator, this, value or output.param)
			else
				timer.Simple(delay, function()
					if (IsValid(ent)) then
						ent:Input(output.input, activator, this, value or output.param)
					end
				 end)
			end
		end
	end

	if (output.times ~= -1) then
		output.times = output.times - 1
	end

	return ((output.times > 0) or (output.times == -1))
end


-- This function is used to trigger an output.
-- This changed version supports value replacemant and delay offsets.
function ENT:TriggerOutput(name, activator, value, delayoffset)
	if (!self._OutputsToMap) then return end
	local OutputsToMap = self._OutputsToMap[name]
	if (!OutputsToMap) then return end

	for idx,op in pairs(OutputsToMap) do
		if (!FireSingleOutput(op, self, activator, value, delayoffset)) then
			self._OutputsToMap[name][idx] = nil
		end
	end
end
