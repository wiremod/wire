include('shared.lua')

ENT.gmod_wire_egp_emitter = true

function ENT:Initialize()
	self.RenderTable = table.Copy(EGP.HomeScreen)
end

function ENT:EGP_Update()
	self.UpdateConstantly = nil
	for k,object in pairs(self.RenderTable) do
		if object.parent == -1 or object.Is3DTracker then self.UpdateConstantly = true end -- Check if an object is parented to the cursor (or for 3DTrackers)

		if object.parent and object.parent ~= 0 then
			if not object.IsParented then EGP:SetParent(self, object.index, object.parentindex) end
			local _, data = EGP:GetGlobalPos(self, object.index)
			EGP:EditObject(object, data)
		elseif not object.parent or object.parent == 0 and object.IsParented then
			EGP:UnParent(self, object.index)
		end

	end
end

function ENT:DrawEntityOutline() end

local wire_egp_emitter_drawdist = CreateClientConVar("wire_egp_emitter_drawdist","0",true,false)

function ENT:Think()
	local dist = Vector(1,0,1)*wire_egp_emitter_drawdist:GetInt()
	self:SetRenderBounds(Vector(-64,0,0)-dist,Vector(64,0,135)+dist)
end

local wire_egp_drawemitters = CreateClientConVar("wire_egp_drawemitters", "1")

function ENT:Draw()
	if (wire_egp_drawemitters:GetBool() == true and self.RenderTable and #self.RenderTable > 0) then
		if (self.UpdateConstantly) then self:EGP_Update() end

		local pos = self:LocalToWorld( Vector( -64, 0, 135 ) )
		local ang = self:LocalToWorldAngles( Angle(0,0,90) )

		cam.Start3D2D( pos , ang , 0.25 )
			for i=1,#self.RenderTable do
				local object = self.RenderTable[i]
				local oldtex = EGP:SetMaterial( object.material )

				object:Draw(self)
				EGP:FixMaterial( oldtex )
			end
		cam.End3D2D()
	end

	self:DrawModel()
	Wire_Render(self)
end
