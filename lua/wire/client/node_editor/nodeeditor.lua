local Editor = {}

local Nodes = {
  {gate = "IN", x = 0, y = 50, connections = {3}},
  {gate = "IN", x = 0, y = 150, connections = {3}},
  {gate = "AND", x = 50, y = 100, connections = {4}},
  {gate = "OUT", x = 150, y = 100, connections = {}}
}

function Editor:Init()
  self.Position = {0, 0}
  self.Zoom = 1
  self.DraggingWorld = false
  self.DraggingGate = nil

  self.LastMousePos = {0, 0}
  self.MouseDown = false

  self.GateSize = 5
end


-- UTILITY
function Editor:PosToScr(x, y)
  return self:GetWide()/2 - (self.Position[1] - x) * self.Zoom, self:GetTall()/2 - (self.Position[2] - y) * self.Zoom
end

function Editor:ScrToPos(x, y)
  return self.Position[1] - (self:GetWide()/2 - x) / self.Zoom, self.Position[2] - (self:GetTall()/2 - y) / self.Zoom
end

-- DETECTION
function Editor:GetNodeAt(x, y)
  local gx, gy = self:ScrToPos(x, y)

  for k, node in pairs(Nodes) do
    if gx < node.x - self.GateSize/2 then continue end
    if gx > node.x + self.GateSize/2 then continue end
    if gy < node.y - self.GateSize/2 then continue end
    if gy > node.y + self.GateSize/2 then continue end

    return k
  end

  return nil
end

-- DRAWING
function Editor:PaintConnection(nodeFrom, nodeTo)
  local x1, y1 = self:PosToScr(nodeFrom.x, nodeFrom.y)
  local x2, y2 = self:PosToScr(nodeTo.x, nodeTo.y)

  surface.SetDrawColor(Color(50, 50, 150, 255))
  surface.DrawLine(x1, y1, x2, y2)
end

function Editor:PaintConnections()
  for k1, node in pairs(Nodes) do
    for k2, dest in pairs(node.connections) do
      self:PaintConnection(node, Nodes[dest])
    end
  end
end

function Editor:PaintNode(node)
  surface.SetDrawColor(Color(50, 150, 50, 255))

  local size = self.Zoom * self.GateSize
  local x, y = self:PosToScr(node.x, node.y)

  surface.DrawRect(x-size/2, y-size/2, size, size)

  surface.SetFont("Default")
  surface.SetTextColor(255, 255, 255)
  local tx, ty = surface.GetTextSize(node.gate)
	surface.SetTextPos(x-tx/2, y-ty/2) 
	surface.DrawText(node.gate)
end

function Editor:PaintNodes()
  for k, node in pairs(Nodes) do
    self:PaintNode(node)
  end
end

function Editor:Paint()
  surface.SetDrawColor(Color(200, 200, 200, 255))
  surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

  self:PaintConnections()
  self:PaintNodes()

  self:PaintDebug()

  -- moving the plane
  if self.DraggingWorld then
    local x, y = self:CursorPos()
    local dx, dy = self.LastMousePos[1] - x, self.LastMousePos[2] - y
    self.Position = {self.Position[1] + dx * (1/self.Zoom), self.Position[2] + dy * (1/self.Zoom)}
  end
  -- moving a node
  if self.DraggingNode then
    local x, y = self:CursorPos()
    local gx, gy = self:ScrToPos(x, y)
    Nodes[self.DraggingNode].x = gx
    Nodes[self.DraggingNode].y = gy
  end

  local x, y = self:CursorPos()
  self.LastMousePos = {x, y}
end


function Editor:PaintDebug()
  surface.SetFont("Default")
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(128, 128) 
  surface.DrawText(self.Position[1] .. ", " .. self.Position[2])
  surface.SetTextPos(128, 158) 
	surface.DrawText(self.Zoom)
end

--EVENTS
function Editor:OnMousePressed(code)
	if code == MOUSE_LEFT then
    self.MouseDown = true
    --check if over node
    local x, y = self:CursorPos()
    local node = self:GetNodeAt(x, y)
    --begin dragging
    if node then
      self.DraggingNode = node
    end
	elseif code == MOUSE_RIGHT then
		self.DraggingWorld = true
	end
end

function Editor:OnMouseReleased(code)
	--if not self.MouseDown  then return end

	if code == MOUSE_LEFT then
    self.MouseDown = false
    self.DraggingNode = nil
  elseif code == MOUSE_RIGHT then
    self.DraggingWorld = false
  end
  
end

function Editor:OnMouseWheeled(delta)
  self.Zoom = self.Zoom + delta * 0.1
	if self.Zoom < 0.1 then self.Zoom = 0.1 end
	if self.Zoom > 10 then self.Zoom = 10 end
end


vgui.Register("FPGAEditor", Editor, "Panel");