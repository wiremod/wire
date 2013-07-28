AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local cvar = CreateConVar("wire_holoemitter_interval",0.3,{FCVAR_ARCHIVE,FCVAR_NOTIFY})

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

	self.Inputs = WireLib.CreateInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )

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
	self.Points[#self.Points+1] = {
		Pos = Vector(self.Data.Pos.x,self.Data.Pos.y,self.Data.Pos.z),
		Local = self.Data.Local,
		Color = Vector(self.Data.Color.x,self.Data.Color.y,self.Data.Color.z),
		FadeTime = self.Data.FadeTime,
		LineBeam = self.Data.LineBeam,
		GroundBeam = self.Data.GroundBeam,
		Size = self.Data.Size,
	}
end

function ENT:TriggerInput( name, value )
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
	elseif (name == "Pos") then -- XYZ
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

-- Hispeed info
-- 0 = Draw (when changed, draws point) (if used in readcell, returns whether or not you are allowed to draw any more this interval)
-- 1 = X
-- 2 = Y
-- 3 = Z
-- 4 = Local (1/0)
-- 5 = R
-- 6 = G
-- 7 = B
-- 8 = FadeTime
-- 9 = LineBeam
-- 10 = GroundBeam
-- 11 = Size
-- 12 = Clear (removes all dots when = 1)
-- 13 = Active

function ENT:ReadCell( Address )
	if (Address == 0) then
		return 1
	elseif (Address == 1) then
		return self.Data.Pos.x
	elseif (Address == 2) then
		return self.Data.Pos.y
	elseif (Address == 3) then
		return self.Data.Pos.z
	elseif (Address == 4) then
		return (self.Data.Local and 1 or 0)
	elseif (Address == 5) then
		return self.Data.Color.x
	elseif (Address == 6) then
		return self.Data.Color.y
	elseif (Address == 7) then
		return self.Data.Color.z
	elseif (Address == 8) then
		return self.Data.FadeTime
	elseif (Address == 9) then
		return (self.Data.LineBeam and 1 or 0)
	elseif (Address == 10) then
		return (self.Data.GroundBeam and 1 or 0)
	elseif (Address == 11) then
		return self.Data.Size
	elseif (Address == 12) then
		return (self:GetNWBool("Clear",false) and 1 or 0)
	elseif (Address == 13) then
		return (self:GetNWBool("Active",true) and 1 or 0)
	end
end

function ENT:WriteCell( Address, value )
	if (Address == 0) then
		self:AddPoint()
		return true
	elseif (Address == 1) then
		self.Data.Pos.x = value
		return true
	elseif (Address == 2) then
		self.Data.Pos.y = value
		return true
	elseif (Address == 3) then
		self.Data.Pos.z = value
		return true
	elseif (Address == 4) then
		self.Data.Local = value ~= 0
		return true
	elseif (Address == 5) then
		self.Data.Color.x = value
		return true
	elseif (Address == 6) then
		self.Data.Color.y = value
		return true
	elseif (Address == 7) then
		self.Data.Color.z = value
		return true
	elseif (Address == 8) then
		self.Data.FadeTime = value
		return true
	elseif (Address == 9) then
		self.Data.LineBeam = !(value == 0 and true) or false
		return true
	elseif (Address == 10) then
		self.Data.GroundBeam = !(value == 0 and true) or false
		return true
	elseif (Address == 11) then
		self.Data.Size = value
		return true
	elseif (Address == 12) then
		self:SetNWBool( "Clear", !(value == 0 and true) or false )
		return true
	elseif (Address == 13) then
		self:SetNWBool( "Active", !(value == 0 and true) or false )
		return true
	end
	return false
end

function ENT:Link( ent )
	if ent and ent:IsValid() and ent:GetClass() == "gmod_wire_hologrid" then -- Remove "Local" input if linking to a hologrid
		WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
	else
		local old = self:GetNWEntity( "Link" )
		if old and old:IsValid() and old:GetClass() == "gmod_wire_hologrid" then -- Put the "Local" input back
			WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
		end
	end

	self:SetNWEntity( "Link", ent )
end

function ENT:UnLink()
	local old = self:GetNWEntity( "Link" )
	if old and old:IsValid() and old:GetClass() == "gmod_wire_hologrid" then -- Put the "Local" input back
		WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
	end

	self:SetNWEntity( "Link", NULL )
end

util.AddNetworkString("WireHoloEmitterData")
function ENT:Think()
	self:NextThink( CurTime() + cvar:GetFloat() )
	if not next(self.Points) then return true end
	net.Start("WireHoloEmitterData")
		net.WriteEntity(self)
		net.WriteUInt(#self.Points, 16)
		for _,v in pairs( self.Points ) do
			net.WriteVector(v.Pos)
			net.WriteBit(v.Local)
			net.WriteUInt(v.Color.x,8)
			net.WriteUInt(v.Color.y,8)
			net.WriteUInt(v.Color.z,8)
			net.WriteUInt(math.Clamp(v.FadeTime,0,100)*100,16)
			net.WriteBit(v.LineBeam)
			net.WriteBit(v.GroundBeam)
			net.WriteUInt(math.Clamp(v.Size,0,100)*100, 16)
		end
	net.Broadcast()
	
	/*umsg.Start( "hed" ) -- short for "holo emitter data"
		umsg.Entity( self ) -- 2
		umsg.Char( #self.Points ) -- 1
		for k,v in pairs( self.Points ) do
			umsg.Float( v.Pos.x ) -- 4
			umsg.Float( v.Pos.y ) -- 4
			umsg.Float( v.Pos.z ) -- 4
	//		if (v.IsDifferentFromPrevious) then
	//			umsg.Bool( true ) -- We're sending lots of data -- 1
				umsg.Bool( v.Local ) -- 1
				umsg.Char( v.Color.x - 128 ) -- 1
				umsg.Char( v.Color.y - 128 ) -- 1
				umsg.Char( v.Color.z - 128 ) -- 1
				--umsg.Vector( v.Color )
				umsg.Short( math.Clamp(v.FadeTime,0,100)*100 ) -- 2
				umsg.Bool( v.LineBeam ) -- 1
				umsg.Bool( v.GroundBeam ) -- 1
				umsg.Short( math.Clamp(v.Size,0,100)*100 ) -- 2
	//		else
	//			umsg.Bool( false ) -- We're not sending lots of data, only a position. -- 1
	//		end
		end

		-- Total umsg size (if 1 point is sent): 3 + 11 + 11 + 1 = 27
		-- Umsg size of "different" part: 12 + 11 = 23
		-- Umsg size of "same" part: 12 + 1 = 13
	umsg.End()*/
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

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	local link = self:GetNWEntity("Link",false)
	if (link) then
		info.holoemitter_link = link:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local link = info.holoemitter_link
	if (link) then
		link = GetEntByID(link)
		if (link and link:IsValid()) then
			self:Link(link)
		end
	end
end
