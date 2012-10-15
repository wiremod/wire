TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Memory - ROM"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (SERVER) then

	CreateConVar("sbox_maxwire_roms",20)

else

	----------------------------------------------------------------------------------------------------
	-- Tool Info
	----------------------------------------------------------------------------------------------------

	language.Add( "Tool.wire_rom.name", "ROM Tool (Wire)" )
	language.Add( "Tool.wire_rom.desc", "Spawns a ROM chip" )
	language.Add( "Tool.wire_rom.0", "Primary: Create ROM." )
	language.Add( "sboxlimit_wire_roms", "You've hit the Wire ROM limit!" )
	language.Add( "undone_wirerom", "Undone Wire ROM" )

	language.Add( "Tool_wire_rom_weld", "Weld the ROM." )
	language.Add( "Tool_wire_rom_weldtoworld", "Weld the ROM to the world." )
	language.Add( "Tool_wire_rom_freeze", "Freeze the ROM." )
	language.Add( "Tool_wire_rom_note", "ROM size will depend on written data.\nThe maximum size is 256 KB." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["weldtoworld"] = 0
	TOOL.ClientConVar["freeze"] = 1

	----------------------------------------------------------------------------------------------------
	-- BuildCPanel
	----------------------------------------------------------------------------------------------------

	function TOOL.BuildCPanel( CPanel )
		CPanel:AddControl("Header", { Text = "#Tool.wire_rom.name", Description = "#Tool.wire_rom.desc" })

		local mdl = vgui.Create("DWireModelSelect",CPanel)
		mdl:SetModelList( list.Get( "Wire_gate_Models" ), "wire_rom_model" )
		mdl:SetHeight( 4 )
		CPanel:AddItem( mdl )

		local weld = vgui.Create("DCheckBoxLabel",CPanel)
		weld:SetText( "#Tool_wire_rom_weld" )
		weld:SizeToContents()
		weld:SetConVar( "wire_rom_weld" )
		CPanel:AddItem( weld )

		local toworld = vgui.Create("DCheckBoxLabel",CPanel)
		toworld:SetText( "#Tool_wire_rom_weldtoworld" )
		toworld:SizeToContents()
		toworld:SetConVar( "wire_rom_weldtoworld" )
		CPanel:AddItem( toworld )

		local freeze = vgui.Create("DCheckBoxLabel",CPanel)
		freeze:SetText( "#Tool_wire_rom_freeze" )
		freeze:SizeToContents()
		freeze:SetConVar( "wire_rom_freeze" )
		CPanel:AddItem( freeze )

		local label = vgui.Create("DLabel",CPanel)
		label:SetText( "#Tool_wire_rom_note" )
		label:SizeToContents()
		CPanel:AddItem( label )
	end

end

cleanup.Register( "wire_roms" )

----------------------------------------------------------------------------------------------------
-- GetMode
----------------------------------------------------------------------------------------------------

function TOOL:GetModel()
	local model = self:GetClientInfo( "model" )
	if (!util.IsValidModel( model ) or !util.IsValidProp( model )) then return "models/jaanus/wiretool/wiretool_gate.mdl" end
	return model
end
--------------------
-- LeftClick
-- Create ROM
--------------------
function TOOL:LeftClick( trace )
	if (!trace) then return false end
	if (trace.Entity) then
		if (trace.Entity:IsPlayer()) then return false end
	end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()
	local model = self:GetModel()
	local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + Angle(90,0,0)

	local rom = MakeWireDHDD( ply, Pos, Ang, model )
	rom.ROM = true
	rom:SetOverlayText("ROM")

	if (!rom or !rom:IsValid()) then return false end

	local weld
	if (self:GetClientNumber( "weld" ) != 0) then
		weld = WireLib.Weld( rom, trace.Entity, trace.PhysicsBone, true, false, self:GetClientNumber( "weldtoworld" ) != 0 )
	end

	if (self:GetClientNumber( "freeze") != 0) then
		rom:GetPhysicsObject():EnableMotion( false )
	end

	undo.Create("wiresocket")
		undo.AddEntity( rom )
		if (weld) then undo.AddEntity( weld ) end
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_roms", rom )

	return true
end

----------------------------------------------------------------------------------------------------
-- GHOST
----------------------------------------------------------------------------------------------------

if ((game.SinglePlayer() and SERVER) or (!game.SinglePlayer() and CLIENT)) then
	function TOOL:DrawGhost()
		local ent, ply = self.GhostEntity, self:GetOwner()
		if (!ent or !ent:IsValid()) then return end
		local trace = ply:GetEyeTrace()

		if (!trace.Hit or trace.Entity:IsPlayer()) then
			ent:SetNoDraw( true )
			return
		end

		local Pos, Ang = trace.HitPos, trace.HitNormal:Angle() + Angle(90,0,0)
		ent:SetPos( Pos )
		ent:SetAngles( Ang )

		ent:SetNoDraw( false )
	end

	function TOOL:Think()
		local model = self:GetModel()
		if (!self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() != model) then
			self:MakeGhostEntity( model, Vector(), Angle() )
		end

		self:DrawGhost()
	end
end
