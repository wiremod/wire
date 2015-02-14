
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
		
		net.Start("E2_joystick_sendstream")
		for I=0, stream.num_axis-1 do
			net.WriteUInt(joystick.axis(stream.enum,I),16)
		end
		for I=0, stream.num_buttons-1 do
			net.WriteBit(joystick.button(stream.enum,I) > 0)
		end
		for I=0, stream.num_povs-1 do
			net.WriteUInt(joystick.pov(stream.enum,I),16)
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