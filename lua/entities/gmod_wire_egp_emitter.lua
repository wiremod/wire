AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_egp" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

ENT.IsEGP = true
ENT.gmod_wire_egp_emitter = true

local DrawOffsetPos = Vector(0, 0, 71)
local DrawOffsetAng = Angle(0, 0, 90)
local DrawScale     = 0.25
local DrawOffsetNoRT = Vector(-64,0,64)

if SERVER then

	function ENT:Initialize()
		BaseClass.Initialize(self)

		self:SetDrawOffsetPos(DrawOffsetPos)
		self:SetDrawOffsetAng(DrawOffsetAng)
		self:SetDrawScale(DrawScale)
		self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

		WireLib.CreateInputs(self, {
			"Scale (Increase or decrease draw scale. Limited between 0.04 and 2)",
			"Position (Offsets the draw position. Limited between -150 to +150 in any direction away from the emitter.) [VECTOR]",
			"Angle (Offsets the draw angle.) [ANGLE]"
		})
	end

	function ENT:TriggerInput(iname, value)
		if iname == "Scale" then
			self:SetDrawScale( math.Clamp(value * 0.25, 0.01, 0.5) )

		elseif iname == "Position" then
			local x = math.Clamp(value.x, -150, 150)
			local y = math.Clamp(value.y, -150, 150)
			local z = math.Clamp(value.z, -150, 150)

			self:SetDrawOffsetPos(Vector(x, y, z))
		elseif iname == "Angle" then
			self:SetDrawOffsetAng(value)
		end
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "DrawScale" )
	self:NetworkVar( "Vector", 0, "DrawOffsetPos" )
	self:NetworkVar( "Angle", 0, "DrawOffsetAng" )
	self:NetworkVar( "Bool", 0, "UseRT" )

	if CLIENT then
		self:NetworkVarNotify("UseRT", function(self, _, _, new)
			local hasGPU = self.GPU ~= nil
			if not new and hasGPU then
				self.GPU:FreeRT() -- remove gpu RT
				self.GPU = nil
				self:EGP_Update()
			elseif new and not hasGPU then
				local t = self.RenderTable -- save reference
				BaseClass.Initialize(self)
				self.GPU.GetInfo = function()
					local pos = self:LocalToWorld(self:GetDrawOffsetPos())
					local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng())
					return { RS = self:GetDrawScale() * 0.5, RatioX = 1, translucent = true }, pos, ang
				end
				self.RenderTable = t -- restore render table
				self:EGP_Update()
			end
		end)
	end
end

if CLIENT then
	function ENT:Initialize()
		if self:GetUseRT() then
			BaseClass.Initialize(self)
			self.GPU.GetInfo = function()
				local pos = self:LocalToWorld(self:GetDrawOffsetPos())
				local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng())
				return { RS = self:GetDrawScale() * 0.5, RatioX = 1, translucent = true }, pos, ang
			end
		else
			self.RenderTable = table.Copy(EGP.HomeScreen)
		end
	end

	function ENT:EGP_Update()
		if not self.GPU then
			self.NeedsUpdate = false
			local rt = self.RenderTable
			for _, obj in ipairs(rt) do
				if obj.parent == -1 or obj.NeedsConstantUpdate then self.NeedsUpdate = true end
				if obj.parent ~= 0 then
					if not obj.IsParented then EGP:SetParent(self, obj, obj.parent) end
					local _, data = EGP.GetGlobalPos(self, obj)
					obj:SetPos(data.x, data.y, data.angle)
				elseif obj.IsParented then
					EGP:UnParent(self, obj)
				end
			end
		else
			self.NeedsUpdate = true
		end
	end

	function ENT:DrawEntityOutline() end

	local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)
	local wire_egp_drawemitters = CreateClientConVar("wire_egp_drawemitters", "1")

 	function ENT:DrawNoRT()
		if wire_egp_drawemitters:GetBool() then
 			cam.Start3D2D(self:LocalToWorld(self:GetDrawOffsetPos() + DrawOffsetNoRT), self:LocalToWorldAngles(self:GetDrawOffsetAng()), self:GetDrawScale())
				local mat = self:GetEGPMatrix()
				for _, obj in ipairs(self.RenderTable) do
					local oldtex = EGP:SetMaterial(obj.material)
					local filter = obj.filtering
					if filter then
						render.PushFilterMag(filter)
						render.PushFilterMin(filter)
						obj:Draw(self, mat)
						render.PopFilterMag()
						render.PopFilterMin()
					else
						obj:Draw(self, mat)
					end
					EGP:FixMaterial(oldtex)
				end
			cam.End3D2D()
		end
	end

	-- cam.PushModelMatrix replaces the currently drawn matrix, because cam.Start3D2D
	-- pushes a matrix of its own we need to replicate it
	function ENT:GetEGPMatrix()
		if self.GPU ~= nil then
			local mat = Matrix()
	 		local pos = self:LocalToWorld(self:GetDrawOffsetPos() + DrawOffsetNoRT)
			mat:SetTranslation(pos)
	 		-- Just using the angle given to cam.Start3D2D doesn't seem to work, it seems to be rotated 180 on the roll
			local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng() + Angle(0, 0, 180))
			mat:SetAngles(ang)
	 		local scale = Vector(1, 1, 1)
			scale:Mul(self:GetDrawScale())
			mat:SetScale(scale)
	 		return mat
	 	else
	 		return BaseClass.GetEGPMatrix(self)
	 	end
	end

	function ENT:Draw()
		if self.GPU then -- if we're rendering on RT, use base EGP's draw function instead
			BaseClass.Draw(self)
		else
			self:DrawModel()
			self:DrawNoRT()
			Wire_Render(self)
		end
	end

	function ENT:GetTranslucent() return true end -- emitters are always transparent

	function ENT:Think()
		local dist = Vector(1,0,1)*wire_egp_emitter_drawdist:GetInt()
		self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
	end


	function ENT:OnRemove()
		if self.GPU then self.GPU:Finalize() end
	end
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
