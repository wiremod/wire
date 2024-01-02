AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Vehicle Exit Point"

if CLIENT then return end -- No more client

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Inputs = WireLib.CreateInputs(self, {
		"Entity (Links the exit point controller to a single specified vehicle and unlinks all others.) [ENTITY]",
		"Entities (Links the exit point controller to the specified array of vehicles.\nEntities will be linked one by one and this value can't be changed during this time.) [ARRAY]",
		"Position (Whenever a player exits a linked vehicle, they will be teleported to this position.\nOnly either this or 'Local Position' can be used at a time. The last changed input is used.) [VECTOR]",
		"Local Position (Whenever a player exits a linked vehicle, they will be teleported to this position, relative to the vehicle they just exited.\nOnly either this or 'Position' can be used at a time. The last changed input is used.) [VECTOR]",
		"Angle (Whenever a player exits a linked vehicle, they will be rotated to face this angle.\nOnly either this or 'Local Angle' can be used at a time. The last changed input is used.) [ANGLE]",
		"Local Angle (Whenever a player exits a linked vehicle, they will rotated to face this angle, relative to the vehicle they just exited.\nOnly either this or 'Angle' can be used at a time. The last changed input is used.) [ANGLE]"
	})

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
		if self.ToLink then return end
		self:ClearEntities()
		if next(value) ~= nil then
			-- unfortunately (for our performance) copying is required here
			self.ToLink = table.Copy(value)
			self.ToLinkCounter = nil
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
	self:SetOverlayText(string.format(
		"Entities linked: %i\n%sPosition: (%.2f, %.2f, %.2f)%s",
		table.Count(self.Entities),
		self.Global and "" or "Local ",
		self.Position.x, self.Position.y, self.Position.z,
		(self.ToLink and self.ToLinkCounter) and "\nLinking " .. (#self.ToLink-self.ToLinkCounter) .. " entities..." or ""
	))
end

function ENT:CheckPP(ent)
	-- Check Prop Protection. Most block/allow all of CanTool, but lets check hoverdrive controller specifically, since if they can attach one to your vehicle, they can simulate this anyways
	return IsValid(ent) and WireLib.CanTool(self:GetPlayer(), ent, "wire_hoverdrivecontroller")
end

function ENT:Think()
	BaseClass.Think(self)

	if self.ToLink then
		self.ToLinkCounter = (self.ToLinkCounter or 0) + 1
		if self.ToLinkCounter > #self.ToLink then
			self.ToLink = nil
			self.ToLinkCounter = nil
		else
			local ent = self.ToLink[self.ToLinkCounter]

			if self:CheckPP(ent) then
				self:LinkEnt(ent, true)
			end
		end

		self:ShowOutput()
		self:SendMarks()
		self:NextThink(CurTime()+0.1)
		return true
	end
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

function ENT:LinkEnt( ent, dontNotify )
	ent = WireLib.GetClosestRealVehicle(ent,nil,(not dontNotify) and self:GetPlayer())

	if not IsValid(ent) or not ent:IsVehicle() then return false, "Must link to a vehicle" end
	if self.Entities[ent] then return end
	self.Entities[ent] = true
	ent:CallOnRemove("ExitPoint.Unlink", function(ent)
		if IsValid(self) then self:UnlinkEnt(ent) end
	end)

	if not dontNotify then
		self:SendMarks()
		self:ShowOutput()
	end
	return true
end

function ENT:UnlinkEnt( ent )
	if not self.Entities[ent] then return end
	self.Entities[ent] = nil
	ent:RemoveCallOnRemove("ExitPoint.Unlink")

	self:SendMarks()
	self:ShowOutput()
	return true
end

function ENT:ClearEntities()
	self.Entities = {}
	self:SendMarks()
	self:ShowOutput()
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if next(self.Entities) then
		info.marks = {}
		for ent, _ in pairs(self.Entities) do
			if IsValid(ent) then table.insert(info.marks, ent:EntIndex()) end
		end
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.marks then
		self.ToLink = {}
		for idx, entindex in pairs(info.marks) do
			self.ToLink[idx] = GetEntByID(entindex)
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_exit_point", WireLib.MakeWireEnt, "Data")
