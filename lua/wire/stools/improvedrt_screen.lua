WireToolSetup.setCategory("Visuals")
WireToolSetup.open("improvedrt_screen", "Improved RT Screen", "improvedrt_screen", nil, "Improved RT Screens")

if CLIENT then
    language.Add("tool.wire_improvedrt_screen.name", "Improved RT Screen")
    language.Add("tool.wire_improvedrt_screen.desc", "Places Render Target screens")
    language.Add("tool.wire_improvedrt_screen.0", "Create or update RT Screen")

    language.Add("tool.improvedrt_screen.settings.hint_serverside", 
        "Following settings are server-side, they are stored during duplication and changes to them are visible to all clients")
    language.Add("tool.improvedrt_screen.settings.screenmaterial", "Screen effect")

    language.Add("tool.improvedrt_screen.settings.hint_clientside", 
        "Following settings are client-side, they are player-specific, not stored via duplication and not visible by other players")
    language.Add("tool.improvedrt_screen.settings.cl_renderdistance", "Range in wich screens will be rendered")
    
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
    panel:Help("#tool.improvedrt_screen.settings.hint_serverside")
    WireDermaExts.ModelSelect(panel, "wire_improvedrt_screen_model", list.Get( "WireScreenModels" ), 5)
    local materials = panel:ComboBox("#tool.improvedrt_screen.settings.screenmaterial", "wire_improvedrt_screen_screenmaterial")
    
    local files = file.Find("materials/improvedrt_screen/monitor_*.vmt", "GAME")

    for i, mtlfile in ipairs(files) do
        local name = mtlfile:match("monitor_(.+)%.vmt")
        if name ~= nil then materials:AddChoice(name) end
    end
    
    panel:Help("#tool.improvedrt_screen.settings.hint_clientside")
    panel:NumSlider("#tool.improvedrt_screen.settings.cl_renderdistance", "improvedrt_screen_renderdistance", 0, 999999, 0)
end