-- wire_paths.lua
--
-- This file implements syncing of wire paths, which are the visual
-- component of wires.
--
-- Conceptually, a wire path has a material, a color, and a non-zero width, as
-- well as as a non-empty polyline along the wire. (Each point in the line
-- has both a parent entity, and a local offset from that entity.)
--

if not WireLib then return end

if CLIENT then
	net.Receive("WireLib.Paths.TransmitPath", function(length)
		local path = {
			Path = {}
		}
		path.Entity = net.ReadEntity()
		if not path.Entity:IsValid() then return end
		path.Name = net.ReadString()
		path.Width = net.ReadFloat()
		if path.Width<=0 then
			if path.Entity.WirePaths then
				path.Entity.WirePaths[path.Name] = nil
			end
			return
		end
		path.StartPos = net.ReadVector()
		path.Material = net.ReadString()
		path.Color = net.ReadColor()

		local num_points = net.ReadUInt(16)
		for i = 1, num_points do
			path.Path[i] = { Entity = net.ReadEntity(), Pos = net.ReadVector() }
		end

		if path.Entity.WirePaths == nil then path.Entity.WirePaths = {} end
		path.Entity.WirePaths[path.Name] = path

	end)
	return
end

WireLib.Paths = {}
local transmit_queues = WireLib.RegisterPlayerTable(setmetatable({}, { __index = function(t,p) t[p] = {} return t[p] end }))
util.AddNetworkString("WireLib.Paths.RequestPaths")
util.AddNetworkString("WireLib.Paths.TransmitPath")

net.Receive("WireLib.Paths.RequestPaths", function(length, ply)
	local ent = net.ReadEntity()
	if ent:IsValid() and ent.Inputs then
		for name, input in pairs(ent.Inputs) do
			if input.Src then
				WireLib.Paths.Add(input, ply)
			end
		end
	end
end)

local function TransmitPath(input, ply)
	net.Start("WireLib.Paths.TransmitPath")
	local color = input.Color
	net.WriteEntity(input.Entity)
	net.WriteString(input.Name)
	if not input.Src or input.Width<=0 then
		net.WriteFloat(0)
	else
		net.WriteFloat(input.Width)
		net.WriteVector(input.StartPos)
		net.WriteString(input.Material)
		net.WriteColor(Color(color.r or 255, color.g or 255, color.b or 255, color.a or 255))
		net.WriteUInt(#input.Path, 16)
		for _, point in ipairs(input.Path) do
			net.WriteEntity(point.Entity)
			net.WriteVector(point.Pos)
		end
	end
	net.Send(ply)
end

local function ProcessQueue()
	for ply, queue in pairs(transmit_queues) do
		if ply:IsValid() then
			local nextinqueue = table.remove(queue, 1)
			if nextinqueue then
				TransmitPath(nextinqueue, ply)
			else
				transmit_queues[ply] = nil
			end
		else
			transmit_queues[ply] = nil
		end
	end
	if not next(transmit_queues) then
		timer.Remove("WireLib.Paths.ProcessQueue")
	end
end

-- Add a path to every player's transmit queue
function WireLib.Paths.Add(input, ply)
	if ply then
		table.insert(transmit_queues[ply], input)
	else
		for _, player in pairs(player.GetAll()) do
			table.insert(transmit_queues[player], input)
		end
	end
	if not timer.Exists("WireLib.Paths.ProcessQueue") then
		timer.Create("WireLib.Paths.ProcessQueue", 0, 0, ProcessQueue)
	end
end
