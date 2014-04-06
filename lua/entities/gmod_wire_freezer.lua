AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Freezer"
ENT.WireDebugName = "Freezer"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.State = false
	self.CollisionState = 0
	self.Marks = {}
	self.Inputs = WireLib.CreateInputs(self, {"Activate", "Disable Collisions"})
	self:UpdateOutputs()
end

function ENT:TriggerInput(name, value)
	if name == "Activate" then
		self.State = value ~= 0
		for _, ent in pairs(self.Marks) do
			if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
				if self.State then
					-- Garry's Mod provides an OnPhysgunFreeze hook, which will
					-- unfreeze the object if prop protection allows it...
					gamemode.Call("OnPhysgunFreeze", self, ent:GetPhysicsObject(), ent, self:GetPlayer())
				else
					-- ...and a CanPlayerUnfreeze hook, which will return whether
					-- prop protection allows it, but won't unfreeze do the unfreezing.
					if not gamemode.Call("CanPlayerUnfreeze", self:GetPlayer(), ent, ent:GetPhysicsObject()) then return end
					ent:GetPhysicsObject():EnableMotion(true)
					ent:GetPhysicsObject():Wake()
				end
			end
		end
	elseif name == "Disable Collisions" then
		self.CollisionState = math.Clamp(math.Round(value), 0, 4)
		for _, ent in pairs(self.Marks) do
			if IsValid(ent) and IsValid(ent:GetPhysicsObject()) and gamemode.Call("CanTool", self:GetPlayer(), WireLib.dummytrace(ent), "nocollide") then
				if self.CollisionState == 0 then
					ent:SetCollisionGroup( COLLISION_GROUP_NONE )
					ent:GetPhysicsObject():EnableCollisions(true)
				elseif self.CollisionState == 1 then
					ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
					ent:GetPhysicsObject():EnableCollisions(true)
				elseif self.CollisionState == 2 then
					ent:SetCollisionGroup( COLLISION_GROUP_NONE )
					ent:GetPhysicsObject():EnableCollisions(false)
				elseif self.CollisionState == 3 then
					ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					ent:GetPhysicsObject():EnableCollisions(true)
				elseif self.CollisionState == 4 then
					ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					ent:GetPhysicsObject():EnableCollisions(false)
				end
			end
		end
	end
	self:UpdateOverlay()
end

local collisionDescriptions = {
	[0] = "Normal Collisions",
	[1] = "Disabled prop/player Collisions",
	[2] = "Disabled prop/world Collisions",
	[3] = "Disabled player Collisions",
	[4] = "Disabled prop/world/player Collisions"
}

function ENT:UpdateOverlay()
	self:SetOverlayText( 
		(self.State and "Frozen" or "Unfrozen") .. "\n" .. 
		collisionDescriptions[self.CollisionState] .. "\n" ..
		"Linked Entities: " .. #self.Marks)
end
function ENT:UpdateOutputs()
	self:UpdateOverlay()

	WireLib.SendMarks(self) -- Stool's yellow lines
end

function ENT:CheckEnt( ent )
	if IsValid(ent) then
		for index, e in pairs( self.Marks ) do
			if (e == ent) then return true, index end
		end
	end
	return false, 0
end

function ENT:LinkEnt( ent )
	if (self:CheckEnt( ent )) then return false	end
	self.Marks[#self.Marks+1] = ent
	ent:CallOnRemove("AdvEMarker.Unlink", function(ent)
		if IsValid(self) then self:UnlinkEnt(ent) end
	end)
	self:UpdateOutputs()
	return true
end

function ENT:UnlinkEnt( ent )
	local bool, index = self:CheckEnt( ent )
	if (bool) then
		table.remove( self.Marks, index )
		self:UpdateOutputs()
	end
	return bool
end

function ENT:ClearEntities()
	self.Marks = {}
	self:UpdateOutputs()
end

duplicator.RegisterEntityClass( "gmod_wire_freezer", WireLib.MakeWireEnt, "Data" )

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if next(self.Marks) then
		local tbl = {}
		for index, e in pairs( self.Marks ) do
			tbl[index] = e:EntIndex()
		end

		info.marks = tbl
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.Ent1 then
		-- Old wire-extras dupe support
		table.insert(self.Marks, GetEntByID(info.Ent1))
	end
	if info.marks then
		for index, entindex in pairs(info.marks) do
			self.Marks[index] = GetEntByID(entindex)
		end
	end
	self:TriggerInput("Disable Collisions", self.Inputs["Disable Collisions"].Value)
	self:UpdateOutputs()
end
