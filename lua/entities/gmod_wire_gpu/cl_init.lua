if (EmuFox) then
	include('gmod_wire_gpu/shared.lua')
	include('gmod_wire_gpu/gpu_vm.lua')
	include('gmod_wire_gpu/gpu_opcodes.lua')
	include('gmod_wire_gpu/gpu_clientbus.lua')
else
	include('shared.lua')
	include('gpu_vm.lua')
	include('gpu_opcodes.lua')
	include('gpu_clientbus.lua')
end

ENT.RenderGroup = RENDERGROUP_BOTH

WireGPU_HookedGPU = nil -- TODO: local?

//local texFSB = render.GetSuperFPTex()
//local matFSB = Material("pp/motionblur")
//local matFB  = Material("pp/fb")

function ENT:Initialize()
	self.IsGPU = true
	self.PrevTime = CurTime()

	self.Debug = false

	self.Memory = {}
	self.ROMMemory = {}

	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self:InitGraphicTablet()
	self:InitializeGPUOpcodeTable()
	self:InitializeGPULookupTables()
	self:InitializeGPUVariableSet()
	self:InitializeErrors()
	self:GPUMathInit()
	self:GPUHardReset()

	self.FramesSinceRedraw = 0
	self.FrameRateRatio = 4
	self.FrameInstructions = 0

	self.GPU = WireGPU(self)

	self.MinFrameRateRatio = CreateClientConVar("wire_gpu_frameratio",4,false,false)

	-- TODO: what are these for?
	self.OF = CreateClientConVar("gpu_of",0,false,false)
	self.OR = CreateClientConVar("gpu_or",0,false,false)
	self.OU = CreateClientConVar("gpu_ou",0,false,false)
	self.Scale = CreateClientConVar("gpu_scale",1,false,false)
	self.Ratio = CreateClientConVar("gpu_ratio",1,false,false)
	self.Rot90 = CreateClientConVar("gpu_rot90",0,false,false)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function DebugMessage(msg)
	Msg("============================================\n")
	Msg(msg.."\n")
end

function WireGPU_MemoryMessage(um)
	local ent = ents.GetByIndex(um:ReadLong())
	local cachebase = um:ReadLong()
	local cachesize = um:ReadLong()

	if ((ent) && (ent.Memory)) then
		if (cachebase >= 0) && (cachebase + cachesize < 65537) then
			for i=0,cachesize-1 do
				local value = um:ReadFloat()

				ent:WriteCell(cachebase+i,value)
				ent.ROMMemory[cachebase+i] = value
			end
		end
	end
end
usermessage.Hook("wiregpu_memorymessage", WireGPU_MemoryMessage)

function ENT:SVN_Version()
	local SVNString = "$Revision: 000$"

	return tonumber(string.sub(SVNString,12,14))
end

function ENT:DoCall(callid,calldepth)
	if ((self.EntryPoint) && (self.EntryPoint[callid])) then
		self:GPUFrameReset()

		self.IP = self.EntryPoint[callid]
		local cmdcount = 0
		while ((cmdcount < calldepth) && (self.INTR == 0)) do
			self:GPUExecute()
			cmdcount = cmdcount + 1
			self.FrameInstructions = self.FrameInstructions + 1
		end

		if (EmuFox) then
			SetInstructions(cmdcount)
		end
	end
end

function ENT:OutputError(intnumber,intparam)
	local ErrorText = "Unknown error"
	if (self.ErrorText[intnumber]) then ErrorText = self.ErrorText[intnumber] end

	surface.SetDrawColor(200,0,0,255)
	surface.DrawRect(64-4,128-4,512-128+8,128+8)
	surface.SetDrawColor(30,30,30,255)
	surface.DrawRect(64,128,512-128,128)

	draw.DrawText(
		"GPU Error  : \n"..
		"Parameter  : \n"..
		"Instruction: \n"..
		"Error: \n",
	"WireGPU_ConsoleFont",64+4,128+4,Color(255,64,64,255),0)
	draw.DrawText(
		"             "..intnumber.."\n"..
		"             "..intparam .."\n"..
		"             "..self.XEIP.."\n"..
		"       "..ErrorText.."\n",
		"WireGPU_ConsoleFont",64+4,128+4,Color(255,255,255,255),0)
end

function ENT:RenderGPU(clearbg)
	if (EmuFox) then
		self:WriteCell(65513,1.33)
	end

	self.FrameBuffer = self.GPU.RT
	//self.SpriteBuffer = self.SpriteGPU.RT --WireGPU_GetMyRenderTarget(self:EntIndex().."_sprite")

	local FrameRate = self.MinFrameRateRatio:GetFloat() or 4
	self.FramesSinceRedraw = self.FramesSinceRedraw + 1
	self.FrameInstructions = 0
	if (self.FramesSinceRedraw >= FrameRate) then
		self.FramesSinceRedraw = 0
		local oldw = ScrW()
		local oldh = ScrH()

		local OldRT = render.GetRenderTarget()
		local NewRT = self.FrameBuffer

		if (not NewRT) then return end
		WireGPU_matScreen:SetMaterialTexture( "$basetexture", NewRT )
		render.SetRenderTarget(NewRT)
		render.SetViewPort(0,0,512,512)
		cam.Start2D()
			if (self:ReadCell(65531) == 0) then
				if ((self:ReadCell(65533) == 1) && (clearbg == true)) then
					surface.SetDrawColor(0,0,0,255)
					surface.DrawRect(0,0,512,512)
				end
				if (self:ReadCell(65535) == 1) then
					if (self.EntryPoint[3]) && (self.HandleError == 1) then
						self:DoCall(3,FrameRate*600)
					else
						self:DoCall(0,FrameRate*600)
					end
				end
			end
		cam.End2D()

		//matFSB:SetMaterialFloat("$alpha", 1)
		//render.SetMaterial(matFSB)
		//render.DrawScreenQuad()

		//local TempRT = self.SpriteBuffer
		//render.SetRenderTarget(TempRT)
		//render.Clear(255,0,0,127)

		//render.SetRenderTarget(NewRT)
		//matFSB:SetMaterialTexture("$basetexture",self.SpriteBuffer)
		//render.SetMaterial(matFSB)
		//render.DrawQuad(Vector(0,0,0),Vector(256,0,0),Vector(256,256,0),Vector(0,256,0))
		//render.DrawScreenQuad()

		//render.CopyRenderTargetToTexture(NewRT)

		render.SetViewPort(0,0,oldw,oldh)
		render.SetRenderTarget(OldRT)
	end
end

function ENT:Draw()
	self.DoNormalDraw = function() end
	self.DrawEntityOutline = function() end
	self:DrawModel()

	local DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = CurTime()
	self.DeltaTime = DeltaTime

	if (WireGPU_HookedGPU == self) then
		Wire_Render(self)
		return
	end

	self:RenderGPU(true)

	local monitor = WireGPU_Monitors[self:GetModel()]

	self.GPU:Render(
		self:ReadCell(65522), self:ReadCell(65523)-self:ReadCell(65518)/512, -- rotation, scale
		512*math.Clamp(self:ReadCell(65525),0,1), 512*math.Clamp(self:ReadCell(65524),0,1), -- width, height
		function(pos, ang, resolution, aspect) -- postrenderfunction
			self:WriteCell(65513, aspect)
			local ply = LocalPlayer()
			local shootpos = ply:GetShootPos()
			local tracedata = {
				start = shootpos,
				endpos = shootpos + ply:GetAimVector()*self.workingDistance,
				filter = ply,
			}
			local trace = util.TraceLine(tracedata)

			if (trace.Entity == self) then
				local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)

				local cx = (self.x1 - cpos.x) / (self.x1 - self.x2)
				local cy = 1-(self.y1 - cpos.y) / (self.y1 - self.y2)

				self:WriteCell(65505,cx)
				self:WriteCell(65504,cy)

				if (self:ReadCell(65503) == 1) and (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
					surface.SetDrawColor(255,255,255,255)
					surface.SetTexture(surface.GetTextureID("gui/arrow"))
					surface.DrawTexturedRectRotated(-256*aspect+cx*512*aspect,-256+cy*512,32,32,45)
				end
			end
		end
	)

	Wire_Render(self)
end

function drawGPUHUD()
	if (WireGPU_HookedGPU) then
		Msg("Render GPU\n")

		if (not WireGPU_HookedGPU.RenderGPU) then
			WireGPU_HookedGPU = nil
			return
		end

		WireGPU_HookedGPU:RenderGPU(false)

		local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
		WireGPU_matScreen:SetMaterialTexture("$basetexture",WireGPU_HookedGPU.FrameBuffer)

		local w = ScrW()*math.Clamp(WireGPU_HookedGPU:ReadCell(65525),0,1)
		local h = ScrH()*math.Clamp(WireGPU_HookedGPU:ReadCell(65524),0,1)
		local x = 0
		local y = 0

		render.SetMaterial(WireGPU_matScreen)
		WireGPU_HookedGPU.GPU.DrawScreen(x,y,w,h,WireGPU_HookedGPU:ReadCell(65522),WireGPU_HookedGPU:ReadCell(65523))

		WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
	end
end
//hook.Add("HUDPaint","drawGPUHUD",drawGPUHUD)

function ENT:IsTranslucent()
	return false
end
