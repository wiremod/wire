E2Lib.RegisterExtension( "holo", true, "Allows E2 to create and manipulate non-solid models." )

-- -----------------------------------------------------------------------------

local function checkOwner(self)
	return IsValid(self.player)
end

-- -----------------------------------------------------------------------------

local wire_holograms_max = CreateConVar( "wire_holograms_max", "250", {FCVAR_ARCHIVE} )
local wire_holograms_spawn_amount = CreateConVar( "wire_holograms_spawn_amount", "15", {FCVAR_ARCHIVE} ) -- This limit resets once a second
local wire_holograms_burst_amount = CreateConVar( "wire_holograms_burst_amount", "80", {FCVAR_ARCHIVE} ) -- This limit goes down first, resets every burst_delay
local wire_holograms_burst_delay = CreateConVar( "wire_holograms_burst_delay", "10", {FCVAR_ARCHIVE} )
local wire_holograms_max_clips = CreateConVar( "wire_holograms_max_clips", "5", {FCVAR_ARCHIVE} ) -- Don't set higher than 16 without editing net.Start("wire_holograms_clip")
local wire_holograms_modelany = CreateConVar( "wire_holograms_modelany", "0", {FCVAR_ARCHIVE},
	"1: Allow holograms to use models besides the official hologram models." ..
	"2: Allow holograms to additionally use models not present on the server." )
local wire_holograms_size_max = CreateConVar( "wire_holograms_size_max", "50", {FCVAR_ARCHIVE} )
CreateConVar( "wire_holograms_display_owners_maxdist", "-1", {FCVAR_ARCHIVE + FCVAR_REPLICATED},
	"The maximum distance that wire_holograms_display_owners will allow names to be seen. -1 for original function. Server-side and has priority over clients.", -1, 32768)
util.AddNetworkString("wire_holograms_set_visible")
util.AddNetworkString("wire_holograms_clip")
util.AddNetworkString("wire_holograms_set_scale")
util.AddNetworkString("wire_holograms_set_bone_scale")
util.AddNetworkString("wire_holograms_set_player_color")


-- context = chip.context = self
-- uid = context.uid = self.uid = chip.uid = player:UniqueID()
-- Holo = { ent = prop, scale = scale, e2owner = context }
-- E2HoloRepo[uid][-index] = Holo <-- global holos
-- E2HoloRepo[uid][Holo] = Holo <-- local holos
-- context.data.holos[index] = Holo <-- local holos

local E2HoloRepo = {}
local PlayerAmount = {}
local BlockList = {}

local ModelList = {
	["cone"]              = "cone",
	["cplane"]			  = "cplane",
	["cube"]              = "cube",
	["cylinder"]          = "cylinder",
	["hq_cone"]           = "hq_cone",
	["hq_cylinder"]       = "hq_cylinder",
	["hq_dome"]           = "hq_dome",
	["hq_hdome"]          = "hq_hdome",
	["hq_hdome_thick"]    = "hq_hdome_thick",
	["hq_hdome_thin"]     = "hq_hdome_thin",
	["hq_icosphere"]      = "hq_icosphere",
	["hq_sphere"]         = "hq_sphere",
	["hq_torus"]          = "hq_torus",
	["hq_torus_thick"]    = "hq_torus_thick",
	["hq_torus_thin"]     = "hq_torus_thin",
	["hq_torus_oldsize"]  = "hq_torus_oldsize",
	["hq_tube"]           = "hq_tube",
	["hq_tube_thick"]     = "hq_tube_thick",
	["hq_tube_thin"]      = "hq_tube_thin",
	["hq_stube"]          = "hq_stube",
	["hq_stube_thick"]    = "hq_stube_thick",
	["hq_stube_thin"]     = "hq_stube_thin",
	["icosphere"]         = "icosphere",
	["icosphere2"]        = "icosphere2",
	["icosphere3"]        = "icosphere3",
	["plane"]             = "plane",
	["prism"]             = "prism",
	["pyramid"]           = "pyramid",
	["sphere"]            = "sphere",
	["sphere2"]           = "sphere2",
	["sphere3"]           = "sphere3",
	["tetra"]             = "tetra",
	["torus"]             = "torus",
	["torus2"]            = "torus2",
	["torus3"]            = "torus3",

	["rcube"]             = "rcube",
	["rcube_thick"]       = "rcube_thick",
	["rcube_thin"]     	  = "rcube_thin",
	["hq_rcube"]          = "hq_rcube",
	["hq_rcube_thick"]    = "hq_rcube_thick",
	["hq_rcube_thin"]     = "hq_rcube_thin",
	["rcylinder"]         = "rcylinder",
	["rcylinder_thick"]   = "rcylinder_thick",
	["rcylinder_thin"]    = "rcylinder_thin",
	["hq_rcylinder"]      = "hq_rcylinder",
	["hq_rcylinder_thick"]= "hq_rcylinder_thick",
	["hq_rcylinder_thin"] = "hq_rcylinder_thin",
	["hq_cubinder"]       = "hq_cubinder",
	["hexagon"]           = "hexagon",
	["octagon"]           = "octagon",
	["right_prism"]       = "right_prism",

	-- Removed models with their replacements

	["dome"]             = "hq_dome",
	["dome2"]            = "hq_hdome",
	["hqcone"]           = "hq_cone",
	["hqcylinder"]       = "hq_cylinder",
	["hqcylinder2"]      = "hq_cylinder",
	["hqicosphere"]      = "hq_icosphere",
	["hqicosphere2"]     = "hq_icosphere",
	["hqsphere"]         = "hq_sphere",
	["hqsphere2"]        = "hq_sphere",
	["hqtorus"]          = "hq_torus_oldsize",
	["hqtorus2"]         = "hq_torus_oldsize",

	-- HQ models with their short names

	["hqhdome"]          = "hq_hdome",
	["hqhdome2"]         = "hq_hdome_thin",
	["hqhdome3"]         = "hq_hdome_thick",
	["hqtorus3"]         = "hq_torus_thick",
	["hqtube"]           = "hq_tube",
	["hqtube2"]          = "hq_tube_thin",
	["hqtube3"]          = "hq_tube_thick",
	["hqstube"]          = "hq_stube",
	["hqstube2"]         = "hq_stube_thin",
	["hqstube3"]         = "hq_stube_thick",
	["hqrcube"]          = "hq_rcube",
	["hqrcube2"]         = "hq_rcube_thick",
	["hqrcube3"]         = "hq_rcube_thin",
	["hqrcylinder"]      = "hq_rcylinder",
	["hqrcylinder2"]     = "hq_rcylinder_thin",
	["hqrcylinder3"]     = "hq_rcylinder_thick",
	["hqcubinder"]       = "hq_cubinder"
}

-- Return the absolute model path
local function modelPath(name)
	return "models/holograms/" .. name .. ".mdl"
end

local added = {}
local pathLookup = {}

for _,v in pairs( ModelList ) do
	if not added[v] then
		local path = modelPath(v)

		pathLookup[path] = true
		util.PrecacheModel(path)
		-- resource.AddSingleFile( "models/holograms/" .. v .. ".mdl" )

		added[v] = true
	end
end

local function GetModel(self, model, skin)
	skin = skin or 0

	if ModelList[model] then
		model = modelPath(ModelList[model])

	-- If this model isn't already the absolute path of a default model, and only default models are allowed
	elseif not pathLookup[model] and wire_holograms_modelany:GetInt() == 0 then
		return false
	end

	if wire_holograms_modelany:GetInt() ~= 2 and not WireLib.CanModel(self.player, model, skin) then
		-- Check if the model is at least valid
		if not WireLib.CanModel(self.player, model, 0) then
			return false
		end

		-- The model was valid however the skin was not. Go to default skin
		skin = 0
	end

	return model, skin
end

-- -----------------------------------------------------------------------------

local scale_queue = {}
local bone_scale_queue = {}
local clip_queue = {}
local vis_queue = {}
local player_color_queue = {}

--[[ helper function to add items to a queue
	parameters:
		queue - the queue to add to
		ply - the player who ran the command
		holo - holo table entry
		id - ID of queue entry, or nil if not unique. will overwrite entries in the queue of a matching id
			 this is not the same as hologram ID - this refers to the queue ID
		data - data to add to queue
]]
local function add_queue( queue, ply, holo, id, data )
	local plyqueue = queue[ply]
	if not plyqueue then
		plyqueue = {}
		queue[ply] = plyqueue
	end

	if id ~= nil then
		local holoqueue = plyqueue[holo]
		if holoqueue == nil then
			holoqueue = {}
			plyqueue[holo] = holoqueue
		end
		holoqueue[id] = data
	else
		plyqueue[holo] = data
	end
end

-- call to remove all queued items for a specific hologram
local function remove_from_queues( holo_ent )
	local function remove_from_queue( queue )
		for _, plyqueue in pairs( queue ) do
			for holo, _ in pairs( plyqueue ) do
				if holo.ent == holo_ent then
					plyqueue[holo] = nil
				end
			end
		end
	end

	remove_from_queue( scale_queue )
	remove_from_queue( bone_scale_queue )
	remove_from_queue( clip_queue )
	remove_from_queue( vis_queue )
	remove_from_queue( player_color_queue )
end

local function remove_holo( Holo )
	if IsValid(Holo.ent) then
		remove_from_queues( Holo.ent )
		Holo.ent:Remove()
	end
end

local function flush_scale_queue(queue, recipient)
	if not queue then queue = scale_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_set_scale")
		for _, plyqueue in pairs(queue) do
			for Holo, scale in pairs(plyqueue) do
				net.WriteUInt(Holo.ent:EntIndex(), MAX_EDICT_BITS)
				net.WriteFloat(scale.x)
				net.WriteFloat(scale.y)
				net.WriteFloat(scale.z)
			end
		end
		net.WriteUInt(0, MAX_EDICT_BITS)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_bone_scale_queue(queue, recipient)
	if not queue then queue = bone_scale_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_set_bone_scale")
	for _, plyqueue in pairs(queue) do
		for Holo, holoqueue in pairs(plyqueue) do
			for bone, scale in pairs(holoqueue) do
				net.WriteUInt(Holo.ent:EntIndex(), MAX_EDICT_BITS)
				net.WriteUInt(bone + 1, 9) -- using +1 to be able reset holo bones scale with -1 and not use signed int
				net.WriteFloat(scale.x)
				net.WriteFloat(scale.y)
				net.WriteFloat(scale.z)
			end
		end
	end
	net.WriteUInt(0, MAX_EDICT_BITS)
	net.WriteUInt(0, 16)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_clip_queue(queue, recipient)
	if not queue then queue = clip_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_clip")
		for _, plyqueue in pairs(queue) do
			for Holo,holoqueue in pairs(plyqueue) do
				for _, clip in pairs(holoqueue) do
					if clip and clip.index then
						net.WriteUInt(Holo.ent:EntIndex(), MAX_EDICT_BITS)
						net.WriteUInt(clip.index, 4) -- 4: absolute highest wire_holograms_max_clips is thus 16
						if clip.enabled ~= nil then
							net.WriteBool(true)
							net.WriteBool(clip.enabled)
						elseif clip.origin and clip.normal and clip.localentid then
							net.WriteBool(false)
							net.WriteVector(clip.origin)
							net.WriteVector(clip.normal)
							net.WriteUInt(clip.localentid, MAX_EDICT_BITS)
						end
					end
				end
			end
		end
		net.WriteUInt(0, MAX_EDICT_BITS)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_vis_queue()
	if not next(vis_queue) then return end

	for ply,plyqueue in pairs( vis_queue ) do
		if IsValid( ply ) and next(plyqueue) ~= nil then
			net.Start("wire_holograms_set_visible")
				for Holo,visible in pairs(plyqueue) do
					net.WriteUInt(Holo.ent:EntIndex(), MAX_EDICT_BITS)
					net.WriteBit(visible)
				end
				net.WriteUInt(0, MAX_EDICT_BITS)
			net.Send(ply)
		end
	end
end

local function flush_player_color_queue()
	if not next(player_color_queue) then return end

	net.Start("wire_holograms_set_player_color")
		for _, plyqueue in pairs(player_color_queue) do
			for Holo,color in pairs(plyqueue) do
				net.WriteUInt(Holo.ent:EntIndex(), MAX_EDICT_BITS)
				net.WriteVector(color)
			end
		end
		net.WriteUInt(0, MAX_EDICT_BITS)
	net.Broadcast()
end


registerCallback("postexecute", function(self)
	if timer.Exists("wire_hologram_postexecute_"..self.uid) then return end
	timer.Create("wire_hologram_postexecute_"..self.uid,0.1,1,function()
		if not IsValid(self.entity) then return end

		flush_scale_queue()
		flush_bone_scale_queue()
		flush_clip_queue()
		flush_vis_queue()
		flush_player_color_queue()

		scale_queue = {}
		bone_scale_queue = {}
		clip_queue = {}
		vis_queue = {}
		player_color_queue = {}
	end)
end)

local function rescale(Holo, scale, bone)
	local maxval = wire_holograms_size_max:GetInt()
	local minval = -maxval

	if scale then
		local x = math.Clamp( scale[1], minval, maxval )
		local y = math.Clamp( scale[2], minval, maxval )
		local z = math.Clamp( scale[3], minval, maxval )
		local scale = Vector(x, y, z)

		if Holo.scale ~= scale then
			add_queue( scale_queue, Holo.e2owner, Holo, nil, scale )
			Holo.scale = scale
		end
	end

	if bone then
		Holo.bone_scale = Holo.bone_scale or {}
		if #bone == 2 then
			local bidx, b_scale = bone[1], bone[2]
			local x = math.Clamp( b_scale[1], minval, maxval )
			local y = math.Clamp( b_scale[2], minval, maxval )
			local z = math.Clamp( b_scale[3], minval, maxval )
			local scale = Vector(x, y, z)

			add_queue( bone_scale_queue, Holo.e2owner, Holo, bidx, scale )
			Holo.bone_scale[bidx] =  scale
		else  -- reset holo bone scale
			add_queue( bone_scale_queue, Holo.e2owner, Holo, -1, Vector(0,0,0) )
			Holo.bone_scale = {}
		end
	end
end

local function check_clip(Holo, idx)
	Holo.clips = Holo.clips or {}

	if idx > 0 and idx <= wire_holograms_max_clips:GetInt() then
		Holo.clips[idx] = Holo.clips[idx] or {}
		local clip = Holo.clips[idx]

		clip.enabled = clip.enabled or false
		clip.origin = clip.origin or Vector(0,0,0)
		clip.normal = clip.normal or Vector(0,0,0)
		clip.localentid = clip.localentid or 0

		return clip
	end

	return nil
end

local function enable_clip(Holo, idx, enabled)
	local clip = check_clip(Holo, idx)

	if clip and clip.enabled ~= enabled then
		clip.enabled = enabled

		add_queue( clip_queue, Holo.e2owner, Holo, "e"..idx, {index = idx, enabled=enabled} )
	end
end

local function set_clip(Holo, idx, origin, normal, localentid)
	local clip = check_clip(Holo, idx)

	if clip and (clip.origin ~= origin or clip.normal ~= normal or clip.localentid ~= localentid) then
		clip.origin = origin
		clip.normal = normal
		clip.localentid = localentid

		add_queue( clip_queue, Holo.e2owner, Holo, "s"..idx, {
			index = idx,
			origin = origin,
			normal = normal,
			localentid = localentid
		})
	end
end

local function set_visible(Holo, players, visible)
	if not Holo.visible then Holo.visible = {} end
	visible = (visible == 1) or (visible == true)
	for _,ply in pairs( players ) do
		if IsValid( ply ) and ply:IsPlayer() and Holo.visible[ply] ~= visible then
			Holo.visible[ply] = visible
			add_queue( vis_queue, ply, Holo, nil, visible )
		end
	end
end

local function reset_clholo(Holo, scale)
	if Holo.clips then
		for cidx, clip in pairs(Holo.clips) do
			if clip.enabled then
				add_queue( clip_queue, Holo.e2owner, Holo, "e"..cidx, {index=cidx,enabled=false} )
			end
		end
		Holo.clips = {}
	end
	rescale(Holo, scale, {})
	if Holo.visible then
		for ply, state in pairs(Holo.visible) do
			if not state then
				add_queue( vis_queue, ply, Holo, nil, true )
			end
		end
		Holo.visible = {}
	end
end

local function set_player_color(Holo, color)
	add_queue( player_color_queue, Holo.e2owner, Holo, nil, color )
end

hook.Add( "PlayerInitialSpawn", "wire_holograms_set_vars", function(ply)
	local temp_scale_queue = {}
	local temp_bone_scale_queue = {}
	local temp_clip_queue = {}

	for pl_uid,rep in pairs( E2HoloRepo ) do
		for k,Holo in pairs( rep ) do
			if Holo and IsValid(Holo.ent) then
				local clips = Holo.clips
				local scale = Holo.scale
				local bone_scales = Holo.bone_scale

				add_queue( temp_scale_queue, ply, Holo, nil, scale )


				if bone_scales and next(bone_scales) ~= nil then
					for bidx,b_scale in pairs(bone_scales) do
						add_queue( temp_bone_scale_queue, ply, Holo, bidx, b_scale )
					end
				end

				if clips and next(clips) ~= nil then
					for cidx,clip in pairs(clips) do
						if clip.enabled then
							add_queue( temp_clip_queue, ply, Holo, "e"..cidx, {index=cidx,enabled=clip.enabled} )
						end

						if clip.origin and clip.normal and clip.localentid then
							add_queue( temp_clip_queue, ply, Holo, "s"..cidx, {
								index = cidx,
								origin = clip.origin,
								normal = clip.normal,
								localentid = clip.localentid
							})
						end
					end
				end
			end
		end
	end

	flush_scale_queue(temp_scale_queue, ply)
	flush_bone_scale_queue(temp_bone_scale_queue, ply)
	flush_clip_queue(temp_clip_queue, ply)
end)

-- -----------------------------------------------------------------------------

local function MakeHolo(Player, Pos, Ang, model)
	local prop = ents.Create( "gmod_wire_hologram" )
	WireLib.setPos(prop, Pos)
	WireLib.setAng(prop, Ang)
	prop:SetModel(model)
	prop:SetPlayer(Player)
	return prop
end

-- Returns the hologram with the given index or nil if it doesn't exist.
-- if shouldbenil is nil or false, assert that the hologram exists on @strict with an error. Otherwise, don't check (for holo creation, etc)
local function CheckIndex(self, index, shouldbenil)
	if index ~= index then return self:throw("holo index is NaN!", nil) end
	index = math.Clamp(math.floor(index), -2^31, 2^31)
	local Holo
	if index<0 then
		Holo = E2HoloRepo[self.uid][-index]
	else
		Holo = self.data.holos[index]
	end
	if (not Holo or not IsValid(Holo.ent)) and not shouldbenil then return self:throw("Holo at index " .. index .. " does not exist!", nil) end
	return Holo
end

-- checks if a bone id is valid for a holo, throws an error for @strict if not.
local function CheckBone(self, index, boneindex, Holo)
	local name = Holo.ent:GetBoneName(boneindex)
	if not name or name == "__INVALIDBONE__" then return self:throw("Holo at index " .. index .. " does not have a bone " .. boneindex .. "!", nil) end
	return true
end

-- Sets the given index to the given hologram.
local function SetIndex(self, index, Holo)
	index = math.Clamp(math.floor(index), -2^31, 2^31)
	local rep = E2HoloRepo[self.uid]
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

	model = GetModel(self, model or "cube") or "models/holograms/cube.mdl"

	local Holo = CheckIndex(self, index, true)
	if not Holo then
		Holo = {}
		SetIndex(self, index, Holo)
	end

	local prop

	if IsValid(Holo.ent) then
		prop = Holo.ent
		WireLib.setPos(prop, pos)
		WireLib.setAng(prop, ang)
		prop:SetModel( model )
	else
		prop = MakeHolo(self.player, pos, ang, model, {}, {})
		prop:Activate()
		prop:Spawn()
		prop:SetSolid(SOLID_NONE)
		prop:SetMoveType(MOVETYPE_NONE)
		PlayerAmount[self.uid] = PlayerAmount[self.uid]+1
		Holo.ent = prop
		Holo.e2owner = self

		prop:CallOnRemove( "holo_cleanup", function( ent, self, index ) --Give the player more holograms if we get removed
			local Holo = CheckIndex( self, index )
			if not Holo then return end

			PlayerAmount[self.uid] = PlayerAmount[self.uid] - 1
			SetIndex( self, index, nil )
		end, self, index )
	end

	if not IsValid(prop) then return nil end

	if color then WireLib.SetColor(Holo.ent, Color(color[1],color[2],color[3],color[4] or 255)) end

	reset_clholo(Holo, scale) -- Reset scale, clips, and visible status

	prop.E2HoloData = Holo

	return prop
end

-- -----------------------------------------------------------------------------

local function CheckSpawnTimer( self, readonly )
	local holo = self.data.holo
	if CurTime() >= holo.nextSpawn then
		holo.nextSpawn = CurTime()+1
		if CurTime() >= holo.nextBurst then
			holo.remainingSpawns = wire_holograms_burst_amount:GetInt()
		elseif holo.remainingSpawns < wire_holograms_spawn_amount:GetInt() then
			holo.remainingSpawns = wire_holograms_spawn_amount:GetInt()
		end
	end

	if CurTime() >= holo.nextBurst then
		holo.nextBurst = CurTime() + wire_holograms_burst_delay:GetInt()
	end

	if holo.remainingSpawns > 0 then
		if not readonly then
			holo.remainingSpawns = holo.remainingSpawns - 1
		end
		return true
	else
		return false
	end
end

-- Removes all holograms from the given chip.
local function clearholos(self)
	-- delete local holos
	for index,Holo in pairs(self.data.holos) do remove_holo(Holo) end

	-- delete global holos owned by this chip
	local rep = E2HoloRepo[self.uid]
	if not rep then return end
	for index,Holo in pairs(rep) do
		if Holo.e2owner == self then remove_holo(Holo) end
	end
end

local function clearholos_all(ply_uid)
	if ply_uid == nil then
		for pl_uid, rep in pairs(E2HoloRepo) do clearholos_all(pl_uid) end
		return
	end

	for k,Holo in pairs(E2HoloRepo[ply_uid]) do
		if Holo and IsValid(Holo.ent) then
			Holo.ent:RemoveCallOnRemove( "holo_cleanup" )
			remove_holo(Holo)
		end
	end

	E2HoloRepo[ply_uid] = {}
	PlayerAmount[ply_uid] = 0
end

local function checkHoloCount(self)
	if PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then
		return self:throw("You've hit the maximum amount of holograms!", true)
	end
end

-- -----------------------------------------------------------------------------

__e2setcost(30) -- temporary



e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color, string model)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color, model)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector4 color, string model)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color, model)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector4 color)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position, scale)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and checkHoloCount(self) then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index, true)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	local ret = CreateHolo(self, index)
	if IsValid(ret) then return ret end
end

__e2setcost(20)
e2function void holoDelete(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	remove_holo(Holo)
end

e2function void holoDeleteAll()
	clearholos(self)
end

e2function void holoDeleteAll( all )
	if all > 0 then
		clearholos_all( self.uid )
	else
		clearholos( self )
	end
end

e2function void holoReset(index, string model, vector scale, vector color, string material)
	model = GetModel(self, model)
	if not model then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetModel(model)
	WireLib.SetColor(Holo.ent, Color(color[1],color[2],color[3],255))
	E2Lib.setMaterial(Holo.ent, material)

	remove_from_queues( Holo.ent )
	reset_clholo(Holo, scale) -- Reset scale, clips, and visible status
end

__e2setcost(2)

e2function number holoCanCreate()
	if (not checkOwner(self)) then return 0 end

	if CheckSpawnTimer(self, true) == false or PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then
		return 0
	end

	return 1
end

e2function number holoRemainingSpawns()
	CheckSpawnTimer(self, true)
	return self.data.holo.remainingSpawns
end

e2function number holoAmount()
	return PlayerAmount[self.uid]
end

e2function number holoMaxAmount()
	return wire_holograms_max:GetInt()
end

-- -----------------------------------------------------------------------------

__e2setcost(30) -- temporary

e2function void holoScale(index, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	rescale(Holo, scale)
end

e2function vector holoScale(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.scale or Vector(0, 0, 0) -- TODO: maybe 1,1,1?
end

e2function void holoScaleUnits(index, vector size)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local propsize = Holo.ent:OBBMaxs()-Holo.ent:OBBMins()

	local x = size[1] / propsize.x
	local y = size[2] / propsize.y
	local z = size[3] / propsize.z

	rescale(Holo, Vector(x, y, z))
end

e2function vector holoScaleUnits(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return self:throw("Holo at index " .. index .. " does not exist!", Vector(0, 0, 0)) end

	local scale = Holo.scale or Vector(0, 0, 0) -- TODO: maybe 1,1,1?

	local propsize = Holo.ent:OBBMaxs()-Holo.ent:OBBMins()

	return Vector(scale[1] * propsize.x, scale[2] * propsize.y, scale[3] * propsize.z)
end

-- -----------------------------------------------------------------------------

e2function void holoBoneScale(index, boneindex, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	if not CheckBone(self, index, boneindex, Holo) then return end

	rescale(Holo, nil, {boneindex, scale})
end

e2function void holoBoneScale(index, string bone, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	local boneindex = Holo.ent:LookupBone(bone)
	if boneindex == nil then return self:throw("Holo at index " .. index .. " does not have a bone ['" .. bone .. "']!", nil) end

	rescale(Holo, nil, {boneindex, scale})
end

e2function vector holoBoneScale(index, boneindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return Vector(0, 0, 0) end
	if not CheckBone(self, index, boneindex, Holo) then return Vector(0, 0, 0) end

	return Holo.bone_scale[boneindex] or Vector(1, 1, 1)
end

e2function vector holoBoneScale(index, string bone)
	local Holo = CheckIndex(self, index)
	if not Holo then return Vector(0, 0, 0) end
	local boneindex = Holo.ent:LookupBone(bone)

	if boneindex == nil then return self:throw("Holo at index " .. index .. " does not have a bone ['" .. bone .. "']!", Vector(0, 0, 0)) end
	return Holo.bone_scale[boneindex] or Vector(1, 1, 1)
end

e2function vector holoBonePos(index, boneindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return Vector(0, 0, 0) end
	if not CheckBone(self, index, boneindex, Holo) then return Vector(0, 0, 0) end

	return Holo.ent:GetBoneMatrix(boneindex):GetTranslation()
end


e2function vector holoBonePos(index, string bone)
	local Holo = CheckIndex(self, index)
	if not Holo then return self:throw("Holo at index " .. index .. " does not exist!", Vector(0, 0, 0)) end

	local boneindex = Holo.ent:LookupBone(bone)
	if boneindex == nil then return self:throw("Holo at index " .. index .. " does not have a bone ['" .. bone .. "']!", Vector(0, 0, 0)) end
	return Holo.ent:GetBoneMatrix(boneindex):GetTranslation()
end

e2function angle holoBoneAng(index, boneindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return Angle(0, 0, 0) end
	if not CheckBone(self, index, boneindex, Holo) then return Angle(0, 0, 0) end

	return Holo.ent:GetBoneMatrix(boneindex):GetAngles()
end


e2function angle holoBoneAng(index, string bone)
	local Holo = CheckIndex(self, index)
	if not Holo then return self:throw("Holo at index " .. index .. " does not exist!", Angle(0, 0, 0)) end

	local boneindex = Holo.ent:LookupBone(bone)
	if boneindex == nil then return self:throw("Holo at index " .. index .. " does not have a bone ['" .. bone .. "']!", Angle(0, 0, 0)) end
	return Holo.ent:GetBoneMatrix(boneindex):GetAngles()
end

-- -----------------------------------------------------------------------------

__e2setcost(1)
e2function number holoClipsAvailable()
	return wire_holograms_max_clips:GetInt()
end

__e2setcost(30)
e2function void holoClipEnabled(index, enabled) -- Clip at first index
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if enabled == 1 then
		enable_clip(Holo, 1, true)
	elseif enabled == 0 then
		enable_clip(Holo, 1, false)
	end
end

e2function void holoClipEnabled(index, clipidx, enabled)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if enabled == 1 then
		enable_clip(Holo, clipidx, true)
	elseif enabled == 0 then
		enable_clip(Holo, clipidx, false)
	end
end

e2function void holoClip(index, vector origin, vector normal, isglobal) -- Clip at first index
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, 1, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), isglobal ~= 0 and 0 or Holo.ent:EntIndex())
end

e2function void holoClip(index, clipidx, vector origin, vector normal, isglobal)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, clipidx, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), isglobal ~= 0 and 0 or Holo.ent:EntIndex())
end

e2function void holoClip(index, vector origin, vector normal, entity localent) -- Clip at first index
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, 1, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), localent:EntIndex())
end

e2function void holoClip(index, clipidx, vector origin, vector normal, entity localent)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, clipidx, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), localent:EntIndex())
end

__e2setcost(15)

e2function void holoPos(index, vector position)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	WireLib.setPos(Holo.ent, position)
end

e2function void holoLocalPos(index, vector position)
	local holo = CheckIndex(self, index)
	if not holo then return end

	WireLib.setLocalPos(holo.ent, position)
end

[nodiscard]
e2function vector holoPos(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return Vector(0, 0, 0) end

	return Holo.ent:GetPos()
end

e2function void holoAng(index, angle ang)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	WireLib.setAng(Holo.ent, ang)
end

e2function void holoLocalAng(index, angle ang)
	local holo = CheckIndex(self, index)
	if not holo then return end

	WireLib.setLocalAng(holo.ent, ang)
end

[nodiscard]
e2function angle holoAng(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return Angle(0, 0, 0) end

	return Holo.ent:GetAngles()
end

-- -----------------------------------------------------------------------------

e2function void holoColor(index, vector color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	WireLib.SetColor(Holo.ent, Color(color[1],color[2],color[3],Holo.ent:GetColor().a))
end

e2function void holoColor(index, vector4 color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	WireLib.SetColor(Holo.ent, Color(color[1],color[2],color[3],color[4]))
end

e2function void holoColor(index, vector color, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	WireLib.SetColor(Holo.ent, Color(color[1],color[2],color[3],alpha))
end

e2function void holoAlpha(index, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local c = Holo.ent:GetColor()
	c.a = alpha
	WireLib.SetColor(Holo.ent, c)
end

__e2setcost(10)
e2function void holoShadow(index, has_shadow)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:DrawShadow( has_shadow ~= 0 )
end

e2function void holoDisableShading( index, disable )
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetNWBool( "disable_shading", disable == 1 )
end

e2function void holoInvertModel( index, enable )
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetNWInt("invert_model", enable ~= 0 and 1 or 0)
end

-- -----------------------------------------------------------------------------

e2function array holoModelList()
	local mlist = {}

	for k,_ in pairs( ModelList ) do
	    mlist[#mlist + 1] = k
	end

	return mlist
end

__e2setcost(1)
e2function number holoModelAny()
	return wire_holograms_modelany:GetInt()
end

__e2setcost(10)
e2function void holoModel(index, string model)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	model = GetModel(self, model)
	if not model then return end

	Holo.ent:SetModel(model)
end

e2function void holoModel(index, string model, skin)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	skin = skin - skin % 1

	model, skin = GetModel(self, model, skin)
	if not model then return end

	Holo.ent:SetModel(model)
	Holo.ent:SetSkin(skin)
end

e2function void holoSkin(index, skin)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	skin = skin - skin % 1
	local _, skin = GetModel(self, Holo.ent:GetModel(), skin)

	Holo.ent:SetSkin(skin)
end

e2function void holoMaterial(index, string material)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	E2Lib.setMaterial(Holo.ent, material)
end

e2function void holoPlayerColor(index, vector color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local r = color[1]/255
	local g = color[2]/255
	local b = color[3]/255

	set_player_color(Holo, Vector(r, g, b))
end

e2function void holoRenderFX(index, effect)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	effect = effect - effect % 1
	Holo.ent:SetKeyValue("renderfx",effect)
end

e2function void holoBodygroup(index, bgrp_id, bgrp_subid)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetBodygroup(bgrp_id, bgrp_subid)
end

e2function number holoBodygroups(index, bgrp_id)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:GetBodygroupCount(bgrp_id)
end

-- -----------------------------------------------------------------------------

e2function void holoVisible(index, entity ply, visible)
	local Holo = CheckIndex(self, index)
	if not Holo or not IsValid( ply ) or not ply:IsPlayer() then return end

	set_visible(Holo, { ply }, visible)
end

e2function void holoVisible(index, array players, visible)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_visible(Holo, players, visible)
end

-- -----------------------------------------------------------------------------
---@param bone integer?
local function Parent_Hologram(holo, ent, attachment, bone)
	if ent:GetParent() and ent:GetParent():IsValid() and ent:GetParent() == holo.ent then return end

	if bone then
		if bone >= 0 and bone < ent:GetBoneCount() then
			holo.ent:FollowBone(ent, bone)
			return
		end
	end

	holo.ent:SetParent(ent)

	if attachment ~= nil then
		holo.ent:Fire("SetParentAttachmentMaintainOffset", attachment, 0.01)
	end
end

-- Check for recursive parenting
local function Check_Parents(child, parent)
	while IsValid(parent:GetParent()) do
		parent = parent:GetParent()
		if parent == child then
			return false
		end
	end

	return true
end

__e2setcost(40)
e2function void holoParent(index, otherindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local Holo2 = CheckIndex(self, otherindex)
	if not Holo2 then return end

	if not Check_Parents(Holo.ent, Holo2.ent) then return end

	Parent_Hologram(Holo, Holo2.ent, nil)
end

e2function void holoParent(index, entity ent)
	if not IsValid(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if not Check_Parents(Holo.ent, ent) then return end

	Parent_Hologram(Holo, ent, nil)
end

e2function void holoParentAttachment(index, entity ent, string attachmentName)
	if not IsValid(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Parent_Hologram(Holo, ent, attachmentName)
end

e2function void holoParentAttachment(index, otherindex, string attachmentName)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local Holo2 = CheckIndex(self, otherindex)
	if not Holo2 then return end

	if not Check_Parents(Holo.ent, Holo2.ent) then return end

	Parent_Hologram(Holo, Holo2.ent, attachmentName)
end

e2function void holoParentBone(index, entity ent, bone)
	if not IsValid(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Parent_Hologram(Holo, ent, nil, bone)
end

e2function void holoParentBone(index, otherindex, bone)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local Holo2 = CheckIndex(self, otherindex)
	if not Holo2 then return end

	if not Check_Parents(Holo.ent, Holo2.ent) then return end

	Parent_Hologram(Holo, Holo2.ent, nil, bone)
end

-- Combination of EF_BONEMERGE and EF_BONEMERGE_FASTCULL, to avoid performance complaints.
local BONEMERGE_FLAGS = bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL)

e2function void holoUnparent(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:RemoveEffects(BONEMERGE_FLAGS)
	Holo.ent:FollowBone(nil, 0)
end

__e2setcost(10)

e2function void holoBonemerge(index, state)
	local Holo = CheckIndex(self, index)
	if not Holo or not Holo.ent:GetParent():IsValid() then return end

	if state ~= 0 then
		Holo.ent:AddEffects(BONEMERGE_FLAGS)
	else
		Holo.ent:RemoveEffects(BONEMERGE_FLAGS)
	end
end

-- -----------------------------------------------------------------------------

__e2setcost(2)
e2function entity holoEntity(index)
	local Holo = CheckIndex(self, index)
	if Holo and IsValid(Holo.ent) then return Holo.ent end
end

__e2setcost(30)
--- Gets the hologram index of the given entity, if any. Returns 0 on failure.
e2function number holoIndex(entity ent)
	if not IsValid(ent) then return 0 end
	if ent:GetClass() ~= "gmod_wire_hologram" then return 0 end

	-- check local holos
	for k,Holo in pairs(self.data.holos) do
		if(ent == Holo.ent) then return k end
	end

	-- check global holos
	for k,Holo in pairs(E2HoloRepo[self.uid]) do
		if isnumber(k) and ent == Holo.ent then return -k end
	end
	return 0
end

-- -----------------------------------------------------------------------------

local function SetHoloAnim(Holo, Animation, Frame, Rate)
	if (Holo and Animation and Frame and Rate) then
		if not Holo.ent.Animated then
			-- This must be run once on entities that will be animated
			Holo.ent.Animated = true
			Holo.ent.AutomaticFrameAdvance = true
		end
		Holo.ent:ResetSequence(Animation)
		Holo.ent:SetCycle(math.Clamp(Frame, 0, 1))
		--Something mustve changed between the time holoAnim core was made and now, negative values no longer affect the "Frame" value
		Holo.ent:SetPlaybackRate(math.Clamp(Rate, -12, 12))
	end
end

__e2setcost(15)
e2function void holoAnim(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	local anim = Holo.ent:LookupSequence(animation)
	if anim == -1 then self:throw("'" .. animation .. "' does not exist on this model!", 0) end

	SetHoloAnim(Holo, anim, 0, 1)
end

e2function void holoAnim(index, string animation, frame)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	if Holo.ent:LookupSequence(animation) == -1 then self:throw("'" .. animation .. "' does not exist on this model!", 0) end

	SetHoloAnim(Holo, animation, frame, 1)
end

e2function void holoAnim(index, string animation, frame, rate)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	if Holo.ent:LookupSequence(animation) == -1 then self:throw("'" .. animation .. "' does not exist on this model!", 0) end

	SetHoloAnim(Holo, animation, frame, rate)
end

e2function void holoAnim(index, animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	SetHoloAnim(Holo, animation, 0, 1)
end

e2function void holoAnim(index, animation, frame)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	SetHoloAnim(Holo, animation, frame, 1)
end

e2function number holoGetAnimFrame(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:GetCycle()
end

e2function void holoAnim(index, animation, frame, rate)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	SetHoloAnim(Holo, animation, frame, rate)
end

e2function array holoGetAnims(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:GetSequenceList()
end

e2function number holoAnimLength(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:SequenceDuration()
end

e2function number holoAnimNum(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:LookupSequence(animation) or 0
end

e2function number holoGetAnimGroundSpeed(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	local anim = Holo.ent:LookupSequence(animation)
	if anim == -1 then self:throw("'" .. animation .. "' does not exist on this model!", 0) end

	return Holo.ent:GetSequenceGroundSpeed(anim)
end

e2function void holoSetAnimFrame(index, frame)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetCycle(math.Clamp(frame, 0, 1))
end

e2function void holoSetAnimSpeed(index, rate)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetPlaybackRate(math.Clamp(rate, -12, 12))
end

e2function number holoGetAnimGroundSpeed(index, animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	return Holo.ent:GetSequenceGroundSpeed(animation)
end

e2function void holoSetPose(index, string pose, value)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetPoseParameter(pose, value)
end

e2function number holoGetPose(index, string pose)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local pose_param = Holo.ent:LookupPoseParameter(pose)
	if pose_param == -1 then self:throw("'" .. pose .. "' pose parameter does not exist on this model!", 0) end
	return Holo.ent:GetPoseParameter(pose_param)
end

e2function array holoGetPoses(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local tbl = {}
	for i = 0, Holo.ent:GetNumPoseParameters() - 1 do
		table.insert(tbl, Holo.ent:GetPoseParameterName(i))
	end
	return tbl
end

e2function vector2 holoGetPoseRange(index, string pose)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local pose_param = Holo.ent:LookupPoseParameter(pose)
	if pose_param == -1 then self:throw("'" .. pose .. "' pose parameter doesn't exist on this model!", 0) end
	return { Holo.ent:GetPoseParameterRange(pose_param) }
end

e2function void holoClearPoses(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:ClearPoseParameters()
end

-- -----------------------------------------------------------------------------

registerCallback("construct", function(self)
	if not E2HoloRepo[self.uid] then
		E2HoloRepo[self.uid] = {}
		PlayerAmount[self.uid] = 0
	end
	--self.data.HoloEffect = false
	self.data.holos = {}
	self.data.holo = {
		nextSpawn = CurTime()+1,
		nextBurst = CurTime()+wire_holograms_burst_delay:GetInt(),
		remainingSpawns = wire_holograms_burst_amount:GetInt()
	}
end)

registerCallback("destruct", function(self)
	clearholos(self)
end)

-- -----------------------------------------------------------------------------

local function ConsoleMessage(ply, text)
	if ply:IsValid() then
		ply:PrintMessage( HUD_PRINTCONSOLE, text )
	else
		print(text)
	end
end

concommand.Add( "wire_holograms_remove_all", function( ply, com, args )
	if ply:IsValid() and not ply:IsAdmin() then return end

	clearholos_all()
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
			local uid = v:UniqueID()
			if E2HoloRepo[uid] then
				clearholos_all(uid)
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
		local uid
		for _,v in ipairs( player.GetAll() ) do
			if v:SteamID() == steamID then
				uid = v:UniqueID()
				if (E2HoloRepo[uid]) then
					clearholos_all(uid)
					return
				end
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

-- -----------------------------------------------------------------------------

wire_holograms = {} -- This global table is used to share certain functions and variables with UWSVN
wire_holograms.CheckIndex = CheckIndex

registerCallback( "postinit", function()
	timer.Simple( 1, function()
		wire_holograms = nil
	end )
end )
