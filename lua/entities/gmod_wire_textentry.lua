AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Text Entry (Wire)"
ENT.WireDebugName	= "Text Entry"


function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Hold")
end
if CLIENT then
	net.Receive("textentry_show",function()
		local self=net.ReadEntity()
		if !IsValid(self) then return end
		Derma_StringRequest(
			"Text Entry",
			"Please enter text below. Hit ENTER to send to the text entry.",
			"",
			function(text)
				net.Start("textentry_action")
					net.WriteEntity(self)
					net.WriteBit(true)
					net.WriteString(text)
				net.SendToServer()
			end,
			function()
				net.Start("textentry_action")
					net.WriteEntity(self)
					net.WriteBit(false)
				net.SendToServer()
			end,
			"ENTER","Cancel"
		)
	end)
	return
end
if !SERVER then return end
function ENT:Overlay()
	local txt="Hold Length: "..math.Round(self:GetHold(),1)
	local function app(...)
		local args={...}
		txt=txt.."\n"..table.concat(args,"\n")
	end
	if self.BlockInput then
		app("Blocking Input")
	elseif self.Ply then
		app("In Use")
	end
	self:SetOverlayText(txt)
end
function ENT:Initialize()
    self:SetModel( "models/beer/wiremod/keyboard.mdl" )
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
	
	self.Inputs=WireLib.CreateInputs(self,{"Block Input"})
	self.Outputs=WireLib.CreateOutputs(self,{"In Use","Memory [STRING]","User [ENTITY]"})
	self.BlockInput=false
	self:Overlay()
end
function ENT:Output(name,value)
	WireLib.TriggerOutput(self,name,value)
end
function ENT:TriggerInput(name,value)
	if name=="Block Input" then
		self.BlockInput = value~=0
		self:Overlay()
	end
end
util.AddNetworkString("textentry_action")
util.AddNetworkString("textentry_show")
net.Receive("textentry_action",function(_,ply)
	local self=net.ReadEntity()
	if !IsValid(self) or ply!=self.Ply or !IsValid(ply) then return end
	local act=net.ReadBit()
	if !act then
		self.Ply=nil
		self:Output("In Use",0)
		self:Output("User",nil)
		return
	elseif act and !self.BlockInput then
		self:Output("Memory",net.ReadString())
		self.Ply=nil
		self:Output("In Use",0)
		self:Output("User",nil)
		timer.Destroy("TextEntry"..self:EntIndex())
		timer.Create("TextEntry"..self:EntIndex(),self:GetHold(),1,function()
			if IsValid(self) then
				self:Output("Memory","")
			end
		end)
	elseif act and self.BlockInput then
		self.Ply=nil
		self:Output("In Use",0)
		self:Output("User",nil)
		WireLib.AddNotify(ply,"That text entry is not accepting input right now!",NOTIFY_ERROR,5,6)
	end
end)
function ENT:Use(ply)
	if self.BlockInput then
		WireLib.AddNotify(ply,"That text entry is not accepting input right now!",NOTIFY_ERROR,5,6)
		return
	end
	if !IsValid(ply) then return end
	if IsValid(self.Ply) then
		WireLib.AddNotify(ply,"That text entry is not accepting input right now!",NOTIFY_ERROR,5,6)
		return
	end
	self.Ply=ply
	self:Output("User",ply)
	self:Output("In Use",1)
	net.Start("textentry_show")
		net.WriteEntity(self)
	net.Send(ply)
end
function ENT:Think()
	if self:GetHold()<1 then
		self:SetHold(1)
	end
	self:Overlay()
	self:NextThink(CurTime()+1)
	return true
end
function ENT:Setup(hold)
	if tonumber(hold) then
		hold=tonumber(hold)
		self:SetHold(hold)
		self.hold=hold
	end
end
duplicator.RegisterEntityClass("gmod_wire_textentry",WireLib.MakeWireEnt,"Data")
