TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Namer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_namer.name", "Naming Tool" )
    language.Add( "Tool.wire_namer.desc", "Names components." )
    language.Add( "Tool.wire_namer.0", "Primary: Set name\nSecondary: Get name" )
    language.Add( "WireNamerTool_name", "Name:" )
end

TOOL.ClientConVar[ "name" ] = ""

local function SetName( Player, Entity, Data )
	if ( Data and Data.name ) then
		Entity:SetNetworkedString("WireName", Data.name)
		duplicator.StoreEntityModifier( Entity, "WireName", Data )
	end
end
duplicator.RegisterEntityModifier( "WireName", SetName )

function TOOL:LeftClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return end
	if (not trace.Entity.IsWire) then return end

	local name = self:GetClientInfo("name")

	//trace.Entity:SetNetworkedString("WireName", name)

	//made the WireName duplicatable entmod (TAD2020)
	SetName( Player, trace.Entity, {name = name} )

	return true
end


function TOOL:RightClick(trace)
	if (not trace.Entity:IsValid()) then return end
	if (CLIENT) then return end

	local name = trace.Entity:GetNetworkedString("WireName")
	if (not name) then return end

    self:GetOwner():ConCommand('wire_namer_name "' .. name .. '"')
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_namer.name", Description = "#Tool.wire_namer.desc" })

	panel:AddControl("TextBox", {
		Label = "#WireNamerTool_name",
		Command = "wire_namer_name",
		MaxLength = "20"
	})
end
