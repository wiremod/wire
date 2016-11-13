AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Vehicle Exit Point"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Inputs = WireLib.CreateInputs(self, {"Entity [ENTITY]", "Entities [ARRAY]", "Position [VECTOR]", "Local Position [VECTOR]", "Angle [ANGLE]", "Local Angle [ANGLE]"})
	
	self.Position = Vector(0,0,0)
	self.Angle = Angle(0,0,0)
	self.Entities = {}
	self.Global = false
	self.GlobalAngle = false
	self:AddExitPoint()
	
	self:ShowOutput()
end

function ENT:TriggerInput( name, value )
	if (name == "Entity") then
		self.Entities = {}
		if self:CheckPP(value) then
			self:LinkEnt(value)
		end
	elseif (name == "Entities") then
		self.Entities = {}
		for _, ent in pairs(value) do
			if self:CheckPP(ent) then
				self:LinkEnt(ent)
			end
		end
	elseif (name == "Position") then
		self.Position = value
		self.Global = true
	elseif (name == "Local Position") then
		self.Position = value
		self.Global = false
	elseif (name == "Angle") then
		self.Angle = value
		self.GlobalAngle = true
	elseif (name == "Local Angle") then
		self.Angle = value
		self.GlobalAngle = false
	end
	self:ShowOutput()
end

function ENT:ShowOutput()
	self:SetOverlayText(string.format("Entities linked: %i\n%sPosition: (%.2f, %.2f, %.2f)", table.Count(self.Entities), self.Global and "" or "Local ", self.Position.x, self.Position.y, self.Position.z))
end

function ENT:CheckPP(ent)
	-- Check Prop Protection. Most block/allow all of CanTool, but lets check hoverdrive controller specifically, since if they can attach one to your vehicle, they can simulate this anyways
	return IsValid(ent) and gamemode.Call("CanTool", self:GetPlayer(), WireLib.dummytrace(ent), "wire_hoverdrivecontroller")
end


local ExitPoints = {}
function ENT:AddExitPoint()
	ExitPoints[self] = true
end
local function RemoveExitPoint( ent )
	if ExitPoints[ent] then ExitPoints[ent] = nil end
end
hook.Add( "EntityRemoved", "WireExitPoint", RemoveExitPoint )


local ClampDistance = CreateConVar("wire_pod_exit_distance", "1000", FCVAR_ARCHIVE, "The maximum distance an exit point can move a player")
local function MovePlayer( ply, vehicle )
	for epoint, _ in pairs( ExitPoints ) do
		if IsValid(epoint) and not epoint.Position:IsZero() and epoint.Entities and epoint.Entities[vehicle] then
			if epoint.Global then
				local origin = vehicle:GetPos()
				local direction = epoint.Position - origin
				local direction_distance = direction:Length()
				ply:SetPos( origin + direction / direction_distance * math.min(direction_distance, math.max(0, ClampDistance:GetInt())) + Vector(0,0,5) ) -- Add 5z so they don't get stuck in the GPS or whatnot
				local ang = ply:EyeAngles()
			else
				local LocalPosDistance = epoint.Position:Length()
				ply:SetPos( vehicle:LocalToWorld( epoint.Position / LocalPosDistance * math.min(LocalPosDistance, math.max(0, ClampDistance:GetInt()))) + Vector(0,0,5) )
			end
			
			if epoint.GlobalAngle then
				ply:SetEyeAngles( Angle( epoint.Angle.p, epoint.Angle.y, 0 ) )
			else
				local ang = epoint:LocalToWorldAngles( epoint.Angle )
				ang.r = 0
				ply:SetEyeAngles( ang )
			end
			
			return
		end
	end
end
hook.Add("PlayerLeaveVehicle", "WireExitPoint", MovePlayer )

function ENT:SendMarks()
	local marks = {}
	for ent,_ in pairs(self.Entities) do table.insert(marks, ent) end
	WireLib.SendMarks(self, marks)
end

function ENT:LinkEnt( ent )
	if self.Entities[ent] then return end
	self.Entities[ent] = true
	ent:CallOnRemove("ExitPoint.Unlink", function(ent)
		if IsValid(self) then self:UnlinkEnt(ent) end
	end)
	
	self:SendMarks()
	self:ShowOutput()
	return true
end

function ENT:UnlinkEnt( ent )
	if not self.Entities[ent] then return end
	self.Entities[ent] = nil
	
	self:SendMarks()
	self:ShowOutput()
	return true
end

function ENT:ClearEntities()
	self.Entities = {}
	WireLib.SendMarks(self, {})
	self:ShowOutput()
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if next(self.Entities) then
		info.marks = {}
		for ent, _ in pairs(self.Entities) do
			if IsValid(ent) then table.insert(info.marks, ent:EntIndex()) end
		end
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.marks then
		for _, entindex in pairs(info.marks) do
			self:LinkEnt(GetEntByID(entindex))
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_exit_point", WireLib.MakeWireEnt, "Data")
