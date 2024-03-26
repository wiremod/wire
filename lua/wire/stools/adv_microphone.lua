WireToolSetup.setCategory( "Other/Sound" )
WireToolSetup.open( "adv_microphone", "Adv. Microphone", "gmod_wire_adv_microphone", nil, "Adv. Microphones" )

if CLIENT then
    language.Add("tool.wire_adv_microphone.name", "Advanced Microphone")
    language.Add("tool.wire_adv_microphone.desc", "Places Advanced Microphones")
    language.Add("tool.wire_adv_microphone.0", "Create or update microphone")

    -- TODO: icon?
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	model     = "models/jaanus/wiretool/wiretool_siren.mdl",
}


function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_adv_microphone", true)
end