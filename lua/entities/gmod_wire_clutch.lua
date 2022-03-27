AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Clutch"
ENT.Purpose         = "Allows rotational friction to be varied dynamically"
ENT.WireDebugName = "Clutch"

if CLIENT then return end -- No more client

local Clutch = {
	__index = {
		createAdvBallsocket = function(self)
			if self.friction <= 0 then return end

			local ballsocket = constraint.AdvBallsocket( self.ent1, self.ent2, 0, 0,
				Vector(0,0,0), Vector(0,0,0), 0, 0,
				-180, -180, -180, 180, 180, 180,
				self.friction, self.friction, self.friction, 1, 0 )

			if ballsocket then
				-- Prevent ball socket from being affected by dupe/remove functions
				ballsocket.Type = ""
				ballsocket:CallOnRemove( "WireClutchRemove", function()
					if self.clutch_ballsockets[ballsocket] then
						-- The table value is still true so something unknown killed the ballsocket
						-- Set the table so that nothing else runs into issues
						self.clutch_ballsockets[ballsocket] = nil
						-- Wait a frame so nothing bad happens, then rebuild it
						timer.Simple(0, function()
							if self.controller:IsValid() and self:isValid() then
								self:createAdvBallsocket()
							end
						end)
					end
				end)
				self.ballsocket = ballsocket
			end
		end,
		setFriction = function(self, friction)
			self.friction = friction
			self:remove()
			self:createAdvBallsocket()
		end,
		saveMass = function(self)
			self.ent1mass = self.phys1:GetMass()
			self.ent2mass = self.phys2:GetMass()
			self.phys1:SetMass(1)
			self.phys2:SetMass(1)
		end,
		restoreMass = function(self)
			self.phys1:SetMass(self.ent1mass)
			self.phys2:SetMass(self.ent2mass)
		end,
		remove = function(self)
			if self.ballsocket and self.ballsocket:IsValid() then
				self.ballsocket:RemoveCallOnRemove( "WireClutchRemove" )
				self.ballsocket:Remove()
			end
		end,
		isValid = function(self)
			return self.ent1:IsValid() and self.ent2:IsValid() and self.phys1:IsValid() and self.phys2:IsValid()
		end
	},
	__call = function(meta, controller, ent1, ent2, friction)
		local clutch = setmetatable({
			controller = controller,
			friction = friction,
			ent1 = ent1,
			ent2 = ent2,
			phys1 = ent1:GetPhysicsObject(),
			phys2 = ent2:GetPhysicsObject(),
		}, meta)
		if clutch:isValid() then
			clutch:saveMass()
			clutch:createAdvBallsocket()
			clutch:restoreMass()
			return clutch
		end
	end
}
setmetatable(Clutch, Clutch)

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

function ENT:ClutchExists( ent1, ent2 )
	for clutch in pairs( self.clutch_ballsockets ) do
		if  ( ent1 == clutch.ent1 and ent2 == clutch.ent2 ) or
			( ent1 == clutch.ent2 and ent2 == clutch.ent1 ) then
			return true
		end
	end
	return false
end


-- Returns an array with each entry as a table containing ent1, ent2
function ENT:GetConstrainedPairs()
	local ConstrainedPairs = {}
	for clutch in pairs( self.clutch_ballsockets ) do
		if clutch:isValid() then
			table.insert( ConstrainedPairs, {ent1 = clutch.ent1, ent2 = clutch.ent2} )
		else
			self.clutch_ballsockets[clutch] = nil
		end
	end
	return ConstrainedPairs
end

-- Register a new clutch association with the controller
function ENT:AddClutch( ent1, ent2 )
	local clutch = Clutch( self, ent1, ent2, self.clutch_friction )
	if clutch then
		self.clutch_ballsockets[clutch] = true
	end
	return clutch
end

-- Remove a new clutch association from the controller
function ENT:RemoveClutch(clutch)
	self.clutch_ballsockets[clutch] = nil
	clutch:remove()
end

function ENT:OnRemove()
	for clutch in pairs( self.clutch_ballsockets ) do
		clutch:remove()
	end
end

-- Set friction on all constrained ents, called by input or timer (if delayed)
function ENT:UpdateFriction(value)
	if value then self.clutch_friction = value end
	if self.LastUpdated == CurTime() then self:NextThink(CurTime()) return end
	self.LastUpdated = CurTime()

	for clutch in pairs( self.clutch_ballsockets ) do
		if clutch:isValid() then
			clutch:saveMass()
		else
			self.clutch_ballsockets[clutch] = nil
		end
	end
	for clutch in pairs( self.clutch_ballsockets ) do
		clutch:setFriction(self.clutch_friction)
	end
	for clutch in pairs( self.clutch_ballsockets ) do
		clutch:restoreMass()
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
		info.constrained_pairs[k].Ent1 = v.ent1:EntIndex() or 0
		info.constrained_pairs[k].Ent2 = v.ent2:EntIndex() or 0
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
	self:UpdateOverlay()
end

duplicator.RegisterEntityClass("gmod_wire_clutch", WireLib.MakeWireEnt, "Data")
