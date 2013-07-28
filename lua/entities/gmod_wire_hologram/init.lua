AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetSolid( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:DrawShadow( false )

end
