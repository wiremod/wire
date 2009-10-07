-- Functions for backwards-compatibility. Might be removed at any time...

registerFunction("teamName", "n:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local str = team.GetName(rv1)
	if not str then return "" end
	return str
end)

registerFunction("teamScore", "n:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.GetScore(rv1)
end)

registerFunction("teamPlayers", "n:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.NumPlayers(rv1)
end)

registerFunction("teamDeaths", "n:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.TotalDeaths(rv1)
end)

registerFunction("teamFrags", "n:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.TotalFrags(rv1)
end)
