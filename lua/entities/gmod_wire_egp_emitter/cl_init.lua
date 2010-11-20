include('shared.lua')
include('shared.lua')

function ENT:Initialize()
	self.RenderTable = table.Copy(EGP.HomeScreen)
end

function ENT:EGP_Update()
	self.UpdateConstantly = nil
	for k,v in pairs( self.RenderTable ) do
		if (v.parent == -1) then self.UpdateConstantly = true end -- Check if an object is parented to the cursor
		if (v.parent and v.parent != 0) then
			if (!v.IsParented) then EGP:SetParent( self, v.index, v.parentindex ) end
			local _, data = EGP:GetGlobalPos( self, v.index )
			EGP:EditObject( v, data )
		elseif (!v.parent or v.parent == 0 and v.IsParented) then
			EGP:UnParent( self, v.index )
		end
	end
end

function ENT:DrawEntityOutline() end

function ENT:Think() self:SetRenderBounds(Vector(-64,0,0),Vector(64,0,135)) end

local cvar = CreateClientConVar("wire_egp_drawemitters","1")

function ENT:Draw()
	if (cvar:GetBool() == true and self.RenderTable and #self.RenderTable > 0) then
		if (self.UpdateConstantly) then self:EGP_Update() end

		local pos = self:LocalToWorld( Vector( -64, 0, 135 ) )
		local ang = self:LocalToWorldAngles( Angle(0,0,90) )

		cam.Start3D2D( pos , ang , 0.25 )
			for i=1,#self.RenderTable do
				local v = self.RenderTable[i]
				local oldtex = EGP:SetMaterial( v.material )
				v:Draw()
				EGP:FixMaterial( oldtex )
			end
		cam.End3D2D()
	end

	self:DrawModel()
	Wire_Render(self)
end
