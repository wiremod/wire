AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("remap.lua")

include('shared.lua')
include('remap.lua')

ENT.WireDebugName = "Wired Keyboard"

local All_Enums = {} -- table containing key -> key enum conversion

-- Add a few common keys
for i = 48, 57 do -- 0 -> 9
	All_Enums[i] = _G["KEY_" .. string.char(i)]
end
for i = 65, 90 do -- A -> Z
	All_Enums[i] = _G["KEY_" .. string.upper(string.char(i))]
end
for i = 97, 122 do -- a -> z
	All_Enums[i] = _G["KEY_" .. string.upper(string.char(i))]
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self.Inputs = WireLib.CreateInputs(self, { "Kick", "Reset Output String" })
	self.Outputs = WireLib.CreateOutputs(self, { "Memory", "Output [STRING]", "ActiveKeys [ARRAY]", "User [ENTITY]", "InUse" })

	self.ActiveKeys = {} -- table containing all currently active keys, used to see when keys are pressed/released
	self.Buffer = {} -- array containing all currently active keys, value is ascii
	self.BufferLookup = {} -- lookup table mapping enums to buffer positions
	self.Buffer[0] = 0
	self.OutputString = ""

	self:TriggerOutputs()
end

WireLib.AddInputAlias("Kick the bastard out of keyboard", "Kick")

function ENT:TriggerInput(name, value)
	if name == "Kick" then
		-- It was kicking at the same time as giving output - added tiny delay fixing that race condition
		timer.Simple(0.1, function()
			if IsValid(self) then
				self.Locked = (value ~= 0)
				self:PlayerDetach()
			end
		end)
	elseif name == "Reset Output String" then
		self.OutputString = ""
		self:TriggerOutputs()
	end
end

function ENT:TriggerOutputs(key)
	-- Output key numerical representation
	if key ~= nil then
		WireLib.TriggerOutput(self, "Memory", key)
	end

	-- Output user
	if IsValid( self.ply ) then
		WireLib.TriggerOutput(self, "User", self.ply)
		WireLib.TriggerOutput(self, "InUse", 1)
		self:SetOverlayText("In use by " .. self.ply:Nick())
	else
		WireLib.TriggerOutput(self, "User", nil)
		WireLib.TriggerOutput(self, "InUse", 0)
		self:SetOverlayText("Not in use")
	end

	-- Output currently pressed keys
	local ActiveKeys_Output, idx = {}, 0
	for key_enum,_ in pairs( self.ActiveKeys ) do
		idx = idx + 1
		ActiveKeys_Output[idx] = self:GetRemappedKey(key_enum)
	end
	WireLib.TriggerOutput(self, "ActiveKeys", ActiveKeys_Output)

	-- Output buffer string
	WireLib.TriggerOutput(self, "Output", self.OutputString)
end

function ENT:ReadCell(Address)
	if Address >= 0 and Address < 32 then
		return self.Buffer[Address] or 0
	elseif Address >= 32 and Address < 256 then
		return self:IsPressedAscii(Address - 32) and 1 or 0
	end

	return 0
end

function ENT:WriteCell(Address, value)
	if Address == 0 then
		self:UnshiftBuffer() -- User wants to remove the first key in the buffer
	else
		self:RemoveFromBufferByKey(value)
	end

	return false
end

util.AddNetworkString("wire_keyboard_blockinput")
util.AddNetworkString("wire_keyboard_activatemessage")
function ENT:PlayerAttach(ply)
	if not IsValid(ply) or IsValid(self.ply) then return end -- If the keyboard is already in use, don't attach the player

	if IsValid(ply.WireKeyboard) then -- If the player is already using a different keyboard
		if ply.WireKeyboard == self then return end -- If the keyboard is this keyboard, don't re-attach the player
		ply.WireKeyboard:PlayerDetach() -- If it's another keyboard, detach the player from that keyboard first
	end

	-- If the keyboard is locked (Kick input is wired to something other than 0), don't attach the player
	if self.Locked then return end

	-- Store player
	self.ply = ply

	-- Block keyboard input
	if self.Synchronous then
		net.Start("wire_keyboard_blockinput")
			net.WriteBit(true)
		net.Send(ply)
	end

	net.Start("wire_keyboard_activatemessage")
		net.WriteBit(true)
		net.WriteBit(IsValid(self.Pod))
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

	self:TriggerOutputs()
end

function ENT:PlayerDetach()
	local ply = self.ply
	self.ply = nil

	-- Kick player out of vehicle, if in one
	if IsValid(self.Pod) and IsValid(self.Pod:GetDriver()) and self.Pod:GetDriver() == ply then
		self.Pod:GetDriver():ExitVehicle()
	end

	if IsValid(ply) then
		net.Start("wire_keyboard_blockinput")
			net.WriteBit(false)
		net.Send(ply)

		net.Start("wire_keyboard_activatemessage")
			net.WriteBit(false)
		net.Send(ply)

		ply.WireKeyboard = nil
	end

	self:TriggerOutputs()
end

function ENT:Use(ply)
	if IsValid(self.Pod) then
		ply:ChatPrint("This keyboard is linked to a pod. Please use the pod instead.")
		return
	end

	self:PlayerAttach(ply)
end

function ENT:OnRemove()
	self:UnlinkEnt()
	self:PlayerDetach()
	self.BaseClass.OnRemove(self)
end

function ENT:LinkEnt(pod)
	if not IsValid(pod) or not pod:IsVehicle() then return false, "Must link to a vehicle" end
	if IsValid(self.Pod) then self.Pod.WireKeyboard = nil end
	pod.WireKeyboard = self
	self.Pod = pod
	WireLib.SendMarks(self, {pod})
	return true
end
function ENT:UnlinkEnt()
	if IsValid(self.Pod) then
		self.Pod.WireKeyboard = nil
	end
	self.Pod = nil
	WireLib.SendMarks(self, {})
	return true
end

hook.Add("PlayerEnteredVehicle", "Wire_Keyboard_PlayerEnteredVehicle", function(ply, pod)
	if IsValid(pod.WireKeyboard) then
		pod.WireKeyboard:PlayerAttach(ply)
	end
end)

hook.Add("PlayerLeaveVehicle", "wire_keyboard_PlayerLeaveVehicle", function(ply, pod)
	if IsValid(pod.WireKeyboard) and pod.WireKeyboard.ply == ply then
		pod.WireKeyboard:PlayerDetach()
	end
end)

local unprintable_chars = {}
for i=17,20 do unprintable_chars[i] = true end -- arrow keys
for i=144,177 do unprintable_chars[i] = true end -- ctrl, alt, shift, break, F1-F12, scroll/num/caps lock, and more

local convertable_chars = {
	[128] = 49, -- numpad 1
	[129] = 50, -- numpad 2
	[130] = 51, -- numpad 3
	[131] = 52, -- numpad 4
	[132] = 53, -- numpad 5
	[133] = 54, -- numpad 6
	[134] = 55, -- numpad 7
	[135] = 56, -- numpad 8
	[136] = 57, -- numpad 9
	[137] = 58, -- numpad 4
	[138] = 47, -- /
	[139] = 42, -- *
	[140] = 45, -- -
	[141] = 43, -- +
	[142] = 10, -- \n
	[143] = 46, -- .
}

function ENT:AppendOutputString(key)
	if unprintable_chars[key] and not convertable_chars[key] then return end
	if convertable_chars[key] then key = convertable_chars[key] end

	if key == 127 then
		local pos = string.match(self.OutputString,"()"..utf8.charpattern.."$")
		if pos then
			self.OutputString = string.sub(self.OutputString,1,pos-1)
		end
	else
		self.OutputString = self.OutputString .. utf8.char(key)
	end

	self:TriggerOutputs()
end

--local Wire_Keyboard_Remap = Wire_Keyboard_Remap -- Defined in remap.lua
function ENT:GetRemappedKey(key_enum)
	if not key_enum or key_enum == 0 or key_enum > KEY_LAST then return 0 end -- Above KEY_LAST are joystick and mouse enums

	local layout = "American"
	if IsValid(self.ply) then layout = self.ply:GetInfo("wire_keyboard_layout", "American") end
	local current = Wire_Keyboard_Remap[layout]
	if not current then return 0 end

	local ret = current.normal[key_enum]

	-- Check if a special key is being held down (such as SHIFT)
	for k,v in pairs(self.ActiveKeys) do
		if v == true and current[k] and current[k][key_enum] then
			ret = current[k][key_enum]
		end
	end

	if isstring(ret) then ret = utf8.codepoint(ret) end
	return ret
end

function ENT:KeyPressed(key_enum)
	local key = self:GetRemappedKey(key_enum)
	if key == nil or key == 0 then return end

	if not All_Enums[key] then All_Enums[key] = key_enum end

	self.ActiveKeys[key_enum] = true
	self:PushBuffer(key, key_enum)
	self:AppendOutputString(key)

	self:TriggerOutputs(key)
end

function ENT:KeyReleased(key_enum)
	local key = self:GetRemappedKey(key_enum)
	if key == nil or key == 0 then return end

	self.ActiveKeys[key_enum] = nil

	if self.AutoBuffer then
		self:RemoveFromBufferByKey(key)
	end

	self:TriggerOutputs(0)
end

function ENT:IsPressedEnum(key_enum)
	return self.ActiveKeys[key_enum]
end

function ENT:IsPressedAscii(key)
	local key_enum = All_Enums[key]
	if not key_enum then return false end
	return self:IsPressedEnum(key_enum)
end

function ENT:UnshiftBuffer()
	self:RemoveFromBufferByPosition(1)
end

function ENT:PushBuffer(key, key_enum)
	self.Buffer[0] = self.Buffer[0] + 1
	self.Buffer[self.Buffer[0]] = key

	if not self.BufferLookup[key_enum] then self.BufferLookup[key_enum] = {} end
	local positions = self.BufferLookup[key_enum]
	positions[#positions+1] = self.Buffer[0]
end

function ENT:RemoveFromBufferByPosition(bufferpos)
	if self.Buffer[0] <= 0 then return end
	local key = table.remove(self.Buffer, bufferpos)
	self.Buffer[0] = self.Buffer[0] - 1

	-- Move all remaining keys down one step
	for key_enum,positions in pairs(self.BufferLookup) do
		for k,pos in pairs(positions) do
			if bufferpos < pos then
				positions[k] = positions[k] - 1
			end
		end
	end
end

function ENT:RemoveFromBufferByKey(key)
	local key_enum = All_Enums[key]
	if not key_enum then return false end -- key is invalid

	local positions = self.BufferLookup[key_enum]
	if not positions then return false end -- error, shouldn't happen
	local bufferpos = table.remove(positions, 1)
	if not bufferpos then return false end -- error, shouldn't happen

	self:RemoveFromBufferByPosition(bufferpos)
end

function ENT:Think()
	if not IsValid(self.ply) then
		self:NextThink(CurTime() + 0.3) -- Don't need to update as often
		return true
	end

	if self.IgnoreFirstKey then -- Don't start listening to keys until Use is released
		if not self.ply.keystate[KEY_E] then self.IgnoreFirstKey = nil end

		self:NextThink(CurTime())
		return true
	end

	local leavekey = self.ply:GetInfoNum("wire_keyboard_leavekey", KEY_LALT)

	-- Remove lifted up keys from our ActiveKeys
	for key_enum, bool in pairs(self.ActiveKeys) do
		if not self.ply.keystate[key_enum] then
			self:KeyReleased(key_enum)
		end
	end

	-- Check for newly pressed keys and add them to our ActiveKeys
	for key_enum, bool in pairs(self.ply.keystate) do
		if key_enum == leavekey then
			if leavekey ~= KEY_ALT or not self:IsPressedEnum(KEY_LCONTROL) then -- if LCONTROL and LALT are being pressed, then the player is trying to use the "ALT GR" key which is available for some languages
				self:PlayerDetach() -- Pressing the leave key quits the keyboard
				break
			end
		end

		if not self:IsPressedEnum(key_enum) then
			self:KeyPressed(key_enum)
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Setup(autobuffer, sync)
	self.AutoBuffer = autobuffer
	self.Synchronous = sync
end

duplicator.RegisterEntityClass("gmod_wire_keyboard", WireLib.MakeWireEnt, "Data", "AutoBuffer", "Synchronous")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.Pod) then
		info.pod = self.Pod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:LinkEnt(GetEntByID(info.pod), true)
	if info.autobuffer then self.AutoBuffer = info.autobuffer end
end
