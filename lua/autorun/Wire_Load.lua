-- $Rev: 1663 $
-- $LastChangedDate: 2009-09-12 03:34:53 -0700 (Sat, 12 Sep 2009) $
-- $LastChangedBy: TomyLobo $

if VERSION < 70 then Error("WireMod: Your GMod is years too old. Load aborted.\n") end

if SERVER then
	-- this file
	AddCSLuaFile("autorun/Wire_Load.lua")

	-- shared includes
	AddCSLuaFile("wire/WireShared.lua")
	AddCSLuaFile("wire/UpdateCheck.lua")
	AddCSLuaFile("wire/Beam_NetVars.lua")
	AddCSLuaFile("wire/WireGates.lua")
	AddCSLuaFile("wire/WireMonitors.lua")
	AddCSLuaFile("wire/opcodes.lua")
	AddCSLuaFile("wire/GPULib.lua")

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

	-- resource files
	for i=1,32 do
		resource.AddFile("settings/render_targets/WireGPU_RT_"..i..".txt")
	end
	resource.AddFile("materials/expression 2/cog.vtf")
	resource.AddFile("materials/expression 2/cog.vmt")
	resource.AddSingleFile("materials/expression 2/cog_world.vmt")
end

-- shared includes
include("wire/WireShared.lua")
include("wire/UpdateCheck.lua")
include("wire/Beam_NetVars.lua")
include("wire/WireGates.lua")
include("wire/WireMonitors.lua")
include("wire/opcodes.lua")
include("wire/GPULib.lua")

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
	include("wire/client/cl_gpulib.lua")
	include("wire/client/WireDermaExts.lua")
	include("wire/client/WireMenus.lua")
	include("wire/client/toolscreen.lua")
	include("wire/client/TextEditor.lua")
	include("wire/client/wire_expression2_browser.lua")
	include("wire/client/wire_expression2_editor.lua")
	include("wire/client/e2helper.lua")
	include("wire/client/e2descriptions.lua")
	include("wire/client/gmod_tool_auto.lua")
end
