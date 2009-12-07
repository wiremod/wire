E2Lib.RegisterExtension("holo", true)

if not datastream then require( "datastream" ) end

CreateConVar("wire_holograms_max","50")
local wire_holograms_size_max = CreateConVar("wire_holograms_size_max","50")

-- context = chip.context = self
-- Holo = { ent = prop, scale = scale, e2owner = context }
-- E2HoloRepo[player][-index] = Holo <-- global holos
-- E2HoloRepo[player][Holo] = Holo <-- local holos
-- context.data.holos[index] = Holo <-- local holos
local E2HoloRepo = {}
local PlayerAmount = {}
local BlockList = {}
local ModelList = {
	["cone"] = true,
	["cube"] = true,
	["dome"] = true,
	["dome2"] = true,
	["cylinder"] = true,
	["hqcone"] = true,
	["hqcylinder"] = true,
	["hqcylinder2"] = true,
	["hqicosphere"] = true,
	["hqicosphere2"] = true,
	["hqsphere"] = true,
	["hqsphere2"] = true,
	["hqtorus"] = true,
	["hqtorus2"] = true,
	["icosphere"] = true,
	["icosphere2"] = true,
	["icosphere3"] = true,
	["prism"] = true,
	["pyramid"] = true,
	["plane"] = true,
	["sphere"] = true,
	["sphere2"] = true,
	["sphere3"] = true,
	["tetra"] = true,
	["torus"] = true,
	["torus2"] = true,
	["torus3"] = true
}
if resource.AddSingleFile then
	for k,_ in pairs(ModelList) do
		util.PrecacheModel( "models/Holograms/"..k..".mdl" )
		resource.AddSingleFile( "models/Holograms/"..k..".mdl" )
	end
elseif not wire_expression2_is_reload and not SinglePlayer() then
	-- TODO: delete this branch once resource.AddSingleFile is present in the regular gmod version.
	print("Ignore the following bunch of error messages:")
	for k,_ in pairs(ModelList) do
		util.PrecacheModel( "models/Holograms/"..k..".mdl" )
		resource.AddFile( "models/Holograms/"..k..".mdl" )
	end
	print("Ignore the preceding bunch of error messages.")
end

/******************************************************************************/

local function ConsoleMessage(ply, text)
	if ply:IsValid() then
		ply:PrintMessage( HUD_PRINTCONSOLE, text )
	else
		print(text)
	end
end

concommand.Add( "wire_holograms_remove_all", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	for pl,rep in pairs( E2HoloRepo ) do
		for k,Holo in pairs( rep ) do
			if Holo and validEntity(Holo.ent) then
				Holo.ent:Remove()
				PlayerAmount[pl] = PlayerAmount[pl] - 1
			end
		end
	end

end )

concommand.Add( "wire_holograms_block", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	if not args[1] then
		ConsoleMessage( ply, "Command requires a player's name (or part of their name)" )
		ConsoleMessage( ply, "Usage: wire_holograms_block [name]" )
		return
	end

	local name = args[1]:lower()
	local players = E2Lib.filterList(player.GetAll(), function(ent) return ent:GetName():lower():match(name) end)

	if #players == 1 then
		local v = players[1]
		if BlockList[v:SteamID()] == true then
			ConsoleMessage( ply, v:GetName() .. " is already in the holograms blocklist!" )
		else
			if E2HoloRepo[v] then
				for k2,v2 in pairs( E2HoloRepo[v] ) do
					if v2 and validEntity(v2.ent) then
						v2.ent:Remove()
						PlayerAmount[v] = PlayerAmount[v] - 1
					end
				end
			end
			BlockList[v:SteamID()] = true
			for _,p in ipairs( player.GetAll() ) do
				p:PrintMessage( HUD_PRINTTALK, "(ADMIN) " .. v:GetName() .. " added to holograms blocklist" )
			end
		end
	elseif #players > 1 then
		ConsoleMessage( ply, "More than one player matches that name!" )
	else
		ConsoleMessage( ply, "No player names found with " .. args[1] )
	end
end )

concommand.Add( "wire_holograms_unblock", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	if not args[1] then
		ConsoleMessage( ply, "Command requires a player's name (or part of their name)" )
		ConsoleMessage( ply, "Usage: wire_holograms_unblock [name]" )
		return
	end

	local name = args[1]:lower()
	local players = E2Lib.filterList(player.GetAll(), function(ent) return ent:GetName():lower():match(name) end)

	if #players == 1 then
		local v = players[1]
		if BlockList[v:SteamID()] == true then
			BlockList[v:SteamID()] = nil
			for _,player in ipairs( player.GetAll() ) do
				player:PrintMessage( HUD_PRINTTALK, "(ADMIN) " .. v:GetName() .. " removed from holograms blocklist" )
			end
		else
			ConsoleMessage( ply, v:GetName() .. " is not in the holograms blocklist!" )
		end
	elseif #players > 1 then
		ConsoleMessage( ply, "More than one player matches that name!" )
	else
		ConsoleMessage( ply, "No player names found with " .. args[1] )
	end
end )

concommand.Add( "wire_holograms_block_id", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	local steamID = table.concat(args)

	if not steamID:match("STEAM_[0-9]:[0-9]:[0-9]+") then
		ConsoleMessage( ply, "Invalid SteamID format" )
		ConsoleMessage( ply, "Usage: wire_holograms_block_id STEAM_X:X:XXXXXX" )
		return
	end

	if BlockList[steamID] == true then
		ConsoleMessage( ply, steamID .. " is already in the holograms blocklist!" )
	else
		BlockList[steamID] = true
		for _,player in ipairs( player.GetAll() ) do
			player:PrintMessage( HUD_PRINTTALK, "(ADMIN) " .. steamID .. " added to holograms blocklist" )
		end
		for _,v in pairs( player.GetAll() ) do
			if v:SteamID() == steamID and E2HoloRepo[v] then
				for k2,v2 in pairs( E2HoloRepo[v] ) do
					if v2 and validEntity(v2.ent) then
						v2.ent:Remove()
						PlayerAmount[v] = PlayerAmount[v] - 1
					end
				end
				return
			end
		end
	end
end )

concommand.Add( "wire_holograms_unblock_id", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	local steamID = table.concat(args)

	if not steamID:match("STEAM_[0-9]:[0-9]:[0-9]+") then
		ConsoleMessage( ply, "Invalid SteamID format" )
		ConsoleMessage( ply, "Usage: wire_holograms_unblock_id STEAM_X:X:XXXXXX" )
		return
	end

	if BlockList[steamID] == true then
		BlockList[steamID] = nil
		for _,player in ipairs( player.GetAll() ) do
			player:PrintMessage( HUD_PRINTTALK, "(ADMIN) " .. steamID .. " removed from holograms blocklist" )
		end
	else
		ConsoleMessage( ply, steamID .. " is not in the holograms blocklist!" )
	end
end )

/******************************************************************************/

local scale_queue = {}
local clip_queue = {}

-- If no recipient is given, the umsg is sent to everyone (umsg.Start does that)
local function flush_scale_queue(queue, recipient)
	if not queue then queue = scale_queue end
	if #queue == 0 then return end

	local bytes = 4 -- Header(2)+Short(2)
	umsg.Start("wire_holograms_set_scale", recipient)
		for _,Holo,scale in ipairs_map(queue, unpack) do
			bytes = bytes + 14 -- Vector(12)+Short(2)
			if bytes > 255 then
				umsg.Short(0) -- terminate list
				umsg.End() -- end message
				umsg.Start("wire_holograms_set_scale", recipient) -- make a new one
				bytes = 4+14 -- Header(2)+Short(2)+Vector(12)+Short(2)
			end
			umsg.Short(Holo.ent:EntIndex())
			umsg.Vector(scale)
		end
		umsg.Short(0)
	umsg.End()
end

local function flush_clip_queue(queue, recipient)
	if !queue then queue = clip_queue end
	if #queue == 0 then return end

	local bytes = 4
	umsg.Start("wire_holograms_clip", recipient)
		for _,Holo,clip in ipairs_map(queue, unpack) do
			bytes = bytes + 2

			if bytes > 255 then
				umsg.Short(0)
				umsg.End()
				umsg.Start("wire_holograms_clip", recipient)

				bytes = 6
			end

			umsg.Short(Holo.ent:EntIndex())

			if clip and clip.enabled != nil then
				bytes = bytes + 2

				umsg.Bool(true)
				umsg.Bool(clip.enabled)
			elseif clip and clip.origin and clip.normal and clip.isglobal then
				bytes = bytes + 27

				umsg.Bool(false)
				umsg.Vector(clip.origin)
				umsg.Vector(clip.normal)
				umsg.Short(clip.isglobal)
			end
		end
		umsg.Short(0) //stop list
	umsg.End()
end

registerCallback("postexecute", function(self)
	flush_scale_queue()
	flush_clip_queue()
	scale_queue = {}
	clip_queue = {}
end)

local function rescale(Holo, scale)
	local maxval = wire_holograms_size_max:GetInt()
	local minval = -maxval

	x = math.Clamp( scale[1], minval, maxval )
	y = math.Clamp( scale[2], minval, maxval )
	z = math.Clamp( scale[3], minval, maxval )

	local scale = Vector(x, y, z)
	if Holo.scale ~= scale then
		table.insert(scale_queue, { Holo, scale })
		Holo.scale = scale
	end
end

local function enable_clip(Holo, enabled)
	Holo.clip = Holo.clip or {}
	local clip = Holo.clip

	if clip.enabled != enabled then
		clip.enabled = enabled

		table.insert(clip_queue, {
			Holo,
			{
				enabled = enabled
			}
		} )
	end
end

local function set_clip(Holo, origin, normal, isglobal)
	Holo.clip = Holo.clip or {}
	local clip = Holo.clip

	if clip.origin != origin or clip.normal != normal or clip.isglobal != isglobal then
		clip.origin = origin
		clip.normal = normal
		clip.isglobal = isglobal

		table.insert(clip_queue, {
			Holo,
			{
				origin = origin,
				normal = normal,
				isglobal = isglobal
			}
		} )
	end
end

hook.Add( "PlayerInitialSpawn", "wire_holograms_set_vars", function(ply)
	local queue = {}
	local c_queue = {}

	for pl,rep in pairs( E2HoloRepo ) do
		for k,Holo in pairs( rep ) do
			if Holo and validEntity(Holo.ent) then
				table.insert(queue, { Holo, Holo.scale })

				local clip = Holo.clip

				if clip and clip.enabled != nil then
					table.insert(c_queue, {
						Holo,
						{
							enabled = clip.enabled
						}
					} )
				end

				if clip and clip.origin and clip.normal and clip.isglobal then
					table.insert(c_queue, {
						Holo,
						{
							origin = origin,
							normal = normal,
							isglobal = isglobal
						}
					} )
				end
			end
		end
	end

	flush_scale_queue(queue, ply)
	flush_clip_queue(c_queue, ply)
end)

/******************************************************************************/

local function MakeHolo(Player, Pos, Ang, model)
	local prop = ents.Create( "gmod_wire_hologram" )
	prop:SetPos(Pos)
	prop:SetAngles(Ang)
	prop:SetModel(model)
	prop:SetPlayer(Player)
	prop:SetNetworkedInt("ownerid", Player:UserID())
	return prop
end

-- Returns the hologram with the given index or nil if it doesn't exist.
local function CheckIndex(self, index)
	index = index - index % 1
	local Holo
	if index<0 then
		Holo = E2HoloRepo[self.player][-index]
	else
		Holo = self.data.holos[index]
	end
	if not Holo or not validEntity(Holo.ent) then return nil end
	return Holo
end

-- Sets the given index to the given hologram.
local function SetIndex(self, index, Holo)
	index = index - index % 1
	local rep = E2HoloRepo[self.player]
	if index<0 then
		rep[-index] = Holo
	else
		local holos = self.data.holos
		if holos[index] then rep[holos[index]] = nil end
		holos[index] = Holo
		if Holo then rep[Holo] = Holo end
	end
end

local function CreateHolo(self, index, pos, scale, ang, color, model)
	if not pos   then pos   = self.entity:GetPos() end
	if not scale then scale = Vector(1,1,1) end
	if not ang   then ang   = self.entity:GetAngles() end
	if not model or not ModelList[model] then model = "cube" end

	local Holo = CheckIndex(self, index)
	if not Holo then
		Holo = {}
		SetIndex(self, index, Holo)
	end

	model = "models/Holograms/"..model..".mdl"

	local prop

	if validEntity(Holo.ent) then
		prop = Holo.ent
		prop:SetPos( pos )
		prop:SetAngles( ang )
		prop:SetModel( model )
	else
		prop = MakeHolo(self.player, pos, ang, model, {}, {})
		prop:Activate()
		prop:Spawn()
		prop:SetSolid(SOLID_NONE)
		prop:SetMoveType(MOVETYPE_NONE)
		PlayerAmount[self.player] = PlayerAmount[self.player]+1
		Holo.ent = prop
		Holo.e2owner = self
	end

	if not validEntity(prop) then return nil end
	if color then prop:SetColor(color[1],color[2],color[3],255) end

	rescale(Holo, scale)

	return prop
end

/******************************************************************************/

local function CheckSpawnTimer( self )
	local holo = self.data.holo
	if CurTime() >= holo.nextSpawn then
		holo.nextSpawn = CurTime()+1
		if CurTime() >= holo.nextBurst then
			holo.remainingSpawns = 30
		elseif holo.remainingSpawns < 10 then
			holo.remainingSpawns = 10
		end
	end

	holo.nextBurst = CurTime()+10

	if holo.remainingSpawns > 0 then
		holo.remainingSpawns = holo.remainingSpawns - 1
		return true
	else
		return false
	end
end

-- Removes the hologram with the given index from the given chip.
local function removeholo(self, index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	if validEntity(Holo.ent) then
		Holo.ent:Remove()
	end
	PlayerAmount[self.player] = PlayerAmount[self.player] - 1
	SetIndex(self, index, nil)
end

-- Removes all holograms from the given chip.
local function clearholos(self)
	-- delete local holos
	for index,Holo in pairs(self.data.holos) do
		removeholo(self, index)
	end

	-- delete global holos owned by this chip
	local rep = E2HoloRepo[self.player]
	if not rep then return end
	for index,Holo in ipairs(rep) do
		if Holo.e2owner == self then
			removeholo(self, -index)
		end
	end
end

/******************************************************************************/

__e2setcost(20) -- temporary

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color, string model)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color, model)
	if validEntity(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color)
	if validEntity(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang)
	if validEntity(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position, scale)
	if validEntity(ret) then return ret end
end

e2function entity holoCreate(index, vector position)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position)
	if validEntity(ret) then return ret end
end

e2function entity holoCreate(index)
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.player] >= GetConVar("wire_holograms_max"):GetInt() then return end

	local ret = CreateHolo(self, index)
	if validEntity(ret) then return ret end
end

e2function void holoDelete(index)
	removeholo(self, index)
end

e2function void holoDeleteAll()
	clearholos(self)
end

e2function void holoReset(index, string model, vector scale, vector color, string color)
	if !ModelList[model] then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetModel(Model("models/Holograms/"..model..".mdl"))
	Holo.ent:SetColor(color[1],color[2],color[3],255)
	Holo.ent:SetMaterial(color)

	rescale(Holo, scale)
end

__e2setcost(5)

e2function number holoCanCreate()
	if CheckSpawnTimer(self) and PlayerAmount[self.player] < GetConVar("wire_holograms_max"):GetInt() then
		return 1
	end

	return 0
end

e2function number holoRemainingSpawns()
	return self.data.holo.remainingSpawns
end

/******************************************************************************/

__e2setcost(5) -- temporary

e2function void holoScale(index, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	rescale(Holo, scale)
end

e2function vector holoScale(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.scale or Vector(0,0,0)
end

e2function void holoScaleUnits(index, vector size)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local propsize = Holo.ent:OBBMaxs() - Holo.ent:OBBMins()
	x = size[1] / propsize.x
	y = size[2] / propsize.y
	z = size[3] / propsize.z

	rescale(Holo, Vector(x, y, z))
end

e2function vector holoScaleUnits(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local scale = Holo.scale
	local propsize = Holo.ent:OBBMaxs() - Holo.ent:OBBMins()

	return Vector(scale[1] * propsize.x, scale[2] * propsize.y, scale[3] * propsize.z)
end

e2function void holoClipEnabled(index, enabled)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if enabled == 1 then
		enable_clip(Holo, true)
	elseif enabled == 0 then
		enable_clip(Holo, false)
	end
end

e2function void holoClip(index, vector origin, vector normal, isglobal)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), isglobal)
end

e2function void holoPos(index, vector position)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetPos(Vector(position[1],position[2],position[3]))
end

e2function void holoAng(index, angle ang)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetAngles(Angle(ang[1],ang[2],ang[3]))
end

/******************************************************************************/

e2function void holoColor(index, vector color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local _,_,_,alpha = Holo.ent:GetColor()
	Holo.ent:SetColor(color[1],color[2],color[3],alpha)
end

e2function void holoColor(index, vector4 color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetColor(color[1],color[2],color[3],color[4])
end

e2function void holoColor(index, vector color, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetColor(color[1],color[2],color[3],alpha)
end

e2function void holoAlpha(index, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local r,g,b = Holo.ent:GetColor()
	Holo.ent:SetColor(r,g,b,alpha)
end

e2function void holoShadow(index, has_shadow)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:DrawShadow( has_shadow ~= 0 )
end

/******************************************************************************/

e2function void holoModel(index, string model)
	if !ModelList[model] then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetModel(Model("models/Holograms/"..model..".mdl"))
end

e2function void holoModel(index, string model, skin)
	if !ModelList[model] then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	skin = skin - skin % 1
	Holo.ent:SetModel(Model("models/Holograms/"..model..".mdl"))
	Holo.ent:SetSkin(skin)
end

e2function void holoSkin(index, skin)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	skin = skin - skin % 1
	Holo.ent:SetSkin(skin)
end

e2function void holoMaterial(index, string material)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetMaterial(material)
end

e2function void holoRenderFX(index, effect)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	effect = effect - effect % 1
	Holo.ent:SetKeyValue("renderfx",effect)
end

/******************************************************************************/

e2function void holoParent(index, otherindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local Holo2 = CheckIndex(self, otherindex)
	if not Holo2 then return end

	Holo.ent:SetParent( Holo2.ent )
end

e2function void holoParent(index, entity ent)
	if not validEntity(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetParent(ent)
	Holo.ent:SetParentPhysNum(0)
end

e2function void holoParent(index, bone b)
	local ent, boneindex = E2Lib.isValidBone2(b)
	if not ent then return end

	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetParent(ent)
	Holo.ent:SetParentPhysNum(boneindex)
end

e2function void holoParentAttachment(index, entity ent, string attachmentName)
	if not validEntity(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetParent(ent)
	Holo.ent:Fire("SetParentAttachmentMaintainOffset", attachmentName, 0.01)
end

e2function void holoUnparent(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetParent(nil)
	Holo.ent:SetParentPhysNum(0)
end

/******************************************************************************/

e2function entity holoEntity(index)
	local Holo = CheckIndex(self, index)
	if Holo and validEntity(Holo.ent) then return Holo.ent end
end

__e2setcost(30)
--- Gets the hologram index of the given entity, if any. Returns 0 on failure.
e2function number holoIndex(entity ent)
	if not validEntity(ent) then return 0 end
	if ent:GetClass() ~= "gmod_wire_hologram" then return 0 end

	-- check local holos
	for k,Holo in pairs(self.data.holos) do
		if(ent == Holo.ent) then return k end
	end

	-- check global holos
	for k,Holo in pairs(E2HoloRepo[self.player]) do
		if type(k) == number and ent == Holo.ent then return -k end
	end
	return 0
end

/******************************************************************************/

registerCallback("construct", function(self)
	if not E2HoloRepo[self.player] then
		E2HoloRepo[self.player] = {}
		PlayerAmount[self.player] = 0
	end
	--self.data.HoloEffect = false
	self.data.holos = {}
	self.data.holo = {
		nextSpawn = CurTime()+1,
		nextBurst = CurTime()+10,
		remainingSpawns = 30
	}
end)

registerCallback("destruct", function(self)
	if not self or not validEntity(self.entity) then return end -- TODO: evaluate necessity

	clearholos(self)
end)

/******************************************************************************/

local DisplayOwners = {}
concommand.Add( "wire_holograms_display_owners", function( ply, com, args )
	if not ply:IsValid() then return end

	if !DisplayOwners[ply] then
		DisplayOwners[ply] = {}
		DisplayOwners[ply].bool = false
	end

	if DisplayOwners[ply].bool == false then
		timer.Create( "wire_holograms_update_owners"..ply:EntIndex(), 0.5, 0, function(ply)
			local tbl = {}
			for _,owner in ipairs( player.GetAll() ) do
				if owner and owner:IsValid() and owner:IsPlayer() and E2HoloRepo[owner] then
					for _,Holo in pairs( E2HoloRepo[owner] ) do
						if Holo and type( Holo ) == "table" and Holo.ent and Holo.ent:IsValid() then
							if !DisplayOwners[ply][Holo.ent] then
								DisplayOwners[ply][Holo.ent] = true
								table.insert( tbl, { owner = owner, hologram = Holo.ent } )
							end
						end
					end
				end
			end
			if #tbl > 0 then
				datastream.StreamToClients( ply, "wire_holograms_owners", { tbl } )
			end
		end, ply )
		DisplayOwners[ply].bool = true
	else
		if timer.IsTimer( "wire_holograms_update_owners"..ply:EntIndex() ) then -- TODO: is this check necessary?
			timer.Remove( "wire_holograms_update_owners"..ply:EntIndex() )
		end
		ply:SendLua( "wire_holograms_remove_owners_display()")
		DisplayOwners[ply] = {}
		DisplayOwners[ply].bool = false
	end

end )

__e2setcost(nil) -- temporary
