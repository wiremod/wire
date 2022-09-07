WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "clutch", "Clutch", "gmod_wire_clutch", nil, "Clutchs" )

if CLIENT then
	language.Add( "Tool.wire_clutch.name", "Clutch Tool (Wire)" )
	language.Add( "Tool.wire_clutch.desc", "Control rotational friction between props" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Place/Select a clutch controller" },
		{ name = "right_0", stage = 0, text = "Select an entity to apply the clutch to" },
		{ name = "reload_0", stage = 0, text = "Remove clutch from entity/deselect controller" },
		{ name = "right_1", stage = 1, text = "Right click on the second entity you want the clutch to apply to" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 8 )

if SERVER then
	CreateConVar( "wire_clutch_maxlinks", 10 )	-- how many constraints can be added per controller
	CreateConVar( "wire_clutch_maxrate", 40 )	-- how many constraints/sec may be changed per controller
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
cleanup.Register( "wire_clutch" )


/*---------------------------------------------------------
   -- Server Usermessages --
   Send entity tables for the DrawHUD display
---------------------------------------------------------*/
local Send_Links

if SERVER then
	// Send info: constraints associated with the selected clutch controller
	Send_Links = function( ply, constrained_pairs )
		umsg.Start( "wire_clutch_links", ply )
			local num_constraints = #constrained_pairs
			umsg.Short( num_constraints )

			for k, v in pairs( constrained_pairs ) do
				umsg.Entity( v.Ent1 )
				umsg.Entity( v.Ent2 )
			end
		umsg.End()
	end
end


/*---------------------------------------------------------
   -- Client Usermessages --
   Receive entity tables for the DrawHUD display
---------------------------------------------------------*/
if CLIENT then
	local Linked_Ents = {}		-- Table of constrained ents, with Ent1 as k and Ent2 as v
	local Unique_Ents = {}		-- Table of entities as keys

	// Receive stage 0 info
	local function Receive_links( um )
		table.Empty( Linked_Ents )
		local num_constraints = um:ReadShort() or 0

		if num_constraints ~= 0 then
			for i = 1, num_constraints do
				local Ent1 = um:ReadEntity()
				local Ent2 = um:ReadEntity()
				table.insert( Linked_Ents, {Ent1 = Ent1, Ent2 = Ent2} )

				Unique_Ents[Ent1] = true
				Unique_Ents[Ent2] = true
			end
		end
	end

	usermessage.Hook( "wire_clutch_links", Receive_links )

	/*---------------------------------------------------------
	   -- DrawHUD --
	   Display clutch constraints associated with a controller
	---------------------------------------------------------*/
	local function InView( pos2D )
		if pos2D.x > 0 and pos2D.y > 0 and pos2D.x < ScrW() and pos2D.y < ScrH() then
			return true
		end
		return false
	end


	// Client function for drawing a line to represent constraint to world
	local function DrawBaseLine( pos, viewpos )
		local dist = math.Clamp( viewpos:Distance( pos ), 50, 5000 )
		local linelength = 3000 / dist

		local pos2D = pos:ToScreen()
		local pos1 = { x = pos2D.x + linelength, y = pos2D.y }
		local pos2 = { x = pos2D.x - linelength, y = pos2D.y }

		surface.DrawLine( pos1.x, pos1.y, pos2.x, pos2.y )
	end


	// Client function for drawing a circle around the currently selected controller
	local function DrawSelectCircle( pos, viewpos )
		local pos2D = pos:ToScreen()

		if InView( pos2D ) then
			surface.DrawCircle( pos2D.x, pos2D.y, 7, Color(255, 100, 100, 255 ) )
		end
	end

	function TOOL:DrawHUD()
		local DrawnEnts = {}	-- Used to keep track of which ents already have a circle

		local controller = self:GetWeapon():GetNWEntity( "WireClutchController" )
		if not IsValid( controller ) then return end

		// Draw circle around the controller
		local viewpos = LocalPlayer():GetViewModel():GetPos()
		local controllerpos = controller:LocalToWorld( controller:OBBCenter() )
		DrawSelectCircle( controllerpos, viewpos )

		local numconstraints_0 = #Linked_Ents
		if numconstraints_0 ~= 0 then
			// Draw lines between each pair of constrained ents
			surface.SetDrawColor( 100, 255, 100, 255 )


			// Check whether each entity/position can be drawn
			for k, v in pairs( Linked_Ents ) do
				local basepos
				local pos1, pos2

				local IsValid1 = IsValid( v.Ent1 )
				local IsValid2 = IsValid( v.Ent2 )

				if IsValid1 then pos1 = v.Ent1:GetPos():ToScreen() end
				if IsValid2 then pos2 = v.Ent2:GetPos():ToScreen() end

				if not IsValid1 and not IsValid2 then
					table.remove( Linked_Ents, k )
				elseif v.Ent1:IsWorld() then
					basepos = v.Ent2:GetPos() + Vector(0, 0, -30)
					pos1 = basepos:ToScreen()
				elseif v.Ent2:IsWorld() then
					basepos = v.Ent1:GetPos() + Vector(0, 0, -30)
					pos2 = basepos:ToScreen()
				end

				if pos1 and pos2 then
					if InView( pos1 ) and InView( pos2 ) then
						surface.DrawLine( pos1.x, pos1.y, pos2.x, pos2.y )

						if not DrawnEnts[v.Ent1] and IsValid1 then
							surface.DrawCircle( pos1.x, pos1.y, 5, Color(100, 255, 100, 255 ) )
							DrawnEnts[v.Ent1] = true
						end

						if not DrawnEnts[v.Ent2] and IsValid2 then
							surface.DrawCircle( pos2.x, pos2.y, 5, Color(100, 255, 100, 255 ) )
							DrawnEnts[v.Ent2] = true
						end

						if basepos then
							DrawBaseLine( basepos, viewpos )
						end
					end
				end
			end
		end
	end
end


if SERVER then
	function TOOL:SelectController( controller )
		self.controller = controller
		self:GetWeapon():SetNWEntity( "WireClutchController", controller or Entity(0) ) -- Must use null entity since nil won't send

		// Send constraint from the controller to the client
		local constrained_pairs = {}
		if IsValid( controller ) then
			constrained_pairs = controller:GetConstrainedPairs()
		end

		Send_Links( self:GetOwner(), constrained_pairs )
	end

	function TOOL:PostMake(ent)
		self:SelectController(ent)
	end

	function TOOL:LeftClick_Update( trace )
		self:PostMake(trace.Entity)
	end
end

/*---------------------------------------------------------
   -- Right click --
   Associates ents with the currently selected controller
---------------------------------------------------------*/
function TOOL:RightClick( trace )
	if CLIENT then return true end

	local ply = self:GetOwner()
	local stage = self:NumObjects()

	if not IsValid( self.controller ) then
		ply:PrintMessage( HUD_PRINTTALK, "Select a clutch controller with left click first" )
		return
	end

	if ( not IsValid( trace.Entity ) and not trace.Entity:IsWorld() ) or trace.Entity:IsPlayer() then return end

	// First click: select the first entity
	if stage == 0 then
		if trace.Entity:IsWorld() then
			ply:PrintMessage( HUD_PRINTTALK, "Select a valid entity" )
			return
		end

		// Check that we won't be going over the max number of links allowed
		local maxlinks = GetConVarNumber( "wire_clutch_maxlinks", 10 )
		if table.Count( self.controller.clutch_ballsockets ) >= maxlinks then
			ply:PrintMessage( HUD_PRINTTALK, "A maximum of " .. tostring( maxlinks ) .. " links are allowed per clutch controller" )
			return
		end

		// Store this entity for use later
		local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

		self:SetStage(1)

	// Second click: select the second entity, and update the controller
	else
		local Ent1, Ent2 = self:GetEnt(1), trace.Entity

		if Ent1 == Ent2 then
			ply:PrintMessage( HUD_PRINTTALK, "Select a different entity" )
			return false
		end

		// Check that these ents aren't already registered on this controller
		if self.controller:ClutchExists( Ent1, Ent2 ) then
			ply:PrintMessage( HUD_PRINTTALK, "Entities have already been registered to this controller!" )
			return true
		end

		// Add this constraint to the clutch controller
		self.controller:AddClutch( Ent1, Ent2 )
		WireLib.AddNotify( ply, "Entities registered with clutch controller", NOTIFY_GENERIC, 7 )

		// Update client
		Send_Links( ply, self.controller:GetConstrainedPairs() )

		self:ClearObjects()
		self:SetStage(0)

	end

	return true
end


/*---------------------------------------------------------
   -- Reload --
   Remove clutch association between current controller and
	the traced entity
   Removes all current selections if hits world
---------------------------------------------------------*/
function TOOL:Reload( trace )
	local stage = self:NumObjects()

	if stage == 1 then
		self:ClearObjects()
		self:SetStage(0)
		return

	// Remove clutch associations with this entity
	elseif IsValid( self.controller ) then
		if trace.Entity:IsWorld() then
			self:ClearObjects()
			self:SetStage(0)
			self.controller = nil

		else
			for k, v in pairs( self.controller.clutch_ballsockets ) do
				if k.Ent1 == trace.Entity or k.Ent2 == trace.Entity then
					self.controller:RemoveClutch( k )
				end
			end

		end

		// Update client with new constraint info
		self:SelectController( self.controller )
	end

	return true
end

function TOOL:Holster()
	self:ClearObjects()
	self:SetStage(0)
	self:ReleaseGhostEntity()
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.wire_clutch.name", Description = "#Tool.wire_clutch.desc" } )
	WireDermaExts.ModelSelect(panel, "wire_clutch_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end


if CLIENT then return end
