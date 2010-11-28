
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

function ENT:DrawEntityOutline()
	if (GetConVar("wire_plug_drawoutline"):GetBool()) then
		self.BaseClass.DrawEntityOutline( self )
	end
end
