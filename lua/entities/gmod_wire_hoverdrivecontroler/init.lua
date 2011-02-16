
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "HoverDrive"

local useenergy = CreateConVar( "sv_HoverDriveUseEnergy", 0, {FCVAR_ARCHIVE} )

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self:SetModel( "models//props_c17/utilityconducter001.mdl" )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow(false)

	//self:SetModel( "models/dav0r/hoverball.mdl" )
	//self:PhysicsInitSphere( 8, "metal_bouncy" )

	local phys = self:GetPhysicsObject()

	if ( phys:IsValid() ) then
		phys:SetMass( 100 )
		phys:EnableGravity( false )
		phys:Wake()
	end

	if ( RES_DISTRIB == 2 ) then
		RD_AddResource(self, "energy", 0)
		if(LS_RegisterEnt) then LS_RegisterEnt(self, "Generator") end; -- Not everyone uses LifeSupport if he has Resource Distribution installed
	end

	//self:StartMotionController()

	self.Fraction = 0

	self.Velocity = Vector(0,0,0)
	self:SetTargetZ( self:GetPos().z )
	self.Target = self:GetPos()
	self:SetSpeed( 1 )
	self:SetHoverMode( 1 )

	self.TargetYaw = 0
	self.YawVelocity = 0

	self.TargetAngle = Angle(0, 0, 0)
	self.AngleVelocity = Angle(0, 0, 0)

	self.JumpTarget = Vector(0,0,0)

	self.Sound = true

	self.Inputs = WireLib.CreateInputs( self, { "X_JumpTarget", "Y_JumpTarget", "Z_JumpTarget", "SetJumpTarget (deprecated)", "Jump", "JumpTarget [VECTOR]", "Sound" } ) //"X_Velocity", "Y_Velocity", "Z_Velocity", "Pitch_Velocity", "Yaw_Velocity", "Roll_Velocity", "HoverMode",
	//self.Outputs = WireLib.CreateOutputs(self, { "Data [HOVERDATAPORT]" })
	self:ShowOutput()
end

CreateConVar('sbox_maxwire_hoverdrives', 2)
local function MakeWireHoverDriveCtrl(pl, Data)
	if !pl:CheckLimit("wire_hoverdrives") then return nil end

	local ent = ents.Create("gmod_wire_hoverdrivecontroler")
		if !ent:IsValid() then return end
		duplicator.DoGeneric(ent, Data)
		ent:SetPlayer(pl)
	ent:Spawn()
	ent:Activate()

	duplicator.DoGenericPhysics(ent, pl, Data)

	ent:SetSpeed(1)
	ent:SetAirResistance(0)
	ent:SetStrength(10)

	pl:AddCount("wire_hoverdrives", ent)
	pl:AddCleanup("hoverdrivecontrolers", ent)
	return ent
end
duplicator.RegisterEntityClass("gmod_wire_hoverdrivecontroler", MakeWireHoverDriveCtrl, "Data")

function ENT:SpawnFunction( pl, tr )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = MakeWireHoverDriveCtrl( pl, {Pos = SpawnPos} )

	return ent
end

function ENT:TriggerInput(iname, value)
	if (iname == "Jump") then
		if (value ~= 0) and (!self.Jumping) then
			if not self.Inputs.SetJumpTarget.Src then
				-- if there is nothing connected to SetJumpTarget, set the jump target
				self.JumpTargetSet = true
			end
			self:Jump()
		end
	elseif (iname == "JumpTarget") then
		self.JumpTarget = value or Vector(0,0,20)
	elseif (iname == "X_JumpTarget") then
		self.JumpTarget = self.JumpTarget or Vector(0,0,20)
		self.JumpTarget.x = value
	elseif (iname == "Y_JumpTarget") then
		self.JumpTarget = self.JumpTarget or Vector(0,0,20)
		self.JumpTarget.y = value
	elseif (iname == "Z_JumpTarget") then
		self.JumpTarget = self.JumpTarget or Vector(0,0,20)
		self.JumpTarget.z = value
	elseif (iname == "SetJumpTarget") then
		//Msg("value = "..value.."\n")
		if (value ~= 0) then
			self.JumpTargetSet = true
		/*else
			self.JumpTargetSet = false*/
		end
	elseif (iname == "Sound") then
		self.Sound = value ~= 0
	elseif (iname == "Z_Velocity") then
		self:SetZVelocity( value )
	elseif (iname == "X_Velocity") then
		self:SetXVelocity( value )
	elseif (iname == "Y_Velocity") then
		self:SetYVelocity( value )
	elseif (iname == "HoverMode") then
		if (value ~= 0) then
			self.Target = self:GetPos()
			self:SetHoverMode( 1 )
		else
			self:SetHoverMode( 0 )
		end
	elseif (iname == "Pitch_Velocity") then
		self:SetPitchVelocity( value )
	elseif (iname == "Yaw_Velocity") then
		self:SetYawVelocity( value )
	elseif (iname == "Roll_Velocity") then
		self:SetRollVelocity( value )
	end
	self:ShowOutput()
end


function ENT:ShowOutput()
	local txt = "-HoverDrive-\nJump Target = "..tostring(self.JumpTarget)
	if (self.JumpTargetSet) then
		txt = txt.."\n( Jump Target Set )"
	end
	self:SetOverlayText( txt )
end


function ENT:OnRestore()
	self.Velocity = Vector(0,0,0)
	self.Target = self:GetPos()

	self.BaseClass.OnRestore(self)
end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
/*function ENT:OnTakeDamage( dmginfo )
	//self:TakePhysicsDamage( dmginfo )
end*/


local function GetTargetAndExponentVector(deltatime, Target, Velocity, AxisPos, AxisVel, AirResistance, Speed)

	local Diff = Target - AxisPos
	Diff.x = math.Clamp( Diff.x, -100, 100 )
	Diff.y = math.Clamp( Diff.y, -100, 100 )
	Diff.z = math.Clamp( Diff.z, -100, 100 )

	if ( Diff == Vector(0,0,0) ) then
		return Target, Vector(0,0,0)
	end

	local Exponent = Vector()
	Exponent.x = Diff.x^2
	Exponent.y = Diff.y^2
	Exponent.z = Diff.z^2

	if ( Diff.x < 0 ) then Exponent.x = Exponent.x * -1 end
	if ( Diff.y < 0 ) then Exponent.y = Exponent.y * -1 end
	if ( Diff.z < 0 ) then Exponent.z = Exponent.z * -1 end

	Exponent = ( Exponent * deltatime * 300 ) - ( AxisVel * deltatime * 600 * ( AirResistance + 1 ) )

	Exponent.x = math.Clamp( Exponent.x, -5000, 5000 )
	Exponent.y = math.Clamp( Exponent.y, -5000, 5000 )
	Exponent.z = math.Clamp( Exponent.z, -5000, 5000 )

	return Target, Exponent
end

/*---------------------------------------------------------
	Think wasn't good enough
---------------------------------------------------------*/
/*function ENT:PhysicsSimulate( phys, deltatime )

	/*if ( self.YawVelocity != 0 ) then
		self.TargetYaw = math.fmod( ( self.TargetYaw + ( self.YawVelocity * deltatime ) ), 360 )
		//Msg("self.TargetYaw =  "..self.TargetYaw.."\n")
	end*
	if ( self.AngleVelocity.p != 0 ) then
		self.TargetAngle.p = math.fmod( ( self.TargetAngle.p + ( self.AngleVelocity.p * deltatime ) ), 360 )
	end
	if ( self.AngleVelocity.y != 0 ) then
		self.TargetAngle.y = math.fmod( ( self.TargetAngle.y + ( self.AngleVelocity.y * deltatime ) ), 360 )
	end
	if ( self.AngleVelocity.r != 0 ) then
		self.TargetAngle.r = math.fmod( ( self.TargetAngle.r + ( self.AngleVelocity.r * deltatime ) ), 360 )
	end

	local Vel = self:GetPhysicsObject():LocalToWorldVector( self.Velocity )

	self.Target = self.Target + ( Vel * deltatime * self:GetSpeed() )
	self:SetTargetZ(self.Target.Z)

	local data = {}
	data.Hover = self:GetHoverMode()
	data.Target = self.Target
	//data.TargetYaw = self.TargetYaw
	data.TargetAngle = self.TargetAngle
	//data.ControlerPos = self:GetPos()

	Wire_TriggerOutput(self, "Data", data)

	local txt = "-HoverDrive-\nJump Target = "..tostring(self.JumpTarget)
	if (self:GetHoverMode()) then
		txt = txt.."\n(on)"
		self:SetOverlayText( txt )
	else
		txt = txt.."\n(off)"
		self:SetOverlayText( txt )
	end

	return SIM_GLOBAL_FORCE*

	/*local Pos = phys:GetPos()
	//local txt = string.format( "Speed: %i\nResistance: %.2f", self:GetSpeed(), self:GetAirResistance() )
	//txt = txt.."\nZ pos: "..math.floor(Pos.z) //.."Target: "..math.floor(self:GetTargetZ())

	local txt = "TargetX = "..self.Target.x.."\nTargetY = "..self.Target.y.."\nTargetZ = "..self.Target.z

	Wire_TriggerOutput(self, "A: Zpos", Pos.z)
	Wire_TriggerOutput(self, "B: Xpos", Pos.x)
	Wire_TriggerOutput(self, "C: Ypos", Pos.y)


	if (self:GetHoverMode()) then

		txt = txt.."\n(on)"
		self:SetOverlayText( txt )

		local physVel = phys:GetVelocity()
		local physAngVel = phys:GetAngleVelocity()
		local AirResistance = self:GetAirResistance()
		local Speed = self:GetSpeed()

		phys:Wake()

		self.Velovity = Vector( self.XVelocity, self.YVelocity, self.ZVelocity )
		local Vel = phys:LocalToWorldVector( self.Velovity )

		/*local TargetX, ExponentX = GetTargetAndExponent(deltatime, self:GetTargetX(), Vel.x, Pos.x, physVel.x, AirResistance, Speed)
		self:SetTargetX(TargetX)

		local TargetY, ExponentY = GetTargetAndExponent(deltatime, self:GetTargetY(), Vel.y, Pos.y, physVel.y, AirResistance, Speed)
		self:SetTargetY(TargetY)

		local TargetZ, ExponentZ = GetTargetAndExponent(deltatime, self:GetTargetZ(), Vel.z, Pos.z, physVel.z, AirResistance, Speed)
		self:SetTargetZ(TargetZ)*

		local Target, Exponent = GetTargetAndExponentVector(deltatime, self.Target, Vel, Pos, physVel, AirResistance, Speed)
		self.Target = Target
		self:SetTargetZ(Target.Z)

		local Ang = phys:GetAngles()

		if ( Exponent == Vector(0,0,0) ) then return end

		//local Linear = Vector(0,0,0)
		local Angular = Vector(0,0,0)

		/*Linear.z = ExponentZ
		Linear.x = ExponentX
		Linear.y = ExponentY*
		// Linear
		return Angular, Exponent, SIM_GLOBAL_ACCELERATION //SIM_LOCAL_ACCELERATION
	else
		txt = txt.."\n(off)"
		self:SetOverlayText( txt )
		return SIM_GLOBAL_FORCE
	end*/

//end


/*function ENT:DoOutput()

	local data = {}
	data.Hover = self:GetHoverMode()
	data.Target = self.Target
	data.TargetNorm = self:GetForward()
	//data.ControlerPos = self:GetPos()

	Wire_TriggerOutput(self, "Data", data)

	local txt = "Target = "..tostring(self.Target)
	if (self:GetHoverMode()) then
		txt = txt.."\n(on)"
		self:SetOverlayText( txt )
	else
		txt = txt.."\n(off)"
		self:SetOverlayText( txt )
	end
end*/


function ENT:WakePhys()
	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:Wake()
	end
end

function ENT:SetXVelocity( x )
	self.Velocity.x = x * FrameTime() * 5000
	self:WakePhys()
end

function ENT:SetYVelocity( y )
	self.Velocity.y = y * FrameTime() * 5000
	self:WakePhys()
end

function ENT:SetZVelocity( z )
	self.Velocity.z = z * FrameTime() * 5000
	self:WakePhys()
end

function ENT:SetVelocity( vel )
	self.Velocity = vel * FrameTime() * 5000
	self:WakePhys()
end

function ENT:SetPitchVelocity( vel )
	self.AngleVelocity.p = vel * FrameTime() * 2000
	self:WakePhys()
end

function ENT:SetYawVelocity( vel )
	self.AngleVelocity.y = vel * FrameTime() * 2000
	self:WakePhys()
end

function ENT:SetRollVelocity( vel )
	self.AngleVelocity.r = vel * FrameTime() * 2000
	self:WakePhys()
end


/*---------------------------------------------------------
   GetAirFriction
---------------------------------------------------------*/
function ENT:GetAirResistance( )
	return self:GetVar( "AirResistance", 0 )
end


/*---------------------------------------------------------
   SetAirFriction
---------------------------------------------------------*/
function ENT:SetAirResistance( num )
	self:SetVar( "AirResistance", num )
end

/*---------------------------------------------------------
   SetStrength
---------------------------------------------------------*/
function ENT:SetStrength( strength )

	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:SetMass( 150 * strength )
	end
end




ENT.JumpStage = 0


//util.PrecacheSound("stargate/teleport.mp3")
util.PrecacheSound("npc/turret_floor/die.wav")
//util.PrecacheSound("npc/scanner/combat_scan_loop2.wav")
util.PrecacheSound("ambient/levels/citadel/weapon_disintegrate2.wav")
//util.PrecacheSound("ambient/levels/labs/electric_explosion2.wav")
util.PrecacheSound("buttons/button2.wav")
util.PrecacheSound("buttons/button8.wav")
function ENT:FailJump()
	self:EmitSound("npc/turret_floor/die.wav", 450, 70)
end

function ENT:Jump()
	if (self.Jumping) then return end

	if (!self.JumpTargetSet) then
		self:EmitSound("buttons/button8.wav", 130)
		return
	end

	if ( RES_DISTRIB == 2 and useenergy:GetBool() ) then
		local dist = self:GetPos():Distance(self.JumpTarget)
		local needed = math.floor(dist ^ 2 / 5000 + 200)
		--Msg("hover drive requires ",needed," energy to jump ",dist,"\n")
		local energy = RD_GetResourceAmount(self, "energy")
		if (energy >= needed) then
			RD_ConsumeResource(self, "energy", needed)
		else
			self:EmitSound("buttons/button2.wav", 500)
			self:FailJump()
			return
		end
	end

	if ( not util.IsInWorld( self.JumpTarget ) ) then
		self:EmitSound("buttons/button8.wav", 500)
		self:FailJump()
		return
	end

	self.Jumping = true

	self.other_gate = self
	self.LastPos = self:GetPos()// + Vector(0,0,5)

	self.JumpStage = 1
	self.JumpTargetSet = false
	--Msg("Jumping!\n")
end

function ENT:Think()
	if (self.JumpStage == 1) then
		--Msg("Start Jump 1\n")

		local attached = self:GetEntitiesForTeleport(self);
		if(attached) then

			--TODO: LS2 energy required based on attached mass
			/*if ( RES_DISTRIB == 2 and useenergy:GetBool() ) then
				local mass = something
				local dist = self:GetPos():Distance(self.JumpTarget)
				local needed = math.floor(dist ^ 2 / 5000 + 200) + mass?
				--Msg("hover drive requires ",needed," energy to jump ",dist,"\n")
				local energy = RD_GetResourceAmount(self, "energy")
				if (energy >= needed) then
					RD_ConsumeResource(self, "energy", needed)
				else
					self:EmitSound("buttons/button2.wav", 500)
					self:FailJump()
					self.JumpStage = 0
					return
				end
			end*/

			self.ents = self:PrepareTeleport(attached);

			DoPropSpawnedEffect( self );

			//self.LastPos = self:GetPos()

			local Ofs = self.JumpTarget - self:GetPos()
			//local ang = Ofs:Angle()
			//local effectend = self:GetPos() + (Ofs:Normalize() * 180)

			local ed = EffectData()
				ed:SetEntity( self )
				ed:SetOrigin( self:GetPos() + (Ofs:Normalize() * math.Clamp( self:BoundingRadius() * 5, 180, 4092 ) ) )
			util.Effect( "jump_out", ed, true, true );

			for _,v in pairs(self.ents.Attached) do
				if (v and v.Entity and v.Entity:IsValid()) then

					v.Entity:DrawShadow(false)

					DoPropSpawnedEffect( v.Entity );

					local ed = EffectData()
						ed:SetEntity( v.Entity )
						ed:SetOrigin( self:GetPos() + (Ofs:Normalize() * math.Clamp( v.Entity:BoundingRadius() * 5, 180, 4092 ) ) )
					util.Effect( "jump_out", ed, true, true );

				end
			end

			//self:EmitSound("stargate/teleport.mp3")
			//self:EmitSound("npc/scanner/combat_scan_loop2.wav", 500)
			if self.Sound then
				self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
			end
			self.JumpStage = 2
		else
			self:FailJump()
			self.JumpStage = 0
		end

		--Msg("End Jump 1\n")
	elseif (self.JumpStage == 2) then
		--Msg("Start Jump 2\n")

		self:Teleport(self.ents.Entity, self);

		DoPropSpawnedEffect( self );

		local Ofs = self.LastPos - self:GetPos()

		local ed = EffectData()
			ed:SetEntity( self )
			ed:SetOrigin( self:GetPos() + (Ofs:Normalize() * math.Clamp( self:BoundingRadius() * 5, 180, 4092 ) ) )
		util.Effect( "jump_in", ed, true, true );

		for _,v in pairs(self.ents.Attached) do
			self:Teleport(v,self);

			if (v and v.Entity and v.Entity:IsValid()) then

				v.Entity:DrawShadow(true)

				DoPropSpawnedEffect( v.Entity );

				local ed = EffectData()
					ed:SetEntity( v.Entity )
					ed:SetOrigin( self:GetPos() + (Ofs:Normalize() * math.Clamp( v.Entity:BoundingRadius() * 5, 180, 4092 ) ) )
				util.Effect( "jump_in", ed, true, true );

			end
		end

		if self.Sound then
			//self:EmitSound("stargate/teleport.mp3")
			self:EmitSound("npc/turret_floor/die.wav", 450, 70)
			//self:EmitSound("ambient/levels/labs/electric_explosion2.wav", 500, 90)
		end

		//self.JumpTarget = self.NextJumpTarget
		self.Target = self:GetPos()
		self.JumpStage = 0
		self.Jumping = false

		--Msg("End Jump 1\n")
	end
end



/*---------------------------------------------------------
	Teleport Functions
	Based on Teleport functions from Stargates
	Credits to Avon
---------------------------------------------------------*/


--################# Allowed for teleport?
function ENT:Allowed(e,auto_close_check)
	local c = e:GetClass();
	local t = type(e):lower();
	/*local p = e:GetPhysicsObject();
	local moveable = true;
	if(p:IsValid() and t == "entity") then
		if(not p:IsMoveable()) then
			moveable = false;
		end
	end*/
	if(((t == "player" and not e:InVehicle()) or
		(t == "entity" and (c:find("prop_[prv]") or (c:find("phys_") and not auto_close_check))) or -- Allow props and constraints
		t == "vehicle" or -- Vehicles
		(e.Type ~= nil) or //and not c:find("stargate") and not (c:find("dhd") and auto_close_check)) or -- SENT's but not stargates - May cause into infinity selfteleportation - For more, watch this funny screeny ;)  http://forums.facepunchstudios.com/showpost.php?p=4747617&postcount=256
		t == "npc" or -- NPC's
		t == "weapon" or c == "npc_grenade_frag" or c == "rpg_missile" or c == "grenade_ar2" or c == "crossbow_bolt" or c == "npc_satchel" or c == "prop_combine_ball") and -- Weapons and grenades from weapons etc
		e:GetParent():EntIndex() == 0 -- Only allow unparented props to get teleported
		//and (moveable or not auto_close_check) -- For the autoclose only - Is the object awake?
	) then
		return true
	end
	return false
end


--################# Bones for vehicle teleportation
function ENT:GetBones(e)
	-- And as well, get the bones of an object
	local bones = {};
	if(type(e):lower() == "vehicle" or e:GetClass() == "prop_ragdoll") then
		for k=0,e:GetPhysicsObjectCount()-1 do
			local bone = e:GetPhysicsObjectNum(k);
			if(bone:IsValid()) then
				table.insert(bones,{
					Entity=bone,
					Position=e:WorldToLocal(bone:GetPos()),
					Velocity=e:WorldToLocal(e:GetPos()+bone:GetVelocity()),
				});
			end
		end
	end
	return bones;
end

--################# Prepares the teleport for the entity e and the attached entities a
function ENT:PrepareTeleport(tbl)
	-- Entities
	local e = tbl.Entity;
	-- Gate specific
	local g = {self,self.other_gate} -- Gates
	local a = { -- Angles
		This=g[1]:GetAngles(),
		Other=g[2]:GetAngles(),
	}
	a.Delta=a.Other-a.This;

	/*local maxz = e:GetPos().z + e:BoundingRadius();
	local maxeent = e;
	local minz = e:GetPos().z - e:BoundingRadius();
	local minzent = e;*/


	-- Return table
	local ret = {Attached={}};
	-- ######### Calculate new positions,angles and velocity for attached
	for _,v in pairs(tbl.Attached) do
		local vel = v:GetVelocity();
		local data = {
			Entity=v,
			Position={
				New=e:WorldToLocal(v:GetPos()),
				Old=v:GetPos(),
			},
			Velocity={
				New=e:WorldToLocal(vel+e:GetPos()),
				Old=vel,
			},
			Angles={
				Old=v:GetAngles(),
				New=v:GetAngles()+a.Delta,
				Delta=a.Delta,
			},
			Bones=self:GetBones(v),
		}
		table.insert(ret.Attached,data);
		/*if minz < v:GetPos().z - v:BoundingRadius() then
			minz = v:GetPos().z - v:BoundingRadius();
			maxeent = v;
		end
		if maxz < v:GetPos().z + v:BoundingRadius() then
			maxz = v:GetPos().z + v:BoundingRadius();
			minzent = v;
		end*/
	end
	-- ######### Calculate new positions,angles and velocity for constraints
	-- No we don't do. Why? I found out, constraints are at the same placer - always. so, don't change them
	-- ######### Now change the base-entity itself
	local vel = e:GetVelocity();
	ret.Entity={
		Entity=e;
		Position={
			//New=g[2]:LocalToWorld(g[1]:WorldToLocal(e:GetPos())),
			New=self.JumpTarget,// + e:WorldToLocal(e:GetPos()),
			Old=e:GetPos(),
		},
		Velocity={
			//New=g[2]:LocalToWorld(g[1]:WorldToLocal(-1*vel+g[1]:GetPos())) - g[2]:GetPos(),
			New=vel, //self.JumpTarget + e:WorldToLocal(vel+e:GetPos()),
			Old=vel,
		},
		Angles={
			Old=e:GetAngles(),
			New=e:GetAngles()+a.Delta,
			Delta=a.Delta,
		},
		//Bones=self:GetBones(e),
	}
	-- ######### Calculate the heigh of the object, so it won't get stuck on the other side
	/*local localmaxz = ( e:GetPos() - maxeent:GetPos() ).z + maxeent:BoundingRadius()
	local localminz = ( e:GetPos() - minzent:GetPos() ).z - minzent:BoundingRadius()
	local trace = util.TraceLine({
		start = ret.Entity.Position.New + Vector(0,0,localmaxz),
		endpos = ret.Entity.Position.New - Vector(0,0,localminz),
	})

	if (trace.HitWorld) and (trace.Fraction == 0) then
		//local add_height = localminz - trace.HitPos.z
		local add_height = 5 + trace.Fraction * ( localmaxz - localminz );
		ret.Entity.Position.New = ret.Entity.Position.New + Vector(0,0,add_height);
	end*/

	/*local height = 60;
	local trace={
		util.TraceLine({
			start=e:GetPos(),
			endpos=e:GetPos()-Vector(0,0,height),
			filter=self,
		}),
		util.TraceLine({
			start=ret.Entity.Position.New+Vector(0,0,height),
			endpos=ret.Entity.Position.New-Vector(0,0,height),
			filter=self,
		}),
	}
	if(trace[1].Hit and trace[2].Hit) then
		local add_height = 5 + (1 - 2*trace[2].Fraction + trace[1].Fraction)*height;
		ret.Entity.Position.New = ret.Entity.Position.New + Vector(0,0,add_height);
	end*/
	return ret;
end

--################# Retrieves the valid entites for a teleport from an ent
function ENT:GetEntitiesForTeleport(e)
	if(self:Allowed(e)) then
		local entities = {};
		local constraints = {}; -- We dont need constraints
		--################# Attached Props and constraints
		local attached = {};
		//DebugDuplicator.GetAllConstrainedEntities(e,attached[1],attached[2]);
		AdvDupe.GetAllEnts( e, attached, {}, {} )
		--################# Check, if the prop is attached to the gate (like hoverballs) and disallow it's teleportataion then
		local allow = true;
		/*for _,v in pairs(attached[1]) do
			if(v == self) then
				allow = false;
				break;
			end
		end*/
		--################# Filter specific entities
		if(allow) then
			--#################  Attached props filter
			/*local allow = true;
			for _,v in pairs(attached[1]) do
				if(v:GetClass() == "gmod_spawner") then
					allow = false;
					break;
				end
			end*/
			//if(allow) then
				for _,v in pairs(attached) do
					//if(v:GetClass() ~= "gmod_spawner" and
					if (v ~= e and self:Allowed(v)) then
						table.insert(entities,v);
					end
				end
			//end
			--[[ -- Disabled - Not necsessary
			--#################  Constraint filter
			for _,v in pairs(attached[2]) do
				if(self:Allowed(v)) then
					table.insert(constraints,v);
				end
			end
			--]]
		end
		return {Entity=e,Attached=entities};
	else
		return false;
	end
end

-- The awesome StarGate sounds, ftw!
/*ENT.snd = {
	"stargate/gate_roll.mp3",
	"stargate/chevron.mp3",
	"stargate/chevron_inbound.mp3",
	"stargate/gate_open.mp3",
	"stargate/gate_travel.mp3",
	"stargate/gate_close.mp3",
	"stargate/teleport.mp3",
	"stargate/chevron_inbound_lock.mp3",
	"stargate/dial_fail.mp3",
	"stargate/iris_open.mp3",
	"stargate/iris_close.mp3",
	"stargate/iris_hit.mp3",
	"stargate/wormhole_loop.wav", -- Thx to appollo114 for sending me this sounds
	"stargate/chevron2.mp3", -- Second engage sound
	"stargate/chevron_lock.mp3", -- Chevron lock sound
}*/

--################# Teleportation function
function ENT:Teleport(tbl,base)
	local g = {self,self.other_gate} -- Gates
	local p = tbl.Position;
	local b = tbl.Bones;
	local e = tbl.Entity;
	local a = tbl.Angles;
	local v = tbl.Velocity;
	local t = type(e):lower();
	if(e ~= base) then
		p.New = base:LocalToWorld(p.New);
		v.New = base:LocalToWorld(v.New)-base:GetPos();
	end
	-- Now, rotate the velocity vector by 180 degrees around the Forward axis of the stargate
	--v.New = math.RotationMatrix(g[2]:GetForward(),0,v.New);
	e:SetNetworkedInt("last_stargate_teleport",CurTime());
	-- ######### Disable stucking (make the gates possible to pass threw) for some seconds
	//g[1]:SetSolid(0);
	//g[2]:SetSolid(0);
	//timer.Create("StarGate_"..g[1]:EntIndex().."solid",0.8,1,g[1].SetSolid,g[1],6);
	//timer.Create("StarGate_"..g[2]:EntIndex().."solid",0.8,1,g[2].SetSolid,g[2],6);
	-- ######### Player teleport
	if(t == "player") then
		//if(not g[2]:IsBlocked()) then
			-- Calculate correct viewangle
			local ai = e:GetAimVector();
			local pitch = math.deg(math.acos(ai.z))-90;
			ai.z=0; ai:Normalize();
			local parity = 1; -- This will handle, whether the y componet is below the x-axis in the unit-circle or not, so the angle has the right orientation
			if(ai:Normalize().y <0) then
				parity = -1;
			end
			local yaw = math.deg(math.acos(parity*ai.x))+(1-parity)*90;
			e:SetNetworkedString("stargate_movetype",tonumber(e:GetNetworkedString("stargate_movetype")) or e:GetMoveType());
			e:SetMoveType(MOVETYPE_NOCLIP); -- Needed, or person dont get teleported correctly
			timer.Create("RestoreMovetype"..e:EntIndex(),0.1,1,
				function (p)
					e:SetMoveType(tonumber(e:GetNetworkedString("stargate_movetype")));
					e:SetNetworkedString("stargate_movetype","");
				end
			,e);
			e:SetPos(p.New);
			e:SetEyeAngles(Angle(pitch,yaw+a.Delta.y,0));
			e:SetVelocity(v.New-v.Old);
		/*else
			e:StripWeapons();
			e:KillSilent();
		end*/
	end
	-- ######### Entity teleport
	if(t == "entity" or t == "npc" or t == "weapon") then
		//if(not g[2]:IsBlocked()) then
			-- Hoverball fix
			if(e:GetClass() == "gmod_hoverball")then
				local hp = (p.New-p.Old);
				e.dt.TargetZ = e.dt.TargetZ + hp.z; -- Set changed hoverball heigh to the hoverball
			end

			if (e:GetClass() == "gmod_toggleablehoverball")
			or (e:GetClass() == "gmod_wire_hoverball") then
				local hp = (p.New-p.Old);
				e:SetTargetZ( e:GetTargetZ() + hp.z ); -- Set changed hoverball heigh to the hoverball
			end

			local ph = e:GetPhysicsObject();
			-- ######### Teleport
			e:SetPos(p.New);
			if(t == "npc") then a.Delta.p = 0 a.Delta.r = 0 end -- Remove roll and pitch from NPCs
			e:SetAngles(a.Old + a.Delta + Angle(0,0,0));
			e:SetVelocity(-1*v.Old) -- Substract old velocity first!
			if(ph:IsValid()) then
				local ma = ph:GetMass();
				timer.Create("prop_velocity_"..e:EntIndex(),0.05,1,ph.ApplyForceCenter,ph,v.New*ma); -- Apply power so it has velocity again
				//ph:ApplyForceCenter(v.New*ma); -- Apply power so it has velocity again
			else
				-- Try another method (for grenades etc)
				e:SetVelocity(v.New);
			end
			-- ######### Move the bones of the entity
			if(b) then
				for _,v in pairs(b) do
					v.Entity:SetPos(e:LocalToWorld(v.Position));
					v.Entity:SetVelocity(e:LocalToWorld(v.Velocity)-e:GetPos());
				end
			end
		/*else
			e:Remove();
		end*/
	end
	-- ######### Vehicle teleport
	if(t == "vehicle") then
		//if(not self.other_gate:IsBlocked()) then
			e:SetAngles(a.New + Angle(0,0,0));
			e:SetPos(p.New);
			-- ######### Move the bones of the entity
			for _,v in pairs(b) do
				v.Entity:SetPos(e:LocalToWorld(v.Position));
				v.Entity:SetVelocity(e:LocalToWorld(v.Velocity)-e:GetPos());
			end
		/*else
			for _,p in pairs(player.GetAll()) do
				if(p:GetParent() == e) then
					p:StripWeapons();
					p:KillSilent();
					break;
				end
			end
			e:Remove();
		end*/
	end
	-- ######### Teleportation sounds (only for the base entity, not for the attached or you will have cummulated sounds)
	if(e == base) then
		//local mysound = ;self.snd[7]
		//local yoursound = self.snd[7];
		/*if(g[1].irisclosed) then
			mysound = self.snd[12];
		end
		if(g[2].irisclosed) then
			yoursound = self.other_gate.snd[12];
			self.other_gate:IrisHitEffect();
		end*/
		//timer.Create("StarGate_"..g[1]:EntIndex(),0,1,g[2].EmitSound,g[2],yoursound);
		//timer.Create("StarGate_"..g[1]:EntIndex().."_other_gate",0,1,g[1].EmitSound,g[1],self.snd[7]);
		-- ######### Debug
		if(self.debug) then
			player.GetByID(1):SendLua("DrawVector(Vector("..p.other.x+p.differ.x..","..p.other.y+p.differ.y..","..p.other.z+p.differ.z.."),Vector("..v.new2.x..","..v.new2.y..","..v.new2.z.."))");
		end
		self.last_teleport = CurTime();
	end
	-- ######### Use energy equivalent to the mass of the object
	//if(e and e:IsValid()) then
		//DoPropSpawnedEffect( e )
		/*local ph = e:GetPhysicsObject();
		if(ph and ph:IsValid()) then
			self:UseEnergy(ph:GetMass(),true);
		end*/
	//end
end

if !math.RotationMatrix then //if we didn't get this function from some where else, define it now.
	--################# Needed again to rotate the velocity correctly
	function math.RotationMatrix(axis,angle,vector)
		local a = axis;
		local v = vector;
		local p = math.rad(angle);
		-- Regulary rotation matrix
		local M = {
			{
				(math.cos(p) + (1-math.cos(p))*math.pow(a.x,2)),
				((1-math.cos(p))*a.x*a.y - math.sin(p)*a.z),
				((1-math.cos(p))*a.x*a.z+math.sin(p)*a.y),
			},
			{
				((1-math.cos(p))*a.y*a.x+math.sin(p)*a.z),
				(math.cos(p) + (1-math.cos(p))*math.pow(a.y,2)),
				((1-math.cos(p))*a.y*a.z - math.sin(p)*a.x),
			},
			{
				((1-math.cos(p))*a.x*a.z - math.sin(p)*a.y),
				((1-math.cos(p))*a.z*a.y+math.sin(p)*a.x),
				(math.cos(p) + (1-math.cos(p))*math.pow(a.z,2)),
			}
		}
		-- Matrix/vector multiplication
		local r = Vector();
		for i=1,3 do
				r[i] = v.x*M[i][1] + v.y*M[i][2] + v.z*M[i][3];
		end
		return r;
	end
end
