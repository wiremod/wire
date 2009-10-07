ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Advanced Pod Controller"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


-- Output keys. Format: keys[index] = { "Output", IN_* }
ENT.keys = {
	{ "W", IN_FORWARD },
	{ "A", IN_MOVELEFT },
	{ "S", IN_BACK },
	{ "D", IN_MOVERIGHT },
	{ "Mouse1", IN_ATTACK },
	{ "Mouse2", IN_ATTACK2 },
	{ "R", IN_RELOAD },
	{ "Space", IN_JUMP },
	--{ "Duck", IN_DUCK }, -- Doesn't work with pods, apparently
	{ "Shift", IN_SPEED },
	{ "Zoom", IN_ZOOM },
	{ "Alt", IN_WALK },
	{ "TurnLeftKey", IN_LEFT },
	{ "TurnRightKey", IN_RIGHT },
}

-- Output client-side binds. Format: keys[index] = { "Output", "bind" }
ENT.bindlist = {
	{ "PrevWeapon", "invprev" },
	{ "NextWeapon", "invnext" },
	{ "Light", "impulse 100" },
}

-- prepare for lookup
for index,output,bind in ipairs_map(ENT.bindlist, unpack) do
	ENT.bindlist[bind] = output
end


function ENT:SetEffect(name)
	self.Entity:SetNetworkedString("Effect",name)
end

function ENT:GetEffect(name)
	return self.Entity:GetNetworkedString("Effect")
end


function ENT:SetOn(boolon)
	self.Entity:SetNetworkedBool("On",boolon,true)
end

function ENT:IsOn(name)
	return self.Entity:GetNetworkedBool("On")
end


function ENT:SetOffset(v)
	self.Entity:SetNetworkedVector("Offset",v,true)
end

function ENT:GetOffset(name)
	return self.Entity:GetNetworkedVector("Offset")
end
