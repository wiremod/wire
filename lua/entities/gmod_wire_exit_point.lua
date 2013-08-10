AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Vehicle Exit Point"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Inputs = WireLib.CreateInputs(self, {"Entity [ENTITY]", "Entities [ARRAY]", "Position [VECTOR]", "Local Position [VECTOR]"})
	
	self.Position = Vector()
	self.Entities = {}
	self.Global = false
	self:AddExitPoint()
end

function ENT:TriggerInput( name, value )
	if (name == "Entity") then
		self.Entities = {}
		if self:CheckPP(value) then
			self.Entities[value] = true
		end
	elseif (name == "Entities") then
		self.Entities = {}
		for _, ent in pairs(value) do
			if self:CheckPP(ent) then
				self.Entities[ent] = true
			end
		end
	elseif (name == "Position") then
		self.Position = value
		self.Global = true
	elseif (name == "Local Position") then
		self.Position = value
		self.Global = false
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
	if ExitPoints[self] then ExitPoints[self] = nil end
end
hook.Add( "EntityRemoved", "WireExitPoint", RemoveExitPoint )

local function MovePlayer( ply, vehicle )
	for epoint, _ in pairs( ExitPoints ) do
		if IsValid(epoint) and not epoint.Position:IsZero() and epoint.Entities and epoint.Entities[vehicle] then
			-- if ( vehicle:GetPos():Distance( epoint:GetPos() ) < 1000 ) then -- Meh, why the distinction?
			if epoint.Global then
				ply:SetPos( epoint.Position + Vector(0,0,5) ) -- Add 5z so they don't get stuck in the GPS or whatnot
			else
				ply:SetPos( vehicle:LocalToWorld( epoint.Position ) + Vector(0,0,5) )
			end
			return
		end
	end
end
hook.Add("PlayerLeaveVehicle", "WireExitPoint", MovePlayer )


duplicator.RegisterEntityClass("gmod_wire_exit_point", WireLib.MakeWireEnt, "Data")
