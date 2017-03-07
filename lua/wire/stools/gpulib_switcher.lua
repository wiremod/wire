WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "gpulib_switcher", "GPULib Switcher", "gmod_wire_gpulib_controller" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if (CLIENT) then
	language.Add("Tool.wire_gpulib_switcher.name", "GPULib Screen Switcher")
	language.Add("Tool.wire_gpulib_switcher.desc", "Displays one entity's GPULib screen on another entity.")
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Link a GPULib Screen (Console/Digital/Text Screen/GPU/Oscilloscope) to a different prop/entity" },
		{ name = "right_0", stage = 0, text = "Unlink a screen" },
		{ name = "left_1", stage = 1, text = "Link selected GPULib Screen to this prop/entity" },
		{ name = "right_1", stage = 1, text = "Place GPULib controller for the selected screen" },
		{ name = "reload_1", stage = 1, text = "Cancel" },
	}

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_gpulib_switcher.name", Description = "#Tool.wire_gpulib_switcher.desc" })
		WireDermaExts.ModelSelect(panel, "wire_gpulib_switcher_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	end

elseif SERVER then

	function TOOL:LeftClick(trace)
		local ent = trace.Entity

		if ent:IsPlayer() then return false end
		if CLIENT then return true end

		if not ent:IsValid() then return false end

		if self:GetStage() == 0 then
			--if not ent.IsGPU then return false end -- needs check for GPULib-ness
			self.screen = ent

			self:SetStage(1)

			return true
		elseif self:GetStage() == 1 then
			GPULib.switchscreen(self.screen, ent)
			self.screen = nil

			self:SetStage(0)

			return true
		end
	end

	function TOOL:RightClick(trace)
		local ent = trace.Entity

		if ent:IsPlayer() then return false end
		if CLIENT then return true end

		if self:GetStage() == 1 then
			local ply = self:GetOwner()

			local Ang = trace.HitNormal:Angle()
			Ang.pitch = Ang.pitch + 90

			local controller = MakeGPULibController( ply, trace.HitPos, Ang, self:GetModel(), self.screen )
			controller:SetPos(trace.HitPos - trace.HitNormal * controller:OBBMins().z)

			local const = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)

			undo.Create("GPULib controller ("..self.screen:GetClass()..")")
				undo.AddEntity( controller )
				undo.AddEntity( const )
				undo.SetPlayer( ply )
			undo.Finish()

			self.screen = nil
			self:SetStage(0)

			return true
		end
	end

	function TOOL:Reload(trace)
		if self:GetStage() == 0 then
			local ent = trace.Entity

			if ent:IsPlayer() then return false end
			if CLIENT then return true end

			GPULib.switchscreen(ent, ent)

			return true
		else
			self:SetStage(0)
			return true
		end
	end

end -- if SERVER

WireToolSetup.BaseLang()