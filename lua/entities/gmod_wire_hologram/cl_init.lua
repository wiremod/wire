include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_BOTH

local blocked = {}
local scales = {}
local clips = {}

function ENT:Initialize( )
	self:DoScale()

	local ownerid = self:GetNetworkedInt("ownerid")
	self.blocked = blocked[ownerid] or false
end

/******************************************************************************/

local function CheckClip(eidx, cidx)
	clips[eidx] = clips[eidx] or {}
	clips[eidx][cidx] = clips[eidx][cidx] or {}

	return clips[eidx][cidx]
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

function ENT:Draw()
	if self.blocked then return end

	local cliptbl = clips[self:EntIndex()]
	local nclips = 0

	if cliptbl then nclips = table.Count(cliptbl) end

	if nclips > 0 then
		render.EnableClipping( true )

		for _,clip in pairs(cliptbl) do
			if clip.enabled and clip.normal and clip.origin then
				local norm = clip.normal
				local origin = clip.origin

				if !clip.isglobal then
					norm = self:LocalToWorld( norm ) - self:GetPos()
					origin = self:LocalToWorld( origin )
				end

				render.PushCustomClipPlane( norm, norm:Dot( origin ) )
			end
		end
	end

	self.BaseClass.Draw( self )

	if nclips > 0 then
		for i = 1, nclips do
			render.PopCustomClipPlane()
		end

		render.EnableClipping( false )
	end
end

usermessage.Hook("wire_holograms_clip", function( um )
	local eidx = um:ReadShort()

	while eidx != 0 do
		local cidx = um:ReadShort()

		if um:ReadBool() then
			SetClipEnabled(eidx, cidx, um:ReadBool())
		else
			SetClip(eidx, cidx, um:ReadVector(), um:ReadVector(), um:ReadShort() ~= 0)
		end

		eidx = um:ReadShort()
	end
end)

/******************************************************************************/

local function SetScale(entindex, scale)
	scales[entindex] = scale

	local ent = Entity(entindex)

	if ent and ent.DoScale then
		ent:DoScale()
	end
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

usermessage.Hook("wire_holograms_set_scale", function( um )
	local index = um:ReadShort()
	while index ~= 0 do
		local scale = um:ReadVector()

		SetScale(index, scale)
		index = um:ReadShort()
	end
end)

/******************************************************************************/

hook.Add("EntityRemoved", "gmod_wire_hologram", function(ent)
	scales[ent:EntIndex()] = nil
	clips[ent:EntIndex()] = nil
end)

concommand.Add("wire_holograms_block_client",
	function(ply, command, args)
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
	end
)

concommand.Add( "wire_holograms_unblock_client",
	function(ply, command, args)
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
	end
)
