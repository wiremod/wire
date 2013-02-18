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

	self.ActiveKeyEnums = {} -- table indexed by key enums, value is position in buffer
	self.ActiveKeys = {} -- table indexed by ascii values, value is the key enum for that key
	self.Buffer = {} -- array containing all currently active keys, value is ascii
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
		local enum = All_Enums[Address - 32]
		if not enum then return 0 end -- Either this key is invalid, or it has never been pressed

		return self.ActiveKeys[enum] and 1 or 0
	end

	return 0
end

function ENT:WriteCell( Address, value )
	if Address == 0 then
		return self:Switch( -1, nil )
	else
		self:Switch( value, nil )
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
	self.ActiveKeyEnums = {}
	self.ActiveKeys = {}
	self.Buffer = {}
	self.Buffer[0] = 0
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

function ENT:PlayerDetach()
	WireLib.TriggerOutput( self, "User", nil )
	WireLib.TriggerOutput( self, "InUse", 0 )

	self:SetOverlayText("Not in use")

	-- Kick player out of vehicle, if in one
	if IsValid(self.Pod) and IsValid(self.Pod:GetDriver()) and self.Pod:GetDriver() == self.ply then
		self.Pod:GetDriver():ExitVehicle()
	end
	
	if IsValid(self.ply) then 
		net.Start( "wire_keyboard_blockinput" ) net.WriteBit(false) net.Send(self.ply)
		self.ply.WireKeyboard = nil 
	end
	self.ply = nil
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
	if IsValid(pod.WireKeyboard) then
		pod.WireKeyboard:PlayerDetach()
	end
end)

//local Wire_Keyboard_Remap = Wire_Keyboard_Remap // Defined in remap.lua
function ENT:GetRemappedKey( key )
	if (!key or key == 0) then return 0 end

	local layout = "American"
	if IsValid(self.ply) then layout = self.ply:GetInfo("wire_keyboard_layout", "American") end
	local current = Wire_Keyboard_Remap[layout]
	if (!current) then return "" end

	local ret = current.normal[key]

	-- Check if a special key is being held down (such as SHIFT)
	for k,v in pairs( self.ActiveKeys ) do
		if (v == true and current[k] and current[k][key]) then
			ret = current[k][key]
		end
	end

	if isstring(ret) then ret = string.byte(ret) end
	return ret
end

function ENT:Switch( key, key_enum, on )
	if not key then return false end -- Invalid key
	if key and key_enum then All_Enums[key] = key_enum end -- Add to list of keys

	local remove_from_buffer = self.AutoBuffer

	if key == -1 then -- User wants to remove the first key in the buffer
		key = self.Buffer[1]
		remove_from_buffer = true
	end

	if not key_enum then -- User wants to remove the specified key manually
		key_enum = All_Enums[key]
		if not key_enum then return false end -- That key is invalid
		remove_from_buffer = true
	end

	if on == true then
		-- Increase buffer count
		self.Buffer[0] = self.Buffer[0] + 1

		-- Save buffer position for this key
		local keyenums = self.ActiveKeyEnums[key_enum] or {}
		keyenums[#keyenums+1] = self.Buffer[0]
		self.ActiveKeyEnums[key_enum] = keyenums

		-- Save on/off state
		self.ActiveKeys[key_enum] = true

		-- Save to buffer
		self.Buffer[self.Buffer[0]] = key

		-- Trigger output
		WireLib.TriggerOutput( self, "Memory", key )
	else
		if remove_from_buffer then
			if not self.ActiveKeyEnums[key_enum] then return end -- error; this shouldn't happen

			-- Get buffer index from the lookup table
			local bufferindex = table.remove( self.ActiveKeyEnums[key_enum], 1 )
			if not bufferindex then return false end -- This key isn't in the buffer

			-- Remove key
			table.remove( self.Buffer, bufferindex )

			-- Move all remaining keys down one step
			for _, keyenum in pairs( self.ActiveKeyEnums ) do
				for k,v in pairs( keyenum ) do
					if v > bufferindex then
						keyenum[k] = v - 1
					end
				end
			end

			self.Buffer[0] = self.Buffer[0] - 1
		end

		-- Set active state to 'off'
		self.ActiveKeys[key_enum] = nil

		WireLib.TriggerOutput( self, "Memory", 0 )
	end
end

function ENT:Think()
	if not IsValid(self.ply) then
		self:NextThink( CurTime() + 0.3 ) -- Don't need to update as often
	else
		if self.IgnoreFirstKey then
			if not self.ply.keystate[KEY_E] then self.IgnoreFirstKey = nil end -- Don't start listening to keys until Use is released
		else
			local leavekey = self.ply:GetInfoNum("wire_keyboard_leavekey", KEY_LALT)

			-- Remove lifted up keys from our ActiveKeys
			for key_enum, bool in pairs(self.ActiveKeys) do
				if not self.ply.keystate[key_enum] then 
					self:Switch( self:GetRemappedKey(key_enum), key_enum, false )
				end
			end

			-- Check for newly pressed keys and add them to our ActiveKeys
			for key_enum, bool in pairs(self.ply.keystate) do
				if (key_enum == leavekey) then
					local detach = true
					if (leavekey == KEY_ALT and self.self.ActiveKeys[KEY_LCONTROL]) then detach = nil end -- if LCONTROL and LALT are being pressed, then the player is trying to use the "ALT GR" key which is available for some languages
					if (detach) then
						self:PlayerDetach() -- Pressing the leave key quits the keyboard
						continue
					end
				end

				if not self.ActiveKeys[key_enum] then self:Switch( self:GetRemappedKey(key_enum), key_enum, true ) end
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
		self.AutoBuffer = true
	end
end
