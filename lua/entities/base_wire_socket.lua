AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )


local PositionOffsets = {
	["models/wingf0x/isasocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Vector(0,0,2.6),
	["models/wingf0x/ethernetsocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Vector(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Vector(5, 13, 10),
	["models/bull/various/usb_socket.mdl"] = Vector(8,0,0),
	["models/hammy/pci_slot.mdl"] = Vector(0,0,0),
	["models//hammy/pci_slot.mdl"] = Vector(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local AngleOffsets = {
	["models/wingf0x/isasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/ethernetsocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Angle(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_socket.mdl"] = Angle(0,0,0),
	["models/hammy/pci_slot.mdl"] = Angle(0,0,0),
	["models//hammy/pci_slot.mdl"] = Angle(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local SocketModels = {
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl",
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models//hammy/pci_slot.mdl"] = "models//hammy/pci_card.mdl", -- For some reason, GetModel on this model has two / on the client... Bug?
}

--Time after loosing one plug to search for another
local NEW_PLUG_WAIT_TIME = 2


function ENT:GetLinkPos()
	return self:LocalToWorld(PositionOffsets[self:GetModel()] or Vector(0,0,0)), self:LocalToWorldAngles(AngleOffsets[self:GetModel()] or Angle(0,0,0))
end

function ENT:CanLink( Target )
	if (Target.Socket and Target.Socket:IsValid()) then return false end
	if (SocketModels[self:GetModel()] ~= Target:GetModel()) then return false end
	return true
end

function ENT:GetClosestPlug()
	local Pos, _ = self:GetLinkPos()

	local plugs = ents.FindInSphere( Pos, self:GetAttachRange() )

	local ClosestDist
	local Closest
  --override
  local plugClass = self:GetPlugClass()
	for k,v in pairs( plugs ) do
		if (v:GetClass() == plugClass and self:CanLink(v) and not v:GetNWBool( "Linked", false )) then
			local Dist = v:GetPos():Distance( Pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end

function ENT:CanLink( Target )
	if (Target.Socket and Target.Socket:IsValid()) then return false end
	if (SocketModels[self:GetModel()] ~= Target:GetModel()) then return false end
	return true
end



if CLIENT then

	function ENT:GetAttachRange()
		return self:GetNWInt( "AttachRange", 5 )
	end

	function ENT:DrawEntityOutline()
		if (GetConVar("wire_plug_drawoutline"):GetBool()) then
			BaseClass.DrawEntityOutline( self )
		end
	end

	return  -- No more client
end
--this server only method
--will be used in plug
function ENT:GetAttachRange()
	return self.AttachRange
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

end

function ENT:Setup( WeldForce, AttachRange )

	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
	self:SetNWInt( "AttachRange", self.AttachRange )

end

------------------------------------------------------------
-- Think
-- Find nearby plugs and connect to them
------------------------------------------------------------
function ENT:Think()
	BaseClass.Think(self)

	if (not self.Plug) or (not self.Plug:IsValid()) then

		local plug = self:GetClosestPlug()

		if IsValid(plug) and SocketModels[self:GetModel()] == plug:GetModel() and (not plug:IsPlayerHolding()) then
			self:AttachPlug(plug)
			self:NextThink(CurTime()+0.05)
		end
	elseif (self.Const and (not self.Const:IsValid())) then -- Plug was unplugged
		self.Const = nil
		self.NoCollideConst = nil

		self.Plug:SetNWBool( "Linked", false )
		self:SetNWBool( "Linked", false )

		self.Plug:SetSocket(nil)
		self.Plug = nil
		self:OnDetach()

		self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME )
		return true
	end
end

local function ConfigConstraintRemove(socket,plug)
	plug:DeleteOnRemove( socket.Const )
	socket:DeleteOnRemove( socket.Const )
	if socket.NoCollideConst then
		socket.Const:DeleteOnRemove( socket.NoCollideConst )
	end
end

function ENT:AttachPlug( plug )
	-- Position plug
	local newpos,socketAng = self:GetLinkPos()
	plug:SetPos( newpos )
	plug:SetAngles( socketAng )

	self.NoCollideConst = constraint.NoCollide(self, plug, 0, 0)
	if not (self.NoCollideConst) then
		self.Plug = nil
		return
	end

	-- Constrain together
	self.Const = constraint.Weld( self, plug, 0, 0, self.WeldForce, true )
	if (not self.Const) then
		self.NoCollideConst:Remove()
		self.NoCollideConst = nil
		self.Plug = nil
		return
	end

	-- Prepare clearup incase one is removed
	plug:DeleteOnRemove( self.Const )
	self:DeleteOnRemove( self.Const )
	self.Const:DeleteOnRemove( self.NoCollideConst )

	-- Set references between them
	self.Plug = plug
	plug:SetSocket(self)

	self.Plug:SetNWBool( "Linked", true )
	self:SetNWBool( "Linked", true )

	self:OnAttach()
end

------------------------------------------------------------
-- Adv Duplicator Support
------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	info.Socket = {}
	info.Socket.WeldForce = self.WeldForce
	info.Socket.AttachRange = self.AttachRange
	if (self.Plug) then
		info.Socket.Plug = self.Plug:EntIndex()
	end

	return info
end


local function FindPlugConstraints(ent,plug,ctype)
	local index = {["Weld"] = "Const", ["NoCollide"] = "NoCollideConst"}
	local welds = constraint.FindConstraints( ent, ctype )
	for k,v in pairs( welds ) do
		if (v.Ent2 == plug) then
			ent[index[ctype]] = v.Constraint
			return
		end
	end
	local welds = constraint.FindConstraints( plug, ctype )
	for k,v in pairs( welds ) do
		if (v.Ent2 == ent) then
			ent[index[ctype]] = v.Constraint
			return
		end
	end
end

local function FindConstraint( ent, plug )
	timer.Simple(0.5,function()
		if IsValid(ent) and IsValid(plug) then
			local function findConsts(ctype)
				FindPlugConstraints(ent,plug,ctype)
			end
			findConsts("Weld")
			findConsts("NoCollide")
			ConfigConstraintRemove(ent,plug)
		end
	end)
end

function ENT:GetSetupDupeInfo(info)
	return info.Socket.WeldForce, info.Socket.AttachRange
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Socket) then
		ent:Setup( self:GetSetupDupeInfo(info)  )
		local plug = GetEntByID( info.Socket.Plug )
		if IsValid(plug) then
			ent.Plug = plug
			plug:SetSocket(ent)
			ent.Const = { ["IsValid"] = function() return true end }

			plug:SetNWBool( "Linked", true )
			ent:SetNWBool( "Linked", true )

			if GetConstByID then
				if info.Socket.Weld then
					ent.Const = GetConstByID( info.Socket.Weld )
				elseif info.Socket.Const then
					ent.Const = GetConstByID( info.Socket.Const )
				end
				if info.Socket.NoCollideConst then
					ent.NoCollideConst = GetConstByID( info.Socket.NoCollideConst )
				end
				ConfigConstraintRemove(ent,plug)
			else
				FindConstraint( ent, plug )
			end
		end
	else -- OLD DUPES COMPATIBILITY
		ent:Setup() -- default values

		-- Attempt to find connected plug
		timer.Simple(0.5,function()
			local welds = constraint.FindConstraints( ent, "Weld" )
      local plugClass = ent:GetPlugClass()
			local Pos = ent:GetPos()

			local plug = nil
			local p_constraint = nil
			local ClosestDist = nil
			for k,v in pairs( welds ) do
				if (v.Ent2:GetClass() == plugClass and ent:CanLink(v.Ent2)) then
					local dist = v.Ent2:GetPos():Distance( Pos )
					--check if we can attach it to socket and sort plugs
					if dist <= ent.AttachRange and (ClosestDist==nil or dist<ClosestDist) then
						p_constraint = v.Constraint
						plug = v.Ent2
						ClosestDist = dist
					end
				end
			end
			if plug then
				ent.Plug = plug
				plug:SetSocket(ent)
				ent.Const = p_constraint
				FindPlugConstraints(ent,plug,"NoCollide")
				ConfigConstraintRemove(ent,plug)
				plug:SetNWBool( "Linked", true )
				ent:SetNWBool( "Linked", true )
			end
		end)
	end -- /OLD DUPES COMPATIBILITY
end
