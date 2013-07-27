AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire CD Disk"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName = "CD"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.DiskMemory = {}
	self.Precision = 1 //1 unit
	self.IRadius = 12 //units

	//Use Z axis for Sector address
	//Use XY radius for Track address
	//Use Z height for Stack address
	self:Setup()
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.Precision = self.Precision
	info.IRadius = self.IRadius
	info.Skin = self:GetSkin()
	info["DiskMemory"] = {}

	local dataptr = 0
	for k,v in pairs(self.DiskMemory) do
		info["DiskMemory"][k] = dataptr
		info["DiskData"..dataptr] = {}
		for k2,v2 in pairs(self.DiskMemory[k]) do
			info["DiskData"..dataptr][k2] = v2
		end
		dataptr = dataptr + 1
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Precision = info.Precision
	self.IRadius = info.IRadius
	self:SetSkin(info.Skin or 0)
	self.DiskMemory = {}

	for k,v in pairs(info["DiskMemory"]) do
		local dataptr = info["DiskMemory"][k]
			self.DiskMemory[k] = {}
		for k2,v2 in pairs(info["DiskData"..dataptr]) do
			self.DiskMemory[k][k2] = v2
		end
	end

	self:Setup()
end

function ENT:Setup()
	local min = self:OBBMins()
	local max = self:OBBMaxs()

	self.Precision = math.floor(math.Clamp(self.Precision,1,64))
	self.IRadius = math.max(self.IRadius,0)

	self.StackStartHeight = -min.z

	self.DiskStacks = math.max(1,math.floor((max.z - min.z) / self.Precision)+1)
	self.DiskTracks = math.floor(0.5*math.min(max.x - min.x,max.y - min.y) / self.Precision)

	self.DiskSectors = 0
	self.TrackSectors = {}
	self.FirstTrack = math.floor((self.IRadius) / self.Precision)
	for i=self.FirstTrack,self.DiskTracks-1 do
		self.TrackSectors[i] = self.DiskSectors
		self.DiskSectors = self.DiskSectors + math.floor(2*3.1415926*i) + 1
	end

	self.DiskVolume = self.DiskSectors*self.DiskStacks
	self.BytesPerBlock = 512//*self.Precision
	self.DiskSize = self.DiskSectors*self.BytesPerBlock

//	print("Precision: "..(self.Precision))
//	print("H: "..(max.z - min.z))
//	print("R: "..(0.5*((max.x - min.x)^2+(max.y - min.y)^2)^0.5))
//	print("Disk stacks: "..self.DiskStacks)
//	print("Disk tracks: "..self.DiskTracks)
//	print("Disk sectors total: "..self.DiskSectors)
//	print("Disk volume "..self.DiskVolume)

	self:ShowOutput()
end

function ENT:ShowOutput()
	self:SetOverlayText("Effective size (per stack): "..self.DiskSize.." bytes ("..math.floor(self.DiskSize/1024).." kb)\n"..
			    "Tracks: "..self.DiskTracks.."\nSectors: "..self.DiskSectors.."\nStacks: "..self.DiskStacks)
end

function MakeWireCDDisk(pl, Pos, Ang, model)
	if (!pl:CheckLimit("wire_cd_disks")) then return false end

	local wire_cd_disk = ents.Create("gmod_wire_cd_disk")
	if (!wire_cd_disk:IsValid()) then return false end

	wire_cd_disk:SetAngles(Ang)
	wire_cd_disk:SetPos(Pos)
	wire_cd_disk:SetModel(model)
	wire_cd_disk:Spawn()

	wire_cd_disk:SetPlayer(pl)
	wire_cd_disk.pl = pl

	pl:AddCount("wire_cd_disks", wire_cd_disk)

	return wire_cd_disk
end
duplicator.RegisterEntityClass("gmod_wire_cd_disk", MakeWireCDDisk, "Pos", "Ang", "Model")
