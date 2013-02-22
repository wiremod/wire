WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hoverdrivecontroller", "Hoverdrive Controller", "gmod_wire_hoverdrivecontroler", nil, "Hoverdrive Controllers" )

if ( CLIENT ) then
    language.Add( "Tool.wire_hoverdrivecontroller.name", "Hoverdrive Controller Tool" )
    language.Add( "Tool.wire_hoverdrivecontroller.desc", "Spawns a Hoverdrive Controller." )
    language.Add( "Tool.wire_hoverdrivecontroller.0", "Primary: Create Hoverdrive Controller, Reload: Change Hoverdrive Controller Model" )
	language.Add( "sboxlimit_wire_hoverdrives", "You've hit the Hoverdrive Controller limit!" )
	language.Add( "undone_wire_hoverdrive", "Undone Hoverdrive Controller" )
	language.Add( "Tool_wire_hoverdrivecontroller_effects", "Toggle effects" )
	language.Add( "Tool_wire_hoverdrivecontroller_sounds", "Toggle sounds (Also has an input)" )
elseif ( SERVER ) then
    CreateConVar('sbox_maxwire_hoverdrives',2)
	CreateConVar("wire_hoverdrive_cooldown","2",{FCVAR_ARCHIVE,FCVAR_NOTIFY})
end

TOOL.ClientConVar[ "model" ] = "models/props_c17/utilityconducter001.mdl"
TOOL.ClientConVar[ "effects" ] = 1
TOOL.ClientConVar[ "sounds" ] = 1
cleanup.Register( "wire_hoverdrivecontrollers" )

if (SERVER) then
	function TOOL:CreateTeleporter( ply, trace, Model )
		if (!ply:CheckLimit("wire_hoverdrives")) then return end
		local ent = ents.Create( "gmod_wire_hoverdrivecontroler" )
		if (!ent:IsValid()) then return end

		-- Pos/Model/Angle
		ent:SetModel( Model )
		ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )
		ent:SetAngles( trace.HitNormal:Angle() + Angle(90,0,0) )

		ent:Spawn()
		ent:Activate()
		ent:SetPlayer(ply)

		ent.UseEffects = (self:GetClientNumber( "effects" ) == 1)
		ent.UseSounds = (self:GetClientNumber( "sounds" ) == 1)

		ply:AddCount( "wire_hoverdrives", ent )

		ent:ShowOutput()

		return ent
	end

	function TOOL:LeftClick( trace )
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
		local ply = self:GetOwner()

		if trace.Entity and trace.Entity:GetClass() == "gmod_wire_hoverdrivecontroler" then
			trace.Entity.UseEffects = (self:GetClientNumber( "effects" ) == 1)
			trace.Entity.UseSounds = (self:GetClientNumber( "sounds" ) == 1)
			trace.Entity:ShowOutput()
			return true
		end

		local ent = self:CreateTeleporter( ply, trace, self:GetModel() )

		local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
		undo.Create("wire_hoverdrive")
			undo.AddEntity( ent )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( "wire_hoverdrivecontrollers", ent )

		return true
	end


else
	function TOOL:LeftClick( trace ) return !trace.Entity:IsPlayer() end

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_hoverdrivecontroller_model", list.Get( "WireHoverdriveModels" ), 4)
		panel:CheckBox("#Tool_wire_hoverdrivecontroller_effects","wire_hoverdrivecontroller_effects")
		panel:CheckBox("#Tool_wire_hoverdrivecontroller_sounds","wire_hoverdrivecontroller_sounds")
	end
end

function TOOL:Reload( trace )
	if (!trace) then return end
	if (!trace.Hit) then return end
	if (trace.Entity) then
		if game.SinglePlayer() then
			self:GetOwner():ConCommand("wire_hoverdrivecontroller_model " .. trace.Entity:GetModel())
			self:GetOwner():ChatPrint("Hoverdrive Controller model set to: " .. trace.Entity:GetModel())
		else
			if (CLIENT) then
				RunConsoleCommand("wire_hoverdrivecontroller_model", trace.Entity:GetModel())
			else
				self:GetOwner():ChatPrint("Hoverdrive Controller model set to: " .. trace.Entity:GetModel())
			end
		end
	end
	return true
end
