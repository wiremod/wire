AddCSLuaFile()

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

    self._activeSpeakers[speaker] = true
end

function ENT:SpeakerDeactivated(speaker)
    self._activeSpeakers[speaker] = nil
end

hook.Add("EntityEmitSound", "Wire.AdvMicrophone", function(snd)
    
end)