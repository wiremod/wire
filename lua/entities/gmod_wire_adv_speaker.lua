AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.Author = "stpM64"
ENT.PrintName = "Wire Advanced Speaker"
ENT.Purpose = "Reproduces sounds, soundscapes and player voices listened by Advanced Microphone"
ENT.WireDebugName = "Advanced Speaker"

-- TODO: notify of microphone connection when loading from duplication

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
    self:NetworkVar("Entity", 0, "Microphone")
    self:NetworkVarNotify("Microphone",self.OnMicrophoneChanged)
end

if SERVER then
    function ENT:Initialize()
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        self.Inputs = WireLib.CreateInputs(self, {
            "Active",
            "Microphone (Must be Wire Advanced Microphone to work) [ENTITY]"
        })
    end
end

function ENT:TriggerInput( name, value )
    if name == "Active" then
        self:SetActive(value ~= 0)
    elseif name == "Microphone" then
        if not (IsValid(value) and value:GetType() == "gmod_wire_adv_microphone") then
            value = nil
        end

        self:SetMicrophone(value)
    end
end

function ENT:OnMicrophoneChanged(_, oldmic, newmic)
    if oldmic ~= newmic then
        if IsValid(oldmic) then
            oldmic:SpeakerDeactivated(self)
        end
        
        if IsValid(newmic) then
            newmic:SpeakerActivated(self)
        end
    end
end

function ENT:OnRemove()
    local mic = self:GetMicrophone()
    if not IsValid(mic) then return end

    timer.Simple(0, function()
        if IsValid(self) or not IsValid(mic) then return end
        mic:SpeakerDisconSpeakerDeactivatednected(self)
    end)
end