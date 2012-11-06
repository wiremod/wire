WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "soundemitter", "Sound Emitter", "gmod_wire_soundemitter", nil, "Sound Emitters" )

if CLIENT then
	language.Add( "tool.wire_soundemitter.name", "Sound Emitter Tool (Wire)" )
	language.Add( "tool.wire_soundemitter.desc", "Spawns a sound emitter for use with the wire system." )
	language.Add( "tool.wire_soundemitter.0", "Primary: Create/Update Sound Emitter" )
	language.Add( "WireEmitterTool_sound", "Sound:" )
	language.Add( "WireEmitterTool_collision", "Collision" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 10, "wire_emitters", "You've hit sound emitters limit!" )

if SERVER then
	ModelPlug_Register("speaker")

	function TOOL:GetConVars()
		return Sound( self:GetClientInfo( "sound" ) )
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireEmitter( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model     = "models/cheeze/wires/speaker.mdl",
	sound     = "synth/square.wav",
	collision = 0,
	weld      = 1,
}
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
		RunConsoleCommand("wire_sound_browser_open",SoundNameText:GetValue())
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

	panel:CheckBox("#WireEmitterTool_collision", "wire_soundemitter_collision")
	ModelPlug_AddToCPanel(panel, "speaker", "wire_soundemitter", true)
	panel:CheckBox("Weld", "wire_soundemitter_weld")
end
