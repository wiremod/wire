--[[
gvars v2
Made by Divran
]]

local gvars = {}
gvars.shared = {}

------------------------------------------------------------------------------------------------
-- GVARS V2
------------------------------------------------------------------------------------------------
------------------------------------------------
-- Type
------------------------------------------------
registerType( "gtable", "xgt", {},
	function(self) self.entity:Error("You may not input a gtable.") end,
	function(self) self.entity:Error("You may not output a gtable.") end,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a gtable, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "table"
	end
)

__e2setcost(1)

e2function gtable operator=(gtable lhs, gtable rhs)
	--return rhs
	local lookup = self.data.lookup

	-- remove old lookup entry
	if lookup[rhs] then lookup[rhs][lhs] = nil end

	-- add new lookup entry
	local lookup_entry = lookup[rhs]
	if not lookup_entry then
		lookup_entry = {}
		lookup[rhs] = lookup_entry
	end
	lookup_entry[lhs] = true

	self.vars[lhs] = rhs
	--self.vclk[lhs] = true
	return rhs
end

e2function number operator_is( gtable tbl )
	return (type(tbl) == "table")
end

------------------------------------------------
-- gTable
------------------------------------------------
__e2setcost(20)

e2function gtable gTable( string groupname )
	if (!gvars[self.player][groupname]) then gvars[self.player][groupname] = {} end
	return gvars[self.player][groupname]
end

e2function gtable gTable( string groupname, number shared )
	if (shared == 1) then
		if (!gvars.shared[groupname]) then gvars.shared[groupname] = {} end
		return gvars.shared[groupname]
	else
		if (!gvars[self.player][groupname]) then gvars[self.player][groupname] = {} end
		return gvars[self.player][groupname]
	end
end

__e2setcost(10)

-- Clear the non-shared table
e2function void gRemoveAll()
	self.prf = self.prf + table.Count(gvars[self.player]) / 3
	for k,v in pairs( gvars[self.player] ) do
		self.prf = self.prf + table.Count(v) / 3
		table.Empty( v )
	end
	table.Empty(gvars[self.player])
end

e2function void gtable:clear()
	self.prf = self.prf + table.Count(this) / 3
	table.Empty(this)
end

------------------------------------------------
-- Get/Set functions
------------------------------------------------
-- Upperfirst, used by the E2 functions below
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

local non_allowed_types = { "xgt" } -- If anyone can think of any other types that should never be allowed, enter them here.

registerCallback("postinit",function()
	for k,v in pairs( wire_expression_types ) do
		if (!table.HasValue(non_allowed_types,v[1])) then
			if (k == "NORMAL") then k = "NUMBER" end
			k = upperfirst(k)

			__e2setcost(10)

			-- Table[index,type] functions
			local function getf( self, args )
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
				if (type(rv2) == "number") then rv2 = tostring(rv2) end
				local val = rv1[v[1]..rv2]
				if (val) then -- If the var exists
					return val -- return it
				end
				local default = v[2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			end
			local function setf( self, args )
				local op1, op2, op3 = args[2], args[3], args[4]
				local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
				if (type(rv2) == "number") then rv2 = tostring(rv2) end
				rv1[v[1]..rv2] = rv3
			end

			registerOperator("idx", v[1].."=xgts", v[1], getf) -- G[S,type]
			registerOperator("idx", v[1].."=xgts"..v[1], v[1], setf) -- G[S,type]
			registerOperator("idx", v[1].."=xgtn", v[1], getf) -- G[N,type] (same as G[N:toString(),type])
			registerOperator("idx", v[1].."=xgtn"..v[1], v[1], setf) -- G[N,type] (same as G[N:toString(),type])
			------

			__e2setcost(15)
			--gRemove* -- Remove the variable at the specified index and return it
			registerFunction("remove"..k,"xgt:s",v[1],function(self,args)
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
				local val = rv1[v[1]..rv2]
				if (val) then
					rv1[v[1]..rv2] = nil
					return val
				end
				local default = v[2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			end)

			__e2setcost(50)
			-- gRemoveAll*() - Remove all variables of a type in the player's non-shared table
			registerFunction("gRemoveAll"..k.."s","","",function(self,args)
				for k2,v2 in pairs( gvars[self.player] ) do
					for k3, v3 in pairs( v2 ) do
						if (string.Left(k3,#v[1]) == v[1]) then
							gvars[self.player][k2][k3] = nil
							--v3 = nil
						end
					end
				end
			end)

			__e2setcost(25)
			-- gRemoveAll*(S) - Remove all variables of a type in the player's non-shared table in the specified group
			registerFunction("gRemoveAll"..k.."s","s","",function(self,args)
				local op1 = args[2]
				local rv1 = op1[1](self,op1)
				if (gvars[self.player][rv1]) then
					for k2,v2 in pairs( gvars[self.player][rv1] ) do
						if (string.Left(k2,#v[1]) == v[1]) then
							gvars[self.player][rv1][k2] = nil
							--v2 = nil
						end
					end
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
__e2setcost(4)

e2function void gSetGroup( string groupname )
	self.data.gvars.group = groupname
end

e2function string gGetGroup()
	return self.data.gvars.group or ""
end

e2function void gShare( number share )
	self.data.gvars.shared = math.Clamp(share,0,1)
end

e2function number gGetShare()
	return self.data.gvars.shared or 0
end

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

		__e2setcost(10)

		-- gSet*(S,*)
		registerFunction("gSet"..k,"s"..v[1],"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
			if (self.data.gvars.shared == 1) then
				if (!gvars.shared[self.data.gvars.group]) then gvars.shared[self.data.gvars.group] = {} end
				gvars.shared[self.data.gvars.group][v[1]..rv1] = rv2
			else
				if (!gvars[self.player][self.data.gvars.group]) then gvars[self.player][self.data.gvars.group] = {} end
				gvars[self.player][self.data.gvars.group][v[1]..rv1] = rv2
			end
		end)

		-- gGet*(S)
		registerFunction("gGet"..k,"s",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = op1[1](self,op1)
			if (self.data.gvars.shared == 1) then
				local ret = GetVar(self.data.gvars.group,gvars.shared,rv1,v[1])
				if (ret) then return ret end
				local default = v[2][2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			else
				local ret = GetVar(self.data.gvars.group,gvars[self.player],rv1,v[1])
				if (ret) then return ret end
				local default = v[2][2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			end
		end)

		-- gSet*(N,*) (same as gSet*(N:toString(),*)
		registerFunction("gSet"..k,"n"..v[1],"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
			if (self.data.gvars.shared == 1) then
				if (!gvars.shared[self.data.gvars.group]) then gvars.shared[self.data.gvars.group] = {} end
				gvars.shared[self.data.gvars.group][v[1]..tostring(rv1)] = rv2
			else
				if (!gvars[self.player][self.data.gvars.group]) then gvars[self.player][self.data.gvars.group] = {} end
				gvars[self.player][self.data.gvars.group][v[1]..tostring(rv1)] = rv2
			end
		end)

		-- gGet*(N) (same as gGet*(N:toString()))
		registerFunction("gGet"..k,"n",v[1],function(self,args)
			local op1 = args[2]
			local rv1 = tostring(op1[1](self,op1))
			if (self.data.gvars.shared == 1) then
				local ret = GetVar(self.data.gvars.group,gvars.shared,rv1,v[1])
				if (ret) then return ret end
				local default = v[2][2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			else
				local ret = GetVar(self.data.gvars.group,gvars[self.player],rv1,v[1])
				if (ret) then return ret end
				local default = v[2][2]
				if (type(default) == "table") then default = table.Copy(default) end
				return default
			end
		end)

		__e2setcost(20)

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
				if (gvars[self.player][self.data.gvars.group]) then
					if (gvars[self.player][self.data.gvars.group][v[1]..rv1]) then
						local val = gvars[self.player][self.data.gvars.group][v[1]..rv1]
						gvars[self.player][self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			end
			local default = v[2][2]
			if (type(default) == "table") then default = table.Copy(default) end
			return default
		end)

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
				if (gvars[self.player][self.data.gvars.group]) then
					if (gvars[self.player][self.data.gvars.group][v[1]..rv1]) then
						local val = gvars[self.player][self.data.gvars.group][v[1]..rv1]
						gvars[self.player][self.data.gvars.group][v[1]..rv1] = nil
						return val
					end
				end
			end
			local default = v[2][2]
			if (type(default) == "table") then default = table.Copy(default) end
			return default
		end)

		__e2setcost(25)

		-- gDeleteAll*()
		registerFunction("gDeleteAll"..k,"","",function(self,args)
			for k,v in pairs( gvars[self.player][self.data.gvars.group] ) do
				if (string.Left(k,#v[1]) == v[1]) then
					v = nil
				end
			end
		end)
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
	if (!gvars[self.player]) then gvars[self.player] = {} end
end)

hook.Add("EntityRemoved","Expression2_gvars_PlayerDisconnected",function(ply)
	if (ply:IsValid() and ply:IsPlayer() and gvars[ply]) then
		gvars[ply] = nil
	end
end)

__e2setcost(nil)

--[[
registerCallback("postexecute",function(self)
	self.data.gvars.group = "default"
	self.data.gvars.shared = 0
end)
]]
