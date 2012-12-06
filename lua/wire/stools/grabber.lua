WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "grabber", "Grabber", "gmod_wire_grabber", nil, "Grabbers" )

if CLIENT then
	language.Add( "tool.wire_grabber.name", "Grabber Tool (Wire)" )
	language.Add( "tool.wire_grabber.desc", "Spawns a constant grabber prop for use with the wire system." )
	language.Add( "tool.wire_grabber.0", "Primary: Create/Update Grabber Secondary: link the grabber to its extra prop that is attached for stabilty" )
	language.Add( "WireGrabberTool_Range", "Max Range:" )
	language.Add( "WireGrabberTool_Gravity", "Disable Gravity" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	CreateConVar('sbox_wire_grabbers_onlyOwnersProps', 1)
	
	function TOOL:GetConVars() 
		return self:GetClientNumber("Range"), self:GetClientNumber("Gravity")~=0
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireGrabber( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model	= "models/jaanus/wiretool/wiretool_range.mdl",
	Range	= 100,
	Gravity	= 1,
}

function TOOL:GetGhostMin( min )
	if self:GetModel() == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
		return min.z + 20
	end
	return min.z
end

function TOOL:RightClick( trace )
	if not trace.HitPos or not IsValid(trace.Entity) then return false end
	if CLIENT then return true end
	if self.Oldent then
		self.Oldent.ExtraProp = trace.Entity
		self.Oldent = nil
		return true
	else
		if trace.Entity:GetClass() == "gmod_wire_grabber" then
			self.Oldent = trace.Entity
			return true
		end
	end
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_grabber")
	ModelPlug_AddToCPanel(panel, "Forcer", "wire_grabber", true, 1)
	panel:CheckBox("#WireGrabberTool_Gravity", "wire_grabber_Gravity")
	panel:NumSlider("#WireGrabberTool_Range", "wire_grabber_Range", 1, 10000, 0)
end
