AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')


ENT.WireDebugName = "Ranger"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:StartMotionController()

	self.Inputs = Wire_CreateInputs(self, { "X", "Y", "SelectValue","Length"})
	self.Outputs = Wire_CreateOutputs(self, { "Dist" })
	self.hires = false
end

function ENT:Setup( range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hiRes )
	--for duplication
	self.range          = range
	self.default_zero   = default_zero
	self.show_beam      = show_beam
	self.ignore_world   = ignore_world
	self.trace_water    = trace_water
	self.out_dist       = out_dist
	self.out_pos        = out_pos
	self.out_vel        = out_vel
	self.out_ang        = out_ang
	self.out_col        = out_col
	self.out_val        = out_val
	self.out_sid        = out_sid
	self.out_uid        = out_uid
	self.out_eid        = out_eid
	self.out_hnrm       = out_hnrm
	self.hires          = hiRes

	self.PrevOutput = nil

	if (show_beam) then
		self:SetBeamLength(math.min(self.range, 2000))
	else
		self:SetBeamLength(0)
	end

	self:SetNetworkedBool("TraceWater", trace_water)

	local onames, otypes = {}, {}
	if (out_dist) then
		table.insert(onames, "Dist") table.insert(otypes, "NORMAL")
	end
	if (out_pos) then
		table.insert(onames, "Pos") table.insert(otypes, "VECTOR")
		table.insert(onames, "Pos X") table.insert(otypes, "NORMAL")
		table.insert(onames, "Pos Y") table.insert(otypes, "NORMAL")
		table.insert(onames, "Pos Z") table.insert(otypes, "NORMAL")
	end
	if (out_vel) then
		table.insert(onames, "Vel") table.insert(otypes, "VECTOR")
		table.insert(onames, "Vel X") table.insert(otypes, "NORMAL")
		table.insert(onames, "Vel Y") table.insert(otypes, "NORMAL")
		table.insert(onames, "Vel Z") table.insert(otypes, "NORMAL")
	end
	if (out_ang) then
		table.insert(onames, "Ang") table.insert(otypes, "ANGLE")
		table.insert(onames, "Ang Pitch") table.insert(otypes, "NORMAL")
		table.insert(onames, "Ang Yaw") table.insert(otypes, "NORMAL")
		table.insert(onames, "Ang Roll") table.insert(otypes, "NORMAL")
	end
	if (out_col) then
		table.insert(onames, "Col RGB") table.insert(otypes, "VECTOR")
		table.insert(onames, "Col R") table.insert(otypes, "NORMAL")
		table.insert(onames, "Col G") table.insert(otypes, "NORMAL")
		table.insert(onames, "Col B") table.insert(otypes, "NORMAL")
		table.insert(onames, "Col A") table.insert(otypes, "NORMAL")
	end
	if (out_val) then
		table.insert(onames, "Val") table.insert(otypes, "NORMAL")
		table.insert(onames, "ValSize") table.insert(otypes, "NORMAL")
	end
	if (out_sid) then
		table.insert(onames, "SteamID") table.insert(otypes, "STRING")
	end
	if (out_uid) then
		table.insert(onames, "UniqueID") table.insert(otypes, "NORMAL")
	end
	if (out_eid) then
		table.insert(onames, "EntID") table.insert(otypes, "NORMAL")
		table.insert(onames, "Entity") table.insert(otypes, "ENTITY")
	end
	if (out_hnrm) then
		table.insert(onames, "HitNormal") table.insert(otypes, "VECTOR")
		table.insert(onames, "HitNormal X") table.insert(otypes, "NORMAL")
		table.insert(onames, "HitNormal Y") table.insert(otypes, "NORMAL")
		table.insert(onames, "HitNormal Z") table.insert(otypes, "NORMAL")
	end
	table.insert(onames, "RangerData") table.insert(otypes, "RANGER")
	WireLib.AdjustSpecialOutputs(self, onames, otypes)

	self:TriggerOutput(0, Vector(0, 0, 0), Vector(0, 0, 0), Angle(0, 0, 0), Color(255, 255, 255, 255),nil,0,0,NULL, Vector(0, 0, 0),nil)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "X") then
		self:SetSkewX(value)
	elseif (iname == "Y") then
		self:SetSkewY(value)
	elseif (iname == "Length") then
		self.range = value
		self:SetBeamLength(self.show_beam and math.min(value, 2000) or 0)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	local trace = {}
	trace.start = self:GetPos()
	if (self.Inputs.X.Value == 0 and self.Inputs.Y.Value == 0) then
		trace.endpos = trace.start + self:GetUp()*self.range
	else
		local skew = Vector(self.Inputs.X.Value, self.Inputs.Y.Value, 1)
		skew = skew*(self.range/skew:Length())
		local beam_x = self:GetRight()*skew.x
		local beam_y = self:GetForward()*skew.y
		local beam_z = self:GetUp()*skew.z
		trace.endpos = trace.start + beam_x + beam_y + beam_z
	end
	trace.filter = { self }
	if (self.trace_water) then trace.mask = -1 end
	trace = util.TraceLine(trace)

	local dist = 0
	local pos = Vector(0, 0, 0)
	local vel = Vector(0, 0, 0)
	local ang = Angle(0, 0, 0)
	local col = Color(255, 255, 255, 255)
	local ent = NULL
	local sid = ""
	local uid = 0
	local val = {}
	local hnrm = Vector(0,0,0)

	if (trace.Hit) then
		dist = trace.Fraction*self.range
		pos = trace.HitPos
		hnrm = trace.HitNormal
		ent = trace.Entity

		if (ent:IsValid()) then

			vel = ent:GetVelocity()
			ang = ent:GetAngles()
			col = ent:GetColor()

			if (self.out_sid or self.out_uid) and (ent:IsPlayer()) then
				sid = ent:SteamID() or ""
				uid = tonumber(ent:UniqueID()) or -1
			end

			if (self.out_val and ent.Outputs) then
				local i = 0
				for k,v in pairs(ent.Outputs) do
					if (v.Value != nil) then
						val[i] = v.Value
						i = i + 1
					end
				end
			end

		elseif(self.ignore_world) then
			if (trace.HitWorld) then
				if (self.default_zero) then
					dist = 0
				else
					dist = self.range
				end
				pos = Vector(0,0,0)
			end
		end

	else
		if (not self.default_zero) then
			dist = self.range
		end
	end

	if (COLOSSAL_SANDBOX) then
		vel = vel * 6.25
		pos = pos * 6.25
		dist = dist * 6.25
	end

	self:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)
	self:ShowOutput()

	if (self.hires) then
		self:NextThink(CurTime())
	else
		self:NextThink(CurTime()+0.04)
	end

	return true
end

function ENT:ShowOutput() --this function is evil (very), should be done clientside

	local txt = "Max Range: " .. self.range

	if (self.out_dist) then
		txt = txt .. "\nRange = " .. math.Round(self.Outputs["Dist"].Value*1000)/1000
	end

	if (self.out_pos) then
		txt = txt .. "\nPosition = "
			.. math.Round(self.Outputs["Pos X"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Pos Y"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Pos Z"].Value*1000)/1000
	end

	if (self.out_vel) then
		txt = txt .. "\nVelocity = "
			.. math.Round(self.Outputs["Vel X"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Vel Y"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Vel Z"].Value*1000)/1000
	end

	if (self.out_ang) then
		txt = txt .. "\nAngles = "
			.. math.Round(self.Outputs["Ang Pitch"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Ang Yaw"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Ang Roll"].Value*1000)/1000
	end

	if (self.out_col) then
		txt = txt .. "\nColor = "
			.. math.Round(self.Outputs["Col R"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col G"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col B"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["Col A"].Value*1000)/1000
	end

	if (self.out_val) then
		txt = txt .. "\nValue = " .. math.Round((self.Outputs["Val"].Value)*1000)/1000 .. " ValSize = " .. self.Outputs["ValSize"].Value
	end

	if (self.out_sid) then
		txt = txt .. "\nSteamID = " .. (self.Outputs["SteamID"].Value or "")
	end

	if (self.out_uid) then
		txt = txt .. "\nUniqueID = " .. (self.Outputs["UniqueID"].Value or 0)
	end

	if (self.out_eid) then
		txt = txt .. "\nEntID = " .. (self.Outputs["EntID"].Value or 0)
	end

	if (self.out_hnrm) then
		txt = txt .. "\nHitNormal = "
			.. math.Round(self.Outputs["HitNormal X"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["HitNormal Y"].Value*1000)/1000 .. ", "
			.. math.Round(self.Outputs["HitNormal Z"].Value*1000)/1000
	end

	self:SetOverlayText(txt)
end

function ENT:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)

	if (self.out_dist) then
		Wire_TriggerOutput(self, "Dist", dist)
	end

	if (self.out_pos) then
		Wire_TriggerOutput(self, "Pos", pos)
		Wire_TriggerOutput(self, "Pos X", pos.x)
		Wire_TriggerOutput(self, "Pos Y", pos.y)
		Wire_TriggerOutput(self, "Pos Z", pos.z)
	end

	if (self.out_vel) then
		Wire_TriggerOutput(self, "Vel", vel)
		Wire_TriggerOutput(self, "Vel X", vel.x)
		Wire_TriggerOutput(self, "Vel Y", vel.y)
		Wire_TriggerOutput(self, "Vel Z", vel.z)
	end

	if (self.out_ang) then
		Wire_TriggerOutput(self, "Ang", ang)
		Wire_TriggerOutput(self, "Ang Pitch", ang.p)
		Wire_TriggerOutput(self, "Ang Yaw", ang.y)
		Wire_TriggerOutput(self, "Ang Roll", ang.r)
	end

	if (self.out_col) then
		Wire_TriggerOutput(self, "Col RGB", Vector(col.r, col.g, col.b))
		Wire_TriggerOutput(self, "Col R", col.r)
		Wire_TriggerOutput(self, "Col G", col.g)
		Wire_TriggerOutput(self, "Col B", col.b)
		Wire_TriggerOutput(self, "Col A", col.a)
	end

	if (self.out_sid) then
		Wire_TriggerOutput(self, "SteamID", sid)
	end

	if (self.out_uid) then
		Wire_TriggerOutput(self, "UniqueID", uid)
	end

	if (self.out_eid) then
		Wire_TriggerOutput(self, "EntID", ent:EntIndex())
		Wire_TriggerOutput(self, "Entity", ent)
	end

	if (self.out_hnrm and hnrm) then
		Wire_TriggerOutput(self, "HitNormal", hnrm)
		Wire_TriggerOutput(self, "HitNormal X", hnrm.x)
		Wire_TriggerOutput(self, "HitNormal Y", hnrm.y)
		Wire_TriggerOutput(self, "HitNormal Z", hnrm.z)
	end

	if (val != nil && #val > 0 && self.Inputs.SelectValue.Value < table.Count(val)) then
		Wire_TriggerOutput(self, "Val", val[self.Inputs.SelectValue.Value])
		Wire_TriggerOutput(self, "ValSize", table.Count(val))
	else
		Wire_TriggerOutput(self, "Val", 0)
		Wire_TriggerOutput(self, "ValSize", 0)
	end
	Wire_TriggerOutput(self, "RangerData", trace)

end

function MakeWireRanger( pl, Pos, Ang, model, range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hires, nocollide )
	if ( !pl:CheckLimit( "wire_rangers" ) ) then return false end

	local wire_ranger = ents.Create( "gmod_wire_ranger" )
	if (!wire_ranger:IsValid()) then return false end

	wire_ranger:SetAngles( Ang )
	wire_ranger:SetPos( Pos )
	wire_ranger:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
	wire_ranger:Spawn()

	wire_ranger:Setup( range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hires )
	wire_ranger:SetPlayer( pl )
	wire_ranger.pl	= pl

	if ( nocollide == true ) then wire_ranger:GetPhysicsObject():EnableCollisions( false ) end
	wire_ranger.nocollide = nocollide

	pl:AddCount( "wire_rangers", wire_ranger )

	return wire_ranger
end
duplicator.RegisterEntityClass("gmod_wire_ranger", MakeWireRanger, "Pos", "Ang", "Model", "range", "default_zero", "show_beam", "ignore_world", "trace_water", "out_dist", "out_pos", "out_vel", "out_ang", "out_col", "out_val", "out_sid", "out_uid", "out_eid", "out_hnrm", "hires", "nocollide")
