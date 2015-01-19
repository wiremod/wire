/******************************************************************************\
  Built-in Sound support v1.18
\******************************************************************************/

E2Lib.RegisterExtension("sound", true)

local wire_expression2_maxsounds = CreateConVar( "wire_expression2_maxsounds", 16, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_max = CreateConVar( "wire_expression2_sound_burst_max", 8, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_rate = CreateConVar( "wire_expression2_sound_burst_rate", 0.1, {FCVAR_ARCHIVE} )
local wire_expression2_sound_allowurl = CreateConVar( "wire_expression2_sound_allowurl", 1, {FCVAR_ARCHIVE} )

util.AddNetworkString("e2_soundcreate")
util.AddNetworkString("e2_soundplay")
util.AddNetworkString("e2_soundpause")
util.AddNetworkString("e2_soundstop")
util.AddNetworkString("e2_soundremove")
util.AddNetworkString("e2_soundvolume")
util.AddNetworkString("e2_soundpitch")
util.AddNetworkString("e2_soundfadedist")
util.AddNetworkString("e2_soundsetlooping")

---------------------------------------------------------------
-- Client-side sound class
---------------------------------------------------------------

local ClientSideSound = {}
ClientSideSound.mt = {__index = ClientSideSound}
	
function ClientSideSound.CreateSound( path, time, index, entity, e2 ) 
	local self = setmetatable({index = e2:EntIndex() .. "_" .. index, path=path},ClientSideSound.mt)
	net.Start("e2_soundcreate")
		net.WriteString(self.index)
		net.WriteString(path)
		net.WriteDouble(time)
		net.WriteEntity(entity)
		net.WriteEntity(e2:GetPlayer())
	net.Broadcast()
	return self
end

function ClientSideSound:Play(time, entity)
	net.Start("e2_soundplay")
		net.WriteString(self.index)
		net.WriteDouble(time)
		net.WriteEntity(entity)
	net.Broadcast()
end

function ClientSideSound:Pause()
	net.Start("e2_soundpause")
		net.WriteString(self.index)
	net.Broadcast()
end
	
function ClientSideSound:Stop(time)
	net.Start("e2_soundstop")
		net.WriteString(self.index)
		net.WriteDouble(time)
	net.Broadcast()
end
	
function ClientSideSound:Remove()
	net.Start("e2_soundremove")
		net.WriteString(self.index)
	net.Broadcast()
end
	
function ClientSideSound:ChangeVolume(vol, time)
	net.Start("e2_soundvolume")
		net.WriteString(self.index)
		net.WriteDouble(vol)
		net.WriteDouble(time)
	net.Broadcast()
end
	
function ClientSideSound:ChangePitch(pitch, time)
	net.Start("e2_soundpitch")
		net.WriteString(self.index)
		net.WriteDouble(math.Clamp(pitch,0,2))
		net.WriteDouble(time)
	net.Broadcast()
end
	
function ClientSideSound:ChangeFadeDistance(min, max)
	net.Start("e2_soundfadedist")
		net.WriteString(self.index)
		net.WriteDouble(math.Clamp(min,50,300))
		net.WriteDouble(math.Clamp(max,350,2000))
	net.Broadcast()
end
	
function ClientSideSound:SetLooping(bool)
	net.Start("e2_soundsetlooping")
		net.WriteString(self.index)
		net.WriteUInt(bool and 1 or 0, 8)
	net.Broadcast()
end

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

local function soundDestroy(self, index)
	if self.data.sound_data.sounds[index] then
		self.data.sound_data.sounds[index]:Remove()
		self.data.sound_data.sounds[index] = nil
		self.data.sound_data.count = self.data.sound_data.count - 1
	end
end

local function getSound( self, index )
	if isnumber( index ) then index = math.floor( index ) end
	return self.data.sound_data.sounds[index]
end

local function soundCreate(self, entity, index, time, path, fade)
	if not isAllowed( self ) then return end
	
	if path:sub(1,4)=="http" then
		if wire_expression2_sound_allowurl:GetInt()==0 then return end
	else
		if path:match('["?]') then return end
		path = path:Trim()
		path = path:gsub( "\\", "/" )
	end
	
	if isnumber( index ) then index = math.floor( index ) end
	
	local data = self.data.sound_data
	local oldsound = getSound( self, index )
	if oldsound then
		if oldsound.path == path then
			oldsound:Play(time, entity)
			return
		end
		oldsound:Remove()
	else
		data.count = data.count + 1
	end
	
	local sound = ClientSideSound.CreateSound(path,time,index,entity,self.entity)
	
	data.sounds[index] = sound
	
	entity:CallOnRemove( "E2_stopsound", function()
		soundDestroy( self, index )
	end )
	
end

local function soundPurge( self )
	local sound_data = self.data.sound_data
	if sound_data.sounds then
		for k,v in pairs( sound_data.sounds ) do
			v:Remove()
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
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:Stop(0)
end

e2function void soundStop( index, fadetime )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:Stop(fadetime)
end

e2function void soundPause( index )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:Pause()
end

e2function void soundRemove( index )
		if isnumber( index ) then index = math.floor( index ) end
		
		soundDestroy( self, index )
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

e2function void soundFadeDistance( index, min, max )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangeFadeDistance( min, max )
end

--e2function void soundLoop( index, bool )
	--local sound = getSound( self, index )
	--if not sound then return end
	
	--sound:SetLooping( bool ~= 0 )
--end


e2function void soundStop( string index ) = e2function void soundStop( index )
e2function void soundStop( string index, fadetime ) = e2function void soundStop( index, fadetime )
e2function void soundPause( string index ) = e2function void soundPause( index )
e2function void soundRemove( string index ) = e2function void soundRemove( index )
e2function void soundVolume( string index, volume ) = e2function void soundVolume( index, volume )
e2function void soundVolume( string index, volume, fadetime ) = e2function void soundVolume( index, volume, fadetime )
e2function void soundPitch( string index, pitch ) = e2function void soundPitch( index, pitch )
e2function void soundPitch( string index, pitch, fadetime ) = e2function void soundPitch( index, pitch, fadetime )
e2function void soundFadeDistance( string index, min, max ) = e2function void soundFadeDistance( index, min, max ) 
--e2function void soundLoop( string index, bool ) = e2function void soundLoop( index, bool )

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
