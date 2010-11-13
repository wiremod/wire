-- Wire Advanced Entity Marker
-- Made by Divran

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Adv EMarker"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Target = nil

	AddAdvEMarker( self.Entity )

	self.Marks = {}
	local outputs = {}
	local types = {}
	outputs[1] = "Entities"
	types[1] = "ARRAY"
	outputs[2] = "Nr"
	types[2] = "NORMAL"
	for i=3,12 do
		outputs[i] = "Entity" .. (i-2)
		types[i] = "ENTITY"
	end
	self.Inputs = WireLib.CreateInputs( self.Entity, { "Entity [ENTITY]", "Add Entity", "Remove Entity", "Clear Entities" } )
	self.Outputs = WireLib.CreateSpecialOutputs( self.Entity, outputs, types )
	self:SetOverlayText( "Number of entities linked: 0" )
end

function ENT:TriggerInput( name, value )
	if (name == "Entity") then
		if (value:IsValid()) then
			self.Target = value
		end
	elseif (name == "Add Entity") then
		if (self.Target and self.Target:IsValid()) then
			if (value != 0) then
				local bool, index = self:CheckEnt( self.Target )
				if (!bool) then
					self:AddEnt( self.Target )
				end
			end
		end
	elseif (name == "Remove Entity") then
		if (self.Target and self.Target:IsValid()) then
			if (value != 0) then
				local bool, index = self:CheckEnt( self.Target )
				if (bool) then
					self:RemoveEnt( self.Target )
				end
			end
		end
	elseif (name == "Clear Entities") then
		for _, ent in pairs( self.Marks ) do
			self:RemoveEnt( ent )
		end
	end
end

function ENT:UpdateOutputs()
	-- Trigger regular outputs
	WireLib.TriggerOutput( self.Entity, "Entities", self.Marks )
	WireLib.TriggerOutput( self.Entity, "Nr", #self.Marks )

	-- Trigger special outputs
	for i=3,12 do
		WireLib.TriggerOutput( self.Entity, "Entity" .. (i-2), self.Marks[i-2] )
	end

	-- Overlay text
	self:SetOverlayText( "Number of entities linked: " .. #self.Marks )

	-- Yellow lines information
	if (SERVER) then
		umsg.Start("Wire_Adv_EMarker_Links")
			umsg.Short(self.Entity:EntIndex())
			umsg.Short(#self.Marks)
			for k,v in pairs( self.Marks ) do
				umsg.Short(v:EntIndex())
			end
		umsg.End()
	end
end

function ENT:CheckEnt( ent )
	for index, e in pairs( self.Marks ) do
		if (e == ent) then return true, index end
	end
	return false, 0
end

function ENT:AddEnt( ent )
	if (self:CheckEnt( ent )) then return false	end
	self.Marks[#self.Marks+1] = ent
	self:UpdateOutputs()
	return true
end

function ENT:RemoveEnt( ent )
	local bool, index = self:CheckEnt( ent )
	if (bool) then
		table.remove( self.Marks, index )
		self:UpdateOutputs()
	end
end



// Advanced Duplicator Support

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (#self.Marks) then
		local tbl = {}
		for index, e in pairs( self.Marks ) do
			tbl[index] = e:EntIndex()
		end

		info.marks = tbl
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (!ply:CheckLimit("wire_adv_emarkers")) then
		ent:Remove()
		return
	end
	ply:AddCount( "wire_adv_emarkers", ent )

	if (info.marks) then
		local tbl = info.marks

		if (!self.Marks) then self.Marks = {} end

		for index, entindex in pairs( tbl ) do
			self.Marks[index] = GetEntByID(entindex) or ents.GetByIndex(entindex)
		end
		self:UpdateOutputs()
	end

	ent:SetPlayer( ply )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end
