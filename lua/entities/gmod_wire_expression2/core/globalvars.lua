--[[
gvars v2
Made by Divran
]]

E2Lib.RegisterExtension( "gtable", true, "Allows users to create gTables to transmit data between E2 chips.", "!!! Very easy to exploit to use a ton of server memory. Superceded by event remote." )

local gvars = {}
gvars.shared = {}
gvars.safe = {} -- Safe from hacking using gTableSafe

hook.Add("Wire_EmergencyRamClear","gvars_EmergencyRamClear",function()
	gvars = {}
	gvars.shared = {}
	gvars.safe = {}
end)

------------------------------------------------------------------------------------------------
-- GVARS V2
------------------------------------------------------------------------------------------------
------------------------------------------------
-- Type
------------------------------------------------
registerType( "gtable", "xgt", {},
	function(self) self.entity:Error("You may not input a gtable.") end,
	function(self) self.entity:Error("You may not output a gtable.") end,
	nil,
	function(v)
		return !istable(v)
	end
)

__e2setcost(1)

e2function number operator_is(gtable this)
	return istable(this) and 1 or 0
end

------------------------------------------------
-- gTable
------------------------------------------------
__e2setcost(1)

e2function gtable gTable( string groupname )
	if (!gvars[self.uid][groupname]) then gvars[self.uid][groupname] = {} end
	return gvars[self.uid][groupname]
end

e2function gtable gTable( string groupname, number shared )
	if shared == 0 then
		if (!gvars[self.uid][groupname]) then gvars[self.uid][groupname] = {} end
		return gvars[self.uid][groupname]
	else
		if (!gvars.shared[groupname]) then gvars.shared[groupname] = {} end
		return gvars.shared[groupname]
	end
end

local getHash = E2Lib.getHash
e2function gtable gTableSafe( number shared )
	local hash = getHash( self, self.entity.buffer )
	if shared == 0 then
		if not gvars[self.uid][hash] then gvars[self.uid][hash] = {} end
		return gvars[self.uid][hash]
	else
		if not gvars.safe[hash] then gvars.safe[hash] = {} end
		return gvars.safe[hash]
	end
end

__e2setcost(5)

-- Clear the non-shared table
e2function void gRemoveAll()
	for k,v in pairs( gvars[self.uid] ) do
		self.prf = self.prf + 0.3

		for k2,v2 in pairs( v ) do
			self.prf = self.prf + 0.3
			v[k2] = nil
		end

		gvars[self.uid][k] = nil
	end
end

e2function void gtable:clear()
	for k,v in pairs( this ) do
		this[k] = nil
		self.prf = self.prf + 0.3
	end
end

e2function number gtable:count()
	local ret = table.Count( this )
	self.prf = self.prf + ret / 3
	return ret
end

local string_sub = string.sub
e2function table gtable:toTable()
	local ret = E2Lib.newE2Table()

	for k,v in pairs( this ) do
		if self.prf > e2_tickquota then error("perf", 0) end

		local typeid, index = string_sub( k, 1,1 ), string_sub( k, 2 )
		if typeid == "x" then
			typeid = string_sub( k, 1,3 )
			index = string_sub( k, 4 )
		end

		ret.s[index] = v
		ret.stypes[index] = typeid
		ret.size = ret.size + 1

		self.prf = self.prf + 3
	end

	return ret
end

------------------------------------------------
-- Get/Set functions
------------------------------------------------
-- Upperfirst, used by the E2 functions below
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

local non_allowed_types = { -- If anyone can think of any other types that should never be allowed, enter them here.
	xgt = true,
}

local fixDefault = E2Lib.fixDefault

registerCallback("postinit",function()
	for k,v in pairs( wire_expression_types ) do
		if (!non_allowed_types[v[1]]) then
			if (k == "NORMAL") then k = "NUMBER" end
			k = upperfirst(k)

			__e2setcost(5)

			-- Table[index,type] functions
			local function getf(state, gtable, key)
				if isnumber(key) then key = tostring(key) end
				local val = gtable[v[1]..key]
				if val then -- If the var exists
					return val -- return it
				else
					return fixDefault(v[2])
				end
			end

			local function setf(state, gtable, key, value)
				if isnumber(key) then key = tostring(key) end
				gtable[v[1] .. key] = value
				return value
			end

			registerOperator("indexget", "xgts" .. v[1], v[1], getf) -- G[S,type]
			registerOperator("indexset", "xgts".. v[1], "", setf) -- G[S,type]
			registerOperator("indexget", "xgtn" .. v[1], v[1], getf) -- G[N,type] (same as G[N:toString(),type])
			registerOperator("indexset", "xgtn".. v[1], "", setf) -- G[N,type] (same as G[N:toString(),type])
			------

			--gRemove* -- Remove the variable at the specified index and return it
			registerFunction("remove"..k,"xgt:s",v[1],function(self,args)
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
				local val = rv1[v[1]..rv2]
				if (val) then
					rv1[v[1]..rv2] = nil
					return val
				end
				return E2Lib.fixDefault(v[2])
			end)

			-- gRemoveAll*() - Remove all variables of a type in the player's non-shared table
			registerFunction("gRemoveAll"..k.."s","","",function(self,args)
				for k2,v2 in pairs( gvars[self.uid] ) do
					for k3, v3 in pairs( v2 ) do
						self.prf = self.prf + 0.3
						if (string.Left(k3,#v[1]) == v[1]) then
							gvars[self.uid][k2][k3] = nil
							--v3 = nil
						end
					end
				end
			end)

			-- gRemoveAll*(S) - Remove all variables of a type in the player's non-shared table in the specified group
			registerFunction("gRemoveAll"..k.."s","s","",function(self,args)
				local op1 = args[2]
				local rv1 = op1[1](self,op1)
				if (gvars[self.uid][rv1]) then
					for k2,v2 in pairs( gvars[self.uid][rv1] ) do
						self.prf = self.prf + 0.3
						if (string.Left(k2,#v[1]) == v[1]) then
							gvars[self.uid][rv1][k2] = nil
							--v2 = nil
						end
					end
				end
			end)

			--------------------------------------------------------------------------------
			-- gTable converts all numeric indexes to strings, so we can only support iterating string keys
			--------------------------------------------------------------------------------
			__e2setcost(1)

			local len = #v[1]

			local function iter(tbl, i)
				local key, value = next(tbl, i)
				if key and key:sub(1, len) == v[1] then
					return key, value
				end
			end

			registerOperator("iter", "s" .. v[1] .. "=xgt", "", function(state, gtable)
				return function()
					return iter, gtable
				end
			end)

		end -- allowed check
	end -- loop
end) -- postinit

------------------------------------------------------------------------------------------------
-- ALL BELOW FUNCTIONS ARE DEPRECATED (Only for compability)
------------------------------------------------------------------------------------------------
------------------------------------------------
-- Group management
------------------------------------------------
__e2setcost(1)

[deprecated]
e2function void gSetGroup( string groupname )
	self.data.gvars.group = groupname
end

[deprecated]
e2function string gGetGroup()
	return self.data.gvars.group or ""
end

[deprecated]
e2function void gShare( number share )
	self.data.gvars.shared = math.Clamp(share,0,1)
end

[deprecated]
e2function number gGetShare()
	return self.data.gvars.shared or 0
end

[deprecated]
e2function void gResetGroup()
	self.data.gvars.group = "default"
end

------------------------------------------------
-- Get/Set functions
------------------------------------------------
registerCallback("postinit",function()

	local types = {}

	types.Str = { "s", wire_expression_types.STRING }
	types.Num = { "n", wire_expression_types.NORMAL }
	types.Ent = { "e", wire_expression_types.ENTITY }
	types.Vec = { "v", wire_expression_types.VECTOR }
	types.Ang = { "a", wire_expression_types.ANGLE  }

	local function GetVar( Group, Tbl, Index, Type )
		if (Tbl[Group]) then
			local val = Tbl[Group][Type..Index]
			if (val) then -- If the var exists
				return val -- return it
			end
		end
	end

	for k,v in pairs( types ) do
		-- gSet*(S,*)
		registerFunction("gSet"..k,"s"..v[1],"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
			if (self.data.gvars.shared == 1) then
				if (!gvars.shared[self.data.gvars.group]) then gvars.shared[self.data.gvars.group] = {} end
				gvars.shared[self.data.gvars.group][v[1]..rv1] = rv2
			else
				if (!gvars[self.uid][self.data.gvars.group]) then gvars[self.uid][self.data.gvars.group] = {} end
				gvars[self.uid][self.data.gvars.group][v[1]..rv1] = rv2
			end
		end, 8, nil, { deprecated = true })

		-- gGet*(S)
		registerFunction("gGet"..k,"s",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = op1[1](self,op1)
			if (self.data.gvars.shared == 1) then
				local ret = GetVar(self.data.gvars.group,gvars.shared,rv1,v[1])
				if (ret) then return ret end
				return E2Lib.fixDefault(v[2][2])
			else
				local ret = GetVar(self.data.gvars.group,gvars[self.uid],rv1,v[1])
				if (ret) then return ret end
				return E2Lib.fixDefault(v[2][2])
			end
		end, 8, nil, { deprecated = true })

		-- gSet*(N,*) (same as gSet*(N:toString(),*)
		registerFunction("gSet"..k,"n"..v[1],"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
			if (self.data.gvars.shared == 1) then
				if (!gvars.shared[self.data.gvars.group]) then gvars.shared[self.data.gvars.group] = {} end
				gvars.shared[self.data.gvars.group][v[1]..tostring(rv1)] = rv2
			else
				if (!gvars[self.uid][self.data.gvars.group]) then gvars[self.uid][self.data.gvars.group] = {} end
				gvars[self.uid][self.data.gvars.group][v[1]..tostring(rv1)] = rv2
			end
		end, 8, nil, { deprecated = true })

		-- gGet*(N) (same as gGet*(N:toString()))
		registerFunction("gGet"..k,"n",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = tostring(op1[1](self,op1))
			if (self.data.gvars.shared == 1) then
				local ret = GetVar(self.data.gvars.group,gvars.shared,rv1,v[1])
				if (ret) then return ret end
				return E2Lib.fixDefault(v[2][2])
			else
				local ret = GetVar(self.data.gvars.group,gvars[self.uid],rv1,v[1])
				if (ret) then return ret end
				return E2Lib.fixDefault(v[2][2])
			end
		end, 8, nil, { deprecated = true })

		-- gDelete*(S)
		registerFunction("gDelete"..k,"s",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = op1[1](self,op1)
			if (self.data.gvars.shared == 1) then
				if (gvars.shared[self.data.gvars.group]) then
					if (gvars.shared[self.data.gvars.group][v[1]..rv1]) then
						local val = gvars.shared[self.data.gvars.group][v[1]..rv1]
						gvars.shared[self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			else
				if (gvars[self.uid][self.data.gvars.group]) then
					if (gvars[self.uid][self.data.gvars.group][v[1]..rv1]) then
						local val = gvars[self.uid][self.data.gvars.group][v[1]..rv1]
						gvars[self.uid][self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			end
			return E2Lib.fixDefault(v[2][2])
		end, 8, nil, { deprecated = true })

		-- gDelete*(N) (same as gDelete*(N:toString()))
		registerFunction("gDelete"..k,"n",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = tostring(op1[1](self,op1))
			if (self.data.gvars.shared == 1) then
				if (gvars.shared[self.data.gvars.group]) then
					if (gvars.shared[self.data.gvars.group][v[1]..rv1]) then
						local val = gvars.shared[self.data.gvars.group][v[1]..rv1]
						gvars.shared[self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			else
				if (gvars[self.uid][self.data.gvars.group]) then
					if (gvars[self.uid][self.data.gvars.group][v[1]..rv1]) then
						local val = gvars[self.uid][self.data.gvars.group][v[1]..rv1]
						gvars[self.uid][self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			end
			return E2Lib.fixDefault(v[2][2])
		end, 8, nil, { deprecated = true })

		-- gDeleteAll*()
		registerFunction("gDeleteAll"..k,"","",function(self,args)
			for k,v in pairs( gvars[self.uid][self.data.gvars.group] ) do
				self.prf = self.prf + 0.3
				if (string.Left(k,#v[1]) == v[1]) then
					v = nil
				end
			end
		end, 5, nil, { deprecated = true })
	end

end)
------------------------------------------------------------------------------------------------
-- ALL ABOVE FUNCTIONS ARE DEPRECATED (Only for compability)
------------------------------------------------------------------------------------------------
------------------------------------------------
-- Construct/Destruct
------------------------------------------------
registerCallback("construct",function(self)
	self.data.gvars = {}
	self.data.gvars.group = "default"
	self.data.gvars.shared = 0
	if (!gvars[self.uid]) then gvars[self.uid] = {} end
end)
