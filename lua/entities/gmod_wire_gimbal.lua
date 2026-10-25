AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Gimbal"
ENT.WireDebugName = "Gimbal"

if CLIENT then
	local function DrawOutlinedBeam(start_pos, end_pos, size, color)
		render.DrawBeam(start_pos, end_pos, size + 0.2, 0, 1, color_black)
		render.DrawBeam(start_pos, end_pos, size, 0, 1, color)
	end

	function ENT:DrawWorldTip()
		BaseClass.DrawWorldTip(self)

		cam.Start3D()
			local origin = self:GetPos()
			local mins, maxs = self:GetModelRenderBounds()

			local forward = self:GetForward()
			forward:Mul(math.max(math.abs(mins[1]), maxs[1]))

			local right = self:GetRight()
			right:Mul(math.max(math.abs(mins[2]), maxs[2]))

			local up = self:GetUp()
			up:Mul(math.max(math.abs(mins[3]), maxs[3]))

			render.SetColorMaterialIgnoreZ()
			DrawOutlinedBeam(origin, origin + forward, 0.2, Color(255, 100, 100))
			DrawOutlinedBeam(origin, origin + right, 0.2, Color(100, 255, 100))
			DrawOutlinedBeam(origin, origin + up, 0.2, Color(100, 100, 255))

			render.DrawSphere(origin, 0.35, 8, 8, color_black)
			render.DrawSphere(origin, 0.2, 8, 8, Color(255, 150, 50))
		cam.End3D()
	end

	return
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:EnableGravity(false)
	end

	self.XYZ = Vector(0, 0, 0)
	self.TargetAngOffset = Matrix()
	self.TargetAngOffset:SetAngles(Angle(90, 0, 0))

	WireLib.CreateInputs(self, { "On", "X", "Y", "Z", "Target [VECTOR]", "Direction [VECTOR]", "Angle [ANGLE]", "AngleOffset [ANGLE]" })
end

function ENT:TriggerInput(name, value)
	local tab = self:GetTable()

	if name == "On" then
		tab.On = value ~= 0
	else
		tab.TargetPos = nil
		tab.TargetDir = nil
		tab.TargetAng = nil

		if name == "X" then
			tab.XYZ.x = value
			tab.TargetPos = tab.XYZ
		elseif name == "Y" then
			tab.XYZ.y = value
			tab.TargetPos = tab.XYZ
		elseif name == "Z" then
			tab.XYZ.z = value
			tab.TargetPos = tab.XYZ
		elseif name == "Target" then
			tab.XYZ = Vector(value)
			tab.TargetPos = tab.XYZ
		elseif name == "Direction" then
			tab.TargetDir = value
		elseif name == "Angle" then
			tab.TargetAng = value
		elseif name == "AngleOffset" then
			tab.TargetAngOffset:SetAngles(value)
		end
	end
end

function ENT:Think()
	local tab = self:GetTable()

	if tab.On then
		local ang

		if tab.TargetPos then
			local pos = self:GetPos()
			pos:Negate()
			pos:Add(tab.TargetPos)
			ang = pos:Angle()
		elseif tab.TargetDir then
			ang = tab.TargetDir:Angle()
		elseif tab.TargetAng then
			ang = Angle(tab.TargetAng)
		end

		if ang then
			local matrix = Matrix()
			matrix:SetAngles(ang)
			matrix:Mul(tab.TargetAngOffset)
			self:SetAngles(matrix:GetAngles())
		end

		local phys = self:GetPhysicsObject()

		if phys:IsValid() then
			phys:Wake()
		end
	end

	self:NextThink(CurTime())

	return true
end

function ENT:PrepareOverlayData()
	local tab = self:GetTable()

	if not tab.On then
		tab.SetOverlayText(self, "Off")
	elseif tab.TargetPos then
		tab.SetOverlayText(self, string.format("Aiming position (%.2f, %.2f, %.2f)", tab.XYZ:Unpack()))
	elseif tab.TargetDir then
		tab.SetOverlayText(self, string.format("Aiming direction (%.4f, %.4f, %.4f)", tab.TargetDir:Unpack()))
	elseif tab.TargetAng then
		tab.SetOverlayText(self, string.format("Aiming angle (%.1f, %.1f, %.1f)", tab.TargetAng:Unpack()))
	else
		tab.SetOverlayText(self, "Aiming nothing")
	end
end

duplicator.RegisterEntityClass("gmod_wire_gimbal", WireLib.MakeWireEnt, "Data")
