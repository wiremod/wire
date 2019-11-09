WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "gpulib_switcher", "GPULib Switcher", "gmod_wire_gpulib_controller", nil, "GPULib Switchers" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if (CLIENT) then
	language.Add("Tool.wire_gpulib_switcher.name", "GPULib Screen Switcher")
	language.Add("Tool.wire_gpulib_switcher.desc", "Spawn/link a GPULib Screen Switcher.")

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_gpulib_switcher.name", Description = "#Tool.wire_gpulib_switcher.desc" })
		WireDermaExts.ModelSelect(panel, "wire_gpulib_switcher_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	end
end

WireToolSetup.SetupLinking(true, "screen")

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.NoLeftOnClass = true
