AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Analog Lever"
ENT.WireDebugName	= "Lever"

function ENT:CalcAngle(dist) -- ('dist' is passed so we don't have to re-calculate it)
	local TargPos = self.User:GetShootPos() + self.User:GetAimVector() * dist
	local distMax = TargPos:Distance(self:GetPos() + self:GetForward() * 30)
	local distMin = TargPos:Distance(self:GetPos() + self:GetForward() * -30)
	local FPos = (distMax - distMin) * 0.5
	distMax = TargPos:Distance(self:GetPos())
	distMin = TargPos:Distance(self:GetPos() + self:GetUp() * 40)
	local HPos = 20 - ((distMin - distMax) * 0.5)

	self.Ang = math.Clamp( math.deg( math.atan2( HPos, FPos ) ) - 90, -45, 45 )
end

if CLIENT then

	local MAX_RENDER_DISTANCE = 1024
	local RenderGroup = ENT.RenderGroup

	function ENT:Draw()
		if IsValid(self.csmodel) then
			self.Ang = self:GetNWFloat("Ang",0) -- get networked ang

			-- however, if we are able, also calculate the angle more accurately clientside
			self.User = self:GetNWEntity("User",NULL)
			if IsValid(self.User) then
				self:CalcAngle(self.User:GetShootPos():Distance(self:GetPos()))
			end

			local lever_ang = Angle(self.Ang,0,0)
			local ang = self:LocalToWorldAngles(lever_ang)
			local pos = self:LocalToWorld(lever_ang:Up() * 21)

			render.Model({
				model = self.csmodel:GetModel(),
				pos = pos,
				angle = ang
			}, self.csmodel)
		end
		BaseClass.Draw(self)
	end

	function ENT:Think()
		-- check if user is close enough to render lever
		local curtime = CurTime()
		if curtime >= (self.NextDistanceCheck or 0) then
			self.NextDistanceCheck = curtime + 1
			local distance = LocalPlayer():GetPos():Distance(self:GetPos())
			if distance < MAX_RENDER_DISTANCE then
				if not IsValid(self.csmodel) then
					self.csmodel = ClientsideModel("models/props_wasteland/tram_lever01.mdl",RenderGroup)
				end
			else
				self.csmodel:Remove()
				self.csmodel = nil
			end
		end
		
		-- check if we need to update renderbounds
		if curtime >= (self.NextRBUpdate or 0) then
			self.NextRBUpdate = curtime + 10

			if not IsValid(self.csmodel) then return end

			local function vecmin(v1,v2)
				return Vector(
					v1.x < v2.x and v1.x or v2.x,
					v1.y < v2.y and v1.y or v2.y,
					v1.z < v2.z and v1.z or v2.z
				)
			end
			local function vecmax(v1,v2)
				return Vector(
					v1.x > v2.x and v1.x or v2.x,
					v1.y > v2.y and v1.y or v2.y,
					v1.z > v2.z and v1.z or v2.z
				)
			end

			local self_min, self_max = self:WorldSpaceAABB()
			local lever_min, lever_max = self.csmodel:WorldSpaceAABB()
			local new_min, new_max = vecmin(self_min,lever_min), vecmax(self_max,lever_max)

			new_min = self:WorldToLocal(new_min)
			new_max = self:WorldToLocal(new_max)

			self:SetRenderBounds(new_min, new_max)
		end

		BaseClass.Think(self)
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
		if min then self.Min = min end
		if max then self.Max = max end
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

	function ENT:Think()
		BaseClass.Think(self)

		if IsValid(self.User) then
			local dist = self.User:GetShootPos():Distance(self:GetPos())
			if dist < 160 and (self.User:KeyDown(IN_USE) or self.User:KeyDown(IN_ATTACK)) then
				self:CalcAngle(dist)
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

	local fix_after_dupe = {}
	hook.Add("AdvDupe_FinishPasting","LeverFixOldDupe",function(data)
		-- yes, this is also called on garrydupe paste, thanks to wirelib.lua
		for i=#fix_after_dupe,1,-1 do
			local base = fix_after_dupe[i].base
			local self = fix_after_dupe[i].self

			local found = false

			for __,ent in pairs( data[1].CreatedEntities ) do
				if ent == self or ent == base then
					found = true
					break
				end
			end

			if found then
				table.remove(fix_after_dupe,i)

				-- remove all constraints from self
				self:SetParent() -- temporarily parent to base to prevent the entity from flying off
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

					self:SetNotSolid(not original_solid)
					self:GetPhysicsObject():EnableMotion(original_motion)
				end)
			end
		end
	end)

	function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
		BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

		-- this is only used to update the entity to the latest version
		-- if it's found to be an old dupe
		if info.baseent then
			local base = GetEntByID(info.baseent)

			fix_after_dupe[#fix_after_dupe+1] = {self=self,base=base}
		end
	end

	duplicator.RegisterEntityClass("gmod_wire_lever", WireLib.MakeWireEnt, "Data", "Min", "Max" )

end