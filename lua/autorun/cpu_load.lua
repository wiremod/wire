AddCSLuaFile()

-- HL-ZASM
AddCSLuaFile("wire/client/hlzasm/hc_compiler.lua")
AddCSLuaFile("wire/client/hlzasm/hc_opcodes.lua")
AddCSLuaFile("wire/client/hlzasm/hc_expression.lua")
AddCSLuaFile("wire/client/hlzasm/hc_preprocess.lua")
AddCSLuaFile("wire/client/hlzasm/hc_syntax.lua")
AddCSLuaFile("wire/client/hlzasm/hc_codetree.lua")
AddCSLuaFile("wire/client/hlzasm/hc_optimize.lua")
AddCSLuaFile("wire/client/hlzasm/hc_output.lua")
AddCSLuaFile("wire/client/hlzasm/hc_tokenizer.lua")

-- ZVM
AddCSLuaFile("wire/zvm/zvm_core.lua")
AddCSLuaFile("wire/zvm/zvm_features.lua")
AddCSLuaFile("wire/zvm/zvm_opcodes.lua")
AddCSLuaFile("wire/zvm/zvm_data.lua")

AddCSLuaFile("wire/cpulib.lua")
include("wire/cpulib.lua")

AddCSLuaFile("wire/gpulib.lua")
include("wire/gpulib.lua")

AddCSLuaFile("wire/cpu_default_data_decompressor.lua")
include("wire/cpu_default_data_decompressor.lua")

AddCSLuaFile("wire/cpu_default_data_files.lua")

if CLIENT then
	include("wire/client/hlzasm/hc_compiler.lua")
end