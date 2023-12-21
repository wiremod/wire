WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "ledtape", "LED Tape", "gmod_wire_ledtape", nil, "LED Tape Controllers" )

--[[
	I would have used the original wirepath system, but it looks like it was never designed for a tool like this.  
	So we're stuck with whatever horribleness I come up with.  Sorry.
	- Fast
]]--

TOOL.ClientConVar = {
	material = "cable/white",
	width = "1",
	model = "models/beer/wiremod/hydraulic.mdl",
	modelsize = ""
}

TOOL.ToolPath = {}
TOOL.CurWidth = 1
TOOL.Scale = 1

function TOOL:GetConVars()
	return self:GetClientInfo("material") or "cable/rope",
		   self:GetClientNumber("width", 3)
end

local function isLookingAtController(trace)
	return trace.Entity and trace.Entity:GetClass() == "gmod_wire_ledtape"
end

if CLIENT then

	language.Add( "Tool.wire_ledtape.name", "LED Tape Tool (Wire)" )
	language.Add( "Tool.wire_ledtape.desc", "Makes a group of ropes with controllable color" )
	language.Add( "Tool.wire_ledtape.width", "Width:" )
	language.Add( "Tool.wire_ledtape.material", "Material:" )
	TOOL.Information = {
		{ name = "right_0", stage = 0, text = "Start LED Tape" },
		{ name = "left_0", stage = 0, text = "Update material of existing controller" },
		{ name = "right_1", stage = 1, text = "Place another point" },
		{ name = "left_2", stage = 2, text = "Finish tape and place controller" },
		{ name = "right_2", stage = 2, text = "Place more points" },
		{ name = "left_3", stage = 3, text = "Finish tape and place controller" },
	}
	WireToolSetup.setToolMenuIcon( "icon16/chart_line.png" )

	local WHITE = Color(255,255,255) -- creating these every frame is bad
	local YELLOW = Color(255,255,0)  -- it wastes memory and strains the garbage collector

	function TOOL:Holster()
		self.ToolPath = {}
		self:ReleaseGhostEntity()
	end

	function TOOL:Preview()

		if #self.ToolPath < 1 then hook.Remove("PostDrawOpaqueRenderables","LEDTape_Preview") return end -- something happened, bail

		render.SetMaterial(self.CurMater)

		local pt2 = Wire_LEDTape.DrawFullbright(self.CurWidth, self.ScrollMul / 3, WHITE, self.CurMater, self.ToolPath)

		if pt2 and (#self.ToolPath + 1 < Wire_LEDTape.MaxPoints) then
			local eyetrace = LocalPlayer():GetEyeTrace()
			local pt3 = eyetrace.HitPos + eyetrace.HitNormal * self.CurWidth * 0.5
			render.DrawLine( pt2, pt3, YELLOW )
		end

	end

end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(8)

if SERVER then

	function TOOL:MakeEnt(ply, model, Ang, trace)
		local material, width = self:GetConVars()
		return MakeWireLEDTapeController(ply, trace.HitPos, Ang, model, self.ToolPath, width, material)
	end

	function TOOL:Holster()
		self:SetStage(0)
		self.ToolPath = {}
	end

end

function TOOL:RightClick( trace )

	if not trace.Hit or ( trace.Entity:IsValid() and trace.Entity:IsPlayer() ) or trace.Entity:IsWorld() then return end
	if ( SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local mater, width = self:GetConVars()

	if self:GetStage() == 3 then return false end

	if self:GetStage() == 0 then
		self.ToolPath = {}

		self:SetStage(1)

		self.CurMater = Material and Material(mater) or mater -- material on client, string on server
		self.CurWidth = width

		if CLIENT then

			hook.Add("PostDrawOpaqueRenderables","LEDTape_Preview", function() self:Preview() end)

			local metadata = Wire_LEDTape.materialData[mater]
			self.ScrollMul = metadata and metadata.scale or 1

		end
	end

	local nextPos = trace.Entity:WorldToLocal(trace.HitPos + trace.HitNormal * self.CurWidth * 0.5)

	if #self.ToolPath > 0 then
		local prevPoint = self.ToolPath[ #self.ToolPath ]
		if prevPoint[1] == trace.Entity and prevPoint[2]:IsEqualTol( nextPos, 0.1 ) then -- disallow placing the same point
			return false
		end
	end

	table.insert(self.ToolPath, {trace.Entity, nextPos})

	if #self.ToolPath == 1 then
		self:SetStage(2)
	elseif #self.ToolPath == Wire_LEDTape.MaxPoints then
		self:SetStage(3)
	end

	return true

end

function TOOL:LeftClick( trace )

	if self:GetStage() == 0 and isLookingAtController(trace) then
		if CLIENT then return true end -- only server
		local controller = trace.Entity
		controller.BaseMaterial = self:GetConVars()
		for _, ply in ipairs(player.GetHumans()) do
			table.insert(controller.DownloadQueue, {ply = ply, full = false})
		end
		return true
	end

	if self:GetStage() < 1 or isLookingAtController(trace) then return false end

	local ply = self:GetOwner()
	self:SetStage(0)

	if SERVER then
		local controller = self:LeftClick_Make(trace, ply)
		if isbool(controller) then return controller end
		self:LeftClick_PostMake(controller, ply, trace)
	end

	self.ToolPath = {}

	return true

end

-- I just wanted to match the vanilla look, not write a horrible hacky workaround!
local function emptyRopeMaterialPanel(panel)
	table.Empty(panel.Controls)
	for k, v in ipairs( panel.List:GetItems() ) do v:Remove() end
end

function TOOL.BuildCPanel(panel)

	WireToolHelpers.MakeModelSizer(panel, "wire_ledtape_modelsize")
	WireDermaExts.ModelSelect(panel, "wire_ledtape_model", list.Get( "Wire_Hydraulic_Models" ), 1, true)

	panel:NumSlider("#Tool.wire_ledtape.width","wire_ledtape_width",0,4,2)
	local ropeMaterials = panel:AddControl( "RopeMaterial", { Label = "#Tool.wire_ledtape.material", convar = "wire_ledtape_material" } )

	emptyRopeMaterialPanel(ropeMaterials) -- remove garry's materials

	for texpath, data in pairs( Wire_LEDTape.materialData ) do -- add mine
		ropeMaterials:AddMaterial(data.name, texpath)
	end

end