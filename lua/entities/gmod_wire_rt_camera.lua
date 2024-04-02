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
    local cvar_resolution_h = CreateClientConVar("wire_rt_camera_resolution_h", "512", true, nil, nil, 128)
    local cvar_resolution_w = CreateClientConVar("wire_rt_camera_resolution_w", "512", true, nil, nil, 128)
    local cvar_filtering = CreateClientConVar("wire_rt_camera_filtering", "2", true, nil, nil, 0, 2)
    local cvar_hdr = CreateClientConVar("wire_rt_camera_hdr", "1", true, nil, nil, 0, 1)

    -- array(Entity)
    WireLib.__RTCameras_Active = WireLib.__RTCameras_Active or {}
    local ActiveCameras = WireLib.__RTCameras_Active
    -- table(Entity, true)
    WireLib.__RTCameras_Observed = WireLib.__RTCameras_Observed or {}
    local ObservedCameras = WireLib.__RTCameras_Observed

    concommand.Add("wire_rt_camera_recreate", function()
        for _, cam in ipairs(ObservedCameras) do
            cam:InitRTTexture()
        end
    end)

    local function SetCameraActive(camera, isActive)
        if isActive then
            if not table.HasValue(ActiveCameras, camera) then
                table.insert(ActiveCameras, camera)
            end
        else
            if camera.SetIsObserved then -- May be undefined (?)
                camera:SetIsObserved(false)
            end
            table.RemoveByValue(ActiveCameras, camera)
        end
    end

    function ENT:ActiveChanged(_, _, isActive)
        SetCameraActive(self, isActive)
    end

    function ENT:OnRemove(fullUpdate)
        if not fullUpdate then
            SetCameraActive(self, false)
        end
    end

    function ENT:SetIsObserved(isObserved)
        assert(isbool(isObserved))

        if isObserved == self.IsObserved then
            return
        end

        self.IsObserved = isObserved

        if isObserved then
            self.ObservedCamerasIndex = table.insert(ObservedCameras, self)

            self:InitRTTexture()
        else
            self.RenderTarget = nil

            local oldi = table.RemoveFastByValue(ObservedCameras, self)
            if oldi == nil then return end
            self.ObservedCamerasIndex = nil

            local shifted_cam = ObservedCameras[oldi]
            if IsValid(shifted_cam) then
                shifted_cam.ObservedCamerasIndex = oldi
            end
        end
    end

    local function CreateRTName(index)
        return "improvedrtcamera_rt_"..tostring(index).."_"..cvar_filtering:GetString().."_"
            ..cvar_resolution_h:GetString().."x"..cvar_resolution_w:GetString()..
            (cvar_hdr:GetInt() and "_hdr" or "_ldr")
    end

    function ENT:InitRTTexture()
        local index = self.ObservedCamerasIndex

        local filteringFlag = 1 -- pointsample

        if cvar_filtering:GetInt() == 1 then
            filteringFlag = 2 -- trilinear
        elseif cvar_filtering:GetInt() == 2 then
            filteringFlag = 16 -- anisotropic
        end

        local isHDR = cvar_hdr:GetInt() ~= 0

        local rt = GetRenderTargetEx(CreateRTName(index),
            cvar_resolution_w:GetInt(),
            cvar_resolution_h:GetInt(),
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


    hook.Add("ShouldDrawHalos", "ImprovedRTCamera", function()
        if CameraIsDrawn then return false end
    end)

    local function RenderCamerasImpl()
        local isHDR = cvar_hdr:GetInt() ~= 0
        local renderH = cvar_resolution_h:GetInt()
        local renderW = cvar_resolution_w:GetInt()

        local renderedCameras = 0

        for _, ent in ipairs(ActiveCameras) do
            if not IsValid(ent) or not ent.IsObserved then goto next_camera end
            renderedCameras = renderedCameras + 1

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

            ::next_camera::
        end

        return renderedCameras
    end


    local cvar_skip_frame_per_cam = CreateClientConVar("wire_rt_camera_skip_frame_per_camera", 0.8, true, nil, nil, 0)

    local SkippedFrames = 0
    hook.Add("PreRender", "ImprovedRTCamera", function()
        SkippedFrames = SkippedFrames - 1

        if SkippedFrames <= 0 then
            local rendered_cams = RenderCamerasImpl()
            SkippedFrames = math.ceil(rendered_cams * cvar_skip_frame_per_cam:GetFloat())
        end
    end)

end


duplicator.RegisterEntityClass("improvedrt_camera", WireLib.MakeWireEnt, "Data", --[["Model",]] "CamFOV")
duplicator.RegisterEntityClass("gmod_wire_rt_camera", WireLib.MakeWireEnt, "Data", --[["Model",]] "CamFOV")