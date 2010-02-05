AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- wire debug and overlay crap.
ENT.WireDebugName	= "Holographic Emitter"
ENT.OverlayDelay 	= 0
ENT.LastClear       = 0

-- init.
function ENT:Initialize( )
	self:DrawShadow( false )

	-- setup physics
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	-- vars
	self.Entity:SetNetworkedFloat( "X", 0 )
	self.Entity:SetNetworkedFloat( "Y", 0 )
	self.Entity:SetNetworkedFloat( "Z", 0 )
	self.Entity:SetNetworkedFloat( "FadeRate", 50 )
	self.Entity:SetNetworkedFloat( "PointSize", 0.2 )
	self.Entity:SetNetworkedBool( "ShowBeam", true )
	self.Entity:SetNetworkedBool( "GroundBeam", true )
	self.Entity:SetNetworkedBool( "Active", false )
	self.Entity:SetNetworkedEntity( "reference", self.Entity )
	self.Entity:SetNetworkedInt( "LastClear", 0 )
	self:LinkToGrid(nil)

	-- create inputs.
	self.Inputs = WireLib.CreateSpecialInputs( self.Entity, { "X", "Y", "Z", "Vector", "Active", "FadeRate", "Clear" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL" } )
end

-- link to grid
function ENT:LinkToGrid( ent )
	if ent == nil then ent = self.Entity end
	self.Entity:SetNetworkedEntity( "grid", ent )
end

-- trigger input
function ENT:TriggerInput( inputname, value, iter )
	-- store values.
	if(not value) then return end
	if (inputname == "Clear" and value ~= 0)  then
		self.LastClear = self.LastClear + 1
		self.Entity:SetNetworkedInt( "Clear", self.LastClear )

	elseif ( inputname == "Active" ) then
		self.Entity:SetNetworkedBool( "Active", value ~= 0 )

	-- store float values.
	elseif ( inputname == "Vector" ) and ( type(value) == "Vector" ) then
		self.Entity:SetNetworkedFloat( "X", value.x )
		self.Entity:SetNetworkedFloat( "Y", value.y )
		self.Entity:SetNetworkedFloat( "Z", value.z )

	elseif ( inputname ~= nil ) then
		self.Entity:SetNetworkedFloat( inputname, value )
	end
end

function ENT:Setup( r, g, b, a, showbeams, groundbeams, size )
	self:SetColor( r, g, b, a );

	-- update size and show states
	self:SetNetworkedBool( "ShowBeam", showbeams );
	self:SetNetworkedBool( "GroundBeam", groundbeams );
	self:SetNetworkedFloat( "PointSize", size );

	self.r = r
	self.g = g
	self.b = b
	self.a = a
	self.showbeams = showbeams
	self.groundbeams = groundbeams
	self.size = size
end



function MakeWireHoloemitter( pl, Pos, Ang, model, r, g, b, a, showbeams, groundbeams, size, frozen )
	-- check the players limit
	if( !pl:CheckLimit( "wire_holoemitters" ) ) then return end

	-- create the emitter
	local emitter = ents.Create( "gmod_wire_holoemitter" )
		emitter:SetPos( Pos )
		emitter:SetAngles( Ang )
		emitter:SetModel( model )
	emitter:Spawn()
	emitter:Activate()

	if emitter:GetPhysicsObject():IsValid() then
		local Phys = emitter:GetPhysicsObject()
		Phys:EnableMotion(not frozen)
	end

	-- setup the emitter.
	emitter:Setup( r, g, b, a, showbeams, groundbeams, size, frozen )
	emitter.pl = pl
	emitter:SetPlayer( pl )

	-- add to the players count
	pl:AddCount( "wire_holoemitters", emitter )

	return emitter
end

duplicator.RegisterEntityClass("gmod_wire_holoemitter", MakeWireHoloemitter, "Pos", "Ang", "Model", "r", "g", "b", "a", "showbeams", "groundbeams", "size", "frozen")


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	grid = self.Entity:GetNetworkedEntity( "grid" )
	if (grid) and (grid:IsValid()) then
		info.holoemitter_grid = grid:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local grid = nil
	if (info.holoemitter_grid) then
		grid = GetEntByID(info.holoemitter_grid)
		if (!grid) then
			grid = ents.GetByIndex(info.holoemitter_grid)
		end
	end
	if (grid && grid:IsValid()) then
		self:LinkToGrid(grid)
	end
end


