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
		if !IsValid(self) then return end
		panel = Derma_StringRequest(
			"Wire Text Entry",
			"Enter text below",
			"",
			function(text)
				net.Start("wire_textentry_action")
					net.WriteEntity(self)
					net.WriteString(text)
				net.SendToServer()
			end,
			function()
				net.Start("wire_textentry_action")
					net.WriteEntity(self)
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

----------------------------------------------------
-- UpdateOverlay
----------------------------------------------------
function ENT:UpdateOverlay()
	local hold = math.Round(math.max(self:GetHold(),0),1)
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
	
	self.Inputs=WireLib.CreateInputs(self,{"Block Input","Prompt"})
	self.Outputs=WireLib.CreateOutputs(self,{"In Use","Text [STRING]","User [ENTITY]"})
	
	self.BlockInput=false
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
	
	self:Unprompt( true )
end

----------------------------------------------------
-- Receiving text from client
----------------------------------------------------
util.AddNetworkString("wire_textentry_action")
net.Receive("wire_textentry_action",function(len,ply)
	local self=net.ReadEntity()
	
	if not IsValid( self ) or not IsValid( ply ) or ply ~= self.User then return end
	
	local text = net.ReadString()
	
	self:Unprompt() -- in all cases, make text entry available for use again
	
	if not self.BlockInput then
		WireLib.TriggerOutput( self, "Text", text )
		
		local timername = "wire_textentry_" .. self:EntIndex()
		timer.Remove( timername )
		if math.max(self:GetHold(),0) > 0 then
			timer.Create( timername, math.max(self:GetHold(),0), 1, function()
				if IsValid( self ) then
					WireLib.TriggerOutput( self, "User", nil )
					WireLib.TriggerOutput( self, "Text", "" )
				end
			end)
		end
	end
	
	self:UpdateOverlay()
end)

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
		
		local timername = "wire_textentry_" .. self:EntIndex()
		timer.Remove( timername )
		
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

	local timername = "wire_textentry_" .. self:EntIndex()
	timer.Remove( timername )

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
