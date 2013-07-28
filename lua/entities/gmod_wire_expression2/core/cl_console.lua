local convars = {
	wire_expression2_concmd = 0,
	wire_expression2_concmd_whitelist = "",
}

local function CreateCVars()
	for name,default in pairs(convars) do
		current_cvar = CreateClientConVar(name, default, true, true)
		local value = current_cvar:GetString() or default
		RunConsoleCommand(name, value)
	end
end

if CanRunConsoleCommand() then
	CreateCVars()
else
	hook.Add("OnEntityCreated", "wire_expression2_console", function(ent)
		if not IsValid(ent) then return end
		if ent ~= LocalPlayer() then return end

		CreateCVars()
		timer.Create("Remove_wire_expression2_console_Hook",0,1,function() hook.Remove("OnEntityCreated", "wire_expression2_console") end) -- Removing it immediately may hurt the hook loop
	end)
end
