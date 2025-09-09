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
	
	self.TreeMesh = Mesh()

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
	self.TreeMesh:Destroy()
end

function ENT:ReadCell(Address)
	return self.Memory[math.floor(Address)]
end

function ENT:WriteCell(Address,value)
	self.Memory[math.floor(Address)] = value
end

function ENT:Transform(x,y)
	return {
		x*self.LocalXX+y*self.LocalXY+self.LocalX,
		x*self.LocalYX+y*self.LocalYY+self.LocalY
	}
end

function ENT:TransformOffset(x,y)
	return {
		x*self.LocalXX+y*self.LocalXY,
		x*self.LocalYX+y*self.LocalYY
	}
end

function ENT:PushTransform(XX,XY,YX,YY)
	self.TransformStack[#self.TransformStack + 1] = {self.LocalXX,self.LocalXY,self.LocalYX,self.LocalYY}
	local oXX = self.LocalXX
	local oXY = self.LocalXY
	local oYX = self.LocalYX
	local oYY = self.LocalYY
	
	local nXX = oXX*XX + oXY*YX
	local nXY = oXY*YY + oXX*XY
	local nYX = oYX*XX + oYY*YX
	local nYY = oYY*YY + oYX*XY
	
	self.LocalXX = nXX
	self.LocalXY = nXY
	self.LocalYX = nYX
	self.LocalYY = nYY
end

function ENT:PopTransform()
	self.LocalXX,self.LocalXY,self.LocalYX,self.LocalYY = unpack(self.TransformStack[#self.TransformStack])
	self.TransformStack[#self.TransformStack] = nil
end

function ENT:AddPoly(poly)
	local u = ((self.BitIndex%1024)+0.5)/1024
	local v = (math.floor(self.BitIndex/1024)+0.5)/1024
	for i = 1,#poly do
		mesh.Position(Vector(poly[i][1],poly[i][2],0))
		mesh.TexCoord(0, u, v, u ,v)
		mesh.Color(255,255,255,255)
		mesh.AdvanceVertex()
	end
end

function ENT:DrawSegment(segment)
	self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.8
	end
	--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
	local transformedLocal = self:TransformOffset(segment.X or 0,segment.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	local angle = math.rad(segment.Rotation or 0)
	self:PushTransform(math.cos(angle),
	math.sin(angle)-(segment.SkewX or 0),
	-math.sin(angle)+(segment.SkewY or 0),
	math.cos(angle))
	--self:Transform(,segment.H/2+(segment.H*(segment.BevelSkew or 0))),
	local bevel = math.min(segment.H,segment.W)/2*(segment.Bevel or 0)
	local rect = {
		self:Transform(bevel,segment.H),
		self:Transform(0,segment.H-bevel),
		self:Transform(0,bevel),
		self:Transform(bevel,0),
		self:Transform(segment.W-bevel,0),
		self:Transform(segment.W,bevel),
		self:Transform(segment.W,segment.H-bevel),
		self:Transform(segment.W-bevel,segment.H)
	}
	local poly = {
		rect[1],rect[2],rect[3],
		rect[1],rect[3],rect[4],
		rect[1],rect[4],rect[5],
		rect[1],rect[5],rect[6],
		rect[1],rect[6],rect[7],
		rect[1],rect[7],rect[8]
	}
	self:AddPoly(poly)
	--surface.DrawPoly(Rect)
	self:PopTransform()
	--surface.DrawRect(self.LocalX,self.LocalY,segment.W,segment.H)
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawText(text)
	self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
	if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
		self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.08
	end
	local transformedLocal = self:TransformOffset(text.X or 0,text.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	--surface.SetTextPos(self.LocalX,self.LocalY)
	--surface.SetFont("Default")
	--surface.SetTextColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
	--surface.DrawText(text.Text)
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawMatrix(matrix)
	for y = 0,matrix.H-1 do
		for x = 0,matrix.W-1 do
			self.Fade[self.BitIndex] = (self.Fade[self.BitIndex] or 0)*0.92
			if bit.band(self.Memory[bit.rshift(self.BitIndex,3)] or 0,bit.lshift(1,bit.band(self.BitIndex,7))) ~= 0 then
				self.Fade[self.BitIndex] = self.Fade[self.BitIndex] + 0.08
			end
			
			local transformedLocal = self:TransformOffset(matrix.X+x*matrix.OffsetX,matrix.Y+y*matrix.OffsetY)
			self.LocalX = self.LocalX + transformedLocal[1]
			self.LocalY = self.LocalY + transformedLocal[2]
			--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,self.Fade[self.BitIndex]*255)
			local rect = {
				self:Transform(0,matrix.ScaleH),
				self:Transform(0,0),
				self:Transform(matrix.ScaleW,0),
				self:Transform(matrix.ScaleW,matrix.ScaleH)
			}
			local poly = {
				rect[1],rect[2],rect[3],
				rect[1],rect[3],rect[4],
			}
			self:AddPoly(poly)
			
			
			--surface.DrawRect(self.LocalX,self.LocalY,matrix.ScaleW,matrix.ScaleH)
			self.LocalX = self.LocalX - transformedLocal[1]
			self.LocalY = self.LocalY - transformedLocal[2]
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
	local transformedLocal = self:TransformOffset(group.X or 0,group.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
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
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]
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
	local transformedLocal = self:TransformOffset(group.X or 0,group.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	local angle = math.rad(group.Rotation or 0)
	self:PushTransform(math.cos(angle),
	math.sin(angle)-(group.SkewX or 0),
	-math.sin(angle)+(group.SkewY or 0),
	math.cos(angle))
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
	self:PopTransform()
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]
	self.Cr = oCr
	self.Cg = oCg
	self.Cb = oCb
	--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
end

function ENT:CountTris(node)
	if node.Type == GROUP or node.Type == UNION then
		local sum = 0
		for i=1,#node.Children do
			sum = sum + self:CountTris(node.Children[i])
		end
		return sum
	elseif node.Type == MATRIX then
		return node.W*node.H*2
	end
	return 6
end

function ENT:Draw()
	self:DrawModel()
	--[[
	self.GPU:RenderToWorld(nil, self.ResolutionH, function(x, y, w, h)
		draw.NoTexture()
		surface.SetDrawColor(self.Bgred,self.Bggreen,self.Bgblue,255)
		surface.DrawRect(x,y,w,h)
		if self.Tree then
			--render.SetScissorRect(x,y,w,h, true)
			surface.SetDrawColor(self.Fgred,self.Fggreen,self.Fgblue,255)
			self.Cr = self.Fgred
			self.Cg = self.Fggreen
			self.Cb = self.Fgblue
			self.LocalXX = 1
			self.LocalXY = 0
			self.LocalYX = 0
			self.LocalYY = 1
			self.LocalX = x
			self.LocalY = y
			self.BitIndex = 0
			
			self.TransformStack = {}
			self:DrawGroup(self.Tree)
			--render.SetScissorRect( 0, 0, 0, 0, false )
		end
	end)]]
	
	
	
	
	if self.Tree then
		
		local oldw = ScrW()
		local oldh = ScrH()

		local NewRT = self.GPU.RT
		local OldRT = render.GetRenderTarget()

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0, 0, 1024, 1024)
		cam.Start2D()
			for i=0,self.BitIndex do
				local x = ((i%1024)+0.5)
				local y = (math.floor(i/1024)+0.5)
				self.Fade[i] = (self.Fade[i] or 0)*0.92
				if bit.band(self.Memory[bit.rshift(i,3)] or 0,bit.lshift(1,bit.band(i,7))) ~= 0 then
					self.Fade[i] = self.Fade[i] + 0.08
				end
				surface.SetDrawColor(self.Cr,self.Cg,self.Cb,self.Fade[i]*255)
				surface.DrawRect( x, y, 1, 1 )
			end
		cam.End2D()
		render.SetViewPort(0, 0, oldw, oldh)
		render.SetRenderTarget(OldRT)
		
		
	    local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
	    WireGPU_matScreen:SetTexture("$basetexture", self.GPU.RT)
		render.SetMaterial( WireGPU_matScreen )
		
		local monitor, pos, ang = self.GPU:GetInfo()
		local h = self.ResolutionH
		local scale = monitor.RS*1024/h
		local m = Matrix()
		m:SetAngles( ang )
		m:SetTranslation( pos )
		m:SetScale( Vector( scale, -scale, 1 ) )
		cam.PushModelMatrix( self:GetWorldTransformMatrix() )
		cam.PushModelMatrix( m )
	
		--surface.SetDrawColor(self.Fgred,self.Fggreen,self.Fgblue,255)
		
		
		self.TreeMesh:Draw()
		cam.PopModelMatrix()
		cam.PopModelMatrix()
		
		WireGPU_matScreen:SetTexture("$basetexture", OldTex)
		--render.SetScissorRect( 0, 0, 0, 0, false )
	end
	--
	
	--self.GPU:Render(0,0,1024,1024,nil,-(1024-self.ResolutionW)/1024,-(1024-self.ResolutionH)/1024)
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
	
	self.Cr = self.Fgred
	self.Cg = self.Fggreen
	self.Cb = self.Fgblue
	self.LocalXX = 1
	self.LocalXY = 0
	self.LocalYX = 0
	self.LocalYY = 1
	self.BitIndex = 0
	self.TransformStack = {}
	local monitor, pos, ang = self.GPU:GetInfo()
	local h = self.ResolutionH
	local w = h/monitor.RatioX
	self.LocalX = -w/2
	self.LocalY = -h/2
	mesh.Begin(self.TreeMesh,MATERIAL_TRIANGLES,self:CountTris(self.Tree))
	
	self:DrawGroup(self.Tree)
	mesh.End()
end
