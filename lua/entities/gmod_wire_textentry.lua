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
function ENT:Overlay()
	local txt="Hold Length: "..(math.Round(self:GetHold(),1)>0 and math.Round(self:GetHold(),1) or "Forever")
	if self.BlockInput then
		txt=txt.."\nBlocking Input"
	elseif self.Ply then
		txt=txt.."\nIn Use"
	end
	if IsValid(self.Vehicle)then
		local lst=list.Get("Vehicles")
		local name="Error"
		for k,v in pairs(lst)do
			if v.Class==self.Vehicle:GetClass() and v.Model==self.Vehicle:GetModel() then
				name=k
				break
			end
		end
		name=string.Replace(name,"_"," ")
		txt=txt.."\nLinked Vehicle: Vehicle ("..name..") ["..self.Vehicle:EntIndex().."]"
	end
	self:SetOverlayText(txt)
end
function ENT:Initialize()
    //self:SetModel( self.Model )
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
	
	self.Inputs=WireLib.CreateInputs(self,{"Block Input","Prompt"})
	self.Outputs=WireLib.CreateOutputs(self,{"In Use","Text [STRING]","User [ENTITY]"})
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
	elseif name=="Prompt" and IsValid(self.Vehicle) and !self.BlockInput and !IsValid(self.Ply) and value!=0 then
		local ply=self.Vehicle:GetDriver()
		if !IsValid(ply) then return end
		self.Ply=ply
		self:Output("User",ply)
		self:Output("In Use",1)
		net.Start("textentry_show")
			net.WriteEntity(self)
		net.Send(ply)
	end
end
function ENT:UnlinkEnt(ent)
	if ent==self.Vehicle and IsValid(ent) then
		self.Vehicle=nil
		self.Marks={}
		WireLib.SendMarks(self)
	end
end
function ENT:LinkEnt(ent)
	if ent==self then
		return false,"You can't link a text entry to itself!"
	end
	if !IsValid(ent) or !ent:IsVehicle() then return false,"That entity isn't a vehicle!" end
	self.Vehicle=ent
	self.Marks={ent}
	WireLib.SendMarks(self)
	return true
end
function ENT:ClearEntities()
	self:UnlinkEnt(self.Vehicle)
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
		self:Output("Text",net.ReadString())
		self.Ply=nil
		self:Output("In Use",0)
		self:Output("User",nil)
		timer.Destroy("TextEntry"..self:EntIndex())
		if self:GetHold()>0 then
			timer.Create("TextEntry"..self:EntIndex(),self:GetHold(),1,function()
				if IsValid(self) then
					self:Output("Text","")
				end
			end)
		end
	elseif act and self.BlockInput then
		self.Ply=nil
		self:Output("In Use",0)
		self:Output("User",nil)
		WireLib.AddNotify(ply,"That text entry is not accepting input right now!",NOTIFY_ERROR,5,6)
	end
end)
function ENT:Use(ply)
	if !IsValid(ply) then return end
	if self.BlockInput or IsValid(self.Ply) then
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
	if self:GetHold()<0 then
		self:SetHold(0)
	end
	if !IsValid(self.Vehicle) then
		self.Vehicle=nil
		self.Marks={}
		WireLib.SendMarks(self)
	end
	self:Overlay()
end
function ENT:Setup(Model,Hold)
	if tonumber(Hold) then
		Hold=tonumber(Hold)
		self:SetHold(Hold)
		self.hold=Hold
	end
	if isstring(Model) then
		self.Model=Model
		self:SetModel(Model)
	end
end
duplicator.RegisterEntityClass("gmod_wire_textentry",WireLib.MakeWireEnt,"Data")
