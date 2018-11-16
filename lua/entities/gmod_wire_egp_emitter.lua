AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
--ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT
ENT.WireDebugName	= "E2 Graphics Processor Emitter"
ENT.RenderGroup    = RENDERGROUP_BOTH

if CLIENT then
	ENT.gmod_wire_egp_emitter = true

	ENT.DrawOffsetPos = Vector(-64, 0, 135)
	ENT.DrawOffsetAng = Angle(0, 0, 90)
	ENT.DrawScale     = 0.25

	function ENT:Initialize()
		self.GPU = GPULib.WireGPU( self )
		self.GPU:SetTranslucentOverride(true)
		self:EGP_Update( EGP.HomeScreen )
	end

	function ENT:EGP_Update( Table )
		self.NeedsUpdate = true
		self.NextUpdate = Table
	end

	function ENT:_EGP_Update( bool )
		self.NeedsUpdate = nil
		local Table = self.NextUpdate or self.RenderTable

		if not Table then return end
		self.UpdateConstantly = nil

		self.GPU:RenderToGPU( function()
			render.Clear( 0, 0, 0, 0 )
			--render.ClearRenderTarget( 0, 0, 0, 0 )

			local currentfilter = self.GPU.texture_filtering

			local mat = self:GetEGPMatrix()

			for k,v in pairs( Table ) do
				if (v.parent == -1) then self.UpdateConstantly = true end -- Check if an object is parented to the cursor
				if (v.parent and v.parent != 0) then
					if (!v.IsParented) then EGP:SetParent( self, v.index, v.parent ) end
					local _, data = EGP:GetGlobalPos( self, v.index )
					EGP:EditObject( v, data )
				elseif ((!v.parent or v.parent == 0) and v.IsParented) then
					EGP:UnParent( self, v.index )
				end
				local oldtex = EGP:SetMaterial( v.material )

				if v.filtering != currentfilter then
					render.PopFilterMin()
					render.PopFilterMag()
					render.PushFilterMag(v.filtering)
					render.PushFilterMin(v.filtering)
					currentfilter = v.filtering
				end

				v:Draw(self, mat)
				EGP:FixMaterial( oldtex )
			end
		end)
	end

	function ENT:DrawEntityOutline() end

	local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)

	function ENT:Think()
		local dist = Vector(1,0,1)*wire_egp_emitter_drawdist:GetInt()
		self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
	end

	local wire_egp_drawemitters = CreateClientConVar("wire_egp_drawemitters", "1")

	function ENT:Draw()
		if wire_egp_drawemitters:GetBool() == true then
			if self.UpdateConstantly or self.NeedsUpdate then
				self:_EGP_Update()
			end

			local pos = self:LocalToWorld(self.DrawOffsetPos)
			local ang = self:LocalToWorldAngles(self.DrawOffsetAng)

			local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
			WireGPU_matScreen:SetTexture("$basetexture", self.GPU.RT)

			cam.Start3D2D(pos, ang, self.DrawScale)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(WireGPU_matScreen)
				surface.DrawTexturedRect(0, 0, 512, 512)
			cam.End3D2D()

			WireGPU_matScreen:SetTexture("$basetexture", OldTex)
		end

		self:DrawModel()

		Wire_Render(self)
	end

	-- cam.PushModelMatrix replaces the currently drawn matrix, because cam.Start3D2D
	-- pushes a matrix of its own we need to replicate it
	function ENT:GetEGPMatrix()
		local mat = Matrix()

		local pos = self:LocalToWorld(self.DrawOffsetPos)
		mat:SetTranslation(pos)

		-- Just using the angle given to cam.Start3D2D doesn't seem to work, it seems to be rotated 180 on the roll
		local ang = self:LocalToWorldAngles(self.DrawOffsetAng + Angle(0, 0, 180))
		mat:SetAngles(ang)

		local scale = Vector(1, 1, 1)
		scale:Mul(self.DrawScale)
		mat:SetScale(scale)

		return mat
	end

	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	--self:DrawShadow( false )

	self.RenderTable = {}

	self:SetUseType(SIMPLE_USE)

	WireLib.CreateWirelinkOutput( nil, self, {true} )

	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false

	self.TopLeft = false
end

function ENT:SetEGPOwner( ply )
	self.ply = ply
	self.plyID = ply:UniqueID()
end

function ENT:GetEGPOwner()
	if (!self.ply or !self.ply:IsValid()) then
		local ply = player.GetByUniqueID( self.plyID )
		if (ply) then self.ply = ply end
		return ply
	else
		return self.ply
	end
	return false
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
