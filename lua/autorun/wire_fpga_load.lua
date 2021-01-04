if SERVER then MsgC(Color(0, 150, 255), "Loading Wire FPGA...\n") end

if SERVER then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")
  AddCSLuaFile("wire/tool_loader.lua")
  AddCSLuaFile("wire/fpgagates.lua")
end

include("wire/fpgagates.lua")

if CLIENT then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")
  AddCSLuaFile("wire/tool_loader.lua")

  include("wire/client/node_editor/nodeeditor.lua")
  include("wire/client/node_editor/wire_fpga_editor.lua")
end

if SERVER then MsgC(Color(0, 150, 255), "Wire FPGA loaded!\n") end