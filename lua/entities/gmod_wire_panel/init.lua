AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Panel"

function ENT:OnRemove()
--	SetGlobalInt( "chan", nil )
	for i,pl in pairs(player.GetAll()) do
		pl:SetNetworkedInt(self.Entity:EntIndex().."click",nil)
	end
end


/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	self.click = 0
	self.chan = 1

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "Ch1", "Ch2", "Ch3", "Ch4", "Ch5", "Ch6", "Ch7", "Ch8" })

--	SetGlobalInt( "chan", self.chan )

	self.Entity:SetNetworkedInt('chan',self.chan)
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })

	for i,pl in pairs(player.GetAll()) do
		pl:SetNetworkedInt(self.Entity:EntIndex().."click",self.click)
	end
end


function ENT:Setup()
	for i = 0, 7 do
		self:SetChannelValue( i, string.format("%.2f", 0.0) )
	end
end


function ENT:Use()
end

function ENT:Think()
	self.BaseClass.Think(self)

	for i,pl in pairs(player.GetAll()) do
		local trace = {}
			trace.start = pl:GetShootPos()
			trace.endpos = pl:GetAimVector() * 64 + trace.start
			trace.filter = pl
		local trace = util.TraceLine(trace)

		if trace.Entity == self.Entity then
			pl:SetNetworkedBool(self.Entity:EntIndex().."control",true)
			local s_set = self.chan
			local c_set = pl:GetInfoNum("wire_panel_chan", 1)
			if s_set != c_set then
				if (c_set > 0) then
					--Msg("Think: Set changed, updating var.\n")
					self.chan = c_set
					local value = self:GetChannelValue( self.chan )
					pl:ConCommand("wire_panel_chan 0\n")
					Wire_TriggerOutput(self.Entity, "Out", value)
				end
			end
		else
			pl:SetNetworkedBool(self.Entity:EntIndex().."control",false)
		end
	end

	self.Entity:NextThink(CurTime()+0.08)
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		self.click = self.click + 1
		if self.click > 8 then
			self.click = 1
		end
		caller:SetNetworkedInt(self.Entity:EntIndex().."click",self.click)
	end
end


function ENT:TriggerInput(iname, value, iter)
	if (iname == "Ch1") then
		if (self.chan == 1) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 1, string.format("%.2f", value) )
	elseif (iname == "Ch2") then
		if (self.chan == 2) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 2, string.format("%.2f", value) )
	elseif (iname == "Ch3") then
		if (self.chan == 3) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 3, string.format("%.2f", value) )
	elseif (iname == "Ch4") then
		if (self.chan == 4) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 4, string.format("%.2f", value) )
	elseif (iname == "Ch5") then
		if (self.chan == 5) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 5, string.format("%.2f", value) )
	elseif (iname == "Ch6") then
		if (self.chan == 6) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 6, string.format("%.2f", value) )
	elseif (iname == "Ch7") then
		if (self.chan == 7) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 7, string.format("%.2f", value) )
	elseif (iname == "Ch8") then
		if (self.chan == 8) then Wire_TriggerOutput(self.Entity, "Out", value, iter) end
		self:SetChannelValue( 8, string.format("%.2f", value) )
	end

end


function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end


function MakeWirePanel( pl, Pos, Ang, model )

	if ( !pl:CheckLimit( "wire_panels" ) ) then return false end

	local wire_panel = ents.Create( "gmod_wire_panel" )
	if (!wire_panel:IsValid()) then return false end
	wire_panel:SetModel(model)

	wire_panel:SetAngles( Ang )
	wire_panel:SetPos( Pos )
	wire_panel:Spawn()

	wire_panel:SetPlayer(pl)

	pl:AddCount( "wire_panels", wire_panel )

	return wire_panel

end

duplicator.RegisterEntityClass("gmod_wire_panel", MakeWirePanel, "Pos", "Ang", "Model")
