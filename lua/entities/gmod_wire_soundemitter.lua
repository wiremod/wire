--[[
 The Wire Sound Emitter emits a sound whose parameters can be tweaked.
 See http://wiki.garrysmod.com/page/Category:CSoundPatch
--]]

AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Sound Emitter"
ENT.WireDebugName = "Sound Emitter"

if CLIENT then return end

local DefaultSamples = {
	"synth/square.wav",
	"synth/saw.wav",
	"synth/tri.wav",
	"synth/sine.wav"
}

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "A", "Toggle", "Volume", "Play", "Stop",
		"PitchRelative", "Sample", "SampleName [STRING]", "Level" })
	self.Outputs = WireLib.CreateOutputs(self, { "Duration", "Property Sound", "Properties [ARRAY]", "Memory" })

	self.Samples = table.Copy(DefaultSamples)

	self.Active = false
	self.Volume = 100
	self.Level = 80
	self.Pitch = 100
	self.sound = self.Samples[1]
	-- self.sound is a string, self.SoundObj is a CSoundPatch

	self.NeedsRefresh = true

	hook.Add("PlayerConnect", self:GetClass() .. self:EntIndex(), function()
		self.NeedsRefresh = true
	end)
end

function ENT:OnRemove()
	hook.Remove("PlayerConnect", self:GetClass() .. self:EntIndex())
	self:StopSounds()
	BaseClass.OnRemove(self)
end

--[[
	readcells:
	0: active
	1: volume
	2: pitchrelative
	3: duration
	6: level
]]
function ENT:ReadCell(address)
	address = math.floor(address)
	if address == 0 then
		return self.Active and 1 or 0
	elseif address == 1 then
		return self.Volume / 100
	elseif address == 2 then
		return self.Pitch / 100
	elseif address == 3 then
		return self.Outputs.Duration.Value
	elseif address == 6 then
		return self.Level
	end
end


-- writecells:
local cellsOut = {
	[0] = "A",
	[1] = "Volume",
	[2] = "PitchRelative",
	[3] = "Sample",
	[4] = "Play",
	[5] = "Stop",
	[6] = "Level",
}

function ENT:WriteCell(address, value)
	address = math.floor(address)
	if cellsOut[address] then
		self:TriggerInput(cellsOut[address], value)
		return true
	else
		return false
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "Toggle" and value ~= 0 then
		self:TriggerInput("A", not self.Active)
	elseif iname == "A" then
		if value ~= 0 then
			self:TriggerInput("Play", 1)
		else
			self:TriggerInput("Stop", 1)
		end
	elseif iname == "Play" and value ~= 0 then
		-- Property sounds need to be refreshed
		-- every time to work probably especially
		-- when it has multiple sounds/pitches/volumes.
		if self.SoundProperties then
			self.NeedsRefresh = true
			WireLib.TriggerOutput(self, "Duration", SoundDuration(self.sound))
		end

		self.Active = true
		self:StartSounds()
	elseif iname == "Stop" and value ~= 0 then
		self.Active = false
		self:StopSounds()
	elseif iname == "Volume" then
		self.Volume = math.Clamp(math.floor(value*100), 0.0, 100.0)
	elseif iname == "Level" then
		self.Level = math.Clamp(value, 55.0, 165.0)
	elseif iname == "PitchRelative" then
		self.Pitch = math.Clamp(math.floor(value*100), 0, 255)
	elseif iname == "Sample" then
		self:TriggerInput("SampleName", self.Samples[value] or self.Samples[1])
	elseif iname == "SampleName" then
		self:SetSound(value)
	end
	self:UpdateSound()
end

function ENT:UpdateSound()
	if self.NeedsRefresh or self.sound ~= self.ActiveSample then

		self.NeedsRefresh = nil
		local filter = RecipientFilter()
		filter:AddAllPlayers()

		if self.SoundObj then
			self.SoundObj:Stop()
			self.SoundObj = nil
		end

		self.SoundObj = CreateSound(self, self.sound, filter)
		self.ActiveSample = self.sound

		self.SoundProperties = sound.GetProperties(self.sound)
		if self.SoundProperties then
			WireLib.TriggerOutput(self, "Duration", SoundDuration(self.sound))
			WireLib.TriggerOutput(self, "Property Sound", 1)
			WireLib.TriggerOutput(self, "Properties", self.SoundProperties)
		else
			WireLib.TriggerOutput(self, "Property Sound", 0)
			WireLib.TriggerOutput(self, "Properties", {})
		end

		if self.Active then self:StartSounds() end
	end
	self.SoundObj:ChangePitch(self.Pitch, 0)
	self.SoundObj:ChangeVolume(self.Volume / 100.0, 0)
	self.SoundObj:SetSoundLevel(self.Level)
end

function ENT:SetSound(soundName)
	self:StopSounds()

	soundName = WireLib.SoundExists(soundName)
	if not soundName then return end

	self.sound = soundName

	self.SoundProperties = sound.GetProperties(soundName)
	if self.SoundProperties then
		WireLib.TriggerOutput(self, "Duration", SoundDuration(soundName))
		WireLib.TriggerOutput(self, "Property Sound", 1)
		WireLib.TriggerOutput(self, "Properties", self.SoundProperties)
	else
		WireLib.TriggerOutput(self, "Property Sound", 0)
		WireLib.TriggerOutput(self, "Properties", {})
	end

	self:SetOverlayText(soundName)
end

function ENT:StartSounds()
	if self.NeedsRefresh then
		self:UpdateSound()
	end
	if self.SoundObj then
		self.SoundObj:Play()
	end
end

function ENT:StopSounds()
	if self.SoundObj then
		self.SoundObj:Stop()
	end
end

function ENT:Setup(sample)
	self:SetSound(sample)
end

duplicator.RegisterEntityClass("gmod_wire_soundemitter", WireLib.MakeWireEnt, "Data", "sound")
