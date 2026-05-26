AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.PrintName = "Improved RT Screen"
ENT.WireDebugName = "Improved RT Screen"

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Entity", 0, "Camera" )
    self:NetworkVar("String", 0, "ScreenMaterial")
    if CLIENT then
        self:NetworkVarNotify("ScreenMaterial", self.ScreenMaterialChanged)
    end

    self:NetworkVar("Float", 0, "ScrollX")
    self:NetworkVar("Float", 1, "ScrollY")
    self:NetworkVar("Float", 2, "ScaleX")
    self:NetworkVar("Float", 3, "ScaleY")

    self:NetworkVar("String", 1, "MaterialParams")
    if CLIENT then
        self:NetworkVarNotify("MaterialParams", self.MaterialParamsChanged)
    end
end

local MTLPARAM_TYPE = {
    numint = {"SetInt", "NORMAL", nil },
    numfloat = {"SetFloat", "NORMAL", nil },
    vector3 = {"SetVector", "VECTOR", function(tbl) return Vector(tbl.x, tbl.y, tbl.z) end},
    --vector4 = {"SetVector4D", "VECTOR4", nil }, --May not work
    string = {"SetString", "STRING", nil },
    texture = {"SetTexture", "STRING", nil},
    matrix44 = {"SetMatrix", "matrix4", function(tbl) return Matrix({
        {tbl.a1, tbl.a2, tbl.a3, tbl.a4},
        {tbl.b1, tbl.b2, tbl.b3, tbl.b4},
        {tbl.c1, tbl.c2, tbl.c3, tbl.c4},
        {tbl.d1, tbl.d2, tbl.d3, tbl.d4}
    })
    end}
}

local MaterialParameters = {}
local function GetMaterialParameters(mtl)
    if MaterialParameters[mtl] ~= nil then
        return MaterialParameters[mtl]
    end

    local mtlFile = file.Read("materials/improvedrt_screen/monitor_"..mtl..".vmt", "GAME")

    if mtlFile == nil then return end

    local mtl = util.KeyValuesToTable(mtlFile)
    local params = {}

    for mtlParam, tbl in pairs(mtl["!parameters"] or {}) do
        local defaultParse = assert(MTLPARAM_TYPE[tbl.type])[3]

        params[mtlParam] = {
            WireName = tbl.wirename,
            WireType = MTLPARAM_TYPE[tbl.type][2],
            MaterialFn = MTLPARAM_TYPE[tbl.type][1],
            Default = defaultParse and defaultParse(tbl.default) or tbl.default
        }
    end

    MaterialParameters[mtl] = params

    return params
end


if SERVER then
    local InputsTable = {
        "Active", "Camera [ENTITY]",
        "Scroll X", "Scroll Y", "Scale X", "Scale Y"
    }

	local screens = ents.FindByClass("gmod_wire_rt_screen") or {}

	local function ImprovedRTCamera(ply, plyView)
        for _, screen in ipairs(screens) do
            if screen:GetActive() and screen:IsScreenInRange(ply) then
                local camera = screen:GetCamera()
                if IsValid(camera) and camera:GetActive() then
                    AddOriginToPVS(camera:GetPos())
                end
            end
        end
    end

    function ENT:Initialize()
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup( COLLISION_GROUP_NONE )
        self:DrawShadow( false )

		table.insert(screens, self)
		if #screens == 1 then
			hook.Add("SetupPlayerVisibility", "ImprovedRTCamera", ImprovedRTCamera)
		end

        self.Inputs = Wire_CreateInputs( self, InputsTable )

        self:SetScaleX(1)
        self:SetScaleY(1)

        self.MaterialParams = {}
        self:SetMaterialParams("{}")
    end

    function ENT:Setup(screen_material) --(model, screen_material)
        --self:SetModel(model or "models/kobilica/wiremonitorbig.mdl")
        self:SetScreenMaterial(screen_material or "normal")

        local Inputs = table.Copy(InputsTable)

		local matParams = GetMaterialParameters(self:GetScreenMaterial())
		if not matParams then return end

        for _, tbl in pairs(matParams) do
            table.insert(Inputs, tbl.WireName.." ["..tbl.WireType.."]")
        end

        self.Inputs = Wire_CreateInputs( self, Inputs )
    end

	function ENT:OnRemove()
		table.RemoveByValue(screens, self)
		if #screens == 0 then
			hook.Remove("SetupPlayerVisibility", "ImprovedRTCamera")
		end
	end

end

function ENT:TriggerInput( name, value )
    if name == "Active" then
        self:SetActive(value ~= 0)
    elseif name == "Camera" then
        if not IsValid(value) or value:GetClass() ~= "gmod_wire_rt_camera" then
            value = nil
        end

        self:SetCamera(value)
    elseif name == "Scroll X" then
        self:SetScrollX(value)
    elseif name == "Scroll Y" then
        self:SetScrollY(value)
    elseif name == "Scale X" then
        self:SetScaleX(value)
    elseif name == "Scale Y" then
        self:SetScaleY(value)
    else
        self.MaterialParams[name] = value
        self:SetMaterialParams(util.TableToJSON(self.MaterialParams))
    end
end

function ENT:IsScreenInRange(ply)
    local maxDist = ply:GetInfoNum("wire_rt_screen_renderdistance", 512)

    return ply:EyePos():DistToSqr(self:GetPos()) <= maxDist * maxDist
end

if CLIENT then
    CreateClientConVar("wire_rt_screen_renderdistance","512", nil,true,nil, 0)

    local MATERIALS = {}

    local function GetOrAllocMaterial(name)
        if MATERIALS[name] ~= nil then
            return MATERIALS[name]
        end

        if name == "" then
            MsgN("WireRTScreen: got empty name (typically happens at entity creation).")
            return nil
        end

        local path = "improvedrt_screen/monitor_"..name..".vmt"

        if not file.Exists("materials/"..path, "GAME") then
            MsgN("WireRTScreen: material "..path.." does not exist on client for some reason! Screen will not be rendered")
            return nil
        end

        local mtl = Material(path)
        MATERIALS[name] = mtl
        return mtl
    end

    function ENT:Initialize()
        self.MonitorDesc = WireGPU_Monitors[self:GetModel()]
        self:ScreenMaterialChanged(nil,nil,self:GetScreenMaterial())
        self.MaterialParams = {}
    end

    function ENT:ScreenMaterialChanged(_,_,mtl)
        self.Material = GetOrAllocMaterial(mtl)
        self.MaterialParamsDesc = GetMaterialParameters(mtl)
    end

    function ENT:MaterialParamsChanged(_,_,materialParams)
        self.MaterialParams = util.JSONToTable(materialParams)
    end

    function ENT:Think()
        local camera = self:GetCamera()

        if not self:GetActive() then
            if IsValid(camera) then
                camera:SetIsObserved(false)
            end
            self.ShouldRenderCamera = false

            return
        end

        self.ShouldRenderCamera = self:IsScreenInRange(LocalPlayer())

        if IsValid(camera) then
            camera:SetIsObserved(self.ShouldRenderCamera)
        end
    end

    function ENT:DrawScreen()
        local camera = self:GetCamera()

        local monitor = self.MonitorDesc
        local material = self.Material
        local rt = camera.RenderTarget
        if not rt then return end

        material:SetTexture(material:GetString("!targettex1"), rt)

        local tex2 = material:GetString("!targettex2")
        if tex2 ~= nil then material:SetTexture(tex2, rt) end

		if self.MaterialParamsDesc then
			for mtl_param, tbl in pairs(self.MaterialParamsDesc) do
				--print(self.MaterialParams[tbl.WireName])

				local value = self.MaterialParams[tbl.WireName] or tbl.Default

				material[tbl.MaterialFn](material, mtl_param, value)
			end
		end

        local xraw = 512 / monitor.RatioX
        local yraw = 512
        local x1 = -xraw
        local x2 = xraw
        local y1 = -yraw
        local y2 = yraw

        local u1, v1 = 0, 0
        local u2, v2 = self:GetScaleX(), monitor.RatioX * self:GetScaleY()
        local scrU = self:GetScrollX()
        local scrV = self:GetScrollY()
        u1 = u1 + scrU u2 = u2 + scrU
        v1 = v1 + scrV v2 = v2 + scrV

        cam.Start3D2D(
            self:LocalToWorld(monitor.offset),
            self:LocalToWorldAngles(monitor.rot),
            monitor.RS
        )
            surface.SetDrawColor(255,255,255)
            surface.SetMaterial(material)
            surface.DrawPoly({
                { x = x2, y = y1, u = u2, v = v1},
                { x = x2, y = y2, u = u2, v = v2},
                { x = x1, y = y2, u = u1, v = v2},
                { x = x1, y = y1, u = u1, v = v1},
            })
        cam.End3D2D()
    end

    function ENT:DrawDummy()
        local monitor = self.MonitorDesc

        local xraw = 512 / monitor.RatioX
        local yraw = 512
        local x1 = -xraw
        local x2 = xraw
        local y1 = -yraw
        local y2 = yraw

        cam.Start3D2D(
            self:LocalToWorld(monitor.offset),
            self:LocalToWorldAngles(monitor.rot),
            monitor.RS
        )
            draw.NoTexture()
            surface.SetDrawColor(0,0,0)
            surface.DrawPoly({
                { x = x2, y = y1, u = 1, v = 0},
                { x = x2, y = y2, u = 1, v = 1},
                { x = x1, y = y2, u = 0, v = 1},
                { x = x1, y = y1, u = 0, v = 0},
            })
        cam.End3D2D()
    end

    function ENT:Draw()
        self:DrawModel()

        if self.MonitorDesc == nil then
            return
        end

        if self:GetActive() and self.ShouldRenderCamera and self.Material ~= nil
            and IsValid(self:GetCamera()) and self:GetCamera():GetActive()
        then
            self:DrawScreen()
        elseif not self.translucent then
            self:DrawDummy()
        end
    end
end

duplicator.RegisterEntityClass("improvedrt_screen", WireLib.MakeWireEnt, "Data",--[["Model",]] "ScreenMaterial")
duplicator.RegisterEntityClass("gmod_wire_rt_screen", WireLib.MakeWireEnt, "Data",--[["Model",]] "ScreenMaterial")
