include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_BOTH

local scales = {}
local clips = {}

hook.Add("EntityRemoved", "gmod_wire_hologram", function(ent)
	scales[ent:EntIndex()] = nil
	clips[ent:EntIndex()] = nil
end)

local blocked = {}
concommand.Add("wire_holograms_block_client", function(ply, command, args)
	local toblock
	for _,ply in ipairs(player.GetAll()) do
		if ply:Name() == args[1] then
			toblock = ply
			break
		end
	end
	if not toblock then error("Player not found") end

	local id = toblock:UserID()
	blocked[id] = true
	for _,ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
		if ent:GetNetworkedInt("ownerid") == id then
			ent.blocked = true
		end
	end
end,
function()
	local names = {}
	for _,ply in ipairs(player.GetAll()) do
		table.insert(names, "wire_holograms_block_client \""..ply:Name().."\"")
	end
	table.sort(names)
	return names
end)

concommand.Add("wire_holograms_unblock_client", function(ply, command, args)
	local toblock
	for _,ply in ipairs(player.GetAll()) do
		if ply:Name() == args[1] then
			toblock = ply
			break
		end
	end
	if not toblock then error("Player not found") end

	local id = toblock:UserID()
	blocked[id] = nil
	for _,ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
		if ent:GetNetworkedInt("ownerid") == id then
			ent.blocked = false
		end
	end
end,
function()
	local names = {}
	for _,ply in ipairs(player.GetAll()) do
		if blocked[ply:UserID()] then
			table.insert(names, "wire_holograms_unblock_client \""..ply:Name().."\"")
		end
	end
	table.sort(names)
	return names
end)

function ENT:Initialize( )
	self:DoScale()

	self:SetClipEnabled()
	self:SetClip()

	local ownerid = self:GetNetworkedInt("ownerid")
	self.blocked = blocked[ownerid] or false
end

function ENT:Draw()
	if self.blocked then return end

	local clip = clips[self:EntIndex()]

	if clip and clip.enabled and not clip.isglobal then
		self:SetClip()
	end
	self.BaseClass.Draw(self)
end

function ENT:DoScale()
	local scale = scales[self:EntIndex()] or Vector(1,1,1)

	self:SetModelScale( scale )

	local propmax = self:OBBMaxs()
	local propmin = self:OBBMins()

	propmax.x = scale.x * propmax.x
	propmax.y = scale.y * propmax.y
	propmax.z = scale.z * propmax.z
	propmin.x = scale.x * propmin.x
	propmin.y = scale.y * propmin.y
	propmin.z = scale.z * propmin.z

	self:SetRenderBounds( propmax, propmin )
end

function ENT:SetClipEnabled()
	local clip = clips[self:EntIndex()]

	if clip and clip.enabled ~= nil then
		self:SetRenderClipPlaneEnabled( clip.enabled )
	end
end

function ENT:SetClip()
	local clip = clips[self:EntIndex()]

	if clip and clip.origin then
		local norm = clip.normal
		local origin = clip.origin

		if not clip.isglobal then
			norm = self:LocalToWorld(norm)-self:GetPos()
			origin = self:LocalToWorld(origin)
		end

		self:SetRenderClipPlane(norm, norm:Dot(origin))
	end
end

local function SetScale(entindex, scale)
	scales[entindex] = scale
	local prop = ents.GetByIndex(entindex)
	if prop and prop.DoScale then
		prop:DoScale()
	end
end

usermessage.Hook("wire_holograms_set_scale", function( um )
	local index = um:ReadShort()
	while index ~= 0 do
		local scale = um:ReadVector()

		SetScale(index, scale)
		index = um:ReadShort()
	end
end)

usermessage.Hook("wire_holograms_clip", function( um )
	local idx = um:ReadShort()

	while idx != 0 do
		clips[idx] = clips[idx] or {}
		local clip = clips[idx]
		local ent = ents.GetByIndex(idx)

		if um:ReadBool() then
			clip.enabled = um:ReadBool()

			if ent and ent.SetClipEnabled then
				ent:SetClipEnabled()
			end
		else
			clip.origin = um:ReadVector()
			clip.normal = um:ReadVector()
			clip.isglobal = um:ReadShort() ~= 0

			if ent and ent.SetClip and clip.isglobal then
				ent:SetClip()
			end
		end

		idx = um:ReadShort()
	end
end)
