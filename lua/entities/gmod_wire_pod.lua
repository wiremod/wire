AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Pod Controller"
ENT.WireDebugName	= "Pod Controller"
ENT.AllowLockInsideVehicle = CreateConVar( "wire_pod_allowlockinsidevehicle", "0", FCVAR_ARCHIVE, "Allow or disallow people to be locked inside of vehicles" )

if CLIENT then
	local hideHUD = 0
	local firstTime = true
	local firstTimeCursor = true
	local HUDHidden = false
	local savedHooks = nil
	local toolgunHUDFunc = nil
	local function blank() end

	usermessage.Hook( "wire pod hud", function( um )
		local vehicle = um:ReadEntity()
		if LocalPlayer():InVehicle() and LocalPlayer():GetVehicle() == vehicle then
			hideHUD = um:ReadShort()
			if hideHUD > 0 and not HUDHidden then
				HUDHidden = true
				if firstTime then
					LocalPlayer():ChatPrint( "The owner of this vehicle has hidden your hud using a pod controller. If it gets stuck this way, use the console command 'wire_pod_hud_show' to forcibly enable it again." )
					firstTime = false
				end
				--Hide toolgun HUD
				local toolgun = LocalPlayer():GetWeapon("gmod_tool")
				if IsValid(toolgun) then
					toolgunHUDFunc = toolgun.DrawHUD
					toolgun.DrawHUD = blank
				end
				--Hide all HUDPaints except for EGP HUD
				local hooks = hook.GetTable()["HUDPaint"]
				savedHooks = table.Copy(hooks)
				for k in pairs(hooks) do
					if hideHUD > 2 or k ~= "EGP_HUDPaint" then
						hook.Add( "HUDPaint", k, blank )
					end
				end
				--Hide other HUD elements
				hook.Add( "DrawDeathNotice", "Wire pod DrawDeathNotice", function() return false end)
				hook.Add( "HUDDrawTargetID", "Wire pod HUDDrawTargetID", function() return false end)
				hook.Add( "HUDShouldDraw", "Wire pod HUDShouldDraw", function( name )
					if hideHUD > 0 then
						if LocalPlayer():InVehicle() then
							--Allow crosshair (it can be hidden using the other input) and CHudGMod (for the EGP HUDPaint to pass through). Hide the chat if the input is higher than 1
							if name ~= "CHudCrosshair" and name ~= "CHudGMod" and (hideHUD > 1 and name == "CHudChat" or name ~= "CHudChat")  then return false end
						else
							hideHUD = 0
						end
					else
						--Restore toolgun HUD
						local toolgun = LocalPlayer():GetWeapon("gmod_tool")
						if IsValid(toolgun) and toolgun.DrawHUD == blank and toolgunHUDFunc ~= nil then
							toolgun.DrawHUD = toolgunHUDFunc
						end
						toolgunHUDFunc = nil
						--Restore HUDPaints and other HUD elements
						local hooks = hook.GetTable()["HUDPaint"]
						for k,v in pairs(hooks) do
							if v == blank and savedHooks ~= nil and savedHooks[k] ~= nil then
								hook.Add( "HUDPaint", k, savedHooks[k] )
							end
						end
						savedHooks = nil

						hook.Remove( "HUDShouldDraw", "Wire pod HUDShouldDraw")
						hook.Remove( "DrawDeathNotice", "Wire pod DrawDeathNotice")
						hook.Remove( "HUDDrawTargetID", "Wire pod HUDDrawTargetID")
						HUDHidden = false
					end
				end)
			end
		else
			hideHUD = 0
		end
	end)

	concommand.Add( "wire_pod_hud_show", function(ply,cmd,args)
		hideHUD = 0
	end)

	usermessage.Hook( "wire pod cursor", function( um )
		local vehicle = um:ReadEntity()
		if LocalPlayer():InVehicle() and LocalPlayer():GetVehicle() == vehicle then
			local b = um:ReadShort() ~= 0
			local pnl = vgui.GetWorldPanel()
			pnl:SetWorldClicker( b ) -- this allows the cursor to move the player's eye
			if b then RestoreCursorPosition() else RememberCursorPosition() end
			gui.EnableScreenClicker( b )

			if b and firstTimeCursor then
				LocalPlayer():ChatPrint( "The owner of this vehicle has enabled your cursor using a pod controller. If it gets stuck this way, use the console command 'wire_pod_cursor_disable' to forcibly disable it." )
				firstTimeCursor = false
			end
		end
	end)

	concommand.Add( "wire_pod_cursor_disable", function(ply,cmd,args)
		local pnl = vgui.GetWorldPanel()
		pnl:SetWorldClicker( false )
		gui.EnableScreenClicker( false )
	end)
	
	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	local outputs = {
		-- Keys
		"W", "A", "S", "D", "Mouse1", "Mouse2",
		"R", "Space", "Shift", "Zoom", "Alt", "TurnLeftKey", "TurnRightKey",

		-- Clientside keys
		"PrevWeapon", "NextWeapon", "Light",

		-- Aim Position
		"X", "Y", "Z", "AimPos [VECTOR]",
		"Distance", "Bearing", "Elevation",

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
		"Lock", "Terminate", "Strip weapons", "Eject",
		"Disable", "Crosshairs", "Brake", "Allow Buttons",
		"Relative", "Damage Health", "Damage Armor", "Hide Player", "Hide HUD", "Show Cursor",
		"Vehicle [ENTITY]"
	}

	self.Inputs = WireLib.CreateInputs( self, inputs )
	self.Outputs = WireLib.CreateOutputs( self, outputs )

	self:SetLocked( false )
	self:SetHidePlayer( false )
	self:SetHideHUD( 0 )
	self:SetShowCursor( 0 )
	self.HidePlayerVal = false
	self.Crosshairs = false
	self.Disable = false
	self.AllowButtons = false
	self.Relative = false
	self.MouseDown = false

	self:SetActivated( false )

	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)

	self:SetOverlayText( "Pod Controller" )
end

-- Accessor funcs for certain functions
function ENT:SetLocked( b )
	if not self:HasPod() or self.Locked == b then return end

	self.Locked = b
	self.Pod:Fire( b and "Lock" or "Unlock", "1", 0 )
end

function ENT:SetActivated( b )
	if (self.Activated == b) then return end

	self:ColorByLinkStatus(b and self.LINK_STATUS_ACTIVE or self.LINK_STATUS_LINKED)

	self.Activated = b
	WireLib.TriggerOutput(self, "Active", b and 1 or 0)
end

function ENT:HidePlayer( b )
	if not self:HasPly() then return end

	local c = self:GetPly():GetColor()
	if b then
		self.OldPlyAlpha = c.a
		c.a = 0
	else
		c.a = self.OldPlyAlpha or 255
		self.OldPlyAlpha = nil
	end
	self:GetPly():SetColor(c)
	self:GetPly():SetRenderMode(c.a ~= 255 and RENDERMODE_TRANSALPHA or RENDERMODE_NORMAL)
end

function ENT:SetHidePlayer( b )
	if (self.HidePlayer == b) then return end

	self.HidePlayerVal = b

	if (self:HasPly()) then
		self:HidePlayer( b )
	end
end

function ENT:LinkEnt( pod )
	pod = WireLib.GetClosestRealVehicle(pod,self:GetPos(),self:GetPlayer())

	-- if pod is still not a vehicle even after all of the above, then error out
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	if hook.Run( "CanTool", self:GetPlayer(), WireLib.dummytrace(pod), "wire_pod" ) == false then return false, "You do not have permission to access this vehicle" end

	self:SetPod( pod )
	WireLib.SendMarks(self, {pod})
	return true
end
function ENT:UnlinkEnt()
	if IsValid(self.Pod) then
		self.Pod:RemoveCallOnRemove("wire_pod_remove")
	end
	self:SetShowCursor( 0 )
	self.Pod = nil
	WireLib.SendMarks(self, {})
	WireLib.TriggerOutput( self, "Entity", NULL )
	self:ColorByLinkStatus(self.LINK_STATUS_UNLINKED)
	return true
end
function ENT:OnRemove()
	self:UnlinkEnt()
end

function ENT:HasPod() return (self.Pod and self.Pod:IsValid()) end
function ENT:GetPod() return self.Pod end
function ENT:SetPod( pod )
	if pod and pod:IsValid() and not pod:IsVehicle() then return false end

	if self:HasPly() then
		self:PlayerExited(self:GetPly())
	else
		self:ColorByLinkStatus(IsValid(pod) and self.LINK_STATUS_LINKED or self.LINK_STATUS_UNLINKED)
	end

	self.Pod = pod
	WireLib.TriggerOutput( self, "Entity", pod )

	if not IsValid(pod) then return true end

	pod:CallOnRemove("wire_pod_remove",function()
		self:UnlinkEnt(pod)
	end)

	if IsValid(pod:GetDriver()) then
		self:PlayerEntered(pod:GetDriver())
	end

	return true
end

function ENT:HasPly()
	return (self.Ply and self.Ply:IsValid())
end
function ENT:GetPly()
	return self.Ply
end
function ENT:SetPly( ply )
	if IsValid(ply) and not ply:IsPlayer() then return false end
	self.Ply = ply
	WireLib.TriggerOutput( self, "Driver", ply )
	return true
end

function ENT:SetHideHUD( val )
	self.HideHUD = val

	if self:HasPly() and self:HasPod() then -- If we have a player, we SHOULD always have a pod as well, but just in case.
		umsg.Start( "wire pod hud", self:GetPly() )
			umsg.Entity( self:GetPod() )
			umsg.Short( self.HideHUD )
		umsg.End()
	end
end
function ENT:GetHideHUD() return self.HideHUD end

function ENT:SetShowCursor( val )
	self.ShowCursor = val

	if self:HasPly() and self:HasPod() then
		umsg.Start( "wire pod cursor", self:GetPly() )
			umsg.Entity( self:GetPod() )
			umsg.Short( self.ShowCursor )
		umsg.End()
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
	["speed"] = "Shift",
	["zoom"] = "Zoom",
	["walk"] = "Alt",

	["attack"] = "Mouse1",
	["attack2"] = "Mouse2",
	["reload"] = "R",

	["invprev"] = "PrevWeapon",
	["invnext"] = "NextWeapon",
	["impulse 100"] = "Light",
}

hook.Add("PlayerBindDown", "gmod_wire_pod", function(player, binding)
	if not binding then return end
	local output = bindingToOutput[binding]
	if not output then return end

	for _, pod in pairs(ents.FindByClass("gmod_wire_pod")) do
		if pod:GetPly() == player and not pod.Disable then
			WireLib.TriggerOutput(pod, output, 1)
		end
	end
end)

hook.Add("PlayerBindUp", "gmod_wire_pod", function(player, binding)
	if not binding then return end
	local output = bindingToOutput[binding]
	if not output then return end

	for _, pod in pairs(ents.FindByClass("gmod_wire_pod")) do
		if pod:GetPly() == player and not pod.Disable then
			WireLib.TriggerOutput(pod, output, 0)
		end
	end
end)

-- Helper function for ejecting players using the RC remote
function ENT:RCEject()
	self.RC:Off()
end

function ENT:TriggerInput( name, value )
	if (name == "Lock") then
		if (self.RC) then return end
		if not self:HasPod() then return end
		self:SetLocked( value ~= 0 )
	elseif (name == "Terminate") then
		if value == 0 or not self:HasPly() then return end
		local ply = self:GetPly()
		if (self.RC) then self:RCEject( ply ) end
		ply:Kill()
	elseif (name == "Strip weapons") then
		if value == 0 or not self:HasPly() then return end
		local ply = self:GetPly()
		if (self.RC) then
			ply:ChatPrint( "Your control has been terminated, and your weapons stripped!" )
			self:RCEject( ply )
		else
			ply:ChatPrint( "Your weapons have been stripped!" )
		end
		ply:StripWeapons()
	elseif (name == "Eject") then
		if value == 0 or not self:HasPly() then return end
		if (self.RC) then
			self:RCEject( self:GetPly() )
		else
			self:GetPly():ExitVehicle()
		end
	elseif (name == "Disable") then
		self.Disable = value ~= 0

		if (self.Disable) then
			for _, output in pairs( bindingToOutput ) do
				WireLib.TriggerOutput( self, output, 0 )
			end
		end
	elseif (name == "Crosshairs") then
		self.Crosshairs = value ~= 0
		if (self:HasPly()) then
			if (self.Crosshairs) then
				self:GetPly():CrosshairEnable()
			else
				self:GetPly():CrosshairDisable()
			end
		end
	elseif (name == "Brake") then
		if not self:HasPod() then return end
		local pod = self:GetPod()
		if value ~= 0 then
			pod:Fire("TurnOff","1",0)
			pod:Fire("HandBrakeOn","1",0)
		else
			pod:Fire("TurnOn","1",0)
			pod:Fire("HandBrakeOff","1",0)
		end
	elseif (name == "Damage Health") then
		if not self:HasPly() or value <= 0 then return end
		if (value > 100) then value = 100 end
		self:GetPly():TakeDamage( value )
	elseif (name == "Damage Armor") then
		if not self:HasPly() or value <= 0 then return end
		if (value > 100) then value = 100 end
		local dmg = self:GetPly():Armor() - value
		if (dmg < 0) then dmg = 0 end
		self:GetPly():SetArmor( dmg )
	elseif (name == "Allow Buttons") then
		self.AllowButtons = value ~= 0
	elseif (name == "Relative") then
		self.Relative = value ~= 0
	elseif (name == "Hide Player") then
		self:SetHidePlayer( value ~= 0 )
	elseif (name == "Hide HUD") then
		self:SetHideHUD( value )
	elseif (name == "Show Cursor") then
		self:SetShowCursor( value )
	elseif (name == "Vehicle") then
		if not IsValid(value) then return end -- only link if the input is valid. that way, it won't be unlinked if the wire is disconnected
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

function ENT:Think()
	if (self:HasPly() and self.Activated) then
		local ply = self:GetPly()
		local pod = self:GetPod()

		-- Tracing
		local trace = util.TraceLine( { start = ply:GetShootPos(), endpos = ply:GetShootPos() + ply:GetAimVector() * 9999999999, filter = { ply, pod } } )
		local distance
		if (self:HasPod()) then distance = trace.HitPos:Distance( pod:GetPos() ) else distance = trace.HitPos:Distance( ply:GetShootPos() ) end

		if (trace.Hit) then
			-- Position
			WireLib.TriggerOutput( self, "X", trace.HitPos.x )
			WireLib.TriggerOutput( self, "Y", trace.HitPos.y )
			WireLib.TriggerOutput( self, "Z", trace.HitPos.z )
			WireLib.TriggerOutput( self, "AimPos", trace.HitPos )
			WireLib.TriggerOutput( self, "Distance", distance )
			self.VPos = trace.HitPos

			-- Bearing & Elevation
			local angle = ply:GetAimVector():Angle()

			if (self.Relative) then
				local originalangle
				if (self.RC) then
					originalangle = ply.InitialAngle
				else
					originalangle = pod:GetAngles()
					if pod:GetClass() ~= "prop_vehicle_prisoner_pod" then
						originalangle.y = originalangle.y + 90
					end
				end
				WireLib.TriggerOutput( self, "Bearing", fixupangle( angle.y - originalangle.y ) )
				WireLib.TriggerOutput( self, "Elevation", fixupangle( angle.p - originalangle.p ) )
			else
				WireLib.TriggerOutput( self, "Bearing", fixupangle( angle.y ) )
				WireLib.TriggerOutput( self, "Elevation", fixupangle( -angle.p ) )
			end
		else
			WireLib.TriggerOutput( self, "X", 0 )
			WireLib.TriggerOutput( self, "Y", 0 )
			WireLib.TriggerOutput( self, "Z", 0 )
			WireLib.TriggerOutput( self, "AimPos", Vector(0,0,0) )
			WireLib.TriggerOutput( self, "Bearing", 0 )
			WireLib.TriggerOutput( self, "Elevation", 0 )
			self.VPos = Vector(0,0,0)
		end

		-- Button pressing
		if (self.AllowButtons and distance < 82) then
			local button = trace.Entity
			if IsValid(button) and (ply:KeyDown( IN_ATTACK ) and not self.MouseDown) and button.Use then
				-- Generic support (Buttons, Dynamic Buttons, Levers, EGP screens, etc)
				self.MouseDown = true
				button:Use(ply, self, USE_ON, 0)
			elseif not ply:KeyDown( IN_ATTACK ) and self.MouseDown then
				self.MouseDown = false
			end
		end

		-- Other info
		WireLib.TriggerOutput(self, "Team", ply:Team())
		WireLib.TriggerOutput(self, "Health", ply:Health())
		WireLib.TriggerOutput(self, "Armor", ply:Armor())
		if self:HasPod() then WireLib.TriggerOutput(self, "ThirdPerson", pod:GetThirdPersonMode() and 1 or 0) end

		if not ply:IsBot() then WireLib.TriggerOutput(self, "Light", ply.keystate[KEY_F] and 1 or 0) end
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:PlayerEntered( ply, RC )
	if (self:HasPly()) then return end
	self:SetPly( ply )

	self.RC = RC

	if (self.Crosshairs) then
		ply:CrosshairEnable()
	end

	if self.HideHUD > 0 and self:HasPod() then
		timer.Simple(0.1,function()
			umsg.Start( "wire pod hud", ply )
				umsg.Entity( self:GetPod() )
				umsg.Short( self.HideHUD )
			umsg.End()
		end)
	end

	if self.ShowCursor > 0 and self:HasPod() then
		timer.Simple(0.1,function()
			umsg.Start( "wire pod cursor", ply )
				umsg.Entity( self:GetPod() )
				umsg.Short( self.ShowCursor )
			umsg.End()
		end)
	end

	if (self.HidePlayerVal) then
		self:HidePlayer( true )
	end

	self:SetActivated( true )
end

function ENT:PlayerExited( ply )
	if not self:HasPly() then return end

	self:HidePlayer( false )
	self:SetShowCursor( 0 )

	ply:CrosshairEnable()

	self:SetActivated( false )

	for _, output in pairs(bindingToOutput) do
		WireLib.TriggerOutput( self, output, 0 )
	end

	WireLib.TriggerOutput( self, "X", 0 )
	WireLib.TriggerOutput( self, "Y", 0 )
	WireLib.TriggerOutput( self, "Z", 0 )
	WireLib.TriggerOutput( self, "AimPos", Vector(0,0,0) )

	WireLib.TriggerOutput( self, "Distance", 0 )
	WireLib.TriggerOutput( self, "Bearing", 0 )
	WireLib.TriggerOutput( self, "Elevation", 0 )

	WireLib.TriggerOutput( self, "ThirdPerson", 0 )
	WireLib.TriggerOutput( self, "Team", 0 )
	WireLib.TriggerOutput( self, "Health", 0 )
	WireLib.TriggerOutput( self, "Armor", 0 )

	self:SetPly( nil )
end

hook.Add( "PlayerEnteredVehicle", "Wire_Pod_EnterVehicle", function( ply, vehicle )
	for _, v in pairs( ents.FindByClass( "gmod_wire_pod" ) ) do
		if (v:HasPod() and v:GetPod() == vehicle) then
			v:PlayerEntered( ply )
		end
	end
end)

hook.Add( "PlayerLeaveVehicle", "Wire_Pod_ExitVehicle", function( ply, vehicle )
	for _, v in pairs( ents.FindByClass( "gmod_wire_pod" ) ) do
		if (v:HasPod() and v:GetPod() == vehicle) then
			v:PlayerExited( ply )
		end
	end
end)

hook.Add("CanExitVehicle","Wire_Pod_CanExitVehicle", function( vehicle, ply )
	for _, v in pairs( ents.FindByClass( "gmod_wire_pod" ) ) do
		if (v:HasPod() and v:GetPod() == vehicle) and v.Locked and v.AllowLockInsideVehicle:GetBool() then
			return false
		end
	end
end)

function ENT:GetBeaconPos(sensor)
	return self.VPos
end
function ENT:GetBeaconVelocity(sensor)
	return self:HasPod() and self:GetPod():GetVelocity() or self:GetVelocity()
end

--Duplicator support to save pod link (TAD2020)
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	if self:HasPod() and not self.RC then
		info.pod = self.Pod:EntIndex()
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
	if not hook.Run("PlayerGiveSWEP", User, "remotecontroller", weapons.Get( "remotecontroller" )) then return end
	User:PrintMessage(HUD_PRINTTALK, "Hold down your use key for 2 seconds to get and link a Remote Controller.")
	timer.Create("pod_use_"..self:EntIndex(), 2, 1, function()
		if not IsValid(User) or not User:IsPlayer() then return end
		if not User:KeyDown(IN_USE) then return end
		if not User:GetEyeTrace().Entity or User:GetEyeTrace().Entity ~= self then return end

		if not IsValid(User:GetWeapon("remotecontroller")) then
			if not hook.Run("PlayerGiveSWEP", User, "remotecontroller", weapons.Get( "remotecontroller" )) then return end
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
