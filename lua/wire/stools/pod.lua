WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "pod", "Pod Controller", "gmod_wire_pod", nil, "Pod Controllers" )

if CLIENT then
	language.Add("tool.wire_pod.name", "Pod Controller Tool (Wire)")
	language.Add("tool.wire_pod.desc", "Spawn/link a Wire Pod controller.")
	language.Add("tool.wire_pod.0", "Primary: Create Pod controller. Secondary: Link controller.")
	language.Add("tool.wire_pod.1", "Now select the pod to link to.")
end
WireToolSetup.BaseLang("Pod Controllers")
WireToolSetup.SetupMax( 30 )

if SERVER then
	ModelPlug_Register("podctrlr")
end

TOOL.NoLeftOnClass = true
TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

function TOOL:RightClick(trace)
	if (CLIENT) then return true end
	if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_pod" then
		self.PodCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity:IsVehicle() then
		local owner = self:GetOwner()
		if self.PodCont:Link(trace.Entity) then
			owner:PrintMessage(HUD_PRINTTALK,"Pod linked!")
		else
			owner:PrintMessage(HUD_PRINTTALK,"Link failed!")
		end
		self:SetStage(0)
		self.PodCont = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.PodCont = nil
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "podctrlr", "wire_pod", nil, 1)
end
