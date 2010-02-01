/******************************************************************************\
  Built-in Sound support v1.18
\******************************************************************************/

E2Lib.RegisterExtension("sound", true)

//-----------------------//
//--Server Convar--//
//-----------------------//

local wire_expression2_maxsounds = CreateConVar( "wire_expression2_maxsounds", 8 )

//--------------------------//
//--Functions--//
//--------------------------//

local function soundCreate(self, entity, index, time, path, fade)
	if path:match('["?]') then return end
	local data = self.data['currentsound']
	if table.Count(data)>wire_expression2_maxsounds:GetFloat() then return end
	path = path:Trim()
	local sound = CreateSound(entity, path)
	if type(index)=="number" then index = index - index % 1 end
	if data[index] then data[index]:Stop() end
	data[index] = sound
	sound:Play()
	if time==0 && fade==0 then return end
	if time<0 then time = time * -1 end
	if fade<0 then fade = fade * -1 end
	timer.Create( "sounddeletetime"..index, time, 1, function()
		if !data[index] then return end
		if fade==0 then
			data[index]:Stop()
			data[index] = nil
			return
		end
		data[index]:FadeOut(fade)
		timer.Create( "soundfadetime"..index, fade, 1, function()
			if !data[index] then return end
			data[index]:Stop()
			data[index] = nil
		end)
	end)
end

local function soundStop(self, index, fade)
	local data = self.data['currentsound']
	if !data[index] then return end
	local sound = data[index]
	sound:FadeOut(fade)
	data[index] = nil
end

/*************************************************************/

e2function void soundPlay(rv1, rv2, string rv3)
	soundCreate(self,self.entity,rv1,rv2,rv3,0)
end

e2function void soundPlay(string rv1, rv2, string rv3)
	soundCreate(self,self.entity,rv1, rv2,rv3,0)
end

e2function void entity:soundPlay(rv2, rv3, string rv4)
	local entity = checkEntity(this)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,0)
end

e2function void entity:soundPlay(string rv2, rv3, string rv4)
	local entity = checkEntity(this)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,0)
end

e2function void soundPlay(rv1, rv2, string rv3, rv4)
	soundCreate(self,self.entity,rv1,rv2,rv3,rv4)
end

e2function void soundPlay(string rv1, rv2, string rv3, rv4)
	soundCreate(self,self.entity,rv1, rv2,rv3,rv4)
end

e2function void entity:soundPlay(rv2, rv3, string rv4, rv5)
	local entity = checkEntity(this)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,rv5)
end

e2function void entity:soundPlay(string rv2, rv3, string rv4, rv5)
	local entity = checkEntity(this)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,rv5)
end

e2function void soundStop(rv1)
	rv1 = rv1 - rv1 % 1
	soundStop(self, rv1, 0)
end

e2function void soundStop(rv1, rv2)
	rv1 = rv1 - rv1 % 1
	soundStop(self, rv1, rv2)
end

e2function void soundStop(string rv1)
	soundStop(self, rv1, 0)
end

e2function void soundStop(string rv1, rv2)
	soundStop(self, rv1, rv2)
end

e2function void soundVolume(rv1, rv2)
	rv1 = math.Clamp(rv1,0,1)
	rv1 = rv1 - rv1 % 1
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangeVolume(rv2)
	end
end

e2function void soundVolume(string rv1, rv2)
	rv1 = math.Clamp(rv1,0,1)
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangeVolume(rv2)
	end
end

e2function void soundPitch(rv1, rv2)
	rv1 = math.Clamp(rv1,0,255)
	rv1 = rv1 - rv1 % 1
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangePitch(rv2)
	end
end

e2function void soundPitch(string rv1, rv2)
	rv1 = math.Clamp(rv1,0,255)
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangePitch(rv2)
	end
end

e2function void soundPurge()
	local data = self.data['currentsound']
	local count = table.Count(data)
	for _,v in pairs(data) do
		v:Stop()
	end
	self.data['currentsound'] = {}
end

e2function number soundDuration(string sound)
	return SoundDuration(sound) or 0
end

/******************************************************************************/

registerCallback("construct", function(self)
	self.data['currentsound'] = {}
end)

registerCallback("destruct", function(self)
	for _,v in pairs(self.data['currentsound']) do
		v:Stop()
	end
end)
