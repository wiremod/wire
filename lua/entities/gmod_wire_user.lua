AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire User"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "User"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateInputs(self, {"Fire"})
	self:Setup(2048)
end

function ENT:Setup(Range)
	if Range then self:SetBeamLength(Range) end
end
function ENT:TriggerInput(iname, value)
	if iname == "Fire" and value ~= 0 then
		local vStart = self:GetPos()

		local trace = util.TraceLine( {
			start = vStart,
			endpos = vStart + (self:GetUp() * self:GetBeamLength()),
			filter = { self },
		})

		if not IsValid(trace.Entity) then return false end
		local ply = self:GetPlayer()
		if not IsValid(ply) then ply = self end

		if ply:IsPlayer() and ply:InVehicle() and trace.Entity:IsVehicle() then return end -- don't use a vehicle if you're in one

		if hook.Run( "PlayerUse", ply, trace.Entity ) == false then return false end
		if hook.Run( "WireUse", ply, trace.Entity, self ) == false then return false end

		if trace.Entity.Use then
			trace.Entity:Use(ply,self,USE_ON,0)
		else
			trace.Entity:Fire("use","1",0)
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_user", WireLib.MakeWireEnt, "Data", "Range")
