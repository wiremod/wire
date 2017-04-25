/******************************************************************************\
  Selfaware support
\******************************************************************************/

__e2setcost(1) -- temporary

e2function entity entity()
	return self.entity
end

e2function entity owner()
	return self.player
end

__e2setcost(nil) -- temporary

e2function void selfDestruct()
	self.entity:Remove()
end

e2function void selfDestructAll()
	for k,v in pairs(constraint.GetAllConstrainedEntities(self.entity)) do
		if(getOwner(self,v)==self.player) then
			v:Remove()
		end
	end
	//constraint.RemoveAll(self.entity)
	self.entity:Remove()
end

/******************************************************************************/
-- i/o functions

__e2setcost(10)

-- Returns an array of all entities wired to the output
e2function array ioOutputEntities( string output )
	local ret = {}
	if (self.entity.Outputs[output]) then
		local tbl = self.entity.Outputs[output].Connected
		for i=1,#tbl do if (IsValid(tbl[i].Entity)) then ret[#ret+1] = tbl[i].Entity end end
		self.prf = self.prf + #ret
	end
	return ret
end

-- Returns the entity the input is wired to
e2function entity ioInputEntity( string input )
	if (self.entity.Inputs[input] and self.entity.Inputs[input].Src and IsValid(self.entity.Inputs[input].Src)) then return self.entity.Inputs[input].Src end
end

local function setOutput( self, args, Type )
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if (self.entity.Outputs[rv1] and self.entity.Outputs[rv1].Type == Type) then
		self.GlobalScope[rv1] = rv2
		self.GlobalScope.vclk[rv1] = true
	end
end

local function getInput( self, args, default, Type )
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if istable(default) then default = table.Copy(default) end
	if (self.entity.Inputs[rv1] and self.entity.Inputs[rv1].Type == Type) then
		return self.GlobalScope[rv1] or default
	end
	return default
end

local excluded_types = {
	xgt = true,
}

local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

__e2setcost(5)

registerCallback("postinit",function()
	for k,v in pairs( wire_expression_types ) do
		local short = v[1]
		if (!excluded_types[short]) then
			registerFunction("ioSetOutput","s"..short,""..short,function(self,args) return setOutput(self,args,k) end)
			registerFunction("ioGetInput"..upperfirst(k == "NORMAL" and "NUMBER" or k),"s",short,function(self,args) return getInput(self,args,v[2],k) end)
		end
	end
end)

/******************************************************************************/
-- Name functions

local CurTime = CurTime
local math_min = math.min
local string_len = string.len

local antiSpamLookup = {}
local function NameSpamCheck(ent, str) -- Returns true if it is being spammed; otherwise false
	local time = CurTime()
	local antispam = antiSpamLookup[ent] or { time + 1, 0 } -- Using index-table for faster lookup
	antiSpamLookup[ent] = antispam -- Avoid the frequency of table indexing
	if time - antispam[1] > 0 then
		antispam[1] = time + 1
		antispam[2] = 0
	end
	antispam[2] = antispam[2] + math_min(string_len(str), 199) -- Only add 199 at max per call since that's the limit of [G|S]etNWString functions
	return 12000 < antispam[2] -- Using the "standard" length limit (12k chars) for anti-spam
end

local function SetE2Name(ent, name)
	if ent.name == name or NameSpamCheck(ent, name) then return 0 end
	if name == "generic" or name == "" then -- NOTE: This could be simplified if we exclude the "generic" check
		name = "generic"
		ent.WireDebugName = "Expression 2"
	else
		ent.WireDebugName = "E2 - " .. name
	end
	ent.name = name
	ent:SetNWString("name", name)
	ent:SetOverlayText(name) -- NOTE: Maybe use UpdateOverlay() function instead
	return 1
end

__e2setcost(20)

local IsValid = IsValid

-- Set the name of the E2 itself. Returns 1 if the E2 name was changed; otherwise, it will return 0 to indicate a failure
e2function number setName(string name)
	local ent = self.entity
	if IsValid(ent) then
		return SetE2Name(ent, name)
	end
	return 0
end

-- Set the name of another E2. Returns 1 if the E2 name was changed; otherwise, it will return 0 to indicate a failure
e2function number entity:setName(string name)
	if IsValid(this) and this:GetClass() == "gmod_wire_expression2" and E2Lib.getOwner(this) == self.player then
		return SetE2Name(this, name)
	end
	return 0
end

-- Set the component name of Wire-compatible entity. Returns 1 if the component name was changed; otherwise, it will return 0 to indicate a failure
e2function number entity:setComponentName(string componentName)
	if IsValid(this) and not NameSpamCheck(this, componentName) and E2Lib.getOwner(this) == self.player then
		return WireLib.SetComponentName(this, componentName) and 1 or 0
	end
	return 0
end

__e2setcost(2)

-- Returns the name of another E2
e2function string entity:getName()
	if IsValid(this) and this.GetGateName then
		return this:GetGateName() or ""
	end
	return ""
end

-- Returns the component name of Wire-compatible entity
e2function string entity:getComponentName()
	return IsValid(this) and this:GetNWString("WireName", this.PrintName) or ""
end


/******************************************************************************/

registerCallback("construct", function(self)
	self.data.changed = {}
end)

__e2setcost(1)

-- This is the prototype for everything that can be compared using the == operator
e2function number changed(value)
	local chg = self.data.changed

	if value == chg[args] then return 0 end

	chg[args] = value
	return 1
end

-- vectors can be of gmod type Vector, so we need to treat them separately
e2function number changed(vector value)
	local chg = self.data.changed

	local this_chg = chg[args]
	if not this_chg then
		chg[args] = value
		return 1
	end
	if this_chg
	and value[1] == this_chg[1]
	and value[2] == this_chg[2]
	and value[3] == this_chg[3]
	then return 0 end

	chg[args] = value
	return 1
end

-- This is the prototype for all table types.
e2function number changed(angle value)
	local chg = self.data.changed

	local this_chg = chg[args]
	if not this_chg then
		chg[args] = value
		return 1
	end
	for i,v in pairs(value) do
		if v ~= this_chg[i] then
			chg[args] = value
			return 1
		end
	end
	return 0
end

local excluded_types = {
	n = true,
	v = true,
	a = true,

	r = true,
	t = true,
}
local comparable_types = {
	s = true,
	e = true,
	xwl = true,
	b = true,
}

registerCallback("postinit", function()
	-- generate this function for all types
	for typeid,_ in pairs(wire_expression_types2) do
		if not excluded_types[typeid] then
			if comparable_types[typeid] then
				registerFunction("changed", typeid, "n", e2_changed_n)
			else
				registerFunction("changed", typeid, "n", e2_changed_a)
			end
		end
	end
end)

/******************************************************************************/

__e2setcost( 5 )

local getHash = E2Lib.getHash
e2function number hash()
	return getHash( self, self.entity.original )
end

e2function number hashNoComments()
	return getHash( self, self.entity.buffer )
end

e2function number hash( string str )
	return getHash( self, str )
end
