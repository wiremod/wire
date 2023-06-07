WireToolSetup.setCategory("Visuals")
WireToolSetup.open("rt_screen", "RT Screen", "gmod_wire_rt_screen", nil, "RT Screens")

if CLIENT then
    language.Add("tool.wire_rt_screen.name", "Render-Target Screen")
    language.Add("tool.wire_rt_screen.desc", "Places Render Target screens")
    language.Add("tool.wire_rt_screen.0", "Create or update RT Screen")

    language.Add("tool.wire_rt_screen.settings.hint_serverside",
        "Following settings are server-side, they are stored during duplication and changes to them are visible to all clients")
    language.Add("tool.wire_rt_screen.settings.screenmaterial", "Screen effect")

    language.Add("tool.wire_rt_screen.settings.hint_clientside",
        "Following settings are client-side, they are player-specific, not stored via duplication and not visible by other players")
    language.Add("tool.wire_rt_screen.settings.cl_renderdistance", "Render range")

    WireToolSetup.setToolMenuIcon( "icon16/camera.png" )
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
    model = "models/kobilica/wiremonitorbig.mdl",
    screenmaterial = "normal"
}

if SERVER then
    function TOOL:GetConVars()
        return  --self:GetClientInfo("model"),
                self:GetClientInfo("screenmaterial")
    end
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.wire_rt_screen.settings.hint_serverside")
    WireDermaExts.ModelSelect(panel, "wire_rt_screen_model", list.Get( "WireScreenModels" ), 5)
    local materials = panel:ComboBox("#tool.wire_rt_screen.settings.screenmaterial", "wire_rt_screen_screenmaterial")

    local files = file.Find("materials/improvedrt_screen/monitor_*.vmt", "GAME")

    for _, mtlfile in ipairs(files) do
        local name = mtlfile:match("monitor_(.+)%.vmt")
        if name ~= nil then materials:AddChoice(name) end
    end

    panel:Help("#tool.wire_rt_screen.settings.hint_clientside")
    panel:NumSlider("#tool.wire_rt_screen.settings.cl_renderdistance", "wire_rt_screen_renderdistance", 0, 999999, 0)
end