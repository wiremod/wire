WireLib.Sound = WireLib.Sound or {}
local lib = WireLib.Sound

local LoopedCache = {}

local function Riff_ReadChunkHeader(fil)
    local id = fil:Read(4)
    local content_len = fil:ReadULong()
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
    print(path, looped)
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
function sound.Play(...)
    hook.Run("Wire_SoundPlay", ...)

    sound.Play_NoWireHook(...)
end