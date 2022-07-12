AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_egp" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

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
end

if CLIENT then
	function ENT:Initialize()
		BaseClass.Initialize(self)
		self.GPU.GetInfo = function()
			local pos = self:LocalToWorld(self:GetDrawOffsetPos())
			local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng())
			return {RS = self:GetDrawScale(), RatioX = 1, translucent = true}, pos, ang
		end
	end

	function ENT:DrawEntityOutline() end

	local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)
	local wire_egp_drawemitters = CreateClientConVar("wire_egp_drawemitters", "1")

	function ENT:EGP_Update( Table )
		self.NeedsUpdate = true
		self.NextUpdate = Table

		-- the parent checks need to be processed here if we aren't using a GPU
		self.UpdateConstantly = nil
		if self.GPU == nil then
			for _,object in pairs(self.RenderTable) do
				if object.parent == -1 or object.NeedsConstantUpdate then self.UpdateConstantly = true end -- Check if an object is parented to the cursor (or for 3DTrackers)
	 			if object.parent and object.parent ~= 0 then
					if not object.IsParented then EGP:SetParent(self, object.index, object.parent) end
					local _, data = EGP:GetGlobalPos(self, object.index)
					EGP:EditObject(object, data)
				elseif not object.parent or object.parent == 0 and object.IsParented then
					EGP:UnParent(self, object.index)
				end
			end
		end
	end

 	function ENT:DrawNoRT()
		if (wire_egp_drawemitters:GetBool() == true and self.RenderTable and #self.RenderTable > 0) then
			if (self.UpdateConstantly) then self:EGP_Update() end
 			local pos = self:LocalToWorld(self:GetDrawOffsetPos() + DrawOffsetNoRT)
			local ang = self:LocalToWorldAngles(self:GetDrawOffsetAng())
 			local mat = self:GetEGPMatrix()
 			cam.Start3D2D(pos, ang, self:GetDrawScale())
				local globalfilter = TEXFILTER.ANISOTROPIC -- Emitter uses ANISOTRPOIC (unchangeable)
				for i=1,#self.RenderTable do
					local object = self.RenderTable[i]
					local oldtex = EGP:SetMaterial( object.material )
 					if object.filtering ~= globalfilter then
						render.PushFilterMag(object.filtering)
						render.PushFilterMin(object.filtering)
						object:Draw(self, mat)
						render.PopFilterMin()
						render.PopFilterMag()
					else
						object:Draw(self, mat)
					end
 					EGP:FixMaterial( oldtex )
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
		-- check if the RT should be removed or recreated
		local hasGPU = (self.GPU~=nil)
		if self:GetUseRT() == false and hasGPU then
			self.GPU:FreeRT() -- remove gpu RT
			self.GPU = nil
			if not self.RenderTable or #self.RenderTable == 0 then -- if the screen is empty
				self.RenderTable = table.Copy(EGP.HomeScreen) -- copy home screen
			end
			self:EGP_Update()
		elseif self:GetUseRT() == true and not hasGPU then
			local t = self.RenderTable -- save reference
			self:Initialize() -- recreate gpu RT
			self.RenderTable = t -- restore render table
			self:EGP_Update()
		end

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