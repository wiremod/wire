AddCSLuaFile()
DEFINE_BASECLASS("base_anim") -- NOTE: Not base_wire_entity! Simpler than that
ENT.PrintName = "Wire Hologram"
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetPlayer(ply)
	self:SetVar("Founder", ply)
	self:SetVar("FounderIndex", ply:UniqueID())

	self:SetNetworkedString("FounderName", ply:Nick())
end

function ENT:GetPlayer()
	return self:GetVar("Founder", NULL)
end

if CLIENT then
	local blocked = {}
	local scale_buffer = {}
	local bone_scale_buffer = {}
	local clip_buffer = {}
	local vis_buffer = {}

	function ENT:Initialize()
		self.bone_scale = {}
		self:DoScale()
		local ownerid = self:GetNetworkedInt("ownerid")
		self.blocked = blocked[ownerid] or false

		self.clips = {}
	end

	hook.Add("PlayerBindPress", "wire_hologram_scale_setup", function() -- For initial spawn
		for _, ent in pairs(ents.FindByClass("gmod_wire_hologram")) do
			if ent:IsValid() and ent.DoScale then
				ent:DoScale()
			end
		end
		hook.Remove("PlayerBindPress", "wire_hologram_scale_setup")
	end)

	function ENT:SetupClipping()
		local eidx = self:EntIndex()

		if clip_buffer[eidx] ~= nil then
			table.Merge(self.clips, clip_buffer[eidx])

			clip_buffer[eidx] = nil
		end


		if self.clips and next(self.clips) then
			self.oldClipState = render.EnableClipping(true)

			for _, clip in pairs(self.clips) do
				if clip.enabled and clip.normal and clip.origin then
					local norm = clip.normal
					local origin = clip.origin

					if not clip.isglobal then
						norm = self:LocalToWorld(norm) - self:GetPos()
						origin = self:LocalToWorld(origin)
					end

					render.PushCustomClipPlane(norm, norm:Dot(origin))
				end
			end
		end
	end

	function ENT:FinishClipping()
		if self.clips and next(self.clips) then
			for _, clip in pairs(self.clips) do
				render.PopCustomClipPlane()
			end

			render.EnableClipping(self.oldClipState)
		end
	end

	function ENT:Draw()
		local eidx = self:EntIndex()

		if vis_buffer[eidx] ~= nil then
			self.visible = vis_buffer[eidx]
			vis_buffer[eidx] = nil
		end

		if self.blocked or self.visible == false then return end -- self.visible and vis_buffer[] is nil by default, but nil != false

		if self:GetColor().a ~= 255 then
			self.RenderGroup = RENDERGROUP_BOTH
		else
			self.RenderGroup = RENDERGROUP_OPAQUE
		end

		self:SetupClipping()

		if self:GetNWBool("disable_shading") then
			render.SuppressEngineLighting(true)
			self:DrawModel()
			render.SuppressEngineLighting(false)
		else
			self:DrawModel()
		end

		self:FinishClipping()
	end

	-- -----------------------------------------------------------------------------

	local function CheckClip(eidx, cidx)
		clip_buffer[eidx] = clip_buffer[eidx] or {}
		clip_buffer[eidx][cidx] = clip_buffer[eidx][cidx] or {}

		return clip_buffer[eidx][cidx]
	end

	local function SetClipEnabled(eidx, cidx, enabled)
		local clip = CheckClip(eidx, cidx)

		clip.enabled = enabled
	end

	local function SetClip(eidx, cidx, origin, norm, isglobal)
		local clip = CheckClip(eidx, cidx)

		clip.normal = norm
		clip.origin = origin
		clip.isglobal = isglobal
	end

	net.Receive("wire_holograms_clip", function(netlen)
		local entid = net.ReadUInt(16)

		while entid ~= 0 do
			local clipid = net.ReadUInt(4)

			if net.ReadBit() ~= 0 then
				SetClipEnabled(entid, clipid, net.ReadBit())
			else
				SetClip(entid, clipid, net.ReadVector(), Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat()), net.ReadBit() ~= 0)
			end
			entid = net.ReadUInt(16)
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

		local count = self:GetBoneCount() or -1
		if count > 1 then
			for i = 0, count do
				self:ManipulateBoneScale(i, self.bone_scale[i] or scale)
			end
		elseif self.EnableMatrix then
			local mat = Matrix()
			mat:Scale(Vector(scale.y, scale.x, scale.z)) -- Note: We're swapping X and Y because RenderMultiply isn't consistant with the rest of source
			self:EnableMatrix("RenderMultiply", mat)
		else
			-- Some entities, like ragdolls, cannot be resized with EnableMatrix, so lets average the three components to get a float
			self:SetModelScale((scale.x + scale.y + scale.z) / 3, 0)
		end

		local propmax = self:OBBMaxs()
		local propmin = self:OBBMins()
		self:SetRenderBounds(Vector(scale.x * propmax.x, scale.y * propmax.y, scale.z * propmax.z), Vector(scale.x * propmin.x, scale.y * propmin.y, scale.z * propmin.z))
	end

	net.Receive("wire_holograms_set_scale", function(netlen)
		local index = net.ReadUInt(16)

		while index ~= 0 do
			SetScale(index, Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat()))
			index = net.ReadUInt(16)
		end
	end)

	net.Receive("wire_holograms_set_bone_scale", function(netlen)
		local index = net.ReadUInt(16)
		local bindex = net.ReadUInt(16) - 1 -- using -1 to get negative -1 for reset

		while index ~= 0 do
			SetBoneScale(index, bindex, Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat()))
			index = net.ReadUInt(16)
			bindex = net.ReadUInt(16) - 1
		end
	end)

	-- -----------------------------------------------------------------------------

	net.Receive("wire_holograms_set_visible", function(netlen)
		local index = net.ReadUInt(16)

		while index ~= 0 do
			vis_buffer[index] = net.ReadBit() ~= 0
			index = net.ReadUInt(16)
		end
	end)

	-- -----------------------------------------------------------------------------

	concommand.Add("wire_holograms_block_client",
		function(ply, command, args)
			local toblock
			for _, ply in ipairs(player.GetAll()) do
				if ply:Name() == args[1] then
					toblock = ply
					break
				end
			end
			if not toblock then error("Player not found") end

			local id = toblock:UserID()
			blocked[id] = true
			for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
				if ent:GetNetworkedInt("ownerid") == id then
					ent.blocked = true
				end
			end
		end,
		function()
			local names = {}
			for _, ply in ipairs(player.GetAll()) do
				table.insert(names, "wire_holograms_block_client \"" .. ply:Name() .. "\"")
			end
			table.sort(names)
			return names
		end)

	concommand.Add("wire_holograms_unblock_client",
		function(ply, command, args)
			local toblock
			for _, ply in ipairs(player.GetAll()) do
				if ply:Name() == args[1] then
					toblock = ply
					break
				end
			end
			if not toblock then error("Player not found") end

			local id = toblock:UserID()
			blocked[id] = nil
			for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
				if ent:GetNetworkedInt("ownerid") == id then
					ent.blocked = false
				end
			end
		end,
		function()
			local names = {}
			for _, ply in ipairs(player.GetAll()) do
				if blocked[ply:UserID()] then
					table.insert(names, "wire_holograms_unblock_client \"" .. ply:Name() .. "\"")
				end
			end
			table.sort(names)
			return names
		end)

	return -- No more client
end

-- Server

function ENT:Initialize()
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(false)
end
