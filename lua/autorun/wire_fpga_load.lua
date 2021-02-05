if SERVER then MsgC(Color(50, 180, 50), "Loading Wire FPGA...\n") end

if SERVER then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")
  AddCSLuaFile("wire/fpgagates.lua")
end

include("wire/fpgagates.lua")

if CLIENT then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")

  include("wire/client/node_editor/nodeeditor.lua")
  include("wire/client/node_editor/wire_fpga_editor.lua")
end

if SERVER then MsgC(Color(50, 180, 50), "Wire FPGA loaded!\n") end