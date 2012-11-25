AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Winch Controller"
ENT.WireDebugName 	= "Winch"
ENT.RenderGroup		= RENDERGROUP_BOTH

if CLIENT then return end -- No more client

DIR_BACKWARD 	= -1
DIR_NONE 		= 0
DIR_FORWARD 	= 1

TYPE_NORMAL	= 0
TYPE_MUSCLE	= 1

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "In", "Out", "Length" } )
	self.Outputs = Wire_CreateOutputs(self, { "Length" })
	self.Trigger = 0

	self.last_time = CurTime()
	self.init_time = CurTime()
	self.min_length = self.min_length or 1
	self.type = self.type or TYPE_NORMAL
	self.ctime = self.ctime or 0
end


function ENT:Setup()
	self.current_length = 0
	self.IsOn = true
end

/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
---------------------------------------------------------*/
function ENT:KeyValue( key, value )
	if (key == "minlength") then		self.min_length = tonumber(value)
	elseif (key == "maxlength") then	self.max_length = tonumber(value)
	elseif (key == "type") then			self.type = tonumber(value)
	end
end

/*---------------------------------------------------------
   Name: Think
   Desc: Entity's think function.
---------------------------------------------------------*/
function ENT:Think()

	self:NextThink( CurTime() + 0.01 )
	local TimeDiff = CurTime() - self.last_time
	self.last_time = CurTime()

	if (!self.constraint) then return end
	if (!self.direction) then return end
	if (self.direction == DIR_NONE) then return end

	local old_length = self.current_length
	local current_length = self.current_length

	if (self.type == TYPE_NORMAL) then

		local speed = 0
		local dist = 0

		if (self.direction == DIR_FORWARD) then
			local speed = self.constraint:GetTable().fwd_speed
			dist = speed * TimeDiff
		elseif (self.direction == DIR_BACKWARD) then
			local speed = self.constraint:GetTable().bwd_speed
			dist = -speed * TimeDiff
		end

		if (dist == 0) then return end

		current_length = current_length + dist

		if ( self.min_length && current_length < self.min_length ) then

			current_length = self.min_length
			if (self.toggle) then self.direction = DIR_NONE end

		end

		if (self.max_length) then

			if (current_length > self.max_length) then

				current_length = self.max_length
				self.isexpanded = true
				if (self.toggle) then self.direction = DIR_NONE	end

			else

				self.isexpanded = false

			end

		end

	elseif ( self.type == TYPE_MUSCLE ) then

		local amp = self.constraint:GetTable().amplitude
		local per = self.constraint:GetTable().period

		local spos = ( math.sin( (self.ctime * math.pi * per )) + 1 ) * (amp / 2)

		if (spos > amp) then spos = amp end
		if (spos < 0) then spos = 0 end

		current_length = self.min_length + spos

		self.ctime = self.ctime + TimeDiff
	end

	self.current_length = current_length

	self.constraint:Fire("SetSpringLength", current_length, 0)
	if (self.rope) then	self.rope:Fire("SetLength", current_length, 0)	end

	self:SetOverlayText( "Winch length : " .. current_length )
	Wire_TriggerOutput(self, "Length", current_length)

end


function ENT:GetWPos( ent, phys, lpos )
	if (ent:EntIndex() == 0) then
		return lpos
	end

	if (phys) and (phys:IsValid()) then
		return phys:LocalToWorld( lpos )
	else
		return ent:LocalToWorld( lpos )
	end
end


function ENT:SetConstraint( c )
	self.constraint = c
	self.direction = DIR_NONE
	self.toggle = c:GetTable().toggle

	local p1 = self:GetWPos(c:GetTable().Ent1, c:GetTable().Phys1, c:GetTable().LPos1)
	local p2 = self:GetWPos(c:GetTable().Ent2, c:GetTable().Phys2, c:GetTable().LPos2)
	local dist = (p1 - p2)

	self.current_length = dist:Length()

	if (self.max_length) then
		self.isexpanded = (self.current_length >= self.max_length)
	end

	if (self.type == TYPE_MUSCLE) then
		local amp = self.constraint:GetTable().amplitude
		local per = self.constraint:GetTable().period
		local spos = self.current_length - self.min_length
		spos = spos / (amp*2)
		spos = spos - 1
		spos = math.Clamp(spos, -1, 1) // just in case!
		spos = math.asin(spos)
		spos = spos / (per * math.pi)
		self.ctime = spos
	end

	self:ShowOutput( dist:Length() )
	self.constraint:Fire("SetSpringLength", self.current_length, 0)
	if self.rope then self.rope:Fire("SetLength", self.current_length, 0) end

	self:SetOverlayText( "Winch length : " .. self.current_length )
	Wire_TriggerOutput(self, "Length", self.current_length)

end


function ENT:SetRope( r )
	self.rope = r
end


function ENT:TriggerInput(iname, value)
	if (iname == "In") then
		if (value > 0) then
			self.direction = -1
		elseif (value < 0) then
			self.direction = 1
		else
			self.direction = 0
		end
	elseif (iname == "Out") then
		if (value > 0) then
			self.direction = 1
		elseif (value < 0) then
			self.direction = -1
		else
			self.direction = 0
		end
	elseif (iname == "Length") then
		self:ShowOutput( math.max(1, value) )
	end
end


function ENT:ShowOutput( Length )
	if ( Length ~= self.current_length and self.constraint ) then
		self:SetOverlayText( "Winch length : " .. Length )
		Wire_TriggerOutput(self, "Length", Length)
		self.current_length = Length
		self.constraint:Fire("SetSpringLength", self.current_length, 0)
		if self.rope then self.rope:Fire("SetLength", self.current_length, 0) end
	end
end


/*function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.constraint) and (self.constraint:IsValid()) then
		info.constraint = self.constraint:EntIndex()
	end
	if (self.rope) and (self.rope:IsValid()) then
		info.rope = self.rope:EntIndex()
	end

	return info
end*/

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)

	if (GetConstByID) then
		if (info.constraint) and (info.constraint > 0) then
		    local const = GetConstByID(info.constraint)
			if (const) then
				self:SetConstraint(const)
			end
		end

		if (info.rope) and (info.rope > 0) then
		    local rope = GetConstByTable(info.rope)
			if (rope) then
				self:SetConstraint(rope)
			end
		end
	end
end

function ENT:SetDirection( n )
	self.direction = n
end

function ENT:GetDirection()
	return self.direction
end

function ENT:IsExpanded()
	return self.isexpanded
end
