-- Author: mitterdoo (with help from Divran)

AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Text Entry (Wire)"
ENT.WireDebugName	= "Text Entry"


function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Hold")
	self:NetworkVar("Bool",0,"DisableUse")
end

if CLIENT then
	local panel

	----------------------------------------------------
	-- Show the prompt
	----------------------------------------------------
	net.Receive("wire_textentry_show",function()
		local self=net.ReadEntity()
		if not IsValid(self) then return end
		panel = Derma_StringRequestNoBlur(
			"Wire Text Entry",
			"Enter text below",
			"",
			function(text)
				net.Start("wire_textentry_action")
					net.WriteEntity(self)
					net.WriteBool(true)
					net.WriteString(text)
				net.SendToServer()
			end,
			function()
				net.Start("wire_textentry_action")
					net.WriteEntity(self)
					net.WriteBool(false)
					net.WriteString("")
				net.SendToServer()
			end,
			"Enter","Cancel"
		)
	end)

	net.Receive( "wire_textentry_kick", function()
		if IsValid( panel ) then
			panel:Remove()
		end
	end)
	return
end

function ENT:GetHoldClamped()
	return math.max(self:GetHold(), 0)
end

function ENT:GetHoldTimerName()
	return "wire_textentry_" .. self:EntIndex()
end

function ENT:RemoveHoldTimer()
	timer.Remove(self:GetHoldTimerName())
end

----------------------------------------------------
-- UpdateOverlay
----------------------------------------------------
function ENT:UpdateOverlay()
	local hold = math.Round(self:GetHoldClamped(),1)
	local txt = "Hold Length: " .. (hold > 0 and hold or "Forever")

	if self.BlockInput then
		txt = txt.."\nBlocking Input"
	elseif IsValid(self.User) then
		txt = txt.."\nIn use by: " .. self.User:Nick()
	end

	if self:GetDisableUse() then
		txt = txt .. "\nUse disabled"
	end

	self:SetOverlayText(txt)
end

----------------------------------------------------
-- Initialize
----------------------------------------------------
function ENT:Initialize()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

	self.Inputs=WireLib.CreateInputs(self,{
		"Block Input (When set to a non-zero value, blocks any further inputs.)",
		"Prompt (When set to a non-zero value, opens the prompt popup for the driver of the linked vehicle.\n"
		.."If no vehicle is linked, opens the prompt for the owner of this entity instead.)"})
	self.Outputs=WireLib.CreateOutputs(self,{
		"In Use","Text [STRING]","User [ENTITY]",
		"Entered (Set to 1 for a bit when text is successfully entered)"
	})

	self.BlockInput = false
	self.NextPrompt = 0

	self:UpdateOverlay()
end

----------------------------------------------------
-- Vehicle linking
----------------------------------------------------
function ENT:TriggerInput(name,value)
	if name == "Block Input" then
		self.BlockInput = value~=0
		self:UpdateOverlay()
		if IsValid( self.User ) then self:Unprompt( true ) end
	elseif name == "Prompt" then
		if value ~= 0 then self:Prompt() end
	end
end

----------------------------------------------------
-- Vehicle linking
----------------------------------------------------
function ENT:UnlinkEnt(ent)
	if not IsValid( ent ) then return false, "Invalid entity specified" end

	if IsValid(self.Vehicle) then
		self.Vehicle:RemoveCallOnRemove( "wire_textentry_onremove" )
		self.Vehicle.WireTextEntry = nil
	end

	self.Vehicle = nil
	WireLib.SendMarks( self, {} )
	return true
end

function ENT:LinkEnt(ent)
	if not IsValid( ent ) then return false, "Invalid entity specified" end
	if not ent:IsVehicle() then return false, "Entity must be a vehicle" end

	if IsValid( self.Vehicle ) then -- remove old callback
		self.Vehicle:RemoveCallOnRemove( "wire_textentry_onremove" )
		self.Vehicle.WireTextEntry = nil
	end

	self.Vehicle = ent
	self.Vehicle.WireTextEntry = self

	-- add new callback
	self.Vehicle:CallOnRemove( "wire_textentry_onremove", function()
		self:UnlinkEnt( ent )
	end)

	WireLib.SendMarks( self, { ent } )
	return true
end

function ENT:ClearEntities()
	self:UnlinkEnt(self.Vehicle)
end

function ENT:OnRemove()
	if IsValid( self.Vehicle ) then -- remove callback
		self.Vehicle:RemoveCallOnRemove( "wire_textentry_onremove" )
		self.Vehicle.WireTextEntry = nil
	end

	self:RemoveHoldTimer()

	self:Unprompt( true )
end

----------------------------------------------------
-- Receiving text from client
----------------------------------------------------
util.AddNetworkString("wire_textentry_action")
net.Receive("wire_textentry_action",function(len,ply)
	local self=net.ReadEntity()

	if not IsValid( self ) or not IsValid( ply ) or ply ~= self.User then return end

	local ok = net.ReadBool()
	local text = net.ReadString()

	self:Unprompt() -- in all cases, make text entry available for use again

	if ok and not self.BlockInput then
		self:OnTextEntered(text)

		
	end

	self:UpdateOverlay()
end)

function ENT:OnTextEntered(text)
	WireLib.TriggerOutput( self, "Text", text )
	WireLib.TriggerOutput( self, "Entered", 1 )
	WireLib.TriggerOutput( self, "Entered", 0 )

	local timername = self:GetHoldTimerName()
	timer.Remove( timername )
	if self:GetHoldClamped() > 0 then
		timer.Create( timername, self:GetHoldClamped(), 1, function()
			if not self:IsValid() then return end

			WireLib.TriggerOutput( self, "User", nil )
			WireLib.TriggerOutput( self, "Text", "" )
		end)
	end
end

----------------------------------------------------
-- Prompt
-- Sends prompt to user etc
----------------------------------------------------
util.AddNetworkString("wire_textentry_show")
function ENT:Prompt( ply )
	if ply then
		if CurTime() < self.NextPrompt then return end -- anti spam
		self.NextPrompt = CurTime() + 0.1

		if self.BlockInput or IsValid( self.User ) then
			WireLib.AddNotify(ply,"That text entry is not accepting input right now!",NOTIFY_ERROR,5,6)
			return
		end

		self.User = ply

		WireLib.TriggerOutput( self, "User", ply )
		WireLib.TriggerOutput( self, "In Use", 1 )

		self:RemoveHoldTimer()

		net.Start( "wire_textentry_show" )
			net.WriteEntity( self )
		net.Send( ply )

		self:UpdateOverlay()
	elseif IsValid( self.Vehicle ) and IsValid( self.Vehicle:GetDriver() ) then -- linked
		self:Prompt( self.Vehicle:GetDriver() ) -- prompt for driver
	else -- not linked
		self:Prompt( self:GetPlayer() ) -- prompt for owner
	end
end

----------------------------------------------------
-- Unprompt
-- Unsets user, making the text entry usable by other users
----------------------------------------------------
util.AddNetworkString("wire_textentry_kick")
function ENT:Unprompt( kickuser )
	if IsValid( self.User ) and kickuser then
		net.Start( "wire_textentry_kick" ) net.Send( self.User )
	end

	self:RemoveHoldTimer()

	self.User = nil
	WireLib.TriggerOutput( self, "In Use", 0 )
	self:UpdateOverlay()
end

----------------------------------------------------
-- PlayerLeaveVehicle
----------------------------------------------------
hook.Add( "PlayerLeaveVehicle", "wire_textentry_leave_vehicle", function( ply, vehicle )
	if vehicle.WireTextEntry and IsValid( vehicle.WireTextEntry ) and
		IsValid( vehicle.WireTextEntry.User ) and vehicle.WireTextEntry.User == ply then

		vehicle.WireTextEntry:Unprompt( true )
	end
end)

----------------------------------------------------
-- Use
----------------------------------------------------
function ENT:Use(ply)
	if self:GetDisableUse() or not IsValid( ply ) then return end

	self:Prompt( ply )
end

----------------------------------------------------
-- Setup
----------------------------------------------------
function ENT:Setup(hold,disableuse)
	hold = tonumber(hold)
	if hold then
		self:SetHold( math.max( hold, 0 ) )
	end

	disableuse = tobool(disableuse)
	if disableuse ~= nil then
		self:SetDisableUse( disableuse )
	end

	self:UpdateOverlay()
end
duplicator.RegisterEntityClass("gmod_wire_textentry",WireLib.MakeWireEnt,"Data")
