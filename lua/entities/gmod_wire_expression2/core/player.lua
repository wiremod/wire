/******************************************************************************\
  Player-Entity support
\******************************************************************************/

local IsValid = IsValid
local isOwner = E2Lib.isOwner


local spawnAlert = {}
local runBySpawn = 0
local lastJoined = NULL

local leaveAlert = {}
local runByLeave = 0
local lastLeft = NULL

registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
	if funcname == "isOwner" then
		isOwner = func
	elseif funcname == "IsValid" then
		IsValid = func
	end
end)

/******************************************************************************/

__e2setcost(5) -- temporary

e2function number entity:isAdmin()
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this:IsAdmin() then return 1 else return 0 end
end

e2function number entity:isSuperAdmin()
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this:IsSuperAdmin() then return 1 else return 0 end
end

/******************************************************************************/

__e2setcost(8)

e2function vector entity:shootPos()
	if(!IsValid(this)) then return {0,0,0} end
	if(this:IsPlayer() or this:IsNPC()) then
		return this:GetShootPos()
	else return {0,0,0} end
end

e2function vector entity:eye()
	if (!IsValid(this)) then return {0,0,0} end
	if (this:IsPlayer()) then
		return this:GetAimVector()
	else
		return this:GetForward()
	end
end

--- Returns a local angle describing player <this>'s view angles.
e2function angle entity:eyeAngles()
	if not IsValid(this) then return { 0, 0, 0} end
	local ang = this:EyeAngles()
	return { ang.p, ang.y, ang.r }
end

/******************************************************************************/

__e2setcost(5)

e2function string entity:name()
	if(!IsValid(this)) then return "" end
	if(!this:IsPlayer()) then return "" end
	return this:Name()
end

e2function string entity:steamID()
	if(!IsValid(this)) then return "" end
	if(!this:IsPlayer()) then return "" end
	return this:SteamID()
end

e2function string entity:steamID64()
	return IsValid(this) and this:IsPlayer() and this:SteamID64() or ""
end

e2function number entity:armor()
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer() or this:IsNPC()) then return this:Armor() else return 0 end
end

/******************************************************************************/

__e2setcost(5)

e2function number entity:isCrouch()
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer() and this:Crouching()) then return 1 else return 0 end
end

e2function number entity:isAlive()
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer() and this:Alive()) then return 1 end
	if(this:IsNPC() and this:Health() > 0) then return 1 end
	return 0
end

-- returns 1 if players has flashlight on or 0 if not
e2function number entity:isFlashlightOn()
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if this:FlashlightIsOn() then return 1 else return 0 end
end

/******************************************************************************/

e2function number entity:frags()
	if(!IsValid(this)) then return 0 end
	if(this:IsPlayer()) then return this:Frags() else return 0 end
end

e2function number entity:deaths()
	if(!this or !this:IsValid()) then return 0 end
	if(this:IsPlayer()) then return this:Deaths() else return 0 end
end

/******************************************************************************/

e2function number entity:team()
	if(!IsValid(this)) then return 0 end
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
__e2setcost(2)

e2function number entity:keyForward()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_FORWARD)) and 1 or 0
end

e2function number entity:keyLeft()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_MOVELEFT)) and 1 or 0
end

e2function number entity:keyBack()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_BACK)) and 1 or 0
end

e2function number entity:keyRight()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_MOVERIGHT)) and 1 or 0
end

e2function number entity:keyJump()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_JUMP)) and 1 or 0
end

e2function number entity:keyAttack1()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_ATTACK)) and 1 or 0
end

e2function number entity:keyAttack2()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_ATTACK2)) and 1 or 0
end

e2function number entity:keyUse()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_USE)) and 1 or 0
end

e2function number entity:keyReload()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_RELOAD)) and 1 or 0
end

e2function number entity:keyZoom()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_ZOOM)) and 1 or 0
end

e2function number entity:keyWalk()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_WALK)) and 1 or 0
end

e2function number entity:keySprint()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_SPEED)) and 1 or 0
end

e2function number entity:keyDuck()
	if not IsValid(this) or not this:IsPlayer() then return 0 end
	return this:KeyDown(IN_DUCK) and 1 or this:GetInfoNum("gmod_vehicle_viewmode", 0)
end

e2function number entity:keyLeftTurn()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_LEFT)) and 1 or 0
end

e2function number entity:keyRightTurn()
	return (IsValid(this) and this:IsPlayer() and this:KeyDown(IN_RIGHT)) and 1 or 0
end

e2function number entity:keyPressed(string char)
	if not IsValid(this) or not this:IsPlayer() then return 0 end
	if this.keystate then
		local key = _G["KEY_" .. string.upper(char)] or "no_key"
		if this.keystate[key] then return 1 end
		
		key = _G[string.match(string.upper(char),"^(MOUSE_.+)$") or ""] or "no_key"
		if this.keystate[key] then return 1 end
	end
	
	return 0
end


local KeyAlert = {}
local runByKey
local pressedKey = ""
local KeyWasReleased = 0

local keys_lookup = {}
local sub = string.sub
local lower = string.lower
for k,v in pairs( _G ) do
	if sub(k,1,4) == "KEY_" then
		keys_lookup[v] = lower(sub(k,5))
	end
end

-- Manually input the mouse buttons because they're a bit fucked up
keys_lookup[107] = "mouse_left"
keys_lookup[108] = "mouse_right"
keys_lookup[109] = "mouse_middle"
keys_lookup[110] = "mouse_4"
keys_lookup[111] = "mouse_5"
keys_lookup[112] = "mouse_wheel_up"
keys_lookup[113] = "mouse_wheel_down"

registerCallback("destruct",function(self)
	KeyAlert[self.entity] = nil
	--Used futher below. Didn't want to create more then one of these per file
	spawnAlert[self.entity] = nil
	leaveAlert[self.entity] = nil
end)

local function UpdateKeys(ply, key)
	runByKey = ply
	pressedKey = keys_lookup[key] or ""
	for chip, plys in pairs(KeyAlert) do
		if IsValid(chip) then
			if plys[ply] then
				chip:Execute()
			end
		else
			KeyAlert[chip] = nil
		end
	end
	runByKey = nil
	pressedKey = ""
	KeyWasReleased = 0
end

-- delay these 1 tick with timers, otherwise ply:keyPressed(str) doesn't work properly, in case old E2s uses that function
-- It is recommended to use keyClkPressed() instead to get which key was pressed.
hook.Add("PlayerButtonDown","Exp2KeyReceivingDown", function(ply,key) timer.Simple(0,function() UpdateKeys(ply,key) end) end)
local temp = function(ply, key)	KeyWasReleased = 1 UpdateKeys(ply, key) end
hook.Add("PlayerButtonUp","Exp2KeyReceivingUp", function(ply,key) timer.Simple(0,function() temp(ply,key) end) end )

--- Makes the chip run on key events from the specified player (can be used on multiple players)
e2function void runOnKeys(entity ply, on)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if on ~= 0 then
		if not KeyAlert[self.entity] then KeyAlert[self.entity] = {} end
		KeyAlert[self.entity][ply] = true
	elseif KeyAlert[self.entity] then
		KeyAlert[self.entity][ply] = nil
		if not next(KeyAlert[self.entity]) then
			KeyAlert[self.entity] = nil
		end
	end
end

--- Returns user if the chip is being executed because of a key event.
e2function entity keyClk()
	return runByKey
end

--- Returns 1 or -1 if the chip is being executed because of a key event by player <ply>
--- depending of whether the key was just pressed or released
e2function number keyClk(entity ply)
	return ((ply == runByKey) and IsValid( ply )) and ((KeyWasReleased == 0) and 1 or -1) or 0
end

-- Returns the key which caused the keyClk event to trigger
e2function string keyClkPressed()
	return pressedKey
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

if CPPI and debug.getregistry().Player.CPPIGetFriends then

	function Trusts(ply, whom)
		if ply == whom then return true end
		local friends = ply:CPPIGetFriends()
		if !istable(friends) then return false end
		for _,friend in pairs(friends) do
			if whom == friend then return true end
		end
		return false
	end

	e2function array entity:friends()
		if not IsValid(this) then return {} end
		if not this:IsPlayer() then return {} end
		if not Trusts(this, self.player) then return {} end

		local ret = this:CPPIGetFriends()
		if !istable(ret) then return {} end
		return ret
	end

	e2function number entity:trusts(entity whom)
		if not IsValid(this) then return 0 end
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

	for index in args[1]:gmatch("[^,]+") do
		local n = tonumber(index)
		if not n then return end
		table.insert(friends, Entity(n))
	end

	steamfriends[ply:EntIndex()] = friends
end)

hook.Add("EntityRemoved", "wire_expression2_friend_status", function(ply)
	steamfriends[ply:EntIndex()] = nil
end)

__e2setcost(15)

--- Returns an array containing <this>'s steam friends currently on the server
e2function array entity:steamFriends()
	if not IsValid(this) then return {} end
	if not this:IsPlayer() then return {} end
	if not Trusts(this, self.player) then return {} end

	return steamfriends[this:EntIndex()] or {}
end

--- Returns 1 if <this> and <friend> are steam friends, 0 otherwise.
e2function number entity:isSteamFriend(entity friend)
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end
	if not Trusts(this, self.player) then return 0 end

	local friends = steamfriends[this:EntIndex()]
	if not friends then return 0 end

	return table.HasValue(friends, friend) and 1 or 0
end

/******************************************************************************/

__e2setcost(5)

e2function number entity:ping()
	if not IsValid(this) then return 0 end
	if(this:IsPlayer()) then return this:Ping() else return 0 end
end

e2function number entity:timeConnected()
	if not IsValid(this) then return 0 end
	if(this:IsPlayer()) then return this:TimeConnected() else return 0 end
end

e2function entity entity:vehicle()
	if not IsValid(this) then return nil end
	if not this:IsPlayer() then return nil end
	return this:GetVehicle()
end

e2function number entity:inVehicle()
	if not IsValid(this) then return 0 end
	if(this:IsPlayer() and this:InVehicle()) then return 1 else return 0 end
end

--- Returns 1 if the player <this> is in noclip mode, 0 if not.
e2function number entity:inNoclip()
	if not IsValid(this) or this:GetMoveType() ~= MOVETYPE_NOCLIP then return 0 end
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
	if not IsValid(this) then return nil end
	if not this:IsPlayer() then return nil end

	local ent = this:GetEyeTraceNoCursor().Entity
	if not ent:IsValid() then return nil end
	return ent
end

e2function vector entity:aimPos()
	if not IsValid(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitPos
end

e2function vector entity:aimNormal()
	if not IsValid(this) then return {0,0,0} end
	if not this:IsPlayer() then return {0,0,0} end

	return this:GetEyeTraceNoCursor().HitNormal
end

--- Returns the bone the player is currently aiming at.
e2function bone entity:aimBone()
	if not IsValid(this) then return nil end
	if not this:IsPlayer() then return nil end

	local trace = this:GetEyeTraceNoCursor()
	local ent = trace.Entity
	if not IsValid(ent) then return nil end
	return getBone(ent, trace.PhysicsBone)
end

--- Equivalent to rangerOffset(16384, <this>:shootPos(), <this>:eye()), but faster (causing less lag)
e2function ranger entity:eyeTrace()
	if not IsValid(this) then return nil end
	if not this:IsPlayer() then return nil end
	local ret = this:GetEyeTraceNoCursor()
	ret.RealStartPos = this:GetShootPos()
	return ret
end

e2function ranger entity:eyeTraceCursor()
	if not IsValid(this) or not this:IsPlayer() then return nil end
	local ret = this:GetEyeTrace()
	ret.RealStartPos = this:GetShootPos()
	return ret
end

--[[--------------------------------------------------------------------------------------------]]--

hook.Add("PlayerInitialSpawn","Exp2RunOnJoin", function(ply)
	runBySpawn = 1
	lastJoined = ply
	for e,_ in pairs(spawnAlert) do
		if IsValid(e) then
			e:Execute()
		else
			spawnAlert[e] = nil
		end
	end
	runBySpawn = 0
end)

hook.Add("PlayerDisconnected","Exp2RunOnLeave", function(ply)
	runByLeave = 1
	lastLeft = ply
	for e,_ in pairs(leaveAlert) do
		if IsValid(e) then
			e:Execute()
		else
			leaveAlert[e] = nil
		end
	end
	runByLeave = 0
end)

__e2setcost(3)

e2function void runOnPlayerConnect(activate)
	if activate ~= 0 then
		spawnAlert[self.entity] = true
	else
		spawnAlert[self.entity] = nil
	end
end

e2function number playerConnectClk()
	return runBySpawn
end

e2function entity lastConnectedPlayer()
	return lastJoined
end

e2function void runOnPlayerDisconnect(activate)
	if activate ~= 0 then
		leaveAlert[self.entity] = true
	else
		leaveAlert[self.entity] = nil
	end
end

e2function number playerDisconnectClk()
	return runByLeave
end

e2function entity lastDisconnectedPlayer()
	return lastLeft
end
