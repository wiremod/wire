ENT.Type			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Spawnable		= false
ENT.AdminSpawnable  = false
ENT.PrintName		= "Text Entry (Wire)"
ENT.Category 		= "Wiremod"
ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT
ENT.Model			= "models/beer/wiremod/keyboard.mdl"

function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Delay")
end