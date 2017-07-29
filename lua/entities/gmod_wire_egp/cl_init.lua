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
		render.Clear( 0, 0, 0, 255 )
		--render.ClearRenderTarget( 0, 0, 0, 0 )

		local currentfilter = self.GPU.texture_filtering

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

			v:Draw(self)
			EGP:FixMaterial( oldtex )
		end
	end)
end

function ENT:DrawEntityOutline() end

function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)
	if self.UpdateConstantly or self.NeedsUpdate then
		self:_EGP_Update()
	end
	self.GPU:Render()
end

function ENT:OnRemove()
	self.GPU:Finalize()
end
