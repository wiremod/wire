local E2Sounds = {}
local BlockedPlayers = {}
local BlockingAll = false

concommand.Add("wire_expression2_sound_blockall", function(ply, com, args)
	if args[1] then
		local n = tonumber(args[1])
		if n then
			if n~=0 then
				BlockingAll = true
				for k,v in pairs(E2Sounds) do
					v.SoundChannel:Stop()
				end
				E2Sounds = {}
			else
				BlockingAll = false
			end
		end
	end
end)

function doPlayerBlocking(args, cb)
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
		if IsValid(v.SoundChannel) then
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
					end
				end
			else
				v.SoundChannel:Stop()
				E2Sounds[k] = nil
			end
		else
			E2Sounds[k] = nil
		end
	end
	if not next(E2Sounds) then
		hook.Remove("Think", "E2_move_sounds")
	end
end

local function setFadePitch(data, pitch, time)
	data.FadePitchStart = CurTime()
	data.FadePitchTime = math.max(time,0.01)
	data.OriginalPitch = data.SoundChannel:GetPlaybackRate()
	data.DeltaPitch = pitch - data.OriginalPitch
end

local function setFadeVolume(data, volume, time)
	data.FadeVolumeStart = CurTime()
	data.FadeVolumeTime = math.max(time,0.01)
	data.OriginalVolume = data.SoundChannel:GetVolume()
	data.DeltaVolume = volume - data.OriginalVolume
end

net.Receive("e2_soundcreate",function()
	if BlockingAll then return end
	local index = net.ReadString()
	local path = net.ReadString()
	local time = net.ReadDouble()
	local ent = net.ReadEntity()
	local ply = net.ReadEntity()
	
	if BlockedPlayers[ply:SteamID()] then return end
	
	local function createSoundCallback(snd, er, ername)
		if IsValid(snd) then
		
			if not next(E2Sounds) then
				hook.Add("Think", "E2_move_sounds",moveSounds)
			end
			
			E2Sounds[index] = {SoundChannel = snd, Entity = ent, Player = ply}
			if time>0 then
				E2Sounds[index].DieTime = CurTime() + time
			end
		else
			print("[E2] Failed to play sound: " .. path)
		end
	end
	
	if path:sub(1,4)=="http" then
		sound.PlayURL( path, "3d", createSoundCallback )
	else
		sound.PlayFile( path, "3d", createSoundCallback )
	end
end)

net.Receive("e2_soundplay",function()
	local index = net.ReadString()
		
	if E2Sounds[index] then
		local time = net.ReadDouble()
		local ent = net.ReadEntity()
		E2Sounds[index].SoundChannel:Play()
		E2Sounds[index].Entity = ent
		if time>0 then
			E2Sounds[index].DieTime = CurTime() + time
		end
	end
end)

net.Receive("e2_soundpause",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		E2Sounds[index].SoundChannel:Pause()
		timer.Remove( "E2_sound_stop_" .. index )
	end
end)

net.Receive("e2_soundstop",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		local time = net.ReadDouble()
		if time>0 then
			E2Sounds[index].DieTime = CurTime() + time
			setFadeVolume(E2Sounds[index], 0, time)
		else
			E2Sounds[index].SoundChannel:Stop()
		end
	end
end)

net.Receive("e2_soundremove",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		E2Sounds[index].SoundChannel:Stop()
		E2Sounds[index] = nil
	end
end)
	
net.Receive("e2_soundvolume",function()
	local index = net.ReadString()	
	
	if E2Sounds[index] then
		local volume =  net.ReadDouble()
		local time = net.ReadDouble()
		if time>0 then
			setFadeVolume(E2Sounds[index], volume, time)
		else
			E2Sounds[index].SoundChannel:SetVolume(volume)
		end
	end
end)

net.Receive("e2_soundpitch",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		local rate = net.ReadDouble()
		local time = net.ReadDouble()
		if time>0 then
			setFadePitch(E2Sounds[index], rate, time)
		else
			E2Sounds[index].SoundChannel:SetPlaybackRate(rate)
		end
	end
end)

net.Receive("e2_soundfadedist",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		local min = net.ReadDouble()
		local max = net.ReadDouble()
		E2Sounds[index].SoundChannel:Set3DFadeDistance(min, max)
	end
end)

net.Receive("e2_soundsetlooping",function()
	local index = net.ReadString()
	
	if E2Sounds[index] then
		E2Sounds[index].SoundChannel:EnableLooping( net.ReadUInt(8) > 0 )
	end
end)