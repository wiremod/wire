local URLSounds = {}

usermessage.Hook("e2_soundurlcreate",function(u)
	local index = u:ReadString(u)
	local path = u:ReadString()
	local ent = u:ReadEntity()
	
	sound.PlayURL (path, "3d", function( station, errorid, errorname )
		if IsValid(station) then
			URLSounds[index] = {SoundChannel = station, Entity = ent}
			station:Set3DFadeDistance(500, 2000)
		end
	end)
end)

usermessage.Hook("e2_soundurlstop",function(u)
	local index = u:ReadString(u)
	if URLSounds[index] then
		URLSounds[index].SoundChannel:Stop()
		URLSounds[index] = nil
	end
end)

usermessage.Hook("e2_soundurlvolume",function(u)
	local index = u:ReadString(u)
	local volume = u:ReadFloat()
	
	if URLSounds[index] then
		URLSounds[index].SoundChannel:SetVolume(volume)
	end
end)

usermessage.Hook("e2_soundurlpitch",function(u)
	local index = u:ReadString(u)
	local rate = u:ReadFloat()
	
	if URLSounds[index] then
		URLSounds[index].SoundChannel:SetPlaybackRate(rate)
	end
end)

hook.Add("Think", "E2_sound_move",function()
	for k,v in pairs(URLSounds) do
		if IsValid(v.SoundChannel) then
			if IsValid(v.Entity) then
				v.SoundChannel:SetPos(v.Entity:GetPos())
			else
				v.SoundChannel:Stop()
				URLSounds[k] = nil
			end
		else
			URLSounds[k] = nil
		end
	end
end)