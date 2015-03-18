/******************************************************************************\
  Built-in Sound support v1.18
\******************************************************************************/

E2Lib.RegisterExtension("sound", true)

local wire_expression2_maxsounds = CreateConVar( "wire_expression2_maxsounds", 16, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_max = CreateConVar( "wire_expression2_sound_burst_max", 8, {FCVAR_ARCHIVE} )
local wire_expression2_sound_burst_rate = CreateConVar( "wire_expression2_sound_burst_rate", 0.1, {FCVAR_ARCHIVE} )
local wire_expression2_sound_allowurl = CreateConVar( "wire_expression2_sound_allowurl", 1, {FCVAR_ARCHIVE} )

util.AddNetworkString("e2_soundrequest")
util.AddNetworkString("e2_soundremove")

---------------------------------------------------------------
-- Client-side sound class
---------------------------------------------------------------

local ClientSideSound = {}
ClientSideSound.mt = {__index = ClientSideSound}
ClientSideSound.SendRequests = {}
ClientSideSound.SendFuncs = {
	Create = function(self, time, ent, ply)
		net.WriteString(self.path)
		net.WriteDouble(time)
		net.WriteEntity(ent)
		net.WriteEntity(ply)
	end,
	Play = function(self, time, entity)
		net.WriteDouble(time)
		net.WriteEntity(entity)
	end,
	Pause = function(self)
	end,
	Stop = function(self, time)
		net.WriteDouble(time)
	end,
	ChangeVolume = function(self, vol, time)
		net.WriteDouble(vol)
		net.WriteDouble(time)
	end,
	ChangePitch = function(self, pitch, time)
		net.WriteDouble(pitch)
		net.WriteDouble(time)
	end,
	ChangeFadeDistance = function(self, min, max)
		net.WriteDouble(min)
		net.WriteDouble(max)
	end,
	SetLooping = function(self, val)
		net.WriteUInt(val, 8)
	end,
	SetTimePosition = function(self, val)
		net.WriteUInt(val, 32)
	end
}
	
function ClientSideSound.CreateSound( path, time, index, entity, e2 ) 
	local self = setmetatable({},ClientSideSound.mt)
	self.index = e2:EntIndex() .. "_" .. index
	self.path = path
	self:SendRequest("Create",time,entity,e2:GetPlayer())
	return self
end

function ClientSideSound:SendRequest(request, ...)
	local len = #ClientSideSound.SendRequests
	if len>=100 then return end
	ClientSideSound.SendRequests[len + 1] = {Func = request, Arg = {self, ...}}
end

function ClientSideSound.Broadcast()
	local numReq = #ClientSideSound.SendRequests
	if numReq > 0 then
		net.Start("e2_soundrequest")
			net.WriteUInt(numReq, 32)
			for I=1, numReq do
				local Request = ClientSideSound.SendRequests[I]
				net.WriteString(Request.Arg[1].index)
				net.WriteString(Request.Func)
				ClientSideSound.SendFuncs[Request.Func](unpack(Request.Arg))
			end
		net.Broadcast()
		ClientSideSound.SendRequests = {}
	end
end

function ClientSideSound:Play(time, entity)
	self:SendRequest("Play",time,entity)
end

function ClientSideSound:Pause()
	self:SendRequest("Pause")
end
	
function ClientSideSound:Stop(time)
	self:SendRequest("Stop",time)
end
	
function ClientSideSound:Remove()
	net.Start("e2_soundremove")
		net.WriteString(self.index)
	net.Broadcast()
end
	
function ClientSideSound:ChangeVolume(vol, time)
	self:SendRequest("ChangeVolume", vol, time)
end
	
function ClientSideSound:ChangePitch(pitch, time)
	self:SendRequest("ChangePitch",pitch,time)
end
	
function ClientSideSound:ChangeFadeDistance(min, max)
	self:SendRequest("ChangeFadeDistance",min,max)
end
	
function ClientSideSound:SetLooping(val)
	self:SendRequest("SetLooping",val)
end

function ClientSideSound:SetTimePosition(val)
	self:SendRequest("SetTimePosition",val)
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
			oldsound:SetTimePosition(0)
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
	
	sound:ChangePitch( math.Clamp( pitch, 0, 400 ) / 100, 0 )
end

e2function void soundPitch( index, pitch, fadetime )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangePitch( math.Clamp( pitch, 0, 400 ) / 100, math.abs( fadetime ) )
end

e2function void soundFadeDistance( index, min, max )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:ChangeFadeDistance( math.Clamp(min,50,1000), math.Clamp(max,10000,200000) )
end

e2function void soundLoop( index, val )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:SetLooping( val )
end

e2function void soundTimePosition( index, val )
	local sound = getSound( self, index )
	if not sound then return end
	
	sound:SetTimePosition( val )
end


e2function void soundStop( string index ) = e2function void soundStop( index )
e2function void soundStop( string index, fadetime ) = e2function void soundStop( index, fadetime )
e2function void soundPause( string index ) = e2function void soundPause( index )
e2function void soundRemove( string index ) = e2function void soundRemove( index )
e2function void soundVolume( string index, volume ) = e2function void soundVolume( index, volume )
e2function void soundVolume( string index, volume, fadetime ) = e2function void soundVolume( index, volume, fadetime )
e2function void soundPitch( string index, pitch ) = e2function void soundPitch( index, pitch )
e2function void soundPitch( string index, pitch, fadetime ) = e2function void soundPitch( index, pitch, fadetime )
e2function void soundFadeDistance( string index, min, max ) = e2function void soundFadeDistance( index, min, max ) 
e2function void soundLoop( string index, bool ) = e2function void soundLoop( index, bool )
e2function void soundTimePosition( string index, val ) = e2function void soundTimePosition( index, val )

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
	ClientSideSound.Broadcast()
end)

registerCallback("postexecute",function(self)
	ClientSideSound.Broadcast()
end)
