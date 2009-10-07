ENT.Type            = "anim"
ENT.Base            = "base_anim"

ENT.PrintName       = "Wire Hologram"
ENT.Author          = "I am McLovin"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


-- copy some functions from base_gmodentity
local ENT = ENT
hook.Add("InitPostEntity", "gmod_wire_hologram_shared", function()
	base_gmodentity = scripted_ents.GetList().base_gmodentity.t

	ENT.SetPlayer = base_gmodentity.SetPlayer
	ENT.GetPlayer = base_gmodentity.GetPlayer
end)
