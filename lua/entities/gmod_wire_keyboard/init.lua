AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("remap.lua")

include('shared.lua')

ENT.WireDebugName = "Wired Keyboard"

local All_Enums = {} -- table containing key -> key enum conversion

-- Add a few common keys
for i=48,57 do -- 0 -> 9
	All_Enums[i] = _E["KEY_" .. string.char(i)]
end
for i=65,90 do -- A -> Z
	All_Enums[i] = _E["KEY_" .. string.upper(string.char(i))]
end
for i=97,122 do -- a -> z
	All_Enums[i] = _E["KEY_" .. string.upper(string.char(i))]
end

------------------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------
-- TriggerInput
------------------------------------------------------------------------------------------
function ENT:TriggerInput( name, value )
	if name == "Kick the bastard out of keyboard" then
		self.Locked = (value ~= 0)
		self:PlayerDetach()
	end
end

------------------------------------------------------------------------------------------
-- ReadCell
------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------
-- WriteCell
------------------------------------------------------------------------------------------
function ENT:WriteCell( Address, value )
	if Address == 0 then
		return self:Switch( -1, nil )
	else
		self:Switch( value, nil )
	end

	return false
end

------------------------------------------------------------------------------------------
-- PlayerAttach
------------------------------------------------------------------------------------------
function ENT:PlayerAttach( ply )
	if not ply or not ply:IsValid() then return end -- Invalid player
	if self.ply and self.ply:IsValid() then return end -- If the keyboard is already in use, don't attach the player

	if ply.WireKeyboard and ply.WireKeyboard:IsValid() then -- If the player is already using a different keyboard
		if ply.WireKeyboard == self then return end -- If the keyboard is this keyboard, don't re-attach the player
		ply.WireKeyboard:PlayerDetach() -- If it's another keyboard, detach the player from that keyboard first
	end

	-- If the keyboard is locked (Kick input is wired to something other than 0), don't attach the player
	if self.Locked then return end

	-- Store player
	self.ply = ply

	-- Update wire outputs
	WireLib.TriggerOutput( self, "User", ply )
	WireLib.TriggerOutput( self, "InUse", 1 )

	-- Update status text
	self:SetOverlayText("In use by " .. ply:Nick())

	-- Block keyboard input
	umsg.Start( "wire_keyboard_blockinput", ply ) umsg.End()

	-- Check for pod
	if self.Pod and self.Pod:IsValid() then
		ply:ChatPrint( "This pod is linked to a keyboard - press ALT to leave." )
	else
		ply:ChatPrint( "Keyboard turned on - press ALT to leave." )
	end

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
	if self.Pod and self.Pod:IsValid() then
		ply:ChatPrint( "This keyboard is linked to a pod. Please use the pod instead." )
		return
	end

	self:PlayerAttach( ply )
end

function ENT:OnRemove()
	self:LinkPod( nil, true )
	self:PlayerDetach()
end

------------------------------------------------------------------------------------------
-- PlayerDetach
------------------------------------------------------------------------------------------
function ENT:PlayerDetach()
	if not self.ply or not self.ply:IsValid() then return end -- If the keyboard isn't linked to a player

	-- Clear values
	self.ply.WireKeyboard = nil
	self.ply = nil

	-- Clear wire outputs
	WireLib.TriggerOutput( self, "User", nil )
	WireLib.TriggerOutput( self, "InUse", 0 )

	-- Update status text
	self:SetOverlayText("Not in use." )

	-- Kick player out of vehicle, if in one
	if self.Pod and self.Pod:IsValid() and self.Pod:GetDriver() and self.Pod:GetDriver():IsValid() then
		self.Pod:GetDriver():ExitVehicle()
	end
end

------------------------------------------------------------------------------------------
-- LinkPod
------------------------------------------------------------------------------------------
function ENT:LinkPod( pod, silent )
	if not pod or not pod:IsValid() then
		if self.Pod and self.Pod:IsValid() then
			self.Pod.WireKeyboard = nil
			self.Pod = nil
		end
	else
		if self.Pod and self.Pod:IsValid() and self.Pod == pod then return end

		pod.WireKeyboard = self
		self.Pod = pod
	end
end

hook.Add( "PlayerEnteredVehicle", "Wire_Keyboard_PlayerEnteredVehicle", function( ply, pod )
	if pod.WireKeyboard and pod.WireKeyboard:IsValid() then
		pod.WireKeyboard:PlayerAttach( ply )
	end
end)

hook.Add("PlayerLeaveVehicle", "wire_keyboard_PlayerLeaveVehicle", function( ply, pod )
	if pod.WireKeyboard and pod.WireKeyboard:IsValid() then
		pod.WireKeyboard:PlayerDetach()
	end
end)

------------------------------------------------------------------------------------------
-- Switch
------------------------------------------------------------------------------------------
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

concommand.Add("wire_keyboard_press", function(ply, cmd, args)
	if 	not ply.WireKeyboard or not ply.WireKeyboard:IsValid() or -- If the player isn't using a keyboard
		not ply.WireKeyboard.ply or not ply.WireKeyboard.ply:IsValid() or ply.WireKeyboard.ply ~= ply then -- If the attached player does not match this player

		umsg.Start( "wire_keyboard_releaseinput", ply ) umsg.End() -- Release their input in case they got stuck or something
		return
	end

	local keyboard = ply.WireKeyboard

	if keyboard.IgnoreFirstKey then
		keyboard.IgnoreFirstKey = nil
		return
	end

	local ascii = tonumber(args[2])
	local key_enum = tonumber(args[3])

	if (key_enum == KEY_LALT and args[1] == "p" and not keyboard.ActiveKeys[KEY_LCONTROL]) then -- if LCONTROL is being pressed, then the player is trying to use the "ALT GR" key which is available for some languages
		keyboard:PlayerDetach()
		return
	end

	keyboard:Switch( ascii, key_enum, args[1] == "p" )
end)

------------------------------------------------------------------------------------------
-- Duplication support
------------------------------------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if self.Pod and self.Pod:IsValid() then
	    info.pod = self.Pod:EntIndex()
	end
	info.autobuffer = self.AutoBuffer
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
