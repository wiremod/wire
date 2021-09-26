local NoRestriction = CreateConVar( "wire_expression2_entmanipulation_norestriction", 0, FCVAR_ARCHIVE )

E2Lib.RegisterExtension("entmanipulate", true, "Allows spawning of entities, changing their keyvalues, datadesc, calling their inputs",
	"It is possible to crash server or client, create NPCs with extremely fast regeneration, to put smoke on players and to abuse Source and custom entities in other ways")


local function IsAllowed( self, ply, ent )
	if !IsValid( ent ) then 
		return false
	end

	if ent:IsPlayer() then 
		ply:ChatPrint( "Entity:entFire() or Entity:entKVSet() error: Players can not be manipulated.", 2 ) 
		return false
	end
	
	if !(ply:IsAdmin() or NoRestriction:GetBool() or isOwner(self, ent) or ent:MapCreationID() ~= -1) then 
		ply:ChatPrint( "Entity:entFire() or Entity:entKVSet() error: You are only allowed to manipulate your own or map-created entities." ) 
		return false
	end
	
	return true
end

local E2_TABLE_DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

local function TableToE2Table(input)
	local ret = table.Copy(E2_TABLE_DEFAULT)
	local size = 0
	for k,v in pairs( input ) do
		if isbool(v) then 
			ret.s[k] = v and 1 or 0
			ret.stypes[k] = "n"
		elseif isnumber(v) then
			ret.s[k] = v
			ret.stypes[k] = "n"
		elseif isstring(v) then
			ret.s[k] = v
			ret.stypes[k] = "s"
		elseif IsEntity(v) then
			ret.s[k] = v
			ret.stypes[k] = "e"
		elseif isvector(v) then
			ret.s[k] = v
			ret.stypes[k] = "v"
		elseif isangle(v) then
			ret.s[k] = v
			ret.stypes[k] = "a"
		elseif istable(v) then
			ret.s[k] = TableToE2Table(v)
			ret.stypes[k] = "t"
		else
			print("Ignored (you should not see this):", k, v)
			continue
		end

		size = size + 1
	end
	ret.size = size
	return ret
end

local function Entity_Fire( self, ent, input, param, activator )
    if not IsAllowed( self, self.player, ent ) then
		return 
	end

	if ent:MapCreationID() ~= -1 and (input == "Kill" or input == "KillHierarchy") then
		return -- Disallow killing (removing) map entities
	end

	if input == "AddOutput" then
		return
	end

	ent:Fire( input, param, 0, activator )
end

local function Entity_SetKeyValue( self, ent, key, value )
    if IsAllowed( self, self.player, ent ) then
		ent:SetKeyValue( key, value )
	end
end

local function Entity_SetDatadescValue(self, ent, key, value)
	if IsAllowed( self, self.player, ent ) then
		if not ent:SetSaveValue( key, value ) then
			self.player:ChatPrint( "Entity:entDatadescSet(): error setting "..tostring(key).." to "..tostring(value) ) 
		end
	end
end

__e2setcost(5)

e2function void entity:entFire( string input, string param )
	Entity_Fire( self, this, input, param )
end

e2function void entity:entFire( string input, number param )
	Entity_Fire( self, this, input, param )
end

e2function void entity:entFire( string input )
	Entity_Fire( self, this, input )
end

e2function void entity:entFire( entity activator, string input, string param )
	Entity_Fire( self, this, input, param, activator )
end

e2function void entity:entFire( entity activator, string input, number param )
	Entity_Fire( self, this, input, param, activator )
end

e2function void entity:entFire( entity activator, string input )
	Entity_Fire( self, this, input, nil, activator )
end

e2function void entity:entKVSet( string key, number value )
	Entity_SetKeyValue( self, this, key, value )
end

e2function void entity:entKVSet( string key, string value )
	Entity_SetKeyValue( self, this, key, value )
end

e2function void entity:entDatadescSetBoolean( string key, number value )
	Entity_SetDatadescValue( self, this, key, tobool(value) )
end

e2function void entity:entDatadescSet( string key, number value )
	Entity_SetDatadescValue( self, this, key, value )
end

e2function void entity:entDatadescSet( string key, string value )
	Entity_SetDatadescValue( self, this, key, value )
end

e2function void entity:entDatadescSet( string key, vector value )
	Entity_SetDatadescValue( self, this, key, Vector(value[0], value[1], value[2]) )
end

e2function void entity:entDatadescSet( string key, angle value )
	Entity_SetDatadescValue( self, this, key, Angle(value[0], value[1], value[2]) )
end

e2function void entity:entDatadescSet( string key, entity value )
	Entity_SetDatadescValue( self, this, key, value )
end

e2function string entity:entGetNameOrAssignRandom()
	if not IsValid(this) or 
		this:IsPlayer() or  -- Player entity has overriden GetName()
		not IsAllowed(self, self.player, this) 
	then
		return ""	
	end

	local name = this:GetName()

	if name ~= "" then -- Has some name
		return name
	end

	name = "e2_name_"..this:GetClass().."_"..tostring(this:GetCreationID())
	this:SetName(name)

	return name
end

__e2setcost(2)

e2function table entity:entKVsGet()
	if not IsValid(this) then
		return table.Copy(E2_TABLE_DEFAULT)
	end

	return TableToE2Table(this:GetKeyValues())
end

e2function table entity:entDatadescGetTable()
	if not IsValid(this) then
		return table.Copy(E2_TABLE_DEFAULT)
	end

	return TableToE2Table(this:GetSaveTable(true))
end

__e2setcost(1)

e2function string entity:entGetName()
	if IsValid( this ) and this:IsPlayer() then
		return this:GetName()
	end
end

e2function number entity:entGetMapID()
	if IsValid( this ) then
		return this:MapCreationID()
	end
end


e2function entity entityMapID( number id )
	local ent = ents.GetMapCreatedEntity( id )
	if IsValid( ent ) then
		return ent
	end
end

-------------------------------------------
-- Entity spawn

local SpawnFilter = {}	
local SpawnFilterCache = {}

local function LoadSpawnFilter()
	print("Loading spawn filter...")

	local filePath = "stpm64_e2/spawn_filter.txt"
	local _file = file.Open(filePath, "r", "DATA")

	if _file == nil then
		print("Error opening", filePath, "in DATA search path")
		return 
	end

	local rules = {}

	while not _file:EndOfFile() do
		local thisLine = _file:ReadLine():TrimRight("\n"):TrimRight("\r")


		if thisLine[1] == '+' then
			rules[#rules + 1] = { 
				Allow = true,
				Regexp = string.sub(thisLine, 3) -- Skip + and space
			}
		elseif thisLine[1] == '-' then
			rules[#rules + 1] = { 
				Allow = false,
				Regexp = string.sub(thisLine, 3) -- Skip - and space
			}
		else
			print("Invalid line:", thisLine)
		end
	end

	SpawnFilterCache = {}
	SpawnFilter = rules

	print("Done loading spawn filter")
end

hook.Add("Initialize", "stpM64_E2Entity_Initialize", LoadSpawnFilter)

concommand.Add("wire_expression2_entmanipulation_reload_spawn_filter", LoadSpawnFilter, nil, 
	"Reloads entSpawnEx class black-/whitelist file (data/stpm64_e2/spawn_filter.txt)")


local function IsAllowedToSpawn(class)
	if SpawnFilterCache[class] ~= nil then
		return SpawnFilterCache[class]
	end

	local isAllowed = false

	for i, rule in ipairs(SpawnFilter) do
		if string.match(class, rule.Regexp) then
			isAllowed = rule.Allow
		end
	end

	SpawnFilterCache[class] = isAllowed

	return isAllowed
end

__e2setcost(30)

local function Spawn_Sent(ply, class, pos, ang, kvs)
	if not IsAllowedToSpawn(class) and not ply:IsAdmin() then
		ply:ChatPrint( "Spawning \""..class.."\" is disallowed" )
		return nil
	end

	if not gamemode.Call("PlayerSpawnSENT", ply, class) then 
		return nil 
	end

	local ent = ents.Create(class)

	if not IsValid(ent) then
		ply:ChatPrint( "Spawning \""..class.."\" failed (invalid class? entity limit?)" )
		return nil
	end

	ent:SetPos(pos)
	ent:SetAngles(ang)

	if kvs then
		for k, v in pairs(kvs.s) do
			if isnumber(v) or isstring(v) then
				ent:SetKeyValue(k, v)
			else
				ply:ChatPrint( "Entity:entSpawnExKVs(): skipping keyvalue "..tostring(k).." = "..tostring(v).." : type is"..type(v) )
			end
		end
	end

	ent:Spawn()
	ent:Activate()

	if not IsValid(ent) then
		return nil
	end

	gamemode.Call("PlayerSpawnedSENT", ply, ent)

	undo.Create("SENT")
		undo.SetPlayer(ply)
		undo.AddEntity(ent)
		undo.SetCustomUndoText("Undone Expression2-created " .. class)
	undo.Finish("Expression2-created scripted Entity (" .. class .. ")")

	ply:AddCleanup("sents", ent)
	
	ent.Player = ply
		
	return ent
end

e2function entity entSpawnEx(string class, vector pos, angle ang)
	return Spawn_Sent(self.player, class, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]))
end

e2function entity entSpawnEx(string class, vector pos)
	return Spawn_Sent(self.player, class, Vector(pos[1],pos[2],pos[3]), Angle(0,0,0))
end

e2function entity entSpawnEx(string class)
	return Spawn_Sent(self.player, class, self.entity:GetPos(), Angle(0,0,0))
end

e2function entity entSpawnExKVs(string class, vector pos, angle ang, table kvs)
return Spawn_Sent(self.player, class, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]), kvs)
end

-------------------------------------------
-- Output hooking

local OutputHookerEntity
local OutputHookerListeners = {}

local function CreateOutputHooker()
	if IsValid(OutputHookerEntity) then 
		OutputHookerEntity:Remove()
	end

	OutputHookerEntity = ents.Create("stpm64_e2_output_hooker")
	OutputHookerEntity:SetName("__stpm64_e2_output_hooker")
	OutputHookerEntity:Spawn()
end


hook.Add("InitPostEntity", "stpM64_E2_Entmanipulation", CreateOutputHooker)
hook.Add("PostCleanupMap", "stpM64_E2_Entmanipulation", CreateOutputHooker)

concommand.Add("wire_expression2_entmanipulation_recreate_output_hooker", CreateOutputHooker)

__e2setcost(50)

e2function void runOnEntityOutput(entity ent, string output)
	if not IsAllowed( self, self.player, ent ) then
		return 
	end

	if not string.match(output, "^[%w_]+$") then 
		-- Output name must be spaceless word of only letters, digits and underscopes
		-- To prevent injections in AddOutput
		return
	end

	local listenerName = tostring(ent:GetCreationID()).."$"..output
	local listener = OutputHookerListeners[self.entity] or {}

	if listener[listenerName] == true then
		return
	end

	local addOutputParam = output.." __stpm64_e2_output_hooker:HookOutput_"..output.."::0:-1"

	ent:Fire("AddOutput", addOutputParam)

	listener[listenerName] = true

	OutputHookerListeners[self.entity] = listener
end

hook.Add("stpM64_E2_OutputHook", "stpM64_E2_OutputHook_Handler", function(activator, caller, output, param)
	param = param or ""

	local context = {
		Activator = activator,
		Caller = caller,
		Output = output,
		Param = param or ""
	}

	local listenerName = tostring(caller:GetCreationID()).."$"..output

	for e2, listens_to in pairs(OutputHookerListeners) do
		if IsValid(e2) and listens_to[listenerName] == true then
			e2.context.data.outputHookContext = context
			e2:Execute()
			e2.context.data.outputHookContext = nil
		end
	end
end)

__e2setcost(5)

e2function number entityOutputClk()
	return self.data.outputHookContext ~= nil and 1 or 0
end

e2function entity entityOutputClkActivator()
	local context = self.data.outputHookContext

	if context then return context.Activator end
end


e2function entity entityOutputClkEntity()
	local context = self.data.outputHookContext

	if context then return context.Caller end
end


e2function string entityOutputClkOutput()
	local context = self.data.outputHookContext

	if context then return context.Output end
end

e2function string entityOutputClkParam()
	local context = self.data.outputHookContext

	if context then return context.Param end
end