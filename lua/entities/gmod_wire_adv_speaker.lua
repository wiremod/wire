AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.Author = "stpM64"
ENT.PrintName = "Wire Advanced Speaker"
ENT.Purpose = "Reproduces sounds, soundscapes and player voices listened by Advanced Microphone"
ENT.WireDebugName = "Advanced Speaker"

-- TODO: stop currently played EmitSound sounds on deactivation 

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
    self:NetworkVarNotify("Active", self.OnActiveChanged)
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

        self:OnMicrophoneChanged(nil, nil, self:GetMicrophone())
    end
end

function ENT:TriggerInput( name, value )
    if name == "Active" then
        self:SetActive(value ~= 0)
    elseif name == "Microphone" then
        if not (IsValid(value) and value:GetClass() == "gmod_wire_adv_microphone") then
            value = nil
        end

        self:SetMicrophone(value)
    end
end

function ENT:OnActiveChanged(_, oldactive, active)
    if oldactive == active then return end

    local mic = self:GetMicrophone()
    if not IsValid(mic) then return end

    if active then
        mic:SpeakerActivated(self)
    else
        mic:SpeakerDeactivated(self)
    end
end

function ENT:OnMicrophoneChanged(_, oldmic, newmic)
    if self:GetActive() and oldmic ~= newmic then
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
        mic:SpeakerDeactivated(self)
    end)
end

function ENT:ReproduceSound(snd, vol, pitch, dsp, emittype)
    if not self:GetActive() then return end

    if WireLib.Sound.IsLooped(WireLib.Sound.StripPrefix(snd)) then
        return
    end


    local soundlevel = 75
    if emittype == "EmitSound" then
        self:EmitSound(snd, soundlevel, pitch, vol, nil, nil, dsp)
    elseif emittype == "sound.Play" then
        sound.Play_NoWireHook(snd, self:GetPos(), soundlevel, pitch, vol)
    else
        ErrorNoHalt("Invalid emittype: ", emittype,"\n --sound ",snd)
    end
end

duplicator.RegisterEntityClass("gmod_wire_adv_speaker", WireLib.MakeWireEnt, "Data")