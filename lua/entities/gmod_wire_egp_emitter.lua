AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire E2 Graphics Processor Emitter"
ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT
ENT.WireDebugName	= "E2 Graphics Processor Emitter"

if CLIENT then 
	ENT.gmod_wire_egp_emitter = true

	function ENT:Initialize()
		self.RenderTable = table.Copy(EGP.HomeScreen)
	end

	function ENT:EGP_Update()
		self.UpdateConstantly = nil
		for k,object in pairs(self.RenderTable) do
			if object.parent == -1 or object.Is3DTracker then self.UpdateConstantly = true end -- Check if an object is parented to the cursor (or for 3DTrackers)

			if object.parent and object.parent ~= 0 then
				if not object.IsParented then EGP:SetParent(self, object.index, object.parent) end
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
