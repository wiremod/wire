-- wire_paths.lua
--
-- This file is implements syncing of wire paths, which are the visual
-- component of wires.
--
-- Conceptually, a wire path has a material, a color, and a non-zero width, as
-- well as as a non-empty polyline along the wire. (Each point in the line
-- has both a parent entity, and a local offset from that entity.)
--

if not WireLib then return end
if WireLib.Paths then return end
WireLib.Paths = {}

if CLIENT then
	net.Receive("WireLib.Paths.TransmitPath", function(length)
		local path = {
			Entity = net.ReadEntity(),
			Name = net.ReadString(),
			Material = net.ReadString(),
			Width = net.ReadFloat(),
			Color = net.ReadColor(),
			Blinking = net.ReadBool(),
			Points = {}
		}

		local num_points = net.ReadUInt(15)
		for i = 1, num_points do
			path.Points[i] = { Entity = net.ReadEntity(), Position = net.ReadVector() }
		end

		if path.Entity.WirePaths == nil then path.Entity.WirePaths = {} end
		path.Entity.WirePaths[path.Name] = path

	end)
	return
end

local paths = setmetatable({}, { __mode = "k", __index = function() return {} end })
local transmit_queues = setmetatable({}, { __mode = "kv", __index = function() return {} end })

-- Add a path to every player's transmit queue
function WireLib.Paths.Add(path)
	paths[ents.Reference(path.Entity)][path.Name] = nil
	for _, player in player.GetAll() do
		table.insert(transmit_queues[ents.Reference(player)], path)
	end
end

function WireLib.Paths.Remove(path)
	paths[ents.Reference(path.Entity)][path.Name] = nil
end

local function TransmitPath(path)
	net.WriteEntity(path.Entity)
	net.WriteString(path.Name)
	net.WriteString(path.Material)
	net.WriteFloat(path.Width)
	net.WriteColor(path.Color)
	net.WriteBool(path.Blinking or false)
	net.WriteUInt(#path.Points, 15)
	for _, point in ipairs(path.Points) do
		net.WriteEntity(point.Entity)
		net.WriteVector(point.Position)
	end
end

timer.Create("WireLib.Paths.ProcessQueue", 0.2, 0, function()
	for player_reference, queue in pairs(transmit_queues) do
		if not next(queue) then continue end
		net.Start("WireLib.Paths")
		while next(queue) and net.BytesWritten() < 63 * 1024 do
			TransmitPath(queue[1])
			table.remove(queue, 1)
		end
		net.Send(player_reference[1])
	end
end)

hook.Add("PlayerInitialSpawn", "WireLib.Paths.PlayerInitialSpawn", function(player)
	local queue = transmit_queues[ents.Reference(player)]
	for _, ent_paths in pairs(paths) do
		for _, path in pairs(ent_paths) do
			queue.insert(path)
		end
	end
end)
