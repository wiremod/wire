AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Camera Controller"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName	= "Camera Controller"

if CLIENT then 
	local living = CreateMaterial("flir_living","UnlitGeneric", {["$basetexture"] = "color/white", ["$model"] = 1, ["$translucent"] = 0, ["$alpha"] = 0, ["$nocull"] = 0, ["$ignorez"] = 0})
	local normal = CreateMaterial("flir_normal","VertexLitGeneric", {["$basetexture"] = "color/white", ["$model"] = 1, ["$translucent"] = 0, ["$ignorez"] = 0})

	local colmod = {
		[ "$pp_colour_addr" ] = -.4,
		[ "$pp_colour_addg" ] = -.5,
		[ "$pp_colour_addb" ] = -.5,
		[ "$pp_colour_brightness" ] = .1,
		[ "$pp_colour_contrast" ] = 1.2,
		[ "$pp_colour_colour" ] = 0,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0
	}

	local flir_enabled = false
	local function flir_start()
		if (flir_enabled) then return end
		flir_enabled = true
		hook.Add("PrePlayerDraw","flir_PrePlayerDraw",function()
			render.MaterialOverride(living)
		end)
		hook.Add("PostPlayerDraw","flir_PostPlayerDraw",function()
			render.MaterialOverride(normal)
		end)

		hook.Add("PreDrawOpaqueRenderables","flir_PreDrawOpaqueRenderables",function()
			render.MaterialOverride(normal)
		end)
		hook.Add("PostDrawOpaqueRenderables","flir_PostDrawOpaqueRenderables",function()
			render.MaterialOverride(nil)
		end)

		hook.Add("PreDrawTranslucentRenderables","flir_PreDrawTranslucentRenderables",function()
			render.MaterialOverride(normal)
		end)
		hook.Add("PostDrawTranslucentRenderables","flir_PostDrawTranslucentRenderables",function()
			render.MaterialOverride(nil)
		end)

		hook.Add("PreDrawSkybox","flir_PreDrawSkybox",function()
			render.MaterialOverride(normal)
		end)
		hook.Add("PostDrawSkybox","flir_PostDrawSkybox",function()
			render.MaterialOverride(nil)
		end)

		hook.Add("RenderScreenspaceEffects","flir_RenderScreenspaceEffects",function()
			DrawColorModify(colmod)
			DrawBloom(0,100,5,5,3,0.1,0,0,0)
			DrawSharpen(1,0.5)
		end)
	end

	local function flir_end()
		if (!flir_enabled) then return end
		flir_enabled = false
		render.MaterialOverride(nil)
		hook.Remove("PrePlayerDraw","flir_PrePlayerDraw")
		hook.Remove("PostPlayerDraw","flir_PostPlayerDraw")

		hook.Remove("PreDrawOpaqueRenderables","flir_PreDrawOpaqueRenderables")
		hook.Remove("PostDrawOpaqueRenderables","flir_PostDrawOpaqueRenderables")

		hook.Remove("PreDrawTranslucentRenderables","flir_PreDrawTranslucentRenderables")
		hook.Remove("PostDrawTranslucentRenderables","flir_PostDrawTranslucentRenderables")

		hook.Remove("PreDrawSkybox","flir_PreDrawSkybox")
		hook.Remove("PostDrawSkybox","flir_PostDrawSkybox")

		hook.Remove("RenderScreenspaceEffects","flir_RenderScreenspaceEffects")
	end

	usermessage.Hook("toggle_flir",function(um)
		local mode = um:ReadBool()
		if(mode == true) then
			flir_start()
		else
			flir_end()
		end
	end)
	
	return  -- No more client
end

-- Server

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = WireLib.CreateOutputs( self, { "On", "X", "Y", "Z", "XYZ [VECTOR]" } )

	self.Activated = 0 -- User defined
	self.Active = false -- Actual status
	self.ZoomAmount = 0
	self.OriginalFOV = 0
	self.Static = 0
	self.FLIREnabled = false
	self.FLIR = 0
end

function ENT:MakeDynamicCam(oldcam)
	local cam = ents.Create("gmod_wire_cam") -- TODO: RT camera
	if not cam:IsValid() then return false end

	if oldcam then
		cam:SetAngles( oldcam:GetAngles() )
		cam:SetPos( oldcam:GetPos() )
	else
		cam:SetAngles( Angle(0, 0, 0) )
		cam:SetPos( self:GetPos() )
	end
	cam:SetModel( Model("models/props_junk/PopCan01a.mdl") )
	cam:SetNoDraw(true)
	cam:Spawn()

	cam:CallOnRemove("wire_cam_restore", function(oldcam) self:MakeDynamicCam(oldcam) end)

	self.CamEnt = cam

	if oldcam then
		self:TriggerInput("Activated", self.Activated)
	end
	return cam
end

function ENT:Setup(Static)
	if IsValid(self:GetPlayer()) then
		self.CamPlayer = self:GetPlayer()
		self.OriginalOwner = self:GetPlayer()
		self.OriginalFOV = self.CamPlayer:GetFOV()
	end

	if Static == 0 then
		if not self:MakeDynamicCam() then return false end
		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom", "X", "Y", "Z", "Pitch", "Yaw", "Roll",
													"Angle [ANGLE]", "Position [VECTOR]", "Direction [VECTOR]", "Velocity [VECTOR]", "Parent [ENTITY]", "FLIR" } )
	else
		local cam = ents.Create("prop_physics")
		if (!cam:IsValid()) then return false end

		cam:SetAngles( Angle(0,0,0) )
		cam:SetPos( self:GetPos()+Vector(0,0,64) )
		cam:SetModel( Model("models/dav0r/camera.mdl") )
		cam:Spawn()
		cam:CallOnRemove("wire_cam_toggle", function(oldcam) if IsValid(self) then self:ToggleCam(false) end end)

		self.CamEnt = cam

		self.Inputs = WireLib.CreateInputs( self, { "Activated", "Zoom", "FLIR" } )
		self.Static = 1
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if not IsValid(self.CamEnt) then return end

	local vStart = self.CamEnt:GetPos()
	local vForward = self.CamEnt:GetForward()

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * 100000)
	trace.filter = { self.CamEnt }
	local trace = util.TraceLine( trace )

	if trace.HitPos then
		WireLib.TriggerOutput( self, "XYZ", trace.HitPos )
		WireLib.TriggerOutput(self, "X", trace.HitPos.x)
		WireLib.TriggerOutput(self, "Y", trace.HitPos.y)
		WireLib.TriggerOutput(self, "Z", trace.HitPos.z)
	else
		WireLib.TriggerOutput( self, "XYZ", Vector(0,0,0) )
		WireLib.TriggerOutput(self, "X", 0)
		WireLib.TriggerOutput(self, "Y", 0)
		WireLib.TriggerOutput(self, "Z", 0)
	end

	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:OnRemove()
	if self.CamEnt and self.CamEnt:IsValid() then
		self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
		self.CamEnt:RemoveCallOnRemove("wire_cam_toggle")
		self.CamEnt:Remove()
	end

	if self.Active then
		self:ToggleCam( false )
		self:ToggleFLIR( false )
	end
	Wire_Remove(self)
end

function ENT:ToggleFLIR( b )
	if (b != self.FLIREnabled) then
		if (self.CamPlayer and self.CamPlayer:IsValid()) then
			umsg.Start( "toggle_flir", self.CamPlayer )
				umsg.Bool( b )
			umsg.End()
			self.FLIREnabled = b
		end
	end
end

function ENT:ToggleCam( b )
	if (b != self.Active) then
		if (self.CamPlayer and self.CamPlayer:IsValid()) then
			if (b and self.CamEnt and self.CamEnt:IsValid()) then
				self.CamPlayer:SetViewEntity( self.CamEnt )
				self.CamPlayer:SetFOV( self.ZoomAmount, 0.01 )
				self.Active = true
			else
				self.CamPlayer:SetViewEntity( self.CamPlayer )
				self.CamPlayer:SetFOV( self.OriginalFOV, 0.01 )
				self.Active = false
			end
		end
	end
end

function ENT:TriggerInput( name, value )
	if (name == "Activated") then
		self.Activated = value
		WireLib.TriggerOutput( self, "On", value )
		if (value == 0 and self.CamPlayer and self.CamPlayer:IsValid()) then
			self:ToggleCam( false )
			self:ToggleFLIR( false )
		else
			if IsValid(self.CamPod) then
				if self.CamPod.GetDriver and self.CamPod:GetDriver() and self.CamPod:GetDriver():IsValid() then
					self.CamPlayer = self.CamPod:GetDriver()
				else
					self.CamPlayer = self.OriginalOwner
				end
			end
			self:ToggleCam( true )
			self:ToggleFLIR( self.FLIR != 0 )
		end
	elseif (name == "Zoom") then
		self.ZoomAmount = math.Clamp( value, 1, self.OriginalFOV )
		if self.Active then
			self.CamPlayer:SetFOV(self.ZoomAmount, 0.01) -- TODO: RT camera
		end
	elseif (name == "FLIR") then
		self:ToggleFLIR( (self.Active and value != 0) )
		self.FLIR = value
	else
		if (self.CamEnt and self.CamEnt:IsValid()) then
			self.CamEnt:ReceiveInfo(name, value)
		end
	end
end

-- Detect players exiting the pod
hook.Add("PlayerLeaveVehicle","Wire_CamController_PlayerEnteredVehicle",function( ply, vehicle )
	for k,v in pairs( ents.FindByClass( "gmod_wire_cameracontroller" ) ) do
		if (v.CamPod and v.CamPod:IsValid() and v.CamPod == vehicle) then
			if (v.Active) then
				v:ToggleCam( false )
				v:ToggleFLIR( false )
				v.CamPlayer = v.OriginalOwner
			end
		end
	end
end)

local antispam = {}
concommand.Add( "wire_cameracontroller_leave", function( ply, cmd, args )
	if (!ply or !ply:IsValid()) then return end
	if (!antispam[ply]) then antispam[ply] = 0 end
	if (antispam[ply] > CurTime()) then
		ply:ChatPrint( "This command has a 5 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime()) .. " seconds.")
		return
	end
	antispam[ply] = CurTime() + 5

	local found = false
	for k,v in pairs( ents.FindByClass( "gmod_wire_cameracontroller" ) ) do
		if (v.CamPlayer and v.CamPlayer:IsValid() and v.CamPlayer == ply) then
			found = true
			v:ToggleCam( false )
			v:ToggleFLIR( false )
			v.CamPlayer = v.OriginalOwner
		end
	end
	if (!found) then
		ply:SetViewEntity( ply )
		umsg.Start( "toggle_flir", ply )
			umsg.Bool( false )
		umsg.End()
	end
end)

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.CamPod) then
		info.pod = self.CamPod:EntIndex()
	end
	if IsValid(self.CamEnt) and self.Static ~= 0 then
		info.cam = self.CamEnt:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.CamPod = GetEntByID(info.pod)

	if IsValid(self.CamEnt) then
		self.CamEnt:RemoveCallOnRemove("wire_cam_restore")
		self.CamEnt:Remove()
	end

	self.CamEnt = GetEntByID(info.cam)
end

duplicator.RegisterEntityClass("gmod_wire_cameracontroller", WireLib.MakeWireEnt, "Data", "Static")
