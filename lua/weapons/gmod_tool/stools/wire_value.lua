TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Constant Value"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (CLIENT) then
	language.Add("Tool.wire_value.name", "Value Tool (Wire)")
	language.Add("Tool.wire_value.desc", "Spawns a constant value for use with the wire system.")
	language.Add("Tool.wire_value.0", "Primary: Create/Update Value, Secondary: Copy Settings")
	language.Add("WireValueTool_value", "Value:")
	language.Add("WireValueTool_model", "Model:")
	language.Add("sboxlimit_wire_values", "You've hit values limit!")
	language.Add("undone_wirevalue", "Undone Wire Value")
end

TOOL.ClientConVar["model"] = "models/kobilica/value.mdl"
// Supported Data Types.
// Should be requested by client and only kept serverside.
local DataTypes = 
{
	["NORMAL"] = "Number",
	["STRING"] = "String",
	["VECTOR"] = "Vector",
	["ANGLE"] = "Angle"
}

cleanup.Register("wire_values")

if CLIENT then
	function TOOL:LeftClick( trace )
		return true
	end
end


if (SERVER) then
	local playerValues = {}
	CreateConVar('sbox_maxwire_values', 20)
	ModelPlug_Register("value")
	util.AddNetworkString( "wire_value_values" )
	
	net.Receive( "wire_value_values", function( length, ply )
		playerValues[ply] = net.ReadTable()
	end)
	
    local function MakeWireValue( ply, Pos, Ang, model, values )
		if (!ply:CheckLimit("wire_values")) then return false end

		local wire_value = ents.Create("gmod_wire_value")
		if (!wire_value:IsValid()) then return false end
		
		undo.Create("wirevalue")
			undo.AddEntity( wire_value )
			undo.SetPlayer( ply )
		undo.Finish()
		
		wire_value:SetAngles(Ang)
		wire_value:SetPos(Pos)
		wire_value:SetModel(model)
		wire_value:Spawn()

		wire_value:Setup(values)

		wire_value:SetPlayer(ply)

		ply:AddCount("wire_values", wire_value)

		return wire_value
	end
	
	duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Pos", "Ang", "Model", "value")
	
	function TOOL:LeftClick(trace)
		if (!trace.HitPos) then return false end
		if (trace.Entity:IsPlayer()) then return false end
		if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
		
		if trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_value" then
			local ply = self:GetOwner()
			trace.Entity:Setup( playerValues[ply] )
		else
			local ply = self:GetOwner()
			local tbl = playerValues[ply]
			if tbl != nil then
				local ang = trace.HitNormal:Angle()
				ang.pitch = ang.pitch + 90
				local ent = MakeWireValue(ply, trace.HitPos, ang, self:GetModel(), playerValues[ply] )
				local weld = constraint.Weld( ent, trace.Entity, trace.PhysicsBone,0,0, true )
				return true
			else
				return false
			end
		end
		return false
	end

	function TOOL:RightClick(trace)
		return false
	end
end

function TOOL:UpdateGhostWireValue(ent, player)
	if (!ent || !ent:IsValid()) then return end

	local tr = util.GetPlayerTrace(player)
	local trace = util.TraceLine(tr)

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
	local ValuePanels = {}
	local selectedValues = {}
	local function SendUpdate()
		net.Start("wire_value_values")
		net.WriteTable(selectedValues)
		net.SendToServer()
	end
	local function AddValue( panel, id )
		local w,_ = panel:GetSize()
		selectedValues[id] = {
			DataType = "Number",
			Value = 0
		}
		local control = vgui.Create( "DCollapsibleCategory", panel )
		control:SetSize( w, 100 )
		control:SetText( "Value: " .. id )
		control:SetLabel( "Value " .. id )
		
		--control:DockMargin( 5,5,5,5 )
		control:Dock(TOP)
		
		local typeSelection = vgui.Create( "DComboBox", control )
		local _, controlW = control:GetSize()
		typeSelection:SetText( DataTypes["NORMAL"] )
		
		typeSelection:Dock( TOP )
		typeSelection:DockMargin( 5,2,5,2 )
		typeSelection.OnSelect = function( panel, index, value )
			selectedValues[id].DataType = value
			SendUpdate()
		end

		for k,v in pairs( DataTypes ) do
			typeSelection:AddChoice(v)
		end
		
		local valueEntry = vgui.Create( "DTextEntry",control )
		valueEntry:Dock( TOP )
		valueEntry:DockMargin( 5,2,5,2 )
		valueEntry:DockPadding(5,5,5,5)
		valueEntry:SetValue(0)
		local oldLoseFocus = valueEntry.OnLoseFocus -- Spawnmenu Q Fix thank you Nebual :) <3
		valueEntry.OnLoseFocus = function( panel )
			if panel:GetValue() != nil then
				local value = panel:GetValue()
				selectedValues[id].Value = panel:GetValue()
				SendUpdate()
			end
			oldLoseFocus(panel)
		end
		return control 
	end
	
	function TOOL.BuildCPanel( panel )
		local LastValueAmount = 0
		
		--local valuePanel = vgui.Create("DPanel", panel)

		--valuePanel:SetSize(w, 500 )
		--valuePanel:Dock( TOP )
		
		-- WIP.
		local reset = vgui.Create( "DButton", panel )
		local w,_ = panel:GetSize()
		reset:SetSize(w, 25)
		reset:SetText("Reset Values.")
		reset:DockMargin( 5, 5, 5, 5 )
		reset:Dock( TOP )

		
		local valueSlider = vgui.Create( "DNumSlider", panel )
		valueSlider:SetSize(w, 25 )
		valueSlider:SetText( "Amount:" )
		valueSlider:SetMin(1)
		valueSlider:SetMax(8)
		valueSlider:SetDecimals( 0 )
		valueSlider:DockMargin( 5, 5, 5, 5 )
		valueSlider:Dock( TOP )
		
		reset.DoClick = function( thePanel )
			valueSlider:SetValue(1)
			for k,v in pairs(ValuePanels) do
				v:Remove()
				v = nil
			end
			
			for k,v in pairs( selectedValues ) do
				v = nil
			end

			LastValueAmount = 0
			
			valueSlider.OnValueChanged( panel, 1 )
		end
		
		
		valueSlider.OnValueChanged = function( thepanel, value )
			local value = tonumber(value) -- Silly Garry, giving me strings.
			if value != LastValueAmount then
				
				if value > LastValueAmount then
					for i = LastValueAmount + 1, value, 1 do
						ValuePanels[i] = AddValue( panel, i )
						
						local _,h = panel:GetSize()
						panel:SetSize(w, h+120 )
					end
				elseif value < LastValueAmount then
					for i = value + 1, LastValueAmount, 1 do
						selectedValues[i] = nil
						ValuePanels[i]:Remove()
						ValuePanels[i] = nil
						local _,h = panel:GetSize()
						panel:SetSize(w, h-120 )
					end
				else
					Msg("Error Incorrect value exists?!?!.\n")
				end
				LastValueAmount = value
				SendUpdate()
			end
		end
		valueSlider.OnValueChanged( panel, 1 )
	end
end
