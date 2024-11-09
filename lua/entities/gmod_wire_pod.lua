AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName       = "Wire Pod Controller"
ENT.WireDebugName	= "Pod Controller"

if CLIENT then
	local hideHUD = 0
	local firstTime = true
	local firstTimeCursor = true
	local HUDHidden = false
	local savedHooks = nil
	local toolgunHUDFunc = nil
	local function blank() end

	net.Receive("wire_pod_hud", function()
		hideHUD = net.ReadUInt(2)
		if hideHUD > 0 and not HUDHidden then
			local ply = LocalPlayer()
			HUDHidden = true

			if firstTime then
				ply:ChatPrint("The owner of this vehicle has hidden your hud using a pod controller. If it gets stuck this way, use the console command 'wire_pod_hud_show' to forcibly enable it again.")
				firstTime = false
			end

			-- Hide toolgun HUD
			local toolgun = ply:GetWeapon("gmod_tool")
			if IsValid(toolgun) then
				toolgunHUDFunc = toolgun.DrawHUD
				toolgun.DrawHUD = blank
			end

			-- Hide all HUDPaints except for EGP HUD
			local hooks = hook.GetTable()["HUDPaint"]
			savedHooks = table.Copy(hooks)
			for k in pairs(hooks) do
				if hideHUD > 2 or k ~= "EGP_HUDPaint" then
					hook.Add("HUDPaint", k, blank)
				end
			end

			-- Hide other HUD elements
			hook.Add("DrawDeathNotice", "wire_pod_drawdeathnotice", function() return false end)
			hook.Add("HUDDrawTargetID", "wire_pod_huddrawtargetid", function() return false end)
			hook.Add("HUDShouldDraw", "wire_pod_hudshoulddraw", function(name)
				local ply = LocalPlayer()

				if hideHUD > 0 then
					if ply:InVehicle() then
						-- Allow crosshair (it can be hidden using the other input) and CHudGMod (for the EGP HUDPaint to pass through). Hide the chat if the input is higher than 1
						if name ~= "CHudCrosshair" and name ~= "CHudGMod" and (hideHUD > 1 and name == "CHudChat" or name ~= "CHudChat")  then return false end
					else
						hideHUD = 0
					end
				else
					-- Restore toolgun HUD
					local toolgun = ply:GetWeapon("gmod_tool")

					if IsValid(toolgun) and toolgun.DrawHUD == blank and toolgunHUDFunc ~= nil then
						toolgun.DrawHUD = toolgunHUDFunc
					end
					toolgunHUDFunc = nil

					-- Restore HUDPaints and other HUD elements
					local hooks = hook.GetTable()["HUDPaint"]
					for k,v in pairs(hooks) do
						if v == blank and savedHooks ~= nil and savedHooks[k] ~= nil then
							hook.Add("HUDPaint", k, savedHooks[k])
						end
					end
					savedHooks = nil

					hook.Remove("HUDShouldDraw", "wire_pod_hudshoulddraw")
					hook.Remove("DrawDeathNotice", "wire_pod_drawdeathnotice")
					hook.Remove("HUDDrawTargetID", "wire_pod_huddrawtargetid")
					HUDHidden = false
				end
			end)
		end
	end)

	concommand.Add("wire_pod_hud_show", function(ply, cmd, args)
		hideHUD = 0
	end)

	net.Receive("wire_pod_cursor", function()
		local b = net.ReadBool()
		local pnl = vgui.GetWorldPanel()
		pnl:SetWorldClicker(b) -- This allows the cursor to move the player's eye
		if b then RestoreCursorPosition() else RememberCursorPosition() end
		gui.EnableScreenClicker(b)

		if b and firstTimeCursor then
			LocalPlayer():ChatPrint("The owner of this vehicle has enabled your cursor using a pod controller. If it gets stuck this way, use the console command 'wire_pod_cursor_disable' to forcibly disable it.")
			firstTimeCursor = false
		end
	end)

	concommand.Add("wire_pod_cursor_disable", function(ply, cmd, args)
		local pnl = vgui.GetWorldPanel()
		pnl:SetWorldClicker(false)
		gui.EnableScreenClicker(false)
	end)

	return -- No more client
end

-- Server

util.AddNetworkString("wire_pod_hud")
util.AddNetworkString("wire_pod_cursor")

local pods = ents.FindByClass("gmod_wire_pod") or {}
local allowLockInsideVehicle = CreateConVar("wire_pod_allowlockinsidevehicle", "0", FCVAR_ARCHIVE, "Allow or disallow people to be locked inside of vehicles")
local PlayerBindDownHook, PlayerBindUpHook, Wire_Pod_EnterVehicle, Wire_Pod_ExitVehicle, Wire_Pod_CanExitVehicle

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	table.insert(pods, self)
	if #pods == 1 then
		hook.Add("PlayerBindDown", "gmod_wire_pod", PlayerBindDownHook)
		hook.Add("PlayerBindUp", "gmod_wire_pod", PlayerBindUpHook)
		hook.Add("PlayerEnteredVehicle", "Wire_Pod_EnterVehicle", Wire_Pod_EnterVehicle)
		hook.Add("PlayerLeaveVehicle", "Wire_Pod_ExitVehicle", Wire_Pod_ExitVehicle)
		hook.Add("CanExitVehicle","Wire_Pod_CanExitVehicle", Wire_Pod_CanExitVehicle)
	end

	local outputs = {
		-- Keys
		"W", "A", "S", "D", "Mouse1", "Mouse2",
		"R", "Space", "Shift", "Zoom", "Alt", "Duck", "Noclip",
		"TurnLeftKey (Not bound to a key by default. Bind a key to '+left' to use.\nOutside of a vehicle, makes the player's camera rotate left.)",
		"TurnRightKey (Not bound to a key by default. Bind a key to '+right' to use.\nOutside of a vehicle, makes the player's camera rotate right.)",

		-- Clientside keys
		"PrevWeapon (Usually bound to the mouse scroller, so will only be active for a single tick.)",
		"NextWeapon (Usually bound to the mouse scroller, so will only be active for a single tick.)",
		"Light",

		-- Aim Position
		"X", "Y", "Z", "AimPos [VECTOR]",
		"Distance", "Bearing (If the 'Relative' input is non-zero, this will be relative to the vehicle.)", "Elevation (If the 'Relative' input is non-zero, this will be relative to the vehicle.)",

		-- Other info
		"ThirdPerson", "Team", "Health", "Armor",

		-- Active
		"Active",

		-- Entity
		"Entity [ENTITY]",

		-- Driver
		"Driver [ENTITY]"
	}

	local inputs = {
		"Lock", "Terminate", "Strip Weapons", "Eject",
		"Disable", "Crosshairs", "Brake", "Allow Buttons",
		"Relative (If this is non-zero, the 'Bearing' and 'Elevation' outputs will be relative to the vehicle.)",
		"Damage Health (Damages the driver's health.)", "Damage Armor (Damages the driver's armor.)", "Hide Player", "Hide HUD", "Show Cursor",
		"Vehicle [ENTITY]"
	}

	self.Inputs = WireLib.CreateInputs(self, inputs)
	self.Outputs = WireLib.CreateOutputs(self, outputs)

	self:SetLocked(false)
	self:SetHidePlayer(false)
	self:SetHideHUD(0)
	self:SetShowCursor(0)
	self.HidePlayerVal = false
	self.Crosshairs = false
	self.Disable = false
	self.AllowButtons = false
	self.Relative = false
	self.MouseDown = false

	self:SetActivated(false)

	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)

	self:SetOverlayText("Pod Controller")
end

-- Accessor funcs for certain functions
function ENT:SetLocked(b)
	local pod = self:GetPod()
	if not pod or self.Locked == b then return end

	self.Locked = b
	pod:Fire(b and "Lock" or "Unlock", "1", 0)
end

function ENT:SetActivated(b)
	if self.Activated == b then return end

	self:ColorByLinkStatus(b and self.LINK_STATUS_ACTIVE or self.LINK_STATUS_LINKED)

	self.Activated = b
	WireLib.TriggerOutput(self, "Active", b and 1 or 0)
end

function ENT:HidePlayer(b)
	local ply = self:GetPly()
	if not ply then return end

	local c = ply:GetColor()
	if b then
		self.OldPlyAlpha = c.a
		c.a = 0
	else
		c.a = self.OldPlyAlpha or 255
		self.OldPlyAlpha = nil
	end
	ply:SetColor(c)
	ply:SetRenderMode(c.a ~= 255 and RENDERMODE_TRANSALPHA or RENDERMODE_NORMAL)
end

function ENT:SetHidePlayer(b)
	if self.HidePlayer == b then return end

	self.HidePlayerVal = b

	if self:GetPly() then
		self:HidePlayer(b)
	end
end

function ENT:LinkEnt(pod)
	pod = WireLib.GetClosestRealVehicle(pod, self:GetPos(), self:GetPlayer())

	-- if pod is still not a vehicle even after all of the above, then error out
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	if not WireLib.CanTool(self:GetPlayer(), pod, "wire_pod") then return false, "You do not have permission to access this vehicle" end

	self:SetPod(pod)
	WireLib.SendMarks(self, { pod })
	return true
end
function ENT:UnlinkEnt()
	if IsValid(self.Pod) then
		self.Pod:RemoveCallOnRemove("wire_pod_remove")
	end
	self:SetShowCursor(0)
	self.Pod = nil
	self:PlayerExited()
	WireLib.SendMarks(self, {})
	WireLib.TriggerOutput(self, "Entity", NULL)
	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)
	return true
end
function ENT:OnRemove()
	self:UnlinkEnt()
	table.RemoveByValue(pods, self)
	if #pods == 0 then
		hook.Remove("PlayerBindDown", "gmod_wire_pod")
		hook.Remove("PlayerBindUp", "gmod_wire_pod")
		hook.Remove("PlayerEnteredVehicle", "Wire_Pod_EnterVehicle")
		hook.Remove("PlayerLeaveVehicle", "Wire_Pod_ExitVehicle")
		hook.Remove("CanExitVehicle","Wire_Pod_CanExitVehicle")
	end
end

function ENT:GetPod()
	local pod = self.Pod
	if not IsValid(pod) then return end
	return pod
end
function ENT:SetPod(pod)
	if pod and pod:IsValid() and not pod:IsVehicle() then return false end

	if self:GetPly() then
		self:PlayerExited()
	else
		self:ColorByLinkStatus(IsValid(pod) and self.LINK_STATUS_LINKED or self.LINK_STATUS_UNLINKED)
	end

	self.Pod = pod
	WireLib.TriggerOutput(self, "Entity", pod)

	if not IsValid(pod) then return true end

	pod:CallOnRemove("wire_pod_remove", function()
		if self:IsValid() then self:UnlinkEnt(pod) end
	end)

	if IsValid(pod:GetDriver()) then
		self:PlayerEntered(pod:GetDriver())
	end

	return true
end

function ENT:GetPly()
	local ply = self.Ply
	if not IsValid(ply) then return end
	return ply
end
function ENT:SetPly(ply)
	if IsValid(ply) and not ply:IsPlayer() then return false end
	self.Ply = ply
	WireLib.TriggerOutput(self, "Driver", ply)
	return true
end

function ENT:SetHideHUD(val)
	local ply = self:GetPly()
	self.HideHUD = val

	if ply and self:GetPod() then -- If we have a player, we SHOULD always have a pod as well, but just in case.
		net.Start("wire_pod_hud")
			net.WriteUInt(self.HideHUD, 2)
		net.Send(ply)
	end
end
function ENT:GetHideHUD() return self.HideHUD end

function ENT:NetShowCursor(val, ply)
	ply = ply or self:GetPly()
	if not ply then return end

	net.Start("wire_pod_cursor")
		net.WriteBool(val or self.ShowCursor)
	net.Send(ply)
end
function ENT:SetShowCursor(val)
	local ply = self:GetPly()
	self.ShowCursor = val

	if ply and self:GetPod() then
		self:NetShowCursor(val, ply)
	end
end
function ENT:GetShowCursor() return self.ShowCursor end

local bindingToOutput = {
	["forward"] = "W",
	["moveleft"] = "A",
	["back"] = "S",
	["moveright"] = "D",
	["left"] = "TurnLeftKey",
	["right"] = "TurnRightKey",

	["jump"] = "Space",
	["noclip"] = "Noclip",
	["speed"] = "Shift",
	["zoom"] = "Zoom",
	["walk"] = "Alt",
	["duck"] = "Duck",

	["attack"] = "Mouse1",
	["attack2"] = "Mouse2",
	["reload"] = "R",

	["invprev"] = "PrevWeapon",
	["invnext"] = "NextWeapon",
	["impulse 100"] = "Light",
}

function PlayerBindDownHook(player, binding)
	if not binding then return end
	local output = bindingToOutput[binding]
	if not output then return end

	for _, pod in ipairs(pods) do
		if pod:GetPly() == player and not pod.Disable then
			WireLib.TriggerOutput(pod, output, 1)
		end
	end
end

function PlayerBindUpHook(player, binding)
	if not binding then return end
	local output = bindingToOutput[binding]
	if not output then return end

	for _, pod in ipairs(pods) do
		if pod:GetPly() == player and not pod.Disable then
			WireLib.TriggerOutput(pod, output, 0)
		end
	end
end

-- Helper function for ejecting players using the RC remote
function ENT:RCEject()
	self.RC:Off()
end

function ENT:TriggerInput(name, value)
	if name == "Lock" then
		if self.RC then return end
		if not self:GetPod() then return end
		self:SetLocked(value ~= 0)
	elseif name == "Terminate" then
		local ply = self:GetPly()
		if value == 0 or not ply then return end
		if self.RC then self:RCEject(ply) end
		ply:Kill()
	elseif name == "Strip Weapons" then
		local ply = self:GetPly()
		if value == 0 or not ply then return end
		if self.RC then
			ply:ChatPrint("Your control has been terminated, and your weapons stripped!")
			self:RCEject(ply)
		else
			ply:ChatPrint("Your weapons have been stripped!")
		end
		ply:StripWeapons()
	elseif name == "Eject" then
		local ply = self:GetPly()
		if value == 0 or not ply then return end
		if self.RC then
			self:RCEject(ply)
		else
			ply:ExitVehicle()
		end
	elseif name == "Disable" then
		self.Disable = value ~= 0

		if self.Disable then
			for _, output in pairs(bindingToOutput) do
				WireLib.TriggerOutput(self, output, 0)
			end
		end
	elseif name == "Crosshairs" then
		self.Crosshairs = value ~= 0
		local ply = self:GetPly()
		if not ply then return end
		if self.Crosshairs then
			ply:CrosshairEnable()
		else
			ply:CrosshairDisable()
		end
	elseif name == "Brake" then
		local pod = self:GetPod()
		if not pod then return end
		if value ~= 0 then
			pod:Fire("TurnOff", "1", 0)
			pod:Fire("HandBrakeOn", "1", 0)
		else
			pod:Fire("TurnOn", "1", 0)
			pod:Fire("HandBrakeOff", "1", 0)
		end
	elseif name == "Damage Health" then
		local ply = self:GetPly()
		if not ply or value <= 0 then return end
		ply:TakeDamage(math.min(value, 100))
	elseif name == "Damage Armor" then
		local ply = self:GetPly()
		if not ply or value <= 0 then return end
		local dmg = math.max(ply:Armor() - value, 0)
		ply:SetArmor(dmg)
	elseif name == "Allow Buttons" then
		self.AllowButtons = value ~= 0
	elseif name == "Relative" then
		self.Relative = value ~= 0
	elseif name == "Hide Player" then
		self:SetHidePlayer(value ~= 0)
	elseif name == "Hide HUD" then
		self:SetHideHUD( value )
	elseif name == "Show Cursor" then
		self:SetShowCursor(value)
	elseif name == "Vehicle" then
		if not IsValid(value) then return end -- Only link if the input is valid. That way, it won't be unlinked if the wire is disconnected
		if value:IsPlayer() then return end
		if value:IsNPC() then return end

		self:LinkEnt(value)
	end
end

local function fixupangle(angle)
	if angle > 180 then angle = angle - 360 end
	if angle < -180 then angle = angle + 360 end
	return angle
end

-- Caching the value to be changed in order to avoid attempting another output trigger (which is more expensive)
local function recacheOutput(entity, selfTbl, oname, value)
	if selfTbl.Outputs[oname].Value == value then return end
	WireLib.TriggerOutput(entity, oname, value)
end

local ent_GetTable = FindMetaTable("Entity").GetTable

function ENT:Think()
	local selfTbl = ent_GetTable(self)
	local ply = selfTbl.Ply

	if IsValid(ply) and selfTbl.Activated then
		local pod = selfTbl.Pod

		-- Tracing
		local shootPos = ply:GetShootPos()
		local aimVector = ply:GetAimVector()
		local trace = util.TraceLine({ start = shootPos, endpos = shootPos + aimVector * 9999999999, filter = { ply, pod } })
		local distance
		local hitPos = trace.HitPos
		if IsValid(pod) then distance = hitPos:Distance(pod:GetPos()) else distance = hitPos:Distance(shootPos) end

		if trace.Hit then
			-- Position
			recacheOutput(self, selfTbl, "X", hitPos.x)
			recacheOutput(self, selfTbl, "Y", hitPos.y)
			recacheOutput(self, selfTbl, "Z", hitPos.z)
			recacheOutput(self, selfTbl, "AimPos", hitPos)
			recacheOutput(self, selfTbl, "Distance", distance)
			selfTbl.VPos = hitPos

			-- Bearing & Elevation
			local angle = aimVector:Angle()

			if selfTbl.Relative then
				local originalangle
				if selfTbl.RC then
					originalangle = selfTbl.RC.InitialAngle
				elseif IsValid(pod) then
					local attachment = pod:LookupAttachment("vehicle_driver_eyes")
					if attachment > 0 then
						originalangle = pod:GetAttachment(attachment).Ang
					else
						originalangle = pod:GetAngles()
					end
				end
				recacheOutput(self, selfTbl, "Bearing", fixupangle(angle.y - originalangle.y))
				recacheOutput(self, selfTbl, "Elevation", fixupangle(angle.p - originalangle.p))
			else
				recacheOutput(self, selfTbl, "Bearing", fixupangle(angle.y))
				recacheOutput(self, selfTbl, "Elevation", fixupangle(-angle.p))
			end
		else
			recacheOutput(self, selfTbl, "X", 0)
			recacheOutput(self, selfTbl, "Y", 0)
			recacheOutput(self, selfTbl, "Z", 0)
			recacheOutput(self, selfTbl, "AimPos", vector_origin)
			recacheOutput(self, selfTbl, "Bearing", 0)
			recacheOutput(self, selfTbl, "Elevation", 0)
			selfTbl.VPos = vector_origin
		end

		-- Button pressing
		if selfTbl.AllowButtons and distance < 82 then
			local button = trace.Entity
			local inAttack = ply:KeyDown(IN_ATTACK)
			local mouseDown = selfTbl.MouseDown

			if IsValid(button) and (inAttack and not mouseDown) and not button:IsVehicle() and button.Use then
				-- Generic support (Buttons, Dynamic Buttons, Levers, EGP screens, etc)
				selfTbl.MouseDown = true
				if hook.Run("PlayerUse", ply, button) ~= false then
					button:Use(ply, self, USE_ON, 0)
				end
			elseif not inAttack and mouseDown then
				selfTbl.MouseDown = false
			end
		end

		-- Other info
		recacheOutput(self, selfTbl, "Health", ply:Health())
		recacheOutput(self, selfTbl, "Armor", ply:Armor())
		if IsValid(pod) then recacheOutput(self, selfTbl, "ThirdPerson", pod:GetThirdPersonMode() and 1 or 0) end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:PlayerEntered(ply, RC)
	if self:GetPly() then return end
	self:SetPly(ply)

	self.RC = RC

	if self.Crosshairs then
		ply:CrosshairEnable()
	end

	local pod = self:GetPod()

	if self.HideHUD > 0 and pod then
		net.Start("wire_pod_hud")
			net.WriteUInt(self.HideHUD, 2)
		net.Send(ply)
	end

	if self.ShowCursor > 0 and pod then
		self:NetShowCursor(self.ShowCursor, ply)
	end

	if self.HidePlayerVal then
		self:HidePlayer(true)
	end

	WireLib.TriggerOutput(self, "Team", ply:Team())

	self:SetActivated(true)
end

function ENT:PlayerExited()
	local ply = self:GetPly()

	if not ply then return end

	self:HidePlayer(false)

	self:NetShowCursor(0, ply)

	ply:CrosshairEnable()

	self:SetActivated(false)

	for _, output in pairs(bindingToOutput) do
		WireLib.TriggerOutput(self, output, 0)
	end

	WireLib.TriggerOutput(self, "X", 0)
	WireLib.TriggerOutput(self, "Y", 0)
	WireLib.TriggerOutput(self, "Z", 0)
	WireLib.TriggerOutput(self, "AimPos", vector_origin)

	WireLib.TriggerOutput(self, "Distance", 0)
	WireLib.TriggerOutput(self, "Bearing", 0)
	WireLib.TriggerOutput(self, "Elevation", 0)

	WireLib.TriggerOutput(self, "ThirdPerson", 0)
	WireLib.TriggerOutput(self, "Team", 0)
	WireLib.TriggerOutput(self, "Health", 0)
	WireLib.TriggerOutput(self, "Armor", 0)

	self:SetPly(nil)
end

function Wire_Pod_EnterVehicle(ply, vehicle)
	for _, v in ipairs(pods) do
		local pod = v:GetPod()
		if pod == vehicle and ply:GetVehicle() == pod then
			v:PlayerEntered(ply)
		end
	end
end

function Wire_Pod_ExitVehicle(ply, vehicle)
	for _, v in ipairs(pods) do
		local pod = v:GetPod()
		if pod and pod == vehicle then
			v:PlayerExited()
		end
	end
end

function Wire_Pod_CanExitVehicle(vehicle, ply)
	local allowLock = allowLockInsideVehicle:GetBool()

	for _, v in ipairs(pods) do
		local pod = v:GetPod()
		if pod and pod == vehicle and v.Locked and allowLock then
			return false
		end
	end
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end
function ENT:GetBeaconVelocity(sensor)
	local pod = self:GetPod()
	return pod and pod:GetVelocity() or self:GetVelocity()
end

--Duplicator support to save pod link (TAD2020)
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	local pod = self:GetPod()
	if pod and not self.RC then
		info.pod = pod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local pod = GetEntByID(info.pod)
	if IsValid(pod) then
		self:LinkEnt(pod)
	end
end

function ENT:Use( User, caller )
	if User ~= self:GetPlayer() then return end
	if not hook.Run("PlayerGiveSWEP", User, "remotecontroller", weapons.Get("remotecontroller")) then return end
	User:PrintMessage(HUD_PRINTTALK, "Hold down your use key for 2 seconds to get and link a Remote Controller.")
	timer.Create("pod_use_" .. self:EntIndex(), 2, 1, function()
		if not IsValid(User) or not User:IsPlayer() then return end
		if not User:KeyDown(IN_USE) then return end
		if not User:GetEyeTrace().Entity or User:GetEyeTrace().Entity ~= self then return end

		if not IsValid(User:GetWeapon("remotecontroller")) then
			if not hook.Run("PlayerGiveSWEP", User, "remotecontroller", weapons.Get("remotecontroller")) then return end
			User:Give("remotecontroller")
		end

		User:GetWeapon("remotecontroller").Linked = self
		User:PrintMessage(HUD_PRINTTALK, "You are now linked!")
		User:SelectWeapon("remotecontroller")
	end)
end

duplicator.RegisterEntityClass("gmod_wire_pod", WireLib.MakeWireEnt, "Data")
duplicator.RegisterEntityClass("gmod_wire_adv_pod", WireLib.MakeWireEnt, "Data")
scripted_ents.Alias("gmod_wire_adv_pod", "gmod_wire_pod")
