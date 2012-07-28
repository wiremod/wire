TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Constant Value"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (CLIENT) then
	language12.Add("Tool_wire_value_name", "Value Tool (Wire)")
	language12.Add("Tool_wire_value_desc", "Spawns a constant value for use with the wire system.")
	language12.Add("Tool_wire_value_0", "Primary: Create/Update Value, Secondary: Copy Settings")
	language12.Add("WireValueTool_value", "Value:")
	language12.Add("WireValueTool_model", "Model:")
	language12.Add("sboxlimit_wire_values", "You've hit values limit!")
	language12.Add("undone_wirevalue", "Undone Wire Value")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_values', 20)
	ModelPlug_Register("value")
end

TOOL.ClientConVar["model"] = "models/kobilica/value.mdl"
TOOL.ClientConVar["numvalues"] = "1"
for i = 1, 12 do
	TOOL.ClientConVar["value"..i] = "0"
	TOOL.ClientConVar["valuetype"..i] = "Number"
end

// Supported Data Types.
local DataTypes = {
// typedata | Shown In The Menu/Console.
["normal"]	= "Number",
[""]		= "Number", // Same as normal/number, but for old dupes. ;)
["string"]	= "String",
["vector2"] = "2D Vector",
["vector"]	= "3D Vector",
["vector4"] = "4D Vector",
["angle"]	= "Angle"}

cleanup.Register("wire_values")

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local numvalues = self:GetClientNumber("numvalues")
	numvalues = math.Clamp(numvalues, 1, 12)

	//value is a table of strings so we can save a step later in adjusting the outputs
	local value = {}

	for i = 1, numvalues do
		local Value = self:GetClientInfo("value"..i)
		local TypeIndex = self:GetClientInfo("valuetype"..i)
		local Type = "string"
		for k, v in pairs(DataTypes) do
			if (TypeIndex == v) then
				Type = k or "string"
				break
			end
		end
		value[i] = (Type..":"..Value)
	end

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" && trace.Entity:GetPlayer() == ply) then
		trace.Entity:Setup(value)
		trace.Entity.value = value
		return true
	end

	if (!self:GetSWEP():CheckLimit("wire_values")) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_value = MakeWireValue(ply, trace.HitPos, Ang, self:GetModel(), value)

	local min = wire_value:OBBMins()
	wire_value:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const = WireLib.Weld(wire_value, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireValue")
		undo.AddEntity(wire_value)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_values", wire_value)

	return true
end

function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value") then
		local Values = 0
		for k1, v1 in pairs(trace.Entity.value) do
			local Valuetype = string.Explode(":", v1)[1]
			local Value = ""

			local Type = "Number"
			for k2, v2 in pairs(DataTypes) do
				if (string.lower(Valuetype) == k2) then
					if ((Valuetype ~= "") or (k2 ~= "")) then
						Value = string.gsub(v1, (Valuetype..":"), "")
						Type = v2 or "Number"
						break
					else
						Value = string.gsub(v1, ("normal:"), "")
						Type = "Number"
						break
					end
				else
					Value = string.gsub(v1, ("normal:"), "")
					Type = "Number"
				end
			end

			ply:ConCommand("wire_value_valuetype"..k1.." "..Type)
			ply:ConCommand("wire_value_value"..k1.." "..Value)
			Values = Values + 1
		end
		ply:ConCommand("wire_value_numvalues "..Values)
		return true
	end
end

if (SERVER) then

	function MakeWireValue(ply, Pos, Ang, model, value)
		if (!ply:CheckLimit("wire_values")) then return false end

		local wire_value = ents.Create("gmod_wire_value")
		if (!wire_value:IsValid()) then return false end

		wire_value:SetAngles(Ang)
		wire_value:SetPos(Pos)
		wire_value:SetModel(model)
		wire_value:Spawn()

		wire_value:Setup(value)
		wire_value:SetPlayer(ply)

		ply:AddCount("wire_values", wire_value)

		return wire_value
	end

	duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Pos", "Ang", "Model", "value")

end

function TOOL:UpdateGhostWireValue(ent, player)
	if (!ent || !ent:IsValid()) then return end

	local tr 	= util.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace 	= util.TraceLine(tr)

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_value") then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model) then
		self:MakeGhostEntity(Model(model), Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireValue(self.GhostEntity, self:GetOwner())
end

function TOOL:GetModel()
	local model = "models/kobilica/value.mdl"
	local modelcheck = self:GetClientInfo("model")

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", { Text = "#Tool_wire_value_name", Description = "#Tool_wire_value_desc" })

	local cVars = {}
	cVars[0] = "wire_value_numvalues"
	for i=1,12 do
		cVars[#cVars+1] = "wire_value_value" .. i
		cVars[#cVars+1] = "wire_value_valuetype" .. i
	end
	cVars[#cVars+1] = "wire_value_model"

	local options = {}
	options.Default = {}
	options.Default["wire_value_numvalues"] = "1"
	options.Default["wire_value_model"] = "models/kobilica/value.mdl"
	for i = 1, 12 do
		options.Default["wire_value_value"..i] = "0"
		options.Default["wire_value_valuetype"..i] = "Number"
	end

	CPanel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_value",
		Options = options,
		CVars = cVars,
	})

	CPanel:AddControl("Button", {
		Text = "Reset values to zero",
		Name = "Reset",
		Command = [[wire_value_value1 0;
			wire_value_value2 0;
			wire_value_value3 0;
			wire_value_value4 0;
			wire_value_value5 0;
			wire_value_value6 0;
			wire_value_value7 0;
			wire_value_value8 0;
			wire_value_value9 0;
			wire_value_value10 0;
			wire_value_value11 0;
			wire_value_value12 0;
			wire_value_valuetype1 Number;
			wire_value_valuetype2 Number;
			wire_value_valuetype3 Number;
			wire_value_valuetype4 Number;
			wire_value_valuetype5 Number;
			wire_value_valuetype6 Number;
			wire_value_valuetype7 Number;
			wire_value_valuetype8 Number;
			wire_value_valuetype9 Number;
			wire_value_valuetype10 Number;
			wire_value_valuetype11 Number;
			wire_value_valuetype12 Number;]],
	})

	CPanel:AddControl("Slider", {
		Label = "Number of Values",
		Type = "Integer",
		Min = "1",
		Max = "12",
		Command = "wire_value_numvalues",
	})


	local ValuePanels = {}

	// List of Control Panels.
	local ValueList = vgui.Create("DPanelList")
	ValueList:SetHeight(300)
	ValueList:SetAutoSize(false)
	ValueList:SetSpacing(1)
	ValueList:EnableHorizontal(false)
	ValueList:EnableVerticalScrollbar(true)
	ValueList:SetVisible(true)

	local function BuildControlPanels(new, old)
		for i = 1, new do
			j = i + old
			if(ValuePanels[j] and ValuePanels[j]:IsValid()) then return end

			local CommandString = ("wire_value_value"..j)
			local CommandString2 = ("wire_value_valuetype"..j)

			// Control Panel.
			ValuePanels[j] = vgui.Create("DPanel")
			local ValuePanel = ValuePanels[j]
			if((!ValuePanel) or (!ValuePanel:IsValid())) then return end

			ValuePanel:SetWide(ValueList:GetWide()-24)
			ValuePanel:SetTall(74)
			ValuePanel:SetVisible(true)
			local Wide = ValuePanel:GetWide()

			// Top Label.
			local ValueLabel1 = vgui.Create("DLabel", ValuePanel)
			ValueLabel1:SetText("Value "..j..":")
			ValueLabel1:SetPos(4, 4)
			ValueLabel1:SizeToContents()
			ValueLabel1:CenterHorizontal()
			ValueLabel1:SetVisible(true)

			// Value Label.
			local ValueLabel2 = vgui.Create("DLabel", ValuePanel)
			ValueLabel2:SetPos(4, 25)
			ValueLabel2:SetText("Value:")
			ValueLabel2:SizeToContents()
			ValueLabel2:SetVisible(true)

			// Type Label.
			local ValueLabel3 = vgui.Create("DLabel", ValuePanel)
			ValueLabel3:SetPos(4, 50)
			ValueLabel3:SetText("Type:")
			ValueLabel3:SizeToContents()
			ValueLabel3:SetVisible(true)

			// Value Textfield.
			local ValueBox = vgui.Create("DTextEntry", ValuePanel)
			ValueBox:SetPos(40, 25)
			ValueBox:SetText("0")
			ValueBox:SetWide(Wide-44)
			ValueBox:SetTall(20)
			ValueBox:SetMultiline(false)
			if VERSION > 150 then
				Derma_Install_Convar_Functions(ValueBox)
				ValueBox.Think = function()
					ValueBox:ConVarStringThink()
				end
			end
			ValueBox:SetConVar(CommandString)
			ValueBox:SetVisible(true)

			// Type Dropbox.
			local oldv = nil
			local ValueType
			ValueType = vgui.Create("DComboBox", ValuePanel)
			ValueType:SetPos(40, 50)
			ValueType:SetWide(Wide-44)
			ValueType:SetTall(20)
			for k, v in SortedPairs(DataTypes) do
				if ((k ~= "") and (v ~= "")) then
					ValueType:AddChoice(v)
				end
			end
			if VERSION > 150 then
				Derma_Install_Convar_Functions(ValueType)
				ValueType.Think = function()
					ValueType:ConVarStringThink()
				end
				ValueType.OnSelect = function(index, value, data) // Updating the ConVar
					RunConsoleCommand(CommandString2, data)
				end
			end
			ValueType:SetConVar(CommandString2)
			
			ValueType:SetVisible(true)

			// Add Control Panel to List.
			ValueList:AddItem(ValuePanel)
		end
	end

	local oldnumvalues = 0
	ValueList.Think = function()
		newnumvalues = math.Clamp(GetConVarNumber("wire_value_numvalues"), 1, 12)
		if (newnumvalues ~= oldnumvalues) then
			if (newnumvalues < oldnumvalues) then
				for i = 1, (12 - newnumvalues) do
					local Panel = ValuePanels[i + newnumvalues]
					if(Panel and Panel:IsValid()) then
						Panel:Remove()
					end
				end
			elseif (newnumvalues > oldnumvalues) then
				BuildControlPanels(newnumvalues - oldnumvalues, oldnumvalues)
			end
			oldnumvalues = newnumvalues
			ValueList:InvalidateLayout(true)
		end
	end

	// Add List of Control Panels to Toolgun Panel.
	CPanel:AddItem(ValueList)

	ModelPlug_AddToCPanel(CPanel, "value", "wire_value", "#WireValueTool_model", nil, "#WireValueTool_model")
end
