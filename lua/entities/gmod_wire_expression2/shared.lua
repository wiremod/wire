DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName = "Wire Expression 2"
ENT.Author = ""
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""

ENT.WireDebugName = "Expression 2"

CreateConVar("wire_expression2_unlimited", "0", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotasoft", "10000", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotahard", "100000", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotatick", "25000", {FCVAR_REPLICATED})
CreateConVar("wire_expression2_quotatime", "-1", {FCVAR_REPLICATED}, "Time in (ms) the e2 can consume before killing (-1 is infinite)")

include("core/e2lib.lua")
include("base/debug.lua")
include("base/preprocessor.lua")
include("base/tokenizer.lua")
include("base/parser.lua")

include("base/compiler.lua")
include("core/init.lua")
