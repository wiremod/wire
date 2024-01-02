WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "addressbus", "Data - Address Bus", "gmod_wire_addressbus", nil, "Address Buses" )

if ( CLIENT ) then
	language.Add( "Tool.wire_addressbus.name", "Address bus tool (Wire)" )
	language.Add( "Tool.wire_addressbus.desc", "Spawns an address bus. Address spaces may overlap!" )
	TOOL.Information = { { name = "left", text = "Create/Update address bus" } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "addrspace1sz" ] = 0
TOOL.ClientConVar[ "addrspace2sz" ] = 0
TOOL.ClientConVar[ "addrspace3sz" ] = 0
TOOL.ClientConVar[ "addrspace4sz" ] = 0
TOOL.ClientConVar[ "addrspace1st" ] = 0
TOOL.ClientConVar[ "addrspace2st" ] = 0
TOOL.ClientConVar[ "addrspace3st" ] = 0
TOOL.ClientConVar[ "addrspace4st" ] = 0
TOOL.ClientConVar[ "addrspace1rw" ] = 0
TOOL.ClientConVar[ "addrspace2rw" ] = 0
TOOL.ClientConVar[ "addrspace3rw" ] = 0
TOOL.ClientConVar[ "addrspace4rw" ] = 0

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "addrspace1st" ), self:GetClientNumber( "addrspace2st" ), self:GetClientNumber( "addrspace3st" ), self:GetClientNumber( "addrspace4st" ),
			   self:GetClientNumber( "addrspace1sz" ), self:GetClientNumber( "addrspace2sz" ), self:GetClientNumber( "addrspace3sz" ), self:GetClientNumber( "addrspace4sz" ),
				self:GetClientNumber( "addrspace1rw" ), self:GetClientNumber( "addrspace2rw" ), self:GetClientNumber( "addrspace3rw" ), self:GetClientNumber( "addrspace4rw" )

	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL:RightClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_addressbus" ) then
		ply:ConCommand("wire_addressbus_addrspace1sz "..(trace.Entity.MemEnd[1]-trace.Entity.MemStart[1]+1))
		ply:ConCommand("wire_addressbus_addrspace1st "..(trace.Entity.MemStart[1]))
		ply:ConCommand("wire_addressbus_addrspace2sz "..(trace.Entity.MemEnd[2]-trace.Entity.MemStart[2]+1))
		ply:ConCommand("wire_addressbus_addrspace2st "..(trace.Entity.MemStart[2]))
		ply:ConCommand("wire_addressbus_addrspace3sz "..(trace.Entity.MemEnd[3]-trace.Entity.MemStart[3]+1))
		ply:ConCommand("wire_addressbus_addrspace3st "..(trace.Entity.MemStart[3]))
		ply:ConCommand("wire_addressbus_addrspace4sz "..(trace.Entity.MemEnd[4]-trace.Entity.MemStart[4]+1))
		ply:ConCommand("wire_addressbus_addrspace4st "..(trace.Entity.MemStart[4]))
	end
	return true
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_addressbus")
	ModelPlug_AddToCPanel(panel, "gate", "wire_addressbus", nil, 4)

	panel:NumSlider("1 internal offset", "wire_addressbus_addrspace1st", 0, 16777216, 0)
	panel:NumSlider("1 size", 	"wire_addressbus_addrspace1sz", 0, 16777216, 0)
	panel:NumSlider("1 external offset",  	"wire_addressbus_addrspace1rw", 0, 16777216, 0)
	panel:NumSlider("2 internal offset", "wire_addressbus_addrspace2st", 0, 16777216, 0)
	panel:NumSlider("2 size", 	"wire_addressbus_addrspace2sz", 0, 16777216, 0)
	panel:NumSlider("2 external offset",  	"wire_addressbus_addrspace2rw", 0, 16777216, 0)
	panel:NumSlider("3 internal offset", "wire_addressbus_addrspace3st", 0, 16777216, 0)
	panel:NumSlider("3 size", 	"wire_addressbus_addrspace3sz", 0, 16777216, 0)
	panel:NumSlider("3 external offset",  	"wire_addressbus_addrspace3rw", 0, 16777216, 0)
	panel:NumSlider("4 internal offset", "wire_addressbus_addrspace4st", 0, 16777216, 0)
	panel:NumSlider("4 size", 	"wire_addressbus_addrspace4sz", 0, 16777216, 0)
	panel:NumSlider("4 external offset",  	"wire_addressbus_addrspace4rw", 0, 16777216, 0)
end
