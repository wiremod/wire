WireToolSetup.setCategory( "Other/Sound" )
WireToolSetup.open( "adv_speaker", "Adv. Speaker", "gmod_wire_adv_speaker", nil, "Adv. Speakers" )

if CLIENT then
    language.Add("tool.wire_adv_speaker.name", "Advanced Speaker")
    language.Add("tool.wire_adv_speaker.desc", "Places Advanced Speakers")
    language.Add("tool.wire_adv_speaker.0", "Create or update speaker")

    WireToolSetup.setToolMenuIcon( "icon16/sound.png" )
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
    ModelPlug_Register("speaker")
end

TOOL.ClientConVar = {
	model     = "models/cheeze/wires/speaker.mdl",
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "speaker", "wire_adv_speaker", true)
end