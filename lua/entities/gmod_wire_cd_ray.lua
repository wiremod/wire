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
	self.Inputs = Wire_CreateInputs(self, {"Write","Read","Value","Range"})
	self.Outputs = Wire_CreateOutputs(self, {"Data","Sector","LocalSector","Track","Stack","Address"})

	self.Command = {}
	self.Command[0]  = 0 //[W] Write ray on
	self.Command[1]  = 0 //[W] Read ray on
	self.Command[2]  = 0 //[R] Current sector (global)
	self.Command[3]  = 0 //[R] Current sector (on track)
	self.Command[4]  = 0 //[R] Current track
	self.Command[5]  = 0 //[R] Current stack
	self.Command[6]  = 0 //[R] Current address (global)
	self.Command[7]  = 0 //[R] Current address (in current stack)

	self.Command[8]  = 0 //[W] Buffer ready (read or write - pick the ray)
	self.Command[9]  = 0 //[W] Continious mode
	self.Command[10] = 0 //[W] Wait for address mode
	self.Command[11] = 0 //[W] Target address (in current stack)
	self.Command[12] = 0 //[W] Wait for track&sector mode
	self.Command[13] = 0 //[W] Target sector
	self.Command[14] = 0 //[W] Target track

	self.Command[21] = 0 //[R] Raw disk spin velocity
	self.Command[22] = 0 //[R] Raw disk spin angle
	self.Command[23] = 0 //[R] Raw distance from disk center
	self.Command[24] = 0 //[R] Raw stack index

	self.Command[25] = 0 //[R] Disk precision (Inches Per Block)
	self.Command[26] = 0 //[R] Disk sectors (total)
	self.Command[27] = 0 //[R] Disk tracks (total)
	self.Command[28] = 0 //[R] First track number
	self.Command[29] = 0 //[R] Bytes per block
	self.Command[30] = 0 //[R] Disk size (per stack)
	self.Command[31] = 0 //[R] Disk volume (bytes total)
	self.Command[32] = 0 //[R] Disk entity id

	self.WriteBuffer = {}
	self.PrevDiskEnt = nil

	self:SetBeamLength(64)
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	if (Address >= 0) and (Address < 512) then
		if (self.Command[Address]) then
			return self.Command[Address]
		else
			return 0
		end
	end
	if (Address >= 512) and (Address < 1024) then
		if (self.WriteBuffer[Address-512]) then
			return self.WriteBuffer[Address-512]
		else
			return 0
		end
	end
	return nil
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	if (Address >= 0) and (Address < 512) then
		self.Command[Address] = value
		if (Address == 8) then
			self:DoJob()
		end
		return true
	end
	if (Address >= 512) and (Address < 1024) then
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
		self.Command[0] = value
		self.Command[8] = 1
		self.Command[9] = 1
	elseif (iname == "Read") then
		self.Command[1] = value
		self.Command[8] = 1
		self.Command[9] = 1
	elseif (iname == "Value") then
		self.Command[8] = 1
		self.Command[9] = 1
		self.WriteBuffer[0] = value
	elseif(iname == "Range")then
		self:SetBeamLength(math.Clamp(value,0,32000))
	end
end

function ENT:DoJob()
	if (not self.Disk) then return end
	local disk = self.Disk
	if (self.Command[8] ~= 0) then
		local dojob = true
		if (self.Command[10] ~= 0) then
			if (self.Command[11] ~= self.Command[7]) then dojob = false end
		end
		if (self.Command[12] ~= 0) then
			if (self.Command[13] ~= self.Command[3]) or (self.Command[14] ~= self.Command[4]) then
				dojob = false
			end
		end

		if dojob then
			if (self.Command[9] == 0) then self.Command[8] = 0 end
			local sector_addr = self.Sector.."."..self.Track.."."..self.Stack//{s=sector,t=track,st=stack}
			if (self.Command[0] ~= 0) then //write ray
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

	if ((self.Command[0] ~= 0) or (self.Command[1] ~= 0)) then
		if (self.Command[0] == 1) then --write ray (blue)
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

			self.Command[25] = disk.Precision
			self.Command[26] = disk.DiskSectors
			self.Command[27] = disk.DiskTracks
			self.Command[28] = disk.FirstTrack
			self.Command[29] = disk.BytesPerBlock
			self.Command[30] = disk.DiskSize
			self.Command[31] = disk.DiskVolume
			self.Command[32] = disk.Entity:EntIndex()
		end

		if ((track >= disk.FirstTrack) and (stack >= 0) and (sector >= 0) and
			//(track < disk.DiskTracks) and
			(stack < disk.DiskStacks)) then
			self.Command[21] = vel //[R] Raw disk spin velocity
			self.Command[22] = a //[R] Raw disk spin angle
			self.Command[23] = r //[R] Raw distance from disk center
			self.Command[24] = h //[R] Raw stack index

			if (not disk.TrackSectors[track]) then disk.TrackSectors[track] = 0 end

			self.Command[2]  = disk.DiskSectors*stack+disk.TrackSectors[track]+sector //[R] Current sector (global)
			self.Command[3]  = sector //[R] Current sector (on track)
			self.Command[4]  = track //[R] Current track
			self.Command[5]  = stack //[R] Current stack
			self.Command[6]  = self.Command[2]*disk.BytesPerBlock //[R] Current address (global)
			self.Command[7]  = (disk.TrackSectors[track]+sector)*disk.BytesPerBlock //[R] Current address (in current stack)

			if ((self.Command[0] ~= 0) or (self.Command[1] ~= 0)) then
				self.Sector = sector
				self.Track = track
				self.Stack = stack
				self.Disk = disk
				self:DoJob()
			end
		else
			self.Command[21] = 0
			self.Command[22] = 0
			self.Command[23] = 0
			self.Command[24] = 0

			self.Command[2]  = 0
			self.Command[3]  = 0
			self.Command[4]  = 0
			self.Command[5]  = 0
			self.Command[6]  = 0
			self.Command[7]  = 0
		end
	else
		self.PrevDiskEnt = nil
		self.Disk = nil

		self.Command[2]  = 0
		self.Command[3]  = 0
		self.Command[4]  = 0
		self.Command[5]  = 0
		self.Command[6]  = 0
		self.Command[7]  = 0

		self.Command[21] = 0
		self.Command[22] = 0
		self.Command[23] = 0
		self.Command[24] = 0
		self.Command[25] = 0
		self.Command[26] = 0
		self.Command[27] = 0
		self.Command[28] = 0
		self.Command[29] = 0
		self.Command[30] = 0
		self.Command[31] = 0
		self.Command[32] = 0
	end

	//Update output
	if (self.WriteBuffer[0]) then
		Wire_TriggerOutput(self, "Data",self.WriteBuffer[0])
	else
		Wire_TriggerOutput(self, "Data",0)
	end
	Wire_TriggerOutput(self, "Sector", 	self.Command[2])
	Wire_TriggerOutput(self, "LocalSector",	self.Command[3])
	Wire_TriggerOutput(self, "Track", 	self.Command[4])
	Wire_TriggerOutput(self, "Stack", 	self.Command[5])
	Wire_TriggerOutput(self, "Address", 	self.Command[6])

	self:NextThink(CurTime()+0.01)
	return true
end

duplicator.RegisterEntityClass("gmod_wire_cd_ray", WireLib.MakeWireEnt, "Data", "Range", "DefaultZero")
