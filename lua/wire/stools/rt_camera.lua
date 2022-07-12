WireToolSetup.setCategory("Visuals")
WireToolSetup.open("rt_camera", "RT Camera", "gmod_wire_rt_camera", nil, "RT Cameras")

if CLIENT then
    language.Add("tool.wire_rt_camera.name", "Render-Target Camera")
    language.Add("tool.wire_rt_camera.desc", "Places Render Target cameras")
    language.Add("tool.wire_rt_camera.0", "Create or update RT Camera")

    language.Add("tool.wire_rt_camera.settings.hint_serverside",
        "Following settings are server-side, they are stored during duplication and changes to them are visible to all clients")
    language.Add("tool.wire_rt_camera.settings.default_fov", "Initial Field-Of-View")

    language.Add("tool.wire_rt_camera.settings.hint_clientside",
        "Following settings are client-side, they are player-specific, not stored via duplication and not visible by other players")
    language.Add("tool.wire_rt_camera.settings.cl_resolution_h", "Camera resolution: height")
    language.Add("tool.wire_rt_camera.settings.cl_resolution_w", "Camera resolution: width")
    language.Add("tool.wire_rt_camera.settings.cl_hdr", "Enable HDR (overbright effects)")
    language.Add("tool.wire_rt_camera.settings.cl_filtering", "Image filtering mode")
    language.Add("tool.wire_rt_camera.settings.cl_filtering_0", "Pixelized (no filtering)")
    language.Add("tool.wire_rt_camera.settings.cl_filtering_1", "Trilinear")
    language.Add("tool.wire_rt_camera.settings.cl_filtering_2", "Anisotropic")
    language.Add("tool.wire_rt_camera.settings.cl_apply", "Apply player-specific changes")

    WireToolSetup.setToolMenuIcon( "icon16/camera.png" )
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
    default_fov = "80",
    model = "models/maxofs2d/camera.mdl"
}

local MODELS = {
    ["models/maxofs2d/camera.mdl"] = true,
    ["models/dav0r/camera.mdl"] = true,
    ["models/props_wasteland/camera_lens001a.mdl"] = true
}

if SERVER then
	function TOOL:GetConVars()
        return  --self:GetClientInfo("model"),
                self:GetClientInfo("default_fov")
    end
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.wire_rt_camera.settings.hint_serverside")

    WireDermaExts.ModelSelect(panel, "wire_rt_camera_model", MODELS, 1)
    panel:NumSlider("#tool.wire_rt_camera.settings.default_fov", "wire_rt_camera_default_fov", 10, 120)

    panel:Help("#tool.wire_rt_camera.settings.hint_clientside")
    panel:NumSlider("#tool.wire_rt_camera.settings.cl_resolution_h", "wire_rt_camera_resolution_h", 128, 2048, 0)
    panel:NumSlider("#tool.wire_rt_camera.settings.cl_resolution_w", "wire_rt_camera_resolution_w", 128, 2048, 0)
    panel:CheckBox("#tool.wire_rt_camera.settings.cl_hdr", "wire_rt_camera_hdr")
    local cl_filtering_slider = panel:NumSlider(
        "#tool.wire_rt_camera.settings.cl_filtering", "wire_rt_camera_filtering", 0, 2, 0)
    local cl_filtering_desc = panel:Help("#tool.wire_rt_camera.settings.cl_filtering_"..GetConVar("wire_rt_camera_filtering"):GetString())

    do
        local old_callback = cl_filtering_slider.OnValueChanged

        cl_filtering_slider.OnValueChanged = function(self, value)
            cl_filtering_desc:SetText("#tool.wire_rt_camera.settings.cl_filtering_"..tostring(math.Round(value)))
            old_callback(self, value)
        end
    end

    panel:Button("#tool.wire_rt_camera.settings.cl_apply", "wire_rt_camera_recreate")
end
