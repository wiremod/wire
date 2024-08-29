WireToolSetup.setCategory( "Vehicle Control" )
WireToolSetup.open( "eyepod", "Eye Pod", "gmod_wire_eyepod", nil, "Eye Pods" )

if ( CLIENT ) then
	--tool hud lang
	language.Add( "Tool.wire_eyepod.name", "Eye Pod Tool (Wire)" )
	language.Add( "Tool.wire_eyepod.desc", "Spawns an Eye Pod Mouse Controller." )

	--panel control lang
	language.Add( "WireEyePod_DefaultToZero", "Default Outputs To Zero When Inactive" )
	language.Add( "WireEyePod_CumulativeOutput", "Output Cumulative Mouse Position" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 15 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "DefaultToZero" ] = "1"
TOOL.ClientConVar[ "CumulativeOutput" ] = "0"
TOOL.ClientConVar[ "XMin" ] = "0"
TOOL.ClientConVar[ "XMax" ] = "0"
TOOL.ClientConVar[ "YMin" ] = "0"
TOOL.ClientConVar[ "YMax" ] = "0"

if SERVER then
	function TOOL:GetConVars()
		local DefaultToZero = self:GetClientNumber("DefaultToZero")
		local CumulativeOutput = self:GetClientNumber("CumulativeOutput")
		local ShowRateOfChange = (CumulativeOutput ~= 0) and 0 or 1
		--set the default to zero to one if you are showing the mouse position instead
		if (ShowRateOfChange == 1) then DefaultToZero = 1 end

		local ClampXMin = self:GetClientNumber("XMin")
		local ClampXMax = self:GetClientNumber("XMax")
		local ClampYMin = self:GetClientNumber("YMin")
		local ClampYMax = self:GetClientNumber("YMax")
		local ClampX = 0
		local ClampY = 0
		--test clamp
		if ( (ClampXMin ~= 0 or ClampXMax ~= 0) and (ClampYMin ~= 0 or ClampYMax ~= 0) and
			ClampXMin ~= ClampXMax and ClampYMin ~= ClampYMax and
			ClampXMin < ClampXMax and ClampYMin < ClampYMax ) then
			ClampX = 1
			ClampY = 1
		elseif( (ClampXMin == 0 and ClampXMax == 0) or (ClampYMin == 0 or ClampYMax == 0) )then
			if(ClampXMin == 0 and ClampXMax == 0 and (ClampYMin ~= 0 or ClampYMax ~= 0)) then
				ClampX = 0
				ClampY = 1
			elseif(ClampYMin == 0 and ClampYMax == 0 and (ClampXMin ~= 0 or ClampXMax ~= 0)) then
				ClampX = 1
				ClampY = 0
			else
				ClampX = 0
				ClampY = 0
			end
		else
			WireLib.AddNotify(self:GetOwner(), "Invalid Clamping of Wire EyePod Values!", NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP1)
			return 1, 0, 0, 0, 0, 0, 0, 0
		end
		return DefaultToZero, ShowRateOfChange, ClampXMin, ClampXMax, ClampYMin, ClampYMax, ClampX, ClampY
	end
end

WireToolSetup.SetupLinking(true, "eyepod")

-------------------------------------- TOOL Menu ---------------------------------------------------
--TODO:  Figure out a way for dynamic panels to work with check boxes (check boxes that use concommands instead of convars default to 1 allways)
--check for client
if (CLIENT) then

	local function Wire_EyePod_Menu(panel)
		panel:ClearControls()

		panel:AddControl("Header", {
			Text = "#Tool.wire_eyepod.name",
			Description = "#Tool.wire_eyepod.desc"
		})

		--preset chooser
		panel:AddControl("ComboBox", {
			Label = "#Presets",
			MenuButton = "1",
			Folder = "wire_eyepod",

			Options = {
				Default = {
					wire_eyepod_DefaultToZero = "1",
					wire_eyepod_CumulativeOutput = "0",
					wire_eyepod_XMin = "0",
					wire_eyepod_XMax = "0",
					wire_eyepod_YMin = "0",
					wire_eyepod_YMax = "0"
				}
			},

			CVars = {
				[0] = "wire_eyepod_DefaultToZero",
				[1] = "wire_eyepod_CumulativeOutput",
				[2] = "wire_eyepod_XMin",
				[3] = "wire_eyepod_XMax",
				[4] = "wire_eyepod_YMin",
				[5] = "wire_eyepod_YMax"
			}
		})

		WireDermaExts.ModelSelect(panel, "wire_eyepod_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

		panel:AddControl("CheckBox", {
			Label = "#WireEyePod_CumulativeOutput",
			Command = "wire_eyepod_CumulativeOutput"
		})

		panel:AddControl("CheckBox", {
			Label = "#WireEyePod_DefaultToZero",
			Command = "wire_eyepod_DefaultToZero"
		})

		--clamps
		panel:AddControl( "Label",  {
					Text = "\nClamp the output of the EyePod. \nSet both sliders to 0 to remove the clamp in that axis.",
					Description = "Clamps the outputs of the EyePod. Set to 0 not to clamp in that axis"}    )

		panel:AddControl( "Slider",  {
					Label	= "X Min",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_XMin",
					Description = "Clamps the output of the EyePod's X to this minimum"}	 )

		panel:AddControl( "Slider",  {
					Label	= "X Max",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_XMax",
					Description = "Clamps the output of the EyePod's X to this maximum"}	 )
		panel:AddControl( "Slider",  {
					Label	= "Y Min",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_YMin",
					Description = "Clamps the output of the EyePod's Y to this minimum"}	 )

		panel:AddControl( "Slider",  {
					Label	= "Y Max",
					Type	= "Float",
					Min		= -2000,
					Max		= 2000,
					Command = "wire_eyepod_YMax",
					Description = "Clamps the output of the EyePod's Y to this maximum"}	 )
	end

	function TOOL.BuildCPanel( panel )
		Wire_EyePod_Menu(panel)
	end

end
