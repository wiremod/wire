AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Ranger"
ENT.WireDebugName = "Ranger"
ENT.WantsTranslucency = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "BeamLength")
	self:NetworkVar("Bool", 0, "ShowBeam")
	self:NetworkVar("Bool", 1, "TraceWater")
	self:NetworkVar("Float", 1, "SkewX")
	self:NetworkVar("Float", 2, "SkewY")
	self:NetworkVar("Vector", 0, "Target")
end

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, { "X", "Y", "SelectValue", "Length", "Target [VECTOR]", "Ignore (Adds all specified entities to the ranger's filter.\nKeep in mind that this filtering is not synced to the client and is therefore not visible in the ranger's beam.) [ARRAY]" })
	WireLib.CreateOutputs(self, { "Dist" })
	self.hires = false
end

function ENT:Setup(range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hires)
	-- For dupe support
	local tab = self:GetTable()
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
	self.hires = hires

	if range then tab.SetBeamLength(self, math.min(range, 65536)) end
	if show_beam ~= nil then tab.SetShowBeam(self, show_beam) end
	if trace_water ~= nil then tab.SetTraceWater(self, trace_water) end

	local onames, otypes = {}, {}

	local function add(...)
		local args = { ... }

		for i = 1, #args, 2 do
			table.insert(onames, args[i])
			table.insert(otypes, args[i + 1])
		end
	end

	if out_dist then
		add("Dist", "NORMAL")
	end

	if out_pos then
		add("Pos", "VECTOR", "Pos X", "NORMAL", "Pos Y", "NORMAL", "Pos Z", "NORMAL")
	end

	if out_vel then
		add("Vel", "VECTOR", "Vel X","NORMAL", "Vel Y", "NORMAL", "Vel Z", "NORMAL")
	end

	if out_ang then
		add("Ang", "ANGLE", "Ang Pitch", "NORMAL", "Ang Yaw", "NORMAL", "Ang Roll", "NORMAL")
	end

	if out_col then
		add("Col RGB", "VECTOR", "Col R","NORMAL", "Col G", "NORMAL", "Col B", "NORMAL", "Col A", "NORMAL")
	end

	if out_val then
		add("Val","NORMAL","ValSize","NORMAL")
	end

	if out_sid then
		add("SteamID", "STRING")
	end

	if out_uid then
		add("UniqueID", "NORMAL")
	end

	if out_eid then
		add("EntID", "NORMAL", "Entity", "ENTITY")
	end

	if out_hnrm then
		add("HitNormal", "VECTOR", "HitNormal X", "NORMAL", "HitNormal Y", "NORMAL", "HitNormal Z", "NORMAL")
	end

	add("RangerData", "RANGER")
	WireLib.AdjustSpecialOutputs(self, onames, otypes)

	self:TriggerOutput(0, Vector(0, 0, 0), Vector(0, 0, 0), Angle(0, 0, 0), Color(255, 255, 255), nil, "", 0, NULL, Vector(0, 0, 0), nil, tab)
end

function ENT:TriggerInput(name, value)
	if name == "X" then
		self:SetSkewX(value)
	elseif name == "Y" then
		self:SetSkewY(value)
	elseif name == "Length" then
		self:SetBeamLength(math.min(value, 64000))
	elseif name == "Target" then
		self:SetTarget(value)
	elseif name == "Ignore" then
		local ignore = { self }
		self.ignore = ignore

		for _, ent in ipairs(value) do
			if isentity(ent) and ent:IsValid() then
				table.insert(ignore, ent)
			end
		end
	end
end

function ENT:Think()
	BaseClass.Think(self)

	local tab = self:GetTable()
	local trace_output = tab.TraceOutput

	if not trace_output then
		trace_output = {}
		tab.TraceOutput = trace_output
	end

	local tracedata = {}
	tracedata.output = tab.TraceOutput

	local selfpos = self:GetPos()
	tracedata.start = selfpos

	local inputs = tab.Inputs
	local beamlength = tab.GetBeamLength(self)

	if inputs.Target.Value ~= vector_origin then
		local endpos = self:GetTarget()
		endpos:Sub(selfpos)
		endpos:Normalize()
		endpos:Mul(beamlength)
		endpos:Add(selfpos)
		tracedata.endpos = endpos
	elseif inputs.X.Value == 0 and inputs.Y.Value == 0 then
		local endpos = self:GetUp()
		endpos:Mul(beamlength)
		endpos:Add(selfpos)
		tracedata.endpos = endpos
	else
		local skew = Vector(inputs.X.Value, inputs.Y.Value, 1)
		skew:Mul(beamlength / skew:Length())

		local x, y, z = skew:Unpack()

		local beam_x = self:GetRight()
		beam_x:Mul(x)

		local beam_y = self:GetForward()
		beam_y:Mul(y)

		local beam_z = self:GetUp()
		beam_z:Mul(z)

		beam_x:Add(beam_y)
		beam_x:Add(beam_z)
		beam_x:Add(selfpos)

		tracedata.endpos = beam_x
	end

	tracedata.filter = tab.ignore or { self }
	if tab.trace_water then tracedata.mask = -1 end

	local trace = util.TraceLine(tracedata)
	trace.RealStartPos = tracedata.start

	local dist, pos, vel, ang, col, ent, sid, uid, val, hnrm

	if trace.Hit then
		dist = trace.Fraction * beamlength
		pos = trace.HitPos
		hnrm = trace.HitNormal
		ent = trace.Entity

		if ent:IsValid() then
			vel = ent:GetVelocity()
			ang = ent:GetAngles()
			col = ent:GetColor()

			if (tab.out_sid or tab.out_uid) and ent:IsPlayer() then
				sid = ent:SteamID()
				uid = ent:UniqueID()
			end

			if tab.out_val and tab.Outputs then
				local i = 1
				val = {}

				for _, output in pairs(tab.Outputs) do
					if output.Value ~= nil and isnumber(output.Value) then
						val[i] = output.Value
						i = i + 1
					end
				end
			end
		else
			vel = Vector(0, 0, 0)
			ang = Angle(0, 0, 0)
			col = Color(255, 255, 255)
			sid = ""
			uid = 0

			if tab.ignore_world then
				if trace.HitWorld then
					if tab.default_zero then
						dist = 0
					else
						dist = beamlength
					end

					pos = Vector(0, 0, 0)
				end
			end
		end
	else
		pos = Vector(0, 0, 0)
		vel = Vector(0, 0, 0)
		ang = Angle(0, 0, 0)
		col = Color(255, 255, 255)
		ent = NULL
		sid = ""
		uid = 0
		hnrm = Vector(0, 0, 0)

		if tab.default_zero then
			dist = 0
		else
			dist = beamlength
		end
	end

	tab.TriggerOutput(self, dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace, tab)

	if tab.OverlayDataRequired then
		local txt = "Max Range: " .. beamlength
		if tab.out_dist then txt = txt .. "\nRange = " .. math.Round(dist, 3) end
		if tab.out_pos then txt = txt .. string.format("\nPosition = %s, %s, %s", math.Round(pos.x, 3), math.Round(pos.y, 3), math.Round(pos.z, 3)) end
		if tab.out_vel then txt = txt .. string.format("\nVelocity = %s, %s, %s", math.Round(vel.x, 3), math.Round(vel.y, 3), math.Round(vel.z, 3)) end
		if tab.out_ang then txt = txt .. string.format("\nAngles = %s, %s, %s", math.Round(ang.pitch, 3), math.Round(ang.yaw, 3), math.Round(ang.roll, 3)) end
		if tab.out_col then txt = txt .. string.format("\nColor = %s, %s, %s, %s", math.Round(col.r), math.Round(col.g), math.Round(col.b), math.Round(col.a)) end
		if tab.out_val then txt = txt .. string.format("\nValue = %s ValSize = %s", math.Round(tab.Outputs["Val"].Value or 0, 3), val and #val or 0) end
		if tab.out_sid then txt = txt .. "\nSteamID = " .. (sid or "") end
		if tab.out_uid then txt = txt .. "\nUniqueID = " .. (uid or 0) end
		if tab.out_eid then txt = txt .. "\nEntID = " .. ent:EntIndex() end
		if tab.out_hnrm then txt = txt .. string.format("\nHitNormal = %s, %s, %s", math.Round(hnrm.x, 3), math.Round(hnrm.y, 3), math.Round(hnrm.z, 3)) end
		tab.OverlayDataRequired = nil
		tab.SetOverlayText(self, txt)
	end

	if tab.hires then
		self:NextThink(CurTime())
	else
		self:NextThink(CurTime() + 0.04)
	end

	return true
end

function ENT:PrepareOverlayData()
	self.OverlayDataRequired = true
end

function ENT:TriggerOutput(dist, pos, vel, ang, col, val, sid, uid, ent, hnrm, trace, tab)
	if tab.out_dist then
		WireLib.TriggerOutput(self, "Dist", dist)
	end

	if tab.out_pos then
		local x, y, z = pos:Unpack()
		WireLib.TriggerOutput(self, "Pos", pos)
		WireLib.TriggerOutput(self, "Pos X", x)
		WireLib.TriggerOutput(self, "Pos Y", y)
		WireLib.TriggerOutput(self, "Pos Z", z)
	end

	if tab.out_vel then
		local x, y, z = vel:Unpack()
		WireLib.TriggerOutput(self, "Vel", vel)
		WireLib.TriggerOutput(self, "Vel X", x)
		WireLib.TriggerOutput(self, "Vel Y", y)
		WireLib.TriggerOutput(self, "Vel Z", z)
	end

	if tab.out_ang then
		local p, y, r = ang:Unpack()
		WireLib.TriggerOutput(self, "Ang", ang)
		WireLib.TriggerOutput(self, "Ang Pitch", p)
		WireLib.TriggerOutput(self, "Ang Yaw", y)
		WireLib.TriggerOutput(self, "Ang Roll", r)
	end

	if tab.out_col then
		WireLib.TriggerOutput(self, "Col RGB", Vector(col.r, col.g, col.b))
		WireLib.TriggerOutput(self, "Col R", col.r)
		WireLib.TriggerOutput(self, "Col G", col.g)
		WireLib.TriggerOutput(self, "Col B", col.b)
		WireLib.TriggerOutput(self, "Col A", col.a)
	end

	if tab.out_sid then
		WireLib.TriggerOutput(self, "SteamID", sid)
	end

	if tab.out_uid then
		WireLib.TriggerOutput(self, "UniqueID", uid)
	end

	if tab.out_eid then
		WireLib.TriggerOutput(self, "EntID", ent:EntIndex())
		WireLib.TriggerOutput(self, "Entity", ent)
	end

	if tab.out_hnrm then
		local x, y, z = hnrm:Unpack()
		WireLib.TriggerOutput(self, "HitNormal", hnrm)
		WireLib.TriggerOutput(self, "HitNormal X", x)
		WireLib.TriggerOutput(self, "HitNormal Y", y)
		WireLib.TriggerOutput(self, "HitNormal Z", z)
	end

	if val and #val > 0 and tab.Inputs.SelectValue.Value <= #val then
		WireLib.TriggerOutput(self, "Val", val[tab.Inputs.SelectValue.Value])
		WireLib.TriggerOutput(self, "ValSize", #val)
	else
		WireLib.TriggerOutput(self, "Val", 0)
		WireLib.TriggerOutput(self, "ValSize", 0)
	end

	WireLib.TriggerOutput(self, "RangerData", trace)
end

duplicator.RegisterEntityClass("gmod_wire_ranger", WireLib.MakeWireEnt, "Data", "range", "default_zero", "show_beam", "ignore_world", "trace_water", "out_dist", "out_pos", "out_vel", "out_ang", "out_col", "out_val", "out_sid", "out_uid", "out_eid", "out_hnrm", "hires")
