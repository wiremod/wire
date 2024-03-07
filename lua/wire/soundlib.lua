WireLib.Sound = WireLib.Sound or {}
local lib = WireLib.Sound

local LoopedCache = {}

local function Riff_ReadChunkHeader(fil)
    local id = fil:Read(4)
    local content_len = fil:ReadULong()
    if content_len == nil then return nil, nil end

    content_len = content_len + bit.band(content_len, 1)

    return id, content_len
end

local function WavIsLooped_Impl(path)
    local fil = file.Open(path, "r", "GAME")
    if fil == nil then
        return false
    end

    local id, _ = Riff_ReadChunkHeader(fil)
    if id ~= "RIFF" then return false end -- Invalid header
    if fil:Read(4) ~= "WAVE" then return false end -- Invalid second header

    local resultid

    while true do
        local id, len = Riff_ReadChunkHeader(fil)
        if id == "cue " or id == "smpl" then resultid = id break end
        if id == nil then
            ErrorNoHaltWithStack("WavIsLooped_Impl: Can't analyze file ", path)
            return false
        end -- Some error

        local p1 = fil:Tell()
        local pnext = p1 + len

        if pnext == fil:Size() then return false end -- End of file
        fil:Seek(pnext)
    end

    if resultid == "cue " then
        local cue_count = fil:ReadULong()
        fil:Close()

        return cue_count ~= 0
    elseif resultid == "smpl" then
        fil:Skip(7*4)
        local sampler_count = fil:ReadULong()
        fil:Close()

        return sampler_count ~= 0
    end


end

local function WavIsLooped(path)
    if LoopedCache[path] ~= nil then return LoopedCache[path] end

    local looped = WavIsLooped_Impl(path)
    LoopedCache[path] = looped
    return looped
end

function lib.IsLooped(path)
    path = "sound/"..path
    local ext = string.GetExtensionFromFilename(path)
    if ext == "wav" then
        return WavIsLooped(path)
    else
        return false -- MP3s are not loopable
    end
end

local PREFIX_CHARS = {"*","#","@",">","<","^",")","(","}","$","!","?"}
local PREFIX_REGEX
do
    local chars_escaped = {}
    for i, ch in ipairs(PREFIX_CHARS) do
        chars_escaped[i] = string.PatternSafe(ch)
    end

    PREFIX_REGEX = "^["..table.concat(chars_escaped).."]+"
end



function lib.StripPrefix(path)
    return string.gsub(path, PREFIX_REGEX, "")
end

sound.Play_NoWireHook = sound.Play_NoWireHook or sound.Play
function sound.Play(snd, pos, level, pitch, volume, ...)
    hook.Run("Wire_SoundPlay", snd, pos, level or 75, pitch or 100, volume or 1, ...)

    sound.Play_NoWireHook(snd, pos, level, pitch, volume, ...)
end


local CVAR_snd_refdb = GetConVar("snd_refdb")
local CVAR_snd_refdist = GetConVar("snd_refdist")
local MAX_DIST_GAIN = 1000

function lib.CalculateDistanceGain(dist, sndlevel)
    -- See SNDLVL_TO_DIST_MULT in engine/audio/private/snd_dma.cpp
    -- See SND_GetGainFromMult in engine/sound_shared.cpp

    local finalsndlevel = CVAR_snd_refdb:GetFloat() - sndlevel
    local distMul = math.pow(10, finalsndlevel / 20) / CVAR_snd_refdist:GetFloat()

    local gain = 1/(distMul * dist)

    return math.min(gain, MAX_DIST_GAIN) -- No infinities
end

-- Maximum distance from player to adv_microphone and from adv_speaker to player, in which voice can be heard
lib.VOICE_MAXDIST_SQR = 250 * 250

lib._DCACHE = lib._DCACHE or {}
local DCACHE = lib._DCACHE
DCACHE.__index = DCACHE

--[[
    struct PlayerDistanceCache {
        fn :Think()

        readonly .PlayersInRange: table(Player, true)
    }

    fn WireLib.Sound.NewPlayerDistanceCache(ent: Entity, max_dist_sqr: number) -> PlayerDistanceCache
]]

function lib.NewPlayerDistanceCache(ent, max_dist_sqr)
    local obj = setmetatable({
        _ent = ent,
        _maxDistSqr = max_dist_sqr,
        PlayersInRange = {}
    }, DCACHE)

    return obj
end

function DCACHE:Think()
    local ent = self._ent
    if not IsValid(ent) then return end

    local plys = {}
    self.PlayersInRange = plys

    local entPos = ent:GetPos()
    local maxDistSqr = self._maxDistSqr

    for _, ply in ipairs(player.GetHumans()) do
        if ply:GetPos():DistToSqr(entPos) < maxDistSqr then
            plys[ply] = true
        end
    end
end