include("shared.lua")


function ENT:Initialize()
	self.Memory = {}
	self.Fade = {}

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

	self.Fgblue = 45
	self.Fggreen = 91
	self.Fgred = 45
	self.Bgblue = 15
	self.Bggreen = 178
	self.Bgred = 148

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

function ENT:Transform(x,y)
	return {
		x=x*self.LocalXX+y*self.LocalXY+self.LocalX,
		y=x*self.LocalYX+y*self.LocalYY+self.LocalY
	}
end

function ENT:DrawSegment(segment)
	self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.8
	end
	surface.SetDrawColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
	self.LocalX = self.LocalX + segment.X
	self.LocalY = self.LocalY + segment.Y
	--[[local Rect = {
		self:Transform(0,segment.H),
		self:Transform(0,0),
		self:Transform(segment.W,0),
		self:Transform(segment.W,segment.H)
	}
	surface.DrawPoly(Rect)
	]]
	surface.DrawRect(self.LocalX,self.LocalY,segment.W,segment.H)
	self.LocalX = self.LocalX - segment.X
	self.LocalY = self.LocalY - segment.Y
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawText(text)
	self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.08
	end
	surface.SetTextPos(text.X+self.LocalX,text.Y+self.LocalY)
	surface.SetFont("Default")
	surface.SetTextColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
	surface.DrawText(text.Text)
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawMatrix(matrix)
	for y = 0,matrix.H-1 do
		for x = 0,matrix.W-1 do
			self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
			if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
				self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.08
			end
			surface.SetDrawColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
			surface.DrawRect(matrix.X+self.LocalX+x*matrix.OffsetX,matrix.Y+self.LocalY+y*matrix.OffsetY,matrix.ScaleW,matrix.ScaleH)
			self.BitIndex = self.BitIndex+1
		end
	end
	
	
end


function ENT:DrawUnion(group)
	local oCr = self.Cr
	local oCg = self.Cg
	local oCb = self.Cb
	if group.HasColor then
		self.Cr = group.R
		self.Cg = group.G
		self.Cb = group.B
		--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
	end
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
		elseif v.Type == MATRIX then 
			self:DrawMatrix(v)
		end
		biggestindex = math.max(biggestindex,self.BitIndex)
		self.BitIndex = savedindex
	end
	self.BitIndex = biggestindex
	self.LocalX = self.LocalX - (group.X or 0)
	self.LocalY = self.LocalY - (group.Y or 0)
	self.Cr = oCr
	self.Cg = oCg
	self.Cb = oCb
	--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
end

function ENT:DrawGroup(group)
	local oCr = self.Cr
	local oCg = self.Cg
	local oCb = self.Cb
	if group.HasColor then
		self.Cr = group.R
		self.Cg = group.G
		self.Cb = group.B
		--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
	end
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
		elseif v.Type == MATRIX then 
			self:DrawMatrix(v)
		end
	end
	self.LocalX = self.LocalX - (group.X or 0)
	self.LocalY = self.LocalY - (group.Y or 0)
	self.Cr = oCr
	self.Cg = oCg
	self.Cb = oCb
	--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
end

function ENT:Draw()
	self:DrawModel()
	self.GPU:RenderToGPU(function()
		surface.SetDrawColor(self.Bgred,self.Bggreen,self.Bgblue,255)
		surface.DrawRect(0,0,1024,1024)
		if self.Tree then
			surface.SetDrawColor(self.Fgred,self.Fggreen,self.Fgblue,255)
			self.Cr = self.Fgred
			self.Cg = self.Fggreen
			self.Cb = self.Fgblue
			self.LocalXX = 1
			self.LocalXY = 0
			self.LocalYX = 0
			self.LocalYY = 1
			self.LocalX = 0
			self.LocalY = 0
			self.BitIndex = 0
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
	self.Fgblue = net.ReadUInt(8)
	self.Fggreen = net.ReadUInt(8)
	self.Fgred = net.ReadUInt(8)
	self.Bgblue = net.ReadUInt(8)
	self.Bggreen = net.ReadUInt(8)
	self.Bgred = net.ReadUInt(8)
end
