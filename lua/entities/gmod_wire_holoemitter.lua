AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Holographic Emitter"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Holographic Emitter"

if CLIENT then
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
		if not IsValid(ent) or not ent.AddPoint then return end
		local syncinterval = net.ReadFloat()
		local count = net.ReadUInt(16)
		for i=1, count do
			local pos = net.ReadVector()
			local lcl = net.ReadBit() ~= 0
			local color = Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8))
			local dietime = net.ReadUInt(16)/100
			local linebeam = net.ReadBit() ~= 0
			local groundbeam = net.ReadBit() ~= 0
			local size = net.ReadUInt(16)/100
			timer.Simple(i/count*syncinterval,function()
				if IsValid(ent) then
					ent:AddPoint(pos, lcl, color, dietime, linebeam, groundbeam, size)
				end
			end)
		end
	end)

	function ENT:Think()
		self:NextThink( CurTime() )

		if (self:GetNWBool( "Clear", false ) == true) then
			self.Points = {}
			return true
		end

		if not next(self.Points) then return true end

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
		BaseClass.Draw(self)

		local ent = self:GetNWEntity( "Link", false )
		if not IsValid(ent) then ent = self end

		local forcelocal = false
		if ent:GetClass() == "gmod_wire_hologrid" then
			local temp = ent:GetNWEntity( "reference", false )
			if IsValid(temp) then
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

	return  -- No more client
end

-- Server

local cvar = CreateConVar("wire_holoemitter_interval",0.3,{FCVAR_ARCHIVE,FCVAR_NOTIFY})

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow( false )
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

	self:SetNWBool( "Clear", false )
	self:SetNWBool( "Active", true )

	self.bools = {}
	self.bools.Local = true
	self.bools.LineBeam = true
	self.bools.GroundBeam = true

	self.Inputs = WireLib.CreateInputs( self, {
		"Pos (The position of the point. Changing this value causes a new point to be added.) [VECTOR]",
		"X (The X position of the point. Changing this value causes a new point to be added.\nIt's recommended to use the vector input, since that allows you to change all three coordinate values at once without creating a new point.)" ,
		"Y (The Y position of the point. Changing this value causes a new point to be added.\nIt's recommended to use the vector input, since that allows you to change all three coordinate values at once without creating a new point.)",
		"Z (The Z position of the point. Changing this value causes a new point to be added.\nIt's recommended to use the vector input, since that allows you to change all three coordinate values at once without creating a new point.)",
		"Local (If 1, position will be relative to the emitter.)",
		"Color [VECTOR]",
		"FadeTime (The time it takes for the point to fade away, in seconds.)",
		"LineBeam (If 1, draws a beam between the last point and the next.)",
		"GroundBeam (If 1, draws a beam between the emitter and the next point.)",
		"Size (The size of the point.)",
		"Clear (Removes all points.)",
		"Active"
	})
	self.Outputs = WireLib.CreateOutputs( self, { "Memory (Allows zGPU/zCPU to communicate with this device. Serves no other purpose.)" } ) -- Compatibility for older hispeed devices (such as gpu/cpu)

	self.Points = {}

	self.Data = {}
	self.Data.Pos = Vector(0,0,0)
	self.Data.Local = false
	self.Data.Color = Vector(255,255,255)
	self.Data.FadeTime = 1
	self.Data.LineBeam = false
	self.Data.GroundBeam = false
	self.Data.Size = 1

	self:SetOverlayText( "Holo Emitter" )
end

function ENT:AddPoint()
	self.Points[#self.Points+1] = {
		Pos = Vector(self.Data.Pos.x,self.Data.Pos.y,self.Data.Pos.z),
		Local = self.Data.Local,
		Color = Vector(self.Data.Color.x,self.Data.Color.y,self.Data.Color.z),
		FadeTime = self.Data.FadeTime,
		LineBeam = self.Data.LineBeam,
		GroundBeam = self.Data.GroundBeam,
		Size = self.Data.Size,
	}
end

function ENT:TriggerInput( name, value )
	if (name == "X") then -- X
		if (self.Data.Pos.x ~= value) then
			self.Data.Pos.x = value
			self:AddPoint()
		end
	elseif (name == "Y") then -- Y
		if (self.Data.Pos.y ~= value) then
			self.Data.Pos.y = value
			self:AddPoint()
		end
	elseif (name == "Z") then -- Z
		if (self.Data.Pos.z ~= value) then
			self.Data.Pos.z = value
			self:AddPoint()
		end
	elseif (name == "Pos") then -- XYZ
		if (self.Data.Pos ~= value) then
			self.Data.Pos = value
			self:AddPoint()
		end
	else
		-- Clear & Active
		if (name == "Clear" or name == "Active") then
			self:SetNWBool(name,value ~= 0)
		else
			-- Other data
			if (self.bools[name]) then value = value ~= 0 end
			self.Data[name] = value
		end
	end
end

-- Hispeed info
-- 0 = Draw (when changed, draws point) (if used in readcell, returns whether or not you are allowed to draw any more this interval)
-- 1 = X
-- 2 = Y
-- 3 = Z
-- 4 = Local (1/0)
-- 5 = R
-- 6 = G
-- 7 = B
-- 8 = FadeTime
-- 9 = LineBeam
-- 10 = GroundBeam
-- 11 = Size
-- 12 = Clear (removes all dots when = 1)
-- 13 = Active

function ENT:ReadCell( Address )
	Address = math.floor(Address)
	if (Address == 0) then
		return 1
	elseif (Address == 1) then
		return self.Data.Pos.x
	elseif (Address == 2) then
		return self.Data.Pos.y
	elseif (Address == 3) then
		return self.Data.Pos.z
	elseif (Address == 4) then
		return self.Data.Local and 1 or 0
	elseif (Address == 5) then
		return self.Data.Color.x
	elseif (Address == 6) then
		return self.Data.Color.y
	elseif (Address == 7) then
		return self.Data.Color.z
	elseif (Address == 8) then
		return self.Data.FadeTime
	elseif (Address == 9) then
		return self.Data.LineBeam and 1 or 0
	elseif (Address == 10) then
		return self.Data.GroundBeam and 1 or 0
	elseif (Address == 11) then
		return self.Data.Size
	elseif (Address == 12) then
		return self:GetNWBool("Clear",false) and 1 or 0
	elseif (Address == 13) then
		return self:GetNWBool("Active",true) and 1 or 0
	end
end

function ENT:WriteCell( Address, value )
	Address = math.floor(Address)
	if (Address == 0) then
		self:AddPoint()
		return true
	elseif (Address == 1) then
		self.Data.Pos.x = value
		return true
	elseif (Address == 2) then
		self.Data.Pos.y = value
		return true
	elseif (Address == 3) then
		self.Data.Pos.z = value
		return true
	elseif (Address == 4) then
		self.Data.Local = value ~= 0
		return true
	elseif (Address == 5) then
		self.Data.Color.x = value
		return true
	elseif (Address == 6) then
		self.Data.Color.y = value
		return true
	elseif (Address == 7) then
		self.Data.Color.z = value
		return true
	elseif (Address == 8) then
		self.Data.FadeTime = value
		return true
	elseif (Address == 9) then
		self.Data.LineBeam = value ~= 0
		return true
	elseif (Address == 10) then
		self.Data.GroundBeam = value ~= 0
		return true
	elseif (Address == 11) then
		self.Data.Size = value
		return true
	elseif (Address == 12) then
		self:SetNWBool( "Clear", value ~= 0 )
		return true
	elseif (Address == 13) then
		self:SetNWBool( "Active", value ~= 0 )
		return true
	end
	return false
end

function ENT:Link( ent )
	if IsValid(ent) and ent:GetClass() == "gmod_wire_hologrid" then -- Remove "Local" input if linking to a hologrid
		WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
	else
		local old = self:GetNWEntity( "Link" )
		if IsValid(old) and old:GetClass() == "gmod_wire_hologrid" then -- Put the "Local" input back
			WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
		end
	end

	self:SetNWEntity( "Link", ent )
end

function ENT:UnLink()
	local old = self:GetNWEntity( "Link" )
	if IsValid(old) and old:GetClass() == "gmod_wire_hologrid" then -- Put the "Local" input back
		WireLib.AdjustInputs( self, { "Pos [VECTOR]", "X" , "Y", "Z", "Local", "Color [VECTOR]", "FadeTime", "LineBeam", "GroundBeam", "Size", "Clear", "Active" } )
	end

	self:SetNWEntity( "Link", NULL )
end

util.AddNetworkString("WireHoloEmitterData")
function ENT:Think()
	self:NextThink( CurTime() + cvar:GetFloat() )
	if not next(self.Points) then return true end
	net.Start("WireHoloEmitterData")
		net.WriteEntity(self)
		net.WriteFloat(cvar:GetFloat()) -- send sync interval
		net.WriteUInt(#self.Points, 16) -- send nr of points
		for _,v in pairs( self.Points ) do -- send each point
			net.WriteVector(v.Pos)
			net.WriteBit(v.Local)
			net.WriteUInt(v.Color.x,8)
			net.WriteUInt(v.Color.y,8)
			net.WriteUInt(v.Color.z,8)
			net.WriteUInt(math.Clamp(v.FadeTime,0,100)*100,16)
			net.WriteBit(v.LineBeam)
			net.WriteBit(v.GroundBeam)
			net.WriteUInt(math.Clamp(v.Size,0,100)*100, 16)
		end
	net.Broadcast()

	self.Points = {}
	return true
end

duplicator.RegisterEntityClass("gmod_wire_holoemitter", WireLib.MakeWireEnt, "Data")

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	local link = self:GetNWEntity("Link",false)
	if (link) then
		info.holoemitter_link = link:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:Link(GetEntByID(info.holoemitter_link))
end
