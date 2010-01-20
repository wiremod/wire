-- shared part --

ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire GPULib Controller"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

if SERVER then return end

-- client part --

ENT.RenderGroup 		= RENDERGROUP_BOTH
