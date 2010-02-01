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

e2function void gSetStr(string rv1)
	local T = glTid(self)
	T["xs"] = rv1
end

e2function string gGetStr()
	local T = glTid(self)
	if T["xs"]==nil then return "" end
	return T["xs"]
end

e2function string gDeleteStr()
	local T = glTid(self)
	if T["xs"]==nil then return "" end
	local value = T["xs"]
	T["xs"] = nil
	return value
end

e2function void gSetStr(string rv1, string rv2)
	local T = glTid(self)
	T["s"][rv1] = rv2
end

e2function string gGetStr(string rv1)
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end

e2function string gDeleteStr(string rv1)
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end

e2function void gSetStr(rv1, string rv2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["s"][rv1] = rv2
end

e2function string gGetStr(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end

e2function string gDeleteStr(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end

//--------------------------//
//--       Numbers        --//
//--------------------------//

e2function void gSetNum(rv1)
	local T = glTid(self)
	T["xn"] = rv1
end

e2function number gGetNum()
	local T = glTid(self)
	if T["xn"]==nil then return 0 end
	return T["xn"]
end

e2function number gDeleteNum()
	local T = glTid(self)
	if T["xn"]==nil then return 0 end
	local value = T["xn"]
	T["xn"] = nil
	return value
end

e2function void gSetNum(string rv1, rv2)
	local T = glTid(self)
	T["n"][rv1] = rv2
end

e2function number gGetNum(string rv1)
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end

e2function number gDeleteNum(string rv1)
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end

e2function void gSetNum(rv1, rv2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["n"][rv1] = rv2
end

e2function number gGetNum(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end

e2function number gDeleteNum(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end

//--------------------------//
//--       Vectors        --//
//--------------------------//

e2function void gSetVec(vector rv1)
	local T = glTid(self)
	if rv1[1] == 0 and rv1[2] == 0 and rv1[3] == 0 then rv1 = nil end
	T["xv"] = rv1
end

e2function vector gGetVec()
	local T = glTid(self)
	return T["xv"] or { 0, 0, 0 }
end

e2function vector gDeleteVec()
	local T = glTid(self)
	if T["xv"]==nil then return { 0, 0, 0 } end
	local value = T["xv"]
	T["xv"] = nil
	return value
end

e2function void gSetVec(string rv1, vector rv2)
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["v"][rv1] = rv2
end

e2function vector gGetVec(string rv1)
	local T = glTid(self)
	return T["v"][rv1] or { 0, 0, 0 }
end

e2function vector gDeleteVec(string rv1)
	local T = glTid(self)
	if T["v"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["v"][rv1]
	T["v"][rv1] = nil
	return value
end

e2function void gSetVec(rv1, vector rv2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["v"][rv1] = rv2
end

e2function vector gGetVec(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	return T["v"][rv1] or { 0, 0, 0 }
end

e2function vector gDeleteVec(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["v"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["v"][rv1]
	T["v"][rv1] = nil
	return value
end

//--------------------------//
//--        Angles        --//
//--------------------------//

e2function void gSetAng(angle rv1)
	local T = glTid(self)
	if rv1[1] == 0 and rv1[2] == 0 and rv1[3] == 0 then rv1 = nil end
	T["xa"] = rv1
end

e2function angle gGetAng()
	local T = glTid(self)
	local ret = T["xa"]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end

e2function angle gDeleteAng()
	local T = glTid(self)
	if T["xa"]==nil then return { 0, 0, 0 } end
	local value = T["xa"]
	T["xa"] = nil
	return value
end

e2function void gSetAng(string rv1, angle rv2)
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["a"][rv1] = rv2
end

e2function angle gGetAng(string rv1)
	local T = glTid(self)
	local ret = T["a"][rv1]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end

e2function angle gDeleteAng(string rv1)
	local T = glTid(self)
	if T["a"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["a"][rv1]
	T["a"][rv1] = nil
	return value
end

e2function void gSetAng(rv1, angle rv2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	T["a"][rv1] = rv2
end

e2function angle gGetAng(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["a"][rv1]
	if type(ret) == "table" and #ret == 3 then return ret end
	return { 0, 0, 0 }
end

e2function angle gDeleteAng(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	if T["a"][rv1]==nil then return { 0, 0, 0 } end
	local value = T["a"][rv1]
	T["a"][rv1] = nil
	return value
end

//--------------------------//
//--        Entity        --//
//--------------------------//

e2function void gSetEnt(entity rv1)
	local T = glTid(self)
	T["xe"] = rv1
end

e2function entity gGetEnt()
	local T = glTid(self)
	local ret = T["xe"]
	if validEntity(ret) then return ret end
	return nil
end

e2function entity gDeleteEnt()
	local T = glTid(self)
	local ret = T["xe"]
	T["xe"] = nil
	if validEntity(ret) then return ret end
	return nil
end

e2function void gSetEnt(string rv1, entity rv2)
	local T = glTid(self)
	T["e"][rv1] = rv2
end

e2function entity gGetEnt(string rv1)
	local T = glTid(self)
	local ret = T["e"][rv1]
	if validEntity(ret) then return ret end
	return nil
end

e2function entity gDeleteEnt(string rv1)
	local T = glTid(self)
	local ret = T["e"][rv1]
	T["e"][rv1] = nil
	if validEntity(ret) then return ret end
	return nil
end

e2function void gSetEnt(rv1, entity rv2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["e"][rv1] = rv2
end

e2function entity gGetEnt(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["e"][rv1]
	if validEntity(ret) then return ret end
	return nil
end

e2function entity gDeleteEnt(rv1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	local ret = T["e"][rv1]
	T["e"][rv1] = nil
	if validEntity(ret) then return ret end
	return nil
end

//--------------------------//
//--       Clean Up       --//
//--------------------------//

e2function void gDeleteAll()
	local group = self.data['globavars']
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	if _G[uid][group] then
	_G[uid][group] = nil
	end
end

e2function void gDeleteAllStr()
	local T = glTid(self)
	T["s"] = {}
	T["xs"] = nil
end

e2function void gDeleteAllNum()
	local T = glTid(self)
	T["n"] = {}
	T["xn"] = nil
end

e2function void gDeleteAllVec()
	local T = glTid(self)
	T["v"] = {}
	T["xv"] = nil
end

e2function void gDeleteAllAng()
	local T = glTid(self)
	T["a"] = {}
	T["xa"] = nil
end

e2function void gDeleteAllEnt()
	local T = glTid(self)
	T["e"] = {}
	T["xe"] = nil
end



//--------------------------//
//--       Sharing        --//
//--------------------------//

e2function void gShare(rv1)
	if rv1==0 then self.data['globashare'] = 0
	else self.data['globashare'] = 1 end
end

//--------------------------//
//--    Group Commands    --//
//--------------------------//

e2function void gSetGroup(string rv1)
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
end

e2function string gGetGroup()
	return self.data['globavars']
end

e2function void gResetGroup()
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
end

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
