DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire Expression 2"
ENT.Author = "Syranide"
ENT.Contact = "me@syranide.com"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "Expression 2"

CreateConVar("wire_expression2_unlimited", "0", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotasoft", "10000", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotahard", "100000", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotatick", "25000", {FCVAR_REPLICATED})

include("core/e2lib.lua")
include("base/preprocessor.lua")
include("base/tokenizer.lua")
include("base/parser.lua")
include("base/optimizer.lua")
include("base/compiler.lua")
include('core/init.lua')
