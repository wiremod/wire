TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Wired Keyboard"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_keyboard.name", "Wired Keyboard Tool (Wire)" )
    language.Add( "Tool.wire_keyboard.desc", "Spawns a keyboard input for use with the hi-speed wire system." )
    language.Add( "Tool.wire_keyboard.0", "Primary: Create/Update Keyboard, Secondary: Link Keyboard to pod, Reload: Unlink" )
	language.Add( "Tool.wire_keyboard.1", "Now select the pod to link to.")
	language.Add( "sboxlimit_wire_keyboard", "You've hit wired keyboards limit!" )
	language.Add( "undone_wirekeyboard", "Undone Wire Keyboard" )
end

if (SERVER) then
	ModelPlug_Register("Keyboard")
	CreateConVar('sbox_maxwire_keyboards', 20)
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_input.mdl",
	sync = "1",
	layout = "American",
	autobuffer = "1",
}


cleanup.Register( "wire_keyboards" )

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if trace.Entity and trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_keyboard" then
		trace.Entity.AutoBuffer = (self:GetClientInfo( "autobuffer" ) ~= "0")
		return true
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90

	local keyboard = MakeWireKeyboard( ply, trace.HitPos, ang, self:GetModel() )
	if not keyboard then return false end

	keyboard.AutoBuffer = (self:GetClientInfo( "autobuffer" ) ~= "0")

	local min = keyboard:OBBMins()
	keyboard:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(keyboard, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireKeyboard")
		undo.AddEntity( keyboard )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_keyboards", keyboard )

	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	local ent = trace.Entity
	if (ent:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if self:GetStage() == 0 then
		if ( not ent:IsValid() or ent:GetClass() ~= "gmod_wire_keyboard" or ent.pl ~= ply ) then return false end

		self:SetStage(1)
		self.LinkSource = ent
		return true
	else
		--TODO: player check is missing. done by the prop protection plugin?
		if ( not ent:IsValid() or not ent:IsVehicle() ) then return false end

		self.LinkSource:LinkPod(ent)

		self:SetStage(0)
		self.LinkSource = nil
		return true
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.LinkSource = nil

	if (!trace.HitPos) then return false end
	local ent = trace.Entity
	if (ent:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( not ent:IsValid() or ent:GetClass() ~= "gmod_wire_keyboard" or ent.pl ~= ply ) then return false end
	ent:LinkPod(nil)
	return true
end

if (SERVER) then

	function MakeWireKeyboard( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_keyboards" ) ) then return false end

		local wire_keyboard = ents.Create( "gmod_wire_keyboard" )
		if (!wire_keyboard:IsValid()) then return false end

		wire_keyboard:SetAngles( Ang )
		wire_keyboard:SetPos( Pos )
		wire_keyboard:SetModel( Model(model or "models/jaanus/wiretool/wiretool_input.mdl") )
		wire_keyboard:Spawn()

		wire_keyboard:SetPlayer( pl )
		wire_keyboard.pl = pl

		pl:AddCount( "wire_keyboards", wire_keyboard )

		return wire_keyboard
	end

	duplicator.RegisterEntityClass("gmod_wire_keyboard", MakeWireKeyboard, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireKeyboard( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_keyboard" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireKeyboard( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_input.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_keyboard.name", Description = "#Tool.wire_keyboard.desc" })
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_keyboard", true)

	local sync = vgui.Create( "DCheckBoxLabel" )
	sync:SetConVar( "wire_keyboard_sync" )
	sync:SetText( "Synchronous Keyboard" )
	sync:SetToolTip( "Pause user input when keyboard is active (clientside)" )
	panel:AddItem( sync )

	local txt = vgui.Create("DLabel")
	txt:SetText("Keyboard language layout:")
	txt:SetToolTip("If you would like to contribute your keyboard layout, so that it may be added, go post on the wiremod forums.")
	panel:AddItem(txt)

	local list = vgui.Create("DComboBox")
	for k,v in pairs( Wire_Keyboard_Remap ) do
		list:AddChoice( k )
		list:SetConVar( "wire_keyboard_layout" )
	end
	panel:AddItem(list)

	local autobuffer = vgui.Create( "DCheckBoxLabel" )
	autobuffer:SetConVar( "wire_keyboard_autobuffer" )
	autobuffer:SetText( "Automatic buffer handling" )
	autobuffer:SetToolTip( "When on, automatically removes the key from the buffer when the user releases it.\nWhen off, leaves all keys in the buffer until they are manually removed.\nTo manually remove a key, write any value to cell 0 to remove the first key, or write a specific ascii value to any address other than 0 to remove that specific key." )
	panel:AddItem( autobuffer )
end
