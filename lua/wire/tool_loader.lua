if SERVER then AddCSLuaFile() end

local function LoadTools()
	-- load tools
	for _, filename in pairs(file.Find("wire/stools/*.lua","LUA")) do
		include("wire/stools/"..filename)
		AddCSLuaFile("wire/stools/"..filename)
	end

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
	if self.NoLeftOnClass and trace.HitNonWorld and (trace.Entity:GetClass() == self.WireClass or NoGhostOn(self, trace)) then return false end

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
		if not self:CheckMaxLimit() or not self:CheckValidModel(model) then return false end

		local Ang = self:GetAngle( trace )

		local ent = self:MakeEnt( ply, model, Ang, trace )

		if IsValid(ent) then self:PostMake_SetPos( ent, trace ) end

		return ent
	end

	-- Default MakeEnt function, override to use a different MakeWire* function
	function WireToolObj:MakeEnt( ply, model, Ang, trace )
		local ent = WireLib.MakeWireEnt( ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model}, self:GetConVars() )
		if ent and ent.RestoreNetworkVars then ent:RestoreNetworkVars(self:GetDataTables()) end
		return ent
	end

	function WireToolObj:GetConVars() return end

	function WireToolObj:GetDataTables() return {} end

	--
	-- to prevent update, set TOOL.NoLeftOnClass = true
	function WireToolObj:LeftClick_Update( trace )
		if trace.Entity:IsValid() then
			if trace.Entity.Setup then trace.Entity:Setup(self:GetConVars()) end
			if trace.Entity.RestoreNetworkVars then trace.Entity:RestoreNetworkVars(self:GetDataTables()) end
		end
	end

	--
	-- this function needs to return true if the tool beam should be "fired"
	function WireToolObj:LeftClick_PostMake( ent, ply, trace )
		if ent == true then return true end
		if ent == nil or ent == false or not ent:IsValid() then return false end

		-- Parenting
		local nocollide, const
		if self:GetClientNumber( "parent" ) == 1 then
			if (trace.Entity:IsValid()) then
				-- Nocollide the gate to the prop to make adv duplicator (and normal duplicator) find it
				if (not self.ClientConVar.noclip or self:GetClientNumber( "noclip" ) == 1) then
					nocollide = constraint.NoCollide( ent, trace.Entity, 0,trace.PhysicsBone )
				end

				ent:SetParent( trace.Entity )
			end
		elseif not self:GetOwner():KeyDown(IN_WALK) then
			-- Welding
			const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true, false, self:GetOwner():GetInfo( "wire_tool_weldworld" )~="0" )

			-- Nocollide All
			if self:GetOwner():GetInfo( "wire_tool_nocollide" )~="0" then
				ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
			end
		end

		undo.Create( self.WireClass )
			undo.AddEntity( ent )
			if (const) then undo.AddEntity( const ) end
			if (nocollide) then undo.AddEntity( nocollide ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		ply:AddCleanup( self.WireClass, ent )

		if self.PostMake then self:PostMake(ent, ply, trace) end
		duplicator.ApplyEntityModifiers(ply, ent)

		return true
	end
end

function WireToolObj:Reload( trace )
	if not IsValid(trace.Entity) then return false end
	if CLIENT then return true end
	if self.ReloadSetsModel then
		self:GetOwner():ConCommand(self.Mode.."_model " .. trace.Entity:GetModel())
		self:GetOwner():PrintMessage( HUD_PRINTTALK, self.Name.." model set to " .. trace.Entity:GetModel() )
		return true
	end
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
	if not IsValid(ent) then return end

	local trace = self:GetOwner():GetEyeTrace()
	if not trace.Hit then return end

	-- don't draw the ghost if we hit nothing, a player, an npc, the type of device this tool makes, or any class this tool says not to
	if IsValid(trace.Entity) and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity:GetClass() == self.WireClass or NoGhostOn(self, trace)) then
		ent:SetNoDraw( true )
		return
	end

	ent:SetAngles( self:GetAngle( trace ) )
	self:SetPos( ent, trace )

	--show the ghost
	ent:SetNoDraw( false )
end


-- option tool Think function for updating the pos of the ghost and making one when needed [default]
function WireToolObj:Think()
	local model = self:GetModel()
	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= model then
		if self.GetGhostAngle then -- the tool as a function for getting the proper angle for the ghost
			self:MakeGhostEntity( model, Vector(0,0,0), self:GetGhostAngle(self:GetOwner():GetEyeTrace()) )
		else -- the tool gives a fixed angle to add else use a zero'd angle
			self:MakeGhostEntity( model, Vector(0,0,0), self.GhostAngle or Angle(0,0,0) )
		end
		if IsValid(self.GhostEntity) and CLIENT then self.GhostEntity:SetPredictable(true) end
	end
	self:UpdateGhost( self.GhostEntity )
end

function WireToolObj:CheckHitOwnClass( trace )
	return trace.Entity:IsValid() and trace.Entity:GetClass() == self.WireClass
end

if SERVER then
	function WireToolObj:CheckMaxLimit()
		return self:GetSWEP():CheckLimit(self.MaxLimitName or (self.Mode.."s"))
	end
end

-- Allow ragdolls to be used?
local ValidModelCache = {[""] = false}
function WireToolObj:CheckValidModel( model )
	local val = ValidModelCache[model or ""]
	if val~=nil then return val end
	if SERVER then
		ValidModelCache[model] = util.IsValidModel(model) and util.IsValidProp(model)
	else
		ValidModelCache[model] = file.Exists(model,"GAME") -- util.IsValidModel doesn't work clientside until after the server runs util.PrecacheModel
	end
	return ValidModelCache[model]
end

function WireToolObj:GetModel()
	local model_convar = self:GetClientInfo( "model" )
	if self.ClientConVar.modelsize then
		local modelsize = self:GetClientInfo( "modelsize" )
		if modelsize ~= "" then
			local model = string.sub(model_convar, 1, -5) .."_".. modelsize .. string.sub(model_convar, -4)
			if self:CheckValidModel(model) then return model end
			model = string.GetPathFromFilename(model_convar) .. modelsize .."_".. string.GetFileFromFilename(model_convar)
			if self:CheckValidModel(model) then return model end
		end
	end
	if self:CheckValidModel(model_convar) then --use a valid model or the server crashes :<
		return model_convar
	end
	return self.Model or self.ClientConVar.model or "models/props_c17/oildrum001.mdl"
end

function WireToolObj:GetAngle( trace )
	local Ang
	if math.abs(trace.HitNormal.x) < 0.001 and math.abs(trace.HitNormal.y) < 0.001 then
		Ang = Vector(0,0,trace.HitNormal.z):Angle()
	else
		Ang = trace.HitNormal:Angle()
	end
	if self.GetGhostAngle then -- the tool as a function for getting the proper angle for the ghost
		Ang = self:GetGhostAngle( trace )
	elseif self.GhostAngle then -- the tool gives a fixed angle to add
		Ang = Ang + self.GhostAngle
	end
	if self.ClientConVar.createflat then
		-- Screen models need a bit of adjustment
		if self:GetClientNumber("createflat") == 0 then
			Ang.pitch = Ang.pitch + 90
		end
		local model = self:GetModel()
		if string.find(model, "pcb") or string.find(model, "hunter") then
			-- PHX Screen models should thus be +180 when not flat, +90 when flat
			Ang.pitch = Ang.pitch + 90
		end
	else
		Ang.pitch = Ang.pitch + 90
	end

	return Ang
end

function WireToolObj:SetPos( ent, trace )
	-- move the ghost to aline properly to where the device will be made
	local min = ent:OBBMins()
	if self.GetGhostMin then -- tool has a function for getting the min
		ent:SetPos( trace.HitPos - trace.HitNormal * self:GetGhostMin( min, trace ) )
	elseif self.GhostMin then -- tool gives the axis for the OBBmin to use
		ent:SetPos( trace.HitPos - trace.HitNormal * min[self.GhostMin] )
	elseif self.ClientConVar.createflat and (self:GetClientNumber("createflat") == 1) ~= ((string.find(self:GetModel(), "pcb") or string.find(self:GetModel(), "hunter")) ~= nil) then
		-- Screens have odd models. If createflat is 1, or its 0 and its a PHX model, use max.x
		ent:SetPos( trace.HitPos + trace.HitNormal * ent:OBBMaxs().x )
	else -- default to the z OBBmin
		ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	end
end
if SERVER then WireToolObj.PostMake_SetPos = WireToolObj.SetPos end

if CLIENT then
	local fonttab = {font = "Helvetica", size = 60, weight = 900}
	for size=60,20,-2 do
		fonttab.size = size
		surface.CreateFont("GmodToolScreen"..size, fonttab)
	end

	local iconparams = {
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$ignorez"] = 1 -- This is essential, since the base Gmod screen_bg has ignorez, otherwise it'll draw overtop of us
	}
	local txBackground = surface.GetTextureID("models/weapons/v_toolgun/wirescreen_bg")
	function WireToolObj:DrawToolScreen(width, height)
		surface.SetTexture(txBackground)
		surface.DrawTexturedRect(0, 0, width, height)

		local text = self.Name
		if self.ScreenFont then
			surface.SetFont(self.ScreenFont)
		else
			for size=60,20,-2 do
				surface.SetFont("GmodToolScreen"..size)
				local x,y = surface.GetTextSize(text)
				if x <= (width - 16) then
					self.ScreenFont = "GmodToolScreen"..size
					break
				end
			end
		end
		local w, h = surface.GetTextSize(text)
		local x = width/2 - w/2
		local y = 105 - h/2

		-- Draw shadow first
		surface.SetTextColor(0, 0, 0, 255)
		surface.SetTextPos(x + 3, y + 3)
		surface.DrawText(text)

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetTextPos(x, y)
		surface.DrawText(text)

		iconparams[ "$basetexture" ] = "spawnicons/"..self:GetModel():sub(1,-5)
		local mat = CreateMaterial(self:GetModel() .. "_DImage", "UnlitGeneric", iconparams )
		surface.SetMaterial(mat)
		surface.DrawTexturedRect( 128 - 32, 150, 64, 64)

		local on = self:GetOwner():GetInfo( "wire_tool_weldworld" )~="0" and not self:GetOwner():KeyDown(IN_WALK)
		draw.DrawText("World Weld:  "..(on and "On" or "Off"),
			"GmodToolScreen20",
			5, height-38,
			Color(on and 150 or 255, on and 255 or 150, 150, 255)
		)
		local on = self:GetOwner():GetInfo( "wire_tool_nocollide" )~="0" and not self:GetOwner():KeyDown(IN_WALK)
		draw.DrawText("Nocollide All: "..(on and "On" or "Off"),
			"GmodToolScreen20",
			5, height-22,
			Color(on and 150 or 255, on and 255 or 150, 150, 255)
		)
	end

	CreateClientConVar( "wire_tool_weldworld", "0", true, true )
	CreateClientConVar( "wire_tool_nocollide", "1", true, true )
	local function CreateCPanel_WireOptions( Panel )
		Panel:ClearControls()

		Panel:Help("Hold Alt while spawning Wire entities\nto disable Weld and Nocollide All")
		Panel:CheckBox("Allow Weld to World", "wire_tool_weldworld")
		Panel:CheckBox("Nocollide All", "wire_tool_nocollide")
	end
	hook.Add("PopulateToolMenu","WireLib_WireOptions",function()
		spawnmenu.AddToolMenuOption( "Wire", "Options", "WireOptions", "Tool Options", "", "", CreateCPanel_WireOptions, nil )
	end)
end


-- function used by TOOL.BuildCPanel
WireToolHelpers = {}

-- gets the TOOL since TOOL.BuildCPanel isn't passed this var. wts >_<
function WireToolHelpers.GetTOOL(mode, ply)
	if CLIENT then ply = LocalPlayer() end
	if not ply then return end

	for _,wep in ipairs(ply:GetWeapons()) do
		if wep:GetClass() == "gmod_tool" then
			return wep:GetToolObject(mode)
		end
	end
end

-- similar to GetTool (above), gets the specified tool, but only if it's the currently actively held weapon by the player
function WireToolHelpers.GetActiveTOOL(mode, ply)
	if CLIENT then ply = LocalPlayer() end
	if not ply then return end

	local activeWep = ply:GetActiveWeapon()
	if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= mode then return end

	return activeWep:GetToolObject(mode)
end

if CLIENT then
	-- makes the preset control for use cause we're lazy
	function WireToolHelpers.MakePresetControl(panel, mode, folder)
		if not mode or not panel then return end
		local TOOL = WireToolHelpers.GetTOOL(mode)
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

	function WireToolHelpers.MakeModelSizer(panel, convar)
		return panel:AddControl("ListBox", {
			Label = "Model Size",
			Options = {
				["normal"] = { [convar] = "" },
				["mini"] = { [convar] = "mini" },
				["nano"] = { [convar] = "nano" }
			}
		})
	end

	-- adds the neato model select control
	function WireToolHelpers.MakeModelSel(panel, mode)
		local TOOL = WireToolHelpers.GetTOOL(mode)
		if not TOOL then return end
		ModelPlug_AddToCPanel(panel, TOOL.short_name, TOOL.Mode, true)
	end
end

function WireToolHelpers.SetupSingleplayerClickHacks(TOOL) end -- empty stub outside of Singleplayer
if game.SinglePlayer() then -- wtfgarry
	-- In Singleplayer, "Because its Predicted", LeftClick/RightClick/Reload don't fire Clientside. Lets work around that
	if SERVER then
		util.AddNetworkString("wire_singleplayer_tool_wtfgarry")
		local function send_singleplayer_click(ply, funcname, toolname)
			net.Start("wire_singleplayer_tool_wtfgarry")
				net.WriteString(funcname)
				net.WriteString(toolname)
			net.Send(ply)
		end

		function WireToolHelpers.SetupSingleplayerClickHacks(TOOL)
			local originalLeftClick = TOOL.LeftClick
			function TOOL:LeftClick(trace)
				send_singleplayer_click(self:GetOwner(), "LeftClick", TOOL.Mode)
				return originalLeftClick(self, trace)
			end
			local originalRightClick = TOOL.RightClick
			function TOOL:RightClick(trace)
				send_singleplayer_click(self:GetOwner(), "RightClick", TOOL.Mode)
				return originalRightClick(self, trace)
			end
			local originalReload = TOOL.Reload
			function TOOL:Reload(trace)
				send_singleplayer_click(self:GetOwner(), "Reload", TOOL.Mode)
				return originalReload(self, trace)
			end
		end
	elseif CLIENT then
		net.Receive( "wire_singleplayer_tool_wtfgarry", function(len)
			local funcname = net.ReadString()
			local toolname = net.ReadString()
			local tool = WireToolHelpers.GetTOOL(toolname)
			if not tool then return end
			tool[funcname](tool, LocalPlayer():GetEyeTrace())
		end)
	end
end


WireToolSetup = {}

-- sets the ToolCategory for every wire tool made fallowing its call
function WireToolSetup.setCategory( s_cat, ... )
	WireToolSetup.cat = s_cat

	local categories = {...}
	if #categories > 0 then
		WireToolSetup.Wire_MultiCategories = categories
	else
		WireToolSetup.Wire_MultiCategories = nil
	end
end

-- Sets the icon for the current tool
function WireToolSetup.setToolMenuIcon( icon )
	if SERVER then return end
	TOOL.Wire_ToolMenuIcon = icon
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
	TOOL.Wire_MultiCategories = WireToolSetup.Wire_MultiCategories
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
function WireToolSetup.BaseLang()
	if CLIENT then
		language.Add( "undone_"..TOOL.WireClass, "Undone Wire "..TOOL.Name )
		if TOOL.PluralName then
			language.Add( "Cleanup_"..TOOL.WireClass, "Wire "..TOOL.PluralName )
			language.Add( "Cleaned_"..TOOL.WireClass, "Cleaned Up Wire "..TOOL.PluralName )
		end
		for _, info in pairs(TOOL.Information or {}) do
			if info.text then
				language.Add("Tool." .. TOOL.Mode .. "." .. info.name, info.text)
			end
		end
	end
	cleanup.Register(TOOL.WireClass)
end

function WireToolSetup.SetupMax( i_limit, s_maxlimitname , s_warning )
	TOOL.MaxLimitName = s_maxlimitname or TOOL.WireClass:sub(6).."s"
	s_warning = s_warning or "You've hit the Wire "..TOOL.PluralName.." limit!"
	if CLIENT then
		language.Add("SBoxLimit_"..TOOL.MaxLimitName, s_warning)
		AddWireAdminMaxDevice(TOOL.PluralName, TOOL.MaxLimitName)
	else
		CreateConVar("sbox_max"..TOOL.MaxLimitName, i_limit)
	end
end

-- Sets up a tool with RightClick, Reload, and DrawHUD functions that link/unlink entities
-- The SENT should have ENT:LinkEnt(e), ENT:UnlinkEnt(e), and ENT:ClearEntities()
-- It should also send ENT.Marks to the client via WireLib.SendMarks(ent)
-- Pass it true to disable linking multiple entities (ie for Pod Controllers)
function WireToolSetup.SetupLinking(SingleLink, linkedname)
	TOOL.SingleLink = SingleLink
	linkedname = linkedname or "entity"
	if CLIENT then
		if TOOL.Information == nil or next(TOOL.Information) == nil then
			TOOL.Information = {
				{ name = "left_0", stage = 0 },
				{ name = "right_0", stage = 0 },
				{ name = "reload_0", stage = 0 },
				{ name = "right_1", stage = 1 },
				{ name = "right_2", stage = 2 },
			}
			if not SingleLink then
				table.insert(TOOL.Information, { name = "info_1", stage = 1 })
				table.insert(TOOL.Information, { name = "info_2", stage = 2 })
				table.insert(TOOL.Information, { name = "reload_2", stage = 2 })
			end
		end

		language.Add( "Tool."..TOOL.Mode..".left_0", "Create/Update "..TOOL.Name )
		language.Add( "Tool."..TOOL.Mode..".right_0", "Select a " .. TOOL.Name .. " to link" )
		language.Add( "Tool."..TOOL.Mode..".reload_0",  "Unlink everything from a " .. TOOL.Name )
		language.Add( "Tool."..TOOL.Mode..".right_1", "Now select the " .. linkedname .. " to link to" )
		language.Add( "Tool."..TOOL.Mode..".right_2", "Now select the " .. linkedname .. " to unlink" )

		if not SingleLink then
			language.Add( "Tool."..TOOL.Mode..".info_1", "Hold shift to link to more")
			language.Add( "Tool."..TOOL.Mode..".info_2", "Hold shift to unlink from more")
			language.Add( "Tool."..TOOL.Mode..".reload_2", "Reload on the same controller again to clear all linked entities.")
		end

		local lastRequested = 0
		function TOOL:DrawHUD()
			local trace = self:GetOwner():GetEyeTrace()

			if not trace.Entity then lastRequested = 0 end

			if self:CheckHitOwnClass(trace) then
				local controller = trace.Entity
				if controller.WireLinkedEnts and controller.WireLinkedEnts.Marks then
					local markerpos = controller:GetPos():ToScreen()
					for _, ent in pairs(controller.WireLinkedEnts.Marks) do
						if IsValid(ent) then
							local markpos = ent:GetPos():ToScreen()
							surface.SetDrawColor( 255,255,100,255 )
							surface.DrawLine( markerpos.x, markerpos.y, markpos.x, markpos.y )
						end
					end
				end

				-- request updated marks when the player looks at the entity
				if CurTime() - lastRequested > 1 then -- at most once per second
					if not controller.WireLinkedEnts or CurTime() > controller.WireLinkedEnts.LastUpdated then
						net.Start("WireLinkedEntsRequest")
							net.WriteEntity(controller)
							if controller.WireLinkedEnts then
								net.WriteFloat(controller.WireLinkedEnts.LastUpdated)
							else
								net.WriteFloat(0)
							end
						net.SendToServer()
					end
					lastRequested = CurTime()
				end
			end
		end
	end

	function TOOL:RightClick(trace)
		if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local ent = trace.Entity
		if self:GetStage() == 0 then -- stage 0: right-clicking on our own class selects it
			if self:CheckHitOwnClass(trace) then
				self.Controller = ent
				self:SetStage(1)
				return true
			else
				return false
			end
		elseif self:GetStage() == 1 then -- stage 1: right-clicking on something links it
			if not IsValid(self.Controller) then self:SetStage(0) return end
			local ply = self:GetOwner()
			local success, message = self.Controller:LinkEnt(ent)
			if success then
				if self.SingleLink or not ply:KeyDown(IN_SPEED) then self:SetStage(0) end
				self.HasLinked = true
				WireLib.AddNotify(ply, "Linked entity: " .. tostring(ent) .. " to the "..self.Name, NOTIFY_GENERIC, 5)
			else
				WireLib.AddNotify(ply, message or "That entity is already linked to the "..self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
			end
			return success
		end
	end

	function TOOL:Reload(trace)
		if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then
			self:SetStage(0)
			return false
		end
		if CLIENT then return true end
		local ent = trace.Entity

		if self:CheckHitOwnClass(trace) then -- regardless of stage, reloading on our own class clears it
			local ply = self:GetOwner()
			self:SetStage(0)
			if ent.ClearEntities then
				ent:ClearEntities()
				WireLib.AddNotify(ply, "All entities unlinked from the "..self.Name, NOTIFY_GENERIC, 7)
			else
				ent:UnlinkEnt()
				WireLib.AddNotify(ply, "Unlinked "..self.Name, NOTIFY_GENERIC, 5)
			end
			return true
		elseif self:GetStage() == 1 then -- stage 1: reloading on something else unlinks it
			local ply = self:GetOwner()
			local success, message = self.Controller:UnlinkEnt(ent)
			if success then
				if not self:GetOwner():KeyDown(IN_SPEED) then self:SetStage(0) end
				self.HasLinked = true
				WireLib.AddNotify(ply, "Unlinked entity: " .. tostring(ent) .. " from the "..self.Name, NOTIFY_GENERIC, 5)
			else
				WireLib.AddNotify(ply, message or "That entity is not linked to the "..self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
			end
			return success
		end
	end

	if not SingleLink then
		function TOOL:Think()
			if self.HasLinked then
				if not self:GetOwner():KeyDown(IN_SPEED) then self:SetStage(0) end
				if self:GetStage() == 0 then self.HasLinked = false end
			end
			WireToolObj.Think(self) -- Basic ghost
		end
	end
end

-- For transmitting the yellow lines showing links between controllers and ents, as used by the Adv Entity Marker
if SERVER then
	util.AddNetworkString("WireLinkedEnts")
	util.AddNetworkString("WireLinkedEntsRequest")
	function WireLib.SendMarks(controller, marks)
		if not IsValid(controller) then return end
		controller.WireLinkedEnts = {
			Marks = marks or controller.Marks,
			LastUpdated = CurTime()
		}
	end
	net.Receive("WireLinkedEntsRequest", function(netlen, ply)
		local controller = net.ReadEntity()
		local lastUpdated = net.ReadFloat()

		if not IsValid(controller) then return end
		if not controller.WireLinkedEnts then return end
		if not controller.WireLinkedEnts.Marks then return end
		if controller.WireLinkedEnts.LastUpdated < lastUpdated then return end

		net.Start("WireLinkedEnts")
			net.WriteEntity(controller)
			net.WriteFloat(controller.WireLinkedEnts.LastUpdated)
			net.WriteUInt(#controller.WireLinkedEnts.Marks, 16)
			for _,v in pairs(controller.WireLinkedEnts.Marks) do
				net.WriteEntity(v)
			end
		net.Send( ply )
	end)
else
	net.Receive("WireLinkedEnts", function(netlen)
		local controller = net.ReadEntity()
		local lastUpdated = net.ReadFloat()
		if IsValid(controller) then
			controller.WireLinkedEnts = {
				Marks = {},
				LastUpdated = lastUpdated
			}
			for _=1, net.ReadUInt(16) do
				local link = net.ReadEntity()
				if IsValid(link) then
					table.insert(controller.WireLinkedEnts.Marks, link)
				end
			end
		end
	end)
end

LoadTools()
