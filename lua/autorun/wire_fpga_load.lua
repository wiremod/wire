if SERVER then MsgC(Color(50, 180, 50), "Loading Wire FPGA...\n") end

if SERVER then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")
  AddCSLuaFile("wire/fpgagates.lua")
  AddCSLuaFile("wire/cpugates.lua")
end

include("wire/fpgagates.lua")
include("wire/cpugates.lua")

if CLIENT then
  AddCSLuaFile("wire/client/node_editor/nodeeditor.lua")
  AddCSLuaFile("wire/client/node_editor/wire_fpga_editor.lua")

  include("data/help.lua")

  include("wire/client/node_editor/nodeeditor.lua")
  include("wire/client/node_editor/wire_fpga_editor.lua")

  -- Add dir
  file.CreateDir("fpgachip")
  -- Add default files
  if not file.Exists("fpgachip/_helloworld_.txt", "DATA") then
    local data = file.Read("data/_helloworld_.lua", "LUA")
    print(data)
    if data ~= nil then
      file.Write("fpgachip/_helloworld_.txt", string.sub(data, 3))
    end
  end
end

if SERVER then MsgC(Color(50, 180, 50), "Wire FPGA loaded!\n") end