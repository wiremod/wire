
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Socket"

local MODEL = Model( "models/props_lab/tpplugholder_single.mdl" )

//Time after loosing one plug to search for another
local NEW_PLUG_WAIT_TIME = 2
local PLUG_IN_SOCKET_CONSTRAINT_POWER = 5000
local PLUG_IN_ATTACH_RANGE = 3

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.MyPlug = nil
	self.Const = nil

	self.Inputs = Wire_CreateInputs(self.Entity, { "A","B","C","D","E","F","G","H" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A","B","C","D","E","F","G","H" })
end

function ENT:TriggerInput(iname, value)
    if (self.MyPlug) and (self.MyPlug:IsValid()) then
		self.MyPlug:SetValue(iname, value)
	end
	self:ShowOutput()
end

function ENT:SetValue(index,value)
	if (self.Const) and (self.Const:IsValid()) then
		Wire_TriggerOutput(self.Entity, index, value)
	else
		Wire_TriggerOutput(self.Entity, index, 0)
	end

	self:ShowOutput()
end

function ENT:Setup()
	self:ShowOutput()
end

function ENT:Think()
	self.BaseClass.Think(self)

	// If we were unplugged, reset the plug and socket to accept new ones.
	if (self.Const) and (not self.Const:IsValid()) then
		self.Const = nil
		self.NoCollideConst = nil
		if (self.MyPlug) and (self.MyPlug:IsValid()) then
			self.MyPlug:SetSocket(nil)
			self.MyPlug = nil
		end

		self.ReceivedValue = 0 //We're now getting no signal
		for i,v in pairs(self.Outputs)do
		  Wire_TriggerOutput(self.Entity, v.Name, 0)
		end
		self:ShowOutput()

		self.Entity:NextThink( CurTime() + NEW_PLUG_WAIT_TIME ) //Give time before next grabbing a plug.
		return true
	end

	// If we have no plug in us
	if (not self.MyPlug) or (not self.MyPlug:IsValid()) then

		// Find entities near us
		local sockCenter = self:GetOffset( Vector(8, -13, -10) )
		local local_ents = ents.FindInSphere( sockCenter, PLUG_IN_ATTACH_RANGE )
		for key, plug in pairs(local_ents) do

			// If we find a plug, try to attach it to us
			if ( plug:IsValid() && plug:GetClass() == "gmod_wire_plug" ) then

				// If no other sockets are using it
				if plug.MySocket == nil then
				    local plugpos = plug:GetPos()
					local dist = (sockCenter-plugpos):Length()

					self:AttachPlug(plug)
				end
			end
		end
	end
end

function ENT:AttachPlug( plug )
	// Set references between them
	plug:SetSocket(self.Entity)
	self.MyPlug = plug

	// Position plug
	local newpos = self:GetOffset( Vector(8, -13, -5) )
	local socketAng = self.Entity:GetAngles()
	plug:SetPos( newpos )
	plug:SetAngles( socketAng )

	self.NoCollideConst = constraint.NoCollide(self.Entity, plug, 0, 0)
	if (not self.NoCollideConst) then
	    self.MyPlug = nil
		plug:SetSocket(nil)
	    return
	end

	// Constrain together
	self.Const = constraint.Weld( self.Entity, plug, 0, 0, PLUG_IN_SOCKET_CONSTRAINT_POWER, true )
	if (not self.Const) then
	    self.NoCollideConst:Remove()
	    self.NoCollideConst = nil
	    self.MyPlug = nil
		plug:SetSocket(nil)
	    return
	end

	// Prepare clearup incase one is removed
	plug:DeleteOnRemove( self.Const )
	self.Entity:DeleteOnRemove( self.Const )
	self.Const:DeleteOnRemove( self.NoCollideConst )

	for i,v in pairs(self.Inputs)do
        plug:SetValue(v.Name,v.Value)
 	end

	plug:AttachedToSocket(self.Entity)

	self:ShowOutput()
end

function ENT:ShowOutput()
	self.OutText = "Socket"
	if (self.Inputs) then
		self.OutText = self.OutText .. "\nInputs: "
		if (self.Inputs.A.Value) then
			self.OutText = self.OutText .. " A:" .. self.Inputs.A.Value
		end
		if (self.Inputs.B.Value) then
			self.OutText = self.OutText .. " B:" .. self.Inputs.B.Value
		end
		if (self.Inputs.C.Value) then
			self.OutText = self.OutText .. " C:" .. self.Inputs.C.Value
		end
		if (self.Inputs.D.Value) then
			self.OutText = self.OutText .. " D:" .. self.Inputs.D.Value
		end
		if (self.Inputs.E.Value) then
			self.OutText = self.OutText .. " E:" .. self.Inputs.E.Value
		end
		if (self.Inputs.F.Value) then
			self.OutText = self.OutText .. " F:" .. self.Inputs.F.Value
		end
		if (self.Inputs.G.Value) then
			self.OutText = self.OutText .. " G:" .. self.Inputs.G.Value
		end
		if (self.Inputs.H.Value) then
			self.OutText = self.OutText .. " H:" .. self.Inputs.H.Value
		end
	end
	if (self.Outputs) then
		self.OutText = self.OutText .. "\nOutputs: "
		if (self.Outputs.A.Value) then
			self.OutText = self.OutText .. " A:" .. self.Outputs.A.Value
		end
		if (self.Outputs.B.Value) then
			self.OutText = self.OutText .. " B:" .. self.Outputs.B.Value
		end
		if (self.Outputs.C.Value) then
			self.OutText = self.OutText .. " C:" .. self.Outputs.C.Value
		end
		if (self.Outputs.D.Value) then
			self.OutText = self.OutText .. " D:" .. self.Outputs.D.Value
		end
		if (self.Outputs.E.Value) then
			self.OutText = self.OutText .. " E:" .. self.Outputs.E.Value
		end
		if (self.Outputs.F.Value) then
			self.OutText = self.OutText .. " F:" .. self.Outputs.F.Value
		end
		if (self.Outputs.G.Value) then
			self.OutText = self.OutText .. " G:" .. self.Outputs.G.Value
		end
		if (self.Outputs.H.Value) then
			self.OutText = self.OutText .. " H:" .. self.Outputs.H.Value
		end
	end
	self:SetOverlayText(self.OutText)
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
end
