include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_BOTH

local scales = {}
hook.Add("EntityRemoved", "gmod_wire_hologram", function(ent)
	scales[ent:EntIndex()] = nil
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
	local ownerid = self:GetNetworkedInt("ownerid")
	self.blocked = blocked[ownerid] or false
end

function ENT:Draw()
	if self.blocked then return end
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
