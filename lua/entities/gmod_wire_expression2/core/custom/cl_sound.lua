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

	for _,v in pairs(E2Sounds) do
	
		if v.IsBass and v.SoundChannel then
		
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
			
		elseif v.SoundChannel then
			if v.FadeRequest != nil and v.FadeRequest > 0 then
				timer.Simple(v.FadeRequest,function()
					v.SoundChannel:Stop()
				end)
				v.FadeRequest = -1
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

local bassNetFunctions = {	
	Play = function(sound, data)
		sound.SoundChannel:Play()
		sound.Entity = data[3]
		if data[2] > 0 then
			sound.DieTime = CurTime() + data[2]
		end
	end,
	Pause = function(sound, data)
		sound.SoundChannel:Pause()
	end,
	Resume = function(sound, data)
		sound.SoundChannel:Play()
	end,
	Remove = function(sound, data)
		sound.SoundChannel:Stop()
		E2Sounds[sound.Index] = nil
	end,
	Stop = function(sound, data)
		if data[2] > 0 then
			sound.DieTime = CurTime() + data[2]
			setFadeVolume(sound, 0, data[2])
		else
			sound.SoundChannel:Stop()
		end
	end,
	ChangeVolume = function(sound, data)
		if data[3] > 0 then
			setFadeVolume(sound, data[2], data[3])
		else
			sound.SoundChannel:SetVolume(data[2])
		end
		return true
	end,
	ChangePitch = function(sound, data)
		if data[3] > 0 then
			setFadePitch(sound, data[2], data[3])
		else
			sound.SoundChannel:SetPlaybackRate(data[2])
		end
		
		return true
	end,
	ChangeFadeDistance = function(sound, data)
		sound.SoundChannel:Set3DFadeDistance(data[2], data[3])
		return true
	end,
	SetLooping = function(sound, data)
		sound.SoundChannel:EnableLooping( data[2]~=0 )
		return true
	end,
	SetTime = function(sound, data)
		sound.SoundChannel:SetTime( data[2] )
		return true
	end
}

local gmodSoundFuncs = {	
	Play = bassNetFunctions.Play,
	Stop = function(sound, data)
		if data[2] > 0 then
			if sound.FadeRequest then return end
			sound.SoundChannel:FadeOut(math.abs(data[2]))
			sound.FadeRequest = math.abs(data[2])
		else
			sound.SoundChannel:Stop()
		end	
	end,
	Remove = bassNetFunctions.Remove,
	ChangeVolume = bassNetFunctions.ChangeVolume,
	ChangePitch = bassNetFunctions.ChangePitch
}
/*
local gmodSoundFuncs = {	
	Play = function(sound, data)

		sound.SoundChannel:Play()
		sound.Entity = data[3]
		
		if data[2] > 0 then
			sound.DieTime = CurTime() + data[2]
		end
		
		return true
	end,
	Stop = function(sound, data)

		if data[2] > 0 then
			sound.SoundChannel:FadeOut(math.abs(data[2]))
			sound.FadeRequest = math.abs(data[2])
		else
			sound.SoundChannel:Stop()
		end	
		
		return true
	end,
	Remove = function(sound, data)
		sound.SoundChannel:Stop()
		E2Sounds[sound.Index] = nil
		return true
	end,
	ChangeVolume = function(sound, data)
		if !sound.SoundChannel then return false end
		if data[3] > 0 then
			sound.SoundChannel:ChangeVolume(data[2], data[3])
		else
			sound.SoundChannel:ChangeVolume(data[2])
		end
		return true
	end,
	ChangePitch = function(sound, data)
		if !sound.SoundChannel then return false end
		
		if data[3] > 0 then
			sound.SoundChannel:ChangePitch(data[2], data[3])
		else
			sound.SoundChannel:ChangePitch(data[2])
		end
		
		return true
	end
}
*/
local function loadSound(index)

	local sounds = E2Sounds[index]
	local path = sounds.Path

	if sounds.IsBass then
		sound.PlayURL(path, "3d mono noblock", function(channel, er, ername)
			if IsValid(channel) then

				if IsValid(sounds.Entity) then
				
					if sounds.SoundChannel then
						sounds.SoundChannel:Stop()
					end
					
					sounds.SoundChannel = channel
					channel:SetPos(sounds.Entity:GetPos())
					
					if sounds.Pitch > 0 then
						newsound:SetPlaybackRate(math.Clamp( sounds.Pitch, 0, 400 ) / 100)
					end
					
					if sounds.Volume > 0 then
						newsound:SetVolume( math.Clamp( sounds.Volume, 0, 1 ))
					end

					// Execute the QUEUED Stuff.
					if sounds.BassQueue != nil and #sounds.BassQueue > 0 then
						for _,v in pairs(sounds.BassQueue) do
							if bassNetFunctions[v.Func] then
								bassNetFunctions[v.Func](sounds,v.Data)
							end
						end
						table.Empty(sounds.BassQueue)
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

local function createSound(index,data)
	
	local path = data[1].path
	local pitch = data[1].pitch
	local volume = data[1].volume
	
	local time = data[2]
	local ent = data[3]
	local ply = data[4]

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
	
	E2Sounds[index] = {SoundChannel = nil, Entity = ent, Player = ply, BassQueue = {}, Path = path, Pitch = pitch, Volume = volume, Length = time, Index = index, IsBass = bass}
	loadSound(index)
	
end

local function decideFunction(index, func, data)

	if func == "Create" then
		createSound(index,data)
	else
		local sound = E2Sounds[index]
		
		if sound then
			if sound.IsBass then
				if bassNetFunctions[func] and sound.SoundChannel then 
					bassNetFunctions[func](sound,data) // Execute the sound Function
				elseif sound.BassQueue then // QUEUE it
					sound.BassQueue[#sound.BassQueue+1] = {Func = func, Data = data}
				end
			else
				if gmodSoundFuncs[func] and sound.SoundChannel then
					gmodSoundFuncs[func](sound,data)
				end
			end
		end

	end
	
end


net.Receive("e2_soundrequest",function()

	local access = wire_expression2_sound_enabled:GetInt()
	if access==0 then return end
	
	local requests = net.ReadTable()
	if requests == nil or #requests <= 0 then return end

	for _,k in pairs(requests) do
		local indx = k.Arg[1].index
		local e2function = k.Func
		
		if k == nil or indx == nil or e2function == nil then continue end
		decideFunction(indx, e2function,k.Arg)
	end
	
end)

net.Receive("e2_soundremove",function()
	local index = net.ReadString()
	decideFunction(index, "Remove")
end)