/******************************************************************************\
  Built-in Sound support v1.18
\******************************************************************************/

E2Lib.RegisterExtension("sound", true)

local wire_expression2_maxsounds = CreateConVar( "wire_expression2_maxsounds", 16, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_max = CreateConVar( "wire_expression2_sound_burst_max", 8, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_rate = CreateConVar( "wire_expression2_sound_burst_rate", 0.1, {FCVAR_ARCHIVE} )
local wire_expression2_sound_allowurl = CreateConVar( "wire_expression2_sound_allowurl", 0, {FCVAR_ARCHIVE} )

---------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------

local function isAllowed( self )
	local data = self.data.sound_data
	local count = data.count
	if count == wire_expression2_maxsounds:GetInt() then return false end
	
	if data.burst == 0 then return false end
	
	data.burst = data.burst - 1
	
	local timerid = "E2_sound_burst_count_" .. self.entity:EntIndex()
	if not timer.Exists( timerid ) then
		timer.Create( timerid, wire_expression2_sound_burst_rate:GetFloat(), 0, function()
			if not IsValid( self.entity ) then
				timer.Remove( timerid )
				return
			end
				
			data.burst = data.burst + 1
			if data.burst == wire_expression2_sound_burst_max:GetInt() then
				timer.Remove( timerid )
			end
		end)
	end
	
	return true
end

local function getSound( self, index )
	if isnumber( index ) then index = math.floor( index ) end
	return self.data.sound_data.sounds[index]
end

local function soundStop(self, index, fade)
	local sound = getSound( self, index )
	if not sound then return end
	
	fade = math.abs( fade )
	
	if fade == 0 then
		sound:Stop()
		
		if isnumber( index ) then index = math.floor( index ) end
		self.data.sound_data.sounds[index] = nil
		
		self.data.sound_data.count = self.data.sound_data.count - 1
	else
		sound:FadeOut( fade )
		
		timer.Simple( fade, function() soundStop( self, index, 0 ) end)
	end
	
	timer.Remove( "E2_sound_stop_" .. self.entity:EntIndex() .. "_" .. index )
end

local ClientSideSound = {}
ClientSideSound.mt = {__index = ClientSideSound}

ClientSideSound.SendIndex = function(self)
	umsg.String(self.e2:EntIndex() .. "_" .. self.index)
end
	
ClientSideSound.CreateSound = function(path, index, e2, entity) 
	local self = setmetatable({index = index, e2 = e2},ClientSideSound.mt)
	umsg.Start("e2_soundurlcreate")
		self:SendIndex()
		umsg.String(path)
		umsg.Entity(entity)
	umsg.End()
	return self
end
	
ClientSideSound.Play = function() end
	
ClientSideSound.Stop = function(self)
	umsg.Start("e2_soundurlstop")
		self:SendIndex()
	umsg.End()
end
	
ClientSideSound.ChangeVolume = function(self, vol)
	umsg.Start("e2_soundurlvolume")
		self:SendIndex()
		umsg.Float(vol)
	umsg.End()
end
	
ClientSideSound.ChangePitch = function(self, pitch)
	umsg.Start("e2_soundurlpitch")
		self:SendIndex()
		umsg.Float(math.Clamp(pitch,0,2))
	umsg.End()
end
	
ClientSideSound.FadeOut = function(self)
	self:Stop()
end

local function soundCreate(self, entity, index, time, path, fade)
	if not isAllowed( self ) then return end
	
	if isnumber( index ) then index = math.floor( index ) end
	local timerid = "E2_sound_stop_" .. self.entity:EntIndex() .. "_" .. index
	
	local data = self.data.sound_data
	local oldsound = getSound( self, index )
	if oldsound then
		oldsound:Stop()
		timer.Remove( timerid )
	end
	
	local sound
	if path:sub(1,4)=="http" then
		if wire_expression2_sound_allowurl:GetInt()==0 then return end
		sound = ClientSideSound.CreateSound(path,index,self.entity,entity)
	else
		if path:match('["?]') then return end
		path = path:Trim()
		path = path:gsub( "\\", "/" )
		sound = CreateSound( entity, path )
	end
	
	data.sounds[index] = sound
	sound:Play()
	
	entity:CallOnRemove( "E2_stopsound", function()
		soundStop( self, index, 0 )
	end )
	
	if time == 0 and fade == 0 then return end
	time = math.abs( time )
	
	timer.Create( timerid, time, 1, function()
		if not self or not IsValid( self.entity ) or not IsValid( entity ) then return end
		
		soundStop( self, index, fade )
	end)
	
	if not oldsound then
		data.count = data.count + 1
	end
end

local function soundPurge( self )
	local sound_data = self.data.sound_data
	if sound_data.sounds then
		for k,v in pairs( sound_data.sounds ) do
			v:Stop()
			timer.Remove( "E2_sound_stop_" .. self.entity:EntIndex() .. "_" .. k )
		end
	end
	
	sound_data.sounds = {}
	sound_data.count = 0
end

---------------------------------------------------------------
-- Play functions
---------------------------------------------------------------

__e2setcost(25)

e2function void soundPlay( index, duration, string path )
	soundCreate(self,self.entity,index,duration,path,0)
end

e2function void entity:soundPlay( index, duration, string path)
	if not IsValid(this) or not isOwner(self, this) then return end
	soundCreate(self,this,index,duration,path,0)
end

e2function void soundPlay( index, duration, string path, fade )
	soundCreate(self,self.entity,index,duration,path,fade)
end

e2function void entity:soundPlay( index, duration, string path, fade )
	if not IsValid(this) or not isOwner(self, this) then return end
	soundCreate(self,this,index,duration,path,fade)
end

e2function void soundPlay( string index, duration, string path ) = e2function void soundPlay( index, duration, string path )
e2function void entity:soundPlay( string index, duration, string path ) = e2function void entity:soundPlay( index, duration, string path )
e2function void soundPlay( string index, duration, string path, fade ) = e2function void soundPlay( index, duration, string path, fade )
e2function void entity:soundPlay( string index, duration, string path, fade ) = e2function void entity:soundPlay( index, duration, string path, fade )

---------------------------------------------------------------
-- Modifier functions
---------------------------------------------------------------

__e2setcost(5)

e2function void soundStop( index )
	soundStop(self, index, 0)
end

e2function void soundStop( index, fadetime )
	soundStop(self, index, fadetime)
end

e2function void soundVolume( index, volume )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangeVolume( math.Clamp( volume, 0, 1 ), 0 )
end

e2function void soundVolume( index, volume, fadetime )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangeVolume( math.Clamp( volume, 0, 1 ), math.abs( fadetime ) )
end
	

e2function void soundPitch( index, pitch )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangePitch( math.Clamp( pitch, 0, 255 ), 0 )
end

e2function void soundPitch( index, pitch, fadetime )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangePitch( math.Clamp( pitch, 0, 255 ), math.abs( fadetime ) )
end


e2function void soundStop( string index ) = e2function void soundStop( index )
e2function void soundStop( string index, fadetime ) = e2function void soundStop( index, fadetime )
e2function void soundVolume( string index, volume ) = e2function void soundVolume( index, volume )
e2function void soundVolume( string index, volume, fadetime ) = e2function void soundVolume( index, volume, fadetime )
e2function void soundPitch( string index, pitch ) = e2function void soundPitch( index, pitch )
e2function void soundPitch( string index, pitch, fadetime ) = e2function void soundPitch( index, pitch, fadetime )

---------------------------------------------------------------
-- Other
---------------------------------------------------------------

e2function void soundPurge()
	soundPurge( self )
end

e2function number soundDuration(string sound)
	return SoundDuration(sound) or 0
end

---------------------------------------------------------------

registerCallback("construct", function(self)
	self.data.sound_data = {}
	self.data.sound_data.burst = wire_expression2_sound_burst_max:GetInt()
	self.data.sound_data.sounds = {}
	self.data.sound_data.count = 0
end)

registerCallback("destruct", function(self)
	soundPurge( self )
end)
