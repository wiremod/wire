-- $Rev: 1663 $
-- $LastChangedDate: 2009-09-12 03:34:53 -0700 (Sat, 12 Sep 2009) $
-- $LastChangedBy: TomyLobo $

if VERSION < 119 then Error("WireMod: Your GMod is years too old. Load aborted.\n") end

if SERVER then
	-- this file
	AddCSLuaFile("autorun/Wire_Load.lua")

	-- shared includes
	AddCSLuaFile("wire/WireShared.lua")
	AddCSLuaFile("wire/UpdateCheck.lua")
	AddCSLuaFile("wire/Beam_NetVars.lua")
	AddCSLuaFile("wire/WireGates.lua")
	AddCSLuaFile("wire/WireMonitors.lua")
	AddCSLuaFile("wire/GPULib.lua")
	AddCSLuaFile("wire/CPULib.lua")

	-- client includes
	AddCSLuaFile("wire/client/cl_wirelib.lua")
	AddCSLuaFile("wire/client/cl_modelplug.lua")
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
	AddCSLuaFile("wire/welcome_menu.lua")
	AddCSLuaFile("wire/client/welcome_menu_derma.lua")
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

	-- resource files
	for i=1,32 do
		resource.AddSingleFile("settings/render_targets/WireGPU_RT_"..i..".txt")
	end
	resource.AddSingleFile("materials/expression 2/cog.vtf")
	resource.AddSingleFile("materials/expression 2/cog.vmt")
	resource.AddSingleFile("materials/gui/silkicons/page_white_add.vmt")
	resource.AddSingleFile("materials/gui/silkicons/page_white_add.vtf")
	resource.AddSingleFile("materials/gui/silkicons/page_white_delete.vmt")
	resource.AddSingleFile("materials/gui/silkicons/page_white_delete.vtf")
	resource.AddSingleFile("materials/wirelogo.vmt")
	resource.AddSingleFile("materials/wirelogo.vtf")
	resource.AddSingleFile("materials/expression 2/cog_world.vmt")
end

-- shared includes
include("wire/WireShared.lua")
include("wire/UpdateCheck.lua")
include("wire/Beam_NetVars.lua")
include("wire/WireGates.lua")
include("wire/WireMonitors.lua")
include("wire/GPULib.lua")
include("wire/CPULib.lua")
include("wire/welcome_menu.lua")

if CLIENT then
	include("wire/client/hlzasm/hc_compiler.lua")
end

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
	include("wire/client/welcome_menu_derma.lua")
	include("wire/client/rendertarget_fix.lua")
end
