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

registerFunction("soundPlay", "nns", "", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
	soundCreate(self,self.entity,rv1,rv2,rv3,0)
end)

registerFunction("soundPlay", "sns", "", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
	soundCreate(self,self.entity,rv1, rv2,rv3,0)
end)

registerFunction("soundPlay", "e:nns", "", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,0)
end)

registerFunction("soundPlay", "e:sns", "", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,0)
end)

registerFunction("soundPlay", "nnsn", "", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	soundCreate(self,self.entity,rv1,rv2,rv3,rv4)
end)

registerFunction("soundPlay", "snsn", "", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	soundCreate(self,self.entity,rv1, rv2,rv3,rv4)
end)

registerFunction("soundPlay", "e:nnsn", "", function(self, args)
    local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
    local rv1, rv2, rv3, rv4, rv5 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4), op5[1](self,op5)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,rv5)
end)

registerFunction("soundPlay", "e:snsn", "", function(self, args)
    local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
    local rv1, rv2, rv3, rv4, rv5 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4), op5[1](self,op5)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if !isOwner(self, entity) then return end
	soundCreate(self,entity,rv2,rv3,rv4,rv5)
end)

registerFunction("soundStop", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	soundStop(self, rv1, 0)
end)

registerFunction("soundStop", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	soundStop(self, rv1, rv2)
end)

registerFunction("soundStop", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	soundStop(self, rv1, 0)
end)

registerFunction("soundStop", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	soundStop(self, rv1, rv2)
end)

registerFunction("soundVolume", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), math.Clamp(op2[1](self, op2),0,1)
	rv1 = rv1 - rv1 % 1
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangeVolume(rv2)
	end
end)

registerFunction("soundVolume", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), math.Clamp(op2[1](self, op2),0,1)
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangeVolume(rv2)
	end
end)

registerFunction("soundPitch", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), math.Clamp(op2[1](self, op2),0,255)
	rv1 = rv1 - rv1 % 1
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangePitch(rv2)
	end
end)

registerFunction("soundPitch", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), math.Clamp(op2[1](self, op2),0,255)
	local data = self.data['currentsound']
	if data[rv1] then
	local sound = data[rv1]
	sound:ChangePitch(rv2)
	end
end)

registerFunction("soundPurge", "", "", function(self, args)
	local data = self.data['currentsound']
	local count = table.Count(data)
	for _,v in pairs(data) do
		v:Stop()
	end
	self.data['currentsound'] = {}
end)

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
