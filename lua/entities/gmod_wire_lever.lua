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
		local distance = LocalPlayer():GetPos():Distance(self:GetPos())
		if distance < MAX_RENDER_DISTANCE then
			if not IsValid(self.csmodel) then
				self.csmodel = ClientsideModel("models/props_wasteland/tram_lever01.mdl",RenderGroup)
			end

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
		elseif self.csmodel then
			self.csmodel:Remove()
			self.csmodel = nil
		end
		BaseClass.Draw(self)
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

	duplicator.RegisterEntityClass("gmod_wire_lever", WireLib.MakeWireEnt, "Data", "Min", "Max" )

end