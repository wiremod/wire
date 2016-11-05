-- First there was phenes
-- Then there was High6
-- Then Black Phoenix came and rewrote everything, what a bastard

local Radio_Entities = {}

function Radio_Register(ent)
	table.insert(Radio_Entities, ent)
end

function Radio_Unregister(ent)
	for k,v in ipairs(Radio_Entities) do
		if v == ent then
			table.remove(Radio_Entities, k)
		elseif IsEntity(v.Entity) then
			-- Zero out all channels that this radio used
			for i=0,31 do
				if v.RecievedData[i].Owner == ent then
					v.RecievedData[i].Owner = nil
					v.RecievedData[i].Data = 0
					v:NotifyDataRecieved(i)
				end
			end
			v:ShowOutput()
		end
	end
end

function Radio_SendData(ent, subch, data)
	ent.SentData[subch] = data

	for k,v in ipairs(Radio_Entities) do
		if not IsEntity(v.Entity) then -- Invalid radio
			Radio_Unregister(v)
		elseif ent:EntIndex() ~= v.Entity:EntIndex() then -- Not sender
			if (ent.Secure) and (v.Secure) then
				if (ent:GetPlayer():SteamID() == v:GetPlayer():SteamID()) and (ent.Channel == v.Channel) then
					v.RecievedData[subch].Owner = ent
					v.RecievedData[subch].Data = data
					v:NotifyDataRecieved(subch)
				end
			else
				if ent.Channel == v.Channel then
					v.RecievedData[subch].Owner = ent
					v.RecievedData[subch].Data = data
					v:NotifyDataRecieved(subch)
				end
			end
			v:ShowOutput()
		end
	end
end

function Radio_RecieveData(ent)
	for i=0,31 do
		ent.RecievedData[i].Owner = nil
		ent.RecievedData[i].Data = 0
		ent:NotifyDataRecieved(i)
	end

	for k,v in ipairs(Radio_Entities) do
		if not IsEntity(v.Entity) then -- Invalid radio
			Radio_Unregister(v)
		elseif ent:EntIndex() ~= v.Entity:EntIndex() then -- Not sender
			if (ent.Secure) and (v.Secure) then
				if (ent:GetPlayer():SteamID() == v:GetPlayer():SteamID()) and (ent.Channel == v.Channel) then
					for i=0,31 do
						ent.RecievedData[i].Owner = v
						ent.RecievedData[i].Data = v.SentData[i]
						ent:NotifyDataRecieved(i)
					end
				end
			else
				if ent.Channel == v.Channel then
					for i=0,31 do
						ent.RecievedData[i].Owner = v
						ent.RecievedData[i].Data = v.SentData[i]
						ent:NotifyDataRecieved(i)
					end
				end
			end
		end
	end
	ent:ShowOutput()
end

function Radio_ChangeChannel(ent)
	-- Request all other radios send data to this radio
	Radio_RecieveData(ent)

	for k,v in ipairs(Radio_Entities) do
		if not IsEntity(v.Entity) then -- Invalid radio
			Radio_Unregister(v)
		elseif ent:EntIndex() ~= v.Entity:EntIndex() then -- Not sender
			-- 1. Kill all transmissions for this radio
			--for i=0,31 do
			--	if (v.RecievedData[i].Owner == ent) then
			--		v.RecievedData[i].Owner = nil
			--		v.RecievedData[i].Data = 0
			--		v:NotifyDataRecieved(i)
			--	end
			--end
			Radio_RecieveData(v)

			-- 2. Retransmit under new channel
			if (ent.Secure) and (v.Secure) then
				if (ent:GetPlayer():SteamID() == v:GetPlayer():SteamID()) and (ent.Channel == v.Channel) then
					for i=0,31 do
						if ent.SentData[i] ~= 0 then -- dont send zeroes
							v.RecievedData[i].Owner = ent
							v.RecievedData[i].Data = ent.SentData[i]
							v:NotifyDataRecieved(i)
						end
					end
				end
			else
				if ent.Channel == v.Channel then
					for i=0,31 do
						if ent.SentData[i] ~= 0 then -- dont send zeroes
							v.RecievedData[i].Owner = ent
							v.RecievedData[i].Data = ent.SentData[i]
							v:NotifyDataRecieved(i)
						end
					end
				end
			end

			v:ShowOutput()
		end
	end
end

local radio_twowaycounter = 0

function Radio_GetTwoWayID()
	radio_twowaycounter = radio_twowaycounter + 1
	return radio_twowaycounter
end

-- phenex: End radio mod.
-- Modified by High6 (To support 4 values)
-- Rebuilt by high6 to allow defined amount of values/secure lines
