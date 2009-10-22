AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function SWEP:PrimaryAttack()
	if !self.Owner.Active then
		local tracedata = {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos()+(self.Owner:GetAimVector()*250),
		filter = self.Owner
		}
		local trace = util.TraceLine(tracedata)
		if trace.HitNonWorld and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
			if trace.Entity:Link(self.Owner,true) then
				self.Owner:PrintMessage(HUD_PRINTTALK,"You are now linked!")
				self.Owner.Linked = true
			else
				self.Owner:PrintMessage(HUD_PRINTTALK,"Link failed!")
			end
		end
	end
end
