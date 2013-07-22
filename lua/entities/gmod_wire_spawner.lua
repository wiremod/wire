AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local GlobalUndoList = {}

hook.Add("EntityRemoved", "wire_spawner_EntityRemoved", function(ent)
	if not GlobalUndoList[ent] then return end
	GlobalUndoList[ent]:CheckEnts(ent)
	GlobalUndoList[ent] = nil
end)

local function MakePropNoEffect(...)
	local backup = DoPropSpawnedEffect
	DoPropSpawnedEffect = function() end
	local ret = MakeProp(...)
	DoPropSpawnedEffect = backup
	return ret
end

function ENT:Initialize()

	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:DrawShadow( false )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then phys:Wake() end

	self.UndoList = {}

	-- Spawner is "edge-triggered"
	self.SpawnLastValue = 0
	self.UndoLastValue = 0

	-- Made more efficient by updating the overlay text and
	-- Wire output only when number of active props changes (TheApathetic)
	self.CurrentPropCount = 0

	-- Add inputs/outputs (TheApathetic)
	self.Inputs = WireLib.CreateSpecialInputs(self, { "Spawn", "Undo", "UndoEnt", "SpawnEffect" }, { "NORMAL", "NORMAL", "ENTITY", "NORMAL" })
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Out", "LastSpawned", "Props" }, { "NORMAL", "ENTITY", "ARRAY" })

	Wire_TriggerOutput(self, "Props", self.UndoList)
end

function ENT:Setup( delay, undo_delay, spawn_effect )
	self.delay = delay
	self.undo_delay = undo_delay
	self.spawn_effect = spawn_effect
	self:ShowOutput()
end

function ENT:DoSpawn( pl, down )

	local ent	= self
	if (not ent:IsValid()) then return end

	local phys	= ent:GetPhysicsObject()
	if (not phys:IsValid()) then return end

	local Pos	= ent:GetPos()
	local Ang	= ent:GetAngles()
	local model	= ent:GetModel()
	local prop  = nil

	if self.spawn_effect ~= 0 then
		prop = MakeProp( pl, Pos, Ang, model, {}, {} )
	else
		prop = MakePropNoEffect( pl, Pos, Ang, model, {}, {} )
	end

	if not IsValid(prop) then return end

	prop:SetMaterial( ent:GetMaterial() )
	prop:SetColor(Color(self.r, self.g, self.b, self.a))
	prop:SetSkin( ent:GetSkin() or 0 )

	-- apply the physic's objects properties
	local phys2 = prop:GetPhysicsObject()
	phys2:SetMass( phys:GetMass() ) -- known issue: while being held with the physgun, the spawner spawns 45k mass props. Could be worked around with a Think hook, but nah...

	if not ent:IsPlayerHolding() then -- minge protection :)
		phys2:SetVelocity( phys:GetVelocity() )
		phys2:AddAngleVelocity( phys:GetAngleVelocity() - phys2:GetAngleVelocity() ) -- No SetAngleVelocity, so we must subtract the current angular velocity
	end

	local nocollide = constraint.NoCollide( prop, ent, 0, 0 )
	if (nocollide:IsValid()) then prop:DeleteOnRemove( nocollide ) end

	undo.Create("Prop")
		undo.AddEntity( prop )
		undo.AddEntity( nocollide )
		undo.SetPlayer( pl )
	undo.Finish()
	
	-- Check if the player is NULL (ab0mbs)
	if IsValid(pl) then
	pl:AddCleanup( "props", prop )
	pl:AddCleanup( "props", nocollide )
	end

	table.insert( self.UndoList, 1, prop )
	GlobalUndoList[prop] = self

	Wire_TriggerOutput(self, "LastSpawned", prop)
	self.CurrentPropCount = #self.UndoList
	Wire_TriggerOutput(self, "Out", self.CurrentPropCount)
	Wire_TriggerOutput(self, "Props", self.UndoList)
	self:ShowOutput()

	if (self.undo_delay == 0) then return end

	timer.Simple( self.undo_delay, function() if prop:IsValid() then prop:Remove() end end )

end

function ENT:DoUndo( pl )
	if not next(self.UndoList) then return end

	local ent = table.remove(self.UndoList, #self.UndoList)

	if not IsValid(ent) then
		return self:DoUndo(pl)
	end

	ent:Remove()
	WireLib.AddNotify(pl, "Undone Prop", NOTIFY_UNDO, 2 )
end

function ENT:DoUndoEnt( pl, ent )
	if not IsValid(ent) then return end

	if GlobalUndoList[ent] ~= self then return end

	ent:Remove()
	WireLib.AddNotify(pl, "Undone Prop", NOTIFY_UNDO, 2 )
end

function ENT:CheckEnts(removed_entity)
	-- Purge list of no longer existing props
	for i = #self.UndoList,1,-1 do
		local ent = self.UndoList[i]
		if not IsValid(ent) or ent == removed_entity then
			table.remove(self.UndoList, i)
		end
	end

	-- Check to see if active prop count has changed
	if (#self.UndoList ~= self.CurrentPropCount) then
		self.CurrentPropCount = #self.UndoList
		Wire_TriggerOutput(self, "Out", self.CurrentPropCount)
		Wire_TriggerOutput(self, "Props", self.UndoList)
		self:ShowOutput()
	end
end

function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()

	if (iname == "Spawn") then
		-- Spawner is "edge-triggered" (TheApathetic)
		local SpawnThisValue = value > 0
		if (SpawnThisValue == self.SpawnLastValue) then return end
		self.SpawnLastValue = SpawnThisValue

		if (SpawnThisValue) then
			-- Simple copy/paste of old numpad Spawn with a few modifications
			if (self.delay == 0) then self:DoSpawn( pl ) return end

			local TimedSpawn = 	function ( ent, pl )
				if not IsValid(ent) then return end
				ent:DoSpawn( pl )
			end

			timer.Simple( self.delay, function() TimedSpawn(self, pl) end )
		end
	elseif (iname == "Undo") then
		-- Same here
		local UndoThisValue = value > 0
		if (UndoThisValue == self.UndoLastValue) then return end
		self.UndoLastValue = UndoThisValue

		if (UndoThisValue) then self:DoUndo(pl) end
	elseif (iname == "UndoEnt") then
		self:DoUndoEnt(pl, value)
	elseif (iname == "SpawnEffect") then
		self.spawn_effect = value
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("Spawn Delay: "..self.delay.."\nUndo Delay: "..self.undo_delay.."\nActive Props: "..self.CurrentPropCount)
end

function ENT:OnRemove()
	-- unregister spawned props from GlobalUndoList
	for _,ent in ipairs(self.UndoList) do
		GlobalUndoList[ent] = nil
	end
end

function MakeWireSpawner( pl, Pos, Ang, model, delay, undo_delay, spawn_effect, mat, r, g, b, a, skin, frozen )
	if !pl:CheckLimit("wire_spawners") then return nil end

	local spawner = ents.Create("gmod_wire_spawner")
		if !spawner:IsValid() then return end
		spawner:SetPos(Pos)
		spawner:SetAngles(Ang)
		spawner:SetModel(model)
		spawner:SetRenderMode(3)
		spawner:SetMaterial(mat or "")
		spawner:SetSkin(skin or 0)
		spawner:SetColor(Color(r or 255, g or 255, b or 255, 100))
	spawner:Spawn()

	if spawner:GetPhysicsObject():IsValid() then
		local Phys = spawner:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	// In multiplayer we clamp the delay to help prevent people being idiots
	if not game.SinglePlayer() and delay < 0.1 then
		delay = 0.1
	end

	spawner:SetPlayer(pl)
	spawner:Setup(delay, undo_delay, spawn_effect)

	local tbl = {
		pl           = pl,
		mat          = mat,
		skin         = skin,
		r            = r,
		g            = g,
		b            = b,
		a            = a,
	}
	table.Merge(spawner:GetTable(), tbl)

	pl:AddCount("wire_spawners", spawner)
	pl:AddCleanup("gmod_wire_spawner", spawner)

	return spawner
end
duplicator.RegisterEntityClass("gmod_wire_spawner", MakeWireSpawner, "Pos", "Ang", "Model", "delay", "undo_delay", "spawn_effect", "mat", "r", "g", "b", "a", "skin", "frozen")

