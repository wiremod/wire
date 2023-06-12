AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Clutch"
ENT.Purpose         = "Allows rotational friction to be varied dynamically"
ENT.WireDebugName = "Clutch"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Friction" } )
	--self.Outputs = Wire_CreateOutputs( self, { "Welded" } )

	self.clutch_friction = 0
	self.clutch_ballsockets = {}	-- Table of constraints as keys

	self:UpdateOverlay()
end

function ENT:UpdateOverlay()
	local text = "Friction: " .. tostring( self.clutch_friction ) .. "\n"

	local num_constraints = table.Count( self.clutch_ballsockets )
	if num_constraints > 0 then
		text = text .. "Links: " .. tostring( num_constraints )
	else
		text = text .. "Unlinked"
	end

	self:SetOverlayText( text )
end


--[[-------------------------------------------------------
   -- Constraint functions --
   Functions for handling clutch constraints
---------------------------------------------------------]]

function ENT:ClutchExists( Ent1, Ent2 )
	for k, _ in pairs( self.clutch_ballsockets ) do
		if  ( Ent1 == k.Ent1 and Ent2 == k.Ent2 ) or
			( Ent1 == k.Ent2 and Ent2 == k.Ent1 ) then
			return true
		end
	end

	return false
end


-- Returns an array with each entry as a table containing Ent1, Ent2
function ENT:GetConstrainedPairs()
	local ConstrainedPairs = {}
	for k, _ in pairs( self.clutch_ballsockets ) do
		if IsValid( k ) then
			table.insert( ConstrainedPairs, {Ent1 = k.Ent1, Ent2 = k.Ent2} )
		else
			self.clutch_ballsockets[k] = nil
		end
	end
	return ConstrainedPairs
end


local function NewBallSocket( Ent1, Ent2, friction )
	if not IsValid( Ent1 ) or not IsValid( Ent2 ) then return false end

	local ballsocket = constraint.AdvBallsocket( Ent1, Ent2, 0, 0,
		Vector(0,0,0), Vector(0,0,0), 0, 0,
		-180, -180, -180, 180, 180, 180,
		friction, friction, friction, 1, 0 )

	if ballsocket then
		-- Prevent ball socket from being affected by dupe/remove functions
		ballsocket.Type = ""
	end

	return ballsocket
end


-- Register a new clutch association with the controller
function ENT:AddClutch( Ent1, Ent2, friction )
	local ballsocket = NewBallSocket( Ent1, Ent2, friction or self.clutch_friction )

	if ballsocket then
		self.clutch_ballsockets[ballsocket] = true
		ballsocket:CallOnRemove( "WireClutchRemove", function()
			if self.clutch_ballsockets[ballsocket] then
				-- The table value is still true so something unknown killed the ballsocket
				-- Set the table so that nothing else runs into issues
				self.clutch_ballsockets[ballsocket] = nil
				self:UpdateOverlay()
				-- Wait a frame so nothing bad happens, then rebuild it
				timer.Simple(0, function()
					if self:IsValid() then
						self:AddClutch( Ent1, Ent2, friction )
					end
				end)
			end
		end)
	end

	self:UpdateOverlay()
	return ballsocket
end


-- Remove a new clutch association from the controller
function ENT:RemoveClutch( const )
	self.clutch_ballsockets[const]	= nil

	if IsValid( const ) then
		const:Remove()
	end

	self:UpdateOverlay()
end


function ENT:SetClutchFriction( const, friction )
	-- There seems to be no direct way to edit constraint friction, so we must create a new ball socket constraint
	self.clutch_ballsockets[const] = nil

	if IsValid( const ) then
		local Ent1 = const.Ent1
		local Ent2 = const.Ent2

		const:Remove()

		local newconst = NewBallSocket( Ent1, Ent2, friction )
		if newconst then
			self.clutch_ballsockets[newconst] = true
		end

	else
		print("Wire Clutch: Attempted to set friction on invalid constraint")
	end

	return true
end


function ENT:OnRemove()
	for k in pairs( self.clutch_ballsockets ) do
		self:RemoveClutch( k )
	end
end


--[[-------------------------------------------------------
   -- Main controller functions --
   Handle controller tables, wire input
---------------------------------------------------------]]
-- Used for setting/restoring entity mass when creating the clutch constraint
local function SaveMass( MassTable, ent )
	if IsValid( ent ) and not MassTable[ent] then
		local Phys = ent:GetPhysicsObject()
		if IsValid( Phys ) then
			MassTable[ent] = Phys:GetMass()
			Phys:SetMass(1)
		end
	end
end

local function RestoreMass( MassTable )
	for k, v in pairs( MassTable ) do
		k:GetPhysicsObject():SetMass( v )
	end
end


-- Set friction on all constrained ents, called by input or timer (if delayed)
function ENT:UpdateFriction()
	-- Set masses to 1 - this will prevents friction from varying depending on mass
	local MassTable = {}

	-- Create a table copy so when we start ammending self.clutch_ballsockets, it won't affect this loop
	local clutch_ballsockets = table.Copy( self.clutch_ballsockets )

	-- Update all registered ball socket constraints
	local numconstraints = 0	-- Used to calculate the delay between inputs

	for k, _ in pairs( clutch_ballsockets ) do
		if not IsValid( k ) then
			self:RemoveClutch( k )

		else
			SaveMass( MassTable, k.Ent1 )
			SaveMass( MassTable, k.Ent2 )

			self:SetClutchFriction( k, self.clutch_friction )
			numconstraints = numconstraints + 1

		end
	end

	RestoreMass( MassTable )
	self:UpdateOverlay()

	return numconstraints
end


-- Called when the clutch input delay timer finishes
local function ClutchDelayEnd( ent )
	ent.ClutchDelay = nil

	if ent.delayed_clutch_friction then
		ent:TriggerInput( "Friction", ent.delayed_clutch_friction )
		ent.delayed_clutch_friction = nil
	end
end

local Clutch_Max = GetConVar("wire_clutch_maxrate")

function ENT:TriggerInput( iname, value )
	if iname == "Friction" then
		if not self.ClutchDelay then
			self.clutch_friction = value

			-- Create a delay to avoid server lag
			local numconstraints = self:UpdateFriction()
			local maxrate = math.max( Clutch_Max:GetInt() or 20, 1 )
			local Delay = numconstraints / maxrate

			self.ClutchDelay = true
			timer.Create( "wire_clutch_delay_" .. tostring(self:EntIndex()), Delay, 0, function() ClutchDelayEnd(self) end )

		else
			-- This should only happen if an error prevents the ClutchDelayEnd function from being called
			if not timer.Exists( "wire_clutch_delay_" .. tostring(self:EntIndex())) then
				self.ClutchDelay = false
			end

			-- Store new friction value so it can be updated after the delay
			self.delayed_clutch_friction = value

		end
	end
end



--[[-------------------------------------------------------
   -- Adv Duplicator Support --
   Linked entities are stored and recalled by their EntIndexes
---------------------------------------------------------]]
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	info.constrained_pairs = {}

	for k, v in pairs( self:GetConstrainedPairs() ) do
		info.constrained_pairs[k] = {}
		info.constrained_pairs[k].Ent1 = v.Ent1:EntIndex() or 0
		info.constrained_pairs[k].Ent2 = v.Ent2:EntIndex() or 0
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local Ent1, Ent2
	for _, v in pairs( info.constrained_pairs ) do
		Ent1 = GetEntByID(v.Ent1)
		Ent2 = GetEntByID(v.Ent2, game.GetWorld())

		if IsValid(Ent1) and
			Ent1 ~= Ent2 and
			WireLib.CanTool(ply, Ent1, "ballsocket_adv") and
			WireLib.CanTool(ply, Ent2, "ballsocket_adv")
		then
			self:AddClutch( Ent1, Ent2 )
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_clutch", WireLib.MakeWireEnt, "Data")
