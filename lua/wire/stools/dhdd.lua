WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "dhdd", "DHDD", "gmod_wire_dhdd", nil, "DHDDs" )

if (SERVER) then

	CreateConVar("sbox_maxwire_dhdds",20)

else

	----------------------------------------------------------------------------------------------------
	-- Tool Info
	----------------------------------------------------------------------------------------------------

	language.Add( "Tool.wire_dhdd.name", "DHDD Tool (Wire)" )
	language.Add( "Tool.wire_dhdd.desc", "Spawns a dupeable hard drive gate for use with the wire system." )
	language.Add( "Tool.wire_dhdd.0", "Primary: Create DHDD." )
	language.Add( "sboxlimit_wire_dhdds", "You've hit the Wire DHDD limit!" )
	language.Add( "undone_wiredhdd", "Undone Wire DHDD" )

	language.Add( "Tool_wire_dhdd_weld", "Weld the DHDD." )
	language.Add( "Tool_wire_dhdd_weldtoworld", "Weld the DHDD to the world." )
	language.Add( "Tool_wire_dhdd_freeze", "Freeze the DHDD." )
	language.Add( "Tool_wire_dhdd_note", "NOTE: The DHDD only saves the first\n512^2 values to prevent\nmassive dupe files and lag." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["weldtoworld"] = 0
	TOOL.ClientConVar["freeze"] = 1

	----------------------------------------------------------------------------------------------------
	-- BuildCPanel
	----------------------------------------------------------------------------------------------------

	function TOOL.BuildCPanel( CPanel )
		CPanel:AddControl("Header", { Text = "#Tool.wire_dhdd.name", Description = "#Tool.wire_dhdd.desc" })

		local mdl = vgui.Create("DWireModelSelect",CPanel)
		mdl:SetModelList( list.Get( "Wire_gate_Models" ), "wire_dhdd_model" )
		mdl:SetHeight( 4 )
		CPanel:AddItem( mdl )

		local weld = vgui.Create("DCheckBoxLabel",CPanel)
		weld:SetText( "#Tool_wire_dhdd_weld" )
		weld:SizeToContents()
		weld:SetConVar( "wire_dhdd_weld" )
		CPanel:AddItem( weld )

		local toworld = vgui.Create("DCheckBoxLabel",CPanel)
		toworld:SetText( "#Tool_wire_dhdd_weldtoworld" )
		toworld:SizeToContents()
		toworld:SetConVar( "wire_dhdd_weldtoworld" )
		CPanel:AddItem( toworld )

		local freeze = vgui.Create("DCheckBoxLabel",CPanel)
		freeze:SetText( "#Tool_wire_dhdd_freeze" )
		freeze:SizeToContents()
		freeze:SetConVar( "wire_dhdd_freeze" )
		CPanel:AddItem( freeze )

		local label = vgui.Create("DLabel",CPanel)
		label:SetText( "#Tool_wire_dhdd_note" )
		label:SizeToContents()
		CPanel:AddItem( label )
	end

end

cleanup.Register( "wire_dhdds" )
--------------------
-- LeftClick
-- Create DHDD
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

	local dhdd = MakeWireDHDD( ply, Pos, Ang, model )

	if (!dhdd or !dhdd:IsValid()) then return false end

	local weld
	if (self:GetClientNumber( "weld" ) != 0) then
		weld = WireLib.Weld( dhdd, trace.Entity, trace.PhysicsBone, true, false, self:GetClientNumber( "weldtoworld" ) != 0 )
	end

	if (self:GetClientNumber( "freeze") != 0) then
		dhdd:GetPhysicsObject():EnableMotion( false )
	end

	undo.Create("wiresocket")
		undo.AddEntity( dhdd )
		if (weld) then undo.AddEntity( weld ) end
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dhdds", dhdd )

	return true
end


--------------------
-- MakeWireDHDD
-- Creation Function
--------------------
if (SERVER) then
	function MakeWireDHDD( ply, Pos, Ang, model )
		if (!ply:CheckLimit( "wire_dhdds" )) then return false end

		local dhdd = ents.Create( "gmod_wire_dhdd" )
		if (!dhdd:IsValid()) then return false end

		dhdd:SetAngles( Ang )
		dhdd:SetPos( Pos )
		dhdd:SetModel( model )
		dhdd:SetPlayer( ply )
		dhdd:Spawn()
		dhdd:Activate()

		ply:AddCount( "wire_dhdds", dhdd )

		return dhdd
	end
	duplicator.RegisterEntityClass( "gmod_wire_dhdd", MakeWireDHDD, "Pos", "Ang", "model" )
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
