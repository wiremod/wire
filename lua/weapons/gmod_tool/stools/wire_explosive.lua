TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Explosives"
TOOL.Command		= nil
TOOL.ConfigName		= nil
TOOL.Tab			= "Wire"

TOOL.ClientConVar[ "model" ] = "models/props_c17/oildrum001_explosive.mdl"
TOOL.ClientConVar[ "modelman" ] = ""
TOOL.ClientConVar[ "usemodelman" ] = 0
TOOL.ClientConVar[ "effect" ] = "Explosion"
TOOL.ClientConVar[ "tirgger" ] = 1		// Current tirgger
TOOL.ClientConVar[ "damage" ] = 200		// Damage to inflict
TOOL.ClientConVar[ "doblastdamage" ] = 1
TOOL.ClientConVar[ "radius" ] = 300
TOOL.ClientConVar[ "removeafter" ] = 0
TOOL.ClientConVar[ "affectother" ] = 0
TOOL.ClientConVar[ "notaffected" ] = 0
TOOL.ClientConVar[ "delaytime" ] = 0
TOOL.ClientConVar[ "delayreloadtime" ] = 0
TOOL.ClientConVar[ "freeze" ] = 0
TOOL.ClientConVar[ "weld" ] = 1
TOOL.ClientConVar[ "maxhealth" ] = 100
TOOL.ClientConVar[ "bulletproof" ] = 0
TOOL.ClientConVar[ "explosionproof" ] = 0
TOOL.ClientConVar[ "weight" ] = 400
TOOL.ClientConVar[ "explodeatzero" ] = 1
TOOL.ClientConVar[ "resetatexplode" ] = 1
TOOL.ClientConVar[ "fireeffect" ] = 1
TOOL.ClientConVar[ "coloreffect" ] = 1
TOOL.ClientConVar[ "nocollide" ] = 0
TOOL.ClientConVar[ "noparentremove" ] = 0
TOOL.ClientConVar[ "invisibleatzero" ] = 0

cleanup.Register( "wire_explosive" )

if ( CLIENT ) then
	language.Add( "Tool_wire_explosive_name", "Wired Explosives Tool" )
	language.Add( "Tool_wire_explosive_desc", "Creates a variety of different explosives for wire system." )
	language.Add( "Tool_wire_explosive_0", "Left click to place the bomb. Right click update." )
	language.Add( "WireExplosiveTool_Model", "Model:" )
	language.Add( "WireExplosiveTool_modelman", "Manual model selection:" )
	--language.Add( "WireExplosiveTool_usemodelman", "Use manual model selection:" )
	language.Add( "WireExplosiveTool_Effects", "Effect:" )
	language.Add( "WireExplosiveTool_tirgger", "Trigger value:" )
	language.Add( "WireExplosiveTool_damage", "Damage:" )
	language.Add( "WireExplosiveTool_delay", "On fire time (delay after triggered before explosion):" )
	language.Add( "WireExplosiveTool_delayreload", "Delay after explosion before it can be triggered again:" )
	language.Add( "WireExplosiveTool_remove", "Remove on explosion" )
	language.Add( "WireExplosiveTool_doblastdamage", "Do blast damage" )
	language.Add( "WireExplosiveTool_affectother", "Damaged/moved by other wired explosives" )
	language.Add( "WireExplosiveTool_notaffected", "Not moved by any phyiscal damage" )
	language.Add( "WireExplosiveTool_radius", "Blast radius:" )
	language.Add( "WireExplosiveTool_freeze", "Freeze" )
	language.Add( "WireExplosiveTool_weld", "Weld" )
	language.Add( "WireExplosiveTool_noparentremove", "Don't remove on parent remove" )
	language.Add( "WireExplosiveTool_nocollide", "No collide all but world" )
	language.Add( "WireExplosiveTool_maxhealth", "Max health:" )
	language.Add( "WireExplosiveTool_weight", "Weight:" )
	language.Add( "WireExplosiveTool_bulletproof", "Bullet proof" )
	language.Add( "WireExplosiveTool_explosionproof", "Explosion proof" )
	--language.Add( "WireExplosiveTool_fallproof", "Fall proof" )
	language.Add( "WireExplosiveTool_explodeatzero", "Explode when health = zero" )
	language.Add( "WireExplosiveTool_resetatexplode", "Reset health then" )
	language.Add( "WireExplosiveTool_fireeffect", "Enable fire effect on triggered" )
	language.Add( "WireExplosiveTool_coloreffect", "Enable color change effect on damage" )
	language.Add( "WireExplosiveTool_invisibleatzero", "Become invisible when health reaches 0" )
	language.Add( "Undone_WireExplosive", "Wired Explosive undone" )
	language.Add( "sbox_maxwire_explosive", "You've hit wired explosives limit!" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_explosive', 30)
end


function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( !self:GetSWEP():CheckLimit( "wire_explosive" ) ) then return false end

	// Get client's CVars
	local _tirgger			= self:GetClientNumber( "tirgger" )
	local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
	local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
	local _delaytime		= self:GetClientNumber( "delaytime" )
	local _delayreloadtime	= self:GetClientNumber( "delayreloadtime" )
	local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
	local _radius			= self:GetClientNumber( "radius" )
	local _affectother		= self:GetClientNumber( "affectother" ) == 1
	local _notaffected		= self:GetClientNumber( "notaffected" ) == 1
	local _freeze			= self:GetClientNumber( "freeze" ) == 1
	local _weld				= self:GetClientNumber( "weld" ) == 1
	local _maxhealth		= self:GetClientNumber( "maxhealth" )
	local _bulletproof		= self:GetClientNumber( "bulletproof" ) == 1
	local _explosionproof	= self:GetClientNumber( "explosionproof" ) == 1
	local _fallproof		= self:GetClientNumber( "fallproof" ) == 1
	local _explodeatzero	= self:GetClientNumber( "explodeatzero" ) == 1
	local _resetatexplode	= self:GetClientNumber( "resetatexplode" ) == 1
	local _fireeffect		= self:GetClientNumber( "fireeffect" ) == 1
	local _coloreffect		= self:GetClientNumber( "coloreffect" ) == 1
	local _noparentremove	= self:GetClientNumber( "noparentremove" ) == 1
	local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local _weight			= self:GetClientNumber( "weight" )
	local _invisibleatzero	= self:GetClientNumber( "invisibleatzero" ) == 1

	//Check Radius
	if (_radius > 10000) then return false end

	//get & check selected model
	_model = self:GetSelModel( true )
	if (!_model) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local explosive = MakeWireExplosive( ply, trace.HitPos, Ang, _model, _tirgger, _damage, _removeafter, _delaytime, _doblastdamage, _radius, _affectother, _notaffected, _delayreloadtime, _maxhealth, _bulletproof, _explosionproof, _fallproof, _explodeatzero, _resetatexplode, _fireeffect, _coloreffect, _invisibleatzero, _nocollide )

	local min = explosive:OBBMins()
	explosive:SetPos( trace.HitPos - trace.HitNormal * min.z )

	if ( _freeze ) then
		explosive:GetPhysicsObject():Sleep() //will freeze the explosive till something touches it
	end

	// Don't weld to world
	local const, nocollid
	if ( trace.Entity:IsValid() && _weld ) then
		if (_noparentremove) then
			const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0 )
		else
			const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, true )
		end
	end

	if (_weight <= 0) then _weight = 1 end
	explosive.Entity:GetPhysicsObject():SetMass(_weight)
	// Make sure the weight is duplicated as well (TheApathetic)
	duplicator.StoreEntityModifier( explosive, "MassMod", {Mass = _weight} )

	undo.Create("WireExplosive")
		undo.AddEntity( explosive )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_explosive", explosive )
	ply:AddCleanup( "wire_explosive", const )

	return true

end


function TOOL:GetSelModel( showerr )

	local model		= self:GetClientInfo( "model" )

	if (model == "usemanmodel") then
		local _modelman = self:GetClientInfo( "modelman" )
		if (_modelman && string.len(_modelman) > 0) then
			model = _modelman
		else
			local message = "You need to define a model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	elseif (model == "usereloadmodel") then
		if (self.reloadmodel && string.len(self.reloadmodel) > 0) then
			model = self.reloadmodel
		else
			local message = "You need to select a model model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	end

	if (not util.IsValidModel(model)) then
		//something fucked up, notify user of that
		local message = "This is not a valid model."..model
		if (showerr) then
			self:GetOwner():PrintMessage(3, message)
			self:GetOwner():PrintMessage(2, message)
		end
		return false
	end
	if (not util.IsValidProp(model)) then return false end

	return model
end


function TOOL:RightClick( trace )
	if (CLIENT) then return true end

	local ply = self:GetOwner()
	//shot an explosive, update it
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_explosive" && trace.Entity.pl == ply ) then
		//double you code double your fun (copy from above)
		// Get client's CVars
		local tirgger			= self:GetClientNumber( "tirgger" )
		local damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
		local removeafter		= self:GetClientNumber( "removeafter" ) == 1
		local delaytime			= self:GetClientNumber( "delaytime" )
		local delayreloadtime	= self:GetClientNumber( "delayreloadtime" )
		local doblastdamage		= self:GetClientNumber( "doblastdamage" ) == 1
		local radius			= self:GetClientNumber( "radius" )
		local affectother		= self:GetClientNumber( "affectother" ) == 1
		local notaffected		= self:GetClientNumber( "notaffected" ) == 1
		local freeze			= self:GetClientNumber( "freeze" ) == 1
		local weld				= self:GetClientNumber( "weld" ) == 1
		local maxhealth			= self:GetClientNumber( "maxhealth" )
		local bulletproof		= self:GetClientNumber( "bulletproof" ) == 1
		local explosionproof	= self:GetClientNumber( "explosionproof" ) == 1
		local fallproof			= self:GetClientNumber( "fallproof" ) == 1
		local explodeatzero		= self:GetClientNumber( "explodeatzero" ) == 1
		local resetatexplode	= self:GetClientNumber( "resetatexplode" ) == 1
		local fireeffect		= self:GetClientNumber( "fireeffect" ) == 1
		local coloreffect		= self:GetClientNumber( "coloreffect" ) == 1
		local noparentremove	= self:GetClientNumber( "noparentremove" ) == 1
		local nocollide			= self:GetClientNumber( "nocollide" ) == 1
		local weight			= self:GetClientNumber( "weight" )
		local invisibleatzero	= self:GetClientNumber( "invisibleatzero" ) == 1

		UpdateWireExplosive(trace.Entity, tirgger, damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

		if (weight <= 0) then weight = 1 end
		trace.Entity:GetPhysicsObject():SetMass(_weight)
		// Make sure the weight is duplicated as well (TheApathetic)
		duplicator.StoreEntityModifier( trace.Entity, "MassMod", {Mass = weight} )

		//reset color in case we turned the color effect off and it's still red
		trace.Entity:SetColor(255, 255, 255, 255)

		return true
	end

end

function TOOL:Reload( trace )
	//get the model of what was shot and set our reloadmodel to that
	//model info getting code mostly copied from OverloadUT's What Is That? STool
	if !trace.Entity then return false end
	local ent = trace.Entity
	local ply = self:GetOwner()
	local class = ent:GetClass()
	if class == "worldspawn" then
		return false
	else
		local model = ent:GetModel()
		local message = "Model selected: "..model
		self.reloadmodel = model
		ply:PrintMessage(3, message)
		ply:PrintMessage(2, message)
	end
	return true
end

if SERVER then

	function UpdateWireExplosive(explosive, trigger, damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

		explosive:Setup( damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

		local ttable = {
			key = trigger,
			nocollide = nocollide,
			damage = damage,
			removeafter = removeafter,
			delaytime = delaytime,
			doblastdamage = doblastdamage,
			radius = radius,
			affectother = affectother,
			notaffected = notaffected,
			delayreloadtime = delayreloadtime,
			maxhealth = maxhealth,
			bulletproof = bulletproof,
			explosionproof = explosionproof,
			fallproof = fallproof,
			explodeatzero = explodeatzero,
			resetatexplode = resetatexplode,
			fireeffect = fireeffect,
			coloreffect = coloreffect,
			invisibleatzero = invisibleatzero
		}
		table.Merge( explosive:GetTable(), ttable )

	end


	function MakeWireExplosive(pl, Pos, Ang, model, trigger, damage, removeafter, delaytime, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

		if ( !pl:CheckLimit( "wire_explosive" ) ) then return nil end

		local explosive = ents.Create( "gmod_wire_explosive" )

		explosive:SetModel( model )
		explosive:SetPos( Pos )
		explosive:SetAngles( Ang )
		explosive:Spawn()
		explosive:Activate()

		explosive:SetPlayer( pl )
		explosive.pl = pl

		UpdateWireExplosive( explosive, trigger, damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

		pl:AddCount( "wire_explosive", explosive )

		return explosive

	end

	duplicator.RegisterEntityClass( "gmod_wire_explosive", MakeWireExplosive, "Pos", "Ang", "Model", "key", "damage", "removeafter", "delaytime", "doblastdamage", "radius", "affectother", "notaffected", "delayreloadtime", "maxhealth", "bulletproof", "explosionproof", "fallproof", "explodeatzero", "resetatexplode", "fireeffect", "coloreffect", "invisibleatzero", "nocollide" )

end

function TOOL:UpdateGhostWireExplosive( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() ) then -- || trace.Entity:GetClass() == "gmod_wire_explosive"
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetSelModel()) then

		local _model = self:GetSelModel()
		if (!_model) then return end

		self:MakeGhostEntity( _model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireExplosive( self.GhostEntity, self:GetOwner() )

end
