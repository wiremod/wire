/******************************************************************************\
Prop Core by MrFaul started by ZeikJT
report any wishes, issues to Mr.Faul@gmx.de (GER or ENG pls)
\******************************************************************************/

E2Lib.RegisterExtension("propcore", false, "Allows E2 chips to create and manipulate props", "Can be used to teleport props to arbitrary locations, including other player's faces")
PropCore = {}
local sbox_E2_maxProps = CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
local sbox_E2_maxPropsPerSecond = CreateConVar( "sbox_E2_maxPropsPerSecond", "4", FCVAR_ARCHIVE )
local sbox_E2_PropCore = CreateConVar( "sbox_E2_PropCore", "2", FCVAR_ARCHIVE ) -- 2: Players can affect their own props, 1: Only admins, 0: Disabled
local sbox_E2_canMakeStatue = CreateConVar("sbox_E2_canMakeStatue", "1", FCVAR_ARCHIVE)
local wire_expression2_propcore_sents_whitelist = CreateConVar("wire_expression2_propcore_sents_whitelist", "1", FCVAR_ARCHIVE) -- 1: Players can spawn sents only that are added to the default sent list, 0: Players can spawn any sent (no way to make players not spawn errors then though!)

local isOwner = E2Lib.isOwner
local GetBones = E2Lib.GetBones
local isValidBone = E2Lib.isValidBone
local setPos = WireLib.setPos
local setAng = WireLib.setAng

local E2totalspawnedprops = 0
local E2tempSpawnedProps = 0
local TimeStamp = 0
local playerMeta = FindMetaTable("Player")

local function TempReset()
 if (CurTime()>= TimeStamp) then
	E2tempSpawnedProps = 0
	TimeStamp = CurTime()+1
 end
end
hook.Add("Think","TempReset",TempReset)

function PropCore.WithinPropcoreLimits()
	return (sbox_E2_maxProps:GetInt() <= 0 or E2totalspawnedprops<sbox_E2_maxProps:GetInt()) and E2tempSpawnedProps < sbox_E2_maxPropsPerSecond:GetInt()
end
local WithinPropcoreLimits = PropCore.WithinPropcoreLimits

function PropCore.ValidSpawn(ply, model, vehicleType)
	local ret -- DO NOT RETURN MID-FUNCTION OR 'LimitHit' WILL BREAK
	local limithit = playerMeta.LimitHit
	playerMeta.LimitHit = function() end

	if not PropCore.WithinPropcoreLimits() then
		ret = false
	elseif not (util.IsValidProp( model ) and WireLib.CanModel(ply, model)) then
		ret = false
	elseif vehicleType then
		ret = gamemode.Call( "PlayerSpawnVehicle", ply, model, vehicleType, list.Get( "Vehicles" )[vehicleType] ) ~= false
	else
		ret = gamemode.Call( "PlayerSpawnProp", ply, model ) ~= false
	end

	playerMeta.LimitHit = limithit
	return ret
end
local ValidSpawn = PropCore.ValidSpawn

local canHaveInvalidPhysics = {
	delete=true, parent=true, deparent=true, solid=true,
	shadow=true, draw=true, use=true, pos=true, ang=true,
	manipulate=true
}

function PropCore.ValidAction(self, entity, cmd, bone)
	if cmd == "spawn" or cmd == "Tdelete" then return true end
	if not IsValid(entity) then return self:throw("Invalid entity!", false) end
	if not isOwner(self, entity) then return self:throw("You do not own this entity!", false) end
	if entity:IsPlayer() then return self:throw("You cannot modify players", false) end

	-- For cases when we'd only want to check an entity
	if cmd then
		if not canHaveInvalidPhysics[cmd] and not validPhysics(entity) then return self:throw("Invalid physics object!", false) end
		if bone then
			if not entity["bone" .. bone] then
				entity["bone" .. bone] = {}
			end
			entity = entity["bone" .. bone]
		end

		-- make sure we can only perform the same action on this prop once per tick
		-- to prevent spam abuse
		if not entity.e2_propcore_last_action then
			entity.e2_propcore_last_action = {}
		end
		if 	entity.e2_propcore_last_action[cmd] and entity.e2_propcore_last_action[cmd] == CurTime() then
			return self:throw("You can only perform one type of action per tick!", false)
		end
		entity.e2_propcore_last_action[cmd] = CurTime()
	end

	return sbox_E2_PropCore:GetInt()==2 or (sbox_E2_PropCore:GetInt()==1 and self.player:IsAdmin())
end
local ValidAction = PropCore.ValidAction

local function MakePropNoEffect(...)
	local backup = DoPropSpawnedEffect
	DoPropSpawnedEffect = function() end
	local ret = MakeProp(...)
	DoPropSpawnedEffect = backup
	return ret
end

function PropCore.CreateProp(self, model, pos, angles, freeze, vehicleType)
	if not WithinPropcoreLimits() then return self:throw("Prop limit reached! (cooldown or max)", NULL) end
	if not ValidSpawn(self.player, model, vehicleType) then return NULL end

	pos = WireLib.clampPos( pos )

	local prop

	local cleanupCategory = "props"
	local undoCategory = "e2_spawned_prop"
	local undoName = "E2 Prop"
	if vehicleType then
		local entry = list.Get("Vehicles")[vehicleType]
		if not entry or entry.Class ~= "prop_vehicle_prisoner_pod" then
			return self:throw("Seat type '" .. vehicleType .. "' is invalid", NULL)
		end

		cleanupCategory = "vehicles"
		undoCategory = "e2_spawned_seat"
		undoName = "E2 Seat"

		prop = ents.Create("prop_vehicle_prisoner_pod")
		prop:SetModel(model)
		prop:SetPos(pos)
		prop:SetAngles(angles)
		prop:SetVehicleClass(vehicleType)

		if self.data.propSpawnEffect then DoPropSpawnedEffect( prop ) end

		prop:Spawn()
		prop:SetKeyValue( "limitview", 0 )

		gamemode.Call( "PlayerSpawnedVehicle", self.player, prop )
	else
		prop = self.data.propSpawnEffect and MakeProp( self.player, pos, angles, model, {}, {} ) or MakePropNoEffect( self.player, pos, angles, model, {}, {} )
	end

	if not IsValid( prop ) then return NULL end

	prop:Activate()

	local phys = prop:GetPhysicsObject()
	if IsValid( phys ) then
		if angles ~= nil then setAng( phys, angles ) end
		phys:Wake()
		if freeze > 0 then phys:EnableMotion( false ) end
	end

	self.player:AddCleanup( cleanupCategory, prop )

	if self.data.propSpawnUndo then
		undo.Create( undoCategory )
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish( undoName .. " (" .. model .. ")" )
	end

	prop:CallOnRemove( "wire_expression2_propcore_remove",
		function( prop )
			self.data.spawnedProps[ prop ] = nil
			E2totalspawnedprops = E2totalspawnedprops - 1
		end
	)

	self.data.spawnedProps[ prop ] = self.data.propSpawnUndo
	E2totalspawnedprops = E2totalspawnedprops + 1
	E2tempSpawnedProps = E2tempSpawnedProps + 1

	return prop
end
local CreateProp = PropCore.CreateProp

function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	local phys = this:GetPhysicsObject()
	local physOrThis = IsValid(phys) and phys or this

	if pos ~= nil then setPos( physOrThis, pos ) end
	if rot ~= nil then setAng( physOrThis, rot ) end

	if IsValid( phys ) then
		if freeze ~= nil and this:GetUnFreezable() ~= true then phys:EnableMotion( freeze == 0 ) end
		if gravity ~= nil then phys:EnableGravity( gravity ~= 0 ) end
		if notsolid ~= nil then this:SetSolid( notsolid ~= 0 and SOLID_NONE or SOLID_VPHYSICS ) end
		phys:Wake()
	end
end
local PhysManipulate = PropCore.PhysManipulate

local function boneVerify(self, bone)
	local ent, index = isValidBone(bone)
	if not ent then return self:throw("Invalid bone!", nil) end
	return ent, index
end

-- Silly function to make printout on errors more userfriendly.
local luaTypeIDToString = {
	["-1"] = "none",
	["0"] = "nil",
	["1"] = "boolean",
	["2"] = "lightuserdata",
	["3"] = "number",
	["4"] = "string",
	["5"] = "table",
	["6"] = "function",
	["7"] = "userdata",
	["8"] = "thread",
	["9"] = "entity",
	["10"] = "vector",
	["11"] = "angle",
	["12"] = "physobj",
	["13"] = "save",
	["14"] = "restore",
	["15"] = "damageinfo",
	["16"] = "effectdata",
	["17"] = "movedata",
	["18"] = "recipientfilter",
	["19"] = "usercmd",
	["20"] = "scriptedvehicle",
	["21"] = "material",
	["22"] = "panel",
	["23"] = "particle",
	["24"] = "particleemitter",
	["25"] = "texture",
	["26"] = "usermsg",
	["27"] = "convar",
	["28"] = "imesh",
	["29"] = "matrix",
	["30"] = "sound",
	["31"] = "pixelvishandle",
	["32"] = "dlight",
	["33"] = "video",
	["34"] = "file",
	["35"] = "locomotion",
	["36"] = "path",
	["37"] = "navarea",
	["38"] = "soundhandle",
	["39"] = "navladder",
	["40"] = "particlesystem",
	["41"] = "projectedtexture",
	["42"] = "physcollide",
	["43"] = "surfaceinfo",
	["44"] = "count",
	["255"] = "color",
}
	
-- Only data types that can be directly casted, or already are in the same category. All other
-- E2 types are either need to be transformed, or can't be casted at anything except for table.
local e2TypeNameToLuaTypeIDTable = {
	["none"] = TYPE_NONE,
	["void"] = TYPE_NONE,
	[""] = TYPE_NONE,
	["number"] = TYPE_NUMBER,
	["n"] = TYPE_NUMBER,
	["string"] = TYPE_STRING,
	["s"] = TYPE_STRING,
	["entity"] = TYPE_ENTITY,
	["e"] = TYPE_ENTITY,
	["vector"] = TYPE_VECTOR,
	["v"] = TYPE_VECTOR,
	["angle"] = TYPE_ANGLE,
	["a"] = TYPE_ANGLE,
}

local function e2TypeNameToLuaTypeID(TypeName)
	return e2TypeNameToLuaTypeIDTable[string.lower(TypeName)] or TYPE_TABLE
end

-- Lua type -> E2 to lua casting function. No way to implement default behaviour, so use castE2ValueToLuaValue function instead of table.
-- (It's forward declaration(to make recursive table unpacking possible). Real table is beneath castE2ValueToLuaValue)
local castE2ValueToLuaValueTable = {}

local function castE2ValueToLuaValue(targetTypeID, e2Value)
	local targetTypeID = tostring(targetTypeID)
	if castE2ValueToLuaValueTable[targetTypeID] then
		return castE2ValueToLuaValueTable[targetTypeID](e2Value)
	end

	return nil
end

-- Well, most of it is a nobrainer, but still helpful when you're just iterating and casting everything.
castE2ValueToLuaValueTable = {
	["0"] = function(e2Value) -- TYPE_NIL from whatever :)
		return nil
	end,
	["1"] = function(e2Value) -- TYPE_BOOL from 'number'
		if TypeID(e2Value)==TYPE_NUMBER then
			if e2Value > 0 then return true end
			return false
		end

		return nil
	end,
	["3"] = function(e2Value) -- TYPE_NUMBER from 'number' or 'string'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_NUMBER then return e2Value end
		if e2TypeID == TYPE_STRING then return tonumber(e2Value) end

		return nil
	end,
	["4"] = function(e2Value) -- TYPE_STRING from 'string' or 'number'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_STRING then return e2Value end
		if e2TypeID == TYPE_NUMBER then return tostring(e2Value) end

		return nil
	end,
	["5"] = function(e2Value) -- TYPE_TABLE from 'table, array, ranger, quaternions, and a most other types that aren't present in other casts'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_TABLE then
			if e2Value.ntypes or e2Value.stypes then -- Is it an E2 table? Unpack it correctly then.
				local res = {}
				
				-- Handle 'n' field
				for i, value in ipairs(e2Value["n"]) do
					res[i] = castE2ValueToLuaValue(e2TypeNameToLuaTypeID(e2Value["ntypes"][i]), value) -- recursively unpacks any tables, or just returns the value.
				end
			
				-- Handle 's' field
				for key, value in pairs(e2Value["s"]) do
					res[key] = castE2ValueToLuaValue(e2TypeNameToLuaTypeID(e2Value["stypes"][key]), value) -- recursively unpacks any tables, or just returns the value.
				end
			
				return res
			end

			return e2Value -- It's not? Just return it then.
		end

		if e2TypeID == TYPE_ANGLE or e2TypeID == TYPE_COLOR or e2TypeID == TYPE_VECTOR or e2TypeID == TYPE_MATRIX then return e2Value:ToTable() end
	
		return nil
	end,
	["9"] = function(e2Value) -- TYPE_ENTITY from 'entity'
		if TypeID(e2Value) == TYPE_ENTITY then return e2Value end

		return nil
	end,
	["10"] = function(e2Value) -- TYPE_VECTOR from 'vector' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_VECTOR then return e2Value end
		if e2TypeID == TYPE_TABLE and isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) then return Vector(e2Value[1], e2Value[2], e2Value[3]) end

		return nil
	end,
	["11"] = function(e2Value) -- TYPE_ANGLE from 'angle' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_ANGLE then return e2Value
		elseif e2TypeID == TYPE_TABLE and isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) then return Angle(e2Value[1], e2Value[2], e2Value[3]) end

		return nil
	end,
	["15"] = function(e2Value) -- TYPE_DAMAGEINFO from 'damageinfo'
		if TypeID(e2Value) == TYPE_DAMAGEINFO then return e2Value end
	end,
	["16"] = function(e2Value) -- TYPE_EFFECTDATA from 'effectdata'
		if TypeID(e2Value) == TYPE_EFFECTDATA then return e2Value end
	end,
	["21"] = function(e2Value) -- TYPE_MATERIAL from 'string' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_STRING then return Material(e2Value) end
		if e2TypeID == TYPE_TABLE then -- Png parameters support
			if #e2Value != 2 then return nil end
			
			if TypeID(e2Value[1]) != TYPE_STRING then return nil end
			if TypeID(e2Value[2]) != TYPE_STRING then return nil end

			return Material(e2Value[1], e2Value[2])
		end

		return nil
	end,
	["29"] = function(e2Value) -- TYPE_MATRIX from 'matrix4'
		if TypeID(e2Value) ~= TYPE_TABLE then return nil end

		if #e2Value == 16 then
			for i = 1, 16 do
				if not isnumber(e2Value[i]) then return nil end
			end

			return Matrix({e2Value[1], e2Value[2], e2Value[3], e2Value[4]}, {e2Value[5], e2Value[6], e2Value[7], e2Value[8]}, {e2Value[9], e2Value[10], e2Value[11], e2Value[12]}, {e2Value[13], e2Value[14], e2Value[15], e2Value[16]})
		end

		return nil
	end,
	["255"] = function(e2Value) -- TYPE_COLOR from 'vector' or 'vector4' or 'itable' or 'table'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_VECTOR then
			return Color(e2Value[1], e2Value[2], e2Value[3])
		elseif e2TypeID == TYPE_TABLE then -- vector4 support + direct table support
			if isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) and isnumber(e2Value[4]) then
				return Color(e2Value[1], e2Value[2], e2Value[3], e2Value[4])
			elseif e2Value.r and e2Value.g and e2Value.b then
				if e2Value.a then return Color(e2Value.r, e2Value.g, e2Value.b, e2Value.a) end
				return Color(e2Value.r, e2Value.g, e2Value.b)
			end
		end

		return nil
	end,
}

-- Separate from PropCore.CreateProp, to add some additional checks, and don't make PropCore.ValidAction check sent cases each time anything else is attempted to be spawned (microopt).
function PropCore.CreateSent(self, class, pos, angles, freeze, data)
	if hook.Run( "Expression2_CanSpawnSent", class, self ) == false then return self:throw("A hook prevented this sent to be spawned!", nil) end
	if not WithinPropcoreLimits() then return self:throw("Prop limit reached! (cooldown or max)", NULL) end
	-- Same logic as in PropCore.ValidSpawn
	-- Decided not to put it in a function, as it's only used twice, and abstraction may lead to problems for future devs.
	local limithit = playerMeta.LimitHit
	playerMeta.LimitHit = function() end
	if gamemode.Call( "PlayerSpawnSENT", self.player, class ) == false then
		playerMeta.LimitHit = limithit
		return NULL
	end
	playerMeta.LimitHit = limithit

	pos = WireLib.clampPos( pos )

	local entity
	local undoName = "E2 Sent"

	local whitelist_sent, sent = list.Get("wire_spawnable_ents_whitelist")[class], list.Get("SpawnableEntities")[class]
	
	local isWhitelist = wire_expression2_propcore_sents_whitelist:GetInt() > 0
	if isWhitelist and not whitelist_sent and sent then
		return self:throw("Spawning entity '"..class.."' is not allowed! wire_expression2_propcore_sents_whitelist is enabled", NULL)
	elseif not whitelist_sent and not sent then
		return self:throw("Sent class '"..class.."' is not registered nor in entity tab!", NULL)
	--elseif isWhitelist and sent then
		--whitelist_sent = sent
	end

	data = castE2ValueToLuaValue(TYPE_TABLE, data)
	if whitelist_sent then
		local sentParams = whitelist_sent or {}

		if data.Model and isstring(data.Model) then
			if #data.Model == 0 and sentParams.Model[2] and isstring(sentParams.Model[2]) then data.Model = sentParams.Model[2] end -- Let's try being forgiving (defaulting the model, if provided empty model path).

			if not util.IsValidProp( data.Model ) then return self:throw("'"..data.Model.."' is not a valid model!", NULL) end
			if not WireLib.CanModel( self.player, data.Model ) then return self:throw("You are not allowed to spawn model '"..data.Model.."'", NULL) end
		end

		-- Not sure if we should check for invalid parameters, as it's not really a problem if the user provides more parameters than needed (they will be ignored), but the check
		-- against pre/post factories injections is still required. If you want to validate that all parameters are valid, uncomment the following code instead.
		-- ( Although I'm not sure that compiler would allow injection(I couldn't make it), some smart lads could still find a workaround, so it's better to be safe than sorry :) )
		--for k, v in pairs(data) do
			--if not sentParams[k] then return self:throw("Invalid parameter name '" .. tostring(k).."'", NULL) end
		--end
		-- And comment that instead to save cpu time.
		if data._preFactory then return self:throw("Invalid parameter name '_preFactory'", NULL) end
		if data._postFactory then return self:throw("Invalid parameter name '_postFactory'", NULL) end

		local entityData = {}

		-- Apply data and cast types.
		for param, org in pairs( sentParams ) do
			if TypeID(org)==TYPE_FUNCTION then continue end -- Skipping pre/post factories.

			local value = data[param]

			if value~=nil then -- Attempting to set provided value (need to cast from E2 to Lua type).
				local res = castE2ValueToLuaValue(org[1], value)
				if res==nil then return self:throw("Incorrect parameter '"..param.."' type during spawning '"..class.."'. Expected '"..luaTypeIDToString[tostring(org[1])].."'. Received '"..string.lower(type(value)).."'", NULL) end

				entityData[param] = res
			elseif org[2]~=nil then -- Attempting to set default value if none provided.
				entityData[param] = org[2]
			else
				self:throw("Missing parameter '"..param.."' and no default value is registered.", NULL)
			end
		end

		-- Constructing an entity table
		local enttbl = entityData
		enttbl.Name = ""
		enttbl.Data = entityData
		enttbl.Class = class
		enttbl.Pos = pos
		enttbl.Angle = angles

		local SocketPlugPairs = {}
		for socket, tbl in pairs(list.Get("Wire_Socket_Models")) do
			SocketPlugPairs[socket] = tbl.plug
		end
		local PlugSocketPairs = table.Flip(SocketPlugPairs)

		-- Better be safe, pcall this to ensure we continue running our code, in case these external functions cause an error...
		local factoryErrMessage
		local isOk, errMessage = pcall(function()
			if whitelist_sent._preFactory then
				factoryErrMessage = whitelist_sent._preFactory(self.player, enttbl)
				if factoryErrMessage then error() end
			end

			entity = duplicator.CreateEntityFromTable(self.player, enttbl)

			if not isentity(entity) then
				factoryErrMessage = "(Either corrupted data, or internal error)"
				error("")
			end

			if whitelist_sent._postFactory then
				factoryErrMessage = whitelist_sent._postFactory(self.player, entity, enttbl)
				if factoryErrMessage then error() end
			end

			if entity.PreEntityCopy then
				entity:PreEntityCopy() -- To build dupe modifiers
			end
			if entity.PostEntityCopy then
				entity:PostEntityCopy()
			end
			if entity.PostEntityPaste then
				entity:PostEntityPaste(self.player, entity, {[entity:EntIndex()] = entity})
			end
		end)

		if not isOk then
			if IsValid(entity) then entity:Remove() end
			if factoryErrMessage then
				return self:throw("Failed to spawn '"..class.."'. "..tostring(factoryErrMessage).." (Is your data valid?)", NULL)
			end

			return self:throw("Failed to spawn '"..class.."'. (Internal error). Traceback: "..tostring(errMessage), NULL) -- Not sure, if we should provide tracebacks to scare people.
		end
	elseif sent then -- Spawning an entity from entity tab.
		if sent.AdminOnly and not self.player:IsAdmin() then return self:throw("You do not have permission to spawn '"..class.."' (admin-only)!", NULL) end

		local mockTrace = {
			FractionLeftSolid = 0,
			HitNonWorld       = true,
			Fraction          = 0,
			Entity            = NULL,
			HitPos            = Vector(pos),
			HitNormal         = Vector(0, 0, 0),
			HitBox            = 0,
			Normal            = Vector(1, 0, 0),
			Hit               = true,
			HitGroup          = 0,
			MatType           = 0,
			StartPos          = Vector(0, 0, 0),
			PhysicsBone       = 0,
			WorldToLocal      = Vector(0, 0, 0),
		}
		if sent.t and sent.t.SpawnFunction then
			entity = sent.t.SpawnFunction( sent.t, ply, mockTrace, class )
		else
			entity = ents.Create( class )
			if IsValid(entity) then
				entity:SetPos(pos)
				entity:SetAngles(angles)
				entity:Spawn()
				entity:Activate()
			end
		end

		gamemode.Call("PlayerSpawnedSENT", self.player, entity)
	end

	if not IsValid( entity ) then return NULL end

	entity:Activate()

	local phys = entity:GetPhysicsObject()
	if IsValid( phys ) then
		if angles ~= nil then setAng( phys, angles ) end
		phys:Wake()
		if freeze > 0 then phys:EnableMotion( false ) end
	end

	self.player:AddCleanup( "e2_spawned_sents", entity )
	
	if self.data.propSpawnUndo then
		undo.Create( "e2_spawned_sent" )
			undo.AddEntity( entity )
			undo.SetPlayer( self.player )
		undo.Finish( undoName .. " (" .. class .. ")" )
	end

	entity:CallOnRemove( "wire_expression2_propcore_remove",
		function( entity )
			self.data.spawnedProps[ entity ] = nil
			E2totalspawnedprops = E2totalspawnedprops - 1
		end
	)

	self.data.spawnedProps[ entity ] = self.data.propSpawnUndo
	E2totalspawnedprops = E2totalspawnedprops + 1
	E2tempSpawnedProps = E2tempSpawnedProps + 1

	return entity
end

local CreateSent = PropCore.CreateSent

--------------------------------------------------------------------------------
__e2setcost(40)
e2function entity propSpawn(string model, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if not IsValid(template) then return NULL end
	return CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

--------------------------------------------------------------------------------

__e2setcost(150)
e2function entity sentSpawn(string class)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, self.entity:GetPos()+self.entity:GetUp()*25, self.entity:GetAngles(), 1, {})
end

e2function entity sentSpawn(string class, vector pos)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), self.entity:GetAngles(), 1, {})
end

e2function entity sentSpawn(string class, table data)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, self.entity:GetPos()+self.entity:GetUp()*25, self.entity:GetAngles(), 1, data)
end

e2function entity sentSpawn(string class, vector pos, table data)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), self.entity:GetAngles(), 1, data)
end

e2function entity sentSpawn(string class, vector pos, angle rot)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), Angle(rot[1],rot[2],rot[3]), 1, {})
end

e2function entity sentSpawn(string class, vector pos, angle rot, table data)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), Angle(rot[1],rot[2],rot[3]), 1, data)
end

e2function entity sentSpawn(string class, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), Angle(rot[1],rot[2],rot[3]), frozen, {})
end

e2function entity sentSpawn(string class, vector pos, angle rot, number frozen, table data)
	if not ValidAction(self, nil, "spawn") then return NULL end
	return CreateSent(self, class, Vector(pos[1],pos[2],pos[3]), Angle(rot[1],rot[2],rot[3]), frozen, data)
end

--------------------------------------------------------------------------------

__e2setcost(25)
[nodiscard]
e2function array getWhitelistedSents()
	local res = {}

	local sents = list.Get("wire_spawnable_ents_whitelist")
	
	for classname, tbl in pairs( sents ) do
		res[#res+1] = classname
	end

	return res
end

--------------------------------------------------------------------------------

__e2setcost(30)
[nodiscard]
e2function table getSentData(string class)
	local res = E2Lib.newE2Table()

	local sent = list.Get("wire_spawnable_ents_whitelist")[class]
	if not sent then return res end
	
	local size = 0
	for key, tbl in pairs( sent ) do
		res.s[key] = E2Lib.newE2Table()
		res.s[key].size = 2
		res.s[key].n[1] = luaTypeIDToString[tostring(tbl[1])]
		res.s[key].n[2] = TypeID(tbl[2])==TYPE_BOOL and (tbl[2]==true and "1" or "0") or tostring(tbl[2])
		res.s[key].ntypes[1] = "s"
		res.s[key].ntypes[2] = "s"
		res.stypes[key] = "t"

		size = size + 1
	end
	res.size = size

	return res
end

--------------------------------------------------------------------------------

__e2setcost(20)
[nodiscard]
e2function table getSentDataTypes(string class)
	local res = E2Lib.newE2Table()

	local sent = list.Get("wire_spawnable_ents_whitelist")[class]
	if not sent then return res end
	
	local size = 0
	for key, tbl in pairs( sent ) do
		res.s[key] = E2Lib.newE2Table()
		res.s[key].size = 1
		res.s[key].n[1] = luaTypeIDToString[tostring(tbl[1])]
		res.s[key].ntypes[1] = "s"
		res.stypes[key] = "t"

		size = size + 1
	end
	res.size = size

	return res
end

--------------------------------------------------------------------------------

__e2setcost(20)
[nodiscard]
e2function table getSentDataDefaultValues(string class)
	local res = E2Lib.newE2Table()

	local sent = list.Get("wire_spawnable_ents_whitelist")[class]
	if not sent then return res end
	
	local size = 0
	for key, tbl in pairs( sent ) do
		res.s[key] = E2Lib.newE2Table()
		res.s[key].size = 1
		res.s[key].n[2] = TypeID(tbl[2])==TYPE_BOOL and (tbl[2]==true and "1" or "0") or tostring(tbl[2])
		res.s[key].ntypes[2] = "s"
		res.stypes[key] = "t"

		size = size + 1
	end
	res.size = size

	return res
end

--------------------------------------------------------------------------------

__e2setcost(5)
[nodiscard]
e2function number sentCanCreate()
	if WithinPropcoreLimits() then return 1 end
	return 0
end

[nodiscard]
e2function number sentCanCreate(string class)
	if not WithinPropcoreLimits() then return 0 end

	local whitelist_sent, sent = list.GetForEdit("wire_spawnable_ents_whitelist")[class], list.Get("SpawnableEntities")[class]
	if whitelist_sent then return 1
	elseif sent and wire_expression2_propcore_sents_whitelist:GetInt() <= 0 then return 1 end

	return 0
end

--------------------------------------------------------------------------------

__e2setcost(1)
[nodiscard]
e2function number sentIsWhitelist()
	if wire_expression2_propcore_sents_whitelist:GetInt() > 0 then return 1 else return 0 end
end

--------------------------------------------------------------------------------

local offset = Vector(0, 0, 25)

__e2setcost(50)
e2function entity seatSpawn(string model, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	return CreateProp(self, model, self.entity:LocalToWorld(offset), self.entity:GetAngles(), frozen, "Seat_Airboat")
end

e2function entity seatSpawn(string model, vector pos, angle rot, number frozen)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	return CreateProp(self, model, pos, rot, frozen, "Seat_Airboat")
end

e2function entity seatSpawn(string model, vector pos, angle rot, number frozen, string vehicleType)
	if not ValidAction(self, nil, "spawn") then return NULL end
	if model == "" then model = "models/nova/airboat_seat.mdl" end
	if vehicleType == "" then vehicleType = "Seat_Airboat" end
	return CreateProp(self, model, pos, rot, frozen, vehicleType)
end

--------------------------------------------------------------------------------

__e2setcost(10)
e2function void entity:propDelete()
	if not ValidAction(self, this, "delete") then return end
	this:Remove()
end

e2function void entity:propBreak()
	if not ValidAction(self, this, "break") then return end
	this:Fire("break",1,0)
end

e2function void entity:use()
	if not ValidAction(self, this, "use") then return end

	local ply = self.player
	if not IsValid(ply) then return end -- if the owner isn't connected to the server, do nothing

	if hook.Run( "PlayerUse", ply, this ) == false then return end
	if hook.Run( "WireUse", ply, this, self.entity ) == false then return end

	if this.Use then
		this:Use(ply,self.entity,USE_ON,0)
	else
		this:Fire("use","1",0)
	end
end

__e2setcost(30)
local function removeAllIn( self, tbl )
	local count = 0
	for k,v in pairs( tbl ) do
		if (IsValid(v) and isOwner(self,v) and not v:IsPlayer()) then
			count = count + 1
			v:Remove()
		end
	end
	return count
end

e2function number table:propDelete()
	if not ValidAction(self, nil, "Tdelete") then return 0 end

	local count = removeAllIn( self, this.s )
	count = count + removeAllIn( self, this.n )

	self.prf = self.prf + count

	return count
end

e2function number array:propDelete()
	if not ValidAction(self, nil, "Tdelete") then return 0 end

	local count = removeAllIn( self, this )

	self.prf = self.prf + count

	return count
end

e2function void propDeleteAll()
	for ent in pairs( self.data.spawnedProps ) do
		if IsValid( ent ) then
			ent:Remove()
		end
	end
	self.data.spawnedProps = {}
end


__e2setcost(10)

--------------------------------------------------------------------------------
e2function void entity:propManipulate(vector pos, angle rot, number freeze, number gravity, number notsolid)
	if not ValidAction(self, this, "manipulate") then return end
	PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propFreeze(number freeze)
	if not ValidAction(self, this, "freeze") then return end
	PhysManipulate(this, nil, nil, freeze, nil, nil)
end

e2function void entity:propNotSolid(number notsolid)
	if not ValidAction(self, this, "solid") then return end
	PhysManipulate(this, nil, nil, nil, nil, notsolid)
end

--- Makes <this> not render at all
e2function void entity:propDraw(number drawEnable)
	if not ValidAction(self, this, "draw") then return end
	this:SetNoDraw( drawEnable == 0 )
end

--- Makes <this>'s shadow not render at all
e2function void entity:propShadow(number shadowEnable)
	if not ValidAction(self, this, "shadow") then return end
	this:DrawShadow( shadowEnable ~= 0 )
end

e2function void entity:propGravity(number gravity)
	if not ValidAction(self, this, "gravity") then return end
	local physCount = this:GetPhysicsObjectCount()
	if physCount > 1 then
		for physID = 0, physCount - 1 do
			local phys = this:GetPhysicsObjectNum(physID)
			if IsValid(phys) then phys:EnableGravity( gravity ~= 0 ) end
		end
	else
		PhysManipulate(this, nil, nil, nil, gravity, nil)
	end
end

e2function void entity:propDrag( number drag )
	if not PropCore.ValidAction(self, this, "drag") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableDrag( drag ~= 0 )
	end
end

e2function void entity:propInertia( vector inertia )
	if not PropCore.ValidAction(self, this, "inertia") then return end
	if inertia:IsZero() then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetInertia(inertia)
	end
end

e2function void entity:propSetBuoyancy(number buoyancy)
	if not ValidAction(self, this, "buoyancy") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
	end
end

e2function void entity:propSetFriction(number friction)
	if not ValidAction(self, this, "friction") then return end
	this:SetFriction( math.Clamp(friction, -1000, 1000) )
end

e2function number entity:propGetFriction()
	if not ValidAction(self, this, "friction") then return 0 end
	return this:GetFriction()
end

e2function void entity:propSetElasticity(number elasticity)
	if not ValidAction(self, this, "elasticity") then return end
	this:SetElasticity( math.Clamp(elasticity, -1000, 1000) )
end

e2function number entity:propGetElasticity()
	if not ValidAction(self, this, "elasticity") then return 0 end
	return this:GetElasticity()
end

local persistCvar = GetConVar("sbox_persist")
e2function void entity:propMakePersistent(number persistent)
	if not ValidAction(self, this, "persist") then return end
	if not persistCvar:GetBool() then return end
	if not gamemode.Call("CanProperty", self.player, "persist", this) then return end
	this:SetPersistent(persistent ~= 0)
end

e2function void entity:propPhysicalMaterial(string physprop)
	if not ValidAction(self, this, "physprop") then return end
	construct.SetPhysProp(self.player, this, 0, nil, {nil, Material = physprop})
end

e2function string entity:propPhysicalMaterial()
	if not ValidAction(self, this, "physprop") then return "" end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then return phys:GetMaterial() or "" end
	return ""
end

e2function void entity:propSetVelocity(vector velocity)
	if not ValidAction(self, this, "velocitynxt") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocity(velocity)
	end
end

e2function void entity:propSetVelocityInstant(vector velocity)
	if not ValidAction(self, this, "velocityins") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetVelocityInstantaneous(velocity)
	end
end

e2function void entity:propSetAngVelocity(vector velocity)
	if not ValidAction(self, this, "angvel") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetAngleVelocity(velocity)
	end
end

e2function void entity:propSetAngVelocityInstant(vector velocity)
	if not ValidAction(self, this, "angvelinst") then return end
	local phys = this:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetAngleVelocityInstantaneous(velocity)
	end
end

hook.Add( "CanDrive", "checkPropStaticE2", function( ply, ent ) if ent.propStaticE2 ~= nil then return false end end )
e2function void entity:propStatic( number static )
	if not ValidAction( self, this, "static" ) then return end
	if static ~= 0 and this.propStaticE2 == nil then
		local phys = this:GetPhysicsObject()
		this.propStaticE2 = phys:IsMotionEnabled()
		this.PhysgunDisabled = true
		this:SetUnFreezable( true )
		phys:EnableMotion( false )
	elseif this.propStaticE2 ~= nil then
		this.PhysgunDisabled = false
		this:SetUnFreezable( false )
		if this.propStaticE2 == true then
			local phys = this:GetPhysicsObject()
			phys:Wake()
			phys:EnableMotion( true )
		end
		this.propStaticE2 = nil
	end
end

-- Bones --
--------------------------------------------------------------------------------

e2function void bone:boneManipulate(vector pos, angle rot, isFrozen, gravity, collision)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "manipulate", index) then return end

	setPos(this, pos)
	setAng(this, rot)

	this:EnableMotion(isFrozen == 0)
	this:EnableGravity(gravity ~= 0)
	this:EnableCollisions(collision ~= 0)

	ent:PhysWake()
end

e2function void bone:boneFreeze(isFrozen)
	if not boneVerify(self, this) then return end
	this:EnableMotion( isFrozen == 0 )
	this:Wake()
end

__e2setcost(30)

e2function void bone:setCollisions(enable)
	if not boneVerify(self, this) then return end
	this:EnableCollisions(enable ~= 0)
	this:Wake()
end

e2function void bone:setDrag( number drag )
	if not boneVerify(self, this) then return end
	this:EnableDrag( drag ~= 0 )
end

e2function void bone:setInertia( vector inertia )
	if not boneVerify(self, this) then return end
	if inertia:IsZero() then return end
	this:SetInertia(inertia)
end

e2function void bone:setBuoyancy(number buoyancy)
	if not boneVerify(self, this) then return end
	this:SetBuoyancyRatio( math.Clamp(buoyancy, 0, 1) )
end

e2function void bone:setPhysicalMaterial(string material)
	if not boneVerify(self, this) then return end
	if not ValidAction(self, this, "physmat") then return end
	this:SetMaterial(material)
end

e2function void bone:setVelocity(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "velocitynxt", index) then return end
	this:SetVelocity(velocity)
	ent:PhysWake()
end

e2function void bone:setVelocityInstant(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "velocityins", index) then return end
	this:SetVelocityInstantaneous(velocity)
	ent:PhysWake()
end

e2function void bone:setAngVelocity(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "angvelnxt", index) then return end
	this:SetAngleVelocity(velocity)
	ent:PhysWake()
end

e2function void bone:setAngVelocityInstant(vector velocity)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, this, "angvelinst", index) then return end
	this:SetAngleVelocityInstantaneous(velocity)
	ent:PhysWake()
end

__e2setcost(5000)

-- This code was leveraged from Garry's Mod. Perhaps it would be a bit cleaner with a slight rewrite.
e2function void entity:makeStatue(enable)
	if sbox_E2_canMakeStatue:GetInt() == 0 then return end
	if not ValidAction(self, this, "statue") then return end
	if (enable ~= 0) == this:GetNWBool("IsStatue") then return end

	local bones = this:GetPhysicsObjectCount()
	if bones < 2 then return self:throw("You can only makeStatue on ragdolls!", nil) end

	if enable ~= 0 then
		if this.StatueInfo then return end
		local ply = self.player

		this.StatueInfo = {}

		for bone = 1, bones - 1 do
			local constraint = constraint.Weld(this, this, 0, bone, 0)

			if constraint then
				this.StatueInfo[bone] = constraint
				ply:AddCleanup("constraints", constraint)
			end
		end

		this:SetNWBool("IsStatue", true)

	else
		if not this.StatueInfo then return end

		for _, v in ipairs(this.StatueInfo) do

			if IsValid(v) then
				v:Remove()
			end

		end

		this:SetNWBool("IsStatue", false)
		this.StatueInfo = nil

	end
end

--------------------------------------------------------------------------------

__e2setcost(20)
e2function void entity:setPos(vector pos)
	if not ValidAction(self, this, "pos") then return end
	setPos(this, pos)
end

e2function void entity:setLocalPos(vector pos)
	if not ValidAction(self, this, "pos") then return end
	WireLib.setLocalPos(this, pos)
end

[deprecated]
e2function void entity:reposition(vector pos) = e2function void entity:setPos(vector pos)

e2function void entity:setAng(angle rot)
	if not ValidAction(self, this, "ang") then return end
	setAng(this, rot)
end

e2function void entity:setLocalAng(angle rot)
	if not ValidAction(self, this, "ang") then return end
	WireLib.setLocalAng(this, rot)
end

[deprecated]
e2function void entity:rerotate(angle rot) = e2function void entity:setAng(angle rot)

e2function void bone:setPos(vector pos)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "pos", index) then return end
	setPos(this, pos)
	ent:PhysWake()
end

e2function void bone:setAng(angle rot)
	local ent, index = boneVerify(self, this)
	if not ValidAction(self, ent, "ang", index) then return end
	setAng(this, rot)
	ent:PhysWake()
end

__e2setcost(60)

e2function void entity:ragdollFreeze(isFrozen)
	if not ValidAction(self, this, "freeze") then return end

	for _, bone in pairs(GetBones(this)) do
		bone:EnableMotion(isFrozen == 0)
		bone:Wake()
	end


end

__e2setcost(150)

e2function void entity:ragdollSetPos(vector pos)
	if not ValidAction(self, this, "pos") then return end

	for _, bone in pairs(GetBones(this)) do
		setPos(bone, this:WorldToLocal(bone:GetPos()) + pos)
	end

	this:PhysWake()
end

e2function void entity:ragdollSetAng(angle rot)
	if not ValidAction(self, this, "rot") then return end

	for _, bone in pairs(GetBones(this)) do
		setAng(bone, bone:AlignAngles(this:GetForward():Angle(), rot))
	end

	this:PhysWake()
end

e2function table entity:ragdollGetPose()
	if not ValidAction(self, this) then return end
	local pose = E2Lib.newE2Table()
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos(), bones[0]:GetAngles()
	local size = 0

	for k, bone in pairs(bones) do
		local value = E2Lib.newE2Table()
		local pos, ang = WorldToLocal(bone:GetPos(), bone:GetAngles(), originPos, originAng)

		value.n[1] = pos
		value.n[2] = ang
		value.ntypes[1] = "v"
		value.ntypes[2] = "a"
		value.size = 2

		pose.n[k] = value
		pose.ntypes[k] = "t"
		size = size + 1
	end

	pose.stypes._origina = "a"
	pose.s._origina = bones[0]:GetAngles()
	pose.size = size + 1
	return pose
end

e2function void entity:ragdollSetPose(table pose, rotate)
	if not ValidAction(self, this, "pose") then return end
	if pose.size == 0 then return end
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos()
	if rotate ~= 0 then
		originAng = bones[0]:GetAngles()
	else
		local stype = pose.stypes._origina
		originAng = stype and stype == "a" and pose.s._origina or angle_zero
	end

	self.prf = self.prf + pose.size * 2

	for k, v in pairs(pose.n) do
		local pos, ang = LocalToWorld(v.n[1], v.n[2], originPos, originAng)
		setAng(bones[k], ang)
		setPos(bones[k], pos)
	end

	this:PhysWake()

end

e2function void entity:ragdollSetPose(table pose)
	if not ValidAction(self, this, "pose") then return end
	if pose.size == 0 then return end
	local bones = GetBones(this)
	local originPos, originAng = bones[0]:GetPos(), bones[0]:GetAngles() -- Rotate by default.

	self.prf = self.prf + pose.size * 2

	for k, v in pairs(pose.n) do
		local pos, ang = LocalToWorld(v.n[1], v.n[2], originPos, originAng)
		setAng(bones[k], ang)
		setPos(bones[k], pos)
	end

	this:PhysWake()

end


__e2setcost(20)
--------------------------------------------------------------------------------

local function getChildLength(curchild, count)
	local max = 0
	for _, v in pairs(curchild:GetChildren()) do
		max = math.max(max, getChildLength(v, count + 1))
	end
	return math.max(max, count)
end

-- Checks if there is recursive parenting, if so then returns false
-- Also checks if parent/child chain length is > 16, and if so, hard errors.
local function parent_check( self, child, parent )
	local parents = 0
	while parent:IsValid() do
		parents = parents + 1
		parent = parent:GetParent()
	end

	return ( parents + getChildLength(child, 1) ) <= 16
end

local function parent_antispam( child )
	if (child.E2_propcore_antispam or 0) > CurTime() then
		return false
	end

	child.E2_propcore_antispam = CurTime() + 0.06
	return true
end

e2function void entity:parentTo(entity target)
	if not ValidAction(self, this, "parent") then return self:throw("You do not have permission to parent to this prop!", nil) end
	if not IsValid(target) then return self:throw("Target prop is invalid.", nil) end
	if not isOwner(self, target) then return self:throw("You do not own the target prop!", nil) end
	if not parent_antispam( this ) then return self:throw("You are parenting too fast!", nil) end
	if this == target then return self:throw("You cannot parent a prop to itself") end
	if not parent_check( self, this, target ) then return self:throw("Parenting chain of entities can't exceed 16 or crash may occur", nil) end

	this:SetParent(target)
end

__e2setcost(5)
e2function void entity:deparent()
	if not ValidAction(self, this, "deparent") then return end
	this:SetParent( nil )
end
e2function void entity:parentTo() = e2function void entity:deparent()

__e2setcost(1)

e2function void propSpawnEffect(number on)
	self.data.propSpawnEffect = on ~= 0
end

e2function void propSpawnUndo(number on)
	self.data.propSpawnUndo = on ~= 0
end

e2function number propCanCreate()
	if WithinPropcoreLimits() then return 1 end
	return 0
end

-- Flexes --
--------------------------------------------------------------------------------

-- Setters

__e2setcost(10)

e2function void entity:setEyeTarget(vector pos)
	if not ValidAction(self, this, "eyetarget") then return end
	this:SetEyeTarget(pos)
end

e2function void entity:setFlexWeight(number flex, number weight)
	if not ValidAction(self, this, "flexweight" .. flex) then return end
	this:SetFlexWeight(flex, weight)
end

__e2setcost(30)

e2function void entity:setEyeTargetLocal(vector pos)
	if not ValidAction(self, this, "eyetarget") then return end
	if not this:IsRagdoll() then
		local attachment = this:GetAttachment(this:LookupAttachment("eyes"))
		if attachment then
			pos = LocalToWorld(pos, angle_zero, attachment.Pos, attachment.Ang)
		end
	end
	this:SetEyeTarget(pos)
end

e2function void entity:setEyeTargetWorld(vector pos)
	if not ValidAction(self, this, "eyetarget") then return end
	if this:IsRagdoll() then
		local attachment = this:GetAttachment(this:LookupAttachment("eyes"))
		if attachment then
			pos = WorldToLocal(pos, angle_zero, attachment.Pos, attachment.Ang)
		end
	end
	this:SetEyeTarget(pos)
end

__e2setcost(20)

e2function void entity:setFlexWeight(string flex, number weight)
	flex = this:GetFlexIDByName(flex)
	if flex then
		if not ValidAction(self, this, "flexweight" .. flex) then return end
		this:SetFlexWeight(flex, weight)
	end
end

e2function void entity:setFlexScale(number scale)
	if not ValidAction(self, this, "flexscale") then return end
	this:SetFlexScale(scale)
end

registerCallback("construct",
	function(self)
		self.data.propSpawnEffect = true
		self.data.propSpawnUndo = true
		self.data.spawnedProps = {}
	end
)

registerCallback("destruct",
	function(self)
		for ent, undo in pairs( self.data.spawnedProps ) do
			if undo == false and IsValid( ent ) then
				ent:Remove()
			end
		end
	end
)
