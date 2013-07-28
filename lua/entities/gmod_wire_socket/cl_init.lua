
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

function ENT:DrawEntityOutline()
	if (GetConVar("wire_plug_drawoutline"):GetBool()) then
		self.BaseClass.DrawEntityOutline( self )
	end
end

hook.Add("HUDPaint","Wire_Socket_DrawLinkHelperLine",function()
	local sockets = ents.FindByClass("gmod_wire_socket")
	for k,self in pairs( sockets ) do
		local Pos, _ = self:GetLinkPos()

		local Closest = self:GetClosestPlug()

		if (Closest and Closest:IsValid() and self:CanLink( Closest ) and Closest:GetNWBool( "PlayerHolding", false ) and Closest:GetClosestSocket() == self) then
			local plugpos = Closest:GetPos():ToScreen()
			local socketpos = Pos:ToScreen()
			surface.SetDrawColor( 255,255,100,255 )
			surface.DrawLine( plugpos.x, plugpos.y, socketpos.x, socketpos.y )
		end
	end
end)
