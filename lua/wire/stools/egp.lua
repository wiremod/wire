-- Wire EGP by Divran
WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "egp", "EGP v3", "gmod_wire_egp", nil, "EGPs" )

TOOL.ClientConVar["model"] = "models/kobilica/wiremonitorbig.mdl"
TOOL.ClientConVar["type"] = 1
TOOL.ClientConVar["createflat"] = 1
TOOL.ClientConVar["weld"] = 0
TOOL.ClientConVar["weldworld"] = 0
TOOL.ClientConVar["freeze"] = 1
TOOL.ClientConVar["emitter_usert"] = 1
TOOL.ClientConVar["translucent"] = 0

cleanup.Register( "wire_egps" )

if (SERVER) then
	CreateConVar('sbox_maxwire_egps', 5)

	local function SpawnEnt( ply, Pos, Ang, model, class)
		if IsValid(ply) and (not ply:CheckLimit("wire_egps")) then return false end
		if not ply then ply = game.GetWorld() end -- For Garry's Map Saver
		if model and not WireLib.CanModel(ply, model) then return false end
		local ent = ents.Create(class)
		if (model) then ent:SetModel(model) end
		ent:SetAngles(Ang)
		ent:SetPos(Pos)
		ent:Spawn()
		ent:Activate()

		ent:SetPlayer(ply)
		ent:SetEGPOwner( ply )

		if IsValid(ply) then ply:AddCount( "wire_egps", ent ) end

		return ent
	end

	local function SpawnEGP( ply, Pos, Ang, model )
		if (EGP.ConVars.AllowScreen:GetInt() == 0) then
			ply:ChatPrint("[EGP] The server has blocked EGP screens.")
			return
		end
		local ent = SpawnEnt( ply, Pos, Ang, model, "gmod_wire_egp" )
		if (ent and ent:IsValid()) then
			ent.EGP_Duplicated = true
			timer.Simple(0.5,function() ent.EGP_Duplicated = nil end)
		end
		return ent
	end
	duplicator.RegisterEntityClass("gmod_wire_egp", SpawnEGP, "Pos", "Ang", "model")
	local function SpawnHUD( ply, Pos, Ang )
		if (EGP.ConVars.AllowHUD:GetInt() == 0) then
			ply:ChatPrint("[EGP] The server has blocked EGP HUDs.")
			return
		end
		local ent = SpawnEnt( ply, Pos, Ang, "models/bull/dynamicbutton.mdl", "gmod_wire_egp_hud" )
		if (ent and ent:IsValid()) then
			ent.EGP_Duplicated = true
			timer.Simple(0.5,function() ent.EGP_Duplicated = nil end)
		end
		return ent
	end
	duplicator.RegisterEntityClass("gmod_wire_egp_hud", SpawnHUD, "Pos", "Ang")
	local function SpawnEmitter( ply, Pos, Ang )
		if (EGP.ConVars.AllowEmitter:GetInt() == 0) then
			ply:ChatPrint("[EGP] The server has blocked EGP emitters.")
			return
		end
		local ent = SpawnEnt( ply, Pos, Ang, "models/bull/dynamicbutton.mdl", "gmod_wire_egp_emitter" )
		if (ent and ent:IsValid()) then
			ent.EGP_Duplicated = true
			timer.Simple(0.5,function() ent.EGP_Duplicated = nil end)
		end
		return ent
	end
	duplicator.RegisterEntityClass("gmod_wire_egp_emitter",SpawnEmitter,"Pos","Ang" )

	function TOOL:LeftClick( trace )
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		-- check if the player clicked an emitter
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_egp_emitter" then
			trace.Entity:SetUseRT(self:GetClientNumber("emitter_usert")~=0)
			return true
		end

		-- check if the player clicked a screen
		if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_egp" then
			trace.Entity:SetTranslucent(self:GetClientNumber("translucent")~=0)
			return true
		end

		local ply = self:GetOwner()
		if (not ply:CheckLimit( "wire_egps" )) then return false end

		local ent
		local Type = self:GetClientNumber("type")
		if (Type == 1) then -- Screen
			local model = self:GetClientInfo("model")
			if (not util.IsValidModel( model )) then return false end

			ent = SpawnEGP( ply, trace.HitPos, self:GetAngle(trace), model )
			if not IsValid(ent) then return end

			self:SetPos(ent, trace) -- Use WireToolObj's pos code
			ent:SetTranslucent(self:GetClientNumber("translucent")~=0)
		elseif (Type == 2) then -- HUD
			ent = SpawnHUD( ply, trace.HitPos + trace.HitNormal * 0.25, trace.HitNormal:Angle() + Angle(90,0,0) )
			if not IsValid(ent) then return end
		elseif (Type == 3) then -- Emitter
			ent = SpawnEmitter( ply, trace.HitPos + trace.HitNormal * 0.25, trace.HitNormal:Angle() + Angle(90,0,0) )
			if not IsValid(ent) then return end

			ent:SetUseRT(self:GetClientNumber("emitter_usert")~=0)
		end

		local weld = self:GetClientNumber("weld") ~= 0 and true or false
		local weldworld = self:GetClientNumber("weldworld") ~= 0 and true or false
		local const
		if (trace.Entity) then
			if (trace.Entity:IsValid() and weld) then
				const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true, false, weldworld )
			elseif (trace.Entity:IsWorld() and weldworld) then
				const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true, false, true )
			end
		end

		if (self:GetClientNumber("freeze") ~= 0) then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
				phys:Wake()
			end
		end

		if (not ent or not ent:IsValid()) then return end
		undo.Create( "wire_egp" )
			if (const) then undo.AddEntity( const ) end
			undo.AddEntity( ent )
			undo.SetPlayer( ply )
		undo.Finish()

		cleanup.Add( ply, "wire_egps", ent )

		return true
	end
end

if CLIENT then
	language.Add( "Tool.wire_egp.name", "E2 Graphics Processor" )
	language.Add( "Tool.wire_egp.desc", "EGP Tool" )
	language.Add( "Tool.wire_egp.left_0", "Create EGP Screen/HUD/Emitter" )
	language.Add( "Tool.wire_egp.right_0", "Link EGP HUD to vehicle" )
	language.Add( "Tool.wire_egp.reload_0", "Open the Reload Menu for several lag fixing options" )
	language.Add( "Tool.wire_egp.1", "Now right click a vehicle." )
	language.Add( "sboxlimit_wire_egps", "You've hit the EGP limit!" )
	language.Add( "Undone_wire_egp", "Undone EGP" )
	language.Add( "Tool_wire_egp_createflat", "Create flat to surface" )
	language.Add( "Tool_wire_egp_weld", "Weld" )
	language.Add( "Tool_wire_egp_weldworld", "Weld to world" )
	language.Add( "Tool_wire_egp_freeze", "Freeze" )
	language.Add( "Tool_wire_egp_drawemitters", "Draw emitters (Clientside)" )
	language.Add( "Tool_wire_egp_emitter_drawdist", "Additional emitter draw distance (Clientside)" )
	language.Add( "Tool_wire_egp_emitter_usert", "Use an RT for emitters (improves performance)" )
	language.Add( "Tool_wire_egp_translucent", "Transparent background" )
end

WireToolSetup.SetupLinking(false, "vehicle") -- Generates RightClick, Reload, and DrawHUD functions

function TOOL:CheckHitOwnClass( trace )
	return IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_egp_hud" -- We only need linking for the hud
end

-- Remove SetupLinking's reload function
TOOL.Reload = nil

if CLIENT then
	local Menu = {}
	local CurEnt

	local function refreshRT( ent )
		ent.GPU:FreeRT()
		ent.GPU = GPULib.WireGPU( ent )
		ent:EGP_Update()
	end

	local function refreshObjects( ent )
		if ent then
			RunConsoleCommand("EGP_Request_Reload",ent:EntIndex())
		else
			RunConsoleCommand("EGP_Request_Reload")
		end
	end

	local function CreateToolReloadMenu()
		local pnl = vgui.Create("DFrame")
		pnl:SetSize( 200, 114 )
		pnl:Center()
		pnl:ShowCloseButton( true )
		pnl:SetDraggable( false )
		pnl:SetTitle( "EGP Reload Menu" )
		pnl:SetDeleteOnClose( false )

		local w = 200/2-4
		local h = 20

		local x1, x2 = 2, 200/2

		local lbl = vgui.Create("DLabel",pnl)
		lbl:SetPos( x1+2, 24 )
		lbl:SetText("Current Screen:")
		lbl:SizeToContents()

		local lbl2 = vgui.Create("DLabel",pnl)
		lbl2:SetPos( x2, 24 )
		lbl2:SetText("All screens on map:")
		lbl2:SizeToContents()

		local btn = vgui.Create("DButton",pnl)
		btn:SetText("RenderTarget")
		btn:SetPos( x1, 40 )
		btn:SetSize( w, h )
		function btn:DoClick()
			pnl:SetVisible( false )

			refreshRT( CurEnt )

			LocalPlayer():ChatPrint("[EGP] RenderTarget reloaded.")
		end

		local btn2 = vgui.Create("DButton",pnl)
		btn2:SetText("Objects")
		btn2:SetPos( x1, 65 )
		btn2:SetSize( w, h )
		function btn2:DoClick()
			pnl:SetVisible( false )

			refreshObjects( CurEnt )

			LocalPlayer():ChatPrint("[EGP] Requesting...")
		end

		local btn3 = vgui.Create("DButton",pnl)
		btn3:SetText("Both")
		btn3:SetPos( x1, 90 )
		btn3:SetSize( w, h )
		function btn3:DoClick()
			pnl:SetVisible( false )
			if (CurEnt:GetClass() == "gmod_wire_egp_hud" and CurEnt:GetClass() == "gmod_wire_egp_emitter") then
				LocalPlayer():ChatPrint("[EGP] Entity does not have a RenderTarget")
			else
				refreshRT( CurEnt )

				LocalPlayer():ChatPrint("[EGP] RenderTarget reloaded.")
			end
			LocalPlayer():ChatPrint("[EGP] Requesting object reload...")
			refreshObjects( CurEnt )
		end

		local btn4 = vgui.Create("DButton",pnl)
		btn4:SetText("RenderTarget")
		btn4:SetPos( x2, 40 )
		btn4:SetSize( w, h )
		function btn4:DoClick()
			pnl:SetVisible( false )
			local tbl = ents.FindByClass("gmod_wire_egp")
			for _,v in pairs( tbl ) do
				refreshRT( v )
			end
			LocalPlayer():ChatPrint("[EGP] RenderTargets reloaded on all screens on the map.")
		end

		local btn5 = vgui.Create("DButton",pnl)
		btn5:SetText("Objects")
		btn5:SetPos( x2, 65 )
		btn5:SetSize( w, h )
		function btn5:DoClick()
			pnl:SetVisible( false )
			LocalPlayer():ChatPrint("[EGP] Requesting...")
			refreshObjects()
		end

		local btn6 = vgui.Create("DButton",pnl)
		btn6:SetText("Both")
		btn6:SetPos( x2, 90 )
		btn6:SetSize( w, h )
		function btn6:DoClick()
			pnl:SetVisible( false )
			local tbl = ents.FindByClass("gmod_wire_egp")
			for _,v in pairs( tbl ) do
				refreshRT( v )
			end
			LocalPlayer():ChatPrint("[EGP] RenderTargets reloaded on all screens on the map.")
			LocalPlayer():ChatPrint("[EGP] Requesting object reload...")
			refreshObjects()
		end

		pnl:MakePopup()
		pnl:SetVisible( false )
		Menu = { Panel = pnl, SingleRender = btn, SingleObjects = btn2, SingleBoth = btn3, AllRender = btn4, AllObjects = btn5, AllBoth = btn6 }
	end

	function TOOL:LeftClick( trace ) return (not trace.Entity or (trace.Entity and not trace.Entity:IsPlayer())) end
	function TOOL:Reload( trace )

		if (not Menu.Panel) then CreateToolReloadMenu() end

		Menu.Panel:SetVisible( true )
		if (not EGP:ValidEGP( trace.Entity )) then
			Menu.SingleRender:SetEnabled( false )
			Menu.SingleObjects:SetEnabled( false )
			Menu.SingleBoth:SetEnabled( false )
		else
			CurEnt = trace.Entity
			if (CurEnt:GetClass() == "gmod_wire_egp_hud" or CurEnt:GetClass() == "gmod_wire_egp_emitter") then
				Menu.SingleRender:SetEnabled( false )
				Menu.SingleBoth:SetEnabled( false)
			else
				Menu.SingleRender:SetEnabled( true )
				Menu.SingleBoth:SetEnabled( true )
			end
			Menu.SingleObjects:SetEnabled( true )
		end
	end

	function TOOL.BuildCPanel(panel)
		if not EGP then return end
		panel:SetSpacing( 10 )
		panel:SetName( "E2 Graphics Processor" )

		WireDermaExts.ModelSelect(panel, "wire_egp_model", list.Get( "WireScreenModels" ), 5)

		local cbox = {}
		cbox.Label = "Screen Type"
		cbox.MenuButton = 0
		cbox.Options = {}
		cbox.Options.Screen = { wire_egp_type = 1 }
		cbox.Options.HUD = { wire_egp_type = 2 }
		cbox.Options.Emitter = { wire_egp_type = 3 }
		panel:AddControl("ComboBox", cbox)

		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_createflat",Command = "wire_egp_createflat"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_weld",Command="wire_egp_weld"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_weldworld",Command="wire_egp_weldworld"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_freeze",Command="wire_egp_freeze"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_translucent",Command="wire_egp_translucent"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_drawemitters",Command="wire_egp_drawemitters"})
		panel:AddControl("Checkbox", {Label = "#Tool_wire_egp_emitter_usert",Command="wire_egp_emitter_usert"})

		local slider = vgui.Create("DNumSlider")
		slider:SetText("#Tool_wire_egp_emitter_drawdist")
		slider:SetConVar("wire_egp_emitter_drawdist")
		slider:SetMin( 0 )
		slider:SetMax( 5000 )
		slider:SetDecimals( 0 )
		panel:AddItem(slider)
	end
end

function TOOL:UpdateGhost( ent, ply )
	if not IsValid(ent) then return end
	local trace = ply:GetEyeTrace()

	if IsValid(trace.Entity) and trace.Entity:IsPlayer() then
		ent:SetNoDraw( true )
		return
	end

	local Type = self:GetClientNumber("type")
	if (Type == 1) then
		ent:SetAngles(self:GetAngle(trace))
		self:SetPos(ent, trace)
	elseif (Type == 2 or Type == 3) then
		ent:SetPos( trace.HitPos + trace.HitNormal * 0.25 )
		ent:SetAngles( trace.HitNormal:Angle() + Angle(90,0,0) )
	end

	ent:SetNoDraw( false )
end

function TOOL:Think()
	if self.HasLinked then
		if not self:GetOwner():KeyDown(IN_SPEED) then self:SetStage(0) end
		if self:GetStage() == 0 then self.HasLinked = false end
	end

	local Type = self:GetClientNumber("type")
	if (not self.GhostEntity or not self.GhostEntity:IsValid()) then
		local trace = self:GetOwner():GetEyeTrace()
		self:MakeGhostEntity( Model("models/bull/dynamicbutton.mdl"), trace.HitPos, trace.HitNormal:Angle() + Angle(90,0,0) )
	elseif (not self.GhostEntity.Type or self.GhostEntity.Type ~= Type or (self.GhostEntity.Type == 1 and self.GhostEntity:GetModel() ~= self:GetClientInfo("model"))) then
		if (Type == 1) then
			self.GhostEntity:SetModel(self:GetClientInfo("model"))
		elseif (Type == 2 or Type == 3) then
			self.GhostEntity:SetModel("models/bull/dynamicbutton.mdl")
		end
		self.GhostEntity.Type = Type
	end
	self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end
