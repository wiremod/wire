-- Collision tracking for E2
-- Author: DerelictDrone

E2Lib.RegisterExtension( "collision", false, "Lets E2 chips mark entities to receive information when they collide with something." )

registerType("collision", "xcd", nil,
	nil,
	nil,
	nil,
	function(v)
		return not istable(v) or not v.HitPos
	end
)

-- These are just the types we care about
-- Helps filter out physobjs cause that's not an e2 type
local typefilter = {
	entity = "e",
	vector = "v",
	number = "n",
}

local newE2Table = E2Lib.newE2Table

e2function table collision:toTable()
	local E2CD = newE2Table()
	for k,v in pairs(this) do
		local type = typefilter[string.lower(type(v))]
		if type then
			E2CD.s[k] = v
			E2CD.stypes[k] = type
		end
	end
	return E2CD
end

-- Getter functions below, sorted by return type

local function GetHitPos(self,collision)
	if not this then return self:throw("Invalid collision data!") end
	return collision.HitPos
end

-- * Vectors

e2function vector collision:hitpos()
	return GetHitPos(self,this)
end

e2function vector collision:pos()
	return GetHitPos(self,this)
end

e2function vector collision:position()
	return GetHitPos(self,this)
end

e2function vector collision:ouroldvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.OurOldVelocity
end

e2function vector collision:theiroldvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.TheirOldVelocity
end

e2function vector collision:hitnormal()
	if not this then return self:throw("Invalid collision data!") end
	return this.HitNormal
end

e2function vector collision:hitspeed()
	if not this then return self:throw("Invalid collision data!") end
	return this.HitSpeed
end

e2function vector collision:ournewvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.OurNewVelocity
end

e2function vector collision:theirnewvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.TheirNewVelocity
end

e2function vector collision:ouroldangularvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.OurOldAngularVelocity
end

e2function vector collision:theiroldangularvelocity()
	if not this then return self:throw("Invalid collision data!") end
	return this.TheirOldAngularVelocity
end

-- * Numbers

e2function number collision:speed()
	if not this then return self:throw("Invalid collision data!") end
	return this.Speed
end

e2function number collision:oursurfaceprops()
	if not this then return self:throw("Invalid collision data!") end
	return this.OurSurfaceProps
end

e2function number collision:theirsurfaceprops()
	if not this then return self:throw("Invalid collision data!") end
	return this.TheirSurfaceProps
end

e2function number collision:deltatime()
	if not this then return self:throw("Invalid collision data!") end
	return this.DeltaTime
end

-- * Entities

e2function entity collision:hitentity()
	if not this then return self:throw("Invalid collision data!") end
	return this.HitEntity
end


__e2setcost( 20 )

e2function number trackCollision( entity ent )
	if IsValid(ent) then
		local entIndex = ent:EntIndex()
		if self.E2TrackedCollisions[entIndex] then
			return 0 -- Already being tracked.
		end
		local chip = self.entity
		local callbackID = ent:AddCallback("PhysicsCollide",
		function( us, cd )
			chip:ExecuteEvent("entityCollision",{us,cd.HitEntity,cd})
		end)
		self.E2TrackedCollisions[entIndex] = callbackID -- This ID is needed to remove the physcollide callback
		ent:CallOnRemove("E2Chip_CCB" .. callbackID, function()
			self.E2TrackedCollisions[entIndex] = nil
		end)
		return 1
	end
	return 0
end

__e2setcost( 5 )

e2function number isTrackingCollision( entity ent )
	if IsValid(ent) and self.E2TrackedCollisions[ent:EntIndex()] then
		return 1
	else
		return 0
	end
end

e2function void stopTrackingCollision( entity ent )
	if IsValid(ent) then 
	local entIndex = ent:EntIndex()
		if self.E2TrackedCollisions[entIndex] then
			local callbackID = self.E2TrackedCollisions[entIndex]
			ent:RemoveCallOnRemove("E2Chip_CCB" .. callbackID)
			ent:RemoveCallback("PhysicsCollide", callbackID)
			self.E2TrackedCollisions[entIndex] = nil
		end
	end
end

registerCallback("construct", function( self )
	self.E2TrackedCollisions = {}
end)

registerCallback("destruct", function( self )
	for k,v in pairs(self.E2TrackedCollisions) do
		local ent = Entity(tonumber(k))
		if IsValid(ent) then
			ent:RemoveCallOnRemove("E2Chip_CCB" .. v)
			ent:RemoveCallback("PhysicsCollide", v)
		end
	end
end)

E2Lib.registerEvent("entityCollision", {
	{"Entity", "e"},
	{"HitEntity", "e"},
	{"CollisionData", "xcd"},
})
