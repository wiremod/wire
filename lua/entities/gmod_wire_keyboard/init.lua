AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("remap.lua")

include('shared.lua')
include('remap.lua')

ENT.WireDebugName = "Wired Keyboard"

local All_Enums = {} -- table containing key -> key enum conversion

-- Add a few common keys
for i=48,57 do -- 0 -> 9
	All_Enums[i] = _G["KEY_" .. string.char(i)]
end
for i=65,90 do -- A -> Z
	All_Enums[i] = _G["KEY_" .. string.upper(string.char(i))]
end
for i=97,122 do -- a -> z
	All_Enums[i] = _G["KEY_" .. string.upper(string.char(i))]
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	self.Inputs = WireLib.CreateInputs( self, { "Kick the bastard out of keyboard" } )
	self.Outputs = WireLib.CreateOutputs( self, { "Memory", "User [ENTITY]", "InUse" } )

	self.ActiveKeys = {} -- table containing all currently active keys, used to see when keys are pressed/released
	self.Buffer = {} -- array containing all currently active keys, value is ascii
	self.BufferLookup = {} -- lookup table mapping enums to buffer positions
	self.Buffer[0] = 0

	self:SetOverlayText( "Not in use" )
	WireLib.TriggerOutput( self, "InUse", 0 )
end

function ENT:TriggerInput( name, value )
	if name == "Kick the bastard out of keyboard" then
		self.Locked = (value ~= 0)
		self:PlayerDetach()
	end
end

function ENT:ReadCell( Address )
	if Address >= 0 and Address < 32 then
		return self.Buffer[Address] or 0
	elseif Address >= 32 and Address < 256 then
		return self:IsPressedAscii( Address - 32 ) and 1 or 0
	end

	return 0
end

function ENT:WriteCell( Address, value )
	if Address == 0 then
		self:UnshiftBuffer() -- User wants to remove the first key in the buffer
	else
		self:RemoveFromBufferByKey( value )
	end

	return false
end

util.AddNetworkString("wire_keyboard_blockinput")
util.AddNetworkString("wire_keyboard_activatemessage")
function ENT:PlayerAttach( ply )
	if not IsValid(ply) or IsValid(self.ply) then return end -- If the keyboard is already in use, don't attach the player

	if IsValid(ply.WireKeyboard) then -- If the player is already using a different keyboard
		if ply.WireKeyboard == self then return end -- If the keyboard is this keyboard, don't re-attach the player
		ply.WireKeyboard:PlayerDetach() -- If it's another keyboard, detach the player from that keyboard first
	end

	-- If the keyboard is locked (Kick input is wired to something other than 0), don't attach the player
	if self.Locked then return end

	-- Store player
	self.ply = ply
	WireLib.TriggerOutput( self, "User", ply )
	WireLib.TriggerOutput( self, "InUse", 1 )
	self:SetOverlayText("In use by " .. ply:Nick())

	-- Block keyboard input
	if ply:GetInfoNum("wire_keyboard_sync", 1) == 1 then net.Start( "wire_keyboard_blockinput" ) net.WriteBit(true) net.Send(ply) end
	local leavekey = ply:GetInfoNum("wire_keyboard_leavekey", KEY_LALT)

	net.Start("wire_keyboard_activatemessage")
		net.WriteBit(IsValid(self.Pod))
		net.WriteUInt(leavekey, 16)
	net.Send(ply)

	-- Set the wire keyboard value on the player
	ply.WireKeyboard = self

	-- Ignore the first key (the "Use" key - default "e" - pressed when entering the keyboard)
	self.IgnoreFirstKey = true

	-- Reset tables
	self.BufferLookup = {}
	self.ActiveKeys = {}
	self.Buffer = {}
	self.Buffer[0] = 0
end

function ENT:PlayerDetach()
	WireLib.TriggerOutput( self, "User", nil )
	WireLib.TriggerOutput( self, "InUse", 0 )

	self:SetOverlayText("Not in use")
	
	local ply = self.ply
	self.ply = nil

	-- Kick player out of vehicle, if in one
	if IsValid(self.Pod) and IsValid(self.Pod:GetDriver()) and self.Pod:GetDriver() == ply then
		self.Pod:GetDriver():ExitVehicle()
	end
	
	if IsValid(ply) then 
		net.Start( "wire_keyboard_blockinput" ) net.WriteBit(false) net.Send(ply)
		ply.WireKeyboard = nil 
	end
end

function ENT:Use( ply )
	if IsValid(self.Pod) then
		ply:ChatPrint( "This keyboard is linked to a pod. Please use the pod instead." )
		return
	end

	self:PlayerAttach( ply )
end

function ENT:OnRemove()
	self:LinkPod( nil, true )
	self:PlayerDetach()
	self.BaseClass.OnRemove(self)
end

function ENT:LinkPod( pod, silent )
	if not IsValid(pod) then
		if IsValid(self.Pod) then
			self.Pod.WireKeyboard = nil
			self.Pod = nil
		end
	else
		if IsValid(self.Pod) and self.Pod == pod then return end

		pod.WireKeyboard = self
		self.Pod = pod
	end
end

hook.Add( "PlayerEnteredVehicle", "Wire_Keyboard_PlayerEnteredVehicle", function( ply, pod )
	if IsValid(pod.WireKeyboard) then
		pod.WireKeyboard:PlayerAttach( ply )
	end
end)

hook.Add("PlayerLeaveVehicle", "wire_keyboard_PlayerLeaveVehicle", function( ply, pod )
	if IsValid(pod.WireKeyboard) and pod.WireKeyboard.ply == ply then
		pod.WireKeyboard:PlayerDetach()
	end
end)

//local Wire_Keyboard_Remap = Wire_Keyboard_Remap // Defined in remap.lua
function ENT:GetRemappedKey( key_enum )
	if not key_enum or key_enum == 0 or key_enum > KEY_LAST then return 0 end -- Above KEY_LAST are joystick and mouse enums

	local layout = "American"
	if IsValid(self.ply) then layout = self.ply:GetInfo("wire_keyboard_layout", "American") end
	local current = Wire_Keyboard_Remap[layout]
	if (!current) then return 0 end

	local ret = current.normal[key_enum]

	-- Check if a special key is being held down (such as SHIFT)
	for k,v in pairs( self.ActiveKeys ) do
		if (v == true and current[k] and current[k][key_enum]) then
			ret = current[k][key_enum]
		end
	end

	if isstring(ret) then ret = string.byte(ret) end
	return ret
end

function ENT:KeyPressed( key_enum )
	local key = self:GetRemappedKey(key_enum)
	if key == nil or key == 0 then return end

	if not All_Enums[key] then All_Enums[key] = key_enum end
	
	self.ActiveKeys[key_enum] = true
	self:PushBuffer( key, key_enum )
	
	WireLib.TriggerOutput( self, "Memory", key )
end

function ENT:KeyReleased( key_enum )
	local key = self:GetRemappedKey(key_enum)
	if key == nil or key == 0 then return end

	self.ActiveKeys[key_enum] = nil

	if self.AutoBuffer then
		self:RemoveFromBufferByKey( key )
	end
	
	WireLib.TriggerOutput( self, "Memory", 0 )
end

function ENT:IsPressedEnum( key_enum )
	return self.ActiveKeys[key_enum]
end

function ENT:IsPressedAscii( key )
	local key_enum = All_Enums[key]
	if not key_enum then return false end
	return self:IsPressedEnum( key_enum )
end

function ENT:UnshiftBuffer()
	self:RemoveFromBufferByPosition( 1 )
end

function ENT:PushBuffer( key, key_enum )
	self.Buffer[0] = self.Buffer[0] + 1
	self.Buffer[self.Buffer[0]] = key
	
	if not self.BufferLookup[key_enum] then self.BufferLookup[key_enum] = {} end
	local positions = self.BufferLookup[key_enum]
	positions[#positions+1] = self.Buffer[0]
end

function ENT:RemoveFromBufferByPosition( bufferpos )
	if self.Buffer[0] <= 0 then return end
	local key = table.remove( self.Buffer, bufferpos )
	self.Buffer[0] = self.Buffer[0] - 1
	
	-- Move all remaining keys down one step
	for key_enum,positions in pairs( self.BufferLookup ) do
		for k,pos in pairs( positions ) do
			if bufferpos < pos then
				positions[k] = positions[k] - 1
			end
		end
	end
end

function ENT:RemoveFromBufferByKey( key )
	local key_enum = All_Enums[key]
	if not key_enum then return false end -- key is invalid
	
	local positions = self.BufferLookup[key_enum]
	if not positions then return false end -- error, shouldn't happen
	local bufferpos = table.remove( positions, 1 )
	if not bufferpos then return false end -- error, shouldn't happen
	
	self:RemoveFromBufferByPosition( bufferpos )
end

function ENT:Think()
	if not IsValid(self.ply) then
		self:NextThink( CurTime() + 0.3 ) -- Don't need to update as often
	else
		if self.IgnoreFirstKey then -- Don't start listening to keys until Use is released
			if not self.ply.keystate[KEY_E] then self.IgnoreFirstKey = nil end
		else
			local leavekey = self.ply:GetInfoNum("wire_keyboard_leavekey", KEY_LALT)

			-- Remove lifted up keys from our ActiveKeys
			for key_enum, bool in pairs(self.ActiveKeys) do
				if not self.ply.keystate[key_enum] then
					self:KeyReleased( key_enum )
				end
			end

			-- Check for newly pressed keys and add them to our ActiveKeys
			for key_enum, bool in pairs(self.ply.keystate) do
				if (key_enum == leavekey) then
					if leavekey ~= KEY_ALT or not self:IsPressedEnum( KEY_LCONTROL ) then -- if LCONTROL and LALT are being pressed, then the player is trying to use the "ALT GR" key which is available for some languages
						self:PlayerDetach() -- Pressing the leave key quits the keyboard
						break
					end
				end
				
				if not self:IsPressedEnum( key_enum ) then
					self:KeyPressed( key_enum )
				end
			end
		end
		self:NextThink( CurTime() )
	end
	return true
end

function ENT:Setup(autobuffer)
	self.AutoBuffer = autobuffer
end

if (SERVER) then
	function MakeWireKeyboard( pl, Pos, Ang, model, autobuffer )
		if ( !pl:CheckLimit( "wire_keyboards" ) ) then return false end

		local wire_keyboard = ents.Create( "gmod_wire_keyboard" )
		if (!wire_keyboard:IsValid()) then return false end

		wire_keyboard:SetAngles( Ang )
		wire_keyboard:SetPos( Pos )
		wire_keyboard:SetModel( Model(model or "models/jaanus/wiretool/wiretool_input.mdl") )
		wire_keyboard:Spawn()

		wire_keyboard:SetPlayer( pl )
		wire_keyboard.pl = pl
		wire_keyboard:Setup(autobuffer)

		pl:AddCount( "wire_keyboards", wire_keyboard )

		return wire_keyboard
	end
	duplicator.RegisterEntityClass("gmod_wire_keyboard", MakeWireKeyboard, "Pos", "Ang", "Model", "AutoBuffer")
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.Pod) then
	    info.pod = self.Pod:EntIndex()
		info.autobuffer = self.AutoBuffer
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if info.pod then
		local LinkedPod = GetEntByID(info.pod)
		if !LinkedPod then
			LinkedPod = ents.GetByIndex(info.pod)
		end
		self:LinkPod(LinkedPod, true)
	end

	if info.autobuffer ~= nil then
		self.AutoBuffer = info.autobuffer
	else
		self.AutoBuffer = false
	end
end
