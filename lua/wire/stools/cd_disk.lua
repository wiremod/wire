WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "cd_disk", "CD Disk", "gmod_wire_cd_disk", nil, "CD Disks" )

if (CLIENT) then
	language.Add("Tool.wire_cd_disk.name", "CD Disk Tool (Wire)")
	language.Add("Tool.wire_cd_disk.desc", "Spawns a CD Disk.")
	language.Add("WireDataTransfererTool_cd_disk", "CD Disk:")

	list.Set( "Wire_Laser_Disk_Models", "models/venompapa/wirecd_small.mdl", true )
	list.Set( "Wire_Laser_Disk_Models", "models/venompapa/wirecd_medium.mdl", true )
	list.Set( "Wire_Laser_Disk_Models", "models/venompapa/wirecd_huge.mdl", true )

	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Change model" },
	}

	WireToolSetup.setToolMenuIcon( "venompapa/wirecd/wirecd" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	function TOOL:GetConVars()
		return self:GetClientNumber( "precision" ), self:GetClientNumber( "iradius" ), self:GetClientNumber( "skin" )
	end
end

TOOL.ClientConVar["model"] = "models/venompapa/wirecd_medium.mdl"
TOOL.ClientConVar["skin"] = "0"
TOOL.ClientConVar["precision"] = 4
TOOL.ClientConVar["iradius"] = 10

function TOOL:RightClick(trace)
	if (CLIENT) then return true end

	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "prop_physics") then
			self:GetOwner():ConCommand('wire_cd_disk_model "'..trace.Entity:GetModel()..'"\n')
			self:GetOwner():ConCommand('wire_cd_disk_skin "'..trace.Entity:GetSkin()..'"\n')
		end
	end

	return true
end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cd_disk_Model", list.Get( "Wire_Laser_Disk_Models" ), 1)
	panel:NumSlider("Disk density (inches per block, ipb)","wire_cd_disk_precision",1,16,0)
	panel:NumSlider("Inner radius (disk hole radius)","wire_cd_disk_iradius",1,48,0)
	panel:NumSlider("Disk skin (0..8, standard disks only)","wire_cd_disk_skin",0,8,0)
end
