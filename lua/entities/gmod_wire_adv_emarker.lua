AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Adv Wire Entity Marker"
ENT.Author      = "Divran"
ENT.WireDebugName = "Adv EMarker"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Marks = {}
	local outputs = {"Entities [ARRAY]", "Nr"}
	for i=3,12 do
		outputs[i] = "Entity" .. (i-2) .. " [ENTITY]"
	end
	self.Inputs = WireLib.CreateInputs( self, {
		"Entity (This entity will be added or removed once the other two inputs are changed) [ENTITY]",
		"Add Entity (Change to non-zero value to add the entity specified by the 'Entity' input)",
		"Remove Entity (Change to non-zero value to remove the entity specified by the 'Entity' input)",
		"Clear Entities (Removes all entities from the marker)"
	} )
	self.Outputs = WireLib.CreateOutputs( self, outputs )
	self:SetOverlayText( "Number of entities linked: 0" )
end

function ENT:TriggerInput( name, value )
	if (name == "Entity") then
		if IsValid(value) then
			self.Target = value
		end
	elseif (name == "Add Entity") then
		if IsValid(self.Target) then
			if (value ~= 0) then
				local bool, index = self:CheckEnt( self.Target )
				if (not bool) then
					self:LinkEnt( self.Target )
				end
			end
		end
	elseif (name == "Remove Entity") then
		if IsValid(self.Target) then
			if (value ~= 0) then
				local bool, index = self:CheckEnt( self.Target )
				if (bool) then
					self:UnlinkEnt( self.Target )
				end
			end
		end
	elseif (name == "Clear Entities") then
		self:ClearEntities()
	end
end

function ENT:UpdateOutputs()
	-- Trigger regular outputs
	WireLib.TriggerOutput( self, "Entities", self.Marks )
	WireLib.TriggerOutput( self, "Nr", #self.Marks )

	-- Trigger special outputs
	for i=3,12 do
		WireLib.TriggerOutput( self, "Entity" .. (i-2), self.Marks[i-2] )
	end

	-- Overlay text
	self:SetOverlayText( "Number of entities linked: " .. #self.Marks )

	-- Yellow lines information
	WireLib.SendMarks(self)
end

function ENT:CheckEnt( ent )
	for index, e in pairs( self.Marks ) do
		if (e == ent) then return true, index end
	end
	return false, 0
end

function ENT:LinkEnt(ent)
	if self:CheckEnt(ent) then return false	end

	table.insert(self.Marks, ent)

	ent:CallOnRemove("AdvEMarker.Unlink", function(ent)
		if self:IsValid() then
			self:UnlinkEnt(ent)
		end
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
	for i=1,#self.Marks do
		if self.Marks[i]:IsValid() then
			self.Marks[i]:RemoveCallOnRemove( "AdvEMarker.Unlink" )
		end
	end
	self.Marks = {}
	self:UpdateOutputs()
end

function ENT:OnRemove()
	self:ClearEntities()
end

duplicator.RegisterEntityClass( "gmod_wire_adv_emarker", WireLib.MakeWireEnt, "Data" )

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

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
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.marks) then
		self.Marks = self.Marks or {}

		for index, entid in pairs(info.marks) do
			local ent = GetEntByID(entid)
			self.Marks[index] = ent
			ent:CallOnRemove("AdvEMarker.Unlink", function(ent)
				if IsValid(self) then self:UnlinkEnt(ent) end
			end)
		end
		self:UpdateOutputs()
	end
end
