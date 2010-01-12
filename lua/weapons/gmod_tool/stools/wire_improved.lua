TOOL.Category = "Wire - Tools"
TOOL.Name     = "Wire Improved" -- TODO: rename
TOOL.Tab      = "Wire"

if CLIENT then
	language.Add( "Tool_wire_improved_name", "Improved Wiring Tool" ) -- TODO: rename
	language.Add( "Tool_wire_improved_desc", "Used to connect wirable props." )
	language.Add( "Tool_wire_improved_0", "Primary: Attach to selected input, Secondary: Next input, Reload: Unlink selected input, Wheel: Select input." )
	language.Add( "Tool_wire_improved_1", "Primary: Attach to output, Secondary: Attach but continue, Reload: Cancel." )
	language.Add( "Tool_wire_improved_2", "Primary: Confirm attach to output, Secondary: Next output, Reload: Cancel, Wheel: Select output." )
end

TOOL.ClientConVar = {
	width = 2,
	material = "cable/cable2",
	r = 255,
	g = 255,
	b = 255,
}

local function dummytrace(ent)
	local pos = ent:GetPos()
	return {
		FractionLeftSolid = 0,
		HitNonWorld       = true,
		Fraction          = 0,
		Entity            = ent,
		HitPos            = pos,
		HitNormal         = Vector(0,0,0),
		HitBox            = 0,
		Normal            = Vector(1,0,0),
		Hit               = true,
		HitGroup          = 0,
		MatType           = 0,
		StartPos          = pos,
		PhysicsBone       = 0,
		WorldToLocal      = Vector(0,0,0),
	}
end

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

local function get_tool(ply, tool)
	-- find toolgun
	local gmod_tool = ply:GetWeapon("gmod_tool")
	if not ValidEntity(gmod_tool) then return end

	-- find tool
	local tool = gmod_tool:GetToolObject(tool)

	return tool
end

local function get_active_tool(ply, tool)
	-- find toolgun
	local activeWep = ply:GetActiveWeapon()
	if not ValidEntity(activeWep) then return end

	-- checks...
	if activeWep:GetClass() ~= "gmod_tool" then return end
	if activeWep:GetMode() ~= tool then return end

	-- find tool
	local tool = activeWep:GetToolObject(tool)

	return tool
end

if SERVER then
	function TOOL:RightClick(trace)
		if self:GetStage() == 1 then
			local ent = trace.Entity
			Wire_Link_Node(self:GetOwner():UniqueID(), ent, ent:WorldToLocal(trace.HitPos+trace.HitNormal))
		end

		return false
	end

	function TOOL:Reload(trace)
		if self:GetStage() ~= 0 then
			self:Holster()
		end
		return true
	end

	function TOOL:Holster()
		Wire_Link_Cancel(self:GetOwner():UniqueID())
		self:SetStage(0)
	end

	function TOOL:Receive(mode, entid, portname, x, y, z)
		if mode == "i" then -- select input and target entity
			if self:GetStage() ~= 0 then return end

			local target = Entity(tonumber(entid))
			if not target:IsValid() then return end
			if not gamemode.Call("CanTool", self:GetOwner(), dummytrace(target), "wire_improved") then return end

			local material = self:GetClientInfo("material")
			local width    = self:GetClientNumber("width")
			local color    = Color(self:GetClientNumber("r"), self:GetClientNumber("g"), self:GetClientNumber("b"))

			local lpos = Vector(tonumber(x), tonumber(y), tonumber(z))

			if Wire_Link_Start(self:GetOwner():UniqueID(), target, lpos, portname, material, color, width) then
				self:SetStage(1)
				self.target = target
				self.input = portname
			end

		elseif mode == "s" then -- select source entity
			if self:GetStage() ~= 1 then return end

			local source = Entity(tonumber(entid))
			if not source:IsValid() then return end
			if not gamemode.Call("CanTool", self:GetOwner(), dummytrace(source), "wire_improved") then return end

			local outputs = source.Outputs
			local input_type = self.target.Inputs[self.input].Type
			if not outputs or not next(outputs) then
				-- the entity has no outputs
				if input_type == "WIRELINK" then
					-- for wirelink, fake a "link" output.
					outputs = { link = { Type = "WIRELINK" } }
					-- TODO: check if wirelink makes sense (props etc)

				elseif input_type == "ENTITY" then
					-- for entities, trigger the input with that entity and cancel the link.
					self:SetStage(0)

					Wire_Link_Cancel(self:GetOwner():UniqueID())
					WireLib.TriggerInput(self.target, self.input, source)
					WireLib.AddNotify(self:GetOwner(), "Triggered entity input '"..self.input.."' with '"..tostring(source).."'.", NOTIFY_GENERIC, 7)
					return

				else
					-- for all other types, display an error.
					WireLib.AddNotify(self:GetOwner(), "The selected entity has no outputs. Please select a different entity.", NOTIFY_GENERIC, 7)
					return
				end
			end

			self.source = source
			self.lpos = Vector(tonumber(x), tonumber(y), tonumber(z))

			self:SetStage(2)

			-- only one port? skip stage 2 and finish the link right away.
			local firstportname,firstport = next(outputs)
			if not next(outputs, firstportname) and (input_type ~= "WIRELINK" or firstport.Type == "WIRELINK") then return self:Receive("o", "0", firstportname) end

		elseif mode == "o" then -- select output
			if self:GetStage() ~= 2 then return end

			if not gamemode.Call("CanTool", self:GetOwner(), dummytrace(self.source), "wire_improved") then return end -- actually useless

			self.output = portname

			Wire_Link_End(self:GetOwner():UniqueID(), self.source, self.lpos, self.output, self:GetOwner())

			self:SetStage(0)

		elseif mode == "c" then -- clear link
			if self:GetStage() ~= 0 then return end

			local target = Entity(tonumber(entid))
			if not target:IsValid() then return end
			if not gamemode.Call("CanTool", self:GetOwner(), dummytrace(target), "wire_improved") then return end

			Wire_Link_Clear(target, portname)
		end
	end

	concommand.Add("wire_improved", function(ply, cmd, args)
		local tool = get_tool(ply, "wire_improved")
		if not tool then return end

		local hook = tool.Receive
		if not hook then return end

		hook(tool, unpack(args))
	end)

elseif CLIENT then

	hook.Add("GUIMousePressed", "wire_improved", function(mousecode, aimvec)
		local self = get_active_tool(LocalPlayer(), "wire_improved")
		if not self then return end

		if self:Click(mousecode, aimvec, false) then return true end
	end)
	hook.Add("GUIMouseDoublePressed", "wire_improved", function(mousecode, aimvec)
		local self = get_active_tool(LocalPlayer(), "wire_improved")
		if not self then return end

		if self:Click(mousecode, aimvec, true) then return true end
	end)

	function TOOL:Click(mousecode, aimvec, doubleclick)
		if mousecode ~= MOUSE_LEFT then return end
		if not self.menu then return end

		if self.mousenum then
			if self.input and self.ports[self.mousenum][2] ~= self.input[2] then return end

			self.port = self.mousenum

			if doubleclick then
				local trace = self:GetOwner():GetEyeTraceNoCursor()
				if self:LeftClickB(trace) then
					self:GetWeapon():DoShootEffect(trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone)
				end
			else
				self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")
			end
		end

	end

	local function DrawPortBox(ports, selindex, align, seltype)
		align = align or 1

		if not ports then return end
		--if #ports == 0 then return end

		surface.SetFont("Trebuchet24")
		local texth = draw.GetFontHeight("Trebuchet24")
		local boxh, boxw = #ports*texth,0

		local haswl = seltype ~= "WIRELINK"
		for num,port in ipairs(ports) do
			local name,tp,desc,connected = unpack(port)

			local text = (tp == "NORMAL") and name or string.format("%s [%s]", name, tp)
			port.text = text

			local textw = surface.GetTextSize(text)
			if textw > boxw then boxw = textw end

			-- If this is a wirelink output, signal that we don't need the "Create Wirelink" option.
			if tp == "WIRELINK" then haswl = true end
		end

		if not haswl then
			-- we seem to need a "Create Wirelink" option, so add one.
			local text = "Create Wirelink"
			ports.wl = { "link", "WIRELINK", "", text = text }

			local textw = surface.GetTextSize(text)
			if textw > boxw then boxw = textw end
			boxh = boxh+texth
		end

		local boxx, boxy = ScrW()/2-boxw-32, ScrH()/2-boxh/2
		boxx = boxx + align/2*(boxw+64)
		draw.RoundedBox(8,
			boxx-8, boxy-8,
			boxw+16, boxh+16,
			Color(50,50,75,192)
		)

		local mousenum

		local cx, cy = gui.MousePos()
		local mouseindex = selindex and cx >= boxx and cx < boxx+boxw and math.floor((cy-boxy)/texth+1)
		for num,port in pairs(ports) do
			local ind = num == "wl" and #ports+1 or num
			local name,tp,desc,connected = unpack(port)
			local texty = boxy+(ind-1)*texth
			if num == selindex then
				draw.RoundedBox(4,
					boxx-4, texty-1,
					boxw+8, texth+2,
					Color(0,150,0,192)
				)
			end
			if mouseindex == ind then
				draw.RoundedBox(4,
					boxx-4, texty-1,
					boxw+8, texth+2,
					Color(255,255,255,16)
				)
				mousenum = num
			end

			surface.SetTextPos(boxx,texty)
			if connected then
				surface.SetTextColor(Color(255,0,0,255))
			elseif seltype and seltype ~= tp then
				surface.SetTextColor(Color(255,255,255,32))
			else
				surface.SetTextColor(Color(255,255,255,255))
			end
			surface.DrawText(port.text)
			port.text = nil
		end

		return mousenum
	end

	function TOOL:NewStage(stage, laststage)
		if stage == 0 then
			self.target = nil
			self.input = nil
			self.source = nil
			self.output = nil

		elseif stage == 1 then
			self.input = self.selinput
			self.selinput = nil
		end
	end

	function TOOL:Holster()
		self.lastent = nil
	end

	function TOOL:DrawHUD()
		local stage = self:GetStage()
		local newstage = self.laststage ~= stage
		if newstage then
			self:NewStage(stage, self.laststage)
			self.laststage = stage

			-- trigger a "newent" event
			self.lastent = nil
		end

		local ent = LocalPlayer():GetEyeTraceNoCursor().Entity
		local newent = ent:IsValid() and ent ~= self.lastent
		if newent and (stage ~= 2 or newstage) then
			self.lastent = ent

			local inputs, outputs = WireLib.GetPorts(ent)

			if stage == 0 then
				self.port = 1
				self.ports = inputs

			elseif stage == 1 then
				if outputs then
					self.ports = outputs
				elseif self.input[2] == "WIRELINK" then
					self.ports = {}
					self.port = "wl"
				end

			elseif stage == 2 then
				self.ports = outputs
				if outputs then
					if self.ports.wl then
						self.port = "wl"
					else
						-- we have outputs, so pick a port of a matching type
						local inputname, inputtype = unpack(self.input)
						inputname = inputname:gsub(" ", "")
						self.port = nil
						for num,name,tp in ipairs_map(outputs,unpack) do
							if tp == inputtype then
								-- found a port of a matching type
								if name:gsub(" ", "") == inputname then
									-- the name matches too? select and break
									self.port = num
									break
								elseif not self.port then
									-- no port selected? select this one
									self.port = num
								end
							end
						end

						-- no matching port? default to 1
						if not self.port then self.port = 1 end
					end -- if self.ports.wl
				elseif self.input[2] == "WIRELINK" then
					self.ports = {}
					self.port = "wl"
				end -- if outputs
			end -- if stage
		end

		if self.input then DrawPortBox({ self.input }, nil, 0) end

		self.menu = self.ports and (ent:IsValid() or stage == 2)
		if self.menu then
			if stage == 0 then
				self.mousenum = DrawPortBox(self.ports, self.port, 0)
			elseif stage == 1 then
				self.mousenum = nil
				local seltype = self.input[2]
				if #self.ports == 1 and self.ports[1][2] == seltype then
					DrawPortBox(self.ports, 1, 2, seltype)
				elseif #self.ports == 0 and self.ports.wl then
					DrawPortBox(self.ports, "wl", 2, seltype)
				else
					DrawPortBox(self.ports, nil, 2, seltype)
				end
			elseif stage == 2 then
				self.mousenum = DrawPortBox(self.ports, self.port, 2, self.input[2])
			end
		end
	end

	function TOOL:LeftClickB(trace)
		if self:GetStage() == 0 then
			if not self.ports then return end
			if not self.port then return end

			self.selinput = self.ports[self.port]
			if not self.selinput then return end

			local target = trace.Entity
			if not ValidEntity(target) then return end

			local lpos = target:WorldToLocal(trace.HitPos)
			RunConsoleCommand("wire_improved", "i", target:EntIndex(), self.selinput[1], lpos.x, lpos.y, lpos.z)

			return true

		elseif self:GetStage() == 1 then
			local source = trace.Entity
			if not ValidEntity(source) then return end

			local lpos = source:WorldToLocal(trace.HitPos)
			RunConsoleCommand("wire_improved", "s", source:EntIndex(), 0, lpos.x, lpos.y, lpos.z)

			return true

		elseif self:GetStage() == 2 then
			if not self.ports then return end
			if not self.port then return end

			self.output = self.ports[self.port]
			if not self.output then return end

			RunConsoleCommand("wire_improved", "o", 0, self.output[1])

			return true
		end
	end

	function TOOL:ReloadB(trace)
		if self:GetStage() == 0 then
			if not self.ports then return end
			RunConsoleCommand("wire_improved", "c", trace.Entity:EntIndex(), self.ports[self.port][1])
			return true
		end
	end

	function TOOL:ScrollUp(trace)
		if not self.menu then return end

		local stage = self:GetStage()
		if stage == 1 then return end

		if not self.ports.wl then
			local seltype = stage ~= 0 and self.input[2]

			local oldport = math.Clamp(self.port, 1, #self.ports)
			repeat
				self.port = self.port-1
				if self.port < 1 then self.port = #self.ports end
			until stage == 0 or self.ports[self.port][2] == seltype or self.port == oldport

			if stage ~= 0 and self.ports[self.port][2] ~= seltype then
				self.port = self.port-1
				if self.port < 1 then self.port = #self.ports end
			end
		end

		self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

		return true
	end

	function TOOL:ScrollDown(trace)
		if not self.menu then return end

		local stage = self:GetStage()
		if stage == 1 then return end

		if not self.ports.wl then
			local seltype = stage ~= 0 and self.input[2]

			local oldport = math.Clamp(self.port, 1, #self.ports)
			repeat
				self.port = self.port+1
				if self.port > #self.ports then self.port = 1 end
			until stage == 0 or self.ports[self.port][2] == seltype or self.port == oldport

			if stage ~= 0 and self.ports[self.port][2] ~= seltype then
				self.port = self.port+1
				if self.port > #self.ports then self.port = 1 end
			end
		end

		self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

		return true
	end
	TOOL.RightClickB = TOOL.ScrollDown

	local bind_mappings = {
		["+attack" ] = { "LeftClickB", true },
		["+attack2"] = { "RightClickB" },
		["+reload" ] = { "ReloadB", true },
		["invprev" ] = { "ScrollUp" },
		["invnext" ] = { "ScrollDown" },
	}

	hook.Add("PlayerBindPress", "wire_improved", function(ply, bind, pressed)
		if not pressed then return end

		local mapping = bind_mappings[bind]
		if not mapping then return end

		local hookname, doeffect = unpack(mapping)

		local self = get_active_tool(ply, "wire_improved")
		if not self then return end

		local hook = self[hookname]
		if not hook then return end

		local trace = ply:GetEyeTraceNoCursor()
		local ret = hook(self, trace)
		if ret then
			if doeffect then
				self:GetWeapon():DoShootEffect(trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone)
			end
			return true
		end
	end)

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool_wire_name", Description = "#Tool_wire_desc" })

		panel:AddControl("ComboBox", {
			Label = "#Presets",
			MenuButton = "1",
			Folder = "wire_improved",

			Options = {
				Default = {
					wire_improved_material = "cable/rope",
					wire_improved_width = "3",
				}
			},

			CVars = {
				[0] = "wire_improved_width",
				[1] = "wire_improved_material",
			}
		})

		panel:AddControl("Slider", {
			Label = "#WireTool_width",
			Type = "Float",
			Min = "0",
			Max = "5",
			Command = "wire_improved_width"
		})

		panel:AddControl("MaterialGallery", {
			Label = "#WireTool_material",
			Height = "64",
			Width = "24",
			Rows = "1",
			Stretch = "1",

			Options = {
				["Wire"] = { Material = "cable/rope_icon", wire_improved_material = "cable/rope" },
				["Cable 2"] = { Material = "cable/cable_icon", wire_improved_material = "cable/cable2" },
				["XBeam"] = { Material = "cable/xbeam", wire_improved_material = "cable/xbeam" },
				["Red Laser"] = { Material = "cable/redlaser", wire_improved_material = "cable/redlaser" },
				["Blue Electric"] = { Material = "cable/blue_elec", wire_improved_material = "cable/blue_elec" },
				["Physics Beam"] = { Material = "cable/physbeam", wire_improved_material = "cable/physbeam" },
				["Hydra"] = { Material = "cable/hydra", wire_improved_material = "cable/hydra" },

			--new wire materials by Acegikmo
				["Arrowire"] = { Material = "arrowire/arrowire", wire_improved_material = "arrowire/arrowire" },
				["Arrowire2"] = { Material = "arrowire/arrowire2", wire_improved_material = "arrowire/arrowire2" },
			},

			CVars = {
				[0] = "wire_improved_material"
			}
		})

		panel:AddControl("Color", {
			Label = "#WireTool_colour",
			Red = "wire_improved_r",
			Green = "wire_improved_g",
			Blue = "wire_improved_b",
			ShowAlpha = "0",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})
	end

end

--[[ TODO:
	fixes:
	- Only play effects when appropriate
	- replace wire_adv
	- desc

	new features:
]]
