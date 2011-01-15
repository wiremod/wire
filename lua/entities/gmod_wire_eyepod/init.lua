AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Eye Pod"
ENT.OverlayDelay = 0

function ENT:Initialize()
	-- Make Physics work
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	-- set it so we don't colide
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self.CollisionGroup = COLLISION_GROUP_WORLD
	-- turn off shadow
	self:DrawShadow(false)

	-- Set wire I/O
	self.Inputs = WireLib.CreateSpecialInputs(self, { "Enable", "SetPitch", "SetYaw", "SetViewAngle" }, {"NORMAL", "NORMAL", "NORMAL", "ANGLE"})
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "X", "Y", "XY" }, {"NORMAL", "NORMAL", "VECTOR2"})

	-- Initialize values
	self.driver = nil
	self.X = 0
	self.Y = 0
	self.enabled = 0
	self.pod = nil
	self.EyeAng = Angle(0,0,0)
	self.Rotate90 = false
	self.DefaultToZero = 1
	self.ShowRateOfChange = 0
	self.LastUpdateTime = CurTime()

	-- clamps
	self.ClampXMin = 0
	self.ClampXMax = 0
	self.ClampYMin = 0
	self.ClampYMax = 0
	self.ClampX = 0
	self.ClampY = 0

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
end

function ENT:Setup(DefaultToZero,RateOfChange,ClampXMin,ClampXMax,ClampYMin,ClampYMax, ClampX, ClampY)
	self.DefaultToZero = DefaultToZero
	self.ShowRateOfChange = RateOfChange
	self.ClampXMin = ClampXMin
	self.ClampXMax = ClampXMax
	self.ClampYMin = ClampYMin
	self.ClampYMax = ClampYMax
	self.ClampX = ClampX
	self.ClampY = ClampY
end

function ENT:PodLink(vehicle)
	if !IsValid(vehicle) or !vehicle:IsVehicle() then
		if IsValid(self.pod) then
			self.pod.AttachedWireEyePod = nil
		end
		self.pod = nil
		return false
	end
	self.pod = vehicle

	local Rotate90ModelList = {
		"models/props_c17/furniturechair001a.mdl",
		"models/airboat.mdl",
		"models/props_c17/chair_office01a.mdl",
		"models/nova/chair_office02.mdl",
		"models/nova/chair_office01.mdl",
		"models/props_combine/breenchair.mdl",
		"models/nova/chair_wood01.mdl",
		"models/nova/airboat_seat.mdl",
		"models/nova/chair_plastic01.mdl",
		"models/nova/jeep_seat.mdl",
		"models/props_phx/carseat.mdl",
		"models/props_phx/carseat2.mdl",
		"models/props_phx/carseat3.mdl",
		"models/buggy.mdl",
		"models/vehicle.mdl"
	}
	self.Rotate90 = false
	self.EyeAng = Angle(0,0,0)
	if IsValid(self.pod) and self.pod:IsVehicle() then
		if table.HasValue( Rotate90ModelList,string.lower( self.pod:GetModel() ) ) then
			self.Rotate90 = true
			self.EyeAng = Angle(0,90,0)
		end
	end


	local ttable = {
		AttachedWireEyePod = self
	}
	table.Merge(vehicle:GetTable(), ttable )
	return true
end

function ENT:OnRemove()
	if IsValid(self.pod) and self.pod:IsVehicle() then
		self.pod:GetTable().AttachedWireEyePod = nil
	end

	if IsValid(self.driver) then
		umsg.Start("UpdateEyePodState", self.driver)
			umsg.Short(0)
			umsg.Angle(self.EyeAng)
			umsg.Bool(self.Rotate90)
		umsg.End()
		self.driver = nil
	end
end

function ENT:Think()
	-- Make sure the gate updates even if we don't receive any input
	self:TriggerInput()

	if IsValid(self.pod) then
		-- if we are in a pod, set the player
		if self.pod:IsVehicle() and self.pod:GetDriver():IsPlayer() then
			self.driver = self.pod:GetDriver()
		else -- else set X and Y to 0
			if IsValid(self.driver) then
				umsg.Start("UpdateEyePodState", self.driver)
					umsg.Short(0)
					umsg.Angle(self.EyeAng)
					umsg.Bool(self.Rotate90)
				umsg.End()
				self.driver = nil
			end
			if (self.DefaultToZero == 1) then
				self.X = 0
				self.Y = 0
				Wire_TriggerOutput(self, "X", self.X)
				Wire_TriggerOutput(self, "Y", self.Y)
				local XY_Vec = {self.X,self.Y}
				Wire_TriggerOutput(self, "XY", XY_Vec)
			end
		end
	else -- else set X and Y to 0
		if IsValid(self.driver) then
			umsg.Start("UpdateEyePodState", self.driver)
				umsg.Short(0)
				umsg.Angle(self.EyeAng)
				umsg.Bool(self.Rotate90)
			umsg.End()
			self.driver = nil
		end
		if (self.DefaultToZero == 1) then
			self.X = 0
			self.Y = 0
			Wire_TriggerOutput(self, "X", self.X)
			Wire_TriggerOutput(self, "Y", self.Y)
			local XY_Vec = {self.X,self.Y}
			Wire_TriggerOutput(self, "XY", XY_Vec)
		end
		self.pod = nil
	end

	-- update the overlay with the user's name
	local Txt = "Eye Pod Control"
	if self.enabled == 1 and IsValid(self.driver) and self.driver:IsPlayer() then
		Txt = Txt.." - In use by "..self.driver:Name()
	else
		Txt = Txt.." - Not Active"
	end
	if IsValid(self.pod) and self.pod:IsVehicle() then
		Txt = Txt.."\nLinked to "..self.pod:GetModel()
	else
		Txt = Txt.."\nNot Linked"
	end

	if Txt ~= self.LastOverlay then
		self:SetNetworkedBeamString("GModOverlayText", Txt)
		self.LastOverlay = Txt
	end

	self:NextThink(CurTime() + 0.1)

	return true
end

local function AngNorm(Ang)
	return (Ang + 180) % 360 - 180
end
local function AngNorm90(Ang)
	return (Ang + 90) % 180 - 90
end

function ENT:TriggerInput(iname, value)
	-- Change variables to reflect input
	if (iname == "Enable") then
		if (value != 0) then
			self.enabled = 1
		else
			self.enabled = 0
		end
	elseif (iname == "SetPitch") then
		self.EyeAng = Angle(AngNorm90(value),self.EyeAng.y,self.EyeAng.r)
	elseif (iname == "SetYaw") then
		if (self.Rotate90 == true) then
			self.EyeAng = Angle(AngNorm90(self.EyeAng.p),AngNorm(value+90),self.EyeAng.r)
		else
			self.EyeAng = Angle(AngNorm90(self.EyeAng.p),AngNorm(value),self.EyeAng.r)
		end
	elseif (iname == "SetViewAngle") then
		if (self.Rotate90 == true) then
			self.EyeAng = Angle(AngNorm90(value.p),AngNorm(value.y+90),0)
		else
			self.EyeAng = Angle(AngNorm90(value.p),AngNorm(value.y),0)
		end
	end

	-- If we're not enabled, set the output to zero and exit
	if (self.enabled == 0) then
		if (self.DefaultToZero == 1) then
			self.X = 0
			self.Y = 0
			Wire_TriggerOutput(self, "X", self.X)
			Wire_TriggerOutput(self, "Y", self.Y)
			local XY_Vec = {self.X,self.Y}
			Wire_TriggerOutput(self, "XY", XY_Vec)
		end
		if IsValid(self.driver) and IsValid(self.pod) then
			umsg.Start("UpdateEyePodState", self.driver)
				umsg.Short(self.enabled)
				umsg.Angle(self.EyeAng)
				umsg.Bool(self.Rotate90)
			umsg.End()
		end
		return
	end

	--Turn on the EyePod Control file
	self.enabled = 1
	if IsValid(self.driver) and IsValid(self.pod) then
		umsg.Start("UpdateEyePodState", self.driver)
			umsg.Short(self.enabled)
			umsg.Angle(self.EyeAng)
			umsg.Bool(self.Rotate90)
		umsg.End()
	end

end

local UpdateTimer = CurTime()

local function EyePodMouseControl(ply, movedata)
	local Vehicle = nil
	local EyePod = nil
	--is the player in a vehicle?
	if ply and ply:InVehicle() and IsValid(ply:GetVehicle()) then
		Vehicle = ply:GetVehicle()
		local Table = Vehicle:GetTable()
		--is the vehicle linked to an EyePod?
		if Table and IsValid(Table.AttachedWireEyePod) then
			--get the EyePod
			EyePod = Table.AttachedWireEyePod
		else
			return
		end
	else
		return
	end

	if !IsValid(EyePod) or !IsValid(Vehicle) then return end

	if (EyePod.enabled == 1) then

		local cmd = ply:GetCurrentCommand()

		--update the cumualative output
		EyePod.X = cmd:GetMouseX()/10 + EyePod.X
		EyePod.Y = -cmd:GetMouseY()/10 + EyePod.Y

		--clamp the output
		if EyePod.ClampX == 1 then
			EyePod.X = math.Clamp(EyePod.X,EyePod.ClampXMin,EyePod.ClampXMax)
		end
		if EyePod.ClampY == 1 then
			EyePod.Y = math.Clamp(EyePod.Y,EyePod.ClampYMin,EyePod.ClampYMax)
		end

		--update the outputs every 0.015 seconds
		if (CurTime() > (EyePod.LastUpdateTime+0.015)) then
			Wire_TriggerOutput(EyePod, "X", EyePod.X)
			Wire_TriggerOutput(EyePod, "Y", EyePod.Y)
			local XY_Vec = {EyePod.X,EyePod.Y}
			Wire_TriggerOutput(EyePod, "XY", XY_Vec)
			--reset the output so it is not cumualative if you want the rate of change
			if EyePod.ShowRateOfChange == 1 then
				EyePod.X = 0
				EyePod.Y = 0
			end
			EyePod.LastUpdateTime = CurTime()
		end

		--reset the mouse
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
		return

	end
end
hook.Add("SetupMove", "WireEyePodMouseControl", EyePodMouseControl)

-- Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.pod) then
		info.pod = self.pod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.pod) then
		self.pod = GetEntByID(info.pod)
		if !self.pod then
			self.pod = ents.GetByIndex(info.pod)
		end
		if self.pod then
			self:PodLink(self.pod)
		end
	end
end
