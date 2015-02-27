
if file.Exists("lua/bin/gmcl_joystick_win32.dll", "GAME") then
	require("joystick")
else
	net.Receive("E2_joystick_setstream", function() LocalPlayer():ChatPrint("Joystick module is missing. Can't use joystick functions.") end)
	net.Receive("E2_joystick_getdata",function() end)
	return
end

local joysticks = {}
local stream = nil

local function sendJoystickData()
	if stream then
		joystick.refresh()
		
		--Get data
		local axis_data = {}
		local pov_data = {}
		local button_data = {}
		local updates = {joysticks = {}, povs = {}, buttons = false}
		
		for I=1, 8 do
			axis_data[I] = joystick.axis(stream.enum, I - 1)
		end
		for I=1, stream.num_povs do
			pov_data[I] = joystick.pov(stream.enum, I - 1)
		end
		for I=1, stream.num_buttons do
			button_data[I] = joystick.button(stream.enum, I - 1)
		end
		
		net.Start("E2_joystick_sendstream")
		--Send update bits
		for I=1, 8 do
			if math.abs(axis_data[I] - stream.axis_data[I]) > 100 then
				stream.axis_data[I] = axis_data[I]
				updates.joysticks[#updates.joysticks + 1] = I
				net.WriteBit(true)
			else
				net.WriteBit(false)
			end
		end
		for I=1, stream.num_povs do
			if pov_data[I] ~= stream.pov_data[I] then
				stream.pov_data[I] = pov_data[I]
				updates.povs[#updates.povs + 1] = I
				net.WriteBit(true)
			else
				net.WriteBit(false)
			end
		end
		for I=1, stream.num_buttons do
			if button_data[I] ~= stream.button_data[I] then
				stream.button_data = button_data
				updates.buttons = true
				break
			end
		end
		if updates.buttons then
			net.WriteBit(true)
		else
			net.WriteBit(false)
		end
		
		for k,v in pairs(updates.joysticks) do
			net.WriteUInt(axis_data[v], 16)
		end
		for k,v in pairs(updates.povs) do
			net.WriteUInt(pov_data[v], 16)
		end
		if updates.buttons then
			for k,v in pairs(button_data) do
				net.WriteBit(v > 0)
			end
		end
		
		net.SendToServer()
	end
end

net.Receive("E2_joystick_setstream",function()
	local stick = net.ReadUInt(8)
	local on = net.ReadBit()
	if on==1 then
		if joysticks[stick] then
			if not stream then
				hook.Add("Tick","StreamJoystickData",sendJoystickData)
			end
			stream = joysticks[stick]
			stream.axis_data = {0, 0, 0, 0, 0, 0, 0, 0}
			stream.pov_data = {}
			stream.button_data = {}
		end
	else
		stream = nil
		hook.Remove("Tick","StreamJoystickData")
	end
end)

local function sendJoystickInit()
	local count = joystick.count()
	if count>0 then
		net.Start("E2_joystick_senddata")
		net.WriteUInt(count,8)
		for I=0, count-1 do
			local name  = joystick.name(I)
			local num_axis = joystick.count(I,1)
			local num_buttons = joystick.count(I,2)
			local num_povs = joystick.count(I,3)
			
			net.WriteString(name)
			net.WriteUInt(num_axis,8)
			net.WriteUInt(num_buttons,8)
			net.WriteUInt(num_povs,8)
			
			joysticks[I+1] = {
				enum = I,
				num_axis = num_axis,
				num_buttons = num_buttons,
				num_povs = num_povs
			}
		end
		net.SendToServer()
	end
end

net.Receive("E2_joystick_getdata",sendJoystickInit)

sendJoystickInit()