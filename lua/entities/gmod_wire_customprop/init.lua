AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
local shared = include("shared.lua")

util.AddNetworkString(shared.classname)

local ENT_META = FindMetaTable("Entity")
local Ent_GetTable = ENT_META.GetTable

local wire_customprops_hullsize_max = CreateConVar("wire_customprops_hullsize_max", 2048, FCVAR_ARCHIVE, "The max hull size of a custom prop")
local wire_customprops_minvertexdistance = CreateConVar("wire_customprops_minvertexdistance", 0.2, FCVAR_ARCHIVE, "The min distance between two vertices in a custom prop.")
local wire_customprops_vertices_max = CreateConVar("wire_customprops_vertices_max", 512, FCVAR_ARCHIVE, "How many vertices custom props can have.", 4)
local wire_customprops_convexes_max = CreateConVar("wire_customprops_convexes_max", 8, FCVAR_ARCHIVE, "How many convexes custom props can have.", 1)

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self:PhysicsInitMultiConvex(self.physmesh) self.physmesh = nil
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:EnableCustomCollisions(true)
	self:DrawShadow(false)

	self.customForceMode = 0
	self.customForceLinear = Vector()
	self.customForceAngular = Vector()
	self.customShadowForce = {
		pos = Vector(),
		angle = Angle(),
		secondstoarrive = 1,
		dampfactor = 0.2,
		maxangular = 1000,
		maxangulardamp = 1000,
		maxspeed = 1000,
		maxspeeddamp = 1000,
		teleportdistance = 1000,
	}

	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
end

function ENT:EnableCustomPhysics(mode)
	local ent_tbl = Ent_GetTable(self)
	if mode then
		ent_tbl.customPhysicsMode = mode
		if not ent_tbl.hasMotionController then
			self:StartMotionController()
			ent_tbl.hasMotionController = true
		end
	else
		ent_tbl.customPhysicsMode = nil
		if ent_tbl.hasMotionController then
			self:StopMotionController()
			ent_tbl.hasMotionController = false
		end
	end
end

function ENT:PhysicsSimulate(physObj, dt)
	local ent_tbl = Ent_GetTable(self)
	local mode = ent_tbl.customPhysicsMode
	if mode == 1 then
		return ent_tbl.customForceAngular, ent_tbl.customForceLinear, ent_tbl.customForceMode
	elseif mode == 2 then
		ent_tbl.customShadowForce.deltatime = dt
		physObj:ComputeShadowControl(ent_tbl.customShadowForce)
		return SIM_NOTHING
	else
		return SIM_NOTHING
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:TransmitData(recip)
	net.Start(shared.classname)
	shared.writeReliableEntity(self)
	local stream = net.WriteStream(self.wiremeshdata, nil, true)
	if recip then net.Send(recip) else net.Broadcast() end
	return stream
end

hook.Add("PlayerInitialSpawn","CustomProp_SpawnFunc",function(ply)
	for k, v in ipairs(ents.FindByClass(shared.classname)) do
		v:TransmitData(ply)
	end
end)

local function streamToMesh(meshdata)
	local maxConvexesPerProp = maxConvexesPerProp:GetInt()
    local maxVerticesPerConvex = maxVerticesPerConvex:GetInt()

    local meshConvexes = {}
    local data = util.Decompress(meshdata, 65536)
    local pos = 1
    local nConvexes
    nConvexes, pos = string.unpack("I4", data, pos)
    assert(nConvexes <= maxConvexesPerProp, "Exceeded the max convexes per prop (max: " .. maxConvexesPerProp .. ", got: " .. nConvexes .. ")")
    for iConvex = 1, nConvexes do
        local nVertices
        nVertices, pos = string.unpack("I4", data, pos)
        assert(nVertices <= maxVerticesPerConvex, "Exceeded the max vertices per convex (max: " .. maxVerticesPerConvex .. ", got: " .. nVertices .. ")")
        local convex = {}
        for iVertex = 1, nVertices do
            local x, y, z
            x, y, z, pos = string.unpack("fff", data, pos)
            convex[iVertex] = Vector(x, y, z)
        end
        meshConvexes[iConvex] = convex
    end
    return meshConvexes
end

local function meshToStream(meshConvexes)
	local buffer = {}

    buffer[#buffer+1] = shared.writeInt32(#meshConvexes)
    for _, convex in ipairs(meshConvexes) do
        buffer[#buffer+1] = shared.writeInt32(#convex)
        for _, vertex in ipairs(convex) do
            buffer[#buffer+1] = shared.writeFloat(vertex[1])
            buffer[#buffer+1] = shared.writeFloat(vertex[2])
            buffer[#buffer+1] = shared.writeFloat(vertex[3])
        end
    end

    return util.Compress(table.concat(buffer))
end

local function checkMesh(ply, meshConvexes)
	local maxHullSize = wire_customprops_hullsize_max:GetFloat()
    local mindist = wire_customprops_minvertexdistance:GetFloat()
    local maxConvexesPerProp = wire_customprops_convexes_max:GetInt()
    local maxVerticesPerConvex = wire_customprops_vertices_max:GetInt()

    assert(#meshConvexes > 0, "Invalid number of convexes (" .. #meshConvexes .. ")")
    assert(#meshConvexes <= maxConvexesPerProp, "Exceeded the max convexes per prop (max: " .. maxConvexesPerProp .. ", got: ".. #meshConvexes .. ")")

    for _, convex in ipairs(meshConvexes) do
        assert(#convex <= maxVerticesPerConvex, "Exceeded the max vertices per convex (max: " .. maxVerticesPerConvex .. ", got: " .. #convex .. ")")
        assert(#convex > 4, "Invalid number of vertices (" .. #convex .. ")")

        for k, vertex in ipairs(convex) do
            assert(math.abs(vertex[1]) < maxHullSize and math.abs(vertex[2]) < maxHullSize and math.abs(vertex[3]) < maxHullSize, "The custom prop cannot exceed a hull size of " .. maxHullSize)
            assert(vertex[1] == vertex[1] and vertex[2] == vertex[2] and vertex[3] == vertex[3], "Your mesh contains nan values!")
            for i = 1, k - 1 do
                assert(convex[i]:DistToSqr(vertex) >= mindist, "No two vertices can have a distance less than " .. math.sqrt(mindist))
            end
        end
    end
end

function WireLib.createCustomProp(ply, pos, ang, wiremeshdata)
	local meshConvexes, meshStream

	if isstring(wiremeshdata) then
		meshConvexes = streamToMesh(wiremeshdata)
		meshStream = wiremeshdata
	elseif istable(wiremeshdata) then
		meshConvexes = wiremeshdata
		meshStream = meshToStream(wiremeshdata)
	else
		assert(false, "Invalid meshdata")
	end

	checkMesh(self, meshConvexes)

	local propent = ents.Create(shared.classname)
	propent.physmesh = meshConvexes

	propent.wiremeshdata = meshStream
	propent:Spawn()

	local physobj = propent:GetPhysicsObject()
	if not physobj:IsValid() then
		propent:Remove()
		assert(false, "Custom prop has invalid physics!")
	end

	propent:SetPos(pos)
	propent:SetAngles(ang)
	propent:TransmitData()

	physobj:EnableCollisions(true)
	physobj:EnableDrag(true)
	physobj:Wake()

	gamemode.Call("PlayerSpawnedSENT", ply, propent)

	local totalVertices = 0
	for k, v in ipairs(meshConvexes) do
		totalVertices = totalVertices + #v
	end

	return propent
end

duplicator.RegisterEntityClass(shared.classname, createCustomProp, "Pos", "Ang", "wiremeshdata")
