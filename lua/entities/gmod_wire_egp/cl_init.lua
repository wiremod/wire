include('shared.lua')

ENT.gmod_wire_egp = true

function ENT:Initialize()
	self.GPU = GPULib.WireGPU( self )
	self.GPU.texture_filtering = TEXFILTER.ANISOTROPIC

	self.RenderTable = {}
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
		render.Clear( 0, 0, 0, 0, true )
		--render.ClearRenderTarget( 0, 0, 0, 0 )

		local currentfilter = self.GPU.texture_filtering
		local pushedFilter = false

		local mat = self:GetEGPMatrix()

		for k,v in pairs( Table ) do
			if (v.parent == -1) then self.UpdateConstantly = true end -- Check if an object is parented to the cursor
			if (v.parent and v.parent ~= 0) then
				if (not v.IsParented) then EGP:SetParent( self, v.index, v.parent ) end
				local _, data = EGP:GetGlobalPos( self, v.index )
				EGP:EditObject( v, data )
			elseif ((not v.parent or v.parent == 0) and v.IsParented) then
				EGP:UnParent( self, v.index )
			end
			local oldtex = EGP:SetMaterial( v.material )

			if v.filtering ~= currentfilter then
				if pushedFilter then
					render.PopFilterMin()
					render.PopFilterMag()
				end
				render.PushFilterMag(v.filtering)
				render.PushFilterMin(v.filtering)
				currentfilter = v.filtering
				pushedFilter = true
			end

			v:Draw(self, mat)
			EGP:FixMaterial( oldtex )
		end

		if pushedFilter then
			render.PopFilterMin()
			render.PopFilterMag()
		end
	end)
end

function ENT:GetEGPMatrix()
	return Matrix()
end

function ENT:DrawEntityOutline() end

local VECTOR_1_1_1 = Vector(1, 1, 1)
function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)

	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(VECTOR_1_1_1)
	if self.UpdateConstantly or self.NeedsUpdate then
		self:_EGP_Update()
	end

	-- check if translucent setting changed
	if self.GPU.translucent ~= self:GetTranslucent() then
		self.GPU.translucent = self:GetTranslucent()
		self:_EGP_Update()
	end

	self.GPU:Render(0,0,1024,1024,nil,-0.5,-0.5)
	render.SetToneMappingScaleLinear(tone)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end
