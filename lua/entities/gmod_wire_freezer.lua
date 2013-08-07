AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Freezer"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName = "Freezer"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.State = false
	self.Marks = {}
	self.Inputs = WireLib.CreateInputs(self, {"Activate"})
	self:UpdateOutputs()
end

function ENT:TriggerInput(name, value)
	if name == "Activate" then
		self.State = value == 1
		for _, ent in pairs(self.Marks) do
			if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
				ent:GetPhysicsObject():EnableMotion(not self.State)
				if not self.State then ent:GetPhysicsObject():Wake() end
			end
		end
		self:UpdateOverlay()
	end
end

function ENT:UpdateOverlay()
	self:SetOverlayText( (self.State and "Frozen" or "Unfrozen") .. "\nLinked Entities: " .. #self.Marks )
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
	self:UpdateOutputs()
end
