include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_OPAQUE

--[[---------------------------------------------------------
   Overridden because I want to show the name of the
   player that spawned it.
---------------------------------------------------------]]
function ENT:GetOverlayText()
	return self:GetPlayerName()
end
