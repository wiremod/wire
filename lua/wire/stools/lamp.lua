WireToolSetup.setCategory("Visuals/Lights")
WireToolSetup.open("lamp", "Lamp", "gmod_wire_lamp", nil, "Lamps")

if CLIENT then
	language.Add("tool.wire_lamp.name", "Lamp Tool (Wire)")
	language.Add("tool.wire_lamp.desc", "Spawns a lamp for use with the wire system.")

	TOOL.Information = {
		{ name = "left", text = "Create hanging lamp" },
		{ name = "right", text = "Create unattached lamp" },
	}

	WireToolSetup.setToolMenuIcon("icon16/lightbulb.png")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("r"), self:GetClientNumber("g"), self:GetClientNumber("b"), self:GetClientInfo("texture"), self:GetClientNumber("fov"), self:GetClientNumber("distance"), self:GetClientNumber("brightness"), self:GetClientNumber("on") ~= 0
	end

	function TOOL:LeftClick_PostMake(ent, ply, trace)
		if ent == true then return true end
		if not IsValid(ent) then return false end

		local const_type = self:GetClientInfo("const")

		if const_type == "weld" then
			local weld = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true, nil, true)

			undo.Create(self.WireClass)
				undo.AddEntity(ent)
				undo.AddEntity(weld)
				undo.SetPlayer(ply)
			undo.Finish()

			ply:AddCleanup(self.WireClass, weld)
		elseif const_type == "rope" then
			local pos2
			local trace_ent = trace.Entity

			if trace_ent:IsValid() then
				local phys = trace_ent:GetPhysicsObjectNum(trace.PhysicsBone)

				if phys:IsValid() then
					pos2 = phys:WorldToLocal(trace.HitPos)
				else
					pos2 = trace_ent:WorldToLocal(trace.HitPos)
				end
			else
				pos2 = trace_ent:WorldToLocal(trace.HitPos)
			end

			local constr, rope = constraint.Rope(ent, trace_ent, 0, trace.PhysicsBone, Vector(-15, 0, 0), pos2, 0, self:GetClientNumber("ropelength"), 0, 1.5, self:GetClientInfo("ropematerial"))

			undo.Create(self.WireClass)
				undo.AddEntity(ent)

				if IsValid(constr) then
					undo.AddEntity(constr)
					ply:AddCleanup(self.WireClass, constr)
				end

				if IsValid(rope) then
					undo.AddEntity(rope)
					ply:AddCleanup(self.WireClass, rope)
				end

				undo.SetPlayer(ply)
			undo.Finish()
		else
			local phys = ent:GetPhysicsObject()

			if phys:IsValid() then
				phys:EnableMotion(false)
			end

			undo.Create(self.WireClass)
				undo.AddEntity(ent)
				undo.SetPlayer(ply)
			undo.Finish()
		end

		ply:AddCleanup(self.WireClass, ent)

		return true
	end
end

function TOOL:GetAngle(trace)
	return trace.HitNormal:Angle()
end

function TOOL:SetPos(ent, trace)
	ent:SetPos(trace.HitPos + trace.HitNormal * 10)
end

TOOL.ClientConVar["ropelength"] = 64
TOOL.ClientConVar["ropematerial"] = "cable/rope"
TOOL.ClientConVar["r"] = 255
TOOL.ClientConVar["g"] = 255
TOOL.ClientConVar["b"] = 255
TOOL.ClientConVar["const"] = "none"
TOOL.ClientConVar["texture"] = "effects/flashlight001"
TOOL.ClientConVar["fov"] = 90
TOOL.ClientConVar["distance"] = 1024
TOOL.ClientConVar["brightness"] = 4
TOOL.ClientConVar["model"] = "models/lamps/torch.mdl"
TOOL.ClientConVar["on"] = 1

function TOOL:RightClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	local ent = self:LeftClick_Make(trace, ply, true)

	if ent == true then return true end
	if not IsValid(ent) then return false end

	undo.Create(self.WireClass)
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup(self.WireClass, ent)

	return true
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_lamp")

	WireDermaExts.ModelSelect(panel, "wire_lamp_model", list.Get("LampModels"), 1, true)
	panel:NumSlider("Rope Length:", "wire_lamp_ropelength", 4, 400, 0)
	panel:NumSlider("FOV:", "wire_lamp_fov", 10, 170, 2)
	panel:NumSlider("Distance:", "wire_lamp_distance", 64, 2048, 0)
	panel:NumSlider("Brightness:", "wire_lamp_brightness", 0, 8, 2)

	local combobox = panel:ComboBox("Constraint:", "wire_lamp_const")
	combobox:AddChoice("Rope", "rope")
	combobox:AddChoice("Weld", "weld")
	combobox:AddChoice("None", "none")

	local startOn = panel:CheckBox("Start On", "wire_lamp_on")
	startOn:SetTooltip("If checked, the lamp will be on when spawned.")

	panel:ColorPicker("Color", "wire_lamp_r", "wire_lamp_g", "wire_lamp_b")

	local matselect = panel:MatSelect("wire_lamp_texture", nil, true, 0.33, 0.33)

	for k, v in pairs(list.Get("LampTextures")) do
		matselect:AddMaterial(v.Name or k, k)
	end
end
