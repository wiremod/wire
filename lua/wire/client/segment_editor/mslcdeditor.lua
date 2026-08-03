local Editor = {}

OFFSET = -3
ALIGN = -2
GROUP = -1
UNION = 0
SEGMENT = 1
TEXT = 2
POLY = 2
MATRIX = 3
SegmentTypeNames = {
[GROUP] = "Group",
[UNION] = "Union",
[SEGMENT] = "Segment",
[POLY] = "Poly",
[MATRIX] = "Matrix",
[ALIGN] = "Align",
[OFFSET] = "Offset",
}

function Editor:Init()
	self.SegmentTree = {
		Type=GROUP,
		X=0,
		Y=0,
		Children=
		{
		
		}
	}

	self.DraggingWorld = false
	self.DraggingNode = nil
	self.DraggingOffset = { 0, 0 }
	self.DraggingPolyVert = nil
	
	
	
	self.SelectedSegments = nil
	self.SelectedSegment = nil
	self.SelectedVert = nil
	self.Selecting = nil

	self.LastMousePos = { 0, 0 }
	self.MouseDown = false

	self.GateSize = FPGANodeSize
	self.GridSize = self.GateSize * 2
	self.GridEnabled = true

	self.IOSize = 2

	self.BackgroundColor = Color(40, 40, 40, 255)
	self.GridColor = Color(50, 50, 50, 255)
	self.SelectionColor = Color(220, 220, 100, 255)
	
	self.ZoomHideThreshold = 2
	self.ZoomThreshold = 7
	
	self.LastFrameTime = SysTime()
	
	self.Mode = POLY
	self.Zoom = 5
	self.Position = {0,0}
	
	self.LocalXX = self.Zoom
	self.LocalXY = 0
	self.LocalYX = 0
	self.LocalYY = self.Zoom
	self.LocalX = self:GetWide() / 2 - self.Position[1]*self.Zoom
	self.LocalY = self:GetTall() / 2 - self.Position[2]*self.Zoom
end

function Editor:SetMode(mode)
	self.Mode = mode
end

local function Transform(self,x,y)
	return x*self.LocalXX+y*self.LocalXY+self.LocalX, x*self.LocalYX+y*self.LocalYY+self.LocalY
end

local function TransformOffset(self,x,y)
	return {
		x*self.LocalXX+y*self.LocalXY,
		x*self.LocalYX+y*self.LocalYY
	}
end


local function PushTransform(self,XX,XY,YX,YY)
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

local function PopTransform(self)
	self.LocalXX,self.LocalXY,self.LocalYX,self.LocalYY = unpack(self.TransformStack[#self.TransformStack])
	self.TransformStack[#self.TransformStack] = nil
end

local function PolyDimensions(self,poly,tlocal)
	self.LocalX = self.LocalX + tlocal[1]
	self.LocalY = self.LocalY + tlocal[2]
	local minx, miny = Transform(self, poly[1].x, poly[1].y)
	local maxx, maxy = minx, miny
	for i, v in ipairs(poly) do
		x, y = Transform(self, v.x, v.y)
		minx, miny = math.min(minx, x), math.min(miny, y)
		maxx, maxy = math.max(maxx, x), math.max(maxy, y)
	end
	self.LocalX = self.LocalX - tlocal[1]
	self.LocalY = self.LocalY - tlocal[2]
	return minx, miny, maxx, maxy
end

local function MatrixDimensions(self,matrix,tlocal)
	self.LocalX = self.LocalX + tlocal[1]
	self.LocalY = self.LocalY + tlocal[2]
	local minx, miny = Transform(self, 0, 0)
	local maxx, maxy = Transform(self, matrix.W*matrix.OffsetX,matrix.H*matrix.OffsetY)
	self.LocalX = self.LocalX - tlocal[1]
	self.LocalY = self.LocalY - tlocal[2]
	return minx, miny, maxx, maxy
end

function LoopToTris(poly)
	poly = table.Copy(poly)
	if #poly == 3 then
		return poly
	end
	local tries = 0
	local tris = {}
	local i = 0
	while #poly > 3 do
		tries = tries + 1
		i = i%#poly+1
		local a = poly[i]
		local b = poly[i%#poly+1]
		local c = poly[(i+1)%#poly+1]
		local lax = a.x-b.x
		local lay = a.y-b.y
		local la = a.y*lax-a.x*lay
		
		local lbx = b.x-c.x
		local lby = b.y-c.y
		local lb = b.y*lbx-b.x*lby
		
		local lcx = c.x-a.x
		local lcy = c.y-a.y
		local lc = c.y*lcx-c.x*lcy
		
		if (c.y*lax - c.x*lay) > la then
			goto fail
		end
		

		for j,p in ipairs(poly) do
			if j == i or j == (i%#poly+1) or j == ((i+1)%#poly+1) then
				goto skip
			end
			local lpa = p.y*lax - p.x*lay
			local lpb = p.y*lbx - p.x*lby
			local lpc = p.y*lcx - p.x*lcy
			if lpa <= la and lpb <= lb and lpc <= lc then
				goto fail
			end
			::skip::
		end
		
		tris[#tris+1] = a
		tris[#tris+1] = b
		tris[#tris+1] = c
		table.remove(poly,i%#poly+1)
		tries = 0
		--i = (i-2)%#poly+1
		--i = 0
		
		::fail::
		if tries > #poly then
			break
		end
	end
	
	tris[#tris+1] = poly[1]
	tris[#tris+1] = poly[2]
	tris[#tris+1] = poly[3]
	return tris
end


local function DrawPoly(self,poly)
	local selected = poly == self.SelectedSegment
	local transformedLocal = TransformOffset(self,poly.X or 0,poly.Y or 0)
	
	local x, y = self:LocalToScreen(0,0)
	local m = Matrix()
	m:Translate(Vector(x,y,0))
	m:Mul(Matrix({
		{self.LocalXX,self.LocalXY,0,self.LocalX + transformedLocal[1]},
		{self.LocalYX,self.LocalYY,0,self.LocalY + transformedLocal[2]},
		{0,0,1,0},
		{0,0,0,1}
	}))
	m:Translate(Vector(-x,-y,0))
	cam.PushModelMatrix(m)
	--surface.DrawPoly(poly.Poly)
	local origdraw = surface.GetDrawColor()
	if selected then
		surface.SetDrawColor(255,192,192,255)
	else
		--surface.SetDrawColor(255,255,255,255)
	end
	
	for i,p in ipairs(poly.Poly) do
		local op = poly.Poly[i%#poly.Poly+1]
		surface.DrawLine(p.x-0.5,p.y-0.5,op.x-0.5,op.y-0.5)
	end
	
	surface.SetDrawColor(255,255,0,255)
	for i,p in ipairs(poly.Poly) do
		local selectedvert = i == self.SelectedVert and selected
		local m = Matrix()
		m:Translate(Vector(x+p.x,y+p.y,0))
		m:Scale(Vector(1/self.Zoom,1/self.Zoom,0))
		m:Translate(Vector(-x,-y,0))
		cam.PushModelMatrix(m, true)
		if selectedvert then
			surface.SetDrawColor(255,0,0,255)
			surface.DrawRect(-4,-4,8,8)
			surface.SetDrawColor(255,255,0,255)
		else
			surface.DrawRect(-4,-4,8,8)
		end
		cam.PopModelMatrix()
	end
	if selected then
		surface.SetDrawColor(0,255,255,255)
	else
		surface.SetDrawColor(0,255,0,255)
	end
	m = Matrix()
	m:Translate(Vector(x-4.0/self.Zoom,y-4.0/self.Zoom,0))
	m:Scale(Vector(1/self.Zoom,1/self.Zoom,0))
	m:Translate(Vector(-x,-y,0))
	cam.PushModelMatrix(m, true)
	surface.DrawRect(0,0,8,8)
	cam.PopModelMatrix()
	surface.SetDrawColor(origdraw)
	cam.PopModelMatrix()
	
	return PolyDimensions(self,poly.Poly,transformedLocal)
end

local function DrawMatrix(self,matrix)
	local selected = matrix == self.SelectedSegment
	local transformedLocal = TransformOffset(self,matrix.X or 0,matrix.Y or 0)
	
	local x, y = self:LocalToScreen(0,0)
	local m = Matrix()
	m:Translate(Vector(x,y,0))
	m:Mul(Matrix({
		{self.LocalXX,self.LocalXY,0,self.LocalX + transformedLocal[1]},
		{self.LocalYX,self.LocalYY,0,self.LocalY + transformedLocal[2]},
		{0,0,1,0},
		{0,0,0,1}
	}))
	m:Translate(Vector(-x,-y,0))
	cam.PushModelMatrix(m)
	
	local origdraw = surface.GetDrawColor()
	
	if selected then
		surface.SetDrawColor(255,192,192,255)
	else
		--surface.SetDrawColor(255,255,255,255)
	end
	for y = 0,matrix.H-1 do
		for x = 0,matrix.W-1 do
			surface.DrawRect(x*matrix.OffsetX,y*matrix.OffsetY,matrix.ScaleW,matrix.ScaleH)
		end
	end
	if selected then
		surface.SetDrawColor(0,255,255,255)
	else
		surface.SetDrawColor(0,255,0,255)
	end
	m = Matrix()
	m:Translate(Vector(x-4.0/self.Zoom,y-4.0/self.Zoom,0))
	m:Scale(Vector(1/self.Zoom,1/self.Zoom,0))
	m:Translate(Vector(-x,-y,0))
	cam.PushModelMatrix(m, true)
	surface.DrawRect(0,0,8,8)
	cam.PopModelMatrix()
	surface.SetDrawColor(origdraw)
	cam.PopModelMatrix()
	
	return MatrixDimensions(self,matrix,transformedLocal)
end

local function DrawUnion(self,union)
	for k,v in ipairs(union.Children) do
		if v.Type == GROUP then
			DrawGroup(self,v)
		elseif v.Type == UNION then
			DrawUnion(self,v)
		elseif v.Type == POLY then 
			DrawPoly(self,v)
		elseif v.Type == MATRIX then 
			DrawMatrix(self,v)
		end
	end
end

local function DrawGroup(self,group)
	if #group.Children == 0 then
		return
	end
	
	
	local angle = math.rad(group.Rotation or 0)
	local transformedLocal = TransformOffset(self,group.X or 0,group.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1]
	self.LocalY = self.LocalY + transformedLocal[2]
	PushTransform(self,math.cos(angle),
	math.sin(angle),
	-math.sin(angle),
	math.cos(angle))
	PushTransform(self,1,
	-(group.SkewX or 0),
	(group.SkewY or 0),
	1)
	local minx, miny = nil, nil
	local maxx, maxy = minx, miny
	
	if group.HasColor then
		surface.SetDrawColor(group.R or 255,group.G or 255,group.B or 255,group.A or 255)
	end
	
	for k,v in ipairs(group.Children) do
		local nminx, nminy, nmaxx, nmaxy
		if v.Type == GROUP then
			nminx, nminy, nmaxx, nmaxy = DrawGroup(self,v)
		elseif v.Type == UNION then
			nminx, nminy, nmaxx, nmaxy = DrawGroup(self,v)
		elseif v.Type == POLY then 
			nminx, nminy, nmaxx, nmaxy = DrawPoly(self,v)
		elseif v.Type == MATRIX then 
			nminx, nminy, nmaxx, nmaxy = DrawMatrix(self,v)
		end
		if nminx ~= nil then
			minx, miny = math.min(nminx, minx or nminx), math.min(nminy, miny or nminy)
			maxx, maxy = math.max(nmaxx, maxx or nmaxx), math.max(nmaxy, maxy or nmaxy)
		end
	end
	--m:Translate(Vector(x+p.x-4.0/self.Zoom,y+p.y-4.0/self.Zoom,0))
	--m:Scale(Vector(1/self.Zoom,1/self.Zoom,0))
	--m:Translate(Vector(-x,-y,0))
	local x, y = self:LocalToScreen(0,0)
	local m = Matrix()
	m:Translate(Vector(x,y,0))
	m:Mul(Matrix({
		{self.LocalXX/self.Zoom,self.LocalXY/self.Zoom,0,self.LocalX + transformedLocal[1]},
		{self.LocalYX/self.Zoom,self.LocalYY/self.Zoom,0,self.LocalY + transformedLocal[2]},
		{0,0,1,0},
		{0,0,0,1}
	}))
	m:Translate(Vector(-x,-y,0))
	--cam.PushModelMatrix(m,true)
	if group.HasColor then
		surface.SetDrawColor(group.R or 255,group.G or 255,group.B or 255,group.A or 255)
	else
		surface.SetDrawColor(255,255,255,255)
	end
	if minx ~= nil then
		surface.DrawOutlinedRect(minx,miny,(maxx-minx),(maxy-miny))
	end
	--cam.PopModelMatrix()
	PopTransform(self)
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]


	return minx,miny,maxx,maxy
end

local function MoveSelectGroup(group, deltaX, deltaY, exclude)
	for i,v in ipairs(group.Children) do
		if v == exclude then
			goto skip
		end
		if v.Type == GROUP then
			MoveSelectGroup(v, deltaX, deltaY, exclude)
		else
			v.X = v.X + deltaX
			v.Y = v.Y + deltaY
		end
		::skip::
	end
end

function Editor:Paint()
	local width = self:GetWide()
	local height = self:GetTall()
	local snapincrement = GetConVar("wire_multisegmentlcd_snapinc"):GetFloat()
	-- Update animation frame time
	self.LastFrameTime = SysTime()

	surface.SetDrawColor(self.BackgroundColor)
	draw.NoTexture()
	surface.DrawRect(0, 0, width, height)
	
	-- detects if mouse is let go outside of the window
	if not input.IsMouseDown(MOUSE_RIGHT) then
		self.DraggingWorld = nil
	end
	if not input.IsMouseDown(MOUSE_LEFT) then
		self.DraggingNode = nil
		self.DrawingConnection = nil
		self.DrawingSelection = nil
	end

	local x, y = self:CursorPos()
	
	local dx, dy = self.LastMousePos[1] - x, self.LastMousePos[2] - y
	-- moving the plane
	if self.DraggingWorld then
		self.Position = { self.Position[1] + dx * (1 / self.Zoom), self.Position[2] + dy * (1 / self.Zoom) }
	end
	local wx, wy = self:ScrToPos(x, y)
	
	if self.DraggingPolyVert then
		
		if self.DraggingPolyVert[2] == 0 then
			local poly = self.DraggingPolyVert[1]
			local origX = poly.X
			local origY = poly.Y
			poly.X = wx-self.DraggingPolyVert[3]
			poly.Y = wy-self.DraggingPolyVert[4]
			if snapincrement > 0.001 then
				poly.X = math.floor(poly.X/snapincrement + 0.5)*snapincrement
				poly.Y = math.floor(poly.Y/snapincrement + 0.5)*snapincrement
			end
			local deltaX = poly.X-origX
			local deltaY = poly.Y-origY
			if self.SelectedSegments ~= nil then
				MoveSelectGroup(self.SelectedSegments, deltaX, deltaY, poly)
			end
		else
			local vert = self.DraggingPolyVert[1].Poly[self.DraggingPolyVert[2]]
			vert.x = wx-self.DraggingPolyVert[3]
			vert.y = wy-self.DraggingPolyVert[4]
			if snapincrement > 0.001 then
				vert.x = math.floor(vert.x/snapincrement + 0.5)*snapincrement
				vert.y = math.floor(vert.y/snapincrement + 0.5)*snapincrement
			end
		end
	end
	
	self:PaintGrid()
	
	
	self.LocalXX = self.Zoom
	self.LocalXY = 0
	self.LocalYX = 0
	self.LocalYY = self.Zoom
	self.LocalX = self:GetWide() / 2 - self.Position[1]*self.Zoom
	self.LocalY = self:GetTall() / 2 - self.Position[2]*self.Zoom
	
	surface.SetDrawColor(255, 255, 255, 255)
	self.TransformStack = {}
	DisableClipping(true)
	self.SegmentTree.X = 0
	self.SegmentTree.Y = 0
	self.minx,self.miny,self.maxx,self.maxy = DrawGroup(self,self.SegmentTree)
	
	if self.SelectedSegments then
		self.SelectedSegments.HasColor = true
		self.SelectedSegments.G = 0
		DrawGroup(self,self.SelectedSegments)
		self.SelectedSegments.HasColor = nil
		self.SelectedSegments.G = nil
	end
	if self.Selecting ~= nil then
		local sminx = math.min(self.Selecting.x,wx)
		local sminy = math.min(self.Selecting.y,wy)
		local smaxx = math.max(self.Selecting.x,wx)
		local smaxy = math.max(self.Selecting.y,wy)
		sminx,sminy = self:PosToScr(sminx,sminy)
		smaxx,smaxy = self:PosToScr(smaxx,smaxy)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawOutlinedRect(sminx-1,sminy-1,smaxx-sminx+2,smaxy-sminy+2)
	end
	
	DisableClipping(false)
	--self:GetPolyVertAt(wx,wy)
	local x, y = self:CursorPos()
	self.LastMousePos = { x, y }
	
	self.ParentPanel.C.MatrixProps:SetParent(self.ParentPanel.C.Invisible)
	self.ParentPanel.C.VertProps:SetParent(self.ParentPanel.C.Invisible)
	self.ParentPanel.C.BlankProps:SetParent(self.ParentPanel.C.Invisible)
	self.ParentPanel.C.GroupProps:SetParent(self.ParentPanel.C.Invisible)
	self.ParentPanel.C.Properties:SetParent(self.ParentPanel.C.Invisible)
	
	if self.SelectedSegment then
		self.ParentPanel.C.Properties:SetParent(self.ParentPanel.C.PropList)
		self.ParentPanel.C.Prop_X:SetValue(self.SelectedSegment.X)
		self.ParentPanel.C.Prop_Y:SetValue(self.SelectedSegment.Y)
		self.ParentPanel.C.Prop_Name:SetValue(self.SelectedSegment.Text or "")
		
		
		if self.SelectedSegment.Type == POLY and self.SelectedVert ~= 0 then
			self.ParentPanel.C.VertProps:SetParent(self.ParentPanel.C.PropList)
			self.ParentPanel.C.Vert_X:SetValue(self.SelectedSegment.Poly[self.SelectedVert].x)
			self.ParentPanel.C.Vert_Y:SetValue(self.SelectedSegment.Poly[self.SelectedVert].y)
		end
		
		if self.SelectedSegment.Type == MATRIX then
			self.ParentPanel.C.MatrixProps:SetParent(self.ParentPanel.C.PropList)
			self.ParentPanel.C.Matrix_W:SetValue(self.SelectedSegment.W)
			self.ParentPanel.C.Matrix_H:SetValue(self.SelectedSegment.H)
			self.ParentPanel.C.Matrix_ScaleW:SetValue(self.SelectedSegment.ScaleW)
			self.ParentPanel.C.Matrix_ScaleH:SetValue(self.SelectedSegment.ScaleH)
			self.ParentPanel.C.Matrix_OffsetX:SetValue(self.SelectedSegment.OffsetX)
			self.ParentPanel.C.Matrix_OffsetY:SetValue(self.SelectedSegment.OffsetY)
		end
		
		if self.SelectedSegment.Type == ALIGN or self.SelectedSegment.Type == OFFSET then
			self.ParentPanel.C.BlankProps:SetParent(self.ParentPanel.C.PropList)
			self.ParentPanel.C.Blank_Size:SetValue(self.SelectedSegment.Size)
		end
		
		if self.SelectedSegment.Type == GROUP or self.SelectedSegment.Type == UNION then
			self.ParentPanel.C.GroupProps:SetParent(self.ParentPanel.C.PropList)
			self.ParentPanel.C.Group_HasColor:SetValue(self.SelectedSegment.HasColor)
			self.ParentPanel.C.Group_Color:SetColor(Color(
				self.SelectedSegment.R or 255, 
				self.SelectedSegment.G or 255,
				self.SelectedSegment.B or 255,
				self.SelectedSegment.A or 255))
		end
	end
	
end

function Editor:SetData(data)
	local ok, data = pcall(WireLib.von.deserialize, data)
	if not ok then
		self:ClearData()
		self.C.Name:SetValue("corrupt")
		return
	end
	
	if data.Position then self.Position = data.Position else self.Position = { 0, 0 } end
	if data.Zoom then self.Zoom = data.Zoom else self.Zoom = 5 end
	if data.SegmentTree then self.SegmentTree = data.SegmentTree end
end

function Editor:GetData()
	self.SegmentTree.X = -((self.minx or 0)-self.LocalX)/self.Zoom
	self.SegmentTree.Y = -((self.miny or 0)-self.LocalY)/self.Zoom
	return WireLib.von.serialize({
			SegmentTree = self.SegmentTree,
			Position = self.Position,
			Zoom = self.Zoom
		}, false)
end

function Editor:ClearData()
	self.Position = { 0, 0 }
	self.Zoom = 5
	self.SegmentTree = {
		Type=GROUP,
		X=0,
		Y=0,
		Children=
		{
		
		}
	}
end

function Editor:PaintGrid()
	if not self.GridEnabled then return end

	local gridSize = self.GridSize * self.Zoom
	if gridSize < 5 then return end

	local screenW = self:GetWide()
	local screenH = self:GetTall()

	local startX = math.floor((self.Position[1] - screenW / (2 * self.Zoom)) / self.GridSize) * self.GridSize
	local endX = math.ceil((self.Position[1] + screenW / (2 * self.Zoom)) / self.GridSize) * self.GridSize
	local startY = math.floor((self.Position[2] - screenH / (2 * self.Zoom)) / self.GridSize) * self.GridSize
	local endY = math.ceil((self.Position[2] + screenH / (2 * self.Zoom)) / self.GridSize) * self.GridSize

	surface.SetDrawColor(self.GridColor)

	for x = startX, endX, self.GridSize do
		local sx, sy1 = self:PosToScr(x, startY)
		local _, sy2 = self:PosToScr(x, endY)
		surface.DrawLine(sx, sy1, sx, sy2)
	end

	for y = startY, endY, self.GridSize do
		local sx1, sy = self:PosToScr(startX, y)
		local sx2, _ = self:PosToScr(endX, y)
		surface.DrawLine(sx1, sy, sx2, sy)
	end
end

-- EDITING

function Editor:CreateMatrix(x, y)
	local group = nil
	local children = nil
	if group ~= nil then
		children = group.Children
	end
	
	if children == nil then
		children = self.SegmentTree.Children
		group = self.SegmentTree
	end
	local n = {Type=MATRIX, X=x,Y=y,OffsetX=8,OffsetY=8,W=4,H=4,ScaleW=7,ScaleH=7}
	children[#children+1] = n
end

function Editor:CreatePoly(x, y)
	local group = nil
	local children = nil
	if group ~= nil then
		children = group.Children
	end
	
	if children == nil then
		children = self.SegmentTree.Children
		group = self.SegmentTree
	end
	local snapincrement = GetConVar("wire_multisegmentlcd_snapinc"):GetFloat()
	if snapincrement > 0.001 then
		x = math.floor(x/snapincrement + 0.5)*snapincrement
		y = math.floor(y/snapincrement + 0.5)*snapincrement
	end
	local n = {Type=POLY, X=x,Y=y, Poly={{x=-math.max(1,snapincrement)*2,y=-math.max(1,snapincrement)*2},{x=math.max(1,snapincrement)*2,y=0},{x=0,y=math.max(1,snapincrement)*2}}}
	children[#children+1] = n
end

-- KEYBOARD

function Editor:OnKeyCodePressed(code)
	local x, y = self:CursorPos()
	local gx, gy = self:ScrToPos(x, y)
	local snapincrement = GetConVar("wire_multisegmentlcd_snapinc"):GetFloat()
	if snapincrement > 0.001 then
		gx = math.floor(gx/snapincrement + 0.5)*snapincrement
		gy = math.floor(gy/snapincrement + 0.5)*snapincrement
	end
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	if control then
		if code == KEY_C then
			if self.SelectedSegments then
				self.ParentPanel.Clipboard = table.Copy(self.SelectedSegments)
			else
				self.ParentPanel.Clipboard = table.Copy(self.SelectedSegment)
			end
		elseif code == KEY_V then
			if self.ParentPanel.Clipboard ~= nil then
				self.ParentPanel.Clipboard.X = gx
				self.ParentPanel.Clipboard.Y = gy
				self.SegmentTree.Children[#self.SegmentTree.Children+1] = table.Copy(self.ParentPanel.Clipboard)
				self.ParentPanel:RebuildNodes()
			end
		end
	elseif code == KEY_C then
		--Create
		if self.Mode == MATRIX then
			self:CreateMatrix(gx, gy)
		elseif self.Mode == POLY then
			self:CreatePoly(gx, gy)
		end
		self.ParentPanel:RebuildNodes()
	end
end

-- MOUSE

function Editor:OnMouseWheeled(delta)
	local sx, sy = self:CursorPos()

	self.Zoom = self.Zoom + delta * 0.1 * self.Zoom
	if self.Zoom < 0.1 then self.Zoom = 0.1 end
	if self.Zoom > 100 then self.Zoom = 100 end
end


function Editor:GetPolyEdgeAtPoly(x, y, poly)
	--local x,y = x/self.Zoom, y/self.Zoom 
	for i,v in ipairs(poly.Poly) do
		local o = poly.Poly[i%#poly.Poly+1]
		local lx = o.x-v.x
		local ly = o.y-v.y
		local d = math.sqrt(lx*lx+ly*ly)
		local ls = (v.x*ly - v.y*lx)/d
		local lf = (v.x*lx + v.y*ly)/d
		local f = (x*lx + y*ly)/d - lf
		local s = (x*ly - y*lx)/d - ls
		if f > 0 and f < d and s >= -10/self.Zoom and s <= 10/self.Zoom then
			return poly, i
		end
	end
	return nil, nil
end

function Editor:GetPolyEdgeAtGroup(x, y, group)
	local x = x-group.X
	local y = y-group.Y
	for i,v in ipairs(group.Children) do
		if v.Type == GROUP then
			ri, rv, ex, ey = self:GetPolyEdgeAtGroup(x, y, v)
			if ri then
				return ri, rv, ex, ey
			end
		elseif v.Type == POLY then
			ri, rv = self:GetPolyEdgeAtPoly(x-v.X, y-v.Y, v)
			if ri then
				return ri, rv, x-v.X, y-v.Y
			end
		end
		
	end
	return nil, nil
end

function Editor:GetPolyEdgeAt(x, y)
	return self:GetPolyEdgeAtGroup(x, y, self.SegmentTree)
end


function Editor:GetPolyVertAtPoly(x, y, poly)
	local x,y = (x)*self.Zoom, (y)*self.Zoom 
	for i,v in ipairs(poly.Poly) do
		local vx = v.x*self.Zoom
		local vy = v.y*self.Zoom
		surface.DrawRect(vx-x-4,vy-y-4,8,8)
		if math.abs(vx-x) < 4 and math.abs(vy-y) < 4 then
			return poly, i
		end
		
	end
	if math.abs(x) < 4 and math.abs(y) < 4 then
		return poly, 0
	end
	return nil, nil
end

function Editor:GetPolyVertAtGroup(x, y, group)
	for i,v in ipairs(group.Children) do
		if v.Type == GROUP then
			ri, rv, g, gi = self:GetPolyVertAtGroup(x-v.X, y-v.Y, v)
			if ri then
				return ri, rv, g, gi
			end
		elseif v.Type == POLY then
			ri, rv = self:GetPolyVertAtPoly(x-v.X, y-v.Y, v)
			if ri then
				return ri, rv, group, i
			end
		elseif v.Type == MATRIX then
			if math.abs(x-v.X)*self.Zoom < 4 and math.abs(y-v.Y)*self.Zoom < 4 then
				return v, 0, group, i
			end
		end
		
	end
	return nil, nil, nil, nil
end

function Editor:GetPolyVertAt(x, y)
	return self:GetPolyVertAtGroup(x, y, self.SegmentTree)
end


function Editor:SelectSegmentsAtGroup(x1, y1, x2, y2, group)
	local sel = {
		X = group.X,
		Y = group.Y,
		Type = GROUP,
		Children = {}
	}
	local x1 = x1-group.X
	local y1 = y1-group.Y
	local x2 = x2-group.X
	local y2 = y2-group.Y
	for i,v in ipairs(group.Children) do
		if v.Type == GROUP then
			sel.Children[#sel.Children+1] = self:SelectSegmentsAtGroup(x1, y1, x2, y2, v)
		elseif v.Type == POLY then
			if v.X >= x1 and v.Y >= y1 and v.X <= x2 and v.Y <= y2 then
				sel.Children[#sel.Children+1] = v
			end
		end
	end
	if #sel.Children > 0 then
		return sel
	end
	--if #sel.Children == 1 then
	--	return sel.Children[1]
	--end
	return nil
end

function Editor:SelectSegments(x1, y1, x2, y2)
	local minx = math.min(x1,x2)
	local miny = math.min(y1,y2)
	local maxx = math.max(x1,x2)
	local maxy = math.max(y1,y2)
	local grp = self:SelectSegmentsAtGroup(minx, miny, maxx, maxy, self.SegmentTree)
	if grp == nil then
		self.SelectedSegments = nil
	elseif grp.Type ~= GROUP then
		self.SelectedSegments = {
			X = 0,
			Y = 0,
			Type = GROUP,
			Children = {grp}
		}
	else
		self.SelectedSegments = grp
	end
end

function Editor:PruneGroups(children)
	for i=#children,1,-1 do
		local v = children[i]
		if v.Type == GROUP then
			if #v.Children == 0 then
				table.remove(children,i)
			else
				self:PruneGroups(v.Children)
			end
		end
	end
end

-- MOUSE

function Editor:OnMousePressed(code)
	self:RequestFocus() --Fix for weird bug, remove once resolved

	if code == MOUSE_LEFT then
		self.MouseDown = true

		--double click detection
		local doubleClick
		if self.LastClick then
			doubleClick = SysTime() - self.LastClick < 0.3
		else doubleClick = false end
		self.LastClick = SysTime()

		local x, y = self:ScrToPos(self:CursorPos())
		local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
		
		local pvKey, pvIndex, pvGroup, pvGroupIndex = self:GetPolyVertAt(x, y)
		
		if pvKey then
			if control then
				if pvIndex ~= 0 then
					table.remove(pvKey.Poly,pvIndex)
					if #pvKey.Poly < 3 then
						table.remove(pvGroup.Children,pvGroupIndex)
						self:PruneGroups(self.SegmentTree.Children)
						self.ParentPanel:RebuildNodes()
					end
				else
					table.remove(pvGroup.Children,pvGroupIndex)
					self:PruneGroups(self.SegmentTree.Children)
					self.ParentPanel:RebuildNodes()
				end
			else
				if pvIndex == 0 then
					self.DraggingPolyVert = {pvKey,pvIndex,x-pvKey.X,y-pvKey.Y}
				else
					local point = pvKey.Poly[pvIndex]
					self.DraggingPolyVert = {pvKey,pvIndex,x - point.x, y - point.y}
				end
				
			end
		elseif not control then
			local peKey, peIndex, ex, ey = self:GetPolyEdgeAt(x, y)
			
			if peKey then
				table.insert(peKey.Poly,peIndex+1,{x=ex,y=ey})
				self.DraggingPolyVert = {peKey,peIndex+1,x-ex,y-ey}
			end
		end
		self.SelectedSegment = nil
		self.SelectedVert = nil
		if self.DraggingPolyVert then
			self.SelectedSegment = self.DraggingPolyVert[1]
			self.SelectedVert = self.DraggingPolyVert[2]
		else
			self.Selecting = {x=x,y=y}
		end
		
	
	elseif code == MOUSE_RIGHT then
		-- PLANE DRAGGING
		self.DraggingWorld = true
	end
end

function Editor:OnMouseReleased(code)
	local x, y = self:ScrToPos(self:CursorPos())

	if code == MOUSE_LEFT then
		self.MouseDown = false
		self.DraggingNode = nil
		self.DraggingPolyVert = nil
		if self.Selecting ~= nil then
			self:SelectSegments(self.Selecting.x,self.Selecting.y,x,y)
		end
		self.Selecting = nil
	elseif code == MOUSE_RIGHT then
		self.DraggingWorld = false
	end

end

-- UTILITY

function Editor:PosToScr(x, y)
	return (self:GetWide()) / 2 - (self.Position[1] - x) * self.Zoom, self:GetTall() / 2 - (self.Position[2] - y) * self.Zoom
end

function Editor:ScrToPos(x, y)
	return self.Position[1] - ((self:GetWide()) / 2 - x) / self.Zoom, self.Position[2] - (self:GetTall() / 2 - y) / self.Zoom
end

function Editor:AlignPosToGrid(x, y)
	return math.Round(x / self.GateSize) * self.GateSize, math.Round(y / self.GateSize) * self.GateSize
end

function Editor:DragHoverClick(hoverTime)
	--print(hoverTime)
end

vgui.Register("MSLCDEditor", Editor, "Panel");
