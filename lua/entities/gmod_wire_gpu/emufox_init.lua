include("gmod_wire_cpu/compiler_asm.lua")

function ENT:ServerInitialize()
	self:Initialize()
	self:InitializeGPUOpcodeNames()
	self:InitializeASMOpcodes()
	self:InitializeRegisterNames()
	self:InitializeOptimizer()
	self.IsGPU = true
	self.MinFrameRateRatio = {}
	self.MinFrameRateRatio.GetFloat = function() return 4 end
end

function ENT:Write(value)
	if (tonumber(value) ~= nil) && (value) then
		self:WriteCell(self.WIP,value)
		self.ROMMemory[self.WIP] = value
		if (self.WIP == 65534) then
			self:GPUHardReset()
		end
		//if (self.Debug) && (value != 0) then Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n") end
	end
	self.WIP = self.WIP + 1
end
