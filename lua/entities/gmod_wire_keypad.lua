AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Keypad"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "DisplayText")
end

if CLIENT then
	local X = -50
	local Y = -100
	local W = 100
	local H = 200

	local keyposes = {
		{X + 5, Y + 100, 25, 25, -2.2, 3.45, 1.3, 0}, -- 1
		{X + 37.5, Y + 100, 25, 25, -0.6, 1.85, 1.3, 0}, -- 2
		{X + 70, Y + 100, 25, 25, 1.0, 0.25, 1.3, 0}, -- 3

		{X + 5, Y + 132.5, 25, 25, -2.2, 3.45, 2.9, -1.6}, -- 4
		{X + 37.5, Y + 132.5, 25, 25, -0.6, 1.85, 2.9, -1.6}, -- 5
		{X + 70, Y + 132.5, 25, 25, 1.0, 0.25, 2.9, -1.6}, -- 6

		{X + 5, Y + 165, 25, 25, -2.2, 3.45, 4.55, -3.3}, -- 7
		{X + 37.5, Y + 165, 25, 25, -0.6, 1.85, 4.55, -3.3}, -- 8
		{X + 70, Y + 165, 25, 25, 1.0, 0.25, 4.55, -3.3}, -- 9

		{X + 5, Y + 67.5, 40, 25, -2.2, 4.25, -0.3, 1.6}, -- abort
		{X + 55, Y + 67.5, 40, 25, 0.3, 1.65, -0.3, 1.6}, -- ok
	}

	surface.CreateFont("WireKeypad", {
		font = "Trebuchet MS",
		size = 24,
		weight = 400,
		antialias = true
	})

	surface.CreateFont("WireKeypad_Big", {
		font = "Trebuchet MS",
		size = 34,
		weight = 400,
		antialias = true
	})

	local color_red = Color(255, 0, 0)
	local color_green = Color(0, 255, 0)

	function ENT:Draw()
		self:DrawModel()

		local ply = LocalPlayer()
		local entpos = self:GetPos()
		if entpos:Distance(ply:GetShootPos()) > 512 then return end

		local ang = self:GetAngles()
		entpos = entpos + self:GetForward() * 1.05

		ang:RotateAroundAxis(ang:Right(), -90)
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 0)

		cam.Start3D2D(entpos, ang, 0.05)
			local trace = ply:GetEyeTrace()
			local pos = self:WorldToLocal(trace.HitPos)

			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(X - 5, Y - 5, W + 10, H + 10)

			surface.SetDrawColor(50, 75, 50)
			surface.DrawRect(X + 5, Y + 5, 90, 50)

			for k, v in ipairs(keyposes) do
				local text = k
				local textx = v[1] + 9
				local texty = v[2] + 4
				local x = (pos.y - v[5]) / (v[5] + v[6])
				local y = 1 - (pos.z + v[7]) / (v[7] + v[8])
				local highlight_current_key = highlight_key == k and highlight_until >= CurTime()

				if (k == 10) then
					text = "ABORT"
					textx = v[1] + 2
					texty = v[2] + 4

					surface.SetDrawColor(150, 25, 25)
				elseif (k == 11) then
					text = "OK"
					textx = v[1] + 12
					texty = v[2] + 5

					surface.SetDrawColor(25, 150, 25)
				else
					surface.SetDrawColor(150, 150, 150)
				end

				if highlight_current_key or (trace.Entity == self and x >= 0 and y >= 0 and x <= 1 and y <= 1) then
					if (k <= 9) then
						surface.SetDrawColor(200, 200, 200)
					elseif (k == 10) then
						surface.SetDrawColor(200, 50, 50)
					elseif (k == 11) then
						surface.SetDrawColor(50, 200, 50)
					end

					if ply:KeyDown(IN_USE) and not ply.WireKeyPad_Pressed and not highlight_current_key then
						net.Start("wire_keypad")
							net.WriteEntity(self)
							net.WriteUInt(k, 4)
						net.SendToServer()

						ply.WireKeyPad_Pressed = true
					end
				end

				surface.DrawRect(v[1], v[2], v[3], v[4])
				draw.DrawText(text, "Trebuchet18", textx, texty, color_black)
			end

			local Display = self:GetDisplayText()

			if Display == "y" then
				draw.DrawText("ACCESS", "WireKeypad", X + 17, Y + 7, color_green)
				draw.DrawText("GRANTED", "WireKeypad", X + 7, Y + 27, color_green)
			elseif Display == "n" then
				draw.DrawText("ACCESS", "WireKeypad", X + 17, Y + 7, color_red)
				draw.DrawText("DENIED", "WireKeypad", X + 19, Y + 27, color_red)
			else
				draw.DrawText(Display, "WireKeypad_Big", X + 17, Y + 10, color_white)
			end
		cam.End3D2D()
	end

	hook.Add("KeyRelease", "Keypad_KeyReleased", function(ply, key)
		ply.WireKeyPad_Pressed = false
	end)

	local binds = {
		["+gm_special 1"] = 1,
		["+gm_special 2"] = 2,
		["+gm_special 3"] = 3,
		["+gm_special 4"] = 4,
		["+gm_special 5"] = 5,
		["+gm_special 6"] = 6,
		["+gm_special 7"] = 7,
		["+gm_special 8"] = 8,
		["+gm_special 9"] = 9,
		["+gm_special 11"] = 11,
		["+gm_special 12"] = 10,
	}

	hook.Add("PlayerBindPress", "keypad_PlayerBindPress", function(ply, bind, pressed)
		if not pressed then return end

		local command = binds[bind]
		if not command then return end

		local ent = ply:GetEyeTraceNoCursor().Entity
		if not IsValid(ent) or ent:GetClass() ~= "gmod_wire_keypad" then return end

		net.Start("wire_keypad")
			net.WriteEntity(ent)
			net.WriteUInt(command, 4)
		net.SendToServer()

		highlight_key, highlight_until = command, CurTime() + 0.5

		return true
	end)

	return
end

util.AddNetworkString("wire_keypad")

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Outputs = WireLib.CreateOutputs(self, {"Valid", "Invalid"})
	self.CurrentNum = 0
end

function ENT:Setup(password, securemode)
	self.Password = password
	self.Secure = securemode
end

net.Receive("wire_keypad", function(len, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not ent.Password then return end

	if ent.CurrentNum == -1 then return end -- Display still shows ACCESS from a past success
	if ply:GetShootPos():Distance(ent:GetPos()) > 64 then return end

	local key = net.ReadUInt(4)

	if key == 10 then
		ent:SetDisplayText("")
		ent:EmitSound("buttons/button14.wav")

		ent.CurrentNum = 0
	elseif key == 11 or ent.CurrentNum > 999 then
		local access = ent.Password == util.CRC(ent.CurrentNum)

		if access then
			Wire_TriggerOutput(ent, "Valid", 1)
			ent:SetDisplayText("y")
			ent:EmitSound("buttons/button9.wav")
		else
			Wire_TriggerOutput(ent, "Invalid", 1)
			ent:SetDisplayText("n")
			ent:EmitSound("buttons/button8.wav")
		end

		ent.CurrentNum = -1

		timer.Simple(2, function()
			if IsValid(ent) then
				ent:SetDisplayText("")
				ent.CurrentNum = 0

				if access then
					Wire_TriggerOutput(ent, "Valid", 0)
				else
					Wire_TriggerOutput(ent, "Invalid", 0)
				end
			end
		end)
	else
		ent.CurrentNum = ent.CurrentNum * 10 + key

		if ent.Secure then
			ent:SetDisplayText(string.rep("*", string.len(ent.CurrentNum)))
		else
			ent:SetDisplayText(tostring(ent.CurrentNum))
		end

		ent:EmitSound("buttons/button15.wav")
	end
end)

duplicator.RegisterEntityClass("sent_keypad", WireLib.MakeWireEnt, "Data", "Pass", "secure")
duplicator.RegisterEntityClass("gmod_wire_keypad", WireLib.MakeWireEnt, "Data", "Password", "Secure")
scripted_ents.Alias("sent_keypad", "gmod_wire_keypad")
