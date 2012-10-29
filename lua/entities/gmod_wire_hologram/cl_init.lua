include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_BOTH

local blocked = {}
local scale_buffer = {}
local clip_buffer = {}
local vis_buffer = {}

function ENT:Initialize( )
	self:DoScale()

	local ownerid = self:GetNetworkedInt("ownerid")
	self.blocked = blocked[ownerid] or false

	self.clips = {}
	self.visible = true
end

function ENT:SetupClipping()
	local eidx = self:EntIndex()

	if clip_buffer[eidx] != nil then
		table.Merge( self.clips, clip_buffer[eidx] )

		clip_buffer[eidx] = nil
	end

	local nclips = 0

	if self.clips then nclips = table.Count( self.clips ) end

	if nclips > 0 then
		render.EnableClipping( true )

		for _,clip in pairs( self.clips ) do
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
end

function ENT:FinishClipping()
	local nclips = 0

	if self.clips then nclips = table.Count( self.clips ) end

	if nclips > 0 then
		for i = 1, nclips do
			render.PopCustomClipPlane()
		end

		render.EnableClipping( false )
	end
end

function ENT:Draw()
	local eidx = self:EntIndex()

	if self.visible != vis_buffer[eidx] then
		self.visible = vis_buffer[eidx]
	end

	if self.blocked or self.visible == false then return end

	self:SetupClipping()

	if self:GetNWBool( "disable_shading" ) then
		render.SuppressEngineLighting( true )
	end

	self:DrawModel()

	render.SuppressEngineLighting( false )

	self:FinishClipping()
end

/******************************************************************************/

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

net.Receive("wire_holograms_clip", function( netlen )
	local entid = net.ReadUInt(16)

	while entid ~= 0 do
		local clipid = net.ReadUInt(16)
		
		if net.ReadBit() ~= 0 then
			SetClipEnabled(entid, clipid, net.ReadBit())
		else
			SetClip(entid, clipid, net.ReadVector(), net.ReadVector(), net.ReadBit() ~= 0)
		end
		entid = net.ReadUInt(16)
	end
end)

/******************************************************************************/

local function SetScale(entindex, scale)
	scale_buffer[entindex] = scale

	local ent = Entity(entindex)

	if ent and ent.DoScale then
		ent:DoScale()
	end
end

function ENT:DoScale()
	local eidx = self:EntIndex()

	local scale = scale_buffer[eidx] or Vector(1,1,1)

	if self.EnableMatrix then
		local mat = Matrix()
		mat:Scale(scale)
		self:EnableMatrix("RenderMultiply", mat)
	else
		-- Some entities, like ragdolls, cannot be resized with EnableMatrix, so lets average the three components to get a float
		self:SetModelScale((scale.x+scale.y+scale.z)/3,0)
	end
	scale_buffer[eidx] = nil
end

net.Receive("wire_holograms_set_scale", function( netlen )
	local index = net.ReadUInt(16)

	while index ~= 0 do
		SetScale(index, net.ReadVector())
		index = net.ReadUInt(16)
	end
end)

/******************************************************************************/

net.Receive("wire_holograms_set_visible", function( netlen )
	local index = net.ReadUInt(16)

	while index ~= 0 do
		vis_buffer[index] = net.ReadBit() ~= 0
		index = net.ReadUInt(16)
	end
end )

/******************************************************************************/

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
