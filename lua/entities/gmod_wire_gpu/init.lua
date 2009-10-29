AddCSLuaFile("gpu_vm.lua")
AddCSLuaFile("gpu_opcodes.lua")
AddCSLuaFile("gpu_serverbus.lua")
AddCSLuaFile("gpu_interrupt.lua")
AddCSLuaFile("gpu_clientbus.lua")

AddCSLuaFile("entities/gmod_wire_cpu/cpu_opcodes.lua")
AddCSLuaFile("entities/gmod_wire_cpu/cpu_vm.lua")
AddCSLuaFile("entities/gmod_wire_cpu/cpu_bitwise.lua")
AddCSLuaFile("entities/gmod_wire_cpu/cpu_advmath.lua")

AddCSLuaFile("entities/gmod_wire_cpu/compiler_asm.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include('entities/gmod_wire_cpu/compiler_asm.lua')	//Include ZASM
include('entities/gmod_wire_cpu/cpu_opcodes.lua')	//Include ZCPU opcodes
include('entities/gmod_wire_cpu/cpu_advmath.lua')	//Include vector and matrix math
include('gpu_serverbus.lua')				//Include ZGPU serverside bus
include('gpu_opcodes.lua')				//Include ZGPU opcodes for ZASM

ENT.WireDebugName = "GPU"

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "Clk", "Reset", "MemBus", "IOBus" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" })

	self.Clk = 1
	self.IOBus = nil
	self.MemBus = nil

	self.Debug = false //will cause massive fps drop!

	self.DebugLines = {}
	self.DebugData = {}

	self.Memory = {}
	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self.IsGPU = true
	self.UseROM = false

	self.SerialNo = 30000000 + math.floor(math.random()*1000000)

	self:SetOverlayText("Graphical Processing Unit")

	self:InitializeGPUOpcodeNames()
	self:InitializeASMOpcodes()
	self:InitializeRegisterNames()
	self:InitializeBus()
end

//function ENT:Use(pl)
//	//if (!self.Using) then
//	//	self.Using = true
//	//	self.Entity:NextThink(CurTime()+0.4)
//
//		local rp = RecipientFilter()
//		rp:AddPlayer(pl)
//
//		Msg("Binding GPU (server)\n")
//
//		umsg.Start("wiregpu_onuse", rp)
//			umsg.Long(self:EntIndex())
//		umsg.End()
//	//end
//end
//
//function ENT:Think()
//	self.BaseClass.Think(self)
//
//	//self.Using = nil
//	//return false
//end
//

function GPU_PlayerRespawn(pl)
	for k,v in pairs(ents.FindByClass("gmod_wire_gpu")) do
		v:GPU_ResendData(pl)
	end
end
hook.Add("PlayerInitialSpawn", "GPUPlayerRespawn", GPU_PlayerRespawn)

function ENT:Reset()
	self:WriteCell(65534,1)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		self:WriteCell(65535,self.Clk)
	elseif (iname == "Reset") then
		if (value >= 1.0) then
			self:WriteCell(65534,1)
		end
	end
end

function ENT:Think()
	if (self.Inputs.IOBus.Src) then
		local DataUpdated = false

		for i = 0, 1023 do
			if (self.Inputs.IOBus.Src.ReadCell) then
				local var = self.Inputs.IOBus.Src:ReadCell(i)
				if (var) then
					if (self:ReadCell(i+63488) ~= var) then
						self:WriteCell(i+63488,var)
						DataUpdated = true
					end
				end
			end
		end

		if (DataUpdated == true) then
			self:FlushCache()
		end
	end
	self.Entity:NextThink(CurTime()+0.05)
	return true
end


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.SerialNo = self.SerialNo
	info.Memory = {}
	for i=0,65535 do
		if (self.Memory[i]) then
			info.Memory[i] = self.Memory[i]
		end
	end

	return info
end

function Resend_GPU_Data(gpuent)
	gpuent:InitializeBus()
	gpuent:FlushCache()
	for i=0,65535 do
		if (gpuent.Memory[i]) then
			gpuent:WriteCell(i,gpuent.Memory[i])
		end
	end
	gpuent:FlushCache()

	gpuent:WriteCell(65534,1) //reset
	gpuent:WriteCell(65535,gpuent.Clk)
end

function Reflush_GPU_Data(gpuent,pl)
	gpuent.ForcePlayer = pl
	gpuent:FlushCache()
	for i=0,65535 do
		if (gpuent.Memory[i]) then
			gpuent:WriteCell(i,gpuent.Memory[i])
		end
	end
	gpuent:FlushCache()

	gpuent:WriteCell(65534,1) //reset
	gpuent:WriteCell(65535,gpuent.Clk)
	gpuent.ForcePlayer = nil
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.SerialNo = info.SerialNo
	self.Memory = {}

	for i=0,65535 do
		if (info.Memory[i]) then
			self.Memory[i] = info.Memory[i]
		end
	end

	timer.Create("GPU_Paste_Timer"..math.floor(math.random()*1000000),0.1+math.random()*0.7,1,Resend_GPU_Data,self)
end

function ENT:GPU_ResendData(pl)
	timer.Create("GPU_Resend_Timer"..math.floor(math.random()*1000000),0.1+math.random()*3.0,1,Reflush_GPU_Data,self,pl)
end
