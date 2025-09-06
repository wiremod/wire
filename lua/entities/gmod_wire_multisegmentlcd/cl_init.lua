include("shared.lua")


function ENT:Initialize()
	self.Memory = {}

	self.InteractiveData = {}
	self.LastButtons = {}
	self.Buttons = {}
	local interactive_model = WireLib.GetInteractiveModel(self:GetModel())
	self.IsInteractive = false
	if interactive_model then
		self.IsInteractive = true
		for i=1, #WireLib.GetInteractiveModel(self:GetModel()).widgets do
			self.InteractiveData[i] = 0
		end
	end

	self.GPU = WireGPU(self)
	self.ResolutionW = 1024
	self.ResolutionH = 1024

	GPULib.ClientCacheCallback(self,function(Address,Value)
		self:WriteCell(Address,Value)
	end)

	WireLib.netRegister(self)
end


function ENT:SendData()
	net.Start("wire_interactiveprop_action")

	local data	= WireLib.GetInteractiveModel(self:GetModel()).widgets
	net.WriteEntity(self)
	for i=1, #data do
		net.WriteFloat(self.InteractiveData[i])
	end
	net.SendToServer()
end

function ENT:GetPanel()
	if not self.IsInteractive then return end
	local data	= WireLib.GetInteractiveModel(self:GetModel())
	return WireLib.GetInteractiveWidgetBody(self, data)
end


function ENT:AddButton(id,button)
	if not self.IsInteractive then return end
	self.Buttons[id] = button
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:ReadCell(Address)
	return self.Memory[math.floor(Address)]
end

function ENT:WriteCell(Address,value)
	self.Memory[math.floor(Address)] = value
end

function ENT:DrawSegment(segment)
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		surface.DrawRect(segment.X+self.LocalX,segment.Y+self.LocalY,segment.W,segment.H)
	end
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawText(text)
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		surface.SetTextPos(text.X+self.LocalX,text.Y+self.LocalY)
		surface.SetFont("Default")
		surface.SetTextColor(255,255,255,255)
		surface.DrawText(text.Text)
	end
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawUnion(group)
	self.LocalX = self.LocalX + (group.X or 0)
	self.LocalY = self.LocalY + (group.Y or 0)
	local savedindex = self.BitIndex
	local biggestindex = savedindex
	for k,v in ipairs(group.Children) do
		if v.Type == GROUP then
			self:DrawGroup(v)
		elseif v.Type == UNION then
			self:DrawUnion(v)
		elseif v.Type == SEGMENT then 
			self:DrawSegment(v)
		elseif v.Type == TEXT then 
			self:DrawText(v)
		end
		biggestindex = math.max(biggestindex,self.BitIndex)
		self.BitIndex = savedindex
	end
	self.BitIndex = biggestindex
	self.LocalX = self.LocalX - (group.X or 0)
	self.LocalY = self.LocalY - (group.Y or 0)
end

function ENT:DrawGroup(group)
	self.LocalX = self.LocalX + (group.X or 0)
	self.LocalY = self.LocalY + (group.Y or 0)
	for k,v in ipairs(group.Children) do
		if v.Type == GROUP then
			self:DrawGroup(v)
		elseif v.Type == UNION then
			self:DrawUnion(v)
		elseif v.Type == SEGMENT then 
			self:DrawSegment(v)
		elseif v.Type == TEXT then 
			self:DrawText(v)
		end
	end
	self.LocalX = self.LocalX - (group.X or 0)
	self.LocalY = self.LocalY - (group.Y or 0)
end

function ENT:Draw()
	self:DrawModel()
	self.GPU:RenderToGPU(function()
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(0,0,1024,1024)
		if self.Tree then
			surface.SetDrawColor(255,255,255,255)
			self.BitIndex = 0
			self.LocalX = 0
			self.LocalY = 0
			self:DrawGroup(self.Tree)
		end
	end)
	self.GPU:Render(0,0,1024,1024,nil,-(1024-self.ResolutionW)/1024,-(1024-self.ResolutionH)/1024)
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end

function ENT:Receive()
	local ent = net.ReadEntity()
	local sz = net.ReadUInt(16)
	self.Tree = WireLib.von.deserialize(net.ReadData(sz))
	self.ResolutionW = net.ReadUInt(16)
	self.ResolutionH = net.ReadUInt(16)
end
