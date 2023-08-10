WireLib.Sound = WireLib.Sound or {}
local lib = WireLib.Sound

local LoopedCache = {}

local function Riff_ReadChunkHeader(fil)
    local id = fil:Read(4)
    local content_len = fil:ReadULong()
    local next_chunk_offs = content_len
    if next_chunk_offs % 2 == 1 then next_chunk_offs = next_chunk_offs + 1 end
    print(id, content_len, next_chunk_offs)

    return id, content_len, next_chunk_offs
end

local function WavIsLooped_Impl(path)
    local fil = file.Open(path, "r", "GAME")
    if fil == nil then 
        return false
    end

    local id, len, nextoffs = Riff_ReadChunkHeader(fil)
    if id ~= "RIFF" then return false end -- Invalid header
    local id, len, nextoffs = Riff_ReadChunkHeader(fil)
    if id ~= "WAVE" then return false end -- Invalid second header

    while true do
        local id, len, nextoffs = Riff_ReadChunkHeader(fil)
        if id == "cue " then break end

        fil:Skip(nextoffs)
    end

    local cue_count = fil:ReadULong()
    fil:Close()

    --[[
    // assume that the cue chunk stored in the wave is the start of the loop
	// assume only one cue chunk, UNDONE: Test this assumption here?
	cueCount = walk.ChunkReadInt();
	if ( cueCount > 0 )
	{
		walk.ChunkReadPartial( &cue_chunk, sizeof(cue_chunk) );
		m_loopStart = LittleLong( cue_chunk.dwSampleOffset );
	}
    ]]

    return cue_count ~= 0
end

local function WavIsLooped(path)
    if LoopedCache[path] ~= nil then return LoopedCache[path] end

    local looped = WavIsLooped_Impl(path)
    LoopedCache[path] = looped
    return looped
end

function lib.IsLooped(path)
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