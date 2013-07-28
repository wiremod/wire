ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Light"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:SetGlow(val)
	self:SetNetworkedBool("LightGlow",val)
end

function ENT:GetGlow()
	return self:GetNetworkedBool("LightGlow")
end

local nwvars = {
	Brightness = 1,
	Decay = 500,
	Size = 100,
}

for varname,default in pairs(nwvars) do
	ENT["Set"..varname] = function(self, val)
		self:SetNetworkedFloat("Light"..varname,val)
	end

	ENT["Get"..varname] = function(self)
		return self:GetNetworkedFloat("Light"..varname, default)
	end
end
