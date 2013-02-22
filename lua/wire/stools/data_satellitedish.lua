WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "data_satellitedish", "Satellite Dish", "gmod_wire_data_satellitedish", nil, "Satellite Dishs" )

if ( CLIENT ) then
    language.Add( "Tool.wire_data_satellitedish.name", "Satellite Dish Tool (Wire)" )
    language.Add( "Tool.wire_data_satellitedish.desc", "Spawns a Satellite Dish." )
    language.Add( "Tool.wire_data_satellitedish.0", "Primary: Create Satellite Dish/Display Link Info, Secondary: Link/Unlink Satellite Dish, Reload: Change model" )
	language.Add( "Tool.wire_data_satellitedish.1", "Now select the transmitter to link to" )
    language.Add( "WireDataTransfererTool_data_satellitedish", "Satellite Dish:" )
	language.Add( "sboxlimit_wire_data_satellitedishs", "You've hit Satellite Dishs limit!" )
	language.Add( "undone_Wire Data Satellite Dish", "Undone Wire Satellite Dish" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_satellitedishs', 20)
end

TOOL.ClientConVar["Model"] = "models/kobilica/wiremonitorrtbig.mdl"

TOOL.FirstSelected = nil

cleanup.Register( "wire_data_satellitedishs" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	self:SetStage(0)

	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ) then
		local satellite_dish = trace.Entity
		if IsValid(satellite_dish.Transmitter) then
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDishTransmitter", satellite_dish.Transmitter )
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDish", satellite_dish )
			return true
		else
			ply:PrintMessage( HUD_PRINTTALK, "Satellite Dish not linked" )
			return false
		end
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_satellitedishs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local model = self:GetClientInfo("Model")
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end
	local wire_data_satellitedish = MakeWireSatellitedish( ply, trace.HitPos, Ang, model)

	local min = wire_data_satellitedish:OBBMins()
	wire_data_satellitedish:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_satellitedish, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Satellite Dish")
		undo.AddEntity( wire_data_satellitedish )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_satellitedishs", wire_data_satellitedish )
	ply:AddCleanup( "wire_data_satellitedishs", const )

	return true
end

function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() ) then
		if ( self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ) then
			self.selected_dish = trace.Entity
			self:SetStage(1)
			return true
		elseif ( self:GetStage() == 1  ) then
			self:SetStage(0)
			if trace.Entity == self.selected_dish then
				ply:PrintMessage( HUD_PRINTTALK, "Satellite Dish unlinked" )
				self.selected_dish.Transmitter = null
				self.selected_dish:ShowOutput()
				self:GetWeapon():SetNetworkedEntity( "WireSatelliteDishTransmitter", self.selected_dish )
				self:GetWeapon():SetNetworkedEntity( "WireSatelliteDish", self.selected_dish ) --Set both to same point so line won't draw
				return true
			elseif trace.Entity:GetClass() != "gmod_wire_data_transferer" then
				ply:PrintMessage( HUD_PRINTTALK, "Satellite Dishes can only be linked to Wire Data Transferers!" )
				return true
			end

			self.selected_dish.Transmitter = trace.Entity
			self.selected_dish:ShowOutput()
			self:SetStage(0)
			self:GetOwner():PrintMessage( HUD_PRINTTALK,"Satellite Dish linked" )
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDishTransmitter", self.selected_dish.Transmitter )
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDish", self.selected_dish )
			return true
		else
			return false
		end
	end
end

function TOOL:Reload( trace )
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "prop_physics") then
			ply:ConCommand('wire_data_satellitedish_Model "'..trace.Entity:GetModel()..'"\n')
			ply:PrintMessage( HUD_PRINTTALK, "Satellite Dish model set to "..trace.Entity:GetModel() )
		else
			ply:PrintMessage( HUD_PRINTTALK, "Satellite Dishes only accept physics models!" )
		end
	end

	return true
end

function TOOL:DrawHUD()
	local selected_dish = self:GetWeapon():GetNetworkedEntity( "WireSatelliteDishTransmitter" )
	local transmitter = self:GetWeapon():GetNetworkedEntity( "WireSatelliteDish" )
	if ( !IsValid(transmitter) or !IsValid(selected_dish) ) then return end

	local selected_dish_pos = selected_dish:GetPos():ToScreen()
	local transmitter_pos = transmitter:GetPos():ToScreen()
	if ( transmitter_pos.x > 0 and transmitter_pos.y > 0 and transmitter_pos.x < ScrW() and transmitter_pos.y < ScrH() ) then
		surface.SetDrawColor( 255, 255, 100, 255 )
		surface.DrawLine(selected_dish_pos.x, selected_dish_pos.y, transmitter_pos.x, transmitter_pos.y)
	end
end

if (SERVER) then

	function MakeWireSatellitedish( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_data_satellitedishs" ) ) then return false end

		local wire_data_satellitedish = ents.Create( "gmod_wire_data_satellitedish" )
		if (!wire_data_satellitedish:IsValid()) then return false end

		wire_data_satellitedish:SetAngles( Ang )
		wire_data_satellitedish:SetPos( Pos )
		wire_data_satellitedish:SetModel( model )
		wire_data_satellitedish:Spawn()

		wire_data_satellitedish:SetPlayer( pl )
		wire_data_satellitedish.pl = pl

		pl:AddCount( "wire_data_satellitedishs", wire_data_satellitedish )

		return wire_data_satellitedish
	end

	duplicator.RegisterEntityClass("gmod_wire_data_satellitedish", MakeWireSatellitedish, "Pos", "Ang", "Model")

end

function TOOL.BuildCPanel(panel)
end
