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



TOOL.ClientConVar["model"] = "models/kobilica/value.mdl"
TOOL.ClientConVar["numvalues"] = "1"
for i = 1, 12 do
	TOOL.ClientConVar["value" .. i] = "0"
	TOOL.ClientConVar["valuetype" .. i] = "Number"
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

if (SERVER) then
	local playerValues = {}
	CreateConVar('sbox_maxwire_values', 20)
	ModelPlug_Register("value")
	util.AddNetworkString( "wire_value_values" )
	
	net.Receive( "wire_value_values", function( length, ply )
		print("BEGIN")
		playerValues[ply] = net.ReadTable()
		PrintTable( playerValues[ply] )
		print("DONE.")
	end)

	function TOOL:LeftClick(trace)
		if (!trace.HitPos) then return false end
		if (trace.Entity:IsPlayer()) then return false end
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

		local ply = self:GetOwner()
		local tbl = playerValues[ply]
		if tbl != nil then
			Msg("Got table!\n")
			PrintTable( tbl )
			return true
		else
			return false
		end
		return true
	end
end
if CLIENT then
	function TOOL:LeftClick( trace )
		return true
	end
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

	local tr 	= util.GetPlayerTrace( player )
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
if CLIENT then
	local selectedValues = {}
	local function SendUpdate()
		net.Start("wire_value_values")
		net.WriteTable(selectedValues)
		net.SendToServer()
		print("Data Sent!")
	end
	local function AddValue( panel, id )
		local w,_ = panel:GetSize()
		selectedValues[id] = {
			DataType = "Number",
			Value = ""
		}
		local control = vgui.Create( "DCollapsibleCategory", panel )
		control:SetSize( w-6, 100 )
		control:SetText( "Value: " .. id )
		control:SetLabel( "Value " .. id )
		control:DockMargin( 5,5,5,5 )
		control:Dock(TOP)
		
		local controlPanel = vgui.Create( "DPanel", control )
		controlPanel:SetSize( w-6, 100 )
		controlPanel:Dock(TOP)
		
		local typeSelection = vgui.Create( "DComboBox", controlPanel )
		local _, controlW = control:GetSize()
		typeSelection:SetText( DataTypes[""] )
		typeSelection:SetSize( controlW , 25 )
		typeSelection:DockMargin( 5,5,5,5)
		typeSelection:Dock( TOP )
		typeSelection.OnSelect = function( panel, index, value )
			selectedValues[id].DataType = value
			SendUpdate()
		end

		for k,v in pairs( DataTypes ) do
			if k != "" then
				typeSelection:AddChoice(v)
			end
		end
		
		local valueEntry = vgui.Create( "DTextEntry", controlPanel )
		valueEntry:SetSize( controlW, 25 )
		valueEntry:DockMargin( 5,5,5,5 )
		valueEntry:Dock( TOP )
		valueEntry.OnEnter = function ( panel )
			if panel:GetValue() != nil then
				selectedValues[id].Value = panel:GetValue()
				SendUpdate()
			end
		end

		return control 
	end
	local ValuePanels = {}
	function TOOL.BuildCPanel( panel )
		local LastValueAmount = 0
		
		local valuePanel = vgui.Create("DPanel", panel)

		valuePanel:SetSize(w, 500 )
		valuePanel:Dock( TOP )
		
		-- WIP.
		local reset = vgui.Create( "DButton", valuePanel )
		local w,_ = panel:GetSize()
		reset:SetSize(w, 25)
		reset:SetText("Reset Values.")
		reset:DockMargin( 5, 5, 5, 5 )
		reset:Dock( TOP )
		
		local valueSlider = vgui.Create( "DNumSlider", valuePanel )
		valueSlider:SetSize(w, 25 )
		valueSlider:SetText( "Amount:" )
		valueSlider:SetMin(1)
		valueSlider:SetMax(20)
		valueSlider:SetDecimals( 0 )
		--valueSlider:SetConVar("numvalues")
		valueSlider:DockMargin( 5, 5, 5, 5 )
		valueSlider:Dock( TOP )
		
		
		
		valueSlider.OnValueChanged = function( panel, value )
			local value = tonumber(value) -- Silly Garry, giving me strings.
			if value != LastValueAmount then
				
				if value > LastValueAmount then
					for i = LastValueAmount + 1, value, 1 do
						ValuePanels[i] = AddValue( valuePanel, i )
						
						local _,h = valuePanel:GetSize()
						valuePanel:SetSize(w, h+120 )
					end
				elseif value < LastValueAmount then
					for i = value + 1, LastValueAmount, 1 do
						selectedValues[i] = nil
						ValuePanels[i]:Remove()
						ValuePanels[i] = nil
						local _,h = valuePanel:GetSize()
						valuePanel:SetSize(w, h-120 )
					end
				else
					Msg("Error.\n")
				end
				LastValueAmount = value
				SendUpdate()
			end
		end
		
		valueSlider.OnValueChanged( valuePanel, 1 )
		
		
		
	end

end