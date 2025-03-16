AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Ranger"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Ranger"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
	self:NetworkVar( "Bool",  0, "ShowBeam" )
	self:NetworkVar( "Float", 1, "SkewX" )
	self:NetworkVar( "Float", 2, "SkewY" )
	self:NetworkVar( "Vector", 0, "Target" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:StartMotionController()

	self.Inputs = WireLib.CreateInputs(self, {
		"X", "Y", "SelectValue", "Length",
		"Target [VECTOR]",
		"Ignore (Adds all specified entities to the ranger's filter.\nKeep in mind that this filtering is not synced to the client and is therefore not visible in the ranger's beam.) [ARRAY]"
	})
	self.Outputs = WireLib.CreateOutputs(self, { "Dist" })
	self.hires = false
end

function ENT:Setup( range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hiRes )
	--for duplication
	self.default_zero = default_zero
	self.show_beam = show_beam
	self.ignore_world = ignore_world
	self.trace_water = trace_water
	self.out_dist = out_dist
	self.out_pos = out_pos
	self.out_vel = out_vel
	self.out_ang = out_ang
	self.out_col = out_col
	self.out_val = out_val
	self.out_sid = out_sid
	self.out_uid = out_uid
	self.out_eid = out_eid
	self.out_hnrm = out_hnrm
	self.hires = hiRes

	self.PrevOutput = nil

	if range then self:SetBeamLength(math.min(range, 64000)) end
	if show_beam ~= nil then self:SetShowBeam(show_beam) end

	self:SetNWBool("TraceWater", trace_water)

	local onames, otypes = {}, {}


	local function add(...)
		local args = {...}
		for i=1,#args,2 do
			onames[#onames+1] = args[i]
			otypes[#otypes+1] = args[i+1]
		end
	end


	if (out_dist) then add("Dist","NORMAL") end
	if (out_pos) then
		add("Pos", "VECTOR",
			"Pos X", "NORMAL",
			"Pos Y", "NORMAL",
			"Pos Z", "NORMAL")
	end
	if (out_vel) then
		add("Vel","VECTOR",
			"Vel X","NORMAL",
			"Vel Y","NORMAL",
			"Vel Z","NORMAL")
	end
	if (out_ang) then
		add("Ang","ANGLE",
			"Ang Pitch","NORMAL",
			"Ang Yaw","NORMAL",
			"Ang Roll","NORMAL")
	end
	if (out_col) then
		add("Col RGB","VECTOR",
			"Col R","NORMAL",
			"Col G","NORMAL",
			"Col B","NORMAL",
			"Col A","NORMAL")
	end
	if (out_val) then add("Val","NORMAL","ValSize","NORMAL") end
	if (out_sid) then add( "SteamID", "STRING" ) end
	if (out_uid) then add( "UniqueID","NORMAL" ) end
	if (out_eid) then add( "EntID", "NORMAL", "Entity", "ENTITY" ) end
	if (out_hnrm) then
		add("HitNormal","VECTOR",
			"HitNormal X","NORMAL",
			"HitNormal Y","NORMAL",
			"HitNormal Z","NORMAL")
	end
	add( "RangerData", "RANGER" )
	WireLib.AdjustSpecialOutputs(self, onames, otypes)

	self:TriggerOutput(0, Vector(0, 0, 0), Vector(0, 0, 0), Angle(0, 0, 0), Color(255, 255, 255, 255),nil,"",0,NULL, Vector(0, 0, 0),nil)
	self:ShowOutput(0, Vector(0, 0, 0), Vector(0, 0, 0), Angle(0, 0, 0), Color(255, 255, 255, 255),nil,"",0,NULL, Vector(0, 0, 0),nil)
end

function ENT:TriggerInput(iname, value)
	if (iname == "X") then
		self:SetSkewX(value)
	elseif (iname == "Y") then
		self:SetSkewY(value)
	elseif (iname == "Length") then
		self:SetBeamLength(math.min(value, 64000))
	elseif (iname == "Target") then
		self:SetTarget(value)
	elseif (iname == "Ignore") then
		self.ignore = { self }
		for k,v in ipairs(value) do
			if IsEntity(v) and IsValid(v) then
				self.ignore[#self.ignore+1] = v
			end
		end
	end
end

function ENT:Think()
	BaseClass.Think(self)

	local tracedata = {}
	tracedata.start = self:GetPos()
	if self.Inputs.Target.Value ~= vector_origin then
		tracedata.endpos = self:GetPos()+(self:GetTarget()-self:GetPos()):GetNormalized()*self:GetBeamLength()
		if tracedata.endpos[1] ~= tracedata.endpos[1] then tracedata.endpos = self:GetPos()+Vector(self:GetBeamLength(), 0, 0) end
	elseif (self.Inputs.X.Value == 0 and self.Inputs.Y.Value == 0) then
		tracedata.endpos = tracedata.start + self:GetUp() * self:GetBeamLength()
	else
		local skew = Vector(self.Inputs.X.Value, self.Inputs.Y.Value, 1)
		skew = skew*(self:GetBeamLength()/skew:Length())
		local beam_x = self:GetRight()*skew.x
		local beam_y = self:GetForward()*skew.y
		local beam_z = self:GetUp()*skew.z
		tracedata.endpos = tracedata.start + beam_x + beam_y + beam_z
	end
	tracedata.filter = self.ignore or { self }
	if (self.trace_water) then tracedata.mask = -1 end
	local trace = util.TraceLine(tracedata)
	trace.RealStartPos = tracedata.start

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
		dist = trace.Fraction * self:GetBeamLength()
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
				local i = 1
				for k,v in pairs(ent.Outputs) do
					if (v.Value ~= nil and type(v.Value) == "number") then
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
					dist = self:GetBeamLength()
				end
				pos = Vector(0,0,0)
			end
		end

	else
		if (not self.default_zero) then
			dist = self:GetBeamLength()
		end
	end

	self:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)
	self:ShowOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)

	if (self.hires) then
		self:NextThink(CurTime())
	else
		self:NextThink(CurTime()+0.04)
	end

	return true
end

local round = math.Round

function ENT:ShowOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)
	local txt = "Max Range: " .. self:GetBeamLength()

	if (self.out_dist) then txt = txt .. "\nRange = " .. round(dist,3) end
	if (self.out_pos) then txt = txt .. string.format("\nPosition = %s, %s, %s", round(pos.x,3), round(pos.y,3), round(pos.z,3)) end
	if (self.out_vel) then txt = txt .. string.format("\nVelocity = %s, %s, %s", round(vel.x,3), round(vel.y,3), round(vel.z,3)) end
	if (self.out_ang) then txt = txt .. string.format("\nAngles = %s, %s, %s", round(ang.pitch,3), round(ang.yaw,3), round(ang.roll,3)) end
	if (self.out_col) then txt = txt .. string.format("\nColor = %s, %s, %s, %s", round(col.r), round(col.g), round(col.b), round(col.a)) end
	if (self.out_val) then txt = txt .. string.format("\nValue = %s ValSize = %s", round(self.Outputs["Val"].Value or 0,3), #(val or {}) ) end
	if (self.out_sid) then txt = txt .. "\nSteamID = " .. (sid or "") end
	if (self.out_uid) then txt = txt .. "\nUniqueID = " .. (uid or 0) end
	if (self.out_eid) then txt = txt .. "\nEntID = " .. ent:EntIndex() end
	if (self.out_hnrm) then txt = txt .. string.format("\nHitNormal = %s, %s, %s", round(hnrm.x,3), round(hnrm.y,3), round(hnrm.z,3)) end

	self:SetOverlayText(txt)
end

function ENT:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace)

	if (self.out_dist) then
		WireLib.TriggerOutput(self, "Dist", dist)
	end

	if (self.out_pos) then
		WireLib.TriggerOutput(self, "Pos", pos)
		WireLib.TriggerOutput(self, "Pos X", pos.x)
		WireLib.TriggerOutput(self, "Pos Y", pos.y)
		WireLib.TriggerOutput(self, "Pos Z", pos.z)
	end

	if (self.out_vel) then
		WireLib.TriggerOutput(self, "Vel", vel)
		WireLib.TriggerOutput(self, "Vel X", vel.x)
		WireLib.TriggerOutput(self, "Vel Y", vel.y)
		WireLib.TriggerOutput(self, "Vel Z", vel.z)
	end

	if (self.out_ang) then
		WireLib.TriggerOutput(self, "Ang", ang)
		WireLib.TriggerOutput(self, "Ang Pitch", ang.p)
		WireLib.TriggerOutput(self, "Ang Yaw", ang.y)
		WireLib.TriggerOutput(self, "Ang Roll", ang.r)
	end

	if (self.out_col) then
		WireLib.TriggerOutput(self, "Col RGB", Vector(col.r, col.g, col.b))
		WireLib.TriggerOutput(self, "Col R", col.r)
		WireLib.TriggerOutput(self, "Col G", col.g)
		WireLib.TriggerOutput(self, "Col B", col.b)
		WireLib.TriggerOutput(self, "Col A", col.a)
	end

	if (self.out_sid) then
		WireLib.TriggerOutput(self, "SteamID", sid)
	end

	if (self.out_uid) then
		WireLib.TriggerOutput(self, "UniqueID", uid)
	end

	if (self.out_eid) then
		WireLib.TriggerOutput(self, "EntID", ent:EntIndex())
		WireLib.TriggerOutput(self, "Entity", ent)
	end

	if (self.out_hnrm and hnrm) then
		WireLib.TriggerOutput(self, "HitNormal", hnrm)
		WireLib.TriggerOutput(self, "HitNormal X", hnrm.x)
		WireLib.TriggerOutput(self, "HitNormal Y", hnrm.y)
		WireLib.TriggerOutput(self, "HitNormal Z", hnrm.z)
	end

	if (val ~= nil and #val > 0 and self.Inputs.SelectValue.Value <= #val) then
		WireLib.TriggerOutput(self, "Val", val[self.Inputs.SelectValue.Value])
		WireLib.TriggerOutput(self, "ValSize", #val)
	else
		WireLib.TriggerOutput(self, "Val", 0)
		WireLib.TriggerOutput(self, "ValSize", 0)
	end
	WireLib.TriggerOutput(self, "RangerData", trace)

end

duplicator.RegisterEntityClass("gmod_wire_ranger", WireLib.MakeWireEnt, "Data", "range", "default_zero", "show_beam", "ignore_world", "trace_water", "out_dist", "out_pos", "out_vel", "out_ang", "out_col", "out_val", "out_sid", "out_uid", "out_eid", "out_hnrm", "hires")
