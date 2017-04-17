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

local function add_queue( queue, ply, data )
	local plyqueue = queue[ply]
	if not plyqueue then
		plyqueue = {}
		queue[ply] = plyqueue
	end
	if #plyqueue==wire_holograms_max:GetInt() then return end
	plyqueue[#plyqueue+1] = data
end

local function flush_scale_queue(queue, recipient)
	if not queue then queue = scale_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_set_scale")
		for _, plyqueue in pairs(queue) do
			for _,Holo,scale in ipairs_map(plyqueue, unpack) do
				net.WriteUInt(Holo.ent:EntIndex(), 16)
				net.WriteFloat(scale.x)
				net.WriteFloat(scale.y)
				net.WriteFloat(scale.z)
			end
		end
		net.WriteUInt(0, 16)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_bone_scale_queue(queue, recipient)
	if not queue then queue = bone_scale_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_set_bone_scale")
	for _, plyqueue in pairs(queue) do
		for _,Holo,bone,scale in ipairs_map(plyqueue, unpack) do
			net.WriteUInt(Holo.ent:EntIndex(), 16)
			net.WriteUInt(bone + 1, 16) -- using +1 to be able reset holo bones scale with -1 and not use signed int
			net.WriteFloat(scale.x)
			net.WriteFloat(scale.y)
			net.WriteFloat(scale.z)
		end
	end
	net.WriteUInt(0, 16)
	net.WriteUInt(0, 16)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_clip_queue(queue, recipient)
	if not queue then queue = clip_queue end
	if not next(queue) then return end

	net.Start("wire_holograms_clip")
		for _, plyqueue in pairs(queue) do
			for _,Holo,clip in ipairs_map(plyqueue, unpack) do
				if clip and clip.index then
					net.WriteUInt(Holo.ent:EntIndex(), 16)
					net.WriteUInt(clip.index, 4) -- 4: absolute highest wire_holograms_max_clips is thus 16
					if clip.enabled ~= nil then
						net.WriteBit(true)
						net.WriteBit(clip.enabled)
					elseif clip.origin and clip.normal and clip.isglobal then
						net.WriteBit(false)
						net.WriteVector(clip.origin)
						net.WriteFloat(clip.normal.x) net.WriteFloat(clip.normal.y) net.WriteFloat(clip.normal.z)
						net.WriteBit(clip.isglobal ~= 0)
					end
				end
			end
		end
		net.WriteUInt(0, 16)
	if recipient then net.Send(recipient) else net.Broadcast() end
end

local function flush_vis_queue()
	if not next(vis_queue) then return end

	for ply,tbl in pairs( vis_queue ) do
		if IsValid( ply ) and #tbl > 0 then
			net.Start("wire_holograms_set_visible")
				for _,Holo,visible in ipairs_map(tbl, unpack) do
					net.WriteUInt(Holo.ent:EntIndex(), 16)
					net.WriteBit(visible)
				end
				net.WriteUInt(0, 16)
			net.Send(ply)
		end
	end
end

local function flush_player_color_queue()
	if not next(player_color_queue) then return end

	net.Start("wire_holograms_set_player_color")
		for _, plyqueue in pairs(player_color_queue) do
			for _,Holo,color in ipairs_map(plyqueue, unpack) do
				net.WriteUInt(Holo.ent:EntIndex(), 16)
				net.WriteVector(color)
			end
		end
		net.WriteUInt(0, 16)
	net.Broadcast()
end

registerCallback("postexecute", function(self)
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

local function rescale(Holo, scale, bone)
	local maxval = wire_holograms_size_max:GetInt()
	local minval = -maxval

	if scale then
		local x = math.Clamp( scale[1], minval, maxval )
		local y = math.Clamp( scale[2], minval, maxval )
		local z = math.Clamp( scale[3], minval, maxval )
		local scale = Vector(x, y, z)

		if Holo.scale ~= scale then
			add_queue( scale_queue, Holo.e2owner, { Holo, scale } )
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

			add_queue( bone_scale_queue, Holo.e2owner, { Holo, bidx, scale } )
			Holo.bone_scale[bidx] =  scale
		else  -- reset holo bone scale
			add_queue( bone_scale_queue, Holo.e2owner, { Holo, -1, Vector(0,0,0) } )
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
		clip.isglobal = clip.isglobal or false

		return clip
	end

	return nil
end

local function enable_clip(Holo, idx, enabled)
	local clip = check_clip(Holo, idx)

	if clip and clip.enabled ~= enabled then
		clip.enabled = enabled

		add_queue( clip_queue, Holo.e2owner, { Holo,
			{
				index = idx,
				enabled = enabled
			}}
		)
	end
end

local function set_clip(Holo, idx, origin, normal, isglobal)
	local clip = check_clip(Holo, idx)

	if clip and (clip.origin ~= origin or clip.normal ~= normal or clip.isglobal ~= isglobal) then
		clip.origin = origin
		clip.normal = normal
		clip.isglobal = isglobal

		add_queue( clip_queue, Holo.e2owner, { Holo,
			{
				index = idx,
				origin = origin,
				normal = normal,
				isglobal = isglobal
			}}
		)
	end
end

local function set_visible(Holo, players, visible)
	if not Holo.visible then Holo.visible = {} end
	visible = (visible == 1) or (visible == true)
	for _,ply in pairs( players ) do
		if IsValid( ply ) and ply:IsPlayer() and Holo.visible[ply] ~= visible then
			Holo.visible[ply] = visible
			add_queue( vis_queue, ply, { Holo, visible } )
		end
	end
end

local function reset_clholo(Holo, scale)
	if Holo.clips then
		for cidx, clip in pairs(Holo.clips) do
			if clip.enabled then
				add_queue(clip_queue, Holo.e2owner, { Holo,
					{
						index = cidx,
						enabled = false
					}}
				)
			end
		end
		Holo.clips = {}
	end
	rescale(Holo, scale, {})
	if Holo.visible then
		for ply, state in pairs(Holo.visible) do
			if not state then
				add_queue(vis_queue, ply, { Holo, true })
			end
		end
		Holo.visible = {}
	end
end

local function set_player_color(Holo, color)
	add_queue(player_color_queue, Holo.e2owner, { Holo, color })
end

hook.Add( "PlayerInitialSpawn", "wire_holograms_set_vars", function(ply)
	local s_queue = {}
	local b_s_queue = {}
	local c_queue = {}

	for pl_uid,rep in pairs( E2HoloRepo ) do
		for k,Holo in pairs( rep ) do
			if Holo and IsValid(Holo.ent) then
				local clips = Holo.clips
				local scale = Holo.scale
				local bone_scales = Holo.bone_scale

				table.insert(s_queue, { Holo, scale })

				if bone_scales and table.Count(bone_scales) > 0 then
					for bidx,b_scale in pairs(bone_scales) do
						table.insert(b_s_queue, { Holo, bidx, b_scale })
					end
				end

				if clips and table.Count(clips) > 0 then
					for cidx,clip in pairs(clips) do
						if clip.enabled then
							table.insert(c_queue, {
								Holo,
								{
									index = cidx,
									enabled = clip.enabled
								}
							} )
						end

						if clip.origin and clip.normal and clip.isglobal ~= nil then
							table.insert(c_queue, {
								Holo,
								{
									index = cidx,
									origin = clip.origin,
									normal = clip.normal,
									isglobal = clip.isglobal
								}
							} )
						end
					end
				end
			end
		end
	end

	flush_scale_queue({[ply] = s_queue}, ply)
	flush_bone_scale_queue({[ply] = b_s_queue}, ply)
	flush_clip_queue({[ply] = c_queue}, ply)
end)

-- -----------------------------------------------------------------------------

local function MakeHolo(Player, Pos, Ang, model)
	local prop = ents.Create( "gmod_wire_hologram" )
	E2Lib.setPos(prop, Pos)
	E2Lib.setAng(prop, Ang)
	prop:SetModel(model)
	prop:SetPlayer(Player)
	prop:SetNWInt("ownerid", Player:UserID())

	return prop
end

-- Returns the hologram with the given index or nil if it doesn't exist.
local function CheckIndex(self, index)
	index = index - index % 1
	local Holo
	if index<0 then
		Holo = E2HoloRepo[self.uid][-index]
	else
		Holo = self.data.holos[index]
	end
	if not Holo or not IsValid(Holo.ent) then return nil end
	return Holo
end

-- Sets the given index to the given hologram.
local function SetIndex(self, index, Holo)
	index = index - index % 1
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

	local Holo = CheckIndex(self, index)
	if not Holo then
		Holo = {}
		SetIndex(self, index, Holo)
	end

	local prop

	if IsValid(Holo.ent) then
		prop = Holo.ent
		E2Lib.setPos(prop, pos)
		E2Lib.setAng(prop, ang)
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
	if color then prop:SetColor(Color(color[1],color[2],color[3],255)) end

	reset_clholo(Holo, scale) -- Reset scale, clips, and visible status

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
	for index,Holo in pairs(self.data.holos) do
		if IsValid(Holo.ent) then Holo.ent:Remove() end
	end

	-- delete global holos owned by this chip
	local rep = E2HoloRepo[self.uid]
	if not rep then return end
	for index,Holo in ipairs(rep) do
		if Holo.e2owner == self then
			if IsValid(Holo.ent) then Holo.ent:Remove() end
		end
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
			Holo.ent:Remove()
		end
	end

	PlayerAmount[ply_uid] = 0
end

-- -----------------------------------------------------------------------------

__e2setcost(20) -- temporary



e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color, string model)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color, model)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang, vector color)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang, color)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale, angle ang)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	position = Vector(position[1], position[2], position[3])
	ang = Angle(ang[1], ang[2], ang[3])
	local ret = CreateHolo(self, index, position, scale, ang)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position, vector scale)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position, scale)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index, vector position)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	position = Vector(position[1],position[2],position[3])
	local ret = CreateHolo(self, index, position)
	if IsValid(ret) then return ret end
end

e2function entity holoCreate(index)
	if not checkOwner(self) then return end
	if BlockList[self.player:SteamID()] == true or CheckSpawnTimer( self ) == false then return end
	local Holo = CheckIndex(self, index)
	if not Holo and PlayerAmount[self.uid] >= wire_holograms_max:GetInt() then return end

	local ret = CreateHolo(self, index)
	if IsValid(ret) then return ret end
end

e2function void holoDelete(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if IsValid(Holo.ent) then
		Holo.ent:Remove()
	end
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
	Holo.ent:SetColor(Color(color[1],color[2],color[3],255))
	if string.lower(material) ~= "pp/copy" then
		Holo.ent:SetMaterial(material)
	end

	reset_clholo(Holo, scale) -- Reset scale, clips, and visible status
end

__e2setcost(5)

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

__e2setcost(5) -- temporary

e2function void holoScale(index, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	rescale(Holo, scale)
end

e2function vector holoScale(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return {0,0,0} end

	return Holo.scale or {0,0,0} -- TODO: maybe {1,1,1}?
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
	if not Holo then return {0,0,0} end

	local scale = Holo.scale or {0,0,0} -- TODO: maybe {1,1,1}?

	local propsize = Holo.ent:OBBMaxs()-Holo.ent:OBBMins()

	return Vector(scale[1] * propsize.x, scale[2] * propsize.y, scale[3] * propsize.z)
end


e2function void holoBoneScale(index, boneindex, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	rescale(Holo, nil, {boneindex, scale})
end

e2function void holoBoneScale(index, string bone, vector scale)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	local boneindex = Holo.ent:LookupBone(bone)
	if boneindex == nil then return end

	rescale(Holo, nil, {boneindex, scale})
end

e2function vector holoBoneScale(index, boneindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return {0,0,0} end
	if table.Count(Holo.bone_scale) <= 0 then return {0,0,0} end

	for bidx,b_scale in pairs(Holo.bone_scale) do
    	if bidx == boneindex then return b_scale end
	end

	return {0,0,0}
end

e2function vector holoBoneScale(index, string bone)
	local Holo = CheckIndex(self, index)
	if not Holo then return {0,0,0} end
	if table.Count(Holo.bone_scale) <= 0 then return {0,0,0} end
	local boneindex = Holo.ent:LookupBone(bone)
	if boneindex == nil then return {0,0,0} end

	for bidx,b_scale in pairs(Holo.bone_scale) do
		if bidx == boneindex then return b_scale end
	end

	return {0,0,0}
end

e2function number holoClipsAvailable()
	return wire_holograms_max_clips:GetInt()
end

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

	set_clip(Holo, 1, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), isglobal)
end

e2function void holoClip(index, clipidx, vector origin, vector normal, isglobal)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	set_clip(Holo, clipidx, Vector(origin[1], origin[2], origin[3]), Vector(normal[1], normal[2], normal[3]), isglobal)
end

e2function void holoPos(index, vector position)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	E2Lib.setPos(Holo.ent, Vector(position[1],position[2],position[3]))
end

e2function void holoAng(index, angle ang)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	E2Lib.setAng(Holo.ent, Angle(ang[1],ang[2],ang[3]))
end

-- -----------------------------------------------------------------------------

e2function void holoColor(index, vector color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetColor(Color(color[1],color[2],color[3],Holo.ent:GetColor().a))
end

e2function void holoColor(index, vector4 color)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetColor(Color(color[1],color[2],color[3],color[4]))
	Holo.ent:SetRenderMode(Holo.ent:GetColor().a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
end

e2function void holoColor(index, vector color, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetColor(Color(color[1],color[2],color[3],alpha))
	Holo.ent:SetRenderMode(Holo.ent:GetColor().a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
end

e2function void holoAlpha(index, alpha)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local c = Holo.ent:GetColor()
	c.a = alpha
	Holo.ent:SetColor(c)
	Holo.ent:SetRenderMode(Holo.ent:GetColor().a == 255 and RENDERMODE_NORMAL or RENDERMODE_TRANSALPHA)
end

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

-- -----------------------------------------------------------------------------

e2function array holoModelList()
	local mlist = {}

	for k,_ in pairs( ModelList ) do
	    mlist[#mlist + 1] = k
	end

	return mlist
end

e2function number holoModelAny()
	return wire_holograms_modelany:GetInt()
end

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
	if string.lower(material) == "pp/copy" then return end

	Holo.ent:SetMaterial(material)
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
local function Parent_Hologram(holo, ent, bone, attachment)
	if ent:GetParent() and ent:GetParent():IsValid() and ent:GetParent() == holo.ent then return end

	holo.ent:SetParent(ent)

	if bone ~= nil then
		holo.ent:SetParentPhysNum(bone)
	end
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

e2function void holoParent(index, otherindex)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	local Holo2 = CheckIndex(self, otherindex)
	if not Holo2 then return end

	if not Check_Parents(Holo.ent, Holo2.ent) then return end

	Parent_Hologram(Holo, Holo2.ent, nil, nil)
end

e2function void holoParent(index, entity ent)
	if not IsValid(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	if not Check_Parents(Holo.ent, ent) then return end

	Parent_Hologram(Holo, ent, 0, nil)
end

e2function void holoParent(index, bone b)
	local ent, boneindex = E2Lib.isValidBone(b)
	if not ent then return end

	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Parent_Hologram(Holo, ent, boneindex, nil)
end

e2function void holoParentAttachment(index, entity ent, string attachmentName)
	if not IsValid(ent) then return end
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Parent_Hologram(Holo, ent, nil, attachmentName)
end

e2function void holoUnparent(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	Holo.ent:SetParent(nil)
	Holo.ent:SetParentPhysNum(0)
end

-- -----------------------------------------------------------------------------

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
				for k2,v2 in pairs( E2HoloRepo[uid] ) do
					if v2 and IsValid(v2.ent) then
						v2.ent:Remove()
						PlayerAmount[uid] = PlayerAmount[uid] - 1
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
		local uid
		for _,v in pairs( player.GetAll() ) do
			if v:SteamID() == steamID then
				uid = v:UniqueID()
				if (E2HoloRepo[uid]) then
					for k2,v2 in pairs( E2HoloRepo[uid] ) do
						if v2 and IsValid(v2.ent) then
							v2.ent:Remove()
							PlayerAmount[uid] = PlayerAmount[uid] - 1
						end
					end
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
