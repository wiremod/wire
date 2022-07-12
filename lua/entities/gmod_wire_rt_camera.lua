AddCSLuaFile()
ENT.Base = "base_wire_entity"
ENT.Type = "anim"
ENT.PrintName = "Improved RT Camera"
ENT.WireDebugName = "Improved RT Camera"

function ENT:Initialize()
    if ( SERVER ) then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )

		-- Don't collide with the player
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

		--self.health = rtcam.cameraHealth
		self.Inputs = Wire_CreateInputs( self, {"Active", "FOV"} )
	end

    self.IsObserved = false

    -- At https://wiki.facepunch.com/gmod/Entity:NetworkVarNotify
    -- The callback will not be called clientside if the var is changed right after entity spawn.
    if CLIENT and self:GetActive() then
        self:ActiveChanged(nil, nil, true)
    end
end

function ENT:Setup(default_fov) --(model, default_fov)
    --self:SetModel(model or "models/maxofs2d/camera.mdl")
    self:SetCamFOV(default_fov or 80)
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "CamFOV")
    self:NetworkVar("Bool", 0, "Active")

    if CLIENT then
        self:NetworkVarNotify("Active", self.ActiveChanged)
    end
end

function ENT:TriggerInput( name, value )
    if name == "FOV" then
      self:SetCamFOV( math.Clamp( value, 10, 120 ) )
    elseif name == "Active" then
        self:SetActive(value ~= 0)
    end
end

if CLIENT then
    local wire_rt_camera_resolution_h = CreateClientConVar("wire_rt_camera_resolution_h", "512", true, nil, nil, 128)
    local wire_rt_camera_resolution_w = CreateClientConVar("wire_rt_camera_resolution_w", "512", true, nil, nil, 128)
    local wire_rt_camera_filtering = CreateClientConVar("wire_rt_camera_filtering", "2", true, nil, nil, 0, 2)
    local wire_rt_camera_hdr = CreateClientConVar("wire_rt_camera_hdr", "1", true, nil, nil, 0, 1)

    local ActiveCameras = {}
    local ObservedCameras = {}

    concommand.Add("wire_rt_camera_recreate", function()
        for _, cam in ipairs(ObservedCameras) do
            cam:InitRTTexture()
        end
    end)

    local function SetCameraActive(camera, isActive)
        if isActive then
            ActiveCameras[camera] = true
        else
            if camera.SetIsObserved then -- undefi
                camera:SetIsObserved(false)
            end
            ActiveCameras[camera] = nil
        end
    end

    function ENT:ActiveChanged(_, _, isActive)
        SetCameraActive(self, isActive)
    end

    function ENT:OnRemove()
        timer.Simple( 0, function()
            if not IsValid(self) then
                SetCameraActive(self, false)
            end
        end)
    end

    function ENT:SetIsObserved(isObserved)
        assert(isbool(isObserved))

        if isObserved == self.IsObserved then
            return
        end

        self.IsObserved = isObserved

        if isObserved then
            local index = #ObservedCameras + 1
            ObservedCameras[index] = self
            self.ObservedCamerasIndex = index

            self:InitRTTexture()
        else
            ObservedCameras[self.ObservedCamerasIndex] = nil
            self.ObservedCamerasIndex = nil
            self.RenderTarget = nil
        end
    end

    local function CreateRTName(index)
        return "improvedrtcamera_rt_"..tostring(index).."_"..wire_rt_camera_filtering:GetString().."_"
            ..wire_rt_camera_resolution_h:GetString().."x"..wire_rt_camera_resolution_w:GetString()..
            (wire_rt_camera_hdr:GetInt() and "_hdr" or "_ldr")
    end

    function ENT:InitRTTexture()
        local index = self.ObservedCamerasIndex

        local filteringFlag = 1 -- pointsample

        if wire_rt_camera_filtering:GetInt() == 1 then
            filteringFlag = 2 -- trilinear
        elseif wire_rt_camera_filtering:GetInt() == 2 then
            filteringFlag = 16 -- anisotropic
        end

        local isHDR = wire_rt_camera_hdr:GetInt() ~= 0

        local rt = GetRenderTargetEx(CreateRTName(index),
            wire_rt_camera_resolution_w:GetInt(),
            wire_rt_camera_resolution_h:GetInt(),
            RT_SIZE_LITERAL,
            MATERIAL_RT_DEPTH_SEPARATE,
            filteringFlag + 256 + 32768,
            isHDR and CREATERENDERTARGETFLAGS_HDR or 0,
            isHDR and IMAGE_FORMAT_RGBA16161616 or IMAGE_FORMAT_RGB888
        )
        rt:Download()

        assert(rt)

        self.RenderTarget = rt
    end

    local CameraIsDrawn = false

    hook.Add("ShouldDrawLocalPlayer", "ImprovedRTCamera", function(ply)
        if CameraIsDrawn then return true end
    end)

    hook.Add("PreRender", "ImprovedRTCamera", function()
        local isHDR = wire_rt_camera_hdr:GetInt() ~= 0
        local renderH = wire_rt_camera_resolution_h:GetInt()
        local renderW = wire_rt_camera_resolution_w:GetInt()

        for ent, _ in pairs(ActiveCameras) do
            if IsValid(ent) and ent.IsObserved then
                render.PushRenderTarget(ent.RenderTarget)
                    local oldNoDraw = ent:GetNoDraw()
                    ent:SetNoDraw(true)
                        CameraIsDrawn = true
                        cam.Start2D()
                            render.OverrideAlphaWriteEnable(true, true)
                            render.RenderView({
                                origin = ent:GetPos(),
                                angles = ent:GetAngles(),
                                x = 0, y = 0, h = renderH, w = renderW,
                                drawmonitors = true,
                                drawviewmodel = false,
                                fov = ent:GetCamFOV(),
                                bloomtone = isHDR
                            })

                        cam.End2D()
                        CameraIsDrawn = false
                    ent:SetNoDraw(oldNoDraw)
                render.PopRenderTarget()
            end
        end
    end)

end


duplicator.RegisterEntityClass("improvedrt_camera", WireLib.MakeWireEnt, "Data", --[["Model",]] "CamFOV")
duplicator.RegisterEntityClass("gmod_wire_rt_camera", WireLib.MakeWireEnt, "Data", --[["Model",]] "CamFOV")