DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire Expression 2"
ENT.Author = "Syranide"
ENT.Contact = "me@syranide.com"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "Expression 2"

ENT.RenderGroup = RENDERGROUP_OPAQUE

include("core/e2lib.lua")
include("base/preprocessor.lua")
include("base/tokenizer.lua")
include("base/parser.lua")
include("base/compiler.lua")
include('core/init.lua')
