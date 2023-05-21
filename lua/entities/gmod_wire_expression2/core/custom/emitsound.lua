E2Lib.RegisterExtension("emitsound", true, "Adds simplier way to play sounds with E2")
    -- This is actually safer that 'sound' core, as sounds can only be played from player-owned entities

local max_soundlevel = GetConVar("wire_expression2_sound_level_max")

local function EmitSound(e2, ent, snd, level, pitch, volume)
    if not E2Lib.SoundLib.isAllowed(e2) then return end

	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

    local maxlevel = max_soundlevel:GetInt()
    if level ~= nil and level > maxlevel then
        level = maxlevel
    end

    ent:EmitSound(snd, level, pitch, volume)
end

__e2setcost(20)
e2function void entity:emitSound(string soundName, number soundLevel, number pitchPercent, number volume)
    EmitSound(self, this, soundName, soundLevel, pitchPercent, volume)
end

e2function void entity:emitSound(string soundName, number soundLevel, number pitchPercent)
    EmitSound(self, this, soundName, soundLevel, pitchPercent)
end

e2function void entity:emitSound(string soundName, number soundLevel)
    EmitSound(self, this, soundName, soundLevel)
end

e2function void entity:emitSound(string soundName)
    EmitSound(self, this, soundName)
end

e2function void entity:emitSoundStop(string soundName)
    if not IsValid(this) then return self:throw("Invalid entity!", nil) end
    if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

    this:StopSound(soundName)
end