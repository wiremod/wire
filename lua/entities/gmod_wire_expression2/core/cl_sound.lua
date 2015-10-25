local E2Sounds = {}
local BlockedPlayers = {}

local wire_expression2_sound_enabled = CreateConVar( "wire_expression2_sound_enabled_cl", 2, {FCVAR_ARCHIVE},"2: Anyone's sounds can be heard, 1: Only friend's sounds will be heard, 0: Only your own sounds will be heard")
cvars.AddChangeCallback("wire_expression2_sound_enabled_cl", function(name, old, new)
	if new~=2 then
		for k,v in pairs(E2Sounds) do
			v.SoundChannel:Stop()
		end
		E2Sounds = {}
	end
end)

local function doPlayerBlocking(args, cb)
	local name = args[1]:lower()
	local players = E2Lib.filterList(player.GetAll(), function(ent) return ent:GetName():lower():match(name) end)
	if #players == 1 then
		cb(players[1])
	elseif #players > 1 then
		ply:PrintMessage( HUD_PRINTCONSOLE, "More than one player matches that name!" )
	else
		ply:PrintMessage( HUD_PRINTCONSOLE, "No player names found with " .. args[1] )
	end
end

concommand.Add("wire_expression2_sound_blockplayer",function(ply,com,args)
	doPlayerBlocking(args, function(found)
		BlockedPlayers[found:SteamID()] = true
		
		for k,v in pairs(E2Sounds) do
			if v.Player == found then
				v.SoundChannel:Stop()
				E2Sounds[k] = nil
			end
		end
	end)
end)

concommand.Add("wire_expression2_sound_unblockplayer",function(ply,com,args)
	doPlayerBlocking(args, function(found)
		BlockedPlayers[found:SteamID()] = nil
	end)
end )

local function moveSounds()
	for k,v in pairs(E2Sounds) do
		if v.IsBass and IsValid(v.SoundChannel) then
			if IsValid(v.Entity) then
				v.SoundChannel:SetPos(v.Entity:GetPos())
				if v.FadePitchStart then
					local t = (CurTime() - v.FadePitchStart)/v.FadePitchTime
					local inter = v.OriginalPitch + v.DeltaPitch*t
					if t>=1 then
						v.SoundChannel:SetPlaybackRate(v.OriginalPitch + v.DeltaPitch)
						v.FadePitchStart = nil
					else
						v.SoundChannel:SetPlaybackRate(inter)
					end
				end
				if v.FadeVolumeStart then
					local t = (CurTime() - v.FadeVolumeStart)/v.FadeVolumeTime
					local inter = v.OriginalVolume + v.DeltaVolume*t
					if t>=1 then
						v.SoundChannel:SetVolume(v.OriginalVolume + v.DeltaVolume)
						v.FadeVolumeStart = nil
					else
						v.SoundChannel:SetVolume(inter)
					end
				end
				if v.DieTime then
					if CurTime()>=v.DieTime then
						v.SoundChannel:Stop()
						v.DieTime = nil
					end
				end
			end
		end
	end
	
	if not next(E2Sounds) then
		hook.Remove("Think", "E2_move_sounds")
	end
end

local function setFadePitch(sound, pitch, time)
	sound.FadePitchStart = CurTime()
	sound.FadePitchTime = math.max(time,0.01)
	sound.OriginalPitch = sound.SoundChannel:GetPlaybackRate()
	sound.DeltaPitch = pitch - sound.OriginalPitch
end

local function setFadeVolume(sound, volume, time)
	sound.FadeVolumeStart = CurTime()
	sound.FadeVolumeTime = math.max(time,0.01)
	sound.OriginalVolume = sound.SoundChannel:GetVolume()
	sound.DeltaVolume = volume - sound.OriginalVolume
end

local bassSoundFuncs = {	
	Play = function(sound, time, ent)
		sound.SoundChannel:Play()
		sound.Entity = ent
		if time>0 then
			sound.DieTime = CurTime() + time
		end
	end,
	
	Pause = function(sound)
			sound.SoundChannel:Pause()
	end,
	
	Stop = function(sound, time)
		if time>0 then
			sound.DieTime = CurTime() + time
			setFadeVolume(sound, 0, time)
		else
			sound.SoundChannel:Stop()
		end
	end,
	
	Remove = function(sound)
		sound.SoundChannel:Stop()
		E2Sounds[sound.Index] = nil
	end,
	
	ChangeVolume = function(sound, volume, time)
		if time>0 then
			setFadeVolume(sound, volume, time)
		else
			sound.SoundChannel:SetVolume(volume)
		end
	end,
	
	ChangePitch = function(sound, rate, time)
		if time>0 then
			setFadePitch(sound, rate, time)
		else
			sound.SoundChannel:SetPlaybackRate(rate)
		end
	end,
	
	ChangeFadeDistance = function(sound, min, max)
		sound.SoundChannel:Set3DFadeDistance(min, max)
	end,
	
	SetLooping = function(sound, loop)
		sound.SoundChannel:EnableLooping( loop~=0 )
	end,
	
	SetTimePosition= function(sound, time)
		sound.SoundChannel:SetTime( time )
	end
}

local CSSoundMeta = FindMetaTable("CSoundPatch")
CSSoundMeta.SetVolume = CSSoundMeta.ChangeVolume
CSSoundMeta.SetPlaybackRate = CSSoundMeta.ChangePitch
local gmodSoundFuncs = {	
	Play = bassSoundFuncs.Play,
	Stop = bassSoundFuncs.Stop,
	Remove = bassSoundFuncs.Remove,
	ChangeVolume = bassSoundFuncs.ChangeVolume,
	ChangePitch = bassSoundFuncs.ChangePitch
}

local function loadSound(index)

	local sounds = E2Sounds[index]
	local path = sounds.Path
	
	if sounds.IsBass then
		sound.PlayURL(path, "3d mono noblock", function(channel, er, ername)
			if IsValid(channel) then
				if E2Sounds[index] and IsValid(sounds.Entity) then
				
					if IsValid(sounds.SoundChannel) then
						sounds.SoundChannel:Stop()
					end
					
					sounds.SoundChannel = channel
					channel:SetPos(sounds.Entity:GetPos())
					
					local queue = sounds.Queue
					if queue then
						for I=1, #queue do
							queue[I].Func(sounds, unpack(queue[I].Arg))
						end
						sounds.Queue = nil
					end
					
					if sounds.Length>0 then
						E2Sounds[index].DieTime = CurTime() + sounds.Length
					end
					sounds.Length = 0
				else
					channel:Stop()
					E2Sounds[index] = nil
				end
			else
				LocalPlayer():PrintMessage( HUD_PRINTCONSOLE, "[E2] Failed to play sound: " .. path .. " | BASS_ERROR : " .. ername .."\n")
				if er == -1 then // BASS_ERROR_UNKNOWN , its usually because the sound isnt mono and 3D requires that, (mono) tag doesn't seem to affect it.
					LocalPlayer():PrintMessage( HUD_PRINTCONSOLE, "[E2] Please make sure the HTTP sound is MONO.\n")
				end
				
				E2Sounds[index] = nil
			end
			
		end)
	else
		local newsound = CreateSound(sounds.Entity, path)
		newsound:Play()
		sounds.Entity:CallOnRemove("E2Sound_"..index, function( ent )
			newsound:Stop()
		end)
		sounds.SoundChannel = newsound
	end
end

local function createSound(index)

	local path = net.ReadString()
	local time = net.ReadDouble()
	local ent = net.ReadEntity()
	local ply = net.ReadEntity()
	
	if not ent:IsValid() or not ply:IsValid() then return end
	
	if wire_expression2_sound_enabled:GetInt()==1 and ply:GetFriendStatus()~="friend" and ply~=LocalPlayer() then return end
	if BlockedPlayers[ply:SteamID()] then return end
	
	if not next(E2Sounds) then
		hook.Add("Think", "E2_move_sounds",moveSounds)
	end
	
	if E2Sounds[index] and E2Sounds[index].SoundChannel and IsValid(E2Sounds[index].SoundChannel) then
		E2Sounds[index].SoundChannel:Stop()
	end
	
	local bass = false
	
	if path:sub(1,4) == "http" || path:sub(1,3) == "www" then
		bass = true
	end
	
	E2Sounds[index] = {SoundChannel = nil, Entity = ent, Player = ply, Queue = {}, Path = path, Length = time, Index = index, IsBass = bass}
	
	loadSound(index)
end

local netFuncs = {	
	Play = function()	
		return {net.ReadDouble(), net.ReadEntity()}
	end,
	Pause = function()
		return {}
	end,
	Remove = function()
		return {}
	end,
	Stop = function()
		return {net.ReadDouble()}
	end,
	ChangeVolume = function()
		return {net.ReadDouble(), net.ReadDouble()}
	end,
	ChangePitch = function()
		return {net.ReadDouble(), net.ReadDouble()}
	end,
	ChangeFadeDistance = function()
		return {net.ReadDouble(), net.ReadDouble()}
	end,
	SetLooping = function()
		return {net.ReadUInt(8)}
	end,
	SetTimePosition = function()
		return {net.ReadUInt(32)}
	end
}

local function decideFunction(index, func)
	if func == "Create" then
		createSound(index)
	elseif netFuncs[func] then
		local sound = E2Sounds[index]
		local netdata = netFuncs[func]()
		if sound then
			local soundFunc = sound.IsBass and bassSoundFuncs[func] or gmodSoundFuncs[func]
			if soundFunc then
				if sound.SoundChannel then
					if not sound.IsBass or sound.SoundChannel:IsValid() then
						soundFunc(sound,unpack(netdata))
					--[[else
						sound.SoundChannel = nil
						sound.Queue = {{Func = soundFunc, Arg = netdata}}
						loadSound(index)]]
					end
				elseif sound.Queue then
					sound.Queue[#sound.Queue+1] = {Func = soundFunc, Arg = netdata}
				else
					 E2Sounds[index] = nil
				end
			end
		end
	end
end

local funcLookup = {
	"Create",
	"Play",
	"Pause",
	"Stop",
	"Remove",
	"ChangeVolume",
	"ChangePitch",
	"ChangeFadeDistance",
	"SetLooping",
	"SetTimePosition",
}

net.Receive("e2_soundrequest",function()

	local access = wire_expression2_sound_enabled:GetInt()
	if access==0 then return end
	
	local numRequests = math.Clamp(net.ReadUInt(32),0,100)
	for I=1, numRequests do
		local index = net.ReadString()
		local func = funcLookup[net.ReadUInt(8)]
		decideFunction(index, func)
	end
	
end)

net.Receive("e2_soundremove",function()
	local index = net.ReadString()
	decideFunction(index, "Remove")
end)