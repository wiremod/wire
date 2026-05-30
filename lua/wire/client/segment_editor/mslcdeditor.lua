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
	
	self.Mode = SEGMENT
end

function Editor:SetMode(mode)
	self.Mode = mode
end

function Transform(self,x,y)
	return x*self.LocalXX+y*self.LocalXY+self.LocalX, x*self.LocalYX+y*self.LocalYY+self.LocalY
end

function TransformOffset(self,x,y)
	return {
		x*self.LocalXX+y*self.LocalXY,
		x*self.LocalYX+y*self.LocalYY
	}
end


function PushTransform(self,XX,XY,YX,YY)
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

function PopTransform(self)
	self.LocalXX,self.LocalXY,self.LocalYX,self.LocalYY = unpack(self.TransformStack[#self.TransformStack])
	self.TransformStack[#self.TransformStack] = nil
end

function PolyDimensions(self,poly,tlocal)
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


function DrawSegment(self,segment)
	local transformedLocal = TransformOffset(self,segment.X or 0,segment.Y or 0)
	local angle = math.rad(segment.Rotation or 0)
	PushTransform(self,math.cos(angle),
	math.sin(angle)-(segment.SkewX or 0),
	-math.sin(angle)+(segment.SkewY or 0),
	math.cos(angle))
	--self:Transform(,segment.H/2+(segment.H*(segment.BevelSkew or 0))),
	local bevel = math.min(segment.H,segment.W)/2*(segment.Bevel or 0)
	
	local rect = {
		{x=bevel,y=segment.H},
		{x=0,y=segment.H-bevel},
		{x=0,y=bevel},
		{x=bevel,y=0},
		{x=segment.W-bevel,y=0},
		{x=segment.W,y=bevel},
		{x=segment.W,y=segment.H-bevel},
		{x=segment.W-bevel,y=segment.H}
	}
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
	surface.DrawPoly(rect)
	cam.PopModelMatrix()
	PopTransform(self)
	--surface.DrawRect(self.LocalX,self.LocalY,segment.W,segment.H)
	
	return PolyDimensions(self,rect,transformedLocal)
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
			if lpa < la and lpb < lb and lpc < lc then
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


function DrawPoly(self,poly)
	local selected = poly == self.SelectedSegment
	local transformedLocal = TransformOffset(self,poly.X or 0,poly.Y or 0)
	
	local x, y = self:LocalToScreen(0,0)
	local m = Matrix()
	m:Translate(Vector(x,y,0))
	m:Mul(Matrix({
		{self.LocalXX,self.LocalXY,0,self.LocalX + transformedLocal[1] - self.LocalXX/2},
		{self.LocalYX,self.LocalYY,0,self.LocalY + transformedLocal[2] - self.LocalYY/2},
		{0,0,1,0},
		{0,0,0,1}
	}))
	m:Translate(Vector(-x,-y,0))
	cam.PushModelMatrix(m)
	--surface.DrawPoly(poly.Poly)
	if selected then
		surface.SetDrawColor(255,192,192,255)
	else
		surface.SetDrawColor(255,255,255,255)
	end
	
	for i,p in ipairs(poly.Poly) do
		local op = poly.Poly[i%#poly.Poly+1]
		surface.DrawLine(p.x,p.y,op.x,op.y)
	end
	
	surface.SetDrawColor(255,255,0,255)
	for i,p in ipairs(poly.Poly) do
		local selectedvert = i == self.SelectedVert and selected
		local m = Matrix()
		m:Translate(Vector(x+p.x+0.5,y+p.y+0.5,0))
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
	surface.SetDrawColor(255,255,255,255)
	cam.PopModelMatrix()
	
	return PolyDimensions(self,poly.Poly,transformedLocal)
end

function DrawMatrix(self,matrix)
	
end

function DrawUnion(self,union)
	for k,v in ipairs(union.Children) do
		if v.Type == GROUP then
			DrawGroup(self,v)
		elseif v.Type == UNION then
			DrawUnion(self,v)
		elseif v.Type == SEGMENT then 
			DrawSegment(self,v)
		elseif v.Type == POLY then 
			DrawPoly(self,v)
		elseif v.Type == MATRIX then 
			DrawMatrix(self,v)
		end
	end
end

function DrawGroup(self,group)
	if #group.Children == 0 then
		return
	end
	
	
	local angle = math.rad(group.Rotation or 0)
	local transformedLocal = TransformOffset(self,group.X or 0,group.Y or 0)
	self.LocalX = self.LocalX + transformedLocal[1] + self.LocalXX/2
	self.LocalY = self.LocalY + transformedLocal[2] + self.LocalYY/2
	PushTransform(self,math.cos(angle),
	math.sin(angle),
	-math.sin(angle),
	math.cos(angle))
	PushTransform(self,1,
	-(group.SkewX or 0),
	(group.SkewY or 0),
	1)
	local minx, miny = Transform(self, group.Children[1].X, group.Children[1].Y)
	local maxx, maxy = minx, miny
	
	for k,v in ipairs(group.Children) do
		local nminx, nminy, nmaxx, nmaxy
		if v.Type == GROUP then
			nminx, nminy, nmaxx, nmaxy = DrawGroup(self,v)
		elseif v.Type == UNION then
			nminx, nminy, nmaxx, nmaxy = DrawGroup(self,v)
		elseif v.Type == SEGMENT then 
			nminx, nminy, nmaxx, nmaxy = DrawSegment(self,v)
		elseif v.Type == POLY then 
			nminx, nminy, nmaxx, nmaxy = DrawPoly(self,v)
		elseif v.Type == MATRIX then 
			DrawMatrix(self,v)
		end
		minx, miny = math.min(nminx, minx), math.min(nminy, miny)
		maxx, maxy = math.max(nmaxx, maxx), math.max(nmaxy, maxy)
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
	end
	surface.DrawOutlinedRect(minx,miny,(maxx-minx),(maxy-miny))
	--cam.PopModelMatrix()
	PopTransform(self)
	self.LocalX = self.LocalX - transformedLocal[1]
	self.LocalY = self.LocalY - transformedLocal[2]


	return minx,miny,maxx,maxy
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
	
	
	if self.DraggingPolyVert then
		local wx, wy = self:ScrToPos(x, y)
		if self.DraggingPolyVert[2] == 0 then
			local poly = self.DraggingPolyVert[1]
			poly.X = wx
			poly.Y = wy
			if snapincrement > 0.001 then
				poly.X = math.floor(poly.X/snapincrement + 0.5)*snapincrement
				poly.Y = math.floor(poly.Y/snapincrement + 0.5)*snapincrement
			end
		else
			local vert = self.DraggingPolyVert[1].Poly[self.DraggingPolyVert[2]]
			vert.x = wx-self.DraggingPolyVert[1].X
			vert.y = wy-self.DraggingPolyVert[1].Y
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
	--[[
	if self.SelectedSegments then
		self.SelectedSegments.HasColor = true
		self.SelectedSegments.G = 0
		self.SelectedSegments.X = -0.5
		self.SelectedSegments.Y = -0.5
		DrawGroup(self,self.SelectedSegments)
	end
	]]--
	DisableClipping(false)
	self.SegmentTree.X = -((self.minx or 0)-self.LocalX)/self.Zoom
	self.SegmentTree.Y = -((self.miny or 0)-self.LocalY)/self.Zoom
	local x, y = self:CursorPos()
	self.LastMousePos = { x, y }
	
	if self.SelectedSegment then
		self.ParentPanel.C.Prop_X:SetValue(self.SelectedSegment.X)
		self.ParentPanel.C.Prop_Y:SetValue(self.SelectedSegment.Y)
		if self.SelectedVert ~= 0 then
			self.ParentPanel.C.Vert_X:SetValue(self.SelectedSegment.Poly[self.SelectedVert].x)
			self.ParentPanel.C.Vert_Y:SetValue(self.SelectedSegment.Poly[self.SelectedVert].y)
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

function Editor:CreateSegment(x, y)
	local group = nil
	local children = nil
	if group ~= nil then
		children = group.Children
	end
	
	if children == nil then
		children = self.SegmentTree.Children
		group = self.SegmentTree
	end
	local n = {Type=SEGMENT, X=x,Y=y,W=70,H=70,Bevel = 0.1}
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
	local n = {Type=POLY, X=x,Y=y, Poly={{x=0,y=0},{x=10,y=0},{x=0,y=10}}}
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
			self.Clipboard = table.Copy(self.SelectedSegment)
		elseif code == KEY_V then
			if self.Clipboard ~= nil then
				self.Clipboard.X = gx
				self.Clipboard.Y = gy
				self.SegmentTree.Children[#self.SegmentTree.Children+1] = table.Copy(self.Clipboard)
			end
		end
	elseif code == KEY_C then
		--Create
		if self.Mode == SEGMENT then
			self:CreateSegment(gx, gy)
		elseif self.Mode == POLY then
			self:CreatePoly(gx, gy)
		end
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
	for i,v in ipairs(group.Children) do
		if v.Type == GROUP then
			ri, rv, ex, ey = self:GetPolyEdgeAtGroup(x-v.X, y-v.Y, v)
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
	local x,y = x*self.Zoom, y*self.Zoom 
	for i,v in ipairs(poly.Poly) do
		local vx = v.x*self.Zoom
		local vy = v.y*self.Zoom
		if math.abs(vx-x) < 4 and math.abs(vy-y) < 4 then
			return poly, i
		end
		
	end
	print(x,y)
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
	for i,v in ipairs(group.Children) do
		if v.Type == GROUP then
			sel.Children[#sel.Children+1] = self:SelectSegmentsAtGroup(x1-v.X, y1-v.Y, x2-v.X, y2-v.Y, v)
		elseif v.Type == POLY then
			if v.X >= x1 and v.Y >= y1 and v.X <= x2 and v.Y <= y2 then
				sel.Children[#sel.Children+1] = v
			end
		end
	end
	if #sel.Children > 0 then
		return sel
	end
	return nil
end

function Editor:SelectSegments(x1, y1, x2, y2)
	self.SelectedSegments = self:SelectSegmentsAtGroup(x1, y1, x2, y2, self.SegmentTree)
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
					end
				end
			else
				self.DraggingPolyVert = {pvKey,pvIndex}
			end
		elseif not control then
			local peKey, peIndex, ex, ey = self:GetPolyEdgeAt(x, y)
			
			if peKey then
				table.insert(peKey.Poly,peIndex+1,{x=ex,y=ey})
				self.DraggingPolyVert = {peKey,peIndex+1}
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
	local x, y = self:CursorPos()

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
	print(hoverTime)
end

vgui.Register("MSLCDEditor", Editor, "Panel");
