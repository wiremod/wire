AddCSLuaFile()
DEFINE_BASECLASS("base_anim") -- NOTE: Not base_wire_entity! Simpler than that
ENT.PrintName = "Wire Hologram"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "PlayerEnt" )
end

function ENT:GetPlayer()
	local ply = self:GetPlayerEnt()

	if self.steamid == "" then
		if ply:IsValid() then
			self.steamid = ply:SteamID()
		end
	end

	return self:GetPlayerEnt()
end

function ENT:SetPlayer(ply)
	self:SetPlayerEnt(ply)
	self.steamid = ply:SteamID()
end

if CLIENT then
	local blocked = {}
	local scale_buffer = {}
	local bone_scale_buffer = {}
	local clip_buffer = {}
	local vis_buffer = {}
	local player_color_buffer = {}

	net.Receive( "holoQueueClear", function()
		local id = net.ReadUInt(16)

		--Holo Clips
		clip_buffer[id] = nil

		--Holo Scales
		scale_buffer[id] = nil

		--Holo Bone Scales
		bone_scale_buffer[id] = nil

		--Holo Enable/Disable
		vis_buffer[id] = nil

		--Holo Colors
		player_color_buffer[id] = nil
	end)

	function ENT:Initialize()
		self.steamid = ""
		self.bone_scale = {}
		self:DoScale()
		self:GetPlayer() -- populate steamid
		self.blocked = blocked[self.steamid]~=nil

		self.clips = {}
		self:DoClip()
		self:DoVisible()
		self:DoPlayerColor()
	end

	hook.Add("PlayerBindPress", "wire_hologram_scale_setup", function() -- For initial spawn
		for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
			if ent:IsValid() and ent.DoScale then
				ent:DoScale()
				ent:DoClip()
				ent:DoVisible()
				ent:DoPlayerColor()
			end
		end
		hook.Remove("PlayerBindPress", "wire_hologram_scale_setup")
	end)

	local EntityMeta = FindMetaTable("Entity")

	local function SetupClipping(selfTbl)
		selfTbl.oldClipState = render.EnableClipping(true)

		for _, clip in pairs(selfTbl.clips) do
			if clip.enabled and clip.normal and clip.origin then
				local norm = clip.normal
				local origin = clip.origin
				local id = clip.localentid

				if id then
					local localent = Entity(id)

					if EntityMeta.IsValid(localent) then
						norm = EntityMeta.LocalToWorld(localent, norm) - EntityMeta.GetPos(localent)
						origin = EntityMeta.LocalToWorld(localent, origin)
					end
				end

				render.PushCustomClipPlane(norm, norm:Dot(origin))
			end
		end
	end

	local function FinishClipping(selfTbl)
		for _, clip in pairs(selfTbl.clips) do
			if clip.enabled and clip.normal and clip.origin then -- same logic as in SetupClipping
				render.PopCustomClipPlane()
			end
		end

		render.EnableClipping(selfTbl.oldClipState)
	end

	function ENT:Draw()
		local selfTbl = EntityMeta.GetTable(self)
		if selfTbl.blocked or selfTbl.notvisible then return end

		local _, _, _, alpha = EntityMeta.GetColor4Part(self)
		if alpha ~= 255 then
			selfTbl.RenderGroup = RENDERGROUP_BOTH
		else
			selfTbl.RenderGroup = RENDERGROUP_OPAQUE
		end

		local hasclips = next(selfTbl.clips)

		if hasclips then
			SetupClipping(selfTbl)
		end

		local invert_model = EntityMeta.GetNWInt(self, "invert_model")
		render.CullMode(invert_model)

		if EntityMeta.GetNWBool(self, "disable_shading") then
			render.SuppressEngineLighting(true)
			EntityMeta.DrawModel(self)
			render.SuppressEngineLighting(false)
		else
			EntityMeta.DrawModel(self)
		end

		if invert_model ~= 0 then
			render.CullMode(0)
		end

		if hasclips then
			FinishClipping(selfTbl)
		end
	end

	-- -----------------------------------------------------------------------------

	function ENT:DoClip()
		local eidx = self:EntIndex()

		if clip_buffer[eidx] ~= nil then
			table.Merge(self.clips, clip_buffer[eidx])
			clip_buffer[eidx] = nil
		end
	end

	local function CheckClip(eidx, cidx)
		clip_buffer[eidx] = clip_buffer[eidx] or {}
		clip_buffer[eidx][cidx] = clip_buffer[eidx][cidx] or {}

		return clip_buffer[eidx][cidx]
	end

	local function SetClipEnabled(eidx, cidx, enabled)
		local clip = CheckClip(eidx, cidx)

		clip.enabled = enabled
	end

	local function SetClip(eidx, cidx, origin, norm, localentid)
		local clip = CheckClip(eidx, cidx)

		clip.normal = norm
		clip.origin = origin

		if localentid ~= 0 then
			clip.localentid = localentid
		else
			clip.localentid = nil
		end
	end

	net.Receive("wire_holograms_clip", function(netlen)
		while true do
			local entid = net.ReadUInt(MAX_EDICT_BITS)
			if entid == 0 then return end -- stupid hack to not include amount of entities in the message. feel free to rework this.

			local clipid = net.ReadUInt(4)

			if net.ReadBool() then
				SetClipEnabled(entid, clipid, net.ReadBool())
			else
				SetClip(entid, clipid, net.ReadVector(), net.ReadVector(), net.ReadUInt(MAX_EDICT_BITS))
			end

			local ent = Entity(entid)
			if ent and ent.DoClip then
				ent:DoClip()
			end
		end
	end)

	-- -----------------------------------------------------------------------------

	local function SetScale(entindex, scale)
		scale_buffer[entindex] = scale

		local ent = Entity(entindex)

		if ent and ent.DoScale then
			ent:DoScale()
		end
	end

	local function SetBoneScale(entindex, bindex, scale)
		if bone_scale_buffer[entindex] == nil then bone_scale_buffer[entindex] = {} end

		if bindex == -1 then
			bone_scale_buffer[entindex] = nil
		else
			bone_scale_buffer[entindex][bindex] = scale
		end

		local ent = Entity(entindex)

		if ent and ent.DoScale then
			if bindex == -1 then ent.bone_scale = {} end -- reset bone scale
			ent:DoScale()
		end
	end

	function ENT:DoScale()
		local eidx = self:EntIndex()

		if scale_buffer[eidx] ~= nil then
			self.scale = scale_buffer[eidx]
			scale_buffer[eidx] = nil
		end

		if bone_scale_buffer[eidx] ~= nil then
			for b, s in pairs(bone_scale_buffer[eidx]) do
				self.bone_scale[b] = s
			end
			bone_scale_buffer[eidx] = {}
		end

		local scale = self.scale or Vector(1, 1, 1)

		if self.EnableMatrix then
			local mat = Matrix()
			mat:Scale(Vector(scale.x, scale.y, scale.z))
			self:EnableMatrix("RenderMultiply", mat)
		else
			-- Some entities, like ragdolls, cannot be resized with EnableMatrix, so lets average the three components to get a float
			self:SetModelScale((scale.x + scale.y + scale.z) / 3, 0)
		end

		if not table.IsEmpty( self.bone_scale ) then
			local count = self:GetBoneCount() or -1

			for i = count, 0, -1 do
				local bone_scale = self.bone_scale[i] or Vector(1,1,1)
				self:ManipulateBoneScale(i, bone_scale) -- Note: Using ManipulateBoneScale currently causes RenderBounds to be reset every frame!
			end
		end

		local propmax = self:OBBMaxs()
		local propmin = self:OBBMins()
		self:SetRenderBounds(Vector(scale.x * propmin.x, scale.y * propmin.y, scale.z * propmin.z),Vector(scale.x * propmax.x, scale.y * propmax.y, scale.z * propmax.z))
	end

	net.Receive("wire_holograms_set_scale", function(netlen)
		local index = net.ReadUInt(MAX_EDICT_BITS)

		while index ~= 0 do
			SetScale(index, Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat()))
			index = net.ReadUInt(MAX_EDICT_BITS)
		end
	end)

	net.Receive("wire_holograms_set_bone_scale", function(netlen)
		local index = net.ReadUInt(MAX_EDICT_BITS)
		local bindex = net.ReadUInt(9) - 1 -- using -1 to get negative -1 for reset

		while index ~= 0 do
			SetBoneScale(index, bindex, Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat()))
			index = net.ReadUInt(MAX_EDICT_BITS)
			bindex = net.ReadUInt(9) - 1
		end
	end)

	-- -----------------------------------------------------------------------------

	function ENT:DoVisible()
		local eidx = self:EntIndex()

		if vis_buffer[eidx] ~= nil then
			self.notvisible = vis_buffer[eidx]
			vis_buffer[eidx] = nil
		end
	end

	net.Receive("wire_holograms_set_visible", function(netlen)
		local index = net.ReadUInt(MAX_EDICT_BITS)

		while index ~= 0 do

			local ent = Entity(index)
			if ent and ent.DoVisible then
				ent.notvisible = net.ReadBit() == 0
			else
				vis_buffer[index] = net.ReadBit() == 0
			end

			index = net.ReadUInt(MAX_EDICT_BITS)
		end
	end)

	-- -----------------------------------------------------------------------------

	local function SetPlayerColor(entindex, color)
		local ent = Entity(entindex)
		-- For reference, here's why this works:
		-- https://github.com/garrynewman/garrysmod/blob/master/garrysmod/lua/matproxy/player_color.lua
		function ent:GetPlayerColor()
			return color
		end
	end

	function ENT:DoPlayerColor()
		local eidx = self:EntIndex()
		if player_color_buffer[eidx] ~= nil then
			SetPlayerColor(eidx, player_color_buffer[eidx])
			player_color_buffer[eidx] = nil
		end
	end

	net.Receive("wire_holograms_set_player_color", function(netlen)
		local index = net.ReadUInt(MAX_EDICT_BITS)

		while index ~= 0 do
			local ent = Entity(index)
			if IsValid(ent) and ent.DoPlayerColor then
				SetPlayerColor(index, net.ReadVector())
			else
				player_color_buffer[index] = net.ReadVector()
			end

			index = net.ReadUInt(MAX_EDICT_BITS)
		end
	end)

	-- -----------------------------------------------------------------------------

	local function checkSteamid(steamid)
		return string.match(steamid, "STEAM_%d+:%d+:%d+")
	end
	concommand.Add("wire_holograms_block_client",
		function(ply, command, args)
			if not args[1] then print("Invalid steamid") return end

			local toblock = checkSteamid(args[1])
			if not toblock then print("Invalid steamid") return end

			blocked[toblock] = true
			for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
				if ent.steamid == toblock then
					ent.blocked = true
				end
			end
		end,
		function(cmd)
			local help = {}
			for _, ply in ipairs(player.GetAll()) do
				table.insert(help, cmd.." \""..ply:SteamID().."\" // "..ply:Name())
			end
			return help
		end)

	concommand.Add("wire_holograms_unblock_client",
		function(ply, command, args)
			local toblock = checkSteamid(args[1])
			if not toblock then print("Invalid SteamId") return end
			if not blocked[toblock] then print("This steamid isn't blocked") return end

			blocked[toblock] = nil
			for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
				if ent.steamid == toblock then
					ent.blocked = false
				end
			end
		end,
		function(cmd)
			local help = {}
			for steamid in pairs(blocked) do
				local ply = player.GetBySteamID(steamid)
				local name = ply and ply:GetName() or "(disconnected)"
				table.insert(help, cmd.." \""..steamid.."\" // "..name)
			end
			return help
		end)

	-- Severe lagspikes can detach the source entity from its lua, so we need to reapply things when its reattached
	hook.Add("NetworkEntityCreated", "wire_hologram_rescale", function(ent)
		if ent.scale and ent.DoScale then
			-- ent.scale isn't present on newly created holograms, only old ones that've been hit by a lagspike
			ent:DoScale()
			ent:DoClip()
			ent:DoVisible()
			ent:DoPlayerColor()
		end
	end)

	return -- No more client
end

-- Server
util.AddNetworkString( "holoQueueClear" )

function ENT:OnRemove()
	-- Let all clients know this holo was removed, incase it was in a different PVS from them since creation
	net.Start( "holoQueueClear" )
		net.WriteUInt( self:EntIndex(), 16 )
	net.Broadcast()
end

function ENT:Think()
	if self.Animated then
		self:NextThink(CurTime())
		return true
	end
end

function ENT:Initialize()
	self.steamid = ""
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(false)
end
