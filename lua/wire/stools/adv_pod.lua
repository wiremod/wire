WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "adv_pod", "Advanced Pod Controller", "gmod_wire_adv_pod", nil, "Advanced Pod Controllers" )

if CLIENT then
	language.Add("tool.wire_adv_pod.name", "Advanced Pod Controller Tool (Wire)")
	language.Add("tool.wire_adv_pod.desc", "Spawn/link a Wire Advanced Pod controller.")
	language.Add("tool.wire_adv_pod.0", "Primary: Create Advanced Pod controller. Secondary: Link Advanced controller.")
	language.Add("tool.wire_adv_pod.1", "Now select the pod to link to.")
end
WireToolSetup.BaseLang("Adv. Pod Controllers")
WireToolSetup.SetupMax( 30, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("podctrlr")
	
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireAdvPod( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.NoLeftOnClass = true
TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

function TOOL:RightClick(trace)
	if (CLIENT) then return true end
	if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
		self.PodCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity:IsVehicle() then
		local owner = self:GetOwner()
		if self.PodCont:Link(trace.Entity) then
			owner:PrintMessage(HUD_PRINTTALK,"Adv. Pod linked!")
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
	ModelPlug_AddToCPanel(panel, "podctrlr", "wire_adv_pod", nil, 1)
end
