
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Colorer"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, { "Fire", "R", "G", "B", "A", "RGB" }, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Out"})
	self.ValueR = 255
	self.ValueG = 255
	self.ValueB = 255
	self.ValueA = 255
	self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(outColor,Range)
	Msg("setup\n")
	if(outColor)then
		local onames = {}
		table.insert(onames, "R")
		table.insert(onames, "G")
		table.insert(onames, "B")
		table.insert(onames, "A")
		Wire_AdjustOutputs(self.Entity, onames)
	end
	self:SetBeamLength(Range)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()

			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * self:GetBeamLength())
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace )

			if (!trace.Entity) then return false end
			if (!trace.Entity:IsValid() ) then return false end
			if (trace.Entity:IsWorld()) then return false end
			if ( CLIENT ) then return true end
			trace.Entity:SetColor( self.ValueR, self.ValueG, self.ValueB, self.ValueA )
		end
	elseif(iname == "R") then
		self.ValueR = math.max(math.min(255,value),0)
	elseif(iname == "G") then
		self.ValueG = math.max(math.min(255,value),0)
	elseif(iname == "B") then
		self.ValueB = math.max(math.min(255,value),0)
	elseif(iname == "A") then
		self.ValueA = math.max(math.min(255,value),0)
	elseif(iname == "RGB") then
		self.ValueR, self.ValueG, self.ValueB = value[1], value[2], value[3]
	end
end

function ENT:ShowOutput()
	local text = "Colorer"
	if(self.Outputs["R"])then
		text = text .. "\nColor = "
		.. math.Round(self.Outputs["R"].Value*1000)/1000 .. ", "
		.. math.Round(self.Outputs["G"].Value*1000)/1000 .. ", "
		.. math.Round(self.Outputs["B"].Value*1000)/1000 .. ", "
		.. math.Round(self.Outputs["A"].Value*1000)/1000
	end
	self:SetOverlayText( text )
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

function ENT:Think()
	self.BaseClass.Think(self)
	if(self.Outputs["R"])then
		local vStart = self.Entity:GetPos()
		local vForward = self.Entity:GetUp()

		local trace = {}
		  trace.start = vStart
		  trace.endpos = vStart + (vForward * self:GetBeamLength())
		  trace.filter = { self.Entity }
		local trace = util.TraceLine( trace )

		if (!trace.Entity) then return false end
		if (!trace.Entity:IsValid() ) then return false end
		if (trace.Entity:IsWorld()) then return false end
		if ( CLIENT ) then return true end

		local r,g,b,a = trace.Entity:GetColor()
		//Msg("color check\n")
		//Msg("R-"..tostring(r).."\nG-"..tostring(g).."\nB-"..tostring(b).."\nA-"..tostring(a).."\n")

		Wire_TriggerOutput(self.Entity,"R",r)
		Wire_TriggerOutput(self.Entity,"G",g)
		Wire_TriggerOutput(self.Entity,"B",b)
		Wire_TriggerOutput(self.Entity,"A",a)

		self:ShowOutput()

	end
	self.Entity:NextThink(CurTime()+0.25)
end

