local convars = {
	wire_expression2_concmd = 0,
	wire_expression2_concmd_whitelist = "",

	wire_expression2_convar = 0,
	wire_expression2_convar_whitelist = ""
}

local function CreateCVars()
	for name,default in pairs(convars) do
		local current_cvar = CreateClientConVar(name, default, true, true)
		local value = current_cvar:GetString() or default
		RunConsoleCommand(name, value)
	end
end

if CanRunConsoleCommand() then
	CreateCVars()
else
	hook.Add("Initialize", "wire_expression2_console", function()
		CreateCVars()
	end)
end
