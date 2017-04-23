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

local IsValid = IsValid

local GetComponentNameHelper = function(ent) -- Keeping this for easier maintain; It is called from 2 _different_ functions below.
	return IsValid(ent) and ent:GetNWString("WireName", ent.PrintName) or ""
end

local SetNameHelper = function(ent, name) -- Keeping this for easier maintain; It is called from 2 _same_ functions below.
	if ent.name == name then return end -- Prevent it from running again if the name is unchanged.
	if name == "generic" or name == "" then
		name = "generic"
		ent.WireDebugName = "Expression 2"
	else
		ent.WireDebugName = "E2 - " .. name
	end
	ent.name = name
	ent:SetNWString("name", name)
	ent:SetOverlayText(name)
end

local string = string
local string_find = string.find

local SetComponentNameHelper = function(ent, componentName) -- Keeping this for easier maintain; It is called from 2 _different_ functions below.
	if ent.wireName == componentName or string_find(componentName, "[\n\r\"]") ~= nil then return end
	ent.wireName = componentName
	ent:SetNWString("WireName", componentName)
	duplicator.StoreEntityModifier(ent, "WireName", { name = componentName })
end

__e2setcost(20)

-- Set the name of the E2 itself.
-- NOTE: Do not remove me, or the existing E2s will break.
e2function void setName(string name)
	local e = self.entity
	if IsValid(e) then
		SetNameHelper(e, name)
	end
end

-- Depending on the type of entity provided, if it is E2 then it will set the name of another E2; otherwise, it will set the component name of another Wire entity instead.
e2function void entity:setName(string name)
	if IsValid(this) and E2Lib.getOwner(this) == self.player then
		(this:GetClass() == "gmod_wire_expression2" and SetNameHelper or SetComponentNameHelper)(this, name)
	end
end

-- Set the component name of another Wire entity. This is _NOT_ the same as setName function if called on E2 entity! This functions exists to allow E2 to set its own component name.
e2function void entity:setComponentName(string componentName)
	if IsValid(this) and E2Lib.getOwner(this) == self.player then
		SetComponentNameHelper(this, componentName)
	end
end

__e2setcost(2)

-- Return value depends on the type of entity provided, if it is E2 then it will return the name of another E2; otherwise, it will return the component name of another Wire entity instead.
-- NOTE: Do not remove me, or the existing E2s will break.
e2function string entity:getName()
	if not IsValid(this) then return "" end
	-- If <this> entity has defined GetGateName function, then call that interface function instead
	if this.GetGateName then
		 -- In case GetGateName returns with failure, then try to return the component name instead; fall-through the if-statement
		local gateName = this:GetGateName()
		if gateName then return gateName end
	end
	-- Else, return the component name of another Wire entity
	return GetComponentNameHelper(this) or ""
end

-- Returns the component name of another Wire entity. This is _NOT_ the same as e:getName() function if called on E2 entity! This functions exists to allow E2 to get its own component name.
e2function string entity:getComponentName()
	return GetComponentNameHelper(this)
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
