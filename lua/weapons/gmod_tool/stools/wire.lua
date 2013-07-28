
-- Load wiremod tools in /lua/wire/stools/
-- Note: If this tool is ever removed, be sure to put this in another stool!
local OLD_TOOL = TOOL
TOOL = nil
include( "wire/tool_loader.lua" )
TOOL = OLD_TOOL

TOOL.Mode			= "wire"
TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Wire (Legacy)"
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add( "Tool.wire.name", "Wiring Tool" )
	language.Add( "Tool.wire.desc", "Used to connect wirable props." )
	language.Add( "Tool.wire.0", "Primary: Attach to selected input.\nSecondary: Next input.\nReload: Unlink selected input." )
	language.Add( "Tool.wire.1", "Primary: Attach to output.\nSecondary: Attach but continue.\nReload: Cancel." )
	language.Add( "Tool.wire.2", "Primary: Confirm attach to output.\nSecondary: Next output.\nReload: Cancel." )
	language.Add( "WireTool_width", "Width:" )
	language.Add( "WireTool_material", "Material:" )
	language.Add( "WireTool_colour", "Material:" )
	language.Add( "undone_wire", "Undone Wire" )
end

TOOL.ClientConVar = {
	width 		= 2,
	material	= "cable/cable2",
	color_r		= 255,
	color_g		= 255,
	color_b		= 255,
}

TOOL.CurrentComponent = nil
TOOL.CurrentInput = nil
TOOL.Inputs = nil
TOOL.CurrentOutput = nil
TOOL.Outputs = nil

function TOOL:LeftClick( trace )
	if (trace.Entity:IsValid()) and (trace.Entity:IsPlayer()) then return end

	local stage = self:GetStage()

	if (stage == 0) then
		if (CLIENT) then
			if (self:GetWeapon():GetNetworkedString("WireCurrentInput")) then
				self:SetStage(0)
				return true
			end
		elseif (self.CurrentInput) then
			local material	= self:GetClientInfo("material")
			local width		= self:GetClientNumber("width")
			local color     = Color(self:GetClientNumber("color_r"), self:GetClientNumber("color_g"), self:GetClientNumber("color_b"))
			if (Wire_Link_Start(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.CurrentInput, material, color, width)) then
				self:SetStage(1)
				return true
			end
		end

		return
	elseif (stage == 1) then
		if (CLIENT) then
			self:SetStage(0)
			return true
		end

		if (!WireLib.HasPorts(trace.Entity) or !trace.Entity.Outputs) then
			self:SetStage(0)

			Wire_Link_Cancel(self:GetOwner():UniqueID())

			WireLib.AddNotify(self:GetOwner(), "Wire source invalid!", NOTIFY_GENERIC, 7)
			return
		end

		self.Outputs = {}
		self.OutputsDesc = {}
		self.OutputsType = {}
		for key,v in pairs(trace.Entity.Outputs) do
			if v.Num then
				self.Outputs[v.Num] = key
				if (v.Desc) then
					self.OutputsDesc[key] = v.Desc
				end
				if (v.Type) then
					self.OutputsType[key] = v.Type
				end
			else
				table.insert(self.Outputs, key)
			end
		end

		local oname = nil
		for k,_ in pairs(trace.Entity.Outputs) do
			if (oname) then
				self:SelectComponent(nil)
				self.CurrentOutput = self.Outputs[1] //oname
				self.OutputEnt = trace.Entity
				self.OutputPos = trace.Entity:WorldToLocal(trace.HitPos)

				local txt = "Output: "..self.CurrentOutput
				if (self.OutputsDesc) and (self.OutputsDesc[self.CurrentOutput]) then
					txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
				end
				if (self.OutputsType) and (self.OutputsType[self.CurrentOutput])
				and (self.OutputsType[self.CurrentOutput] != "NORMAL") then
					txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)

				self:SetStage(2)
				return true
			end

			oname = k
		end

		Wire_Link_End(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), oname, self:GetOwner())

		self:SelectComponent(nil)
		self:SetStage(0)
	else
		if (CLIENT) then
			self:SetStage(0)
			return true
		end

		Wire_Link_End(self:GetOwner():UniqueID(), self.OutputEnt, self.OutputPos, self.CurrentOutput, self:GetOwner())

		self:GetWeapon():SetNetworkedString("WireCurrentInput", "")
		self.CurrentOutput = nil
		self.OutputEnt = nil
		self.OutputPos = nil

		self:SelectComponent(nil)
		self:SetStage(0)
	end

	return true
end


function TOOL:RightClick( trace )
	local stage = self:GetStage()

	if (stage < 2) then
		if (not trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	end

	if (stage == 0) then
		if (CLIENT) then return end

		if (trace.Entity:IsValid()) then
			self:SelectComponent(trace.Entity)
		else
			self:SelectComponent(nil)
		end
		if (not self.Inputs) or (not self.CurrentInput) then return end

		local iNextInput
		for k,v in pairs(self.Inputs) do
			if (v == self.CurrentInput) then iNextInput = k+1 end
		end
		if (iNextInput) then
			self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

			if (iNextInput > #self.Inputs) then iNextInput = 1 end

			self.CurrentInput = self.Inputs[iNextInput]
			if (self.CurrentInput) then self.LastValidInput = self.CurrentInput end

			local txt = ""
			if (IsValid(self.CurrentComponent)) and (WireLib.HasPorts(self.CurrentComponent)) and (self.CurrentInput)
			  and (self.CurrentComponent.Inputs) and (self.CurrentComponent.Inputs[self.CurrentInput])
			  and (self.CurrentComponent.Inputs[self.CurrentInput].Src) then
				txt = "%"..(self.CurrentInput or "")
			else
				txt = self.CurrentInput or ""
			end
			if (self.InputsDesc) and (self.InputsDesc[self.CurrentInput]) then
				txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
			end
			if (self.InputsType) and (self.InputsType[self.CurrentInput])
			and (self.InputsType[self.CurrentInput] != "NORMAL") then
				txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
			end
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)


			if (IsValid(self.CurrentComponent)) then
				self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
			end
		end
	elseif (stage == 1) then
		if (SERVER) then
			Wire_Link_Node(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos+trace.HitNormal))
		end
	elseif (self.Outputs) then
		if (CLIENT) then return end

		local iNextOutput
		for k,v in pairs(self.Outputs) do
			if (v == self.CurrentOutput) then iNextOutput = k+1 end
		end

		if (iNextOutput) then
			self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

			if (iNextOutput > #self.Outputs) then iNextOutput = 1 end

			self.CurrentOutput = self.Outputs[iNextOutput] or "" --if that's nil then somethis is wrong with the ent

			local txt = "Output: "..self.CurrentOutput
			if (self.OutputsDesc) and (self.OutputsDesc[self.CurrentOutput]) then
				txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
			end
			if (self.OutputsType) and (self.OutputsType[self.CurrentOutput])
			and (self.OutputsType[self.CurrentOutput] != "NORMAL") then
				txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
			end
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
		end
	end
end


function TOOL:Reload(trace)
	if (not trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return false end
	if (CLIENT) then return true end

	if (self:GetStage() == 0) then
		if (not IsValid(self.CurrentComponent)) then return end
		if (not self.CurrentInput) or (self.CurrentInput == "") then return end

		Wire_Link_Clear(self.CurrentComponent, self.CurrentInput)

		return true
	end

	Wire_Link_Cancel(self:GetOwner():UniqueID())
	self:SetStage(0)

	return true
end

function TOOL:Holster()
	self:SelectComponent(nil)
end


if (CLIENT) then

	function TOOL:DrawHUD()
		local current_input = self:GetWeapon():GetNetworkedString("WireCurrentInput") or ""
		if (current_input ~= "") then
			if (string.sub(current_input, 1, 1) == "%") then
				draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, string.sub(current_input, 2), "Default", Color(150,50,50,192), Color(255,255,255,255) )
			else
				draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, current_input, "Default", Color(50,50,75,192), Color(255,255,255,255) )
			end
		end
	end

end


function TOOL:Think()
	if (self:GetStage() == 0) then
		local player = self:GetOwner()
		local trace = player:GetEyeTrace()

		if (trace.Hit) and (trace.Entity:IsValid()) then
			self:SelectComponent(trace.Entity)
		else
			self:SelectComponent(nil)
		end
	end
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire.name", Description = "#Tool.wire.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire",

		Options = {
			Default = {
				wire_material = "cable/rope",
				wire_width = "3",
				wire_color_r = "255",
				wire_color_g = "255",
				wire_color_b = "255"

			}
		},

		CVars = {
			[0] = "wire_width",
			[1] = "wire_material",
			[2] = "wire_color_r",
			[3] = "wire_color_g",
			[4] = "wire_color_b"
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireTool_width",
		Type = "Float",
		Min = "0",
		Max = "5",
		Command = "wire_width"
	})
	
	local matselect = panel:AddControl( "RopeMaterial", { Label = "#WireTool_material", convar = "wire_material" } )
	matselect:AddMaterial("Arrowire", "arrowire/arrowire")
	matselect:AddMaterial("Arrowire2", "arrowire/arrowire2")

	panel:AddControl("Color", {
		Label = "#WireTool_colour",
		Red = "wire_color_r",
		Green = "wire_color_g",
		Blue = "wire_color_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end


function TOOL:SelectComponent(ent)
	if (CLIENT) then return end

	if (self.CurrentComponent == ent) then return end

	if (IsValid(self.CurrentComponent)) then
 	    self.CurrentComponent:SetNetworkedBeamString("BlinkWire", "")
	end

	self.CurrentComponent = ent
	self.CurrentInput = nil
	self.Inputs = {}
	self.InputsDesc = {}
	self.InputsType = {}

	local best = nil
	local first = nil
	if (ent) and (ent.Inputs) then
		for k,v in pairs(ent.Inputs) do
			if (not first) then first = k end
			if (k == self.LastValidInput) then best = k end
			if v.Num then
				self.Inputs[v.Num] = k
			else
				table.insert(self.Inputs, k)
			end
			if (v.Desc) then
				self.InputsDesc[k] = v.Desc
			end
			if (v.Type) then
				self.InputsType[k] = v.Type
			end
		end
	end

	first = self.Inputs[1] or first

	self.CurrentInput = best or first
	if (self.CurrentInput) and (self.CurrentInput ~= "") then self.LastValidInput = self.CurrentInput end

	local txt = ""
	if (IsValid(self.CurrentComponent)) and (WireLib.HasPorts(self.CurrentComponent)) and (self.CurrentInput)
	  and (self.CurrentComponent.Inputs) and (self.CurrentComponent.Inputs[self.CurrentInput])
	  and (self.CurrentComponent.Inputs[self.CurrentInput].Src) then
		txt = "%"..(self.CurrentInput or "")
	else
		txt = self.CurrentInput or ""
	end
	if (self.InputsDesc) and (self.InputsDesc[self.CurrentInput]) then
		txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
	end
	if (self.InputsType) and (self.InputsType[self.CurrentInput])
	and (self.InputsType[self.CurrentInput] != "NORMAL") then
		txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
	end
	self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)

	if (IsValid(self.CurrentComponent)) then
		self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
	end
end


