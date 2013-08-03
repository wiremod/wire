WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "data_satellitedish", "Satellite Dish", "gmod_wire_data_satellitedish", nil, "Satellite Dishs" )

if ( CLIENT ) then
    language.Add( "Tool.wire_data_satellitedish.name", "Satellite Dish Tool (Wire)" )
    language.Add( "Tool.wire_data_satellitedish.desc", "Spawns a Satellite Dish." )
    language.Add( "Tool.wire_data_satellitedish.0", "Primary: Create Satellite Dish/Display Link Info, Secondary: Link/Unlink Satellite Dish, Reload: Change model" )
	language.Add( "Tool.wire_data_satellitedish.1", "Now select the transmitter to link to" )
    language.Add( "WireDataTransfererTool_data_satellitedish", "Satellite Dish:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar["Model"] = "models/kobilica/wiremonitorrtbig.mdl"

function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	self:SetStage(0)
	local ply = self:GetOwner()

	if ( trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ) then
		local satellite_dish = trace.Entity
		if IsValid(satellite_dish.Transmitter) then
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDishTransmitter", satellite_dish.Transmitter )
			self:GetWeapon():SetNetworkedEntity( "WireSatelliteDish", satellite_dish )
			return true
		else
			ply:PrintMessage( HUD_PRINTTALK, "Satellite Dish not linked" )
			return false
		end
	else
		local ent = self:LeftClick_Make( trace, ply )
		return self:LeftClick_PostMake( ent, ply, trace )
	end
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

function TOOL.BuildCPanel(panel)
end
