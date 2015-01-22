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
for _, str in pairs(DefaultSamples) do util.PrecacheSound(str) end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "Toggle", "Volume", "Play", "Stop",
		"PitchRelative", "Sample", "SampleName [STRING]" })
	self.Outputs = Wire_CreateOutputs(self, { "Duration", "Property Sound", "Properties [ARRAY]", "Memory" })

	self.Samples = table.Copy(DefaultSamples)

	self.Active = false
	self.Volume = 100
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
	self.BaseClass.OnRemove(self)
end

function ENT:ReadCell(address)
	return nil
end

local cellsOut = {
	[0] = "A",
	[1] = "Volume",
	[2] = "PitchRelative",
	[3] = "Sample"
}

function ENT:WriteCell(address, value)
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
		// Property sounds need to be refreshed
		// every time to work probably especially
		// when it has multiple sounds/pitches/volumes.
		if self.SoundProperties then
			self.NeedsRefresh = true
			Wire_TriggerOutput(self, "Duration", SoundDuration(self.sound))
		end

		self.Active = true
		self:StartSounds()
	elseif iname == "Stop" and value ~= 0 then
		self.Active = false
		self:StopSounds()
	elseif iname == "Volume" then
		self.Volume = math.Clamp(math.floor(value*100), 0.0, 100.0)
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
		self.SoundObj = CreateSound(self, self.sound)
		self.ActiveSample = self.sound

		self.SoundProperties = sound.GetProperties(self.sound)
		if self.SoundProperties then
			Wire_TriggerOutput(self, "Duration", SoundDuration(self.sound))
			Wire_TriggerOutput(self, "Property Sound", 1)
			Wire_TriggerOutput(self, "Properties", self.SoundProperties)
		else
			Wire_TriggerOutput(self, "Property Sound", 0)
			Wire_TriggerOutput(self, "Properties", {})
		end

		if self.Active then self:StartSounds() end
	end
	self.SoundObj:ChangePitch(self.Pitch, 0)
	self.SoundObj:ChangeVolume(self.Volume / 100.0, 0)
end

function ENT:SetSound(soundName)
	self:StopSounds()

	if soundName:match('["?]') then return end
	parsedsound = soundName:Trim()
	util.PrecacheSound(parsedsound)

	self.sound = parsedsound

	self.SoundProperties = sound.GetProperties(self.sound)
	if self.SoundProperties then
		Wire_TriggerOutput(self, "Duration", SoundDuration(self.sound))
		Wire_TriggerOutput(self, "Property Sound", 1)
		Wire_TriggerOutput(self, "Properties", self.SoundProperties)
	else
		Wire_TriggerOutput(self, "Property Sound", 0)
		Wire_TriggerOutput(self, "Properties", {})
	end

	self:SetOverlayText( parsedsound:gsub("[/\\]+","/") )
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
