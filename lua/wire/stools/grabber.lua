WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "grabber", "Grabber", "gmod_wire_grabber", WireToolMakeGrabber, "Grabbers" )

if CLIENT then
	language.Add( "tool.wire_grabber.name", "Grabber Tool (Wire)" )
	language.Add( "tool.wire_grabber.desc", "Spawns a constant grabber prop for use with the wire system." )
	language.Add( "tool.wire_grabber.0", "Primary: Create/Update Grabber Secondary: link the grabber to its extra prop that is attached for stabilty" )
	language.Add( "WireGrabberTool_Range", "Max Range:" )
	language.Add( "WireGrabberTool_Gravity", "Disable Gravity" )
end
WireToolSetup.BaseLang("Grabbers")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	CreateConVar('sbox_wire_grabbers_onlyOwnersProps', 1)
end

TOOL.ClientConVar = {
	model	= "models/jaanus/wiretool/wiretool_range.mdl",
	Range	= 100,
	Gravity	= 1,
}

local grabbermodels = {
	["models/jaanus/wiretool/wiretool_grabber_forcer.mdl"] = {},
	["models/jaanus/wiretool/wiretool_range.mdl"] = {}
}

function TOOL:GetGhostMin( min )
	if self:GetClientInfo("model") == "models/jaanus/wiretool/wiretool_grabber_forcer.mdl" then
		return min.z + 20
	end
	return min.z
end

function TOOL:RightClick( trace )
	if not trace.HitPos then return false end
	if CLIENT then return true end
	if not trace.Entity or not trace.Entity:IsValid() then return false end
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
	WireDermaExts.ModelSelect(panel, "wire_grabber_Model", grabbermodels, 1, true)
	panel:CheckBox("#WireGrabberTool_Gravity", "wire_grabber_Gravity")
	panel:NumSlider("#WireGrabberTool_Range", "wire_grabber_Range", 1, 10000, 0)
end
