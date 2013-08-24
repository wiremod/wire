AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Numpad Output"
ENT.WireDebugName = "Numpad Output"

if CLIENT then return end -- No more client

local keylist = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","KP_INS","KP_END","KP_DOWNARROW","KP_PGDN","KP_LEFTARROW","KP_5","KP_RIGHTARROW","KP_HOME","KP_UPARROW","KP_PGUP","KP_SLASH","KP_MULTIPLY","KP_MINUS","KP_PLUS","KP_ENTER","KP_DEL","[","]","SEMICOLON","'","`",",",".","/","\\","-","=","ENTER","SPACE","BACKSPACE","TAB","CAPSLOCK","NUMLOCK","ESCAPE","SCROLLLOCK","INS","DEL","HOME","END","PGUP","PGDN","PAUSE","SHIFT","RSHIFT","ALT","RALT","CTRL","RCTRL","LWIN","RWIN","APP","UPARROW","LEFTARROW","DOWNARROW","RIGHTARROW","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","CAPSLOCKTOGGLE","NUMLOCKTOGGLE","SCROLLLOCKTOGGLE"}

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetOn( false )

	self.Inputs = Wire_CreateInputs(self, { "A" })
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if ((value > 0) ~= self:IsOn()) then
			self:Switch(not self:IsOn(), self:GetPlayer())
		end
	end
end

function ENT:Switch( on, ply )
	local plyindex 	= self:GetPlayerIndex()
	local key 		= self:GetKey()
	if (not key) then return end

	if (on) then
		numpad.Activate( ply, key, true )
	else
		numpad.Deactivate( ply, key, true )
	end

	self:SetOn(on)
end

function ENT:ShowOutput()
	if (self.key) then
		self:SetOverlayText(keylist[self.key] or "")
	end
end

function ENT:Setup( key )
	if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(self:GetOwner(), key) end
	self.key = key
	self:ShowOutput()
end

function ENT:GetKey()
	return self.key
end

function ENT:SetOn( on )
	self.On = on
end

function ENT:IsOn()
	return self.On
end

duplicator.RegisterEntityClass("gmod_wire_output", WireLib.MakeWireEnt, "Data", "key")
