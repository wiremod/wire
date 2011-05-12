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

e2function number entity:isAdmin()
	if not validEntity(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this:IsAdmin() then return 1 else return 0 end
end

e2function number entity:isSuperAdmin()
	if not validEntity(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this:IsSuperAdmin() then return 1 else return 0 end
end

/******************************************************************************/

__e2setcost(8)

e2function vector entity:shootPos()
	if(!validEntity(this)) then return {0,0,0} end
	if(this:IsPlayer() or this:IsNPC()) then
		return this:GetShootPos()
	else return {0,0,0} end
end

e2function vector entity:eye()
	if (!validEntity(this)) then return {0,0,0} end
	if (this:IsPlayer()) then
		return this:GetAimVector()
	else
		return this:GetForward()
	end
end

--- Returns a local angle describing player <this>'s view angles.
e2function angle entity:eyeAngles()
	if not validEntity(this) then return { 0, 0, 0} end
	local ang = this:EyeAngles()
	return { ang.p, ang.y, ang.r }
end

/******************************************************************************/

__e2setcost(5)

e2function string entity:name()
	if(!validEntity(this)) then return "" end
	if(!this:IsPlayer()) then return "" end
	return this:Name()
end

e2function string entity:steamID()
	if(!validEntity(this)) then return "" end
	if(!this:IsPlayer()) then return "" end
	return this:SteamID()
end

e2function number entity:armor()
	if(!validEntity(this)) then return 0 end
	if(this:IsPlayer() or this:IsNPC()) then return this:Armor() else return 0 end
end

/******************************************************************************/

__e2setcost(5)

e2function number entity:isCrouch()
	if(!validEntity(this)) then return 0 end
	if(this:IsPlayer() and this:Crouching()) then return 1 else return 0 end
end

e2function number entity:isAlive()
	if(!validEntity(this)) then return 0 end
	if(this:IsPlayer() and this:Alive()) then return 1 end
	if(this:IsNPC() and this:Health() > 0) then return 1 end
	return 0
end

/******************************************************************************/

e2function number entity:frags()
	if(!validEntity(this)) then return 0 end
	if(this:IsPlayer()) then return this:Frags() else return 0 end
end

e2function number entity:deaths()
	if(!this or !this:IsValid()) then return 0 end
	if(this:IsPlayer()) then return this:Deaths() else return 0 end
end

/******************************************************************************/

e2function number entity:team()
	if(!validEntity(this)) then return 0 end
	if(this:IsPlayer()) then return this:Team() else return 0 end
end

e2function string teamName(rv1)
	local str = team.GetName(rv1)
	if str == nil then return "" end
	return str
end

e2function number teamScore(rv1)
	return team.GetScore(rv1)
end

e2function number teamPlayers(rv1)
	return team.NumPlayers(rv1)
end

e2function number teamDeaths(rv1)
	return team.TotalDeaths(rv1)
end

e2function number teamFrags(rv1)
	return team.TotalFrags(rv1)
end

e2function vector teamColor(index)
	local col = team.GetColor(index)
	return { col.r, col.g, col.b }
end

__e2setcost(10)

e2function array teams()
	local team_indexes = {}
	for index,_ in pairs(team.GetAllTeams()) do
		team_indexes[#team_indexes+1] = index
	end
	table.sort(team_indexes)
	return team_indexes
end

/******************************************************************************/

e2function number entity:keyAttack1()
	if not validEntity(this) then return 0 end
	if this:IsPlayer() and this:KeyDown(1) then return 1 end -- IN_ATTACK
	return 0
end

e2function number entity:keyAttack2()
	if not validEntity(this) then return 0 end
	if this:IsPlayer() and this:KeyDown(2048) then return 1 end -- IN_ATTACK2
	return 0
end

e2function number entity:keyUse()
	if not validEntity(this) then return 0 end
	if this:IsPlayer() and this:KeyDown(32) then return 1 end -- IN_USE
	return 0
end

e2function number entity:keyReload()
    if not validEntity(this) then return 0 end
    if this:IsPlayer() and this:KeyDown( IN_RELOAD ) then return 1 end
    return 0
end

e2function number entity:keyZoom()
    if not validEntity(this) then return 0 end
    if this:IsPlayer() and this:KeyDown( IN_ZOOM ) then return 1 end
    return 0
end

-- isTyping
local plys = {}
concommand.Add("E2_StartChat",function(ply,cmd,args) plys[ply] = true end)
concommand.Add("E2_FinishChat",function(ply,cmd,args) plys[ply] = nil end)
hook.Add("PlayerDisconnected","E2_istyping",function(ply) plys[ply] = nil end)

e2function number entity:isTyping()
	return plys[this] and 1 or 0
end

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

__e2setcost(15)

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

__e2setcost(5)

e2function number entity:ping()
	if not validEntity(this) then return 0 end
	if(this:IsPlayer()) then return this:Ping() else return 0 end
end

e2function number entity:timeConnected()
	if not validEntity(this) then return 0 end
	if(this:IsPlayer()) then return this:TimeConnected() else return 0 end
end

e2function entity entity:vehicle()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end
	return this:GetVehicle()
end

e2function number entity:inVehicle()
	if not validEntity(this) then return 0 end
	if(this:IsPlayer() and this:InVehicle()) then return 1 else return 0 end
end

--- Returns 1 if the player <this> is in noclip mode, 0 if not.
e2function number entity:inNoclip()
	if not this or this:GetMoveType() ~= MOVETYPE_NOCLIP then return 0 end
	return 1
end

/******************************************************************************/

local player = player

__e2setcost(10)

e2function array players()
	return player.GetAll()
end

e2function array playersAdmins()
	local Admins = {}
	for _,ply in ipairs(player.GetAll()) do
		if (ply:IsAdmin()) then
			table.insert(Admins,ply)
		end
	end
	return Admins
end

e2function array playersSuperAdmins()
	local Admins = {}
	for _,ply in ipairs(player.GetAll()) do
		if (ply:IsSuperAdmin()) then
			table.insert(Admins,ply)
		end
	end
	return Admins
end

/******************************************************************************/

e2function entity entity:aimEntity()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end

	local ent = this:GetEyeTraceNoCursor().Entity
	if not ent:IsValid() then return nil end
	return ent
end

e2function vector entity:aimPos()
	if not validEntity(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitPos
end

e2function vector entity:aimNormal()
	if not validEntity(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitNormal
end

--- Returns the bone the player is currently aiming at.
e2function bone entity:aimBone()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end

	local trace = this:GetEyeTraceNoCursor()
	local ent = trace.Entity
	if not validEntity(ent) then return nil end
	return getBone(ent, trace.PhysicsBone)
end

--- Equivalent to rangerOffset(16384, <this>:shootPos(), <this>:eye()), but faster (causing less lag)
e2function ranger entity:eyeTrace()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() then return nil end
	local ret = this:GetEyeTraceNoCursor()
	ret.RealStartPos = this:GetShootPos()
	return ret
end

/******************************************************************************/

__e2setcost(nil) -- temporary
