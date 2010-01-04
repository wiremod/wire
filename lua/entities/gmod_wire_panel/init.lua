AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Panel"

function ENT:OnRemove()
	--SetGlobalInt( "chan", nil )
	for _,pl in ipairs(player.GetAll()) do
		pl:SetNetworkedInt(self:EntIndex().."click",nil)
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

	self.Inputs = Wire_CreateInputs(self, { "Ch1", "Ch2", "Ch3", "Ch4", "Ch5", "Ch6", "Ch7", "Ch8" })

	--SetGlobalInt( "chan", self.chan )

	self.Entity:SetNetworkedInt('chan',self.chan)
	self.Outputs = Wire_CreateOutputs(self, { "Out" })

	for i,pl in pairs(player.GetAll()) do
		pl:SetNetworkedInt(self:EntIndex().."click",self.click)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	for _,pl in pairs(player.GetAll()) do
		local trace = {}
			trace.start = pl:GetShootPos()
			trace.endpos = pl:GetAimVector() * 64 + trace.start
			trace.filter = pl
		local trace = util.TraceLine(trace)

		if trace.Entity == self then
			pl:SetNetworkedBool(self:EntIndex().."control",true)
			local s_set = self.chan
			local c_set = pl:GetInfoNum("wire_panel_chan", 1)
			if s_set != c_set then
				if (c_set > 0) then
					--Msg("Think: Set changed, updating var.\n")
					self.chan = c_set
					local value = self:GetChannelValue( self.chan )
					pl:ConCommand("wire_panel_chan 0\n")
					Wire_TriggerOutput(self, "Out", value)
				end
			end
		else
			pl:SetNetworkedBool(self:EntIndex().."control",false)
		end
	end

	self:NextThink(CurTime()+0.08)
	return true
end

function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		self.click = self.click + 1
		if self.click > 8 then
			self.click = 1
		end
		caller:SetNetworkedInt(self:EntIndex().."click",self.click)
	end
end

function ENT:TriggerInput(iname, value, iter)
	local channel_number = tonumber(iname:match("^Ch([1-8])$"))
	if not channel_number then return end
	if self.chan == channel_number then Wire_TriggerOutput(self, "Out", value, iter) end
	self:SetChannelValue( channel_number, value )
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
