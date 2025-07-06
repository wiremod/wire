-- Modified gmod base entity hammer outout code to extend it by custom functionalities.

function ENT:FireSingleOutput(outputName, output, activator, data)
	if output.times == 0 then
		return false
	end

	local targetName = output.entities
	local entitiesToFire = nil

	if targetName == "!activator" then
		entitiesToFire = {activator}
	else
		entitiesToFire = self:GetEntitiesByTargetnameOrClass(targetName)
	end

	local params = output.param or ""

	if params == "" then
		params = data or ""
	end

	local inputName = output.input
	local remove = false

	if entitiesToFire then
		for _, ent in ipairs(entitiesToFire) do
			if self:ProtectAgainstDangerousIO(ent, outputName, output, data) then
				if self:IsLuaRunEntity(ent) then
					self:PrepairEntityForFire(ent, outputName)
					ent:Fire(inputName, params, output.delay, activator, self)
				else
					ent:Fire(inputName, params, output.delay, activator, self)
				end
			else
				-- Remove the unsafe IO, to prevent error message spam.
				remove = true
			end
		end
	end

	if output.times > 0 then
		output.times = output.times - 1
	end

	if remove then
		return false
	end

	-- Less then 0 are valid to, e.g. unlimited times.
	return output.times ~= 0
end

-- This function is used to trigger an output.
function ENT:TriggerOutput(outputName, activator, data)
	if not self.m_tOutputs then
		return
	end

	local outputNameLower = string.lower(outputName)
	local outputList = self.m_tOutputs[outputNameLower]

	if not outputList then
		return
	end

	for idx = #outputList, 1, -1 do
		local output = outputList[idx]

		if output and not self:FireSingleOutput(outputName, output, activator, data) then
			-- Shift the indexes so this loop doesn't fail later
			table.remove(outputList, idx)
		end
	end
end

