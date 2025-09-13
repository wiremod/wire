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
	
	self.TreeMesh = {}
	self.Texts = {}

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
	for i=1,#self.TreeMesh do
		self.TreeMesh[i]:Destroy()
	end
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

function ENT:GetTransformMatrix(x,y)
	return Matrix({
		{x*self.LocalXX,y*self.LocalXY,0,self.LocalX},
		{x*self.LocalYX,y*self.LocalYY,0,self.LocalY},
		{0,0,1,0},
		{0,0,0,1}
	})
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
	local u = (((bit.bxor(self.BitIndex,self.XorMask)+1)%1024)+0.5)/1024
	local v = (math.floor((self.BitIndex+1)/1024)+0.5)/1024
	for i = 1,#poly do
		if self.CurTris > 10922 then
			mesh.End()
			self.TreeMesh[#self.TreeMesh + 1] = Mesh()
			mesh.Begin(self.TreeMesh[#self.TreeMesh],MATERIAL_TRIANGLES,math.min(10922,self.Tris))
			self.Tris = self.Tris - 10922
			self.CurTris = 0
		end
		mesh.Position(Vector(poly[i][1],poly[i][2],0))
		mesh.TexCoord(0, u, v, u ,v)
		mesh.Color(255,255,255,127)
		mesh.AdvanceVertex()
		self.CurTris = self.CurTris + 1
	end
	for i = 1,#poly do
		if self.CurTris > 10922 then
			mesh.End()
			self.TreeMesh[#self.TreeMesh + 1] = Mesh()
			mesh.Begin(self.TreeMesh[#self.TreeMesh],MATERIAL_TRIANGLES,math.min(10922,self.Tris))
			self.Tris = self.Tris - 10922
			self.CurTris = 0
		end
		mesh.Position(Vector(poly[i][1],poly[i][2],self.ZOffset))
		mesh.TexCoord(0, u, v, u ,v)
		mesh.Color(255,255,255,255)
		mesh.AdvanceVertex()
		self.CurTris = self.CurTris + 1
	end
end

function ENT:DrawSegment(segment)
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
	self.Colors[self.BitIndex] = {self.Cr,self.Cg,self.Cb,self.Ca}
	self.BitIndex = self.BitIndex+1
end

_TEXT_MATRIX = 0
_TEXT_TEXT = 1
_TEXT_BITINDEX = 2

function ENT:DrawText(text)
	local transformedLocal = self:TransformOffset(text.X or 0,text.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	self.Texts[#self.Texts+1] = {
		[_TEXT_MATRIX] = self:GetTransformMatrix(text.W or 1,text.H or 1),
		[_TEXT_TEXT] = text.Text,
		[_TEXT_BITINDEX] = self.BitIndex
	}
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]
	self.Colors[self.BitIndex] = {self.Cr,self.Cg,self.Cb,self.Ca}
	self.BitIndex = self.BitIndex+1
end

function ENT:DrawMatrix(matrix)
	for y = 0,matrix.H-1 do
		for x = 0,matrix.W-1 do
			
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
			self.Colors[self.BitIndex] = {self.Cr,self.Cg,self.Cb,self.Ca}
			self.BitIndex = self.BitIndex+1
		end
	end
	
	
end


function ENT:DrawUnion(group)
	local oCr = self.Cr
	local oCg = self.Cg
	local oCb = self.Cb
	local oCa = self.Ca
	if group.HasColor then
		self.Cr = group.R
		self.Cg = group.G
		self.Cb = group.B
		self.Ca = group.A or 255
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
	self.Cr = oCrq
	self.Cg = oCg
	self.Cb = oCb
	self.Ca = oCa
end

function ENT:DrawGroup(group)
	local oCr = self.Cr
	local oCg = self.Cg
	local oCb = self.Cb
	local oCa = self.Ca
	if group.HasColor then
		self.Cr = group.R
		self.Cg = group.G
		self.Cb = group.B
		self.Ca = group.A or 255
		--surface.SetDrawColor(self.Cr,self.Cg,self.Cb,255)
	end
	
	local angle = math.rad(group.Rotation or 0)
	local transformedLocal = self:TransformOffset(group.X or 0,group.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	self:PushTransform(math.cos(angle),
	math.sin(angle),
	-math.sin(angle),
	math.cos(angle))
	self:PushTransform(1,
	-(group.SkewX or 0),
	(group.SkewY or 0),
	1)
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
	self.Ca = oCa
end

function ENT:CountTris(node)
	if node.Type == GROUP or node.Type == UNION then
		local sum = 0
		for i=1,#node.Children do
			sum = sum + self:CountTris(node.Children[i])
		end
		return sum
	elseif node.Type == MATRIX then
		return node.W*node.H*16
	end
	return 12
end

function ENT:Draw()
	self:DrawModel()
	
	local self2 = self:GetTable()
	
	
	
	
	if self2.Tree then
		
		local oldw = ScrW()
		local oldh = ScrH()

		local NewRT = self2.GPU.RT
		local OldRT = render.GetRenderTarget()

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0, 0, 1024, 1024)
		if self:GetPos():DistToSqr(EyePos()) < 262144 then
			local fade = self2.Fade
			cam.Start2D()
				render.OverrideBlend( true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
				surface.SetDrawColor(self2.Bgred,self2.Bggreen,self2.Bgblue,self2.Bgalpha)
				surface.DrawRect( 0, 0, 1, 1 )
				for i=0,self2.BitIndex-1 do
					local x = (i+1)%1024
					local y = math.floor((i+1)/1024)
					fade[i] = (fade[i] or 0)*0.92 + 0.01
					if bit.band(self2.Memory[bit.rshift(i,3)] or 0,bit.lshift(1,bit.band(i,7))) ~= 0 then
						fade[i] = fade[i] + 0.07
					end

					if fade[i] < 0.1 or fade[i] > 0.14 and fade[i] < 0.95 then
						local color = self2.Colors[i]
						surface.SetDrawColor(color[1]*fade[i]+self2.Bgred*(1-fade[i]),color[2]*fade[i]+self2.Bggreen*(1-fade[i]),color[3]*fade[i]+self2.Bgblue*(1-fade[i]),fade[i]*color[4]+self2.Bgalpha*(1-fade[i])*0.15)
						if x == 0 and y == 0 then
							break
						end
						surface.DrawRect( x, y, 1, 1 )
					end
				end
				render.OverrideBlend( false )
			cam.End2D()
		end
		render.SetViewPort(0, 0, oldw, oldh)
		render.SetRenderTarget(OldRT)
		
		
	    local OldTex = WireGPU_matSegment:GetTexture("$basetexture")
	    WireGPU_matSegment:SetTexture("$basetexture", self2.GPU.RT)
		render.SetMaterial( WireGPU_matSegment )
		
		local monitor, pos, ang = self2.GPU:GetInfo()
		local h = self2.ResolutionH
		local scale = monitor.RS*1024/h
		local m = Matrix()
		m:SetAngles( ang )
		m:SetTranslation( pos )
		m:SetScale( Vector( scale, -scale, 1 ) )
		--cam.PushModelMatrix( self:GetWorldTransformMatrix() )
		cam.PushModelMatrix( m )

		
		for i=1,#self2.TreeMesh do
			self2.TreeMesh[i]:Draw()
		end
		cam.PopModelMatrix()
		
		for i=1,#self2.Texts do
			local text = self2.Texts[i]
			local newm = text[_TEXT_MATRIX]
			
			surface.SetFont( "Default" )
			cam.Start3D2D(pos, ang, scale)
				cam.PushModelMatrix( newm, true )
				draw.DrawText( text[_TEXT_TEXT], "Default" )
				cam.PopModelMatrix()	
			cam.End3D2D()
		end
		
		
		--cam.PopModelMatrix()
		
		WireGPU_matSegment:SetTexture("$basetexture", OldTex)
	end
	
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
	self.Fgalpha = net.ReadUInt(8)
	self.Bgblue = net.ReadUInt(8)
	self.Bggreen = net.ReadUInt(8)
	self.Bgred = net.ReadUInt(8)
	self.Bgalpha = net.ReadUInt(8)
	self.XorMask = net.ReadUInt(8)
	
	self.Cr = self.Fgred
	self.Cg = self.Fggreen
	self.Cb = self.Fgblue
	self.Ca = self.Fgalpha
	self.LocalXX = 1
	self.LocalXY = 0
	self.LocalYX = 0
	self.LocalYY = 1
	self.BitIndex = 0
	self.TransformStack = {}
	self.Colors = {}
	local monitor, pos, ang = self.GPU:GetInfo()
	local h = self.ResolutionH
	local w = h/monitor.RatioX
	
	self.ZOffset = monitor.RS*1024/h
	self.LocalX = -w/2
	self.LocalY = -h/2
	self.TreeMesh = self.TreeMesh or {}
	self.Texts = {}
	for i=#self.TreeMesh,1,-1 do
		self.TreeMesh[i]:Destroy()
		self.TreeMesh[i] = nil
	end
	self.TreeMesh[#self.TreeMesh + 1] = Mesh()
	self.Tris = self:CountTris(self.Tree)
	mesh.Begin(self.TreeMesh[#self.TreeMesh],MATERIAL_TRIANGLES,math.min(10922,self.Tris))
	self.Tris = self.Tris - 10922
	
	mesh.Position(self.LocalX,self.LocalY,0) mesh.Color(255,255,255,255) mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	mesh.Position(self.LocalX+w,self.LocalY,0) mesh.Color(255,255,255,255) mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	mesh.Position(self.LocalX+w,self.LocalY+h,0) mesh.Color(255,255,255,255)mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	
	mesh.Position(self.LocalX,self.LocalY,0) mesh.Color(255,255,255,255) mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	mesh.Position(self.LocalX+w,self.LocalY+h,0) mesh.Color(255,255,255,255) mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	mesh.Position(self.LocalX,self.LocalY+h,0) mesh.Color(255,255,255,255) mesh.TexCoord(0, 1/2048, 1/2048, 1/2048, 1/2048) mesh.AdvanceVertex()
	self.CurTris = 6
	
	self:DrawGroup(self.Tree)
	mesh.End()
end
