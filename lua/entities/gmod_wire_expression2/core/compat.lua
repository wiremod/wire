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

e2function void setColor(r, g, b)
	self.entity:SetColor(Color(math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255), 255))
end

__e2setcost(10)

e2function number entity:height()
	--[[	Old code (UGLYYYY)
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer() or this:IsNPC()) then
		local pos = this:GetPos()
		local up = this:GetUp()
		return this:NearestPoint(Vector(pos.x+up.x*100,pos.y+up.y*100,pos.z+up.z*100)).z-this:NearestPoint(Vector(pos.x-up.x*100,pos.y-up.y*100,pos.z-up.z*100)).z
	else return 0 end
	]]

	-- New code (Same as E:boxSize():z())
	if(!IsValid(this)) then return 0 end
	return (this:OBBMaxs() - this:OBBMins()).z
end
