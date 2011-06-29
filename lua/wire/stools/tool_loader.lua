-- $Rev: 1731 $
-- $LastChangedDate: 2009-09-24 15:06:08 -0700 (Thu, 24 Sep 2009) $
-- $LastChangedBy: tad2020 $

--MsgN("Loading Wire Tools")

AddCSLuaFile( "tool_loader.lua" )


local function LoadTools()
	-- load server side code for tools
	if SERVER then
		include( "sv_wirestools.lua" )
		include( "sv_detection.lua" )
		include( "sv_display.lua" )
		include( "sv_io.lua" )
		include( "sv_physics.lua" )
	end

	-- load tools
	include("gates.lua")
	include("detection.lua")
	include("display.lua")
	include("io.lua")
	include("physics.lua")

	-- close last TOOL
	if TOOL then WireToolSetup.close() end
end


-- prevent showing the ghost when poiting at any class in the TOOL.NoGhostOn table
local function NoGhostOn(self, trace)
	return self.NoGhostOn and table.HasValue( self.NoGhostOn, trace.Entity:GetClass())
end


WireToolObj = {}
setmetatable( WireToolObj, ToolObj )


WireToolObj.Tab			= "Wire"


-- optional LeftClick tool function for basic tools that just place/weld a device [default]
function WireToolObj:LeftClick( trace )
	if not trace.HitPos or trace.Entity:IsPlayer() or trace.Entity:IsNPC() or (SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
	if self.NoLeftOnClass and trace.HitNonWorld and (trace.Entity:GetClass() == self.WireClass or NoGhostOn(self, trace)) or (SERVER and trace.Entity:GetClass() == self.WireClass and trace.Entity.pl ~= self:GetOwner()) then return false end

	if CLIENT then return true end

	local ply = self:GetOwner()

	local ent = self:LeftClick_Make( trace, ply ) -- WireToolObj.LeftClick_Make will be called if another function was not defined

	return self:LeftClick_PostMake( ent, ply, trace )
end

if SERVER then
	--
	function WireToolObj:LeftClick_Make( trace, ply )
		-- hit our own class, update
		if self:CheckHitOwnClass(trace) then
			self:LeftClick_Update(trace)
			return true
		end

		local model = self:GetModel()
		if self:CheckMaxLimit() or self:CheckValidModel(model) then return false end

		local Ang = self:GetAngle( trace )

		local ent = self:MakeEnt( ply, model, Ang, trace )

		self:PostMake_SetPos( ent, trace )

		return ent
	end

	--
	-- to prevent update, set TOOL.NoLeftOnClass = true
	function WireToolObj:LeftClick_Update( trace )
		trace.Entity:Setup(self:GetConVars())
	end

	--
	-- this function needs to return true if the tool beam should be "fired"
	function WireToolObj:LeftClick_PostMake( ent, ply, trace )
		if ent == true then return true end
		if ent == nil or ent == false or not ent:IsValid() then return false end

		-- Parenting
		local nocollide
		if (self.ClientConVar.parent and self:GetClientNumber( "parent" ) == 1) then
			if (trace.Entity:IsValid()) then

				-- Nocollide the gate to the prop to make adv duplicator (and normal duplicator) find it
				if (!self.ClientConVar.noclip or self:GetClientNumber( "noclip" ) == 1) then
					nocollide = constraint.NoCollide( ent, trace.Entity, 0,trace.PhysicsBone )
				end

				ent:SetParent( trace.Entity )
			end
		end

		-- Welding
		local const
		if not self.ClientConVar.weld or self:GetClientNumber( "weld" ) == 1 then
			const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
		end


		undo.Create( self.WireClass )
			undo.AddEntity( ent )
			if (const) then undo.AddEntity( const ) end
			if (nocollide) then undo.AddEntity( nocollide ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		ply:AddCleanup( self.WireClass, ent )

		return true
	end
end

-- Unparent
function WireToolObj:Reload( trace )
	if (!trace or !trace.Hit) then return false end
	if (CLIENT and trace.Entity) then return true end
	if (trace.Entity:GetParent():IsValid()) then

		-- Get its position
		local pos = trace.Entity:GetPos()

		-- Unparent
		trace.Entity:SetParent()

		-- Teleport it back to where it was before unparenting it (because unparenting causes issues which makes the gate teleport to random wierd places)
		trace.Entity:SetPos( pos )

		-- Wake
		local phys = trace.Entity:GetPhysicsObject()
		if (phys) then
			phys:Wake()
		end

		-- Notify
		self:GetOwner():ChatPrint("Entity unparented.")
		return true
	end
	return false
end

-- basic UpdateGhost function that should cover most of wire's ghost updating needs [default]
function WireToolObj:UpdateGhost( ent )
	if not ent or not ent:IsValid() then return end

	local trace = self:GetOwner():GetEyeTrace()
	if not trace.Hit then return end

	-- don't draw the ghost if we hit nothing, a player, an npc, the type of device this tool makes, or any class this tool says not to
	if not trace.Hit or trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity:GetClass() == self.WireClass or NoGhostOn(self, trace) then
		ent:SetNoDraw( true )
		return
	end

	-- modify the ghosts angle
	local Ang = self:GetAngle( trace )
	ent:SetAngles( Ang )

	self:SetPos( ent, trace )

	--show the ghost
	ent:SetNoDraw( false )
end


-- option tool Think function for updating the pos of the ghost and making one when needed [default]
function WireToolObj:Think()
	local model = self:GetModel()
	if not self.GhostEntity or not self.GhostEntity:IsValid() or self.GhostEntity:GetModel() ~= model then
		if self.GetGhostAngle then -- the tool as a function for getting the proper angle for the ghost
			self:MakeGhostEntity( model, Vector(0,0,0), self:GetGhostAngle(self:GetOwner():GetEyeTrace()) )
		else -- the tool gives a fixed angle to add else use a zero'd angle
			self:MakeGhostEntity( model, Vector(0,0,0), self.GhostAngle or Angle(0,0,0) )
		end
	end
	self:UpdateGhost( self.GhostEntity )
end


if SERVER then
	--
	function WireToolObj:CheckHitOwnClass( trace )
		return trace.Entity:IsValid() and trace.Entity:GetClass() == self.WireClass and trace.Entity.pl == self:GetOwner()
	end

	--
	function WireToolObj:CheckMaxLimit()
		return not self:GetSWEP():CheckLimit(self.MaxLimitName)
	end

	-- Allow ragdolls to be used?
	function WireToolObj:CheckValidModel( model )
		return not util.IsValidModel(model) or not util.IsValidProp(model)
	end

	--
	function WireToolObj:GetModel()
		if self.Model then
			return self.Model
		elseif not self:CheckValidModel(self:GetClientInfo( "model" )) then --use a valid model or the server crashes :<
			return self:GetClientInfo( "model" )
		else
			return "models/props_c17/oildrum001.mdl" --use some other random, valid prop instead if they fuck up
		end
	end
else
	--
	function WireToolObj:GetModel()
		return self.Model or self:GetClientInfo( "model" ) --meh, they are crash themselves if they want
	end
end

--
function WireToolObj:GetAngle( trace )
	local Ang = trace.HitNormal:Angle()
	if self.GetGhostAngle then -- the tool as a function for getting the proper angle for the ghost
		Ang = self:GetGhostAngle( trace )
	elseif self.GhostAngle then -- the tool gives a fixed angle to add
		Ang = Ang + self.GhostAngle
	end
	Ang.pitch = Ang.pitch + 90
	return Ang
end

--
function WireToolObj:SetPos( ent, trace )
	-- move the ghost to aline properly to where the device will be made
	local min = ent:OBBMins()
	if self.GetGhostMin then -- tool has a function for getting the min
		ent:SetPos( trace.HitPos - trace.HitNormal * self:GetGhostMin( min, trace ) )
	elseif self.GhostMin then -- tool gives the axis for the OBBmin to use
		ent:SetPos( trace.HitPos - trace.HitNormal * min[self.GhostMin] )
	else -- default to the z OBBmin
		ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end
end
if SERVER then WireToolObj.PostMake_SetPos = WireToolObj.SetPos end




-- function used by TOOL.BuildCPanel
WireToolHelpers = {}

if CLIENT then
	-- gets the TOOL since TOOL.BuildCPanel isn't passed this var. wts >_<
	local function GetTOOL(mode)
		for _,wep in ipairs(LocalPlayer():GetWeapons()) do
			if wep:GetClass() == "gmod_tool" then
				wep:GetToolObject(mode)
			end
		end
	end

	-- makes the preset control for use cause we're lazy
	function WireToolHelpers.MakePresetControl(panel, mode, folder)
		if not mode or not panel then return end
		local TOOL = GetTOOL(mode)
		if not TOOL then return end
		local ctrl = vgui.Create( "ControlPresets", panel )
		ctrl:SetPreset(folder or mode)
		if TOOL.ClientConVar then
			local options = {}
			for k, v in pairs(TOOL.ClientConVar) do
				if k ~= "id" then
					k = mode.."_"..k
					options[k] = v
					ctrl:AddConVar(k)
				end
			end
			ctrl:AddOption("#Default", options)
		end
		panel:AddPanel( ctrl )
	end

	-- adds the neato model select control
	function WireToolHelpers.MakeModelSel(panel, mode)
		local TOOL = GetTOOL(mode)
		if not TOOL then return end
		ModelPlug_AddToCPanel(panel, TOOL.short_name, TOOL.Mode, "#ToolWireIndicator_Model")
	end
end



WireToolSetup = {}

-- sets the ToolCategory for every wire tool made fallowing its call
function WireToolSetup.setCategory( s_cat )
	WireToolSetup.cat = "Wire - "..s_cat
end

-- makes a new TOOL
--  s_mode: Tool_mode, same as the old tool lua file name, minus the "wire_" part
--  s_name: Proper name for the tool
--  s_class: For tools that make a device. Should begin with "gmod_wire_". Can be nil if not using WireToolObj.LeftClick or WireToolSetup.BaseLang
--  f_toolmakeent: Server side function for making the tools device. Can be nil if not using WireToolObj.LeftClick
function WireToolSetup.open( s_mode, s_name, s_class, f_toolmakeent, s_pluralname )
	-- close the previous TOOL if not done so already
	if TOOL then WireToolSetup.close() end

	-- make new TOOL object
	TOOL				= WireToolObj:Create()

	-- default vars,
	TOOL.Mode			= "wire_"..s_mode
	TOOL.short_name		= s_mode
	TOOL.Category		= WireToolSetup.cat
	TOOL.Name			= s_name
	TOOL.PluralName		= s_pluralname
	TOOL.WireClass		= s_class
	if f_toolmakeent then
		TOOL.LeftClick_Make = f_toolmakeent
	end
	local info = debug.getinfo(2, "S")
	if info then
		TOOL.SourceFile = info.short_src
	end
end

-- closes and saves the open TOOL obj
function WireToolSetup.close()
	TOOL:CreateConVars()
	SWEP.Tool[TOOL.Mode] = TOOL
	TOOL = nil
end


-- optional function to add the basic language for basic tools
function WireToolSetup.BaseLang( pluralname )
	if CLIENT then
		language.Add( "undone_"..TOOL.WireClass, "Undone Wire "..TOOL.Name )
		language.Add( "Cleanup_"..TOOL.WireClass, "Wire "..(TOOL.PluralName or pluralname) )
		language.Add( "Cleaned_"..TOOL.WireClass, "Cleaned Up Wire "..(TOOL.PluralName or pluralname) )
	end
	cleanup.Register(TOOL.WireClass)
end


--
function WireToolSetup.SetupMax( i_limit, s_maxlimitname , s_warning )
	TOOL.MaxLimitName = s_maxlimitname
	if CLIENT then
		language.Add("SBoxLimit_"..TOOL.MaxLimitName, s_warning)
		AddWireAdminMaxDevice(TOOL.PluralName, TOOL.MaxLimitName)
	else
		CreateConVar("sbox_max"..TOOL.MaxLimitName, i_limit)
	end
end

LoadTools()
