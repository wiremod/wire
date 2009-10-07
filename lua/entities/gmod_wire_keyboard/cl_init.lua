include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local BlockFrame

local function Wire_BlockInput()
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end

	if (GetConVarString("wire_keyboard_sync") == "1") then
		BlockFrame = vgui.Create("Panel")
		BlockFrame:SetSize(10,10)
		BlockFrame:SetPos(-100,-100)
		BlockFrame:SetVisible(true)
		BlockFrame:MakePopup()
		BlockFrame:SetMouseInputEnabled(false)
	end
end
usermessage.Hook("wire_keyboard_blockinput", Wire_BlockInput)
concommand.Add("wire_keyboard_blockinput", Wire_BlockInput)

local function Wire_ReleaseInput()
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
		BlockFrame = nil
	end
end
usermessage.Hook("wire_keyboard_releaseinput", Wire_ReleaseInput)
concommand.Add("wire_keyboard_releaseinput", Wire_ReleaseInput)


local KeyEvents = {}
hook.Add("CalcView", "wire_keyboard", function()
	if (WIRE_SERVER_INSTALLED) then
		for i=1,130 do
			if(input.IsKeyDown(i) && !KeyEvents[i]) then
				// The key has been pressed
				KeyEvents[i] = true
				LocalPlayer():ConCommand("wire_keyboard_press p "..i)
			elseif(!input.IsKeyDown(i) && KeyEvents[i]) then
				// The key has been released
				KeyEvents[i] = false
				LocalPlayer():ConCommand("wire_keyboard_press r "..i)
			end
		end
	end
end)
