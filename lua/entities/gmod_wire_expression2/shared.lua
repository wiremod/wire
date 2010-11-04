ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Expression 2"
ENT.Author          = "Syranide"
ENT.Contact         = "me@syranide.com"
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


include("core/e2lib.lua")
include("base/preprocessor.lua")
include("base/tokenizer.lua")
include("base/parser.lua")
include("base/compiler.lua")
include('core/init.lua')

/********************************** Player Disconnection **********************************/

-- This code converts the player variable to a string, which is then converted back if the player rejoins and tries to access their E2 again.
-- This fixes the bug that you have to respawn your E2 after rejoining.
-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved","Wire_Expression2_Player_Disconnected",function(ent)
	if (ent and ent:IsPlayer()) then
		for k,v in ipairs( ents.FindByClass("gmod_wire_expression2") ) do
			if (v.player == ent) then
				if (SERVER) then
					v:SetOverlayText("Expression 2\n" .. v.name .. "\n(Owner disconnected.)")
					local r,g,b,a = v:GetColor()
					v:SetColor(255, 0, 0, a)

					v.error = true
				end

				v.player = ent:UniqueID()
			end
		end
	end
end)
