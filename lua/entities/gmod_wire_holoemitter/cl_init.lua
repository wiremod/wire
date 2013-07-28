include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

local cvar = CreateClientConVar("cl_wire_holoemitter_maxfadetime",5,true,false) -- "cl_" in the cvar name isn't very neat... probably too late to change it now, though.
local keeplatest = CreateClientConVar("wire_holoemitter_keeplatestdot", "0", true, false)

-- Materials
local matbeam = Material( "tripmine_laser" )
local matpoint = Material( "sprites/gmdm_pickups/light" )

function ENT:Initialize()
	self.Points = {}
	self.RBound = Vector(1024,1024,1024)
end

function ENT:AddPoint( Pos, Local, Color, DieTime, LineBeam, GroundBeam, Size )
	if Local ~= nil and Color ~= nil and DieTime ~= nil and LineBeam ~= nil and GroundBeam ~= nil and Size ~= nil then

		local point = {}
		point.Pos = Pos
		point.Local = Local
		point.Color = Color
		point.LineBeam = LineBeam
		point.GroundBeam = GroundBeam
		point.Size = Size

		if DieTime ~= 0 then
			point.DieTime = CurTime() + DieTime
		end

		point.SpawnTime = CurTime()
		self.Points[#self.Points+1] = point
	end
end

net.Receive("WireHoloEmitterData", function(netlen)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	for i=1, net.ReadUInt(16) do
		local pos = net.ReadVector()
		ent:AddPoint(pos, net.ReadBit() ~= 0, Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8)), net.ReadUInt(16)/100, net.ReadBit() ~= 0, net.ReadBit() ~= 0, net.ReadUInt(16)/100)
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

	local cvarnum = cvar:GetFloat()

	for k=#self.Points,1,-1 do
		local v = self.Points[k]

		if k == #self.Points and keeplatest:GetBool() then continue end -- Check keep latest convar

		if v.DieTime then
			v.Color.a = 255-(CurTime()-v.SpawnTime)/(v.DieTime-v.SpawnTime)*255 -- Set alpha

			if v.DieTime < CurTime() then -- If the point's time has passed, remove it
				table.remove( self.Points, k )

				if self.Points[k-1] then self.Points[k-1].LineBeam = false end -- Don't draw a line to this point anymore
			end
		end

		if cvarnum ~= 0 and v.SpawnTime + cvarnum < CurTime() then -- If the clientside time limit is shorter than the DieTime
			table.remove( self.Points, k )

			if self.Points[k-1] then self.Points[k-1].LineBeam = false end -- Don't draw a line to this point anymore
		end
	end

	return true
end

function ENT:Draw()
	self.BaseClass.Draw(self)

	local ent = self:GetNWEntity( "Link", false )
	if (!ent or !IsValid(ent)) then ent = self end

	local forcelocal = false
	if ent:GetClass() == "gmod_wire_hologrid" then
		local temp = ent:GetNWEntity( "reference", false )
		if temp and temp:IsValid() then
			ent = temp
			forcelocal = true
		end
	end

	local selfpos = ent:GetPos()

	local n = #self.Points

	if (n == 0 or self:GetNWBool("Active",true) == false) then return end

	for k=1, n do
		local v = self.Points[k]
		local Pos = v.Pos

		if (v.Local or forcelocal) then
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
			if (NextPoint.Local or forcelocal) then
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
