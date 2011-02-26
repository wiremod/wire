include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

local cvar = CreateClientConVar("cl_wire_holoemitter_maxfadetime",5,true,false)

-- Materials
local matbeam = Material( "tripmine_laser" )
local matpoint = Material( "sprites/gmdm_pickups/light" )

function ENT:Initialize()
	self.Points = {}
	self.RBound = Vector(1024,1024,1024)
end

usermessage.Hook("hed",function( um )
	local ent = um:ReadEntity()
	if (!ent or !ent:IsValid()) then return end
	local n = um:ReadChar()

	local old = {}

	for i=1,n do
		local curpos = Vector( um:ReadFloat(), um:ReadFloat(), um:ReadFloat() )
		local IsDifferent = um:ReadBool()
		local t
		if (IsDifferent) then
			t = {
				Pos = curpos,
				Local = um:ReadBool(),
				Color = um:ReadVector(),
				DieTime = math.min(um:ReadShort()/100,cvar:GetFloat()),
				SpawnTime = CurTime(),
				LineBeam = um:ReadBool(),
				GroundBeam = um:ReadBool(),
				Size = um:ReadShort()/100,
			}
			t.Color = Color(t.Color.x,t.Color.y,t.Color.z,255)
		else
			t = old
			t.Pos = curpos
		end
		old = table.Copy(t)
		if (t.DieTime != 0) then
			t.DieTime = CurTime() + t.DieTime
			old.DieTime = t.DieTime
		else
			t.DieTime = nil
			old.DieTime = 0
		end

		ent.Points[#ent.Points+1] = t
	end
end)

function ENT:Think()
	self:NextThink( CurTime() )

	if (self:GetNWBool( "Clear", false ) == true) then
		self.Points = {}
		return true
	end

	local n = #self.Points

	if (n == 0) then return true end

	-- To make it visible across the entire map
	local p = LocalPlayer():GetPos()
	self:SetRenderBoundsWS( p - self.RBound, p + self.RBound )

	local removetable = {}
	for k,v in ipairs( self.Points ) do
		if (v.DieTime and v.DieTime < CurTime()) then
			removetable[#removetable+1] = k
			if (self.Points[k-1]) then self.Points[k-1].LineBeam = false end -- Don't draw to this point anymore
		elseif (cvar:GetFloat() != 0) then -- If the client changes the max fade time later on
			if (v.SpawnTime + cvar:GetFloat() < CurTime()) then
				removetable[#removetable+1] = k
				if (self.Points[k-1]) then self.Points[k-1].LineBeam = false end -- Don't draw to this point anymore
			end
		end
	end
	for k,v in ipairs( removetable ) do
		table.remove( self.Points, v )
	end

	return true
end

function ENT:Draw()
	self:DrawModel()

	local ent = self:GetNWEntity( "Link" )
	if (!ent or !ValidEntity(ent)) then ent = self end
	local selfpos = ent:GetPos()

	local n = #self.Points

	if (n == 0 or self:GetNWBool("Active",true) == false) then return end

	for k=1, n do
		local v = self.Points[k]
		local Pos = v.Pos

		if (v.Local) then
			Pos = ent:LocalToWorld( Pos )
		end

		if (v.GroundBeam) then
			render.SetMaterial( matbeam )
			render.DrawBeam(
				selfpos,
				Pos,
				v.Size,
				0,1,
				v.Color
			)
		end

		if (v.LineBeam and k < n) then
			render.SetMaterial( matbeam )

			local NextPoint = self.Points[k+1]
			local NextPos = NextPoint.Pos
			if (NextPoint.Local) then
				NextPos = ent:LocalToWorld( NextPos )
			end

			render.DrawBeam(
				NextPos,
				Pos,
				v.Size * 2,
				0, 1,
				v.Color
			)
		end

		render.SetMaterial( matpoint )
		render.DrawSprite(
			Pos,
			v.Size, v.Size,
			v.Color
		)
	end
end
