/******************************************************************************\
  Global variable support v1.5
\******************************************************************************/

//--------------------------//
//--   Helper Functions   --//
//--------------------------//

local function glTid(self)
	local group = self.data['globavars']
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	if !_G[uid][group] then
		_G[uid][group] = {}
		local T = _G[uid][group]
		T["s"] = {}
		T["n"] = {}
		T["v"] = {}
		T["a"] = {}
		T["e"] = {}
		return T
	end
	return _G[uid][group]
end

//--------------------------//
//--       Strings        --//
//--------------------------//

__e2setcost(5) -- temporary

registerFunction("gSetStr", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	T["xs"] = rv1
end)

registerFunction("gGetStr", "", "s", function(self, args)
	local T = glTid(self)
	if T["xs"]==nil then return "" end
	return T["xs"]
end)

registerFunction("gDeleteStr", "", "s", function(self, args)
	local T = glTid(self)
	if T["xs"]==nil then return "" end
	local value = T["xs"]
	T["xs"] = nil
	return value
end)

registerFunction("gSetStr", "ss", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end)

registerFunction("gSetStr", "ns", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end)

//--------------------------//
//--       Numbers        --//
//--------------------------//

registerFunction("gSetNum", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	T["xn"] = rv1
end)

registerFunction("gGetNum", "", "n", function(self, args)
	local T = glTid(self)
	if T["xn"]==nil then return 0 end
	return T["xn"]
end)

registerFunction("gDeleteNum", "", "n", function(self, args)
	local T = glTid(self)
	if T["xn"]==nil then return 0 end
	local value = T["xn"]
	T["xn"] = nil
	return value
end)

registerFunction("gSetNum", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

registerFunction("gSetNum", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

//--------------------------//
//--       Vectors        --//
//--------------------------//

registerFunction("gSetVec", "v", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if rv1[1] == 0 and rv1[2] == 0 and rv1[3] == 0 then rv1 = nil end
	T["xv"] = rv1
end)

registerFunction("gGetVec", "", "v", function(self, args)
	local T = glTid(self)
	return T["xv"] or { 0, 0, 0 }
end)

registerFunction("gDeleteVec", "", "v", function(self, args)
	local T = glTid(self)
	if T["xv"]==nil then return { 0, 0, 0 } end
	local value = T["xv"]
	T["xv"] = nil
	return value
end)

registerFunction("gSetVec", "sv", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["v"][rv1] = rv2
end)

registerFunction("gGetVec", "s", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	return T["v"][rv1] or { 0, 0, 0 }
end)

registerFunction("gDeleteVec", "s", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["v"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["v"][rv1]
	T["v"][rv1] = nil
	return value
end)

registerFunction("gSetVec", "nv", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["v"][rv1] = rv2
end)

registerFunction("gGetVec", "n", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	return T["v"][rv1] or { 0, 0, 0 }
end)

registerFunction("gDeleteVec", "n", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["v"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["v"][rv1]
	T["v"][rv1] = nil
	return value
end)

//--------------------------//
//--        Angles        --//
//--------------------------//

registerFunction("gSetAng", "a", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if rv1[1] == 0 and rv1[2] == 0 and rv1[3] == 0 then rv1 = nil end
	T["xa"] = rv1
end)

registerFunction("gGetAng", "", "a", function(self, args)
	local T = glTid(self)
	local ret = T["xa"]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("gDeleteAng", "", "a", function(self, args)
	local T = glTid(self)
	if T["xa"]==nil then return { 0, 0, 0 } end
	local value = T["xa"]
	T["xa"] = nil
	return value
end)

registerFunction("gSetAng", "sa", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["a"][rv1] = rv2
end)

registerFunction("gGetAng", "s", "a", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	local ret = T["a"][rv1]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("gDeleteAng", "s", "a", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	if T["a"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["a"][rv1]
	T["a"][rv1] = nil
	return value
end)

registerFunction("gSetAng", "na", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["a"][rv1] = rv2
end)

registerFunction("gGetAng", "n", "a", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["a"][rv1]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("gDeleteAng", "n", "a", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["a"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["a"][rv1]
	T["a"][rv1] = nil
	return value
end)

//--------------------------//
//--        Entity        --//
//--------------------------//

registerFunction("gSetEnt", "e", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	T["xe"] = rv1
end)

registerFunction("gGetEnt", "", "e", function(self, args)
	local T = glTid(self)
	local ret = T["xe"]
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("gDeleteEnt", "", "e", function(self, args)
	local T = glTid(self)
	local ret = T["xe"]
	T["xe"] = nil
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("gSetEnt", "se", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	T["e"][rv1] = rv2
end)

registerFunction("gGetEnt", "s", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	local ret = T["e"][rv1]
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("gDeleteEnt", "s", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	local ret = T["e"][rv1]
	T["e"][rv1] = nil
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("gSetEnt", "ne", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["e"][rv1] = rv2
end)

registerFunction("gGetEnt", "n", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["e"][rv1]
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("gDeleteEnt", "n", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["e"][rv1]
	T["e"][rv1] = nil
	if validEntity(ret) then return ret end
	return nil
end)

//--------------------------//
//--       Clean Up       --//
//--------------------------//

registerFunction("gDeleteAll", "", "", function(self, args)
	local group = self.data['globavars']
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	if _G[uid][group] then
	_G[uid][group] = nil
	end
end)

registerFunction("gDeleteAllStr", "", "", function(self, args)
	local T = glTid(self)
	T["s"] = {}
	T["xs"] = nil
end)

registerFunction("gDeleteAllNum", "", "", function(self, args)
	local T = glTid(self)
	T["n"] = {}
	T["xn"] = nil
end)

registerFunction("gDeleteAllVec", "", "", function(self, args)
	local T = glTid(self)
	T["v"] = {}
	T["xv"] = nil
end)

registerFunction("gDeleteAllAng", "", "", function(self, args)
	local T = glTid(self)
	T["a"] = {}
	T["xa"] = nil
end)

registerFunction("gDeleteAllEnt", "", "", function(self, args)
	local T = glTid(self)
	T["e"] = {}
	T["xe"] = nil
end)



//--------------------------//
//--       Sharing        --//
//--------------------------//

registerFunction("gShare", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1==0 then self.data['globashare'] = 0
	else self.data['globashare'] = 1 end
end)

//--------------------------//
//--    Group Commands    --//
//--------------------------//

registerFunction("gSetGroup", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	self.data['globavars'] = rv1
	local group = self.data['globavars']
	if _G[uid][group]==nil then _G[uid][group] = {} end
	local T = _G[uid][group]
	if !T["s"] then T["s"] = {} end
	if !T["n"] then T["n"] = {} end
	if !T["v"] then T["v"] = {} end
	if !T["a"] then T["a"] = {} end
	if !T["e"] then T["e"] = {} end
end)

registerFunction("gGetGroup", "", "s", function(self, args)
	return self.data['globavars']
end)

registerFunction("gResetGroup", "", "", function(self, args)
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	self.data['globavars'] = "default"
	local group = self.data['globavars']
	if !_G[uid][group] then _G[uid][group] = {} end
	local T = _G[uid][group]
	if !T["s"] then T["s"] = {} end
	if !T["n"] then T["n"] = {} end
	if !T["v"] then T["v"] = {} end
	if !T["a"] then T["a"] = {} end
	if !T["e"] then T["e"] = {} end
end)

/******************************************************************************/

registerCallback("construct", function(self)
	if self.data['globavars'] != "default" then
		self.data['globavars'] = "default"
	end
	self.data['globaply'] = self.player:UniqueID()
	self.data['globashare'] = 0
end)

registerCallback("postexecute", function(self)
	if self.data['globavars'] != "default" then
		self.data['globavars'] = "default"
	end
end)

//--------------------------//
//--     Server Hooks     --//
//--------------------------//

_G["exp2globalshare"] = {}

hook.Add( "EntityRemoved", "e2_globalvars_playerdisconnect", function( ply )
	if not ply:IsValid() then return end
	if not ply:IsPlayer() then return end
	local T = _G[ply:UniqueID()]
	if not T then return end

	table.Empty(T)
end)

hook.Add( "PlayerInitialSpawn", "e2_globalvars_playerconnect", function( ply )
	_G[ply:UniqueID()] = {}
end)

__e2setcost(nil) -- temporary
