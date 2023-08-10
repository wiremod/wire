AddCSLuaFile()

local MIN_VOLUME = 0.001
local SPEAKER_VOLUME_COEFF = 0.4 -- Additionally lower volume of sounds from wire speakers to prevent feedback loops
local MAX_DIST_GAIN = 1000

local PLAYER_VOICE_MAXDIST_SQR = 250*250

ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.Author = "stpM64"
ENT.PrintName = "Wire Advanced Microphone"
ENT.Purpose = "Listens to sounds, soundscapes and player voices"
-- Named 'advanced' because 'gmod_wire_microphone' exists in Wire Extras
ENT.WireDebugName = "Advanced Microphone"

-- Note: we listen both serverside and clientside,
-- because some sounds are played clientside only

-- array(Entity(gmod_wire_adv_microphone))
-- Array instead of lookup table because sounds are emitted more often than microphones switched on or off,
-- so iteration is more frequent than insertion/removal.
-- Microphone is live when it is active and at least one active speaker connected to it. 
_WireLiveMicrophones = _WireLiveMicrophones or {}
local LiveMics = _WireLiveMicrophones

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
    self:NetworkVarNotify("Active",self.OnActiveChanged)
end

function ENT:Initialize()
    if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        self.Inputs = WireLib.CreateInputs(self, {
            "Active"
        })
    end

    -- table(Entity(gmod_wire_adv_speaker), true)
    self._activeSpeakers = {}

    -- Callback not called if 'Active' changes right after creation.
    self:OnActiveChanged(nil, nil, self:GetActive())
end

function ENT:SetLive(isLive)
    if self:GetLive() == isLive then return end

    if isLive then
        table.insert(LiveMics, self)
    else
        table.RemoveByValue(LiveMics, self)
    end
end

function ENT:GetLive()
    return self:GetActive() and not table.IsEmpty(self._activeSpeakers)
end

function ENT:OnActiveChanged(_,_,active)
    if table.IsEmpty(self._activeSpeakers) then return end
    self:SetLive(active)
end

function ENT:TriggerInput( name, value )
    if name == "Active" then
        self:SetActive(value ~= 0)
    end
end

function ENT:SpeakerActivated(speaker)
    if not IsValid(speaker) then return end

    if self:GetActive() then
        -- Must be updated before ._activeSpeakers are updated
        self:SetLive(true)
    end
    self._activeSpeakers[speaker] = true
end

local function table_IsEmptyOrSingle(tbl)
    local k1 = next(tbl)
    if k1 == nil then return true end

    local k2 = next(tbl, k1)
    return k2 == nil
end

function ENT:SpeakerDeactivated(speaker)
    if self:GetActive() then
        local live = true
        do
            local spk = self._activeSpeakers

            local k1 = next(spk)
            if k1 == nil then -- No active speakers
                live = false
            else
                local k2 = next(spk)
                if k2 == nil and k1 == speaker then -- The only active speaker is 'speaker'
                    live = false
                end
            end
        end

        -- Must be updated before ._activeSpeakers are updated
        self:SetLive(live)
    end
    self._activeSpeakers[speaker] = nil
end

function ENT:OnRemove()
    timer.Simple(0, function()
        if IsValid(self) then return end

        self:SetLive(false)
    end)
end

local CVAR_snd_refdb = GetConVar("snd_refdb")
local CVAR_snd_refdist = GetConVar("snd_refdist")

local function CalculateDistanceGain(dist, sndlevel)
    -- See SNDLVL_TO_DIST_MULT in engine/audio/private/snd_dma.cpp
    -- See SND_GetGainFromMult in engine/sound_shared.cpp

    local finalsndlevel = CVAR_snd_refdb:GetFloat() - sndlevel 
    local distMul = math.pow(10, finalsndlevel / 20) / CVAR_snd_refdist:GetFloat()

    local gain = 1/(distMul * dist)

    return math.min(gain, MAX_DIST_GAIN) -- No infinities
end




hook.Add("EntityEmitSound", "Wire.AdvMicrophone", function(snd)
    for _, mic in ipairs(LiveMics) do
        mic:HandleEngineSound(snd)
    end
end)

function ENT:HandleEngineSound(snd)
    local volume = snd.Volume

    if IsValid(snd.Entity) 
        and snd.Entity:GetType() == "gmod_wire_adv_speaker" 
    then 
        volume = volume * SPEAKER_VOLUME_COEFF
    end

    local sndlevel = snd.SoundLevel
    if sndlevel ~= 0 then
        -- Over-256 values are 'reserved for sounds using goldsrc compatibility attenuation'
        -- I don't care about correct attenuation for HLSource entities,
        -- but I don't want the system to break. 
        if sndlevel >= 256 then sndlevel = sndlevel - 256 end
        
        volume = volume * CalculateDistanceGain(
            self:GetPos():Distance(snd.Pos), sndlevel)
    end
    if volume < MIN_VOLUME then return end

    self:ReproduceSound(snd.SoundName, volume, snd.Pitch, snd.DSP)
end

function ENT:ReproduceSound(snd, vol, pitch, dsp)
    for _, speaker in ipairs(_activeSpeakers) do
        speaker:ReproduceSound(snd, vol, pitch, dsp)
    end
end

hook.Add("PlayerCanHearPlayersVoice", "Wire.AdvMicrophone", function(listener, talker)
    local talkerPos = talker:GetPos()
    local listenerPos = listener:GetPos()

    local speakers = {}
    -- Note: any given speaker can only be connected to one microphone,
    -- so this loops can be considered O(nMic), not O(nMic*nSpeaker)
    for _, mic in ipairs(LiveMics) do
        if mic:GetPos():DistToSqr(talkerPos) > PLAYER_VOICE_MAXDIST_SQR then continue end

        for _, speaker in ipairs(mic._activeSpeakers) do
            if not IsValid(speaker) then continue end
            
            if speaker:GetPos():DistToSqr(listenerPos) <= PLAYER_VOICE_MAXDIST_SQR then
                return true, false -- Can hear, not in 3D
            end
        end
    end
end)