TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Wire Advanced"
TOOL.Tab			= "Wire"

if CLIENT then
	language.Add( "Tool_wire_adv_name", "Advanced Wiring Tool" )
	language.Add( "Tool_wire_adv_desc", "Used to connect wirable props." )
	language.Add( "Tool_wire_adv_0", "Primary: Attach to selected input, Secondary: Next input, Reload: Unlink selected input." )
	language.Add( "Tool_wire_adv_1", "Primary: Attach to output, Secondary: Attach but continue, Reload: Cancel." )
	language.Add( "Tool_wire_adv_2", "Primary: Confirm attach to output, Secondary: Next output, Reload: Cancel." )
	language.Add( "WireTool_scrollwithoutmod", "Scroll without modifier key" )
end

TOOL.ClientConVar = {
	width		= 2,
	material	= "cable/cable2",
	color_r		= 255,
	color_g		= 255,
	color_b		= 255,
	scrollwithoutmod = 1,
}

-- these lines are pretty useless, but they serve as documentation :)
TOOL.CurrentComponent = nil
TOOL.CurrentInput = nil
TOOL.Inputs = nil
TOOL.CurrentOutput = nil
TOOL.Outputs = nil

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

cleanup.Register( "wireconstraints" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end

	local stage = self:GetStage()

	if stage == 0 then
		if CLIENT then
			if self:GetWeapon():GetNetworkedString("WireCurrentInput") then
				self:SetStage(0)
				return true
			end
		elseif self.CurrentInput then
			local material	= self:GetClientInfo("material")
			local width		= self:GetClientNumber("width")
			local color     = Color(self:GetClientNumber("color_r"), self:GetClientNumber("color_g"), self:GetClientNumber("color_b"))
			if Wire_Link_Start(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.CurrentInput, material, color, width) then
				self:SetStage(1)
				self:GetWeapon():SetNetworkedInt("WireAdvStage",1)
				return true
			end
		end

		return
	elseif stage == 1 then
		if CLIENT then
			self:SetStage(0)
			return true
		end

		if not trace.Entity.Outputs then
			self:SetStage(0)
			self:GetWeapon():SetNetworkedInt("WireAdvStage",0)

			Wire_Link_Cancel(self:GetOwner():UniqueID())

			local inp = self.CurrentComponent.Inputs[self.CurrentInput]

			if inp.Type == "ENTITY" then
				-- TODO: trigger input with entity
				inp.Value = trace.Entity
				self.CurrentComponent:TriggerInput(self.CurrentInput, trace.Entity)
				WireLib.AddNotify(self:GetOwner(), "Triggered entity input '"..self.CurrentInput.."' with '"..tostring(trace.Entity).."'.", NOTIFY_GENERIC, 7 )
				return
			end

			WireLib.AddNotify(self:GetOwner(), "Wire source invalid!", NOTIFY_GENERIC, 7)
			return
		end

		self.Outputs = {}
		self.OutputsDesc = {}
		self.OutputsType = {}
		for key,v in pairs_sortvalues(trace.Entity.Outputs, WireLib.PortComparator) do
			if v.Num then
				self.Outputs[v.Num] = key
				if v.Desc then
					self.OutputsDesc[key] = v.Desc
				end
				if v.Type then
					self.OutputsType[key] = v.Type
				end
			else
				table.insert(self.Outputs, key)
			end
		end

		local oname = nil
		for k,_ in pairs_sortvalues(trace.Entity.Outputs, WireLib.PortComparator) do
			if oname then
				self:SelectComponent(nil)
				self.CurrentOutput = self.Outputs[1] --oname
				self.OutputEnt = trace.Entity
				self.OutputPos = trace.Entity:WorldToLocal(trace.HitPos)
				--New

				local tab = table.concat(self.Outputs,",")..table.concat(self.OutputsDesc,",")..table.concat(self.OutputsType,",")
				if self.LastInputs ~= tab then
					umsg.Start("wireoutputlist",self:GetOwner())
						umsg.String(self.OutputEnt:GetClass())
						umsg.Short(#self.Outputs)
						for k,v in pairs(self.Outputs) do
							local txt = v
							if self.OutputsDesc and self.OutputsDesc[v] then
								txt = txt.." ("..self.OutputsDesc[v]..")"
							end
							if self.OutputsType and self.OutputsType[v]
							and self.OutputsType[v] ~= "NORMAL" then
								txt = txt.." ["..self.OutputsType[v].."]"
							end
							umsg.String(txt)
						end
					umsg.End()
					self.LastInputs = tab
				end
				--Old

				local txt = "Output: "..self.CurrentOutput
				if self.OutputsDesc and self.OutputsDesc[self.CurrentOutput] then
					txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
				end
				if self.OutputsType and self.OutputsType[self.CurrentOutput]
				and self.OutputsType[self.CurrentOutput] ~= "NORMAL" then
					txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)

				self:SetStage(2)
				self:GetWeapon():SetNetworkedInt("WireAdvStage",2)
				return true
			end

			oname = k
		end

		Wire_Link_End(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), oname, self:GetOwner())

		self:SelectComponent(nil)
		self:SetStage(0)
		self:GetWeapon():SetNetworkedInt("WireAdvStage",0)
	else
		if CLIENT then
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
		self:GetWeapon():SetNetworkedInt("WireAdvStage",0)
	end

	return true
end

if CLIENT then
	local function check_override(pl)
		-- find toolgun
		local activeWep = pl:GetActiveWeapon()
		if not ValidEntity(activeWep) then return end

		-- checks...
		if activeWep:GetClass() ~= "gmod_tool" then return end
		if activeWep:GetMode() ~= "wire_adv" then return end

		-- find tool
		local tool = activeWep:GetToolObject("wire_adv")
		local trace = pl:GetEyeTrace()

		-- allow override if conditions are met
		if pl:GetInfo("wire_adv_scrollwithoutmod") == "0" and not pl:KeyDown(IN_SPEED) then return false end
		--if tool.OutputEntClass then return true end
		if activeWep:GetNetworkedInt("WireAdvStage") == 2 then return true end
		if not trace.Entity:IsValid() then return false end
		return trace.Entity:GetClass() == tool.InputEntClass
	end
	hook.Add("PlayerBindPress", "wire_wire_adv", function(pl, bind, pressed)
		if not pressed then return end

		if bind == "invnext" then
			if check_override(pl) then
				RunConsoleCommand("wire_adv_next")
				return true
			end
		elseif bind == "invprev" then
			if check_override(pl) then
				RunConsoleCommand("wire_adv_prev")
				return true
			end
		end
	end)
end

if SERVER then
	concommand.Add("wire_adv_next",function(pl)
		if not pl:GetWeapon("gmod_tool"):IsValid() then return end
		local self = pl:GetWeapon("gmod_tool").Tool.wire_adv
		local stage = self:GetStage()
		if stage == 0 then
			if not self.Inputs or not self.CurrentInput then return end

			local iNextInput
			for k,v in pairs(self.Inputs) do
				if v == self.CurrentInput then iNextInput = k+1 end
			end
			if iNextInput then
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

				if iNextInput > #self.Inputs then iNextInput = 1 end

				self.CurrentInput = self.Inputs[iNextInput]
				if self.CurrentInput then self.LastValidInput = self.CurrentInput end

				--[[if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput)
				  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput])
				  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
					self:GetWeapon():SetNetworkedString("WireCurrentInput", self.CurrentInput or ""))
				else
					self:GetWeapon():SetNetworkedString("WireCurrentInput", self.CurrentInput or "")
				end]]

				local txt = ""
				if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput
				  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput]
				  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
					txt = (self.CurrentInput or "")
				else
					txt = self.CurrentInput or ""
				end
				if self.InputsDesc and self.InputsDesc[self.CurrentInput] then
					txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
				end
				if self.InputsType and self.InputsType[self.CurrentInput]
				and self.InputsType[self.CurrentInput] ~= "NORMAL" then
					txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)


				if self.CurrentComponent and self.CurrentComponent:IsValid() then
					self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
				end
			end
		elseif self.Outputs then
			--New

			local tab = table.concat(self.Outputs,",")..table.concat(self.OutputsDesc,",")..table.concat(self.OutputsType,",")
			if self.LastInputs ~= tab then
				umsg.Start("wireoutputlist",self:GetOwner())
					umsg.String("")
					umsg.Short(#self.Outputs)
					for k,v in pairs(self.Outputs) do
						local txt = v
						if self.OutputsDesc and self.OutputsDesc[v] then
							txt = txt.." ("..self.OutputsDesc[v]..")"
						end
						if self.OutputsType and self.OutputsType[v]
						and self.OutputsType[v] ~= "NORMAL" then
							txt = txt.." ["..self.OutputsType[v].."]"
						end
						umsg.String(txt)
					end
				umsg.End()
				self.LastInputs = tab
			end
			--Old

			local iNextOutput
			for k,v in pairs(self.Outputs) do
				if v == self.CurrentOutput then iNextOutput = k+1 end
			end

			if iNextOutput then
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

				if iNextOutput > #self.Outputs then iNextOutput = 1 end

				self.CurrentOutput = self.Outputs[iNextOutput] or "" --if that's nil then somethis is wrong with the ent

				local txt = "Output: "..self.CurrentOutput
				if self.OutputsDesc and self.OutputsDesc[self.CurrentOutput] then
					txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
				end
				if self.OutputsType and self.OutputsType[self.CurrentOutput]
				and self.OutputsType[self.CurrentOutput] ~= "NORMAL" then
					txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
			end
		end
	end)
	concommand.Add("wire_adv_prev",function(pl)
		if not pl:GetWeapon("gmod_tool"):IsValid() then return end
		local self = pl:GetWeapon("gmod_tool").Tool.wire_adv
		local stage = self:GetStage()
		if stage == 0 then
			if not self.Inputs or not self.CurrentInput then return end

			local iNextInput
			for k,v in pairs(self.Inputs) do
				if v == self.CurrentInput then iNextInput = k-1 end
			end
			if iNextInput then
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

				if iNextInput < 1 then iNextInput = #self.Inputs end

				self.CurrentInput = self.Inputs[iNextInput]
				if self.CurrentInput then self.LastValidInput = self.CurrentInput end

				--[[if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput)
				  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput])
				  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
					self:GetWeapon():SetNetworkedString("WireCurrentInput", self.CurrentInput or ""))
				else
					self:GetWeapon():SetNetworkedString("WireCurrentInput", self.CurrentInput or "")
				end]]

				local txt = ""
				if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput
				  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput]
				  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
					txt = self.CurrentInput or ""
				else
					txt = self.CurrentInput or ""
				end
				if self.InputsDesc and self.InputsDesc[self.CurrentInput] then
					txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
				end
				if self.InputsType and self.InputsType[self.CurrentInput]
				and self.InputsType[self.CurrentInput] ~= "NORMAL" then
					txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)


				if self.CurrentComponent and self.CurrentComponent:IsValid() then
					self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
				end
			end
		elseif self.Outputs then
			if CLIENT then return end
			--New

			local tab = table.concat(self.Outputs,",")..table.concat(self.OutputsDesc,",")..table.concat(self.OutputsType,",")
			if self.LastInputs ~= tab then
				umsg.Start("wireoutputlist",self:GetOwner())
					umsg.String("")
					umsg.Short(#self.Outputs)
					for k,v in pairs(self.Outputs) do
						local txt = v
						if self.OutputsDesc and self.OutputsDesc[v] then
							txt = txt.." ("..self.OutputsDesc[v]..")"
						end
						if self.OutputsType and self.OutputsType[v]
						and self.OutputsType[v] ~= "NORMAL" then
							txt = txt.." ["..self.OutputsType[v].."]"
						end
						umsg.String(txt)
					end
				umsg.End()
				self.LastInputs = tab
			end
			--Old

			local iNextOutput
			for k,v in pairs(self.Outputs) do
				if v == self.CurrentOutput then iNextOutput = k-1 end
			end

			if iNextOutput then
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

				if iNextOutput < 1 then iNextOutput = #self.Outputs end

				self.CurrentOutput = self.Outputs[iNextOutput] or "" --if that's nil then somethis is wrong with the ent

				local txt = "Output: "..self.CurrentOutput
				if self.OutputsDesc and self.OutputsDesc[self.CurrentOutput] then
					txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
				end
				if self.OutputsType and self.OutputsType[self.CurrentOutput]
				and self.OutputsType[self.CurrentOutput] ~= "NORMAL" then
					txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
				end
				self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
			end
		end
	end)

end

function TOOL:RightClick( trace )
	local stage = self:GetStage()

	if stage < 2 then
		if not trace.Entity:IsValid() or trace.Entity:IsPlayer() then return end
	end

	if stage == 0 then
		if CLIENT then return end

		if trace.Entity:IsValid() then
			self:SelectComponent(trace.Entity)
		else
			self:SelectComponent(nil)
		end
		if not self.Inputs or not self.CurrentInput then return end

		local iNextInput
		for k,v in pairs(self.Inputs) do
			if v == self.CurrentInput then iNextInput = k+1 end
		end
		if iNextInput then
			self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

			if iNextInput > #self.Inputs then iNextInput = 1 end

			self.CurrentInput = self.Inputs[iNextInput]
			if self.CurrentInput then self.LastValidInput = self.CurrentInput end

			--[[if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput)
			  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput])
			  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
				self:GetWeapon():SetNetworkedString("WireCurrentInput", (self.CurrentInput or ""))
			else
				self:GetWeapon():SetNetworkedString("WireCurrentInput", self.CurrentInput or "")
			end]]

			local txt = ""
			if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput
			  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput]
			  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
				txt = (self.CurrentInput or "")
			else
				txt = self.CurrentInput or ""
			end
			if self.InputsDesc and self.InputsDesc[self.CurrentInput] then
				txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
			end
			if self.InputsType and self.InputsType[self.CurrentInput]
			and self.InputsType[self.CurrentInput] ~= "NORMAL" then
				txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
			end
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)


			if self.CurrentComponent and self.CurrentComponent:IsValid() then
				self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
			end
		end
	elseif stage == 1 then
		if SERVER then
			Wire_Link_Node(self:GetOwner():UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos+trace.HitNormal))
		end
	elseif self.Outputs then
		if CLIENT then return end
		--New

		local tab = table.concat(self.Outputs,",")..table.concat(self.OutputsDesc,",")..table.concat(self.OutputsType,",")
		if self.LastInputs ~= tab then
			umsg.Start("wireoutputlist",self:GetOwner())
				umsg.String(self.OutputEnt:GetClass())
				umsg.Short(#self.Outputs)
				for k,v in pairs(self.Outputs) do
					local txt = v
					if self.OutputsDesc and self.OutputsDesc[v] then
						txt = txt.." ("..self.OutputsDesc[v]..")"
					end
					if self.OutputsType and self.OutputsType[v]
					and self.OutputsType[v] ~= "NORMAL" then
						txt = txt.." ["..self.OutputsType[v].."]"
					end
					umsg.String(txt)
				end
			umsg.End()
			self.LastInputs = tab
		end
		--Old

		local iNextOutput
		for k,v in pairs(self.Outputs) do
			if v == self.CurrentOutput  then iNextOutput = k+1 end
		end

		if iNextOutput then
			self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

			if iNextOutput > #self.Outputs then iNextOutput = 1 end

			self.CurrentOutput = self.Outputs[iNextOutput] or "" --if that's nil then somethis is wrong with the ent

			local txt = "Output: "..self.CurrentOutput
			if self.OutputsDesc and self.OutputsDesc[self.CurrentOutput] then
				txt = txt.." ("..self.OutputsDesc[self.CurrentOutput]..")"
			end
			if self.OutputsType and self.OutputsType[self.CurrentOutput]
			and self.OutputsType[self.CurrentOutput] ~= "NORMAL" then
				txt = txt.." ["..self.OutputsType[self.CurrentOutput].."]"
			end
			self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)
		end
	end
end


function TOOL:Reload(trace)
	if not trace.Entity:IsValid() or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	if self:GetStage() == 0 then
		if not self.CurrentComponent or not self.CurrentComponent:IsValid() then return end
		if not self.CurrentInput or self.CurrentInput == "" then return end

		Wire_Link_Clear(self.CurrentComponent, self.CurrentInput)

		--New
		local ent = self.CurrentComponent
		local tab = ""
		for k,v in pairs(self.Inputs) do
			tab = tab..v.."|"..((
				ent and
				ent:IsValid() and
				ent.Inputs and
				ent.Inputs[v] and
				ent.Inputs[v].Src) and "1|" or "0|"
			)
		end

		if self.LastInputs ~= tab then
			umsg.Start("wireinputlist",self:GetOwner())
				umsg.String(ent:GetClass())
				umsg.Short(#self.Inputs)
				for k,v in pairs(self.Inputs) do

					local txt = v
					if self.InputsDesc and self.InputsDesc[v] then
						txt = txt.." ("..self.InputsDesc[v]..")"
					end
					if self.InputsType and self.InputsType[v]
					and self.InputsType[v] ~= "NORMAL" then
						txt = txt.." ["..self.InputsType[v].."]"
					end

					umsg.String(txt)
					if
						ent and
						ent:IsValid() and
						ent.Inputs and
						ent.Inputs[v] and
						ent.Inputs[v].Src
					then
						umsg.Bool(true)
					else
						umsg.Bool(false)
					end
				end
			umsg.End()
			self.LastInputs = tab
		end
		return true
	end

	Wire_Link_Cancel(self:GetOwner():UniqueID())
	self:SetStage(0)
	self:GetWeapon():SetNetworkedInt("WireAdvStage",0)

	return true
end

function TOOL:Holster()
	self:SelectComponent(nil)
	self:GetWeapon():SetNetworkedInt("WireAdvStage",0)
end


if CLIENT then

	function TOOL:DrawHUD()
		local current_input = self:GetWeapon():GetNetworkedString("WireCurrentInput" or "")
		--[[
		if current_input ~= "" then
			if string.sub(current_input, 1, 1 == "%") then -- I see a misplaced ")"
				draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, string.sub(current_input, 2), "Default", Color(150,50,50,192), Color(255,255,255,255) )
			else
				draw.WordBox(8, ScrW()/2+10, ScrH()/2+10, current_input, "Default", Color(50,50,75,192), Color(255,255,255,255) )
			end
		end
		]]

		--Begin
		local stage = self:GetWeapon():GetNetworkedInt("WireAdvStage")
		--draw.DrawText(stage,"Trebuchet24",0,0,Color(255,255,255,255),0)
		if stage == 2 and type(self.Outputs) == "table" then
			surface.SetFont("Trebuchet24")
			local twa = surface.GetTextSize(self.WireCurrentInput)
			draw.RoundedBox(8,
				ScrW()/2+20,
				ScrH()/2-12-4,
				twa+16,
				24+8,
				Color(50,50,75,192)
			)
			draw.DrawText(self.WireCurrentInput,"Trebuchet24",ScrW()/2+20+8,ScrH()/2-12,Color(255,255,255,255),0)
			twa = twa+16

			surface.SetFont("Trebuchet24")
			local tw = surface.GetTextSize(table.concat(self.Outputs,"\n"))
			draw.RoundedBox(8,
				twa+ScrW()/2+20,
				ScrH()/2-#self.Outputs*24/2-8,
				tw+16,
				#self.Outputs*24+16,
				Color(50,50,75,192)
			)

			for k,v in pairs(self.Outputs) do
				if self:GetWeapon():GetNetworkedString("WireCurrentInput") == "Output: "..v then
					draw.RoundedBox(4,
						twa+ScrW()/2+20+4,
						ScrH()/2-#self.Outputs*24/2+(k-1)*24,
						tw+8,
						24,
						Color(0,150,0,192)
					)
				end
				draw.DrawText(
					v,"Trebuchet24",
					twa+ScrW()/2+20+8,
					ScrH()/2-#self.Outputs*24/2+(k-1)*24,
					Color(255,255,255,255),
					0
				)
			end
		elseif stage == 0 then

			local tr = utilx.GetPlayerTrace(LocalPlayer(), LocalPlayer():GetCursorAimVector())
			local trace = util.TraceLine(tr)

			if trace.Hit and trace.Entity:IsValid() and trace.Entity:GetClass() == self.InputEntClass and type(self.Inputs) == "table" then
				surface.SetFont("Trebuchet24")
				local tw = surface.GetTextSize(table.concat(self.Inputs,"\n"))
				draw.RoundedBox(8,
					ScrW()/2+20,
					ScrH()/2-#self.Inputs*24/2-8,
					tw+16,
					#self.Inputs*24+16,
					Color(50,50,75,192)
				)

				for k,v in pairs(self.Inputs) do
					local col = Color(255,255,255,255)
					if self.InputsW[k] then
						col = Color(255,0,0,255)
					end

					if self:GetWeapon():GetNetworkedString("WireCurrentInput") == v then
						draw.RoundedBox(4,
							ScrW()/2+20+4,
							ScrH()/2-#self.Inputs*24/2+(k-1)*24,
							tw+8,
							24,
							Color(0,150,0,192)
						)
						self.WireCurrentInput = v
					end

					draw.DrawText(
						v,"Trebuchet24",
						ScrW()/2+20+8,
						ScrH()/2-#self.Inputs*24/2+(k-1)*24,
						col,
						0
					)
				end
			end
		elseif stage == 1 then
			surface.SetFont("Trebuchet24")
			local tw = surface.GetTextSize(self.WireCurrentInput)
			draw.RoundedBox(8,
				ScrW()/2+20,
				ScrH()/2-12-4,
				tw+16,
				24+8,
				Color(50,50,75,192)
			)
			draw.DrawText(self.WireCurrentInput,"Trebuchet24",ScrW()/2+20+8,ScrH()/2-12,Color(255,255,255,255),0)
		end
	end

end


function TOOL:Think()
	if self:GetStage() == 0 then
		local player = self:GetOwner()
		local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
		local trace = util.TraceLine(tr)

		if trace.Hit and trace.Entity:IsValid() then
			self:SelectComponent(trace.Entity)
		else
			self:SelectComponent(nil)
		end
	end
end


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_name", Description = "#Tool_wire_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_adv",

		Options = {
			Default = {
				wire_adv_material = "cable/rope",
				wire_adv_width = "3",
			}
		},

		CVars = {
			[0] = "wire_adv_width",
			[1] = "wire_adv_material",
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireTool_width",
		Type = "Float",
		Min = ".1",
		Max = "5",
		Command = "wire_adv_width"
	})

	panel:AddControl("MaterialGallery", {
		Label = "#WireTool_material",
		Height = "64",
		Width = "24",
		Rows = "1",
		Stretch = "1",

		Options = {
			["Wire"] = { Material = "cable/rope_icon", wire_adv_material = "cable/rope" },
			["Cable 2"] = { Material = "cable/cable_icon", wire_adv_material = "cable/cable2" },
			["XBeam"] = { Material = "cable/xbeam", wire_adv_material = "cable/xbeam" },
			["Red Laser"] = { Material = "cable/redlaser", wire_adv_material = "cable/redlaser" },
			["Blue Electric"] = { Material = "cable/blue_elec", wire_adv_material = "cable/blue_elec" },
			["Physics Beam"] = { Material = "cable/physbeam", wire_adv_material = "cable/physbeam" },
			["Hydra"] = { Material = "cable/hydra", wire_adv_material = "cable/hydra" },

		--new wire materials by Acegikmo
			["Arrowire"] = { Material = "arrowire/arrowire", wire_adv_material = "arrowire/arrowire" },
			["Arrowire2"] = { Material = "arrowire/arrowire2", wire_adv_material = "arrowire/arrowire2" },
		},

		CVars = {
			[0] = "wire_adv_material"
		}
	})

	panel:AddControl("Color", {
		Label = "#WireTool_colour",
		Red = "wire_adv_color_r",
		Green = "wire_adv_color_g",
		Blue = "wire_adv_color_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireTool_scrollwithoutmod",
		Command = "wire_adv_scrollwithoutmod"
	})
end

if CLIENT then
	usermessage.Hook("wireinputlist",function(um)
		local self = LocalPlayer():GetActiveWeapon().Tool.wire_adv
		local temp = um:ReadString()
		if temp ~= "" then
			self.InputEntClass = temp
		end
		self.Inputs = {}
		self.InputsW = {}
		for i = 1, um:ReadShort() do
			self.Inputs[i] = um:ReadString()
			self.InputsW[i] = um:ReadBool()
		end
	end)
	usermessage.Hook("wireoutputlist",function(um)
		local self = LocalPlayer():GetActiveWeapon().Tool.wire_adv
		-- TODO: remove
		local temp = um:ReadString()
		if temp ~= "" then
			self.OutputEntClass = temp
		end
		self.Outputs = {}
		for i = 1, um:ReadShort() do
			self.Outputs[i] = um:ReadString()
		end
	end)
end

function TOOL:SelectComponent(ent)
	if CLIENT then return end

	if self.CurrentComponent == ent then return end

	if self.CurrentComponent and self.CurrentComponent:IsValid() then
		self.CurrentComponent:SetNetworkedBeamString("BlinkWire", "")
	end

	self.CurrentComponent = ent
	self.CurrentInput = nil
	self.Inputs = {}
	self.InputsDesc = {}
	self.InputsType = {}

	local best = nil
	local first = nil
	if ent and ent.Inputs then
		for k,v in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			if not first then first = k end
			if k == self.LastValidInput then best = k end
			if v.Num then
				self.Inputs[v.Num] = k
			else
				table.insert(self.Inputs, k)
			end
			if v.Desc then
				self.InputsDesc[k] = v.Desc
			end
			if v.Type then
				self.InputsType[k] = v.Type
			end
		end

		--New

		local tab = ""
		for k,v in pairs(self.Inputs) do
			tab = tab..v.."|"..((
				ent and
				ent:IsValid() and
				ent.Inputs and
				ent.Inputs[v] and
				ent.Inputs[v].Src) and "1|" or "0|"
			)
		end

		if self.LastInputs ~= tab then
			umsg.Start("wireinputlist",self:GetOwner())
				umsg.String(ent:GetClass())
				umsg.Short(#self.Inputs)
				for k,v in pairs(self.Inputs) do

					local txt = v
					if self.InputsDesc and self.InputsDesc[v] then
						txt = txt.." ("..self.InputsDesc[v]..")"
					end
					if self.InputsType and self.InputsType[v]
					and self.InputsType[v] ~= "NORMAL" then
						txt = txt.." ["..self.InputsType[v].."]"
					end

					umsg.String(txt)
					if
						ent and
						ent:IsValid() and
						ent.Inputs and
						ent.Inputs[v] and
						ent.Inputs[v].Src
					then
						umsg.Bool(true)
					else
						umsg.Bool(false)
					end
				end
			umsg.End()
			self.LastInputs = tab
		end
	end

	first = self.Inputs[1] or first

	self.CurrentInput = best or first
	if self.CurrentInput and self.CurrentInput ~= "" then self.LastValidInput = self.CurrentInput end

	local txt = ""
	if self.CurrentComponent and self.CurrentComponent:IsValid() and self.CurrentInput
	  and self.CurrentComponent.Inputs and self.CurrentComponent.Inputs[self.CurrentInput]
	  and self.CurrentComponent.Inputs[self.CurrentInput].Src then
		txt = (self.CurrentInput or "")
	else
		txt = self.CurrentInput or ""
	end
	if self.InputsDesc and self.InputsDesc[self.CurrentInput] then
		txt = txt.." ("..self.InputsDesc[self.CurrentInput]..")"
	end
	if self.InputsType and self.InputsType[self.CurrentInput]
	and self.InputsType[self.CurrentInput] ~= "NORMAL" then
		txt = txt.." ["..self.InputsType[self.CurrentInput].."]"
	end
	self:GetWeapon():SetNetworkedString("WireCurrentInput", txt)

	if self.CurrentComponent and self.CurrentComponent:IsValid() then
		self.CurrentComponent:SetNetworkedBeamString("BlinkWire", self.CurrentInput)
	end
end
