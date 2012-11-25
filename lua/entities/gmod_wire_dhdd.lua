AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Dupeable Hard Drive"
ENT.Author      	= "Divran"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName 	= "Dupeable HDD"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Outputs = WireLib.CreateOutputs( self, { "Memory [ARRAY]", "Size" } )
	self.Inputs = WireLib.CreateInputs( self, { "Data [ARRAY]", "Clear", "AllowWrite" } )

	self.Memory = {}
	self.ROM = false
	self.AllowWrite = false

	self:SetOverlayText("DHDD")
end

-- Read cell
function ENT:ReadCell( Address )
	local data = self.Memory[Address or 0] or 0
	return isnumber(data) and data or 0
end

-- Write cell
function ENT:WriteCell( Address, value )
	if (not self.ROM) or (self.ROM and self.AllowWrite) then
		self.Memory[Address] = value
	end
	self:ShowOutputs()
	return true
end

function ENT:ShowOutputs()
	WireLib.TriggerOutput( self, "Memory", self.Memory )
	local n = #self.Memory
	WireLib.TriggerOutput( self, "Size", n )
	if not self.ROM then
		self:SetOverlayText("DHDD\nSize: " .. n .." bytes" )
	else
		self:SetOverlayText("ROM\nSize: " .. n .." bytes" )
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Data") then
		if (!value) then return end
		self.Memory = value
		self:ShowOutputs()
	elseif (name == "Clear") then
		self.Memory = {}
		self.MemSize = 0
		self:ShowOutputs()
	elseif (name == "AllowWrite") then
		self.AllowWrite = value >= 1
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo( self ) or {}

	info.DHDD = {}
	info.ROM = self.ROM
	local n = 0
	info.DHDD.Memory = {}
	for k,v in pairs( self.Memory ) do -- Only save the first 512^2 values
		n = n + 1
		if (n > 512*512) then break end
		info.DHDD.Memory[k] = v
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (!ply:CheckLimit("wire_dhdds")) then
		ent:Remove()
		return
	end
	ply:AddCount( "wire_dhdds", ent )

	if (info.DHDD) then
		ent.Memory = (info.DHDD.Memory or {})
		self:ShowOutputs()
	end
	self.ROM = info.ROM or false

	ent:SetPlayer( ply )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end


function MakeWireDHDD( ply, Pos, Ang, model )
	if (!ply:CheckLimit( "wire_dhdds" )) then return false end

	local dhdd = ents.Create( "gmod_wire_dhdd" )
	if (!dhdd:IsValid()) then return false end

	dhdd:SetAngles( Ang )
	dhdd:SetPos( Pos )
	dhdd:SetModel( model )
	dhdd:SetPlayer( ply )
	dhdd:Spawn()
	dhdd:Activate()

	ply:AddCount( "wire_dhdds", dhdd )

	return dhdd
end
duplicator.RegisterEntityClass( "gmod_wire_dhdd", MakeWireDHDD, "Pos", "Ang", "model" )