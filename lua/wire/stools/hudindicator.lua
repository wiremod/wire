-- Created by TheApathetic, so you know who to
-- blame if something goes wrong (someone else :P)
WireToolSetup.setCategory( "Visuals/Indicators" )
WireToolSetup.open( "hudindicator", "Hud Indicator", "gmod_wire_hudindicator", nil, "Hud Indicators" )

-- Pull in DrawHUD from SetupLinking
-- This needs to be called here to prevent it from overwriting anything
WireToolSetup.SetupLinking(true, "vehicle")

if ( CLIENT ) then
	language.Add( "Tool.wire_hudindicator.name", "Hud Indicator Tool (Wire)" )
	language.Add( "Tool.wire_hudindicator.desc", "Spawns a Hud Indicator for use with the wire system." )

	-- HUD Indicator stuff
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

	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create/Update " .. TOOL.Name },
		{ name = "right_0", stage = 0, text = "Hook/Unhook someone else's " .. TOOL.Name },
		{ name = "reload_0", stage = 0, text = "Link Hud Indicator to vehicle" },
		{ name = "reload_1", stage = 1, text = "Now use Reload on a vehicle to link this Hud Indicator to it, or on the same Hud Indicator to unlink it" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

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
-- HUD Indicator stuff
TOOL.ClientConVar[ "showinhud" ] = "0"
TOOL.ClientConVar[ "huddesc" ] = ""
TOOL.ClientConVar[ "hudaddname" ] = "0"
TOOL.ClientConVar[ "hudshowvalue" ] = "0"
TOOL.ClientConVar[ "hudx" ] = "22"
TOOL.ClientConVar[ "hudy" ] = "200"
TOOL.ClientConVar[ "hudstyle" ] = "0"
TOOL.ClientConVar[ "allowhook" ] = "1"
TOOL.ClientConVar[ "hookhidehud" ] = "0" -- Couldn't resist this name :P
TOOL.ClientConVar[ "fullcircleangle" ] = "0"
TOOL.ClientConVar[ "registerdelete" ] = "0"

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("a"), math.min(self:GetClientNumber("ar"), 255), math.min(self:GetClientNumber("ag"), 255), math.min(self:GetClientNumber("ab"), 255), math.min(self:GetClientNumber("aa"), 255),
			self:GetClientNumber("b"), math.min(self:GetClientNumber("br"), 255), math.min(self:GetClientNumber("bg"), 255), math.min(self:GetClientNumber("bb"), 255), math.min(self:GetClientNumber("ba"), 255),
			self:GetClientInfo( "material" ), self:GetClientNumber( "showinhud" ) ~= 0, self:GetClientInfo( "huddesc" ), self:GetClientNumber( "hudaddname" ) ~= 0,
			self:GetClientNumber( "hudshowvalue" ), self:GetClientNumber( "hudstyle" ), self:GetClientNumber( "allowhook" ) ~= 0, self:GetClientNumber( "fullcircleangle" )
	end
end

function TOOL:RightClick( trace )
	-- Can only right-click on HUD Indicators
	if not IsValid(trace.Entity) or trace.Entity:GetClass() ~= self.WireClass then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()
	local hookhidehud = (self:GetClientNumber( "hookhidehud" ) > 0)

	-- Can't hook your own HUD Indicators
	if (ply == trace.Entity:GetPlayer()) then
		WireLib.AddNotify(self:GetOwner(), "You cannot hook your own HUD Indicators!", NOTIFY_GENERIC, 7)
		return false
	end

	if not trace.Entity:CheckRegister(ply) then
		-- Has the creator allowed this HUD Indicator to be hooked?
		if not trace.Entity.AllowHook then
			WireLib.AddNotify(self:GetOwner(), "You are not allowed to hook this HUD Indicator.", NOTIFY_GENERIC, 7)
			return false
		end

		trace.Entity:RegisterPlayer(ply, hookhidehud)
	else
		trace.Entity:UnRegisterPlayer(ply)
	end

	return true
end

-- Hook HUD Indicator to vehicle
function TOOL:Reload( trace )
	-- Can only use this on HUD Indicators and vehicles
	-- The class checks are done later on, no need to do it twice
	if not IsValid(trace.Entity) then return false end

	if (CLIENT) then return true end

	if self:GetStage() == 0 then
		if self:CheckHitOwnClass(trace) then
			self.Controller = trace.Entity
			self:SetStage(1)
		else
			return false
		end
	elseif self:GetStage() == 1 then
		if not IsValid(self.Controller) then self:SetStage(0) return end

		if trace.Entity ~= self.Controller then
			local success, message = self.Controller:LinkEnt(trace.Entity)

			if success then
				WireLib.AddNotify(self:GetOwner(), "Linked entity: " .. tostring(trace.Entity) .. " to the " .. self.Name, NOTIFY_GENERIC, 5)
			else
				WireLib.AddNotify(self:GetOwner(), message or "Could not link " .. self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
				return false
			end
		else
			-- Unlink HUD Indicator from this vehicle
			self.Controller:UnlinkEnt()
			WireLib.AddNotify(self:GetOwner(), "Unlinked " .. self.Name, NOTIFY_GENERIC, 5)
		end

		self:SetStage(0)
	end

	return true
end

function TOOL:GetAngle( trace )
	local Ang = trace.HitNormal:Angle()
	local Model = self:GetModel()
	-- these models get mounted differently
	if Model == "models/props_borealis/bluebarrel001.mdl" or Model == "models/props_junk/PopCan01a.mdl" then
		return Ang + Angle(270, 0, 0)
	elseif Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
		return Ang + Angle(0, 0, (self:GetClientNumber("rotate90") * 90))
	else
		return Ang + Angle(90,0,0)
	end
end

function TOOL:GetSelectedMin( min )
	local Model = self:GetModel()
	-- these models are different
	if Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
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
		-- Add check to see if player is registered with
		-- the HUD Indicator at which they are pointing
		if ((self.NextCheckTime or 0) < CurTime()) then
			local ply = self:GetOwner()
			local trace = ply:GetEyeTrace()

			if IsValid(trace.Entity) and trace.Entity:GetClass() == self.WireClass and trace.Entity:GetPlayer() ~= ply then
				local currentcheck = trace.Entity:CheckRegister(ply)
				if currentcheck ~= self.LastRegisterCheck then
					self.LastRegisterCheck = currentcheck
					self:GetWeapon():SetNWBool("HUDIndicatorCheckRegister", currentcheck)
				end
			else
				if (self.LastRegisterCheck == true) then
					-- Don't need to set this every 1/10 of a second
					self.LastRegisterCheck = false
					self:GetWeapon():SetNWBool("HUDIndicatorCheckRegister", false)
				end
			end
			self.NextCheckTime = CurTime() + 0.10
		end
	end
end

if (CLIENT) then
	-- Override the DrawHUD method from SetupLinking()
	local _DrawHUD = TOOL.DrawHUD
	function TOOL:DrawHUD()
		local isregistered = self:GetWeapon():GetNWBool("HUDIndicatorCheckRegister")

		if (isregistered) then
			draw.WordBox(8, ScrW() / 2 + 10, ScrH() / 2 + 10, "Registered", "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
		end

		_DrawHUD(self)
	end
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	self:GetWeapon():SetNWBool("HUDIndicatorCheckRegister", false)
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

	-- Get the currently registered HUD Indicators for this player that can be unregistered
	local registered = HUDIndicator_GetCurrentRegistered()
	if (#registered > 0) then
		local options = {}
		for _, indinfo in pairs(registered) do
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

-- Concommand to unregister HUD Indicator through control panel
local function HUDIndicator_RemoteUnRegister(ply, cmd, arg)
	local eindex = ply:GetInfoNum("wire_hudindicator_registerdelete", 0)
	if (eindex == 0) then return end
	local ent = ents.GetByIndex(eindex)
	if IsValid(ent) then
		ent:UnRegisterPlayer(ply)
	end
end
concommand.Add("wire_hudindicator_delete", HUDIndicator_RemoteUnRegister)
