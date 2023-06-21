--------------------------------------------------------------------------------
-- WireGPU class
--------------------------------------------------------------------------------
--   Usage:
--     Initialize:
--       self.GPU = WireGPU(self.Entity)
--
--     OnRemove:
--       self.GPU:Finalize()
--
--     Draw (if something changes):
--       self.GPU:RenderToGPU(function()
--           ...code...
--       end)
--
--     Draw (every frame):
--       self.GPU:Render()
--------------------------------------------------------------------------------


GPULib = {}

local GPU = {}
GPU.__index = GPU
GPULib.GPU = GPU

function GPULib.WireGPU(ent, ...)
	local self = {
		entindex = ent and ent:EntIndex() or 0,
		Entity = ent or NULL,
	}
	setmetatable(self, GPU)
	self:Initialize(...)
	return self
end
WireGPU = GPULib.WireGPU

function GPU:SetTranslucentOverride(bool)
	self.translucent = bool;
end

function GPU:GetInfo()
	local ent = self.Entity
	if not ent:IsValid() then ent = self.actualEntity end
	if not ent then return end

	local model = ent:GetModel()
	local monitor = WireGPU_Monitors[model]

	local pos = ent:LocalToWorld(monitor.offset)
	local ang = ent:LocalToWorldAngles(monitor.rot)

	return monitor, pos, ang
end

if CLIENT then
	local materialCache = {}
	function GPULib.Material(name)
		if not materialCache[name] then
			local protoMaterial = Material(name)
			local textureName = protoMaterial:GetString("$basetexture")
			local imageName = protoMaterial:GetName()
			local materialParameters = {
				["$basetexture"] = textureName,
				["$vertexcolor"] = 1,
				["$vertexalpha"] = 1,
			}
			materialCache[name] = CreateMaterial(imageName.."_DImage", "UnlitGeneric", materialParameters)
		end
		return materialCache[name]
	end

	-- Handles rendertarget caching
	local RT_CACHE_SIZE = 64
	local RenderTargetCache = { }

	-- Todo: Just dynamically create table elements instead of having them pre-defined?
	for i = 1, RT_CACHE_SIZE do
		local Target = {
			false, -- Is rendertarget in use
			nil -- The rendertarget
		}
		table.insert(RenderTargetCache, Target)
	end

	-- Returns a render target from the cache pool and marks it as used
	local function GetRT()
		for i, RT in ipairs(RenderTargetCache) do
			if not RT[1] then -- not used
				local rendertarget = RT[2]
				if rendertarget then
					RT[1] = true -- Mark as used
					return rendertarget
				else
				local rendertarget = GetRenderTargetEx("WireGPU_RT_" .. i, 1024, 1024, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 256, 0, 12)
					if rendertarget then
						RT[1] = true -- Mark as used
						RT[2] = rendertarget -- Assign the RT
						return rendertarget
					else
						RT[1] = true -- Mark as used since we couldn't create it
						ErrorNoHalt("Wiremod: Render target WireGPU_RT_" .. i .. " could not be created!\n")
					end
				end
			end
		end

		ErrorNoHalt("All render targets are in use, some wire screens may not draw!\n")
		return nil

	end

	-- Frees an used RT
	local function FreeRT(rt)

		for i, RT in pairs( RenderTargetCache ) do
			if RT[2] == rt then

				RT[1] = false
				return
			end
		end

		ErrorNoHalt("RT Screen ",rt," could not be freed (not found)\n")

	end

	//
	// Create basic fonts
	//
	local fontData =
	{
		font="lucida console",
		size=40,
		weight=800,
		antialias= true,
		additive = false,
	}
	surface.CreateFont("WireGPU_ConsoleFont", fontData)
  surface.CreateFont("LCDFontBlur", {
        font = "Alphanumeric LCD",
        size = 26,
        antialias = false,
        blursize = 1
      })
  surface.CreateFont("LCDFont", {
    font = "Alphanumeric LCD",
    size = 26,
    antialias = false
  })
	//
	// Create screen textures and materials
	//
	WireGPU_matScreen = CreateMaterial("sprites/GPURT","UnlitGeneric",{
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
    ["$translucent"] = 1,
		["$ignorez"] = 1,
		["$nolod"] = 1,
		})
	WireGPU_matBuffer = CreateMaterial("sprites/GPUBUF","UnlitGeneric",{
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
    ["$translucent"] = 1,
		["$ignorez"] = 1,
		["$nolod"] = 1,
	})


	function GPU:Initialize(no_rendertarget)
		if no_rendertarget then return nil end
		-- Rendertarget cache management

		-- This should not even happen.
		if self.RT then
			ErrorNoHalt("Warning: GPU:Initialize called, but an RT still existed. Maybe you are not killing it properly?")
			FreeRT(self.RT)
		end

		-- find a free one
		self.RT = GetRT()
		if not self.RT then
			return nil
		end

		-- clear the new RT
		self.ForceClear = true
		return self.RT
	end

	function GPULib.WireGPU(ent, ...)
		local self = {
			entindex = ent and ent:EntIndex() or 0,
			Entity = ent or NULL,
		}
		setmetatable(self, GPU)
		self:Initialize(...)
		return self
	end

	function GPU:Finalize()
		if not self.RT then return end
		timer.Simple(0.2, function() -- This is to test if the entity has truly been removed. If you really know you need to remove the RT, call FreeRT()
			if IsValid(self.Entity) then
				--MsgN(self,"Entity still exists, exiting.")
				return
			end
			self:FreeRT()
		end)
	end

	function GPU:FreeRT()
		FreeRT( self.RT )
		self.RT = nil
	end

	function GPU:Clear(color)
		if not self.RT then return end
		render.ClearRenderTarget(self.RT, color or Color(0, 0, 0, 0))
	end

	local texcoords = {
		[0] = {
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
		},
		{
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
		},
		{
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
		},
		{
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
		},
	}
	-- helper function for GPU:Render
	function GPU.DrawScreen(x, y, w, h, rotation, scale, uvclipx, uvclipy)
		-- generate vertex data
		local vertices = {
			--[[
			Vector(x  , y  ),
			Vector(x+w, y  ),
			Vector(x+w, y+h),
			Vector(x  , y+h),
			]]
			{ x = x  , y = y   },
			{ x = x+w, y = y   },
			{ x = x+w, y = y+h },
			{ x = x  , y = y+h },
		}

		-- rotation and scaling
		local rotated_texcoords = texcoords[rotation] or texcoords[0]
		for index,vertex in ipairs(vertices) do
			local tex = rotated_texcoords[index]
			if tex.u == 0 then
				vertex.u = tex.u-scale
			else
				vertex.u = tex.u+scale+uvclipx
			end
			if tex.v == 0 then
				vertex.v = tex.v-scale
			else
				vertex.v = tex.v+scale+uvclipy
			end
		end

		surface.DrawPoly(vertices)
		--render.DrawQuad(unpack(vertices))
	end

	function GPU:RenderToGPU(renderfunction)
		if not self.RT then return end

		if self.ForceClear then
			self:Clear()
			self.ForceClear = nil
		end

		local oldw = ScrW()
		local oldh = ScrH()

		local NewRT = self.RT
		local OldRT = render.GetRenderTarget()

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0, 0, 1024, 1024)
		cam.Start2D()
			local ok, err = xpcall(renderfunction, debug.traceback)
			if not ok then WireLib.ErrorNoHalt(err) end
		cam.End2D()
		render.SetViewPort(0, 0, oldw, oldh)
		render.SetRenderTarget(OldRT)
	end

	-- If width is specified, height is ignored. if neither is specified, a height of 512 is used.
	function GPU:RenderToWorld(width, height, renderfunction, zoffset, emulateRT)
		local monitor, pos, ang = self:GetInfo()

		if zoffset then
			pos = pos + ang:Up()*zoffset
		end

		if emulateRT then
			pos = pos - ang:Right()*(monitor.y2-monitor.y1)/2
			pos = pos - ang:Forward()*(monitor.x2-monitor.x1)/2
		end

		local h = width and width*monitor.RatioX or height or 1024
		local w = width or h/monitor.RatioX
		local x = -w/2
		local y = -h/2

		local res = monitor.RS*1024/h
		cam.Start3D2D(pos, ang, res)
			local ok, err = xpcall(renderfunction, debug.traceback, x, y, w, h, monitor, pos, ang, res)
			if not ok then WireLib.ErrorNoHalt(err) end
		cam.End3D2D()
	end

	function GPU:Render(rotation, scale, width, height, postrenderfunction, uvclipx, uvclipy)
		if not self.RT then return end

		local monitor, pos, ang = self:GetInfo()

		local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
		WireGPU_matScreen:SetTexture("$basetexture", self.RT)

		local res = monitor.RS
		cam.Start3D2D(pos, ang, res)
			local ok, err = xpcall(function()
				local aspect = 1/monitor.RatioX
				local w = (width  or 1024)*aspect
				local h = (height or 1024)
				local x = -w/2
				local y = -h/2

				local translucent = self.translucent;

				if translucent == nil then
					translucent = monitor.translucent
				end

				if not translucent then
					surface.SetDrawColor(0,0,0,255)
					surface.DrawRect(-512*aspect,-512,1024*aspect,1024)
				end

				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(WireGPU_matScreen)

				render.PushFilterMag(self.texture_filtering or TEXFILTER.POINT)
				render.PushFilterMin(self.texture_filtering or TEXFILTER.POINT)

				self.DrawScreen(x, y, w, h, rotation or 0, scale or 0, uvclipx or 0, uvclipy or 0)

				render.PopFilterMin()
				render.PopFilterMag()

				if postrenderfunction then postrenderfunction(pos, ang, res, aspect, monitor) end
			end, debug.traceback)
			if not ok then WireLib.ErrorNoHalt(err) end
		cam.End3D2D()

		WireGPU_matScreen:SetTexture("$basetexture", OldTex)
	end

	-- compatibility

	local GPUs = {}

	function WireGPU_NeedRenderTarget(entindex)
		if not GPUs[entindex] then GPUs[entindex] = GPULib.WireGPU(Entity(entindex)) end
		return GPUs[entindex].RT
	end

	function WireGPU_GetMyRenderTarget(entindex)
		local self = GPUs[entindex]
		if self.RT then return self.RT end

		return self:Initialize()
	end

	function WireGPU_ReturnRenderTarget(entindex)
		return GPUs[entindex]:Finalize()
	end

	function WireGPU_DrawScreen(x, y, w, h, rotation, scale)
		return GPU.DrawScreen(x, y, w, h, rotation, scale)
	end

end

-- GPULib switcher functionality
if CLIENT then

	usermessage.Hook("wire_gpulib_setent", function(um)
		local screen = Entity(um:ReadShort())
		if not screen:IsValid() then return end
		if not screen.GPU then return end

		local ent = Entity(um:ReadShort())
		if not ent:IsValid() then return end

		screen.GPU.Entity = ent
		screen.GPU.entindex = ent:EntIndex()

		if screen == ent then return end

		screen.GPU.actualEntity = screen

		local model = ent:GetModel()
		local monitor = WireGPU_Monitors[model]

		local h = 1024*monitor.RS
		local w = h/monitor.RatioX
		local x = -w/2
		local y = -h/2

		local corners = {
			{ x  , y   },
			{ x  , y+h },
			{ x+w, y   },
			{ x+w, y+h },
		}

		local mins, maxs = screen:OBBMins(), screen:OBBMaxs()

		local timerid = "wire_gpulib_updatebounds"..screen:EntIndex()
		local function setbounds()
			if not screen:IsValid() then
				timer.Remove(timerid)
				return
			end
			if not ent:IsValid() then
				timer.Remove(timerid)

				screen.ExtraRBoxPoints[1001] = nil
				screen.ExtraRBoxPoints[1002] = nil
				screen.ExtraRBoxPoints[1003] = nil
				screen.ExtraRBoxPoints[1004] = nil
				Wire_UpdateRenderBounds(screen)

				screen.GPU.Entity = screen.GPU.actualEntity
				screen.GPU.entindex = screen.GPU.actualEntity:EntIndex()
				screen.GPU.actualEntity = nil

				return
			end

			local ang = ent:LocalToWorldAngles(monitor.rot)
			local pos = ent:LocalToWorld(monitor.offset)

			screen.ExtraRBoxPoints = screen.ExtraRBoxPoints or {}
			for i,x,y in ipairs_map(corners, unpack) do
				local p = Vector(x, y, 0)
				p:Rotate(ang)
				p = screen:WorldToLocal(p+pos)

				screen.ExtraRBoxPoints[i+1000] = p
			end

			Wire_UpdateRenderBounds(screen)
		end

		timer.Create(timerid, 5, 0, setbounds)

		setbounds()
	end) -- usermessage.Hook

elseif SERVER then

	function GPULib.switchscreen(screen, ent)
		screen.GPUEntity = ent
		umsg.Start("wire_gpulib_setent")
			umsg.Short(screen:EntIndex())
			umsg.Short(ent:EntIndex())
		umsg.End()
	end

end




-- GPULib caching functionality
if CLIENT then
  ------------------------------------------------------------------------------
  -- Attach cache receiver to this entity
  ------------------------------------------------------------------------------
  local writeHandler = {}
  function GPULib.ClientCacheCallback(ent, writeFunction)
    writeHandler[ent and ent:EntIndex() or 0] = writeFunction
  end

  ------------------------------------------------------------------------------
  -- RLE-decompress incoming message
  ------------------------------------------------------------------------------
  --[[local blockText = {
    { "[no offset]", "[1-offset]", "[2-offset]", "[4-offset]" },
    { "[no rep]", nil, "[rep 2]", "[rep 4]" },
    { "[cnt 1]", nil, "[cnt 2]", "[cnt 3]" },
    { "[1-byte]", "[2-byte]", "[4-byte]", "[marker]" },
  } ]]--

  local function GPULib_MemorySync(um)
    -- Find the referenced entity
    local GPUIdx = um:ReadLong()
    local GPU = ents.GetByIndex(GPUIdx)
    if not GPU then return end
    if not GPU:IsValid() then return end
    if not writeHandler[GPUIdx] then return end

    -- Start reading blocks
    local blockCount = 0
    local currentOffset = 0
    while true do
      -- Read next block
      blockCount = blockCount + 1
      if blockCount > 256 then error("GPULib usermessage read error") return end

      -- Read block flags
      local dataFlags = um:ReadChar()+128
      if dataFlags == 240 then return end

      local offsetSize  = dataFlags % 4
      local repeatCount = math.floor(dataFlags/4) % 4
      local dataCount   = math.floor(dataFlags/16) % 4
      local valueSize   = math.floor(dataFlags/64) % 4

      local Repeat = 0
      local Count = 0

      if offsetSize > 0 then
        local deltaOffset = 0
        if offsetSize == 1 then deltaOffset = um:ReadChar () end
        if offsetSize == 2 then deltaOffset = um:ReadShort() end
        if offsetSize == 3 then deltaOffset = um:ReadFloat() end
        currentOffset = currentOffset + deltaOffset
        --print("  dOffset = "..deltaOffset..", offset = "..currentOffset)
      end

      if dataCount == 0 then Count = 1 end
      if dataCount == 1 then Count = um:ReadChar()+130 end
      if dataCount == 2 then Count = 2 end
      if dataCount == 3 then Count = 3 end

      if repeatCount == 0 then Repeat = 1 end
      if repeatCount == 1 then Repeat = um:ReadChar()+130 end
      if repeatCount == 2 then Repeat = 2 end
      if repeatCount == 3 then Repeat = 4 end

      --[[print("  Block ",
        blockText[1][offsetSize+1],
        blockText[2][repeatCount+1] or ("[rep "..Repeat.."* ]"),
        blockText[3][dataCount+1] or ("[cnt "..Count.."* ]"),
        blockText[4][valueSize+1])]]--

      for i=1,Count do
        local Value = 0
        if valueSize == 0 then Value = um:ReadChar()  end
        if valueSize == 1 then Value = um:ReadShort() end
        if valueSize == 2 then Value = um:ReadLong() end
        if valueSize == 3 then Value = um:ReadFloat() end

        for j=1,Repeat do
          --print("    ["..currentOffset.."] = "..Value)
          writeHandler[GPUIdx](currentOffset,Value)
          currentOffset = currentOffset + 1
        end
      end
    end
  end
  usermessage.Hook("wire_memsync", GPULib_MemorySync)
elseif SERVER then
  local CACHEMGR = {}
  CACHEMGR.__index = CACHEMGR
  GPULib.CACHEMGR = CACHEMGR


  ------------------------------------------------------------------------------
  -- Create new cache manager (serverside)
  ------------------------------------------------------------------------------
  function GPULib.GPUCacheManager(ent, orderMatters, ...)
    local self = {
      EntIndex = ent and ent:EntIndex() or 0,
      Entity = ent or NULL,
    }
    setmetatable(self, CACHEMGR)
    self.ValueOrderMatters = orderMatters
    self.Enabled = true
    self:Reset()
    return self
  end
  GPUCacheManager = GPULib.GPUCacheManager


  ------------------------------------------------------------------------------
  -- Get size of the value to write
  ------------------------------------------------------------------------------
  local function getSize(value)
    if (value >= -128)   and (value <= 127)             and (math.floor(value) == value) then return 1,false end
    if (value >= -32768) and (value <= 32767)           and (math.floor(value) == value) then return 2,false end
    if (value >= -2147483648) and (value <= 2147483647) and (math.floor(value) == value) then return 4,false end
    return 4,true
  end


  ------------------------------------------------------------------------------
  -- Initialize cache manager
  ------------------------------------------------------------------------------
  function CACHEMGR:Reset()
    self.Cache = {}
    self.CacheBytes = 0
  end


  ------------------------------------------------------------------------------
  -- Write a single value to cache
  ------------------------------------------------------------------------------
  function CACHEMGR:Write(Address,Value)
    local valueSize,valueFloat
    if Value then
      valueSize,valueFloat = getSize(Value)
      self.CacheBytes = self.CacheBytes + valueSize
    end

    table.insert(self.Cache,{ Address, Value, valueSize, valueFloat })
    --if #self.Cache > 2048 then self:Flush() end
  end


  ------------------------------------------------------------------------------
  -- Send value right away
  ------------------------------------------------------------------------------
  function CACHEMGR:WriteNow(Address,Value,forcePlayer)
    umsg.Start("wire_memsync", forcePlayer)
      umsg.Long(self.EntIndex)
      umsg.Char(195-128)
      umsg.Float(Address)
      umsg.Float(Value)
      umsg.Char(240-128)
    umsg.End()
  end


  ------------------------------------------------------------------------------
  -- RLE-compress cache and send it
  ------------------------------------------------------------------------------
  function CACHEMGR:Flush(forcePlayer)
    -- Don't flush if nothing cached
    if #self.Cache == 0 then return end
    self.CacheBytes = 0

    -- Sort cache so all addresses are continiously layed out
    -- Do not sort if order at which values are written matters
    if not self.ValueOrderMatters then
      table.sort(self.Cache,function(A,B)
        return A[1] < B[1]
      end)
    end

    -- RLE-encode the data
    local compressInfo = {}
    for _,data in ipairs(self.Cache) do
      local address,value,size,isfloat = data[1],(data[2] or 0),(data[3] or 1),(data[4] or false)
      local compressBlock = compressInfo[#compressInfo]
      local sequentialBlock
      local previousBlockEnd
      if compressBlock then
        previousBlockEnd = compressBlock.Offset+#compressBlock.Data*compressBlock.Repeat
        sequentialBlock = previousBlockEnd == address
      end

      if not compressBlock then
        -- New block of data
        compressBlock = {
          Data = { value },
          Offset = address,
          SetOffset = address,
          Repeat = 1,
          Size = size,
          IsFloat = isfloat,
        }
        table.insert(compressInfo,compressBlock)
      elseif sequentialBlock and
             (compressBlock.Size == size) then
        -- Add to previous block of data
        if (#compressBlock.Data == 1) and (compressBlock.Data[1] == value) and (sequentialBlock) and (compressBlock.Repeat < 256) then
          -- RLE compression
          compressBlock.Repeat = compressBlock.Repeat + 1
        elseif compressBlock.Repeat > 1 then
          -- Cant add to a repeating block, make new
          compressBlock = {
            Data = { value },
            Offset = address,
            Repeat = 1,
            Size = size,
            IsFloat = isfloat,
          }
          if not sequentialBlock then compressBlock.SetOffset = address-previousBlockEnd end
          table.insert(compressInfo,compressBlock)
        else
          -- Append to a group of values, unless the block is too big
          if #compressBlock.Data*compressBlock.Repeat*compressBlock.Size < 196 then
            table.insert(compressBlock.Data,value)
          else
            -- Add it to a new block instead
            compressBlock = {
              Data = { value },
              Offset = address,
              Repeat = 1,
              Size = size,
              IsFloat = isfloat,
            }
            if not sequentialBlock then compressBlock.SetOffset = address-previousBlockEnd end
            table.insert(compressInfo,compressBlock)
          end
        end
      else
        -- Create new block
        compressBlock = {
          Data = { value },
          Offset = address,
          Repeat = 1,
          Size = size,
          IsFloat = isfloat,
        }
        if not sequentialBlock then compressBlock.SetOffset = address-previousBlockEnd end
        table.insert(compressInfo,compressBlock)
      end
    end

    --PrintTable(compressInfo)

    -- Start the message
    local messageSize = 4
    umsg.Start("wire_memsync", forcePlayer)
    umsg.Long(self.EntIndex)

    -- Start sending all compressed blocks
    for k,v in ipairs(compressInfo) do
      --======================================================================--
      -- Generate flags for sending the data
      --======================================================================--
      -- [0..1] Delta offset
      --         0: no offset
      --         1: 1-byte offset
      --         2: 2-byte offset
      --         3: 4-byte offset
      -- [2..3] Repeat count
      --         0: none
      --         1: repeat count 1-byte follows
      --         2: repeat 2 times
      --         3: repeat 4 times
      -- [4..5] Data count
      --         0: 1 element
      --         1: data size 1-byte follows
      --         2: 2 elements
      --         3: 3 elements (but not floats)
      -- [6..7] Size
      --         0: 1-byte
      --         1: 2-byte
      --         2: 4-byte int
      --         3: 4-byte float
      --
      -- If it's a special data marker, then bitmap is:
      -- [0..1] Marker type
      -- [2..5] Marker data
      -- [6] 1
      -- [7] 1

      local dataFlags = 0
      if v.SetOffset then
        local offsetSize = getSize(v.SetOffset)
        if offsetSize == 1 then dataFlags = dataFlags + 1 end
        if offsetSize == 2 then dataFlags = dataFlags + 2 end
        if offsetSize == 4 then dataFlags = dataFlags + 3 end
      end

      if v.Repeat > 1 then
            if v.Repeat == 2 then dataFlags = dataFlags + 8
        elseif v.Repeat == 4 then dataFlags = dataFlags + 12
        else                      dataFlags = dataFlags + 4
        end
      end

      if #v.Data > 1 then
        if #v.Data == 2 then
          dataFlags = dataFlags + 32
        elseif (#v.Data == 3) and (not v.IsFloat) then
          dataFlags = dataFlags + 48
        else
          dataFlags = dataFlags + 16
        end
      end

      if v.Size == 1 then dataFlags = dataFlags + 0   end
      if v.Size == 2 then dataFlags = dataFlags + 64  end
      if (v.Size == 4) and (not v.IsFloat) then dataFlags = dataFlags + 128 end
      if (v.Size == 4) and (    v.IsFloat) then dataFlags = dataFlags + 192 end

      umsg.Char(dataFlags-128)
      messageSize = messageSize + 4


      --======================================================================--
      -- Send the data
      --======================================================================--
      if v.SetOffset then
        local offsetSize = getSize(v.SetOffset)
        if offsetSize == 1 then umsg.Char (v.SetOffset) messageSize = messageSize + 1 end
        if offsetSize == 2 then umsg.Short(v.SetOffset) messageSize = messageSize + 2 end
        if offsetSize == 4 then umsg.Float(v.SetOffset) messageSize = messageSize + 4 end
      end

      if (#v.Data > 2) then
        if (#v.Data ~= 3) or (v.IsFloat) then
          umsg.Char(#v.Data-130) messageSize = messageSize + 1
        end
      end

      if (v.Repeat > 1) and
         (v.Repeat ~= 2) and
         (v.Repeat ~= 4) then umsg.Char(v.Repeat-130) messageSize = messageSize + 1 end

      for _,value in ipairs(v.Data) do
        if v.Size == 1 then umsg.Char (value) messageSize = messageSize + 1 end
        if v.Size == 2 then umsg.Short(value) messageSize = messageSize + 2 end
        if (v.Size == 4) and (not v.IsFloat) then umsg.Long(value)  messageSize = messageSize + 4 end
        if (v.Size == 4) and (    v.IsFloat) then umsg.Float(value) messageSize = messageSize + 4 end
      end


      --======================================================================--
      -- Check size of next data block. If it fits into usermessage, continue.
      -- Otherwise just create new message
      --======================================================================--
      if compressInfo[k+1] then
        local nextSize = #compressInfo[k+1].Data*compressInfo[k+1].Repeat*compressInfo[k+1].Size
        if nextSize + messageSize > 248 then
          umsg.Char(240-128)
          umsg.End()
          messageSize = 4
          umsg.Start("wire_memsync", forcePlayer)
          umsg.Long(self.EntIndex)
          compressInfo[k+1].SetOffset = compressInfo[k+1].Offset -- Force set offset
        end
      else
        umsg.Char(240-128)
        umsg.End()
      end
    end

    self.Cache = {}
  end
end
