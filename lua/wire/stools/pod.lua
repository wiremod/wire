WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "pod", "Pod Controller", "gmod_wire_pod", nil, "Pod Controllers" )

if CLIENT then
	language.Add("Tool.wire_pod.name", "Pod Controller Tool (Wire)")
	language.Add("Tool.wire_pod.desc", "Spawn/link a Wire Pod controller.")
	language.Add("Tool.wire_pod.0", "Primary: Create Pod controller. Secondary: Link controller.")
	language.Add("Tool.wire_pod.1", "Now select the pod to link to.")
	language.Add("WirePodTool_pod", "Pod:")
	language.Add("WirePodTool_Keys", "Outputs:")
	language.Add("sboxlimit_wire_pods", "You've hit your Pod Controller limit!")
	language.Add("Undone_Wire Pod", "Undone Wire Pod Controller")
end

if SERVER then
	CreateConVar('sbox_maxwire_pods', 20)
	ModelPlug_Register("podctrlr")
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar["Keys"] = "W=0,1;A=0,1;S=0,1;D=0,1;"

cleanup.Register("wire_pods")

local keytable = {}
keytable["attack"] = IN_ATTACK
keytable["attack1"] = IN_ATTACK
keytable["mouse"] = IN_ATTACK
keytable["mouse1"] = IN_ATTACK
keytable["attack2"] = IN_ATTACK2
keytable["mouse2"] = IN_ATTACK2
keytable["forward"] = IN_FORWARD
keytable["w"] = IN_FORWARD
keytable["left"] = IN_MOVELEFT
keytable["a"] = IN_MOVELEFT
keytable["back"] = IN_BACK
keytable["s"] = IN_BACK
keytable["right"] = IN_MOVERIGHT
keytable["d"] = IN_MOVERIGHT
keytable["reload"] = IN_RELOAD
keytable["r"] = IN_RELOAD
keytable["jump"] = IN_JUMP
keytable["space"] = IN_JUMP
keytable["duck"] = IN_DUCK
keytable["ctrl"] = IN_DUCK
keytable["sprint"] = IN_SPEED
keytable["shift"] = IN_SPEED
keytable["zoom"] = IN_ZOOM

local function ParseKeys(str)
	local keys = {}
	for key, off, on in string.gmatch(str, "(%a+)=(%d+),(%d+);") do
		local l = key:lower()
		if keytable[l] then
			keys[key] = {keytable[l], tonumber(on), tonumber(off)}
		end
	end
	return keys
end

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_pod" then
		trace.Entity:SetKeys(ParseKeys(self:GetClientInfo("Keys")))
		return true
	end

	if not self:GetSWEP():CheckLimit("wire_pods") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_pod = MakeWirePod(ply, trace.HitPos, Ang, self:GetModel(), ParseKeys(self:GetClientInfo("Keys")))

	wire_pod:SetPos(trace.HitPos - trace.HitNormal * wire_pod:OBBMins().z)

	local const = WireLib.Weld(wire_pod, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Pod")
		undo.AddEntity(wire_pod)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("wire_pods", wire_pod)

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and trace.Entity:GetClass() == "gmod_wire_pod" then
		self.PodCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity.GetPassenger then
		self.PodCont:Setup(trace.Entity)
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

if SERVER then

	function MakeWirePod(pl, Pos, Ang, model, Keys)
		if not pl:CheckLimit("wire_pods") then return false end

		local wire_pod = ents.Create("gmod_wire_pod")
		if not wire_pod:IsValid() then return false end

		wire_pod:SetAngles(Ang)
		wire_pod:SetPos(Pos)
		wire_pod:SetModel(Model(model or "models/jaanus/wiretool/wiretool_siren.mdl"))
		wire_pod:Spawn()
		wire_pod:SetPlayer(pl)
		wire_pod.pl = pl

		pl:AddCount("wire_pods", wire_pod)

		if Keys then
			wire_pod:SetKeys(Keys)
		end

		return wire_pod
	end
	duplicator.RegisterEntityClass("gmod_wire_pod", MakeWirePod, "Pos", "Ang", "Model", "Keys")
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "podctrlr", "wire_pod", nil, 1)

	panel:AddControl("TextBox", {
		Label = "#WirePodTool_Keys",
		Command = "wire_pod_Keys",
		Disabled = "true" -- Does this work?
	})
	panel:Help("This tool is deprecated as its functionality is contained within Advanced Pod Controller, and will be removed soon.")
end
