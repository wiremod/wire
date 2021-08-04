AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.PrintName = "Improved RT Screen"
ENT.WireDebugName = "Improved RT Screen"

function ENT:Setup(screen_material)--(model, screen_material)
    --self:SetModel(model or "models/kobilica/wiremonitorbig.mdl")
    self:SetScreenMaterial(screen_material or "normal")
end

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Entity", 0, "Camera" )
    self:NetworkVar("String", 0, "ScreenMaterial")
    if CLIENT then
        self:NetworkVarNotify("ScreenMaterial", self.ScreenMaterialChanged)
    end

    self:NetworkVar("Vector", 0, "ParamColor1")
    self:NetworkVar("Vector", 1, "ParamColor2")

    self:NetworkVar("Float", 0, "ScrollX")
    self:NetworkVar("Float", 1, "ScrollY")
    self:NetworkVar("Float", 2, "ScaleX")
    self:NetworkVar("Float", 3, "ScaleY")
end

if SERVER then
    function ENT:Initialize()
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup( COLLISION_GROUP_NONE )
        self:DrawShadow( false )
    
        self.Inputs = Wire_CreateInputs( self, {
            "Active", "Camera [ENTITY]", "Screen Color 1 [VECTOR]", "Screen Color 2 [VECTOR]",
            "Scroll X", "Scroll Y", "Scale X", "Scale Y"
        } )

        self:SetScaleX(1)
        self:SetScaleY(1)
    end
end

function ENT:TriggerInput( name, value )
    if name == "Active" then
        self:SetActive(value ~= 0)
    elseif name == "Camera" then
        if value ~= nil and not value:IsValid() then
            return
        end
        if value == nil or value:GetClass() == "improvedrt_camera" then
            self:SetCamera(value)
        end
    elseif name == "Screen Color 1" then
        self:SetParamColor1(value)
    elseif name == "Screen Color 2" then
        self:SetParamColor2(value)
    elseif name == "Scroll X" then
        self:SetScrollX(value)
    elseif name == "Scroll Y" then
        self:SetScrollY(value)
    elseif name == "Scale X" then
        self:SetScaleX(value)
    elseif name == "Scale Y" then
        self:SetScaleY(value)
    end
end

function ENT:ShouldDrawCamera(ply)
    local maxDist = ply:GetInfoNum("improvedrt_screen_renderdistance", 512)

    return ply:EyePos():DistToSqr(self:GetPos()) <= maxDist * maxDist
end

if CLIENT then
    local MATERIALS = {}

    local function GetOrAllocMaterial(name)
        if MATERIALS[name] ~= nil then
            return MATERIALS[name]
        end
        
        local path = "improvedrt_screen/monitor_"..name..".vmt"

        if not file.Exists("materials/"..path, "GAME") then
            return nil
        end

        local mtl = Material(path)
        MATERIALS[name] = mtl
        return mtl 
    end

    function ENT:Initialize()
        self.MonitorDesc = WireGPU_Monitors[self:GetModel()]
        self.Material = GetOrAllocMaterial(self:GetScreenMaterial())
    end

    function ENT:ScreenMaterialChanged(_,_,mtl)
        self.Material = GetOrAllocMaterial(mtl)
    end
    
    local improvedrt_camera_resolution_h = GetConVar("improvedrt_camera_resolution_h")
    local improvedrt_camera_resolution_w = GetConVar("improvedrt_camera_resolution_w")    
    local improvedrt_screen_renderdistance = CreateClientConVar("improvedrt_screen_renderdistance","512", nil,true,nil, 0)

    local white_mtl = Material("lights/White")
    local white_txt = white_mtl:GetTexture("$basetexture")

    function ENT:Think()
        local camera = self:GetCamera()

        if not self:GetActive() then
            if IsValid(camera) then
                camera:SetIsObserved(false)
            end

            return
        end

        local maxDistance = improvedrt_screen_renderdistance:GetFloat()
        self.ShouldRenderCamera = self:ShouldDrawCamera(LocalPlayer())
    
        if IsValid(camera) then
            camera:SetIsObserved(self.ShouldRenderCamera)
        end
    end

    function ENT:DrawScreen()
        local camera = self:GetCamera()

        local monitor = self.MonitorDesc
        local material = self.Material
        local rt = camera.RenderTarget
        assert(rt ~= nil)

        material:SetTexture(material:GetString("!targettex1"), rt)

        local tex2 = material:GetString("!targettex2")
        if tex2 ~= nil then material:SetTexture(tex2, rt) end

        local clr1 = material:GetString("!parameter_color1")
        if clr1 ~= nil then material:SetVector(clr1, self:GetParamColor1()) end

        local clr2 = material:GetString("!parameter_color2")
        if clr2 ~= nil then material:SetVector(clr2, self:GetParamColor2()) end

        local xraw = 256 / monitor.RatioX
        local yraw = 256
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
            --render.SetLightmapTexture(white_txt)
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

        local xraw = 256 / monitor.RatioX
        local yraw = 256
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

        if not self:GetActive() or not IsValid(self:GetCamera()) or not self.ShouldRenderCamera then
            self:DrawDummy()
        else
            self:DrawScreen()
        end
    end    
end

duplicator.RegisterEntityClass("improvedrt_screen", WireLib.MakeWireEnt, "Data",--[["Model",]] "ScreenMaterial")