--[[
Copyright 2013 Wiremod Developers
https://github.com/wiremod/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--

if VERSION < 140403 and VERSION > 5 then
	-- VERSION > 5 check added June 2013, to address issues regarding the Steampipe update sometimes setting VERSION to 1.
	ErrorNoHalt("WireMod: This branch of wiremod only supports Gmod13+.\n")
	return
end

if SERVER then
	-- this file
	AddCSLuaFile("autorun/wire_load.lua")

	-- shared includes
	AddCSLuaFile("wire/wire_paths.lua")
	AddCSLuaFile("wire/wireshared.lua")
	AddCSLuaFile("wire/wirenet.lua")
	AddCSLuaFile("wire/wiregates.lua")
	AddCSLuaFile("wire/fpgagates.lua")
	AddCSLuaFile("wire/cpugates.lua")
	AddCSLuaFile("wire/wiremonitors.lua")
	AddCSLuaFile("wire/cpulib.lua")
	AddCSLuaFile("wire/gpulib.lua")
	AddCSLuaFile("wire/timedpairs.lua")
	AddCSLuaFile("wire/default_data_generator.lua")
	AddCSLuaFile("wire/flir.lua")
	AddCSLuaFile("wire/von.lua")
	AddCSLuaFile("wire/sh_modelplug.lua")

	-- client includes
	AddCSLuaFile("wire/client/cl_wirelib.lua")
	AddCSLuaFile("wire/client/cl_modelplug.lua")
	AddCSLuaFile("wire/client/cl_wire_map_interface.lua")
	AddCSLuaFile("wire/client/wiredermaexts.lua")
	AddCSLuaFile("wire/client/wiremenus.lua")
	AddCSLuaFile("wire/client/wire_expression2_browser.lua")
	AddCSLuaFile("wire/client/wire_filebrowser.lua")
	AddCSLuaFile("wire/client/wire_listeditor.lua")
	AddCSLuaFile("wire/client/wire_soundpropertylist.lua")
	AddCSLuaFile("wire/client/e2helper.lua")
	AddCSLuaFile("wire/client/e2descriptions.lua")
	AddCSLuaFile("wire/client/e2_extension_menu.lua")
	AddCSLuaFile("wire/client/e2_viewrequest_menu.lua")
	AddCSLuaFile("wire/client/gmod_tool_auto.lua")
	AddCSLuaFile("wire/client/sound_browser.lua")
	AddCSLuaFile("wire/client/thrusterlib.lua")
	AddCSLuaFile("wire/client/rendertarget_fix.lua")
	AddCSLuaFile("wire/client/customspawnmenu.lua")

	-- text editor
	AddCSLuaFile("wire/client/text_editor/issue_viewer.lua")
	AddCSLuaFile("wire/client/text_editor/texteditor.lua")
	AddCSLuaFile("wire/client/text_editor/wire_expression2_editor.lua")

	-- node editor
	AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
	AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")

	-- hl-zasm
	AddCSLuaFile("wire/client/hlzasm/hc_compiler.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_opcodes.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_expression.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_preprocess.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_syntax.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_codetree.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_optimize.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_output.lua")
	AddCSLuaFile("wire/client/hlzasm/hc_tokenizer.lua")

	-- zvm
	AddCSLuaFile("wire/zvm/zvm_core.lua")
	AddCSLuaFile("wire/zvm/zvm_features.lua")
	AddCSLuaFile("wire/zvm/zvm_opcodes.lua")
	AddCSLuaFile("wire/zvm/zvm_data.lua")

	for _, filename in ipairs(file.Find("wire/client/text_editor/modes/*.lua","LUA")) do
		AddCSLuaFile("wire/client/text_editor/modes/" .. filename)
	end
end

-- shared includes
include("wire/sh_modelplug.lua")
include("wire/wireshared.lua")
include("wire/wirenet.lua")
include("wire/wire_paths.lua")
include("wire/wiregates.lua")
include("wire/fpgagates.lua")
include("wire/cpugates.lua")
include("wire/wiremonitors.lua")
include("wire/cpulib.lua")
include("wire/gpulib.lua")
include("wire/timedpairs.lua")
include("wire/default_data_generator.lua")
include("wire/flir.lua")
include("wire/von.lua")

-- server includes
if SERVER then
	include("wire/server/wirelib.lua")
	include("wire/server/debuggerlib.lua")
	include("wire/server/sents_registry.lua")
	include("wire/server/wire_map_interface.lua")
	include("wire/zvm/zvm_tests.lua")

	if CreateConVar("wire_force_workshop", "1", FCVAR_ARCHIVE, "Should Wire force all clients to download the Workshop edition of Wire, for models? (requires restart to disable)"):GetBool() then
		if select(2, WireLib.GetVersion()):find("Workshop", 1, true) then
			resource.AddWorkshop("160250458")
		else
			resource.AddWorkshop("3066780663")
		end
	end
end

-- client includes
if CLIENT then
	include("wire/client/cl_wirelib.lua")
	include("wire/client/cl_modelplug.lua")
	include("wire/client/cl_wire_map_interface.lua")
	include("wire/client/wiredermaexts.lua")
	include("wire/client/wiremenus.lua")
	include("wire/client/text_editor/texteditor.lua")
	include("wire/client/wire_expression2_browser.lua")
	include("wire/client/text_editor/issue_viewer.lua")
	include("wire/client/text_editor/wire_expression2_editor.lua")
	include("wire/client/wire_filebrowser.lua")
	include("wire/client/wire_listeditor.lua")
	include("wire/client/wire_soundpropertylist.lua")
	include("wire/client/e2helper.lua")
	include("wire/client/e2descriptions.lua")
	include("wire/client/e2_extension_menu.lua")
	include("wire/client/e2_viewrequest_menu.lua")
	include("wire/client/gmod_tool_auto.lua")
	include("wire/client/sound_browser.lua")
	include("wire/client/thrusterlib.lua")
	include("wire/client/rendertarget_fix.lua")
	include("wire/client/customspawnmenu.lua")
	include("wire/client/node_editor/nodeeditor.lua")
	include("wire/client/node_editor/wire_fpga_editor.lua")
	include("wire/client/hlzasm/hc_compiler.lua")
end

if SERVER then print("Wiremod " .. select(2, WireLib.GetVersion()) .. " loaded") end
