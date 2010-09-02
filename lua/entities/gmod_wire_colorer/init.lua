
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
	self.InColor = Color(255, 255, 255, 255)
	self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(outColor,Range)
	--Msg("setup\n")
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

local function CheckPP(ply, ent)
	if !IsValid(ply) or !IsValid(ent) then return false end
	if CPPI then
		-- Temporary, done this way due to certain PP implementations not always returning a value for CPPICanTool
		if ent == ply then return true end
		if ent:CPPICanTool( ply, "colour" ) == false then return false end
	end
	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "Fire" then
		if value ~= 0 then
			local vStart = self.Entity:GetPos()
			local vForward = self.Entity:GetUp()

			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self.Entity }
			local trace = util.TraceLine( trace )

			if !CheckPP( self.pl, trace.Entity ) then return end
			if trace.Entity:IsPlayer() then
				trace.Entity:SetColor( self.InColor.r, self.InColor.g, self.InColor.b, 255 )
			else
				trace.Entity:SetColor( self.InColor.r, self.InColor.g, self.InColor.b, self.InColor.a )
			end
		end
	elseif iname == "R" then
		self.InColor.r = math.Clamp(value, 0, 255)
	elseif iname == "G" then
		self.InColor.g = math.Clamp(value, 0, 255)
	elseif iname == "B" then
		self.InColor.b = math.Clamp(value, 0, 255)
	elseif iname == "A" then
		self.InColor.a = math.Clamp(value, 0, 255)
	elseif iname == "RGB" then
		self.InColor = Color( value[1], value[2], value[3], self.InColor.a )
	end
end

function ENT:ShowOutput()
	local text = "Colorer"
	if self.Outputs["R"] then
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
	if self.Outputs["R"]then
		local vStart = self.Entity:GetPos()
		local vForward = self.Entity:GetUp()

		local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamLength())
			trace.filter = { self.Entity }
		local trace = util.TraceLine( trace )

		if !IsValid( trace.Entity ) then return end
		local r,g,b,a = trace.Entity:GetColor()

		Wire_TriggerOutput(self.Entity,"R", r)
		Wire_TriggerOutput(self.Entity,"G", g)
		Wire_TriggerOutput(self.Entity,"B", b)
		Wire_TriggerOutput(self.Entity,"A", a)

		self:ShowOutput()
	end
	self.Entity:NextThink(CurTime() + 0.05)
	return true
end
