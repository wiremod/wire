/******************************************************************************\
  Player-Entity support
\******************************************************************************/

local validEntity = E2Lib.validEntity
local isOwner = E2Lib.isOwner
registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "isOwner" then
		isOwner = func
	elseif funcname == "validEntity" then
		validEntity = func
	end
end)

/******************************************************************************/

__e2setcost(5) -- temporary

registerFunction("isAdmin", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return 0 end
	if not rv1:IsPlayer() then return 0 end
	if rv1:IsAdmin() then return 1 else return 0 end
end)

registerFunction("isSuperAdmin", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return 0 end
	if not rv1:IsPlayer() then return 0 end
	if rv1:IsSuperAdmin() then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("shootPos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		return rv1:GetShootPos()
	else return {0,0,0} end
end)

registerFunction("eye", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if (!validEntity(rv1)) then return {0,0,0} end
	if (rv1:IsPlayer()) then
		return rv1:GetAimVector()
	else
		return rv1:GetForward()
	end
end)

--- Returns a local angle describing player <this>'s view angles.
e2function angle entity:eyeAngles()
	if not validEntity(this) then return { 0, 0, 0} end
	local ang = this:EyeAngles()
	return { ang.p, ang.y, ang.r }
end

/******************************************************************************/

registerFunction("name", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(!rv1:IsPlayer()) then return "" end
	return rv1:Name()
end)

registerFunction("steamID", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(!rv1:IsPlayer()) then return "" end
	return rv1:SteamID()
end)

registerFunction("armor", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then return rv1:Armor() else return 0 end
end)

/******************************************************************************/

registerFunction("height", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		local pos = rv1:GetPos()
		local up = rv1:GetUp()
		return rv1:NearestPoint(Vector(pos.x+up.x*100,pos.y+up.y*100,pos.z+up.z*100)).z-rv1:NearestPoint(Vector(pos.x-up.x*100,pos.y-up.y*100,pos.z-up.z*100)).z
	else return 0 end
end)

registerFunction("width", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		local pos = rv1:GetPos()
		local right = rv1:GetRight()
		return rv1:NearestPoint(Vector(pos.x+right.x*100,pos.y+right.y*100,pos.z+right.z*100)).z-rv1:NearestPoint(Vector(pos.x-right.x*100,pos.y-right.y*100,pos.z-right.z*100)).z
	else return 0 end
end)

/******************************************************************************/

registerFunction("isCrouch", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() and rv1:Crouching()) then return 1 else return 0 end
end)

registerFunction("isAlive", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() and rv1:Alive()) then return 1 end
	if(rv1:IsNPC() and rv1:Health() > 0) then return 1 end
	return 0
end)

/******************************************************************************/

registerFunction("frags", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Frags() else return 0 end
end)

registerFunction("deaths", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!rv1 or !rv1:IsValid()) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Deaths() else return 0 end
end)

/******************************************************************************/

registerFunction("team", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Team() else return 0 end
end)

registerFunction("teamName", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local str = team.GetName(rv1)
	if str == nil then return "" end
	return str
end)

registerFunction("teamScore", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.GetScore(rv1)
end)

registerFunction("teamPlayers", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.NumPlayers(rv1)
end)

registerFunction("teamDeaths", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.TotalDeaths(rv1)
end)

registerFunction("teamFrags", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return team.TotalFrags(rv1)
end)

e2function vector teamColor(index)
	local col = team.GetColor(index)
	return { col.r, col.g, col.b }
end

e2function array teams()
	local team_indexes = {}
	for index,_ in pairs(team.GetAllTeams()) do
		team_indexes[#team_indexes+1] = index
	end
	table.sort(team_indexes)
	return team_indexes
end

registerFunction("ping", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if not validEntity(rv1) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Ping() else return 0 end
end)

/******************************************************************************/

registerFunction("keyAttack1", "e:", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not validEntity(rv1) then return 0 end
	if rv1:IsPlayer() and rv1:KeyDown(1) then return 1 end -- IN_ATTACK
	return 0
end)

registerFunction("keyAttack2", "e:", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not validEntity(rv1) then return 0 end
	if rv1:IsPlayer() and rv1:KeyDown(2048) then return 1 end -- IN_ATTACK2
	return 0
end)

registerFunction("keyUse", "e:", "n", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if not validEntity(rv1) then return 0 end
	if rv1:IsPlayer() and rv1:KeyDown(32) then return 1 end -- IN_USE
	return 0
end)

/******************************************************************************/

local Trusts

if CPPI and _R.Player.CPPIGetFriends then

	function Trusts(ply, whom)
		if ply == whom then return true end
		local friends = ply:CPPIGetFriends()
		for _,friend in pairs(friends) do
			if whom == friend then return true end
		end
		return false
	end

	e2function array entity:friends()
		if not validEntity(this) then return {} end
		if not this:IsPlayer() then return {} end
		if not Trusts(this, self.player) then return {} end

		return this:CPPIGetFriends()
	end

	e2function number entity:trusts(entity whom)
		if not validEntity(this) then return 0 end
		if not this:IsPlayer() then return 0 end
		if not Trusts(this, self.player) then return 0 end

		return Trusts(this, whom) and 1 or 0
	end

else

	function Trusts(ply, whom)
		return ply == whom
	end

	e2function array entity:friends()
		return {}
	end

	e2function number entity:trusts(entity whom)
		return whom == this and 1 or 0
	end

end


local steamfriends = {}

concommand.Add("wire_expression2_friend_status", function(ply, command, args)
	local friends = {}

	for index in args[1]:gmatch("[^,]") do
		local n = tonumber(index)
		if not n then return end
		table.insert(friends, Entity(index))
	end

	steamfriends[ply:EntIndex()] = friends
end)

hook.Add("EntityRemoved", "wire_expression2_friend_status", function(ply)
	steamfriends[ply:EntIndex()] = nil
end)

--- Returns an array containing <this>'s steam friends currently on the server
e2function array entity:steamFriends()
	if not validEntity(this) then return {} end
	if not this:IsPlayer() then return {} end
	if not Trusts(this, self.player) then return {} end

	return steamfriends[this:EntIndex()] or {}
end

--- Returns 1 if <this> and <friend> are steam friends, 0 otherwise.
e2function number entity:isSteamFriend(entity friend)
	if not validEntity(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if not Trusts(this, self.player) then return 0 end

	local friends = steamfriends[this:EntIndex()]
	if not friends then return 0 end

	return table.HasValue(friends, friend) and 1 or 0
end

/******************************************************************************/

__e2setcost(nil) -- temporary
