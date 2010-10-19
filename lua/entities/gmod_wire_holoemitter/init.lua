AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- wire debug and overlay crap.
ENT.WireDebugName	= "Holographic Emitter"

function ENT:Initialize( )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow( false )

	self:SetNWBool( "Clear", false )
	self:SetNWBool( "Active", true )

	self.bools = {}
	self.bools.Local = true
	self.bools.LineBeam = true
	self.bools.GroundBeam = true

	self.Inputs = WireLib.CreateInputs( self, { "Pos [VECTOR]", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )

	self.Points = {}

	self.Data = {}
	self.Data.Pos = Vector(0,0,0)
	self.Data.Local = false
	self.Data.Color = Vector(255,255,255)
	self.Data.FadeTime = 1
	self.Data.LineBeam = false
	self.Data.GroundBeam = false
	self.Data.Size = 1
end

function ENT:AddPoint()
	n = #self.Points
	if (n > 7) then return end -- Max points per interval (7 is the max amount before the umsg gets too large.)
	self.Points[n+1] = {
		Pos = self.Data.Pos,
		Local = self.Data.Local,
		Color = self.Data.Color,
		FadeTime = self.Data.FadeTime,
		LineBeam = self.Data.LineBeam,
		GroundBeam = self.Data.GroundBeam,
		Size = self.Data.Size
	}
end

function ENT:TriggerInput( name, value )
	--[[ I'll just leave this here if anyone wants it
	if (name == "X") then -- X
		if (self.Data.Pos.x != value) then
			self.Data.Pos.x = value
			self:AddPoint()
		end
	elseif (name == "Y") then -- Y
		if (self.Data.Pos.y != value) then
			self.Data.Pos.y = value
			self:AddPoint()
		end
	elseif (name == "Z") then -- Z
		if (self.Data.Pos.z != value) then
			self.Data.Pos.z = value
			self:AddPoint()
		end
	else]]
	if (name == "Pos") then -- XYZ
		if (self.Data.Pos != value) then
			self.Data.Pos = value
			self:AddPoint()
		end
	else
		-- Clear & Active
		if (name == "Clear" or name == "Active") then
			self:SetNWBool(name,!(value == 0 and true) or false)
		else
			-- Other data
			if (self.bools[name]) then value = !(value == 0 and true) or false end
			self.Data[name] = value
		end
	end
end

function ENT:Link( ent )
	self:SetNWEntity( "Link", ent )
end

function ENT:UnLink()
	self:SetNWEntity( "Link", nil )
end

umsg.PoolString("Wire_HoloEmitter_Data")
function ENT:Think()
	self:NextThink( CurTime() + 0.1 )
	if (#self.Points == 0) then return true end
	umsg.Start( "Wire_HoloEmitter_Data" )
		umsg.Entity( self )
		umsg.Char( #self.Points )
		for k,v in ipairs( self.Points ) do
			umsg.Vector( v.Pos )
			umsg.Bool( v.Local )
			umsg.Vector( v.Color )
			umsg.Float( v.FadeTime )
			umsg.Bool( v.LineBeam )
			umsg.Bool( v.GroundBeam )
			umsg.Float( v.Size )
		end
	umsg.End()
	self.Points = {}
	return true
end

function MakeWireHoloemitter( ply, Pos, Ang, model, frozen )
	if (!ply:CheckLimit( "wire_holoemitters" )) then return end

	local emitter = ents.Create( "gmod_wire_holoemitter" )
	emitter:SetPos( Pos )
	emitter:SetAngles( Ang )
	emitter:SetModel( model )
	emitter:Spawn()
	emitter:Activate()

	local phys = emitter:GetPhysicsObject()
	if (phys) then
		phys:EnableMotion(!frozen)
	end

	emitter:SetPlayer( ply )

	ply:AddCount( "wire_holoemitters", emitter )

	return emitter
end

duplicator.RegisterEntityClass("gmod_wire_holoemitter", MakeWireHoloemitter, "Pos", "Ang", "Model", "frozen")

