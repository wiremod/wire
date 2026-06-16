local convars = {
	wire_expression2_concmd = 0,
	wire_expression2_concmd_whitelist = "",

	wire_expression2_convar = 0,
	wire_expression2_convar_whitelist = ""
}

for name, default in pairs(convars) do
	CreateClientConVar(name, default, true, true)
end
