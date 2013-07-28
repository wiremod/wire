TOOL.Category = "Wire - Tools"
TOOL.Name			= "Wire Advanced"
TOOL.Tab      = "Wire"

if CLIENT then
	language.Add( "Tool.wire_adv.name", "Advanced Wiring Tool" )
	language.Add( "Tool.wire_adv.desc", "Used to connect wirable props." )
	language.Add( "Tool.wire_adv.0", "Primary: Attach to selected input, Secondary: Next input, Reload: Unlink selected input, Wheel: Select input." )
	language.Add( "Tool.wire_adv.1", "Primary: Attach to output, Secondary: Attach but continue, Reload: Cancel." )
	language.Add( "Tool.wire_adv.2", "Primary: Confirm attach to output, Secondary: Next output, Reload: Cancel, Wheel: Select output." )
end

TOOL.ClientConVar = {
	width = 2,
	material = "cable/cable2",
	r = 255,
	g = 255,
	b = 255,
}

util.PrecacheSound("weapons/pistol/pistol_empty.wav")

local function get_tool(ply, tool)
	-- find toolgun
	local gmod_tool = ply:GetWeapon("gmod_tool")
	if not IsValid(gmod_tool) then return end

	return gmod_tool:GetToolObject(tool)
end

local function get_active_tool(ply, tool)
	-- find toolgun
	local activeWep = ply:GetActiveWeapon()
	if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

	return activeWep:GetToolObject(tool)
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

	-- SERVER --
	function TOOL:Receive(mode, entid, portname, x, y, z)
		if mode == "i" then -- select input and target entity
			if self:GetStage() ~= 0 then return end

			local target = Entity(tonumber(entid))
			if not target:IsValid() then return end
			if not gamemode.Call("CanTool", self:GetOwner(), WireLib.dummytrace(target), "wire_adv") then return end

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
			if not gamemode.Call("CanTool", self:GetOwner(), WireLib.dummytrace(source), "wire_adv") then return end
			if not WireLib.HasPorts(self.target) then return end
			if not self.target.Inputs then return end

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

			if not gamemode.Call("CanTool", self:GetOwner(), WireLib.dummytrace(self.source), "wire_adv") then return end -- actually useless

			self.output = portname

			Wire_Link_End(self:GetOwner():UniqueID(), self.source, self.lpos, self.output, self:GetOwner())

			self:SetStage(0)

		elseif mode == "c" then -- clear link
			if self:GetStage() ~= 0 then return end

			local target = Entity(tonumber(entid))
			if not target:IsValid() then return end
			if not gamemode.Call("CanTool", self:GetOwner(), WireLib.dummytrace(target), "wire_adv") then return end

			Wire_Link_Clear(target, portname)
		end
	end

	-- SERVER --
	concommand.Add("wire_adv", function(ply, cmd, args)
		local tool = get_tool(ply, "wire_adv")
		if not tool then return end

		local hook = tool.Receive
		if not hook then return end

		hook(tool, unpack(args))
	end)

elseif CLIENT then

	function TOOL:Holster()
		if IsValid(self.lastent) then self.lastent:SetNetworkedBeamString("BlinkWire", "") end
		self.lastent = nil
		self.lastinput = {}
		self.lastoutput = {}
	end

	hook.Add("GUIMousePressed", "wire_adv", function(mousecode, aimvec)
		local self = get_active_tool(LocalPlayer(), "wire_adv")
		if not self then return end

		if self:Click(mousecode, aimvec, false) then return true end
	end)

	hook.Add("GUIMouseDoublePressed", "wire_adv", function(mousecode, aimvec)
		local self = get_active_tool(LocalPlayer(), "wire_adv")
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
	
	local fontData = {font = "Trebuchet24"} -- 24 and 18 are stock
	for _,size in pairs({22,20,16,14}) do
		fontData.size = size
		surface.CreateFont("Trebuchet"..size, fontData)
	end

	local function fitfont(...)
		local fontnames = { "Trebuchet24", "Trebuchet22", "Trebuchet20", "Trebuchet18", "Trebuchet16", "Trebuchet14" }
		local fontheights = {}

		for i,fontname in ipairs(fontnames) do
			fontheights[i] = draw.GetFontHeight(fontname)
		end

		function fitfont(nlines, h)
			local maxfontheight = h/nlines
			for i,fontheight in ipairs(fontheights) do
				if fontheight <= maxfontheight then
					return fontnames[i]
				end
			end
			return fontnames[#fontnames]
		end
		return fitfont(...)
	end

	-- CLIENT --
	local function DrawPortBox(ports, selindex, align, seltype)
		align = align or 1

		if not ports then return end

		surface.SetFont(fitfont(#ports, ScrH()-32))
		local _,texth = surface.GetTextSize(" ")
		local boxh, boxw = #ports*texth,0

		local createwl = seltype == "WIRELINK"
		for num,port in ipairs(ports) do
			local name,tp,desc,connected = unpack(port)

			local text = name
			if desc ~= "" then text = text.." ("..desc..")" end
			if tp ~= "NORMAL" then text = text.." ["..tp.."]" end
			port.text = text

			local textw = surface.GetTextSize(text)
			if textw > boxw then boxw = textw end

			-- If this is a wirelink output, signal that we don't need the "Create Wirelink" option.
			if tp == "WIRELINK" then createwl = false end
		end

		if createwl then
			-- we seem to need a "Create Wirelink" option, so add one.
			local text = "Create Wirelink"
			ports.wl = { "link", "WIRELINK", "", text = text }

			local textw = surface.GetTextSize(text)
			if textw > boxw then boxw = textw end
			boxh = boxh+texth
		else
			ports.wl = nil
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
			if (port.text) then surface.DrawText(port.text) end
			port.text = nil
		end

		return mousenum
	end

	-- CLIENT --
	function TOOL:NewStage(stage, laststage)
		if laststage == nil then
			self:Holster() -- initialize lastinput/output tables
		elseif laststage == 0 then
			if self.target and self.selinput then self.lastinput[self.target] = self.selinput end
		elseif laststage == 2 then
			if self.source and self.output then self.lastoutput[self.source] = self.output end
		end

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

	local function lookup(tbl, value)
		if not value then return end -- this is an optimization

		for k,v in pairs(tbl) do
			if value == v then return k end
		end
	end

	-- CLIENT --
	function TOOL:DrawHUD()
		local stage = self:GetStage()
		local newstage = self.laststage ~= stage
		local ent = LocalPlayer():GetEyeTraceNoCursor().Entity
		local newent = ent:IsValid() and ent ~= self.lastent
		if newstage then
			self:NewStage(stage, self.laststage)
			self.laststage = stage

			-- trigger a "newent" event
			newent = true
		end

		if newent and (stage ~= 2 or newstage) then
			if self.lastent then self.lastent:SetNetworkedBeamString("BlinkWire", "") end
			self.lastent = ent

			local inputs, outputs = WireLib.GetPorts(ent)
			local iswire = inputs or outputs or ent.Base == "base_wire_entity"
			self.iswire = iswire

			if stage == 0 then
				self.ports = inputs
				self.port = self.ports and lookup(self.ports,self.lastinput[ent]) or 1

			elseif stage == 1 then
				if outputs then
					self.ports = outputs
				elseif iswire and self.input[2] == "WIRELINK" then
					self.ports = {}
					self.port = "wl"
				else
					self.ports = nil
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

						local lastoutput = self.lastoutput[ent]
						self.port = lastoutput and lastoutput[2] == inputtype and lookup(self.ports,lastoutput)

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
						if not self.port then self.port = lookup(self.ports,lastoutput) or 1 end
					end -- if self.ports.wl
				elseif iswire and self.input[2] == "WIRELINK" then
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

	-- CLIENT --
	function TOOL:LeftClickB(trace)
		local stage = self:GetStage()
		if stage == 0 then
			if not self.ports then return end
			if not self.port then return end

			self.selinput = self.ports[self.port]
			if not self.selinput then return end

			self.target = trace.Entity
			if not IsValid(self.target) then return end

			local lpos = self.target:WorldToLocal(trace.HitPos)
			RunConsoleCommand("wire_adv", "i", self.target:EntIndex(), self.selinput[1], lpos.x, lpos.y, lpos.z)

			return true

		elseif stage == 1 then
			if not self.ports and self.iswire then return end
			self.source = trace.Entity
			if not IsValid(self.source) then return end

			local lpos = self.source:WorldToLocal(trace.HitPos)
			RunConsoleCommand("wire_adv", "s", self.source:EntIndex(), 0, lpos.x, lpos.y, lpos.z)

			return true

		elseif stage == 2 then
			if not self.ports then return end
			if not self.port then return end

			self.output = self.ports[self.port]
			if not self.output then return end

			RunConsoleCommand("wire_adv", "o", 0, self.output[1])

			return true
		end
	end

	function TOOL:ReloadB(trace)
		if self:GetStage() == 0 then
			if not self.ports then return end

			local port = self.ports[self.port]
			if not port then return end

			RunConsoleCommand("wire_adv", "c", trace.Entity:EntIndex(), port[1])
			return true
		end
	end

	-- CLIENT --
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
			self.lastent:SetNetworkedBeamString("BlinkWire", self.ports[self.port][1])
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
			self.lastent:SetNetworkedBeamString("BlinkWire", self.ports[self.port][1])
		end

		self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")

		return true
	end
	TOOL.RightClickB = TOOL.ScrollDown

	-- CLIENT --
	local bind_mappings = {
		["+attack" ] = { "LeftClickB", true },
		["+attack2"] = { "RightClickB" },
		["+reload" ] = { "ReloadB", true },
		["invprev" ] = { "ScrollUp" },
		["invnext" ] = { "ScrollDown" },
	}
	local weapon_selection_close_time = 0

	local function open_menu()
		weapon_selection_close_time = CurTime()+6
	end

	local function close_menu()
		weapon_selection_close_time = 0
	end

	local bind_post = {
		invnext = open_menu,
		invprev = open_menu,
		["+attack" ] = close_menu,
		["+attack2"] = close_menu,
	}

	hook.Add("PlayerBindPress", "wire_adv", function(ply, bind, pressed)
		if not pressed then return end

		if bind:match("^slot%d+$") then return open_menu() end

		if CurTime() > weapon_selection_close_time then
			local mapping = bind_mappings[bind]
			if not mapping then return end

			local hookname, doeffect = unpack(mapping)

			local self = get_active_tool(ply, "wire_adv")
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
		end

		local wsel = bind_post[bind]
		if wsel then wsel() end
	end)

	-- CLIENT --
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire.name", Description = "#Tool.wire.desc" })
		WireToolHelpers.MakePresetControl(panel, "wire_adv")

		panel:NumSlider("#WireTool_width", "wire_adv_width", 0, 5, 2)
		local matselect = panel:AddControl( "RopeMaterial", { Label = "#WireTool_material", convar = "wire_adv_material" } )
		matselect:AddMaterial("Arrowire", "arrowire/arrowire")
		matselect:AddMaterial("Arrowire2", "arrowire/arrowire2")

		panel:AddControl("Color", {
			Label = "#WireTool_colour",
			Red = "wire_adv_r",
			Green = "wire_adv_g",
			Blue = "wire_adv_b"
		})
	end

end

--[[ TODO:
	fixes:
	- Only play effects when appropriate (already better than old wire_adv there)
	- check if wirelink makes sense (props etc) on the server-side

	new features:
]]
