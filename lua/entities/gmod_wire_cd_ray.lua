AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire CD Ray"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "CD Ray"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, {"Write","Read","Value"})
	self.Outputs = Wire_CreateOutputs(self, {"Memory","Data","Sector","LocalSector","Track","Stack","Address"})

	self.Memory = {}
	self.Memory[0]  = 0 //[W] Write ray on
	self.Memory[1]  = 0 //[W] Read ray on
	self.Memory[2]  = 0 //[R] Current sector (global)
	self.Memory[3]  = 0 //[R] Current sector (on track)
	self.Memory[4]  = 0 //[R] Current track
	self.Memory[5]  = 0 //[R] Current stack
	self.Memory[6]  = 0 //[R] Current address (global)
	self.Memory[7]  = 0 //[R] Current address (in current stack)

	self.Memory[8]  = 0 //[W] Buffer ready (read or write - pick the ray)
	self.Memory[9]  = 0 //[W] Continious mode
	self.Memory[10] = 0 //[W] Wait for address mode
	self.Memory[11] = 0 //[W] Target address (in current stack)
	self.Memory[12] = 0 //[W] Wait for track&sector mode
	self.Memory[13] = 0 //[W] Target sector
	self.Memory[14] = 0 //[W] Target track

	self.Memory[21] = 0 //[R] Raw disk spin velocity
	self.Memory[22] = 0 //[R] Raw disk spin angle
	self.Memory[23] = 0 //[R] Raw distance from disk center
	self.Memory[24] = 0 //[R] Raw stack index

	self.Memory[25] = 0 //[R] Disk precision (Inches Per Block)
	self.Memory[26] = 0 //[R] Disk sectors (total)
	self.Memory[27] = 0 //[R] Disk tracks (total)
	self.Memory[28] = 0 //[R] First track number
	self.Memory[29] = 0 //[R] Bytes per block
	self.Memory[30] = 0 //[R] Disk size (per stack)
	self.Memory[31] = 0 //[R] Disk volume (bytes total)

	self.WriteBuffer = {}
	self.PrevDiskEnt = nil

	self:SetBeamLength(64)
end

function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < 512) then
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	end
	if (Address >= 512) && (Address < 1024) then
		if (self.WriteBuffer[Address-512]) then
			return self.WriteBuffer[Address-512]
		else
			return 0
		end
	end
	return nil
end

function ENT:WriteCell(Address, value)
	if (Address >= 0) && (Address < 512) then
		self.Memory[Address] = value
		if (Address == 8) then
			self:DoJob()
		end
		return true
	end
	if (Address >= 512) && (Address < 1024) then
		if (value ~= 0) then
			self.WriteBuffer[Address-512] = value
		else
			self.WriteBuffer[Address-512] = nil
		end
		return true
	end
	return false
end

function ENT:Setup(Range,DefaultZero)
	self.DefaultZero = DefaultZero
	if Range then self:SetBeamLength(Range) end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Write") then
		self.Memory[0] = value
		self.Memory[8] = 1
		self.Memory[9] = 1
	elseif (iname == "Read") then
		self.Memory[1] = value
		self.Memory[8] = 1
		self.Memory[9] = 1
	elseif (iname == "Value") then
		self.Memory[8] = 1
		self.Memory[9] = 1
		self.WriteBuffer[0] = value
	end
end

function ENT:DoJob()
	if (not self.Disk) then return end
	local disk = self.Disk
	if (self.Memory[8] ~= 0) then
		local dojob = true
		if (self.Memory[10] ~= 0) then
			if (self.Memory[11] ~= self.Memory[7]) then dojob = false end
		end
		if (self.Memory[12] ~= 0) then
			if (self.Memory[13] ~= self.Memory[3]) || (self.Memory[14] ~= self.Memory[4]) then
				dojob = false
			end
		end

		if dojob then
			if (self.Memory[9] == 0) then self.Memory[8] = 0 end
			local sector_addr = self.Sector.."."..self.Track.."."..self.Stack//{s=sector,t=track,st=stack}
			if (self.Memory[0] ~= 0) then //write ray
				disk.DiskMemory[sector_addr] = table.Copy(self.WriteBuffer)
			else //read ray
				self.WriteBuffer = table.Copy(disk.DiskMemory[sector_addr]) or { [0] = 0 }
			end
		end
	end
end

function ENT:Think()
	local vStart = self:GetPos()
	local vForward = self:GetUp()

		local trace = {}
		trace.start = vStart
		trace.endpos = vStart + (vForward * self:GetBeamLength())
		trace.filter = { self }
	local trace = util.TraceLine( trace )

	if ((self.Memory[0] ~= 0) or (self.Memory[1] ~= 0)) then
		if (self.Memory[0] == 1) then --write ray (blue)
			self:SetColor(Color(0, 0, 255, 255))
		else --read ray (red)
			self:SetColor(Color(255, 0, 0, 255))
		end
	else
		self:SetColor(Color(255, 255, 255, 255))
	end

	if ((trace.Entity) and
		(trace.Entity:IsValid()) and
		(trace.Entity:GetClass() == "gmod_wire_cd_disk")) then
		local pos = trace.HitPos
		local disk = trace.Entity
		local lpos = disk:WorldToLocal(pos)

		local vel = disk.Entity:GetPhysicsObject():GetAngleVelocity().z

		local r = (lpos.x^2+lpos.y^2)^0.5 //radius
		local a = math.fmod(3.1415926+math.atan2(lpos.x,lpos.y),2*3.1415926) //angle
		local h = lpos.z-disk.StackStartHeight //stack

		local track = math.floor(r / disk.Precision)
		local sector = math.floor(a*track)//*disk.Precision)
		local stack = math.floor(h/disk.Precision)
		if (disk.DiskStacks == 1) then stack = 0 end

		if (self.PrevDiskEnt ~= disk) then
			self.PrevDiskEnt = disk

			self.Memory[25] = disk.Precision
			self.Memory[26] = disk.DiskSectors
			self.Memory[27] = disk.DiskTracks
			self.Memory[28] = disk.FirstTrack
			self.Memory[29] = disk.BytesPerBlock
			self.Memory[30] = disk.DiskSize
			self.Memory[31] = disk.DiskVolume
		end

		if ((track >= disk.FirstTrack) and (stack >= 0) and (sector >= 0) and
			//(track < disk.DiskTracks) and
			(stack < disk.DiskStacks)) then
			self.Memory[21] = vel //[R] Raw disk spin velocity
			self.Memory[22] = a //[R] Raw disk spin angle
			self.Memory[23] = r //[R] Raw distance from disk center
			self.Memory[24] = h //[R] Raw stack index

			if (not disk.TrackSectors[track]) then disk.TrackSectors[track] = 0 end

			self.Memory[2]  = disk.DiskSectors*stack+disk.TrackSectors[track]+sector //[R] Current sector (global)
			self.Memory[3]  = sector //[R] Current sector (on track)
			self.Memory[4]  = track //[R] Current track
			self.Memory[5]  = stack //[R] Current stack
			self.Memory[6]  = self.Memory[2]*disk.BytesPerBlock //[R] Current address (global)
			self.Memory[7]  = (disk.TrackSectors[track]+sector)*disk.BytesPerBlock //[R] Current address (in current stack)

			if ((self.Memory[0] ~= 0) or (self.Memory[1] ~= 0)) then
				self.Sector = sector
				self.Track = track
				self.Stack = stack
				self.Disk = disk
				self:DoJob()
			end
		else
			self.Memory[21] = 0
			self.Memory[22] = 0
			self.Memory[23] = 0
			self.Memory[24] = 0

			self.Memory[2]  = 0
			self.Memory[3]  = 0
			self.Memory[4]  = 0
			self.Memory[5]  = 0
			self.Memory[6]  = 0
			self.Memory[7]  = 0
		end
	else
		self.PrevDiskEnt = nil
		self.Disk = nil

		self.Memory[2]  = 0
		self.Memory[3]  = 0
		self.Memory[4]  = 0
		self.Memory[5]  = 0
		self.Memory[6]  = 0
		self.Memory[7]  = 0

		self.Memory[21] = 0
		self.Memory[22] = 0
		self.Memory[23] = 0
		self.Memory[24] = 0
		self.Memory[25] = 0
		self.Memory[26] = 0
		self.Memory[27] = 0
		self.Memory[28] = 0
		self.Memory[29] = 0
		self.Memory[30] = 0
		self.Memory[31] = 0
	end

	//Update output
	if (self.WriteBuffer[0]) then
		Wire_TriggerOutput(self, "Data",self.WriteBuffer[0])
	else
		Wire_TriggerOutput(self, "Data",0)
	end
	Wire_TriggerOutput(self, "Sector", 	self.Memory[2])
	Wire_TriggerOutput(self, "LocalSector",	self.Memory[3])
	Wire_TriggerOutput(self, "Track", 	self.Memory[4])
	Wire_TriggerOutput(self, "Stack", 	self.Memory[5])
	Wire_TriggerOutput(self, "Address", 	self.Memory[6])

	self:NextThink(CurTime()+0.01)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_cd_ray", WireLib.MakeWireEnt, "Data", "Range", "DefaultZero")
