ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire FX Emitter"
ENT.Author         = "Team garry / ZeikJT"
ENT.Contact        = ""
ENT.Purpose        = ""
ENT.Instructions   = ""

ENT.Spawnable      = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "On" )
	self:NetworkVar( "Int", 0, "Effect" )
	self:NetworkVar( "Float", 0, "Delay" )
	self:NetworkVar( "Vector", 0, "FXDir" )
end

function ENT:GetFXPos()
	return self:GetPos()
end


-- Effect registration

ENT.Effects				= {}
ENT.fxcount = 0
local fx_emitter = ENT

ComboBox_Wire_FX_Emitter_Options = {}

function AddFXEmitterEffect(name, func, nicename)
	fx_emitter.fxcount = fx_emitter.fxcount+1
	// Maintain a global reference for these effects
	ComboBox_Wire_FX_Emitter_Options[name] = fx_emitter.fxcount
	if CLIENT then
		fx_emitter.Effects[fx_emitter.fxcount] = func
		language.Add( "wire_fx_emitter_"..name, nicename )
	end
end

-- Modular effect adding.. stuff
include( "fx_default.lua" )
