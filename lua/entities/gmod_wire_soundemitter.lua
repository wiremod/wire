
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Sound"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self, { "A", "Toggle", "Volume", "Play", "Stop",
		"PitchRelative", "LFOType", "LFORate", "LFOModPitch", "LFOModVolume", "Sample" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })

	self.Active = 0
	self.Volume = 5
	self.Pitch = 100

	self.SampleTable = {}
	self.SampleTable[0] = "synth/square.wav"
	self.SampleTable[1] = "synth/square.wav"
	self.SampleTable[2] = "synth/saw.wav"
	self.SampleTable[3] = "synth/tri.wav"
	self.SampleTable[4] = "synth/sine.wav"

	//LFO:
	// 0 - none
	// 1 - square
	// 2 - tri
	// 3 - saw
	// 4 - sine
	// 5 - random noise

	self.LFOType = 0
	self.LFORate = 0
	self.LFOModPitch = 0
	self.LFOModVolume = 0
	self.Sample = 0

	self.LFOValue = 0
	self.LFONoiseTime = 0

//	note = 69+12 * log2(f/440)
//	f = (2^((note - 69) / 12))*440
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	self:StopSounds()
end

function ENT:ReadCell(Address)
	if (Address < 0) || (Address > 8) then
		return nil
	else
		return 0
	end
end

function ENT:WriteCell(Address, value)
	if (Address == 0) then
		self:TriggerInput("A",value)
	elseif (Address == 1) then
		self:TriggerInput("Volume",value)
	elseif (Address == 2) then
		self:TriggerInput("PitchRelative",value)
	elseif (Address == 3) then
		self:TriggerInput("Sample",value)
	elseif (Address == 4) then
		self:TriggerInput("LFOType",value)
	elseif (Address == 5) then
		self:TriggerInput("LFORate",value)
	elseif (Address == 6) then
		self:TriggerInput("LFOModPitch",value)
	elseif (Address == 7) then
		self:TriggerInput("LFOModVolume",value)
	else
		return false
	end
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local active = value >= 1
		if (self.Active == active) then return end
		self.Active = active
		if (active) then
			self:StartSounds()
			self.SND:ChangeVolume(self.Volume,0)
			self.SND:ChangePitch(self.Pitch,0)
		else
			self:StopSounds()
		end
	elseif (iname == "Toggle") then
		local active = value >= 1
		if (active) then
			self.Active = !self.Active
		end
		if (self.Active) then
			self:StartSounds()
			self.SND:ChangeVolume(self.Volume,0)
			self.SND:ChangePitch(self.Pitch,0)
		else
			self:StopSounds()
		end
	elseif (iname == "Volume") then
		local volume = math.Clamp(math.floor(value*100),0,100)
		self.Volume = volume

		self.SND:ChangeVolume(volume, 0)
	elseif (iname == "Play") then
		local active = value >= 1
		if (active) then
			self.Active = true
			self:StartSounds()
			self.SND:ChangeVolume(self.Volume,0)
			self.SND:ChangePitch(self.Pitch,0)
		end
	elseif (iname == "Stop") then
		local active = value >= 1
		if (active) then
			self.Active = false
			self:StopSounds()
		end
	elseif (iname == "PitchRelative") then
		local relpitch = math.Clamp(math.floor(value*100),0,255)
		if (self.Active) then
			self.SND:ChangePitch(relpitch,0)
		end
		self.Pitch = relpitch
	elseif (iname == "LFOType") then
		local val = math.Clamp(math.floor(value),0,5)
		self.LFOType = val
	elseif (iname == "LFORate") then
		self.LFORate = value
	elseif (iname == "LFOModPitch") then
		self.LFOModPitch = value
	elseif (iname == "LFOModVolume") then
		self.LFOModVolume = value
	elseif (iname == "Sample") then
		self:SetSample(value)
	end

//		"Toggle", "Volume", "Play", "Stop",
//		"PitchFreq", "PitchNote", "PitchRelative", "PitchStart",
//		"SpinUpTime", "SpinDownTime", "FadeInStartVolume", "FadeInTime", "FadeOutTime",
//		"LFOType", "LFORate", "LFOModPitch", "LFOModVolume",
end

function ENT:SetSound(sound)
	self:StopSounds()

	if sound:match('["?]') then return end
	parsedsound = sound:Trim()
	util.PrecacheSound(parsedsound)

	self.SampleTable[0] = parsedsound
	self.SND = CreateSound(self, Sound(self.SampleTable[0]))
	self:SetOverlayText( parsedsound:gsub("[/\\]+","/") )
end

function ENT:SetSample(sample)
	if (self.SampleTable[sample]) then
		self:StopSounds()
		self:SetSound(self.SampleTable[sample])
	end
end

function ENT:StartSounds()
	if (self.SND) then
		self.SND:Play()
	end
end

function ENT:StopSounds()
	if (self.SND) then
		self.SND:Stop()
	end
end

function ENT:Think()
	self.BaseClass.Think( self )

	if (self.LFOType == 5) then //Random noise
		if ((self.LFORate ~= 0) && (CurTime() - self.LFONoiseTime > 1 / self.LFORate)) then
			self.LFONoiseTime = CurTime()

			self.LFOValue = math.random()*2-1

			if (self.Active) then
				self.SND:ChangePitch(self.Pitch + 100*self.LFOValue*self.LFOModPitch,0)
				self.SND:ChangeVolume(self.Volume + 5*self.LFOValue*self.LFOModVolume,0)
			end
		end
	end

	self:NextThink(CurTime()+0.01)
	return true
end

function ENT:Setup( sound )
	self:SetSound( Sound(sound) )
	self.sound = sound
end

function MakeWireEmitter( pl, Pos, Ang, model, sound, nocollide, frozen )

	if ( !pl:CheckLimit( "wire_emitters" ) ) then return false end

	local wire_emitter = ents.Create( "gmod_wire_soundemitter" )
	if (!wire_emitter:IsValid()) then return false end
	wire_emitter:SetModel( model )

	wire_emitter:SetAngles( Ang )
	wire_emitter:SetPos( Pos )
	wire_emitter:Spawn()

	if wire_emitter:GetPhysicsObject():IsValid() then
		local Phys = wire_emitter:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_emitter:Setup( sound )
	wire_emitter:SetPlayer( pl )
	wire_emitter.pl	= pl
	wire_emitter.nocollide = nocollide

	pl:AddCount( "wire_emitters", wire_emitter )

	return wire_emitter

end
duplicator.RegisterEntityClass("gmod_wire_soundemitter", MakeWireEmitter, "Pos", "Ang", "Model", "sound", "nocollide", "frozen")
