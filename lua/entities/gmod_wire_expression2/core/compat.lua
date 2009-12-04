-- Functions in this file are retained purely for backwards-compatibility. They should not be used in new code and might be removed at any time.

e2function string number:teamName()
	local str = team.GetName(this)
	if not str then return "" end
	return str
end

e2function number number:teamScore()
	return team.GetScore(this)
end

e2function number number:teamPlayers()
	return team.NumPlayers(this)
end

e2function number number:teamDeaths()
	return team.TotalDeaths(this)
end

e2function number number:teamFrags()
	return team.TotalFrags(this)
end
