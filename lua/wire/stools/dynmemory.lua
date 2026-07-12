WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "dynmemory", "Dynamic Memory Chip", "gmod_wire_dynmemory", nil, "Dynamic Memory Chips" )

if CLIENT then
	language.Add( "Tool.wire_dynmemory.name", "Dynamic Memory Chip Tool (Wire)" )
	language.Add( "Tool.wire_dynmemory.desc", "Spawns a Dynamic Memory Chip" )
	language.Add( "Tool.wire_dynmemory.wom", "Write-Only Mode" )
	language.Add( "Tool.wire_dynmemory.womdesc", "Disables reading from memory. Affects highspeed access." )
	language.Add( "Tool.wire_dynmemory.bifurcate", "Bifurcate" )
	language.Add( "Tool.wire_dynmemory.bifurcatedesc", "Bifurcates address lines into ReadAddr(X,Y) and WriteAddr(X,Y). Memory size will be adjusted for round addresses. A memory size of 4096 would mean the bifurcated chip is 64x64. Has no effect on highspeed access." )
	--language.Add( "Tool.wire_dynmemory.pers", "Persistent Memory" )
	--language.Add( "Tool.wire_dynmemory.persdesc", "Should contents save when duped?" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name }, { name = "right", text = "Copy " .. TOOL.Name } }

	--language.Add( "Tool.wire_dynmemory.note", "NOTE: Persistence only saves the first\n512^2 values (256kb) to prevent\nmassive dupe files and lag." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["size"] = 16384
	TOOL.ClientConVar["wom"] = 0
	TOOL.ClientConVar["bifurcate"] = 0
	--TOOL.ClientConVar["persistent"] = 0

	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "gate", "wire_dynmemory", nil, 4)

		panel:NumSlider("Memory Size","wire_dynmemory_size",1,2097152,0)

		panel:AddControl("Checkbox", {
			Label = "#Tool.wire_dynmemory.wom",
			Description = "",
			Command = "wire_dynmemory_wom"
		})

		panel:Help("#Tool.wire_dynmemory.womdesc")

		panel:AddControl("Checkbox", {
			Label = "#Tool.wire_dynmemory.bifurcate",
			Description = "",
			Command = "wire_dynmemory_bifurcate"
		})

		panel:Help("#Tool.wire_dynmemory.bifurcatedesc")

		--[[panel:AddControl("Checkbox", {
			Label = "#Tool.wire_dynmemory.pers",
			Description = "#Tool.wire_dynmemory.persdesc",
			Command = "wire_dynmemory_persistent"
		})
		panel:Help("#Tool.wire_dynmemory.note")]]
	end

	WireToolSetup.setToolMenuIcon( "icon16/database.png" )
else
	function TOOL:GetConVars()
		return self:GetClientNumber( "size" ), self:GetClientNumber( "wom" ), self:GetClientNumber( "bifurcate" )--, self:GetClientNumber( "persistent" )
	end
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 32 )

function TOOL:RightClick(trace)
	if (CLIENT) then return true end

	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "gmod_wire_dynmemory") then
			self:GetOwner():ConCommand('wire_dynmemory_size "'..trace.Entity.Size..'"\n')
			self:GetOwner():ConCommand('wire_dynmemory_wom "'..(trace.Entity.WOM and "1" or "0")..'"\n')
			self:GetOwner():ConCommand('wire_dynmemory_bifurcate "'..(trace.Entity.Bifurcate and "1" or "0")..'"\n')
			return true
		end
	end

	return false
end
