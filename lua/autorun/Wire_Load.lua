if VERSION < 143 then
	ErrorNoHalt("WireMod: This branch of wiremod only supports Gmod13+.\n")
	return
end

if SERVER then
	-- this file
	AddCSLuaFile("autorun/Wire_Load.lua")

	-- shared includes
	AddCSLuaFile("wire/WireShared.lua")
	AddCSLuaFile("wire/Beam_NetVars.lua")
	AddCSLuaFile("wire/WireGates.lua")
	AddCSLuaFile("wire/WireMonitors.lua")
	AddCSLuaFile("wire/GPULib.lua")
	AddCSLuaFile("wire/CPULib.lua")
	AddCSLuaFile("wire/Timedpairs.lua")

	-- client includes
	AddCSLuaFile("wire/client/cl_wirelib.lua")
	AddCSLuaFile("wire/client/cl_modelplug.lua")
	AddCSLuaFile("wire/client/cl_wire_map_interface.lua")
	AddCSLuaFile("wire/client/WireDermaExts.lua")
	AddCSLuaFile("wire/client/WireMenus.lua")
	AddCSLuaFile("wire/client/TextEditor.lua")
	AddCSLuaFile("wire/client/toolscreen.lua")
	AddCSLuaFile("wire/client/wire_expression2_browser.lua")
	AddCSLuaFile("wire/client/wire_expression2_editor.lua")
	AddCSLuaFile("wire/client/e2helper.lua")
	AddCSLuaFile("wire/client/e2descriptions.lua")
	AddCSLuaFile("wire/client/gmod_tool_auto.lua")
	AddCSLuaFile("wire/client/sound_browser.lua")
	AddCSLuaFile("wire/client/rendertarget_fix.lua")

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

	AddCSLuaFile("von.lua")

	-- resource files
	for i=1,32 do
		resource.AddSingleFile("settings/render_targets/WireGPU_RT_"..i..".txt")
	end
	resource.AddFile("materials/expression 2/cog.vmt")
	resource.AddFile("materials/gui/silkicons/page_white_add.vmt")
	resource.AddFile("materials/gui/silkicons/page_white_delete.vmt")
	resource.AddFile("materials/wirelogo.vmt")
	resource.AddSingleFile("materials/expression 2/cog_world.vmt")
	resource.AddFile( "materials/gui/silkicons/folder.vmt" )
	resource.AddFile( "materials/gui/silkicons/computer.vmt" )
	resource.AddFile("materials/gui/silkicons/wrench.vtf")
	resource.AddFile("materials/vgui/spawnmenu/save.vtf")
	resource.AddFile("materials/gui/silkicons/help.vmt")
	resource.AddFile("materials/gui/silkicons/emoticon_smile.vtf")
	resource.AddFile("materials/gui/silkicons/newspaper.vtf")
end

-- shared includes
include("wire/WireShared.lua")
include("wire/Beam_NetVars.lua")
include("wire/WireGates.lua")
include("wire/WireMonitors.lua")
include("wire/GPULib.lua")
include("wire/CPULib.lua")
include("wire/Timedpairs.lua")
include("von.lua")

-- server includes
if SERVER then
	include("wire/server/WireLib.lua")
	include("wire/server/ModelPlug.lua")
	include("wire/server/radiolib.lua")
end

-- client includes
if CLIENT then
	include("wire/client/cl_wirelib.lua")
	include("wire/client/cl_modelplug.lua")
	include("wire/client/cl_wire_map_interface.lua")
	include("wire/client/WireDermaExts.lua")
	include("wire/client/WireMenus.lua")
	include("wire/client/toolscreen.lua")
	include("wire/client/TextEditor.lua")
	include("wire/client/wire_expression2_browser.lua")
	include("wire/client/wire_expression2_editor.lua")
	include("wire/client/e2helper.lua")
	include("wire/client/e2descriptions.lua")
	include("wire/client/gmod_tool_auto.lua")
	include("wire/client/sound_browser.lua")
	include("wire/client/rendertarget_fix.lua")
	include("wire/client/hlzasm/hc_compiler.lua")
end
