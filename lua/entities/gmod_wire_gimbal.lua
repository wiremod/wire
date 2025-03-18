AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Gimbal"
ENT.WireDebugName 	= "Gimbal"

local ORIGIN_COLOR  = Color(255, 150, 50)
local FORWARD_COLOR = Color(255, 100, 100)
local RIGHT_COLOR   = Color(100, 255, 100)
local UP_COLOR      = Color(100, 100, 255)

local function DrawOutlinedBeam(startPos, endPos, size, color)
	render.DrawBeam(startPos, endPos, size + 0.2, 0, 1, color_black)
	render.DrawBeam(startPos, endPos, size, 0, 1, color)
end

function ENT:DrawWorldTip()
	BaseClass.DrawWorldTip(self)

	cam.Start3D()
	local origin      = self:GetPos()
	local mi, ma      = self:GetModelRenderBounds()
	local forwardSize = math.max(math.abs(mi[1]), ma[1])
	local rightSize   = math.max(math.abs(mi[2]), ma[2])
	local upSize      = math.max(math.abs(mi[3]), ma[3])
	
	local forward = self:GetForward() * forwardSize
	local right   = self:GetRight() * rightSize
	local up      = self:GetUp() * upSize
	
	render.SetColorMaterialIgnoreZ()
	
	DrawOutlinedBeam(origin, origin + forward, 0.2, FORWARD_COLOR)
	DrawOutlinedBeam(origin, origin + right, 0.2, RIGHT_COLOR)
	DrawOutlinedBeam(origin, origin + up, 0.2, UP_COLOR)
	
	render.DrawSphere(origin, 0.35, 8, 8, color_black)
	render.DrawSphere(origin, 0.2, 8, 8, ORIGIN_COLOR)
	cam.End3D()
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:GetPhysicsObject():EnableGravity(false)

	self.Inputs = WireLib.CreateInputs(self,{"On", "X", "Y", "Z", "Target [VECTOR]", "Direction [VECTOR]", "Angle [ANGLE]", "AngleOffset [ANGLE]"})

	self.XYZ = Vector()
	self.TargetAngOffset = Matrix()
	self.TargetAngOffset:SetAngles(Angle(90,0,0))
end

function ENT:TriggerInput(name,value)
	if name == "On" then
		self.On = value ~= 0
	else
		self.TargetPos = nil
		self.TargetDir = nil
		self.TargetAng = nil

		if name == "X" then
			self.XYZ.x = value
			self.TargetPos = self.XYZ
		elseif name == "Y" then
			self.XYZ.y = value
			self.TargetPos = self.XYZ
		elseif name == "Z" then
			self.XYZ.z = value
			self.TargetPos = self.XYZ
		elseif name == "Target" then
			self.XYZ = Vector(value.x, value.y, value.z)
			self.TargetPos = self.XYZ
		elseif name == "Direction" then
			self.TargetDir = value
		elseif name == "Angle" then
			self.TargetAng = value
		elseif name == "AngleOffset" then
			self.TargetAngOffset = Matrix()
			self.TargetAngOffset:SetAngles(value)
		end
	end
	self:ShowOutput()
	return true
end


function ENT:Think()
	if self.On then
		local ang
		if self.TargetPos then
			ang = (self.TargetPos - self:GetPos()):Angle()
		elseif self.TargetDir then
			ang = self.TargetDir:Angle()
		elseif self.TargetAng then
			ang = self.TargetAng
		end
		if ang then
			local m = Matrix()
			m:SetAngles(ang)
			m = m * self.TargetAngOffset
			self:SetAngles(m:GetAngles())
		end
		-- TODO: Put an option in the CPanel for Angle(90,0,0), and other useful directions
		self:GetPhysicsObject():Wake()
	end
	self:NextThink(CurTime())
	return true
end

function ENT:ShowOutput()
	if not self.On then
		self:SetOverlayText("Off")
	elseif self.TargetPos then
		self:SetOverlayText(string.format("Aiming towards (%.2f, %.2f, %.2f)", self.XYZ.x, self.XYZ.y, self.XYZ.z))
	elseif self.TargetDir then
		self:SetOverlayText(string.format("Aiming (%.4f, %.4f, %.4f)", self.TargetDir.x, self.TargetDir.y, self.TargetDir.z))
	elseif self.TargetAng then
		self:SetOverlayText(string.format("Aiming (%.1f, %.1f, %.1f)", self.TargetAng.pitch, self.TargetAng.yaw, self.TargetAng.roll))
	end
end

duplicator.RegisterEntityClass("gmod_wire_gimbal", WireLib.MakeWireEnt, "Data")
