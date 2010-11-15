include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local BlockFrame

function ENT:Initialize()
	if (WireLib.Version == "-unknown-") then -- WireLib.Version is defined in UpdateCheck.lua
		RunConsoleCommand("Wire_RequestVersion")
	end
end


local KeyEvents = {}
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
				LocalPlayer():ConCommand("wire_keyboard_press p "..key)
				KeyEvents[key] = true
			end
		end
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

hook.Add("PostRenderVGUI", "wire_keyboard_checkkeys", function()
	if (WireLib.Version != "-unknown-") then -- WireLib.Version is defined in UpdateCheck.lua
		for i = 1,130 do
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
