AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "TextReceiver"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

local TextReceivers = {}
local securetext = nil
local returntext = false

local function Add_TextReceiver( r )
	table.insert( TextReceivers, r )
end

hook.Add("PlayerSay","TextReceiverSay", function(pl, text, toall)
	securetext = nil
	for i,ent in ipairs( TextReceivers ) do
		if not IsEntity(ent.Entity) then
			table.remove(TextReceivers, i)
		else
			local temptext = ent:TextReceived(pl,text)
			if (securetext == nil && temptext != nil) then
				securetext = temptext
			end
		end
	end
	if (securetext != nil) then return securetext end
end)

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	Add_TextReceiver(self.Entity)

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Error" })
end

function ENT:Setup( liness, globall,OutputTextt,Holdd,Triggerr,SELFF,sensitivityy,togglee,utriggerr,parsetextt,secure,playerout)
	self.global = globall
	self.Hold = Holdd or 0.1
	self.Trig = Triggerr or 1
	self.Toggle = togglee
	self.UTrig = utriggerr or 0
	self.Bytes = {}
	self.values = {}
	self.lines = {}
	self.CLines = {}
	self.CLines = table.Copy(liness) //Makes getting the lines easier
	self.Iself = SELFF
	self.char1 = string.Left(parsetextt,1) or '"'
	self.char2 = string.Right(parsetextt,1) or '"'
	self.Sensitivity = sensitivityy or 4
	self.OutputText = OutputTextt or ""
	self.secure = secure
	self.playerout = playerout

	local onames = {}
	local i = 1
	for k,o in pairs(liness) do
		self.lines[i] = {}
		self.lines[i].args = {}
		self.lines[i].line, self.lines[i].args,self.lines[i].toggle,self.lines[i].global,self.lines[i].on,self.lines[i].off,self.lines[i].Allow,self.lines[i].Deny,self.lines[i].TAllow,self.lines[i].TDeny, self.lines[i].Radius = self:SParseTextAndArgs(o,"<",">",0)
		self.lines[i].argsC = nil
		table.insert(onames, self.lines[i].line)
		for k2,o2 in pairs(self.lines[i].args) do
			o2.V = 0
			table.insert(onames, o2.A)
			self.lines[i].argsC = true
		end
		self.lines[i].value = self.lines[i].off or self.UTrig
		self.lines[i].reset = 0
		i = i + 1
	end
	if (playerout == true) then
		table.insert(onames,"X")
		table.insert(onames,"Y")
		table.insert(onames,"Z")
		table.insert(onames,"EntId")
	end
	Wire_AdjustOutputs(self.Entity, onames)

	self.changed = false

	self.Bytes[1] = self.UTrig
	self.Bytes[2] = self.Trig
	self.Bytes[3] = self.Hold
	self.Bytes[4] = string.byte(self.char1) or 0
	self.Bytes[5] = string.byte(self.char2) or 0
	self.Bytes[6] = self.global
	self.Bytes[7] = self.Toggle
	self.Bytes[8] = self.OutputText
	self.Bytes[9] = self.Iself
	self.Bytes[10] = self.secure
	self.Bytes[11] = self.playerout
	self.Bytes[12] = self.Sensitivity
	self.Bytes[13] = 0
	self.Bytes[14] = table.Count(self.CLines)
	local q = 15
	for k,v in pairs(self.CLines) do
		self.Bytes[tonumber(q)] = #v
		for i = 1,#v do //String to table :P
			self.Bytes[tonumber(q + i)] = tonumber(string.byte(string.sub(v,i,i)) or 0) or 0
		end
		q = q + #v
	end

	self:TriggerOutput()
end

function ENT:ParsePar(text)
	local y = string.find(text,"(",0,true)
	if (y == nil) then return nil end
	local z = string.find(text,")",y + 1,true)
	if (z == nil) then return nil end
	return tonumber(string.sub(text,y + 1, z - 1))
end

function ENT:ParseFPar(text)
		local allow,deny = {},{}
		local p = string.find(text,"(",0,true)
		if (p == nil) then return {} end
		local n = string.find(text,")",p + 1,true)
		if (n == nil) then return {} end
		local args = string.Explode(",",string.sub(text,p + 1, n - 1))
		for k,o in pairs(args) do
			if (o != nil) then
				if (string.sub(o,1,1)=="~") then
					table.insert(deny,string.sub(o,2))
				else
					table.insert(allow,o)
				end
			end
		end
		return allow,deny
end

function ENT:SParseTextAndArgs(line,char1,char2,remov)
	if !(string.find(line,char1, 1, true) && string.find(line,char2, 1, true)) then return string.Trim(line),{nil} end
	local ret = {}
	local ret2 = string.Trim(string.sub(line,1,string.find(line,char1, 1, true) - 1))
	local p = string.find(line,char1, 1, true)
	local n = 1
	local i = 1
	local toggle = false
	local global = false
	local on = nil
	local off = nil
	local allow = {}
	local deny = {}
	local tallow = {}
	local tdeny = {}
	local curarg = nil
	local radius = nil
	while(p) do
		n = string.find(line,char2,p + 1, true)
		curarg = string.sub(line,p + 1,n - 1)
		if (curarg == "t()") then toggle = true
		elseif (curarg == "g()") then global = true
		elseif (curarg == "") then
		elseif (string.sub(curarg,1,3) == "on(") then
			on = self:ParsePar(curarg)
		elseif (string.sub(curarg,1,4) == "off(") then
			off = self:ParsePar(curarg)
		elseif (string.sub(curarg,1,2) == "f(") then
			allow,deny = self:ParseFPar(curarg)
		elseif (string.sub(curarg,1,3) == "tf(") then
			tallow,tdeny = self:ParseFPar(curarg)
		elseif (string.sub(curarg,1,2) == "r(") then
			radius = self:ParsePar(curarg)
		elseif (string.sub(curarg,1,1) == "~") then
			ret[i] = {}
			ret[i].A = char1 .. (string.sub(line,p + 2 + remov,n - remov) or "")
			ret[i].V = 0
			ret[i].R = true
			i = i + 1
		else
			ret[i] = {}
			ret[i].A = string.sub(line,p + remov,n - remov)
			ret[i].V = 0
			ret[i].R = false
			i = i + 1
		end
		p = string.find(line,char1,n + 1, true)
	end
	return ret2,ret,toggle,global,on,off,allow,deny,tallow,tdeny,radius
end


//yay for while loops and Trim :D
function ENT:ParseTextAndArgs(line,char1,char2,remov)
	if (line == nil) then return "",{} end
	if !(string.find(line,char1, 1, true) && string.find(line,char2, 1, true)) then return string.Trim(line),{nil} end
	local ret = {}
	local ret2 = string.Trim(string.sub(line,1,string.find(line,char1, 1, true) - 1))
	local ret3 = string.sub(line,1,string.find(line,char1, 1, true) - 1)
	local p = string.find(line,char1, 1, true)
	local n = 1
	while(p) do
		n = string.find(line,char2,p + 1, true)
		if (string.sub(string.sub(line,p + 1,n - 1),1,1) == "#") then
			table.insert(ret,tonumber(string.byte(string.sub(line,p + 1 + remov,n - remov)) or 0))
			ret3 = ret3 .. '"*"'
		else
			table.insert(ret,tonumber(string.sub(line,p + remov,n - remov)) or tonumber(string.byte(string.sub(line,p + remov,n - remov)) or 0))
			ret3 = ret3 .. '"' .. (string.rep("*",string.len(string.sub(line,p + remov,n - remov))) or "") .. '"'
		end
		p = string.find(line,char1, n + 1, true)
		if (p!=nil) then
			ret3 = ret3 .. (string.sub(line,n+1,p-1) or "")
		end
	end
	return ret2,ret,ret3
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Toggle == false) then
		for k,o in pairs(self.lines) do
			if !(o.toggle) then
				if (o.value != (o.off or self.UTrig) && CurTime() >= o.reset) then
					o.value = o.off or self.UTrig
					if (o.argsC) then
						for k2,o2 in pairs(o.args) do
							if (o2.R == true) then
								o2.V = 0
							end
						end
					end
					self:TriggerOutput()
				end
			end
		end
	end

	self.Entity:NextThink(CurTime()+0.04)
	return true
end

function ENT:SensitivityCheck(text,line)
	if !(text || line) then return false end
	if (self.Sensitivity == 1) then
		if (text == line) then return true end
	elseif (self.Sensitivity == 2) then
		if (string.lower(text) == string.lower(line)) then return true end
	elseif (self.Sensitivity == 3) then
		if (string.find(text,line, 1, true)) then return true end
	elseif (self.Sensitivity == 4) then
		if (string.find(string.lower(text), string.lower(line), 1, true)) then return true end
	end
	return false
end

function ENT:CheckforChar(text,char1,char2)
	if (string.find(text,char1, 1, true) && string.find(text,char2,string.find(text,char1, 1, true)+1, true)) then return true end
	return false
end

function ENT:InRadius(plpos,selfpos,radius)
	if (radius == nil) then return true end
	if (selfpos:Distance(plpos) < radius) then
		return true
	else
		return false
	end
end

//All text is sent here now :D
function ENT:TextReceived(pl,text)
	local i = 1
	TextReceiversecuretext = nil
	for k,o in pairs(self.lines) do
		if (text != nil && o.line != nil) then
			TextReceivertext = text
			TextReceiverarg = nil
			if (self:InRadius(pl:GetPos(),self.Entity:GetPos(),o.Radius) == true) then
				if (o.argsC == true) then
					if (self:CheckforChar(TextReceivertext or "",self.char1,self.char2) == true) then
						TextReceiverarg = {}
						local temptext = nil
						TextReceivertext,TextReceiverarg,temptext = self:ParseTextAndArgs(text,self.char1,self.char2,1)
						if (TextReceiversecuretext==nil && self.secure == true) then
							TextReceiversecuretext = temptext
						end
					end
				end
				if (self:SensitivityCheck((TextReceivertext or ""),(o.line or ""))) then
					local allow = self:ParseNameandTeam(pl:Nick(),team.GetName(pl:Team()),o,self.global || o.global)
					if (allow == true || (self.Iself == true && self.pl == pl)) then
						if (self.playerout == true) then
							self.Caller = pl
						end
						if (TextReceiverarg != nil) then
							if (table.Count(TextReceiverarg) > 0) then
								for k = 1,table.Count(o.args) do
									o.args[k].V = (TextReceiverarg[k] or 0)
								end
								TextReceiverarg = {}
							end
						end
						if (self.Toggle || o.toggle) then
							if (o.value == o.on) then
								o.value = o.off or self.UTrig
							else
								o.value = o.on or self.Trig
							end
							o.reset = -1
						else
							o.value = o.on or self.Trig
							o.reset = CurTime() + self.Hold
						end
						self:TriggerOutput()
					end
				end
			end
		end
		i = i + 1
	end
	if (TextReceiversecuretext==nil) then
		return nil
	else
		return TextReceiversecuretext
	end
end

function ENT:ParseNameandTeam(name,TEAM,line,global)
	if (line.Allow != nil) then
		for k,o in pairs(line.Allow) do
			if (o==name) then return true end
		end
	end
	if (line.Deny != nil) then
		for k,o in pairs(line.Deny) do
			if(o==name) then return false end
		end
	end
	if (line.TAllow != nil) then
		for k,o in pairs(line.TAllow) do
			if (o==TEAM) then return true end
		end
	end
	if (line.TDeny != nil) then
		for k,o in pairs(line.TDeny) do
			if(o==TEAM) then return false end
		end
	end
	return global
end

function ENT:FOutText(text)
	return math.floor(text*10)/10
end

function ENT:ReadCell(Addr)
	return self.Bytes[Addr+1] or 0 //Makes for faster reading :D
end

function ENT:ReloadLines()
	if (self.changed == false) then return end
	self.changed = false
	local onames = {}
	local lines = {}
	local i = 15
	local line = ""
	while (self.Bytes[i]!=nil) do
		line = ""
		for q = 1,self.Bytes[i] do
			i = i + 1
			line = line .. (string.char(self.Bytes[tonumber(i)] or 0) or "")
		end
		i = i + 1
		if (line != nil && line != "") then table.insert(lines,line) end
	end
	i = 1
	for k,o in pairs(lines) do
		self.lines[i] = {}
		self.lines[i].args = {}
		self.lines[i].line, self.lines[i].args,self.lines[i].toggle,self.lines[i].global,self.lines[i].on,self.lines[i].off,self.lines[i].Allow,self.lines[i].Deny,self.lines[i].TAllow,self.lines[i].TDeny, self.lines[i].Radius = self:SParseTextAndArgs(o,"<",">",0)
		self.lines[i].argsC = nil
		table.insert(onames, self.lines[i].line)
		for k2,o2 in pairs(self.lines[i].args) do
			o2.V = 0
			table.insert(onames, o2.A)
			self.lines[i].argsC = true
		end
		self.lines[i].value = self.lines[i].off or self.UTrig
		self.lines[i].reset = 0
		i = i + 1
	end
	if (self.playerout == true) then
		table.insert(onames,"X")
		table.insert(onames,"Y")
		table.insert(onames,"Z")
		table.insert(onames,"EntId")
	end
	Wire_AdjustOutputs(self.Entity, onames)
end

function ENT:WriteCell(Addr,value)
	Addr = tonumber(Addr)
	if (Addr == 0) then	self.Bytes[Addr+1] = value or 0 self.UTrig = value or 0 end
	if (Addr == 1) then	self.Bytes[Addr+1] = value or 0 self.Trig = value or 0 end
	if (Addr == 2) then	self.Bytes[Addr+1] = value or 0 self.Hold = value or 0 end
	if (Addr == 3) then	self.Bytes[Addr+1] = string.char(value or 0) self.char1 = string.char(value or 0) end
	if (Addr == 4) then	self.Bytes[Addr+1] = string.char(value or 0) self.char2 = string.char(value or 0) end
	if (Addr == 5) then	self.Bytes[Addr+1] = value or 0 self.global = value or 0 end
	if (Addr == 6) then	self.Bytes[Addr+1] = value or 0 self.Toggle = value or 0 end
	if (Addr == 7) then	self.Bytes[Addr+1] = value or 0 self.OutputText = value or 0 end
	if (Addr == 8) then	self.Bytes[Addr+1] = value or 0 self.Iself = value or 0 end
	if (Addr == 9) then self.Bytes[Addr+1] = value or 0 self.secure = value or 0 end
	if (Addr == 10) then self.Bytes[Addr+1] = value or 0 self.playerout = value or 0 end
	if (Addr == 11) then self.Bytes[Addr+1] = value or 0 self.Sensitivity = value or 0 end
	if (Addr == 12 && Value != 0) then self.Bytes[Addr+1] = value or 0 self:ReloadLines() end
	if (Addr >= 13) then
		self.Bytes[Addr+1] = value
		self.changed = true
	end
	self:TriggerOutput()
	return true
end

function ENT:TriggerOutput()
	self.OutText = "TextReceiver:"
	local pos = nil
	if (self.playerout == true && self.Caller != nil) then
		pos = self.Caller:GetPos()
		Wire_TriggerOutput(self.Entity,"X",pos.X)
		Wire_TriggerOutput(self.Entity,"Y",pos.Y)
		Wire_TriggerOutput(self.Entity,"Z",pos.Z)
		Wire_TriggerOutput(self.Entity,"EntId",self.Caller:EntIndex())
	end
	local i = 1
	for k,o in pairs(self.lines) do
		if (self.OutputText == true) then self.OutText = self.OutText .. "\n" .. (o.line or "") .. ":" .. (o.value or 0) end
		for q = 1, table.Count(o.args) do
			Wire_TriggerOutput(self.Entity,o.args[q].A,(o.args[q].V or 0))
			if (self.OutputText == true) then self.OutText =self.OutText .. "  " .. (o.args[q].A or "") .. ":" .. (o.args[q].V or 0) end
		end
		Wire_TriggerOutput(self.Entity,o.line,o.value)
		i = i + 1
	end
	if (self.playerout == true) then //We want it to trigger first BUT display last.
		if (pos != nil) then
			self.OutText = self.OutText .. "\nPos: " .. self:FOutText(pos.X or 0) .. ", " .. self:FOutText(pos.Y or 0) .. ", " .. self:FOutText(pos.Z or 0) .. "\nEntId: "
		else
			self.OutText = self.OutText .. "\nPos: 0, 0, 0\nEntId: "
		end
		if (self.Caller != nil) then
			self.OutText = self.OutText .. self.Caller:EntIndex()
		else
			self.OutText = self.OutText .. "0"
		end
	end
	/*if (self.NoFilter == false) then
		self.OutText = "\nBuddyList: " .. string.Implode(" ",self.Allow) .. "\nIgnoreList: " .. string.Implode(" ",self.Deny)
	end*/
	self:SetOverlayText(self.OutText)
end
