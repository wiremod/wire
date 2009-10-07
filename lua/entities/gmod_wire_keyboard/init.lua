AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')
include('remap.lua')

ENT.WireDebugName = "Wired Keyboard"
ENT.OverlayDelay = 0

--Duplicator support to save pod link (modified from TAD2020's work on advpod)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.LinkedPod) and (self.LinkedPod:IsValid()) then
	    info.pod = self.LinkedPod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.pod) then
		local LinkedPod = GetEntByID(info.pod)
		if (!LinkedPod) then
			LinkedPod = ents.GetByIndex(info.pod)
		end
		self:LinkPod(LinkedPod, true)
	end
end

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetUseType(SIMPLE_USE)

	self.On = {}
	self.Inputs = Wire_CreateInputs(self.Entity, { "Kick the bastard out of keyboard" })
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Memory", "User", "InUse" }, { "NORMAL", "ENTITY", "NORMAL" })

	for i = 0,223 do
		self.On[i] = false
	end

	self.Buffer = {}
	for i = 0,31 do
		self.Buffer[i] = 0
	end

	self.InUse = false
	self.IgnoredFirstChar = false
	self:SetOverlayText("Keyboard - not in use")
	Wire_TriggerOutput(self.Entity, "InUse", 0)
end


function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < 32) then
		return self.Buffer[Address]
	elseif (Address >= 32) && (Address < 256) then
		if (self.On[Address-32]) then
			return 1
		else
			return 0
		end
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	if (Address == 0) then
		self.Buffer[0] = 0
		return true
	elseif (Address > 0) && (Address < 256) then
		self:Switch(false,value)
		return true
	else
		return false
	end
end

function ENT:Use(pl)
	if self.LinkedPod then pl:PrintMessage(HUD_PRINTTALK, "This keyboard is linked to a pod, please use the pod.") return end
	self:PlayerAttach(pl)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Kick the bastard out of keyboard") then
		self.lock = value
		if value ~= 0 and self.InUse and self.InUseBy:IsValid() then
			self:PlayerDetach(self.InUseBy)
		end
	end
end

//=============================================================================
// Switch key state to ON/OFF
//=============================================================================

function ENT:Switch(on, key)
	if (!self.Entity:IsValid()) then return false end

	if (key == -1) then
		self.Buffer[0] = 0
		return true
	end

	self.On[ key ] = on

	if ((key != 21) && (key != 16)) then
		if (on == true) then
			if (self.InUse) then
				self.Buffer[0] = self.Buffer[0] + 1
				self.Buffer[self.Buffer[0]] = key
				Wire_TriggerOutput(self.Entity, "Memory", key)
			end
		else
			Wire_TriggerOutput(self.Entity, "Memory", 0)
			for i = 1,self.Buffer[0] do
				if (self.Buffer[i] == key) then
					self.Buffer[0] = self.Buffer[0] - 1
					for j = i,self.Buffer[0] do
						self.Buffer[j] = self.Buffer[j+1]
					end
					return true
				end
			end
		end
	end

	return true
end

//=============================================================================
// Keyboard turning ON/OFF
//=============================================================================

local KeyBoardPlayerKeys = {}

hook.Add("EntityRemoved", "wire_keyboard", function(ply)
	KeyBoardPlayerKeys[ply:EntIndex()] = nil
end)

local function Wire_KeyOff(pl)
	local prev_ent = KeyBoardPlayerKeys[pl:EntIndex()]
	if (prev_ent) && (prev_ent:IsValid()) && (prev_ent.InUse) then
		Wire_TriggerOutput(prev_ent, "User", NULL)
		Wire_TriggerOutput(prev_ent, "InUse", 0)
		prev_ent.InUse = false
		prev_ent:SetOverlayText("Keyboard - not in use")
	end
	KeyBoardPlayerKeys[pl:EntIndex()] = nil

	umsg.Start("wire_keyboard_releaseinput", pl) umsg.End()

	pl:PrintMessage(HUD_PRINTTALK,"Wired keyboard turned off\n")
end

local function Wire_KeyOn(pl, ent)
	local prev_ent = KeyBoardPlayerKeys[pl:EntIndex()]
	if prev_ent and prev_ent.InUse then return end -- If the player is already using the keyboard, don't use another one

	KeyBoardPlayerKeys[pl:EntIndex()] = ent

	umsg.Start("wire_keyboard_blockinput", pl) umsg.End()
	if ent.LinkedPod then
		pl:PrintMessage(HUD_PRINTTALK, "This pod is linked to a keyboard - press ALT to leave\n")
	else
		pl:PrintMessage(HUD_PRINTTALK, "Wired keyboard turned on - press ALT to exit the mode\n")
	end
end

function ENT:PlayerAttach(pl)
	if self.InUse then return end -- If the keyboard is already in use, don't attach the player
	if self.lock == 1 then return end -- If the keyboard is locked, don't attach the player

	self.InUse = true
	self.IgnoredFirstChar = false
	self.InUseBy = pl
	Wire_TriggerOutput(self.Entity, "User", pl.Entity)
	Wire_TriggerOutput(self.Entity, "InUse", 1)

	self:SetOverlayText("Keyboard - In use by " .. pl:GetName())
	Wire_KeyOn(pl, self.Entity)
end

function ENT:PlayerDetach(pl)
	if not self.InUse then return end
	if self.HasPodDriver and self.LinkedPod then
		if self.LinkedPod.GetDriver and self.LinkedPod:GetDriver().ExitVehicle then
			self.LinkedPod:GetDriver():ExitVehicle()
		end
	else
		Wire_KeyOff(pl)
	end

end

//=============================================================================
// Key press/release hook handlers
//=============================================================================


concommand.Add("wire_keyboard_press", function(pl, cmd, args)
	local key = tonumber(args[2])

	if (!KeyBoardPlayerKeys[pl:EntIndex()]) then return end
	local ent = KeyBoardPlayerKeys[pl:EntIndex()]
	if (!ent) || (!ent:IsValid()) then
		Wire_KeyOff(pl)
		return
	end
	if (!ent.InUse) then
		ent:PlayerDetach(pl)
		return
	end

	if (key == KEY_RALT) || (key == KEY_LALT) then
		ent:PlayerDetach(pl)
		return
	end

	//Get normalized/ASCII key
	local nkey
	if (Keyboard_ReMap[key]) then nkey = Keyboard_ReMap[key]
	else nkey = 0 end

	if (ent.On[21] == true) then
		if (Keyboard_CaseReMap[string.char(nkey)]) then
			nkey = string.byte(Keyboard_CaseReMap[string.char(nkey)])
		end
	end

	if (ent.IgnoredFirstChar == false) then
		ent.IgnoredFirstChar = true
		return
	end

	//Msg("Received key press ("..string.char(nkey)..") for player "..pl:EntIndex()..", entity "..ent:EntIndex().."\n")

	if (args[1] == "p") then
		if (key == KEY_LCONTROL) || (key == KEY_RCONTROL) then ent:Switch(true,16) end
		if (key == KEY_LSHIFT) || (key == KEY_RSHIFT) then ent:Switch(true,21) end

		ent:Switch(true,nkey)
	else
		if (key == KEY_LCONTROL) || (key == KEY_RCONTROL) then ent:Switch(false,16) end
		if (key == KEY_LSHIFT) || (key == KEY_RSHIFT) then ent:Switch(false,21) end

		ent:Switch(false,nkey)
	end
end)


-- a table containing the pods and their linked keyboards
local linked_pods = {}

-- place some hooks that allow the keyboard to track the state of its linked pod
hook.Add("PlayerEnteredVehicle", "wire_keyboard_PlayerEnteredVehicle", function(player, pod, role)
	if not linked_pods[pod] then return end

	for keyboard,b in pairs(linked_pods[pod]) do
		if b then
			keyboard:PlayerEnteredVehicle(player, role)
		end
	end
end)

hook.Add("PlayerLeaveVehicle", "wire_keyboard_PlayerLeaveVehicle", function(player, pod, role)
	if not linked_pods[pod] then return end

	for keyboard,b in pairs(linked_pods[pod]) do
		if b then
			keyboard:PlayerLeaveVehicle(player, role)
		end
	end
end)

function ENT:LinkPod(pod, silent)
	if (pod and pod:IsValid()) then
		-- unlink previous pod
		if self.LinkedPod then self:LinkPod(nil, true) end
		self.LinkedPod = pod

		if not silent then self:GetPlayer():PrintMessage( HUD_PRINTTALK,"Keyboard linked to Pod" ) end
		--self:GetPlayer():PrintMessage( HUD_PRINTTALK,"Keyboard "..tostring(self).." linked to Pod "..tostring(pod) )
		if not linked_pods[pod] then
			linked_pods[pod] = {}
		end
		linked_pods[pod][self] = true
	elseif self.LinkedPod then

		if not silent then self:GetPlayer():PrintMessage( HUD_PRINTTALK,"Keyboard unlinked" ) end
		--self:GetPlayer():PrintMessage( HUD_PRINTTALK,"Keyboard "..tostring(self).." unlinked" )
		if not linked_pods[self.LinkedPod] then return end
		linked_pods[self.LinkedPod][self] = nil --TODO: optimization: remove sub-table if empty
		self.LinkedPod = nil
	end
end
function ENT:PlayerEnteredVehicle(player, role)
	--print("Player "..tostring(player).." entered the vehicle")
	self.HasPodDriver=true
	self:PlayerAttach(player)
end

function ENT:PlayerLeaveVehicle(player, role)
	--print("Player "..tostring(player).." left the vehicle")
	self.HasPodDriver=nil
	self:PlayerDetach(player)
end

function ENT:OnRemove()
	self:LinkPod(nil, true)
end
