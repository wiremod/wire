AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Pod Controller"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Output keys. Format: self.Keys["name"] = IN_*
	self.Keys = { }
	self.Keys["Attack"] = IN_ATTACK
	self.Keys["Attack2"] = IN_ATTACK2
	self.Keys["Forward"] = IN_FORWARD
	self.Keys["Left"] = IN_MOVELEFT
	self.Keys["Back"] = IN_BACK
	self.Keys["Right"] = IN_MOVERIGHT
	self.Keys["Reload"] = IN_RELOAD
	self.Keys["Jump"] = IN_JUMP
	self.Keys["Duck"] = IN_DUCK
	self.Keys["Sprint"] = IN_SPEED
	self.Keys["Zoom"] = IN_ZOOM

	-- Invert the table to use it with Wire_CreateOutputs
	local outputs = { }
	local n = 1

	for k, v in pairs( self.Keys ) do
		outputs[n] = k
		n = n + 1
	end

	outputs[n] = "Active"

	self.VPos = Vector(0, 0, 0)

	-- Create outputs
	self.Outputs = Wire_CreateOutputs( self, outputs )
	self.Inputs = Wire_CreateInputs( self, { "Lock", "Eject", "Crosshair", "Open" } )
end

function ENT:SetKeys(keys)
	self.Keys = keys
	local out = {}
	for k,v in pairs(keys) do
		out[#out+1] = k
	end
	out[#out+1] = "Active"
	WireLib.AdjustOutputs(self, out)
end

-- Link to pod
function ENT:Setup(pod)
	self.Pod = pod
end

-- Called every 0.01 seconds, check for key down
function ENT:Think()
	-- Check that we have a pod
	if self.Pod and self.Pod:IsValid() then
		self.Ply = self.Pod:GetPassenger(0)

		if self.Ply and self.Ply:IsValid() and self.Keys then
			-- Loop through all the self.Keys, and check if they was pressed last frame
			for k, v in pairs(self.Keys)  do
				if self.Ply:KeyDownLast(v) then
					Wire_TriggerOutput(self, k, 1)
				else
					Wire_TriggerOutput(self, k, 0)
				end
			end
			local trace = util.GetPlayerTrace(self.Ply)
			trace.filter = self.Pod
			self.VPos = util.TraceLine(trace).HitPos or self.VPos
			Wire_TriggerOutput(self, "Active", 1)
		else
			Wire_TriggerOutput(self, "Active", 0)
		end
	end
	self:NextThink(CurTime() + 0.01)
	return true
end

function ENT:TriggerInput(iname, value)
	if not (self.Pod and self.Pod:IsValid()) then return end
	if iname == "Lock" then
		if value ~= 0 then
			self.Pod:Fire("Lock", "1", 0)
		else
			self.Pod:Fire("Unlock", "1", 0)
		end
	elseif iname == "Eject" then
		if value ~= 0 then
			self.Pod:Fire("ExitVehicle", "1", 0)
		end
	elseif iname == "Crosshair" and self.Ply and self.Ply:IsValid() then
		if value ~= 0 then
			self.Ply:CrosshairEnable()
		else
			self.Ply:CrosshairDisable()
		end
	elseif iname == "Open" then
		if value ~= 0 then
			self.Pod:Fire("Open", "1", 0)
		else
			self.Pod:Fire("Close", "1", 0)
		end
	end
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end
function ENT:GetBeaconVelocity(sensor)
	return IsValid(self.Pod) and self.Pod:GetVelocity() or Vector()
end

-- Duplicator support to save pod link (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if self.Pod and self.Pod:IsValid() then
	    info.pod = self.Pod:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.pod then
		self.Pod = GetEntByID(info.pod)
		if not (self.Pod and self.Pod:IsValid())  then
			self.Pod = ents.GetByIndex(info.pod)
		end
	end
end
