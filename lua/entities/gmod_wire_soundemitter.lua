--[[
 The Wire Sound Emitter emits a sound whose parameters can be tweaked.
 See http://wiki.garrysmod.com/page/Category:CSoundPatch
--]]

AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Sound Emitter"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName = "Sound Emitter"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "Toggle", "Volume", "Play", "Stop",
		"PitchRelative", "Sample", "SampleName [STRING]" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })

	self.Samples = {
		[1] = "synth/square.wav",
		[2] = "synth/saw.wav",
		[3] = "synth/tri.wav",
		[4] = "synth/sine.wav"
	}

	self.Active = false
	self.Volume = 5
	self.Pitch = 100
	self.Sample = self.Samples[1]

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

local cells = {
	[0] = "A",
	[1] = "Volume",
	[2] = "PitchRelative",
	[3] = "Sample",
	[4] = "LFOType",
	[5] = "LFORate",
	[6] = "LFOModPitch",
	[7]= "LFOModVolume"
}

function ENT:WriteCell(address, value)
	if cells[address] then
		self:TriggerInput(cells[address], value)
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
		self.Active = true
		self:StartSounds()
	elseif iname == "Stop" and value ~= 0 then
		self.Active = false
		self:StopSounds()
	elseif iname == "Volume" then
		self.Volume = math.Clamp(math.floor(value*100), 0, 100)
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
	if self.NeedsRefresh or self.Sample ~= self.ActiveSample then
		self.NeedsRefresh = nil
		self.Sound = CreateSound(self, Sound(self.Sample))
		self.ActiveSample = self.Sample
		if self.Active then self:StartSounds() end
	end
	self.Sound:ChangePitch(self.Pitch, 0)
	self.Sound:ChangeVolume(self.Volume, 0)
end

function ENT:SetSound(soundName)
	self:StopSounds()

	if soundName:match('["?]') then return end
	parsedsound = soundName:Trim()
	util.PrecacheSound(parsedsound)

	self.Sample = parsedsound
	self:SetOverlayText( parsedsound:gsub("[/\\]+","/") )
end

function ENT:StartSounds()
	if self.NeedsRefresh then
		self:UpdateSound()
	end
	if self.Sound then
		self.Sound:Play()
	end
end

function ENT:StopSounds()
	if self.Sound then
		self.Sound:Stop()
	end
end

function ENT:Setup(sample)
	self.Sample = sample
end

duplicator.RegisterEntityClass("gmod_wire_soundemitter", MakeWireEnt, "Data", "Sample")
