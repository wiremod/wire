AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

-- wire debug and overlay crap.
ENT.WireDebugName	= "Holographic Grid";

-- init.
function ENT:Initialize( )

	-- setup physics
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetSolid( SOLID_VPHYSICS );
	self:SetUseType(SIMPLE_USE)

	-- vars
	self:UpdateGPS(false)

	-- create inputs.
	self.Inputs = WireLib.CreateSpecialInputs(self, { "UseGPS", "Reference" }, { "NORMAL", "ENTITY" })
	self.reference = self
end

function ENT:UpdateGPS(UseGPS)
	if UseGPS then
		self.usesgps = true
		self:SetNetworkedEntity( "reference", ents.GetByIndex(-1) )
		self:SetOverlayText( "(GPS)" )
	else
		self.usesgps = false
		self:SetNetworkedEntity( "reference", self.reference )
		self:SetOverlayText( "(Local)" )
	end
end

-- trigger input
function ENT:TriggerInput( inputname, value )
	-- store values.
	if inputname == "UseGPS" then
		self:UpdateGPS(value ~= 0)
	elseif inputname == "Reference" then
		if IsValid(value) then
			self.reference = value
		else
			self.reference = self
		end
		self:UpdateGPS(self.usesgps)
	end
end

function ENT:Use( activator, caller )
	if caller:IsPlayer() then self:UpdateGPS(not self.usesgps) end
end


function MakeWireHologrid( pl, Pos, Ang, model, usegps, frozen )
	-- check the players limit
	if( !pl:CheckLimit( "wire_hologrids" ) ) then return end

	-- create the grid
	local grid = ents.Create( "gmod_wire_hologrid" )

	grid:SetPos( Pos )
	grid:SetAngles( Ang )
	grid:SetModel( model )

	grid:Spawn()
	grid:Activate()

	if grid:GetPhysicsObject():IsValid() then
		local Phys = grid:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	-- setup the grid.
	grid:UpdateGPS(usegps)
	grid.pl = pl
	grid:SetPlayer(pl)

	-- add to the players count
	pl:AddCount( "wire_hologrids", grid )

	return grid;
end

duplicator.RegisterEntityClass("gmod_wire_hologrid", MakeWireHologrid, "Pos", "Ang", "Model", "usegps", "frozen")


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.hologrid_usegps = self.usesgps and 1 or 0

	if IsValid(self.reference) then
		info.reference = self.reference:EntIndex()
	else
		info.reference = nil
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local reference
	if info.reference then
		reference = GetEntByID(info.reference)
		if not reference then
			reference = ents.GetByIndex(info.reference)
		end
	end
	if reference then
		self.reference = reference
	else
		self.reference = self
	end

	self:UpdateGPS(info.hologrid_usegps ~= 0)
end
