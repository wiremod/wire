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

local CSSoundMeta = FindMetaTable("CSoundPatch")
CSSoundMeta.SetVolume = CSSoundMeta.ChangeVolume
CSSoundMeta.SetPlaybackRate = CSSoundMeta.ChangePitch

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

local netFuncs = {	
	Play = function()	
		return {net.ReadDouble(), net.ReadEntity()}
	end,
	Pause = function()
		return {}
	end,
	Resume = function()
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
	SetTime = function()
		return {net.ReadUInt(32)}
	end,
	GetSoundFFT = function()
		return {}
	end,
	GetSoundStatus = function()
		return {}
	end
}

local funcLookup = {
	"Create",
	"Play",
	"Pause",
	"Resume",
	"Remove",
	"Stop",
	"ChangeVolume",
	"ChangePitch",
	"ChangeFadeDistance",
	"SetLooping",
	"SetTime",
	"GetSoundFFT",
	"GetSoundStatus"
}
	
local bassNetFunctions = {	
	Play = function(sound, time, ent)
		sound.SoundChannel:Play()
		sound.Entity = ent
		if time > 0 then
			sound.DieTime = CurTime() + time
		end
	end,
	Pause = function(sound)
		sound.SoundChannel:Pause()
	end,
	Resume = function(sound)
		sound.SoundChannel:Play()
	end,
	Remove = function(sound)
		sound.SoundChannel:Stop()
		E2Sounds[sound.Index] = nil
	end,
	Stop = function(sound, time)
		if time > 0 then
			sound.DieTime = CurTime() + time
			setFadeVolume(sound, 0, time)
		else
			sound.SoundChannel:Stop()
		end
	end,
	ChangeVolume = function(sound, volume, time)
		if time > 0 then
			setFadeVolume(sound, volume, time)
		else
			sound.SoundChannel:SetVolume(volume)
		end
	end,
	ChangePitch = function(sound, rate, time)
		rate = math.Clamp( rate, 0, sound.IsBass and 400 or 255 ) / 100
		if time > 0 then
			setFadePitch(sound, rate, time)
		else
			sound.SoundChannel:SetPlaybackRate(rate)
		end
	end,
	ChangeFadeDistance = function(sound, min, max)
		sound.SoundChannel:Set3DFadeDistance(min, max)
	end,
	SetLooping = function(sound, loop )
		sound.SoundChannel:EnableLooping( loop~=0 )
	end,
	SetTime = function(sound, time)
		sound.SoundChannel:SetTime( time )
	end,
	GetSoundFFT = function(sound)
		//return sound.SoundChannel:SetTime( time )
	end,
	GetSoundStatus = function(sound)
		return sound.SoundChannel:GetState()
	end
}

local gmodSoundFuncs = {	
	Play = bassNetFunctions.Play,
	Stop = function(sound, time)
		if time > 0 then
			if sound.FadeRequest then return end
			sound.SoundChannel:FadeOut(math.abs(time))
			sound.FadeRequest = math.abs(time)
		else
			sound.SoundChannel:Stop()
		end	
	end,
	Remove = bassNetFunctions.Remove,
	ChangeVolume = bassNetFunctions.ChangeVolume,
	ChangePitch = bassNetFunctions.ChangePitch
}

local function loadSound(index)

	local soundtbl = E2Sounds[index]
	local path = soundtbl.Path

	if soundtbl.IsBass then
		sound.PlayURL(path, "3d mono noblock", function(channel, er, ername)
		
			if IsValid(channel) then

				if E2Sounds[index] and IsValid(soundtbl.Entity) then
				
					if soundtbl.SoundChannel then
						soundtbl.SoundChannel:Stop()
					end
					
					soundtbl.SoundChannel = channel
					channel:SetPos(soundtbl.Entity:GetPos())

					// Execute the QUEUED Stuff.
					local queue = sounds.Queue
					if queue then
						for I=1, #queue do
							queue[I].Func(sounds, unpack(queue[I].Arg))
						end
						sounds.Queue = nil
					end
					
					if sounds.Length > 0 then
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
		if E2Sounds[index] != nil and IsValid(sounds.Entity) then
			local s = Sound(path)
			local newsound = CreateSound(sounds.Entity, s)
			if !newsound then E2Sounds[index] = nil return end
			
			if sounds.Pitch <= 0 then sounds.Pitch = 100 else sounds.Pitch = math.Clamp( sounds.Pitch, 0, 255 ) end
			if sounds.Volume <= 0 then sounds.Volume = 1 else sounds.Volume = math.Clamp( sounds.Volume, 0, 1 ) end
			newsound:PlayEx(sounds.Volume,sounds.Pitch)

			if sounds.Length > 0 then
				E2Sounds[index].DieTime = CurTime() + sounds.Length
			end
			
			sounds.Length = 0
			sounds.SoundChannel = newsound
		end
	end
	
end

local function createSound(index)

	local path = net.ReadString()
	local time = net.ReadDouble()
	local ent = net.ReadEntity()
	local ply = net.ReadEntity()

	if not IsValid(ent) or not IsValid(ply) then return end
	if wire_expression2_sound_enabled:GetInt()==1 and ply:GetFriendStatus()~="friend" and ply~=LocalPlayer() then return end
	if BlockedPlayers[ply:SteamID()] then return end
	
	if not next(E2Sounds) then
		hook.Add("Think", "E2_move_sounds",moveSounds)
	end
	
	// Delete old one
	if E2Sounds[index] and E2Sounds[index].SoundChannel then
		E2Sounds[index].SoundChannel:Stop()
	end
	
	local bass = false
	if path:sub(1,4) == "http" || path:sub(1,3) == "www" then
		bass = true
	end
	
	E2Sounds[index] = {SoundChannel = nil, Entity = ent, Player = ply, Queue = {}, Path = path, Length = time, Index = index, IsBass = bass}
	loadSound(index)
	
end

local function decideFunction(index,func)

	if func == "Create" then
		createSound(index)
	else

		local sound = E2Sounds[index]
		local netdata = netFuncs[func]()
		
		if sound then
		
			if sound.IsBass then
			
				local soundFunc = bassNetFunctions[func] 
				if soundFunc then
					if sound.SoundChannel then 
						soundFunc(sound,unpack(netdata)) // Execute the sound Function
					elseif sound.Queue then // QUEUE it
						sound.Queue[#sound.Queue+1] = {Func = soundFunc, Arg = netdata}
					end
				end
				
			else
				local soundFunc = gmodSoundFuncs[func] 
				if soundFunc and sound.SoundChannel then // No delay on creating the sounds
					soundFunc(sound,unpack(netdata))
				end
			end
		end

	end
	
end


net.Receive("e2_soundrequest",function()

	local access = wire_expression2_sound_enabled:GetInt()
	if access==0 then return end
	
	local numRequests = math.Clamp(net.ReadUInt(32),0,100)
	for I=1, numRequests do
		local index = net.ReadString()
		local funcLook = funcLookup[net.ReadUInt(8)]
		decideFunction(index, funcLook)
	end
	
end)