AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire LED Tape Controller"
ENT.WireDebugName 	= "LED Tape"

function ENT:SharedInit()
	self.Color = Color(255,255,255)
	self.Path  = {}
end

Wire_LEDTape = Wire_LEDTape or {}

Wire_LEDTape.MaxPoints = 256
Wire_LEDTape.NumBits   = math.ceil( math.log(Wire_LEDTape.MaxPoints, 2) )

if CLIENT then

	-- TODO: move this into modelplug after the cleanup PR gets accepted

	--[[
		name	= tooltip to display in the spawnmenu ........................ (required)
		sprite	= path to 3x width sprite material ........................... (optional)
		scale	= scaled texture height divided by original texture height ... (required with sprite)
		backlit = draw fullbright base texture even when using a sprite? ..... (optional)
		connect = connect the beams in the sprite texture? ................... (optional)
	]]--

	Wire_LEDTape.materialData = {
		["fasteroid/ledtape01"] = {
			name   = "5050 Sparse",
			sprite = "fasteroid/ledtape01_sprite",
			scale  = 512 / 904
		},
		["fasteroid/ledtape02"] = {
			name   = "5050 Dense",
			sprite = "fasteroid/ledtape02_sprite",
			scale  = 512 / 434
		},
		["cable/white"] = {
			name = "White Cable"
		},
		["arrowire/arrowire2"] = {
			name = "Glowing Arrows",
		},
		["fasteroid/elwire"] = {
			name   = "Electroluminescent Wire",
			sprite = "fasteroid/elwire_sprite",
			scale  = 256 / 2048,
			backlit = true
		},
	}

	local DEFAULT_SCALE = 0.5

	local LIGHT_UPDATE_INTERVAL = CreateClientConVar( "wire_ledtape_lightinterval", "0.5", true, false, "How often environmental lighting on LED tape is calculated", 0 )

	local LIGHT_DIRECTIONS = {
		Vector(1,0,0),
		Vector(-1,0,0),
		Vector(0,1,0),
		Vector(0,-1,0),
		Vector(0,0,1),
		Vector(0,0,-1)
	}

	local function getLitNodeColor(node)
		if not node.lighting or node.nextlight < CurTime() then
			local lightsum = Vector()
			local pos = node[1]:LocalToWorld( node[2] )
			for _, dir in ipairs(LIGHT_DIRECTIONS) do
				lightsum:Add( render.ComputeLighting(pos, dir) )
			end
			lightsum:Mul( 1 / #LIGHT_DIRECTIONS )
			node.lighting = lightsum:ToColor()
			node.nextlight = CurTime() + LIGHT_UPDATE_INTERVAL:GetFloat()
		end
		return node.lighting
	end


	-- This system prevents calling LocalToWorld hundreds of times every frame, as it strains the garbage collector.
	-- This is a necessary evil to prevent stuttering.
	local LocalToWorld_NoGarbage_Ents = {}

	local function LocalToWorld_NoGarbage(ent, pos)
		ent.LEDTapeVecs = ent.LEDTapeVecs or {}
		local LEDTapeVecs = ent.LEDTapeVecs

		if ent.LEDTapeLastPos == ent:GetPos() and ent.LEDTapeLastAng == ent:GetAngles() and LEDTapeVecs[pos] then
			return LEDTapeVecs[pos]
		end

		LEDTapeVecs[pos] = ent:LocalToWorld(pos)
		LocalToWorld_NoGarbage_Ents[ent] = true -- update positions at the end

		return LEDTapeVecs[pos]
	end

	local function LocalToWorld_NoGarbage_End()
		for ent, _ in pairs(LocalToWorld_NoGarbage_Ents) do
			if not IsValid(ent) then continue end
			ent.LEDTapeLastPos = ent:GetPos()
			ent.LEDTapeLastAng = ent:GetAngles()
		end
		LocalToWorld_NoGarbage_Ents = {}
	end

	hook.Add("PostDrawOpaqueRenderables","LEDTapeCleanup",LocalToWorld_NoGarbage_End)

	local function DrawBeams(width, scrollmul, mater, path, getColor, extravertex)

		if not IsValid(path[1][1]) then return end

		local scroll = 0
		local beam   = render.AddBeam

		local beam2     = extravertex and beam or function() end -- branchless programming ftw
		local vertexnum = extravertex and 3 or 2

		scrollmul = scrollmul / width -- scale this

		render.SetMaterial(mater)
		render.StartBeam(#path * vertexnum)

			local node1 = path[1]

			local pt1 = LocalToWorld_NoGarbage(node1[1], node1[2])

			beam(pt1, width, scroll, getColor(node1))

			for i = 2, #path do
				local node2 = path[i]
				local nodeEnt = node2[1]
				if not IsValid(nodeEnt) then continue end
				local nodeOffset = node2[2]

				local pt2 = LocalToWorld_NoGarbage(nodeEnt, nodeOffset)
				local distance = pt2:Distance(pt1) * scrollmul * 0.5

				beam( pt1, width, scroll, getColor(node1))
				scroll = scroll + distance
				beam( pt2, width, scroll, getColor(node2))
				beam2( pt2, width, scroll, getColor(node2)) -- add another point if extravertex is set, prevents some sprites from looking yucky

				pt1 = pt2
				node1 = node2
			end

			beam(pt1, width, scroll, getColor(node1))

		render.EndBeam()
		return pt1
	end

	function Wire_LEDTape.DrawShaded(width, scrollmul, mater, path)
		return DrawBeams(width, scrollmul, mater, path, getLitNodeColor)
	end

	function Wire_LEDTape.DrawFullbright(width, scrollmul, color, mater, path, extravert)
		return DrawBeams(width, scrollmul, mater, path, function(node) return color end, extravert)
	end

	function ENT:Initialize()

		self:SharedInit()
		self.ScrollMul = DEFAULT_SCALE

		net.Start("LEDTapeData")
			net.WriteEntity(self)
			net.WriteBool(true) -- request full update
		net.SendToServer()

		if CLIENT then
			local DrawShaded = Wire_LEDTape.DrawShaded
			local DrawFullbright = Wire_LEDTape.DrawFullbright
			hook.Add("PostDrawOpaqueRenderables", self, function()

				if #self.Path < 2 then return end

				if self.SpriteMaterial then

					if self.Backlit then
						DrawFullbright(self.Width, self.ScrollMul / 3, self.Color, self.BaseMaterial, self.Path, false)
					else
						DrawShaded(self.Width, self.ScrollMul / 3, self.BaseMaterial, self.Path)
					end

					DrawFullbright(self.Width * 3, self.ScrollMul, self.Color, self.SpriteMaterial, self.Path, not self.Connect)

				else
					DrawFullbright(self.Width, self.ScrollMul, self.Color, self.BaseMaterial, self.Path)
				end

			end)
		end

		self:SetOverlayText("LED Tape Controller")

	end

	function ENT:Think()
		self.Color.r = self:GetNW2Int("LedTape_R")
		self.Color.g = self:GetNW2Int("LedTape_G")
		self.Color.b = self:GetNW2Int("LedTape_B")
	end

	net.Receive("LEDTapeData", function()

		local controller = net.ReadEntity()
		if not IsValid(controller) then return end

		local full = net.ReadBool()

		controller.Width = net.ReadFloat()
		local mater = net.ReadString()

		controller.BaseMaterial = Material( mater )

		local metadata = Wire_LEDTape.materialData[mater]

		if metadata then
			controller.SpriteMaterial = metadata.sprite and Material( metadata.sprite )
			controller.ScrollMul = metadata.scale or DEFAULT_SCALE
			controller.Connect   = metadata.connect or false
			controller.Backlit   = metadata.backlit or false
		end

		if not full then return end

		local pathLength = net.ReadUInt(Wire_LEDTape.NumBits) + 1
		for i = 1, pathLength do
			table.insert(controller.Path,{net.ReadEntity(), net.ReadVector()})
		end

		controller:SetOverlayText("LED Tape Controller\n(" .. (pathLength-1) .. " Segments)")

	end )

end


if SERVER then

	util.AddNetworkString("LEDTapeData")
	net.Receive("LEDTapeData", function(len, ply)
		local controller = net.ReadEntity()
		local full       = net.ReadBool()
		if not IsValid(controller) then return end
		table.insert(controller.DownloadQueue, {ply = ply, full = full})
	end )

	function ENT:Initialize()
		BaseClass.Initialize(self)
		WireLib.CreateInputs(self, {
			"Color [VECTOR]"
		})
		self:SharedInit()
		self.DownloadQueue = {}
	end

	function ENT:SendMaterialUpdate()
		net.WriteFloat  ( self.Width )
		net.WriteString ( self.BaseMaterial )
	end

	function ENT:SendFullUpdate()
		self:SendMaterialUpdate()
		net.WriteUInt(#self.Path - 1, Wire_LEDTape.NumBits)
		for k, node in ipairs(self.Path) do
			net.WriteEntity(node[1])
			net.WriteVector(node[2])
		end
	end

	function ENT:Think()

		if self.BaseMaterial and self.Width and self.Path then -- don't send updates with nil stuff!
			for _, request in ipairs(self.DownloadQueue) do
				net.Start("LEDTapeData")

					net.WriteEntity( self )
					net.WriteBool(request.full)

					if request.full then self:SendFullUpdate()
					else self:SendMaterialUpdate() end

				net.Send(request.ply)
			end
			self.DownloadQueue = {}
		end

		BaseClass.Think( self )
		self:NextThink(CurTime() + 0.05)
		return true
	end

	-- duplicator support
	function ENT:BuildDupeInfo()
		local info = BaseClass.BuildDupeInfo(self) or {}
			info.BaseMaterial = self.BaseMaterial
			info.Width    = self.Width
			info.Path     = {}
			for k, node in ipairs(self.Path) do
				info.Path[k] = {node[1]:EntIndex(), node[2]}
			end
		return info
	end

	function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
		BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
		self.BaseMaterial = info.BaseMaterial
		self.Width = info.Width
		self.Path = {}
		for k, node in ipairs(info.Path) do
			self.Path[k] = { GetEntByID(node[1], game.GetWorld()), node[2] }
		end
	end
	duplicator.RegisterEntityClass("gmod_wire_ledtape", WireLib.MakeWireEnt, "Data")

	function ENT:TriggerInput(iname, value)
		if (iname == "Color") then
			self:SetNW2Int("LedTape_R", value[1])
			self:SetNW2Int("LedTape_G", value[2])
			self:SetNW2Int("LedTape_B", value[3])
		end
	end

	function MakeWireLEDTapeController( pl, Pos, Ang, model, path, width, material )
		local controller = WireLib.MakeWireEnt(pl, {Class = "gmod_wire_ledtape", Pos = Pos, Angle = Ang, Model = model})
		if not IsValid(controller) then return end

		controller.Path = path
		controller.Width = math.Clamp(width,0.1,4)
		controller.BaseMaterial = material

		return controller
	end

end


