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
	self.LastUpdated = 0

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


local function NewBallSocket( ent1, ent2, friction )
	if not (ent1:IsValid() and ent2:IsValid()) then return false end
	local phys1, phys2 = ent1:GetPhysicsObject(), ent2:GetPhysicsObject()
	if not (phys1:IsValid() and phys2:IsValid()) then return false end

	local mass1, mass2 = phys1:GetMass(), phys2:GetMass()
	phys1:SetMass(1)
	phys2:SetMass(1)

	local ballsocket = constraint.AdvBallsocket( ent1, ent2, 0, 0,
		Vector(0,0,0), Vector(0,0,0), 0, 0,
		-180, -180, -180, 180, 180, 180,
		friction, friction, friction, 1, 0 )

	if ballsocket then
		-- Prevent ball socket from being affected by dupe/remove functions
		ballsocket.Type = ""
	end

	phys1:SetMass(mass1)
	phys2:SetMass(mass2)

	return ballsocket
end


-- Register a new clutch association with the controller
function ENT:AddClutch( Ent1, Ent2 )
	local ballsocket = NewBallSocket( Ent1, Ent2, self.clutch_friction )

	if ballsocket then
		self.clutch_ballsockets[ballsocket] = true
		ballsocket:CallOnRemove( "WireClutchRemove", function()
			if self.clutch_ballsockets[ballsocket] then
				-- The table value is still true so something unknown killed the ballsocket
				-- Set the table so that nothing else runs into issues
				self.clutch_ballsockets[ballsocket] = nil
				-- Wait a frame so nothing bad happens, then rebuild it
				timer.Simple(0, function()
					if self:IsValid() then
						self:AddClutch( Ent1, Ent2, friction )
					end
				end)
			end
		end)
	end

	return ballsocket
end


-- Remove a new clutch association from the controller
function ENT:RemoveClutch( const )
	self.clutch_ballsockets[const] = nil

	if const:IsValid() then
		const:RemoveCallOnRemove( "WireClutchRemove" )
		const:Remove()
	end
end


function ENT:SetClutchFriction( const, Ent1, Ent2 )
	-- There seems to be no direct way to edit constraint friction, so we must create a new ball socket constraint
	self:RemoveClutch( const )
	self:AddClutch( Ent1, Ent2 )
end


function ENT:OnRemove()
	for k in pairs( self.clutch_ballsockets ) do
		self:RemoveClutch( k )
	end
end

-- Set friction on all constrained ents, called by input or timer (if delayed)
function ENT:UpdateFriction(value)
	if value then self.clutch_friction = value end
	if self.LastUpdated == CurTime() then self:NextThink(CurTime()) return end
	self.LastUpdated = CurTime()

	-- Update all registered ball socket constraints
	for const in pairs( self.clutch_ballsockets ) do
		if const:IsValid() then
			local ent1, ent2 = const.Ent1, const.Ent2
			if ent1:IsValid() and ent2:IsValid() then
				self:SetClutchFriction( const, ent1, ent2 )
			else
				self.clutch_ballsockets[const] = nil
			end
		else
			self.clutch_ballsockets[const] = nil
		end
	end

	self:UpdateOverlay()
end

function ENT:TriggerInput( iname, value )
	if iname == "Friction" then
		self:UpdateFriction(value)
	end
end

function ENT:Think()
	self:UpdateFriction()
	self:NextThink(CurTime() + 1e3)
	return true
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
		   hook.Run( "CanTool", ply, WireLib.dummytrace(Ent1), "ballsocket_adv" ) and
		   hook.Run( "CanTool", ply, WireLib.dummytrace(Ent2), "ballsocket_adv" ) then
			self:AddClutch( Ent1, Ent2 )
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_clutch", WireLib.MakeWireEnt, "Data")
