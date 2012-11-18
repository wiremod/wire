include('shared.lua')
include("remap.lua")

local Wire_Keyboard_Remap = Wire_Keyboard_Remap

local KeyEvents = {}

local function GetRemappedKey( key )
	if (!key or key == 0) then return 0 end

	local current = Wire_Keyboard_Remap[GetConVarString("wire_keyboard_layout")]
	if (!current) then return "" end

	local ret

	-- Check if a special key is being held down (such as SHIFT)
	for k,v in pairs( KeyEvents ) do
		if (v == true and current[k]) then
			ret = current[k][key] or current.normal[key]
		end
	end

	-- Else return the normal key
	if (!ret) then
		ret = current.normal[key]
	end

	if isstring(ret) then ret = string.byte(ret) end
	return ret
end

local BlockFrame
local UseKeyboard = false

local function Wire_BlockInput()
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end

	if (GetConVarString("wire_keyboard_sync") == "1") then
		if not BlockFrame then BlockFrame = vgui.Create("TextEntry") end
		BlockFrame:SetSize(10,10)
		BlockFrame:SetPos(-100,-100)
		BlockFrame:SetVisible(true)
		BlockFrame:MakePopup()
		BlockFrame:SetMouseInputEnabled(false)
		BlockFrame.OnKeyCodeTyped = function(b,key)
			if !KeyEvents[key] then
				LocalPlayer():ConCommand("wire_keyboard_press p "..GetRemappedKey(key).." "..key)
				KeyEvents[key] = true
			end
		end
	end

	UseKeyboard = true
end
usermessage.Hook("wire_keyboard_blockinput", Wire_BlockInput)
concommand.Add("wire_keyboard_blockinput", Wire_BlockInput)

local function Wire_ReleaseInput()
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end

	UseKeyboard = false
end
usermessage.Hook("wire_keyboard_releaseinput", Wire_ReleaseInput)
concommand.Add("wire_keyboard_releaseinput", Wire_ReleaseInput)

hook.Add("PostRenderVGUI", "wire_keyboard_checkkeys", function()
	if (UseKeyboard == true) then
		for i = 1,130 do
			if(input.IsKeyDown(i) && !KeyEvents[i]) then
				// The key has been pressed
				KeyEvents[i] = true
				LocalPlayer():ConCommand("wire_keyboard_press p "..GetRemappedKey(i).." "..i)
			elseif(!input.IsKeyDown(i) && KeyEvents[i]) then
				// The key has been released
				KeyEvents[i] = false
				LocalPlayer():ConCommand("wire_keyboard_press r "..GetRemappedKey(i).." "..i)
			end
		end
	end
end)
