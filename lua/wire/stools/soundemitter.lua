WireToolSetup.setCategory( "Other/Sound" )
WireToolSetup.open( "soundemitter", "Sound Emitter", "gmod_wire_soundemitter", nil, "Sound Emitters" )

if CLIENT then
	language.Add( "tool.wire_soundemitter.name", "Sound Emitter Tool (Wire)" )
	language.Add( "tool.wire_soundemitter.desc", "Spawns a sound emitter for use with the wire system." )
	language.Add( "WireEmitterTool_sound", "Sound:" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Open Sound Browser" },
	}

	WireToolSetup.setToolMenuIcon( "bull/various/subwoofer" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 10 )

if SERVER then
	ModelPlug_Register("speaker")

	function TOOL:GetConVars()
		return self:GetClientInfo( "sound" )
	end
end

TOOL.ClientConVar = {
	model     = "models/cheeze/wires/speaker.mdl",
	sound     = "synth/square.wav",
}

function TOOL:RightClick( trace )
	if SERVER and not game.SinglePlayer() then return false end
	RunConsoleCommand("wire_sound_browser_open", self:GetClientInfo("sound"), "1")

	return false
end

function TOOL.BuildCPanel(panel)

	local wide = panel:GetWide()

	local SoundNameText = vgui.Create("DTextEntry", ValuePanel)
	SoundNameText:SetText("")
	SoundNameText:SetWide(wide)
	SoundNameText:SetTall(20)
	SoundNameText:SetMultiline(false)
	SoundNameText:SetConVar("wire_soundemitter_sound")
	SoundNameText:SetVisible(true)
	panel:AddItem(SoundNameText)

	local SoundBrowserButton = vgui.Create("DButton")
	SoundBrowserButton:SetText("Open Sound Browser")
	SoundBrowserButton:SetWide(wide)
	SoundBrowserButton:SetTall(20)
	SoundBrowserButton:SetVisible(true)
	SoundBrowserButton.DoClick = function()
		RunConsoleCommand("wire_sound_browser_open", SoundNameText:GetValue(), "1")
	end
	panel:AddItem(SoundBrowserButton)

	local SoundPre = vgui.Create("DPanel")
	SoundPre:SetWide(wide)
	SoundPre:SetTall(20)
	SoundPre:SetVisible(true)

	local SoundPreWide = SoundPre:GetWide()

	local SoundPrePlay = vgui.Create("DButton", SoundPre)
	SoundPrePlay:SetText("Play")
	SoundPrePlay:SetWide(SoundPreWide / 2)
	SoundPrePlay:SetPos(0, 0)
	SoundPrePlay:SetTall(20)
	SoundPrePlay:SetVisible(true)
	SoundPrePlay.DoClick = function()
		RunConsoleCommand("play",SoundNameText:GetValue())
	end

	local SoundPreStop = vgui.Create("DButton", SoundPre)
	SoundPreStop:SetText("Stop")
	SoundPreStop:SetWide(SoundPreWide / 2)
	SoundPreStop:SetPos(SoundPreWide / 2, 0)
	SoundPreStop:SetTall(20)
	SoundPreStop:SetVisible(true)
	SoundPreStop.DoClick = function()
		RunConsoleCommand("play", "common/NULL.WAV") //Playing a silent sound will mute the preview but not the sound emitters.
	end
	panel:AddItem(SoundPre)
	SoundPre:InvalidateLayout(true)
	SoundPre.PerformLayout = function()
		local SoundPreWide = SoundPre:GetWide()
		SoundPrePlay:SetWide(SoundPreWide / 2)
		SoundPreStop:SetWide(SoundPreWide / 2)
		SoundPreStop:SetPos(SoundPreWide / 2, 0)
	end

	ModelPlug_AddToCPanel(panel, "speaker", "wire_soundemitter", true)
end
