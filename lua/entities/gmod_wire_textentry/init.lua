AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
DEFINE_BASECLASS("base_wire_entity")

function ENT:SpawnFunction(ply,tr)
	if not tr.Hit then return end
	local pos=tr.HitPos+tr.HitNormal*16
	local ent=ents.Create(ClassName)
	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()
	return ent
end
function ENT:Overlay()
	local txt="- Text Entry -"
	local function app(...)
		local args={...}
		txt=txt.."\n"..table.concat(args,"\n")
	end
	app("Hold Length: "..math.Round(self:GetDelay(),1))
	if self.BlockInput then
		app("Blocking Input")
	elseif self.Ply then
		app("In Use")
	end
	self:SetOverlayText(txt)
end
function ENT:Initialize()
    self:SetModel( self.Model )
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
    end
	
	
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
	local intruder=false
	local self=net.ReadEntity()
	if !IsValid(self) then intruder=true end
	if ply!=self.Ply then intruder=true end
	local act=net.ReadString()
	if not intruder then
		if act=="cancel" then
			self.Ply=nil
			self:Output("In Use",0)
			self:Output("User",nil)
			return
		elseif act=="input" and !self.BlockInput then
			self:Output("Memory",net.ReadString())
			self.Ply=nil
			self:Output("In Use",0)
			self:Output("User",nil)
			timer.Simple(self:GetDelay(),function()
				if IsValid(self) then
					self:Output("Memory","")
				end
			end)
		elseif act=="input" and self.BlockInput then
			self.Ply=nil
			self:Output("In Use",0)
			self:Output("User",nil)
			ply:SendLua([[
			notification.AddLegacy("That keyboard is not accepting input right now!",NOTIFY_ERROR,5)
			]])
		else
			intruder=true
		end
	end
	if intruder then
		ply:SendLua([[notification.AddLegacy("you shouldn't be doing that. server notified.",NOTIFY_ERROR,5)]])
		print("SOMEBODY IS SENDING NET MESSAGES MANUALLY")
		print("> name:","",ply:Nick())
		print("> steamid:",ply:SteamID())
	end
end)
function ENT:Use(ply)
	if self.DeltaTime then
		if CurTime()<self.DeltaTime then
			return
		else
			self.DeltaTime=CurTime()+1
		end
	else
		self.DeltaTime=CurTime()+1
	end
	if self.BlockInput then
		ply:SendLua([[
		notification.AddLegacy("That keyboard is not accepting input right now!",NOTIFY_ERROR,5)
		]])
		return
	end
	assert(IsValid(ply),"ply does not exist!")
	if IsValid(self.Ply) then
		ply:SendLua([[
			notification.AddLegacy("That keyboard is already in use!",NOTIFY_ERROR,5)
		]])
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
	if self:GetDelay()<0.1 then
		self:SetDelay(0.1)
	end
	self:Overlay()
	self:NextThink(CurTime()+1)
end