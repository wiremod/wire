--[[******************************************************************************]]
--	Selfaware support
--[[******************************************************************************]]

local isOwner = E2Lib.isOwner

do
	local v1, v2 = WireLib.GetVersion()
	E2Lib.registerConstant("WIREVERSION", v1)
	E2Lib.registerConstant("WIREVERSION_STR", v2)
end

__e2setcost(1) -- temporary

[nodiscard]
e2function entity entity()
	return self.entity
end

[nodiscard]
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
	--constraint.RemoveAll(self.entity)
	self.entity:Remove()
end

--[[******************************************************************************]]--
-- i/o functions

__e2setcost(10)

-- Returns an array of all entities wired to the output
[nodiscard]
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
[nodiscard]
e2function entity ioInputEntity( string input )
	if (self.entity.Inputs[input] and self.entity.Inputs[input].Src and IsValid(self.entity.Inputs[input].Src)) then return self.entity.Inputs[input].Src end
end

local fixDefault = E2Lib.fixDefault

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
		if not excluded_types[short] then
			registerFunction("ioSetOutput","s"..short,""..short,function(self, args)
				local rv1, rv2 = args[1], args[2]
				if self.entity.Outputs[rv1] and self.entity.Outputs[rv1].Type == k then
					self.GlobalScope[rv1] = rv2
					self.GlobalScope.vclk[rv1] = true
				end
			end, 3, nil, { legacy = false })

			registerFunction("ioGetInput"..upperfirst(k == "NORMAL" and "NUMBER" or k),"s",short,function(self, args)
				local rv1, default = args[1], fixDefault(v[2])
				if self.entity.Inputs[rv1] and self.entity.Inputs[rv1].Type == k then
					return self.GlobalScope[rv1] or default
				end
				return default
			end, 3, nil, { legacy = false })
		end
	end
end)

--[[******************************************************************************]]--
-- Name functions

local function doSetName(self, this, name)
	local data_SetName = self.data.SetName
	if not data_SetName then
		data_SetName = { _n = 0, _chars = 0 }
		self.data.SetName = data_SetName
	end
	local totalRuns, totalChars = data_SetName._n, data_SetName._chars
	if totalRuns >= 5 then return self:throw("You are calling setName too many times!") end
	if data_SetName[this] then return self:throw("You are using setName too fast!") end
	data_SetName[this] = true

	totalChars = totalChars + math.min(#name, 200)
	if totalChars >= 512 then return self:throw("You are sending too much data with setName!") end
	data_SetName._chars = totalChars

	timer.Create("wire_doSetName_Cleanup" .. self.entity:EntIndex(), 1 - engine.TickInterval(), 1, function()
		if self and self.data then self.data.SetName = nil end
	end)

	if this:GetClass() == "gmod_wire_expression2" then
		if this.name == name then return end
		if name == "generic" or name == "" then
			name = "generic"
			this.WireDebugName = "Expression 2"
		else
			this.WireDebugName = "E2 - " .. name
		end
		this.name = name

		this:SetNWString("name", name)
		this:SetOverlayText(name)
	else
		if #name > 200 then name = string.sub(name, 1, 200) end
		if string.find(name, "[\n\r\"]") then return self:throw("setName name contains illegal characters!") end
		if this:GetNWString("WireName") == name then return end
		this:SetNWString("WireName", name)
		duplicator.StoreEntityModifier(this, "WireName", { name = name })

	end

	data_SetName._n = totalRuns + 1

	self.prf = self.prf + (totalRuns - 1) ^ 2 * totalChars -- Disincentivize repeated use
end

__e2setcost(100)

-- Set the name of the E2 itself
e2function void setName( string name )
	doSetName(self,self.entity,name)
end

-- Set the name of an entity (component name if not E2)
e2function void entity:setName( string name )
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	doSetName(self,this,name)
end

__e2setcost(25)

e2function void setOverlayText(string text)
	local this = self.entity
	if this.name == text then return end
	if text == "" then
		text = "generic"
	end
	this.name = text
	this:SetOverlayText(text)
end


__e2setcost(5)

-- Get the name of another E2 or compatible entity or component name of wiremod components
[nodiscard]
e2function string entity:getName()
	if not IsValid(this) then return self:throw("Invalid entity!", "") end
	if this.GetGateName then
		return this:GetGateName() or ""
	end
	return this:GetNWString("WireName", this.PrintName) or ""
end

local function canSetName(self, this, str)
	local data_SetName = self.data.SetName
	return not (data_SetName and (data_SetName[this] or data_SetName._n >= 5 or data_SetName._chars + #str >= 512))
end

[nodiscard]
e2function number canSetName()
	return canSetName(self, self.entity) and 1 or 0
end

[nodiscard]
e2function number entity:canSetName()
	return IsValid(this) and isOwner(self, this) and canSetName(self, this, "") and 1 or 0
end

[nodiscard]
e2function number canSetName(string name)
	return IsValid(this) and isOwner(self, this) and canSetName(self, self.entity, name) and 1 or 0
end

[nodiscard]
e2function number entity:canSetName(string name)
	return IsValid(this) and isOwner(self, this) and canSetName(self, this, name) and 1 or 0
end

--[[******************************************************************************]]--
-- Extensions

local getExtensionStatus = E2Lib.GetExtensionStatus
local e2Extensions
local e2ExtensionsTable
-- See postinit for these getting initialized

__e2setcost(30)

[nodiscard]
e2function array getExtensions()
	local ret = {}
	for k, v in ipairs(e2Extensions) do -- Optimized copy
		ret[k] = v
	end
	return ret
end

__e2setcost(60)

[nodiscard]
e2function table getExtensionStatus()
	local ret = E2Lib.newE2Table()
	local s, stypes = ret.s, ret.stypes
	ret.size = e2ExtensionsTable.size

	for k, v in pairs(e2ExtensionsTable.s) do
		s[k] = v
		stypes[k] = "n"
	end

	return ret
end

__e2setcost(5)

[nodiscard]
e2function number getExtensionStatus(string extension)
	return getExtensionStatus(extension) and 1 or 0
end

--[[******************************************************************************]]--

registerCallback("construct", function(self)
	self.data.changed = {}
end)

__e2setcost(5)

-- This is the prototype for everything that can be compared using the == operator
[nodiscard]
e2function number changed(value)
	local chg = self.data.changed

	if value == chg[typeids] then return 0 end

	chg[typeids] = value
	return 1
end

[nodiscard]
e2function number changed(vector value)
	local chg = self.data.changed

	if chg[typeids] == value then
		return 0
	end

	chg[typeids] = value
	return 1
end

-- This is the prototype for all table types.
[nodiscard]
e2function number changed(vector4 value)
	local chg = self.data.changed

	local this_chg = chg[typeids]
	if not this_chg then
		chg[typeids] = value
		return 1
	end
	for i,v in pairs(value) do
		if v ~= this_chg[i] then
			chg[typeids] = value
			return 1
		end
	end
	return 0
end

__e2setcost(1)

local excluded_types = {
	n = true,
	v = true,
	a = true,
	xv4 = true,
	[""] = true,

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
	-- Angle is the same as vector
	registerFunction("changed", "a", "n", registeredfunctions.e2_changed_v, 5, nil, { legacy = false })

	-- generate this function for all types
	for typeid,_ in pairs(wire_expression_types2) do
		if not excluded_types[typeid] then
			if comparable_types[typeid] then
				registerFunction("changed", typeid, "n", registeredfunctions.e2_changed_n, 5, nil, { legacy = false })
			else
				registerFunction("changed", typeid, "n", registeredfunctions.e2_changed_xv4, 5, nil, { legacy = false })
			end
		end
	end

	e2Extensions = E2Lib.GetExtensions()
	e2ExtensionsTable = E2Lib.newE2Table()
	do
		local s, stypes, size = e2ExtensionsTable.s, e2ExtensionsTable.stypes, 0
		for _, ext in ipairs(e2Extensions) do
			s[ext] = getExtensionStatus(ext) and 1 or 0
			stypes[ext] = "n"
			size = size + 1
		end
		e2ExtensionsTable.size = size
	end
end)

--[[******************************************************************************]]--

__e2setcost( 5 )

local getHash = E2Lib.getHash
[nodiscard]
e2function number hash()
	return getHash( self, self.entity.original )
end

[nodiscard]
e2function number hashNoComments()
	return getHash( self, self.entity.buffer )
end

[nodiscard, deprecated]
e2function number hash( string str )
	return getHash( self, str )
end
