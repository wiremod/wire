AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Analog Lever"
ENT.WireDebugName	= "Lever"

function ENT:CalcAngle(shootPos, shootDir)
	local myPos = self:GetPos()
	local right = self:GetRight()

	local planeHitPos = self:WorldToLocal(shootPos + shootDir * ((myPos - shootPos):Dot(right) / shootDir:Dot(right)))

	self.Ang = math.Clamp( math.deg( math.atan2( planeHitPos[1], planeHitPos[3] ) ), -45, 45 )
end

if CLIENT then

	function ENT:Initialize()
		self.RBMin, self.RBMax = self:GetRenderBounds()
		self.RBMin:Add(Vector(-30,0,0))
		self.RBMax:Add(Vector(30,0,60))
	end

	local RenderGroup = ENT.RenderGroup

	function ENT:Draw()
		if not IsValid(self.csmodel) then
			self.csmodel = ClientsideModel("models/props_wasteland/tram_lever01.mdl",RenderGroup)
			self.csmodel:SetParent(self)
			self.NextRBUpdate = 0
		end

		-- If user, calculate clientside, otherwise get server value
		self.User = self:GetNWEntity("User",NULL)
		if IsValid(self.User) then
			self:CalcAngle(self.User:GetShootPos(), self.User:GetAimVector())
		else
			self.Ang = self:GetNWFloat("Ang",0) -- get networked ang
		end

		local lever_ang = Angle(self.Ang,0,0)
		local ang = self:LocalToWorldAngles(lever_ang)
		local pos = self:LocalToWorld(lever_ang:Up() * 21)

		render.Model({
			model = self.csmodel:GetModel(),
			pos = pos,
			angle = ang
		}, self.csmodel)

		BaseClass.Draw(self)
	end

	function ENT:Think()
		if (CurTime() >= (self.NextRBUpdate or 0)) then
			self.NextRBUpdate = CurTime() + 10
			self:SetRenderBounds(self.RBMin, self.RBMax)
		end

		local isClicking = LocalPlayer():KeyDown(IN_USE) or LocalPlayer():KeyDown(IN_ATTACK)
		if isClicking and not self.wasClicking and IsValid(self.csmodel) then
			local aimPos = LocalPlayer():GetShootPos()
			if aimPos:DistToSqr(self:GetPos())<100^2 then
				local rayPos = util.IntersectRayWithOBB(
					aimPos,
					LocalPlayer():GetAimVector() * 100,
					self.csmodel:GetPos(),
					self.csmodel:GetAngles(),
					self.csmodel:OBBMins() - Vector(2,2,2),
					self.csmodel:OBBMaxs() + Vector(2,2,2)
				)
				if rayPos then
					net.Start("wire_lever_activate")
						net.WriteEntity(self)
					net.SendToServer()
				end
			end
		end
		self.wasClicking = isClicking

		-- Don't call baseclass think or else renderbounds will be overwritten
	end
else
	util.PrecacheModel( "models/props_wasteland/tram_lever01.mdl" )

	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		self.Ang = 0
		self.Value = 0
		self:Setup(0, 1)

		self.Inputs = WireLib.CreateInputs(self, {"SetValue", "Min", "Max"})
		self.Outputs = WireLib.CreateOutputs(self, {"Value", "Entity [ENTITY]"})
	end

	function ENT:Setup(min, max)
		min = min or 0
		max = max or 1
		self.Min = math.min(min, max)
		self.Max = math.max(min, max)
	end

	function ENT:TriggerInput(iname, value)
		if iname == "SetValue" then
			self.Ang = (math.Clamp(value, self.Min, self.Max) - self.Min)/(self.Max - self.Min) * 90 - 45
		elseif (iname == "Min") then
			self.Min = value
		elseif (iname == "Max") then
			self.Max = value
		end
	end

	function ENT:Use( ply )
		if not IsValid(ply) or not ply:IsPlayer() or IsValid(self.User) then return end
		self.User = ply
		WireLib.TriggerOutput( self, "Entity", ply)
		self:SetNWEntity("User",self.User)
	end

	util.AddNetworkString("wire_lever_activate")
	net.Receive("wire_lever_activate", function(netlen, ply)
		local ent = net.ReadEntity()
		if not IsValid(ply) or not IsValid(ent) or not ent.Use or ent:GetClass() ~= "gmod_wire_lever" then return end
		if IsValid(ent.User) then return end

		if ply:GetShootPos():DistToSqr(ent:GetPos()) < 100^2 then
			ent:Use(ply, ply, USE_ON, 1)
		end
	end)

	function ENT:Think()
		BaseClass.Think(self)

		if IsValid(self.User) then
			local shootPos = self.User:GetShootPos()
			if shootPos:DistToSqr(self:GetPos()) < 100^2 and (self.User:KeyDown(IN_USE) or self.User:KeyDown(IN_ATTACK)) then
				local shootDir = self.User:GetAimVector()
				self:CalcAngle(shootPos, shootDir)
			else
				self.User = NULL
				WireLib.TriggerOutput( self, "Entity", NULL)
				self:SetNWEntity("User",self.User)
			end
		end

		local oldvalue = self.Value
		self.Value = Lerp((self.Ang + 45) / 90, self.Min, self.Max)
		if self.Value ~= oldvalue then
			WireLib.TriggerOutput(self, "Value", self.Value)
			self:ShowOutput()
			self:SetNWFloat("Ang",self.Ang)
		end

		self:NextThink(CurTime())
		return true
	end

	function ENT:ShowOutput()
		self:SetOverlayText(string.format("(%.2f - %.2f) = %.2f", self.Min, self.Max, self.Value))
	end

	function ENT:ConvertFromOldLever(base)
		-- remove all constraints from self
		self:SetParent()
		constraint.RemoveAll(self)

		local original_solid = self:GetSolid()
		local original_motion = self:GetPhysicsObject():IsMotionEnabled()

		-- remove collisions and freeze to prevent the entity from flying away
		self:SetNotSolid(true)
		self:GetPhysicsObject():EnableMotion(false)

		-- change model and move into new position
		self:SetModel("models/props_wasteland/tram_leverbase01.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetPos(base:GetPos())
		self:SetAngles(base:GetAngles())

		timer.Simple(0,function() -- give the setpos time to be applied
			if not IsValid(self) then return end

			-- make copies of welds and nocollides and
			-- move the constraints to self instead of base
			-- we're only doing welds and nocollides to avoid any strange
			-- issues, I think it's good enough :tm:
			if base.Constraints then
				for _, con in pairs( base.Constraints ) do
					local Ent1 = con.Ent1
					local Ent2 = con.Ent2
					local Bone1 = con.Bone1
					local Bone2 = con.Bone2

					-- Move the target entity from base to self
					if Ent1 == base then Ent1 = self
					elseif Ent2 == base then Ent2 = self end

					if con.Type == "Weld" then
						local ForceLimit = con.forcelimit
						local NoCollide = con.nocollide
						local DeleteOnBreak = false -- can't be copied easily, so we'll assume it's false to save us the trouble

						constraint.Weld(Ent1,Ent2,Bone1,Bone2,ForceLimit,NoCollide,DeleteOnBreak)
					elseif con.Type == "NoCollide" then
						constraint.NoCollide(Ent1,Ent2,Bone1,Bone2)
					end
				end
			end

			-- copy parent
			self:SetParent(base:GetParent())
			base:Remove()

			-- reset original values
			self:SetNotSolid(not original_solid)
			self:GetPhysicsObject():EnableMotion(original_motion)
		end)
	end

	local fix_after_dupe = setmetatable({},{__mode="kv"})
	hook.Add("AdvDupe_FinishPasting","LeverFixOldDupe",function(data)
		if next(fix_after_dupe) == nil then return end

		local levers = {}
		for __, ent in pairs( data[1].CreatedEntities ) do
			if ent:GetClass()=="gmod_wire_lever" then
				levers[ent] = true
			end
		end
		-- this hook is also called on garrydupe's paste, thanks to wirelib.lua
		for self, base in pairs(fix_after_dupe) do
			if base:IsValid() and self:IsValid() then
				if levers[self] then
					self:ConvertFromOldLever(base)
					fix_after_dupe[self] = nil
				end
			else
				if base:IsValid() then base:Remove() end
				if self:IsValid() then self:Remove() end
				fix_after_dupe[self] = nil
			end
		end
	end)

	function ENT:BuildDupeInfo()
		local info = BaseClass.BuildDupeInfo(self) or {}
		info.value = self.Value
		return info
	end

	function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
		BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

		-- this is only used to update the entity to the latest version
		-- if it's found to be an old dupe
		if info.baseent then
			local base = GetEntByID(info.baseent)
			fix_after_dupe[self] = base
		end
		if info.value then
			self.Value = nil -- So the value is dirty no matter what
			self:TriggerInput("SetValue", info.value)
		end

	end

	duplicator.RegisterEntityClass("gmod_wire_lever", WireLib.MakeWireEnt, "Data", "Min", "Max" )

end
