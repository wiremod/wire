local shared = include("shared.lua")

ENT.DefaultMaterial = Material("models/wireframe")
ENT.Material = ENT.DefaultMaterial

local Ent_IsValid = FindMetaTable("Entity").IsValid
local Phys_IsValid = FindMetaTable("PhysObj").IsValid
local Ent_GetTable = FindMetaTable("Entity").GetTable

function ENT:Initialize()
	self.rendermesh = Mesh(self.Material)
	self.meshapplied = false
	self:DrawShadow(false)
	self:EnableCustomCollisions( true )

	-- local mesh
	-- SF.CallOnRemove(self, "sf_prop",
	-- 	function() mesh = self.rendermesh end,
	-- 	function() if mesh then mesh:Destroy() end
	-- end)
end

function ENT:OnRemove()
    if self.rendermesh then
        self.rendermesh:Destroy()
        self.rendermesh = nil
    end
end

function ENT:BuildPhysics(ent_tbl, physmesh)
	ent_tbl.physmesh = physmesh
	self:PhysicsInitMultiConvex(physmesh)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:EnableCustomCollisions(true)

	local phys = self:GetPhysicsObject()
	if Phys_IsValid(phys) then
		phys:SetMaterial(ent_tbl.GetPhysMaterial(self))
	end
end

function ENT:BuildRenderMesh(ent_tbl, rendermesh)
	local phys = self:GetPhysicsObject()
	if not Phys_IsValid(phys) then return end

	local convexes = phys:GetMeshConvexes()
	local rendermesh = convexes[1]
	for i=2, #convexes do
		for k, v in ipairs(convexes[i]) do
			rendermesh[#rendermesh+1] = v
		end
	end

	-- less than 3 can crash
	if #rendermesh < 3 then return end

	ent_tbl.rendermesh:BuildFromTriangles(rendermesh)
end

function ENT:Think()
	local physobj = self:GetPhysicsObject()
	if Phys_IsValid(physobj) then
		physobj:SetPos( self:GetPos() )
		physobj:SetAngles( self:GetAngles() )
		physobj:EnableMotion(false)
		physobj:Sleep()
	end
end

function ENT:Draw(flags)
	self:DrawModel(flags)
end

function ENT:GetRenderMesh()
	local ent_tbl = Ent_GetTable(self)
	if ent_tbl.custom_mesh then
		if ent_tbl.custom_mesh_data[ent_tbl.custom_mesh] then
			return { Mesh = ent_tbl.custom_mesh, Material = ent_tbl.Material--[[, Matrix = ent_tbl.render_matrix]] }
		else
			ent_tbl.custom_mesh = nil
		end
	else
		return { Mesh = ent_tbl.rendermesh, Material = ent_tbl.Material--[[, Matrix = ent_tbl.render_matrix]] }
	end
end

local function streamToMesh(meshdata)
	local meshConvexes, posMins, posMaxs = {}, Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)

    local meshdata = util.Decompress(meshdata, 65536)

    local pos = 1
    local nConvexes
    nConvexes, pos = shared.readInt32(meshdata, pos)
    for iConvex = 1, nConvexes do
        local nVertices
        nVertices, pos = shared.readInt32(meshdata, pos)
        local convex = {}
        for iVertex = 1, nVertices do
            local x, y, z
            x, pos = shared.readFloat(meshdata, pos)
            y, pos = shared.readFloat(meshdata, pos)
            z, pos = shared.readFloat(meshdata, pos)
            if x > posMaxs.x then posMaxs.x = x end
            if y > posMaxs.y then posMaxs.y = y end
            if z > posMaxs.z then posMaxs.z = z end
            if x < posMins.x then posMins.x = x end
            if y < posMins.y then posMins.y = y end
            if z < posMins.z then posMins.z = z end
            convex[iVertex] = Vector(x, y, z)
        end
        meshConvexes[iConvex] = convex
    end

    return meshConvexes, posMins, posMaxs
end

net.Receive(shared.classname, function()
	local receivedEntity, receivedData

    local function tryApplyData()
        if not receivedEntity or not receivedData then return end

        if Ent_IsValid(receivedEntity) and receivedEntity:GetClass()~=shared.classname then return end
        local ent_tbl = Ent_GetTable(receivedEntity)
        if not (ent_tbl and ent_tbl.rendermesh:IsValid() and receivedData and not ent_tbl.meshapplied) then return end

        ent_tbl.meshapplied = true

        local physmesh, mins, maxs = streamToMesh(receivedData)
        ent_tbl.BuildPhysics(receivedEntity, ent_tbl, physmesh)
        ent_tbl.BuildRenderMesh(receivedEntity, ent_tbl)
        receivedEntity:SetRenderBounds(mins, maxs)
        receivedEntity:SetCollisionBounds(mins, maxs)
    end

    shared.readReliableEntity(function(self)
        receivedEntity = self
        tryApplyData()
    end)

    net.ReadStream(nil, function(data)
        receivedData = data
        tryApplyData()
    end)
end)

hook.Add("NetworkEntityCreated", shared.classname.."physics", function(ent)
	local ent_tbl = Ent_GetTable(ent)
	local mesh = ent_tbl.physmesh
	if mesh and not Phys_IsValid(ent:GetPhysicsObject()) then
		ent_tbl.BuildPhysics(ent, ent_tbl, mesh)
	end
end)

function ENT:OnPhysMaterialChanged(name, old, new)
	local phys = self:GetPhysicsObject()
	if Phys_IsValid(phys) then
		phys:SetMaterial(new)
	end
end
