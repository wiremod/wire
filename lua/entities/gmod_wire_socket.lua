AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Socket"
ENT.Purpose         = "Links with a plug"
ENT.Instructions    = "Move a plug close to a plug to link them, and data will be transferred through the link."
ENT.WireDebugName	= "Socket"

local SocketData = list.Get("Wire_Socket_Models")

hook.Add("ModelPlugLuaRefresh","gmod_wire_socket_updatemodels",function()
	SocketData = list.Get("Wire_Socket_Models")
end)

function ENT:GetLinkPos()
	return self:LocalToWorld(self.SockData.pos or Vector(0,0,0)), self:GetAngles()
end

function ENT:CanLink( Target )
	if (Target.Socket and Target.Socket:IsValid()) then return false end
	if (self.SockData.plug ~= Target:GetModel()) then return false end
	return true
end

function ENT:GetClosestPlug()
	local Pos, _ = self:GetLinkPos()

	local plugs = ents.FindInSphere( Pos, CLIENT and self:GetNWInt( "AttachRange", 5 ) or self.AttachRange )

	local ClosestDist
	local Closest

	for k,v in ipairs( plugs ) do
		if (v:GetClass() == self:GetPlugClass() and not v:GetLinked()) then
			local Dist = v:GetPos():Distance( Pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end
	return Closest
end

function ENT:GetPlugClass()
	return "gmod_wire_plug"
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Linked" )
end

function ENT:CacheData()
	self.SockData = SocketData[ self:GetModel() ] or {}
end

if CLIENT then
	local sockets = ents.FindByClass("gmod_wire_socket") or {}
	function ENT:DrawEntityOutline()
		if (GetConVar("wire_plug_drawoutline"):GetBool()) then
			BaseClass.DrawEntityOutline( self )
		end
	end

	local function DrawLinkHelperLinefunction()
		for k,self in ipairs( sockets ) do
			local Pos, _ = self:GetLinkPos()

			local Closest = self:GetClosestPlug()

			if IsValid(Closest) and self:CanLink(Closest) and Closest:GetPlayerHolding() and Closest:GetClosestSocket() == self then
				local plugpos = Closest:GetPos():ToScreen()
				local socketpos = Pos:ToScreen()
				surface.SetDrawColor(255,255,100,255)
				surface.DrawLine(plugpos.x, plugpos.y, socketpos.x, socketpos.y)
			end
		end
	end

	function ENT:Initialize()
		self:CacheData()
		table.insert(sockets, self)
		if #sockets == 1 then
			hook.Add("HUDPaint", "Wire_Socket_DrawLinkHelperLine",DrawLinkHelperLinefunction)
		end
	end

	function ENT:OnRemove()
		table.RemoveByValue(sockets, self)
		if #sockets == 0 then
			hook.Remove("HUDPaint", "Wire_Socket_DrawLinkHelperLine")
		end
	end

	return  -- No more client
end


local NEW_PLUG_WAIT_TIME = 2
local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }
local LETTERS_INV = {}
for k,v in ipairs( LETTERS ) do
	LETTERS_INV[v] = k
end

function ENT:Initialize()
	self:CacheData()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetLinked( false )

	self.Memory = {}

	self.DoNextThink = CurTime() + 5 -- wait 5 seconds
end

function ENT:Setup( ArrayInput, WeldForce, AttachRange )
	local old = self.ArrayInput
	self.ArrayInput = ArrayInput or false

	if not (self.Inputs and self.Outputs and self.ArrayInput == old) then
		if (self.ArrayInput) then
			self.Inputs = WireLib.CreateInputs( self, { "In [ARRAY]" } )
			self.Outputs = WireLib.CreateOutputs( self, { "Out [ARRAY]" } )
		else
			self.Inputs = WireLib.CreateInputs( self, LETTERS )
			self.Outputs = WireLib.CreateOutputs( self, LETTERS )
		end
	end

	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
	self:SetNWInt( "AttachRange", self.AttachRange )

	self:ShowOutput()
end

function ENT:TriggerInput( name, value )
	if (self.Plug and self.Plug:IsValid()) then
		self.Plug:SetValue( name, value )
	end
	self:ShowOutput()
end

function ENT:SetValue( name, value )
	if not (self.Plug and self.Plug:IsValid()) then return end
	if (name == "In") then
		if (self.ArrayInput) then -- Both have array
			WireLib.TriggerOutput( self, "Out", table.Copy( value ) )
		else -- Target has array, this does not
			for i=1,#LETTERS do
				local val = (value or {})[i]
				if isnumber(val) then
					WireLib.TriggerOutput( self, LETTERS[i], val )
				end
			end
		end
	else
		if (self.ArrayInput) then -- Target does not have array, this does
			if (value ~= nil) then
				local data = table.Copy( self.Outputs.Out.Value )
				data[LETTERS_INV[name]] = value
				WireLib.TriggerOutput( self, "Out", data )
			end
		else -- Niether have array
			if (value ~= nil) then
				WireLib.TriggerOutput( self, name, value )
			end
		end
	end
	self:ShowOutput()
end

------------------------------------------------------------
-- WriteCell
-- Hi-speed support
------------------------------------------------------------
function ENT:WriteCell( Address, Value, WriteToMe )
	Address = math.floor(Address)
	if (WriteToMe) then
		self.Memory[Address or 1] = Value or 0
		return true
	else
		if (self.Plug and self.Plug:IsValid()) then
			self.Plug:WriteCell( Address, Value, true )
			return true
		else
			return false
		end
	end
end

------------------------------------------------------------
-- ReadCell
-- Hi-speed support
------------------------------------------------------------
function ENT:ReadCell( Address )
	Address = math.floor(Address)
	return self.Memory[Address or 1] or 0
end

function ENT:ResetValues()
	if (self.ArrayInput) then
		WireLib.TriggerOutput( self, "Out", {} )
	else
		for i=1,#LETTERS do
			WireLib.TriggerOutput( self, LETTERS[i], 0 )
		end
	end
	self.Memory = {}
	self:ShowOutput()
end

------------------------------------------------------------
-- ResendValues
-- Resends the values when plugging in
------------------------------------------------------------
function ENT:ResendValues()
	if (not self.Plug) then return end
	if (self.ArrayInput) then
		self.Plug:SetValue( "In", self.Inputs.In.Value )
	else
		for i=1,#LETTERS do
			self.Plug:SetValue( LETTERS[i], self.Inputs[LETTERS[i]].Value )
		end
	end
end

function ENT:AttachWeld(weld)
	self:EmitSound("buttons/lightswitch2.wav", 60)
	self.Weld = weld
	local plug = self.Plug
	weld:CallOnRemove("wire_socket_remove_on_weld",function()
		if self:IsValid() then
			self.Weld = nil
			self:SetLinked( false )
			self:ResetValues()
			self.DoNextThink = CurTime() + NEW_PLUG_WAIT_TIME
			self.Plug = nil
		end
		if plug and plug:IsValid() then
			plug:SetLinked( false )
			plug.Socket = nil
			plug:ResetValues()
		end
	end)
end

-- helper function
local function FindConstraint( ent, plug )
	if IsValid(ent) then
		local welds = constraint.FindConstraints( ent, "Weld" )
		for k,v in ipairs( welds ) do
			if (v.Ent2 == plug) then
				return v.Constraint
			end
		end
	end
	if IsValid(plug) then
		local welds = constraint.FindConstraints( plug, "Weld" )
		for k,v in ipairs( welds ) do
			if (v.Ent2 == ent) then
				return v.Constraint
			end
		end
	end
end

------------------------------------------------------------
-- Think
-- Find nearby plugs and connect to them
------------------------------------------------------------
function ENT:Think()
	BaseClass.Think(self)
	if self.DoNextThink then
		self:NextThink( self.DoNextThink )
		self.DoNextThink = nil
		return true
	end

	if not IsValid(self.Plug) then -- currently not linked, check for nearby links|
		local Pos, Ang = self:GetLinkPos()
		local Closest = self:GetClosestPlug()
		if (Closest and Closest:IsValid() and self:CanLink( Closest ) and not Closest:IsPlayerHolding() and Closest:GetClosestSocket() == self) then
			self.Plug = Closest
			Closest.Socket = self

			-- Move
			Closest:SetPos( Pos )
			Closest:SetAngles( Ang )

			-- Weld
			local weld = FindConstraint(self,Closest)
			if not weld then
				weld = constraint.Weld( self, Closest, 0, 0, self.WeldForce, true )
			end

			if weld and weld:IsValid() then self:AttachWeld(weld) end

			-- Resend all values
			Closest:ResendValues()
			self:ResendValues()

			Closest:SetLinked( true )
			self:SetLinked( true )
		end

		self:NextThink( CurTime() + 0.05 )
		return true
	else
		self:NextThink( CurTime() + 1 ) -- while linked, there's no point in running any faster than this
		return true
	end
end

function ENT:ShowOutput()
	local OutText = "Socket [" .. self:EntIndex() .. "]\n"
	if (self.ArrayInput) then
		OutText = OutText .. "Array input/outputs."
	else
		OutText = OutText .. "Number input/outputs."
	end
	if (self.Plug and self.Plug:IsValid()) then
		OutText = OutText .. "\nLinked to plug [" .. self.Plug:EntIndex() .. "]"
	end
	self:SetOverlayText(OutText)
end

duplicator.RegisterEntityClass( "gmod_wire_socket", WireLib.MakeWireEnt, "Data", "ArrayInput", "WeldForce", "AttachRange" )

------------------------------------------------------------
-- Adv Duplicator Support
------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	info.Socket = {}
	info.Socket.ArrayInput = self.ArrayInput
	info.Socket.WeldForce = self.WeldForce
	info.Socket.AttachRange = self.AttachRange
	if self.Plug then
		info.Socket.Plug = self.Plug:EntIndex()
	else
		-- if we don't write -1 here then sockets will somehow remember which plugs they used to be
		-- connected to in the past after paste even though that reference no longer exists. I have no clue why
		info.Socket.Plug = -1
	end

	return info
end

function ENT:GetApplyDupeInfoParams(info)
	return info.Socket.ArrayInput, info.Socket.WeldForce, info.Socket.AttachRange
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Socket) then
		ent:Setup( self:GetApplyDupeInfoParams(info) )
		if info.Socket.Plug ~= -1 then -- check for the strangely required -1 here (see BuildDupeInfo)
			local plug = GetEntByID( info.Socket.Plug )
			if IsValid(plug) then
				ent.Plug = plug
				plug.Socket = ent
				ent.Weld = nil

				plug:SetLinked( true )
				ent:SetLinked( true )
				-- Resend all values
				plug:ResendValues()
				ent:ResendValues()

				-- Attempt to find connected plug
				timer.Simple(0.5,function()
					local weld = FindConstraint( ent, plug )
					if not IsValid(weld) then
						weld = constraint.Weld( self, plug, 0, 0, self.WeldForce, true )
					end
					if IsValid(weld) then
						self:AttachWeld(weld)
					end
				end)
			end
		end
	else -- OLD DUPES COMPATIBILITY
		ent:Setup() -- default values

		-- Attempt to find connected plug
		timer.Simple(0.5,function()
			local weld = FindConstraint( ent )
			if IsValid(weld) then
				self:AttachWeld(weld)
			end
		end)
	end -- /OLD DUPES COMPATIBILITY
end
