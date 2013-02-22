// Created by TheApathetic, so you know who to
// blame if something goes wrong (someone else :P)
WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "hudindicator", "Hud Indicator", "gmod_wire_hudindicator", nil, "Hud Indicators" )

if ( CLIENT ) then
    language.Add( "Tool.wire_hudindicator.name", "Hud Indicator Tool (Wire)" )
    language.Add( "Tool.wire_hudindicator.desc", "Spawns a Hud Indicator for use with the wire system." )
    language.Add( "Tool.wire_hudindicator.0", "Primary: Create/Update Hud Indicator Secondary: Hook/Unhook someone else's Hud Indicator Reload: Link Hud Indicator to vehicle" )
	language.Add( "Tool.wire_hudindicator.1", "Now use Reload on a vehicle to link this Hud Indicator to it, or on the same Hud Indicator to unlink it" )
	language.Add( "undone_wirehudindicator", "Undone Wire Hud Indicator" )

	// HUD Indicator stuff
	language.Add( "ToolWireHudIndicator_showinhud", "Show in my HUD")
	language.Add( "ToolWireHudIndicator_hudheaderdesc", "HUD Indicator Settings:")
	language.Add( "ToolWireHudIndicator_huddesc", "Description:")
	language.Add( "ToolWireHudIndicator_hudaddname", "Add description as Name")
	language.Add( "ToolWireHudIndicator_hudaddnamedesc", "Also adds description as name of indicator (like Wire Namer)")
	language.Add( "ToolWireHudIndicator_hudshowvalue", "Show Value as:")
	language.Add( "ToolWireHudIndicator_hudshowvaluedesc", "How to display value in HUD readout along with description")
	language.Add( "ToolWireHudIndicator_hudx", "HUD X:")
	language.Add( "ToolWireHudIndicator_hudxdesc", "X of the upper-left corner of HUD display")
	language.Add( "ToolWireHudIndicator_hudy", "HUD Y:")
	language.Add( "ToolWireHudIndicator_hudydesc", "Y of the upper-left corner of HUD display")
	language.Add( "ToolWireHudIndicator_hudstyle", "HUD Style:")
	language.Add( "ToolWireHudIndicator_allowhook", "Allow others to hook")
	language.Add( "ToolWireHudIndicator_allowhookdesc", "Allows others to hook this indicator with right-click")
	language.Add( "ToolWireHudIndicator_hookhidehud", "Allow HideHUD on hooked")
	language.Add( "ToolWireHudIndicator_hookhidehuddesc", "Whether your next hooked indicator will be subject to the HideHUD input of that indicator")
	language.Add( "ToolWireHudIndicator_fullcircleangle", "Start angle for full circle gauge (deg):")
	language.Add( "ToolWireHudIndicator_registeredindicators", "Registered Indicators:")
	language.Add( "ToolWireHudIndicator_deleteselected", "Unregister Selected Indicator")
end

if (SERVER) then
	// Hud indicators use the original indicator CVar
	//CreateConVar('sbox_maxwire_indicators', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "0"
TOOL.ClientConVar[ "ab" ] = "0"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "b" ] = "1"
TOOL.ClientConVar[ "br" ] = "0"
TOOL.ClientConVar[ "bg" ] = "255"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"
TOOL.ClientConVar[ "rotate90" ] = "0"
TOOL.ClientConVar[ "material" ] = "models/debug/debugwhite"
// HUD Indicator stuff
TOOL.ClientConVar[ "showinhud" ] = "0"
TOOL.ClientConVar[ "huddesc" ] = ""
TOOL.ClientConVar[ "hudaddname" ] = "0"
TOOL.ClientConVar[ "hudshowvalue" ] = "0"
TOOL.ClientConVar[ "hudx" ] = "22"
TOOL.ClientConVar[ "hudy" ] = "200"
TOOL.ClientConVar[ "hudstyle" ] = "0"
TOOL.ClientConVar[ "allowhook" ] = "1"
TOOL.ClientConVar[ "hookhidehud" ] = "0" // Couldn't resist this name :P
TOOL.ClientConVar[ "fullcircleangle" ] = "0"
TOOL.ClientConVar[ "registerdelete" ] = "0"

cleanup.Register( "wire_indicators" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local model			= self:GetModel()
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local b				= self:GetClientNumber("b")
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)
	local material		= self:GetClientInfo( "material" )

	local showinhud		= (self:GetClientNumber( "showinhud" ) > 0)
	local huddesc		= self:GetClientInfo( "huddesc" )
	local hudaddname	= (self:GetClientNumber( "hudaddname" ) > 0)
	local hudshowvalue	= self:GetClientNumber( "hudshowvalue" )
	local hudstyle		= self:GetClientNumber( "hudstyle" )
	local allowhook		= (self:GetClientNumber( "allowhook" ) > 0)
	local fullcircleangle = self:GetClientNumber( "fullcircleangle" )

	// If we shot a wire_indicator change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hudindicator" ) then

		trace.Entity:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		trace.Entity:SetMaterial( material )

		trace.Entity.a	= a
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= b
		trace.Entity.br	= br
		trace.Entity.bg	= bg
		trace.Entity.bb	= bb
		trace.Entity.ba	= ba

		// This will un-register if showinhud is false
		trace.Entity:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle)

		trace.Entity.showinhud = showinhud
		trace.Entity.huddesc = huddesc
		trace.Entity.hudaddname = hudaddname
		trace.Entity.hudshowvalue = hudshowvalue
		trace.Entity.hudstyle = hudstyle
		trace.Entity.allowhook = allowhook
		trace.Entity.fullcircleangle = fullcircleangle

		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_indicators" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	//local Ang = trace.HitNormal:Angle()
	local Ang = self:GetAngle(trace)

	wire_indicator = MakeWireHudIndicator( ply, trace.HitPos, Ang, model, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle )

	local min = wire_indicator:OBBMins()
	wire_indicator:SetPos( trace.HitPos - trace.HitNormal * self:GetSelectedMin(min) )

	local const = WireLib.Weld(wire_indicator, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireHudIndicator")
		undo.AddEntity( wire_indicator )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_indicators", wire_indicator )

	return true
end

function TOOL:RightClick( trace )
	// Can only right-click on HUD Indicators
	if (!trace.Entity || !trace.Entity:IsValid() || trace.Entity:GetClass() != "gmod_wire_hudindicator") then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()
	local hookhidehud = (self:GetClientNumber( "hookhidehud" ) > 0)

	// Can't hook your own HUD Indicators
	if (ply == trace.Entity:GetPlayer()) then
		WireLib.AddNotify(self:GetOwner(), "You cannot hook your own HUD Indicators!", NOTIFY_GENERIC, 7)
		return false
	end

	if (!trace.Entity:CheckRegister(ply)) then
		// Has the creator allowed this HUD Indicator to be hooked?
		if (!trace.Entity.AllowHook) then
			WireLib.AddNotify(self:GetOwner(), "You are not allowed to hook this HUD Indicator.", NOTIFY_GENERIC, 7)
			return false
		end

		trace.Entity:RegisterPlayer(ply, hookhidehud)
	else
		trace.Entity:UnRegisterPlayer(ply)
	end

	return true
end

// Hook HUD Indicator to vehicle
function TOOL:Reload( trace )
	// Can only use this on HUD Indicators and vehicles
	// The class checks are done later on, no need to do it twice
	if (!trace.Entity || !trace.Entity:IsValid()) then return false end

	if (CLIENT) then return true end

	local iNum = self:NumObjects()

	if (iNum == 0) then
		if (trace.Entity:GetClass() != "gmod_wire_hudindicator") then
			WireLib.AddNotify(self:GetOwner(), "You must select a HUD Indicator to link first.", NOTIFY_GENERIC, 7)
			return false
		end

		local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage(1)
	elseif (iNum == 1) then
		if (trace.Entity != self:GetEnt(1)) then
			if (!string.find(trace.Entity:GetClass(), "prop_vehicle_")) then
				WireLib.AddNotify(self:GetOwner(), "HUD Indicators can only be linked to vehicles.", NOTIFY_GENERIC, 7)
				self:ClearObjects()
				self:SetStage(0)
				return false
			end

			local ent = self:GetEnt(1)
			local bool = ent:LinkVehicle(trace.Entity)

			if (!bool) then
				WireLib.AddNotify(self:GetOwner(), "Could not link HUD Indicator!", NOTIFY_GENERIC, 7)
				return false
			end
		else
			// Unlink HUD Indicator from this vehicle
			trace.Entity:UnLinkVehicle()
		end

		self:ClearObjects()
		self:SetStage(0)
	end

	return true
end

if (SERVER) then

	function MakeWireHudIndicator( pl, Pos, Ang, model, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end

		local wire_indicator = ents.Create( "gmod_wire_hudindicator" )
		if (!wire_indicator:IsValid()) then return false end

		wire_indicator:SetModel( model )
		wire_indicator:SetMaterial( material )
		wire_indicator:SetAngles( Ang )
		wire_indicator:SetPos( Pos )
		wire_indicator:Spawn()

		wire_indicator:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		wire_indicator:SetPlayer(pl)

		wire_indicator:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle)

		if (nocollide) then
			local phys = wire_indicator:GetPhysicsObject()
			if ( phys:IsValid() ) then phys:EnableCollisions(false) end
		end

		local ttable = {
			a	= a,
			ar	= ar,
			ag	= ag,
			ab	= ab,
			aa	= aa,
			b	= b,
			br	= br,
			bg	= bg,
			bb	= bb,
			ba	= ba,
			material = material,
			pl	= pl,
			nocollide = nocollide,
			showinhud = showinhud,
			huddesc = huddesc,
			hudaddname = hudaddname,
			hudshowvalue = hudshowvalue,
			hudstyle = hudstyle,
			allowhook = allowhook,
			fullcircleangle = fullcircleangle
		}
		table.Merge(wire_indicator:GetTable(), ttable )

		pl:AddCount( "wire_indicators", wire_indicator )

		return wire_indicator
	end

	duplicator.RegisterEntityClass("gmod_wire_hudindicator", MakeWireHudIndicator, "Pos", "Ang", "Model", "a", "ar", "ag", "ab", "aa", "b", "br",
	  "bg", "bb", "ba", "material", "showinhud", "huddesc", "hudaddname", "hudshowvalue", "hudstyle", "allowhook", "fullcircleangle", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:GetAngle( trace )
	local Ang = trace.HitNormal:Angle()
	local Model = self:GetModel()
	//these models get mounted differently
	if (Model == "models/props_borealis/bluebarrel001.mdl" || Model == "models/props_junk/PopCan01a.mdl") then
		return Ang + Angle(270, 0, 0)
	elseif (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return Ang + Angle(0, 0, (self:GetClientNumber("rotate90") * 90))
	else
		return Ang + Angle(90,0,0)
	end
end

function TOOL:GetSelectedMin( min )
	local Model = self:GetModel()
	//these models are different
	if (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return min.x
	else
		return min.z
	end
end

function TOOL:Think()
	local model = self:GetModel()
	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= model then
		self:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhost( self.GhostEntity )

	if (SERVER) then
		// Add check to see if player is registered with
		// the HUD Indicator at which he is pointing
		if ((self.NextCheckTime or 0) < CurTime()) then
			local ply = self:GetOwner()
			local trace = ply:GetEyeTrace()

			if (trace.Hit && trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hudindicator" && trace.Entity:GetPlayer() != ply) then
				local currentcheck = trace.Entity:CheckRegister(ply)
				if (currentcheck != self.LastRegisterCheck) then
					self.LastRegisterCheck = currentcheck
					self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", currentcheck)
				end
			else
				if (self.LastRegisterCheck == true) then
					// Don't need to set this every 1/10 of a second
					self.LastRegisterCheck = false
					self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", false)
				end
			end
			self.NextCheckTime = CurTime() + 0.10
		end
	end
end

if (CLIENT) then
	function TOOL:DrawHUD()
		local isregistered = self:GetWeapon():GetNetworkedBool("HUDIndicatorCheckRegister")

		if (isregistered) then
			draw.WordBox(8, ScrW() / 2 + 10, ScrH() / 2 + 10, "Registered", "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
		end
	end
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", false)
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_hudindicator")

	panel:AddControl("Slider", {
		Label = "#ToolWireIndicator_a_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_hudindicator_a"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_a_colour",
		Red = "wire_hudindicator_ar",
		Green = "wire_hudindicator_ag",
		Blue = "wire_hudindicator_ab",
		Alpha = "wire_hudindicator_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Slider", {
		Label =	"#ToolWireIndicator_b_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_hudindicator_b"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_b_colour",
		Red = "wire_hudindicator_br",
		Green = "wire_hudindicator_bg",
		Blue = "wire_hudindicator_bb",
		Alpha = "wire_hudindicator_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	ModelPlug_AddToCPanel(panel, "indicator", "wire_hudindicator", true)

	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Material",
		MenuButton = "0",

		Options = {
			["Matte"]	= { wire_hudindicator_material = "models/debug/debugwhite" },
			["Shiny"]	= { wire_hudindicator_material = "models/shiny" },
			["Metal"]	= { wire_hudindicator_material = "models/props_c17/metalladder003" }
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireIndicator_90",
		Command = "wire_hudindicator_rotate90"
	})

	panel:AddControl("Header", {
		Text = "#ToolWireHudIndicator_hudheaderdesc",
		Description = "#ToolWireHudIndicator_hudheaderdesc"
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireHudIndicator_showinhud",
		Command = "wire_hudindicator_showinhud"
	})

	panel:AddControl("TextBox", {
		Label = "#ToolWireHudIndicator_huddesc",
		Command = "wire_hudindicator_huddesc",
		MaxLength = "20"
	})

	panel:AddControl("ComboBox", {
		Label = "#ToolWireHudIndicator_hudstyle",
		MenuButton = "0",
		Options = {
			["Basic"]		= { wire_hudindicator_hudstyle = "0" },
			["Gradient"]	= { wire_hudindicator_hudstyle = "1" },
			["Percent Bar"]	= { wire_hudindicator_hudstyle = "2" },
			["Full Circle"] = { wire_hudindicator_hudstyle = "3" },
			["Semi-circle"] = { wire_hudindicator_hudstyle = "4" }
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireHudIndicator_hudaddname",
		Command = "wire_hudindicator_hudaddname",
		Description = "#ToolWireHudIndicator_hudaddnamedesc"
	})

	panel:AddControl("ComboBox", {
		Label = "#ToolWireHudIndicator_hudshowvalue",
		MenuButton = "0",
		Options = {
			["Do Not Show"]	= { wire_hudindicator_hudshowvalue = "0" },
			["Percent"]		= { wire_hudindicator_hudshowvalue = "1" },
			["Value"]		= { wire_hudindicator_hudshowvalue = "2" }
		},
		Description = "#ToolWireHudIndicator_hudshowvaluedesc"
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireHudIndicator_allowhook",
		Command = "wire_hudindicator_allowhook",
		Description = "#ToolWireHudIndicator_allowhookdesc"
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireHudIndicator_hookhidehud",
		Command = "wire_hudindicator_hookhidehud",
		Description = "#ToolWireHudIndicator_hookhidehuddesc"
	})

	panel:AddControl("Slider", {
		Label = "#ToolWireHudIndicator_fullcircleangle",
		Type = "Float",
		Min = "0",
		Max = "360",
		Command = "wire_hudindicator_fullcircleangle"
	})

	// Get the currently registered HUD Indicators for this player that can be unregistered
	local registered = HUDIndicator_GetCurrentRegistered()
	if (#registered > 0) then
		local options = {}
		for eindex,indinfo in pairs(registered) do
			local txt = indinfo.Description or ("Indicator #"..indinfo.EIndex)
			options[txt] = { wire_hudindicator_registerdelete = tostring(indinfo.EIndex) }
		end

		panel:AddControl("ListBox", {
			Label = "#ToolWireHudIndicator_registeredindicators",
			MenuButton = 0,
			Height = 120,
			Options = options
		})

		panel:AddControl("Button", {
			Text = "#ToolWireHudIndicator_deleteselected",
			Command = "wire_hudindicator_delete"
		})
	end

	panel:AddControl("TextBox", {
		Label = "#ToolWireHudIndicator_hudx",
		Command = "wire_hudindicator_hudx",
		Description = "#ToolWireHudIndicator_hudxdesc"
	})

	panel:AddControl("TextBox", {
		Label = "#ToolWireHudIndicator_hudy",
		Command = "wire_hudindicator_hudy",
		Description = "#ToolWireHudIndicator_hudydesc"
	})
end

// Concommand to unregister HUD Indicator through control panel
local function HUDIndicator_RemoteUnRegister(ply, cmd, arg)
	local eindex = ply:GetInfoNum("wire_hudindicator_registerdelete", 0)
	if (eindex == 0) then return end
	local ent = ents.GetByIndex(eindex)
	if (ent && ent:IsValid()) then
		ent:UnRegisterPlayer(ply)
	end
end
concommand.Add("wire_hudindicator_delete", HUDIndicator_RemoteUnRegister)
