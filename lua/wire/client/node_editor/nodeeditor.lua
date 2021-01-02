local Editor = {}

function Editor:Init()
  self.Position = {0, 0}
  self.Zoom = 1
  self.DraggingWorld = false
  self.DraggingGate = nil

  self.DrawingConnection = false
  self.DrawingFromInput = false
  self.DrawingFromOutput = false
  self.DrawingConnectionFrom = nil

  self.LastMousePos = {0, 0}
  self.MouseDown = false

  self.GateSize = 5
  self.IOSize = 2

  self.BackgroundColor = Color(32, 32, 32, 255)
  self.NodeColor = Color(100, 100, 100, 255)
  self.ConnectionColor = Color(200, 200, 200, 255)
  self.InputColor = Color(120, 250, 120, 255)
  self.OutputColor = Color(120, 120, 250, 255)

  self.Nodes = {
    {type = "wire", gate = "floor", x = 0, y = 50, connections = {[1] = {5, 1}}},
    {type = "wire", gate = "ceil", x = 0, y = 150, connections = {[1] = {5, 1}}},
    {type = "wire", gate = "+", x = 50, y = 100, connections = {[1] = {1, 1}, [2] = {2, 1}}},
    {type = "wire", gate = "exp", x = 150, y = 100, connections = {[1] = {3, 1}}},
    {type = "io", gate = "in", x = -100, y = 100, connections = {}},
    {type = "io", gate = "out", x = 200, y = 100, connections = {[1] = {4, 1}}},
  }

  --MsgC(Color(0, 150, 255), table.ToString(GateActions, "Gate Actions", true))
end

-- ceil	=	{
--   label	=	function: 0x01eca99bda28,
--   group	=	"Arithmetic",
--   is_banned	=	false,
--   name	=	"Ceiling (Round up)",
--   output	=	function: 0x01eca99bd9f8,
--   inputs	=	{
--       "A",
--       },
--     },

-- INTERACTION
function Editor:GetData() 
  return util.TableToJSON({
      Nodes = self.Nodes,
      Position = self.Position,
      Zoom = self.Zoom
    }, false)
end

function Editor:SetData(data) 
  local data = util.JSONToTable(data)
  -- error check

  self.Nodes = data.Nodes
  self.Position = data.Position
  self.Zoom = data.Zoom
end

function Editor:ClearData() 
  self.Nodes = {}
  self.Position = {0, 0}
  self.Zoom = 1
end


-- GATES
function Editor:GetIOGate(node)
  if node.gate == "in" then
    return {name = "Input", inputs = {}, outputs = {"Out"}}
  elseif node.gate == "out" then
    return {name = "Output", inputs = {"A"}, outputs = {}}
  end
end

function Editor:GetGate(node)
  if node.type == "wire" then 
    return GateActions[node.gate]
  elseif node.type == "io" then
    return self:GetIOGate(node)
  end
end

-- UTILITY
function Editor:PosToScr(x, y)
  return self:GetWide()/2 - (self.Position[1] - x) * self.Zoom, self:GetTall()/2 - (self.Position[2] - y) * self.Zoom
end

function Editor:ScrToPos(x, y)
  return self.Position[1] - (self:GetWide()/2 - x) / self.Zoom, self.Position[2] - (self:GetTall()/2 - y) / self.Zoom
end

function Editor:NodeInputPos(node, input)
  return node.x - self.GateSize/2 - self.IOSize/2, node.y + (input - 1) * self.GateSize
end

function Editor:NodeOutputPos(node, output)
  return node.x + self.GateSize/2 + self.IOSize/2, node.y + (output - 1) * self.GateSize
end

-- DETECTION
function Editor:GetNodeAt(x, y)
  local gx, gy = self:ScrToPos(x, y)

  for k, node in pairs(self.Nodes) do
    if gx < node.x - self.GateSize/2 then continue end
    if gx > node.x + self.GateSize/2 then continue end
    if gy < node.y - self.GateSize/2 then continue end
    if gy > node.y + self.GateSize/2 then continue end

    return k
  end

  return nil
end

function Editor:GetNodeInputAt(x, y)
  local gx, gy = self:ScrToPos(x, y)

  for k, node in pairs(self.Nodes) do
    local gate = self:GetGate(node)

    if gx < node.x - self.GateSize/2 - self.IOSize then continue end
    if gx > node.x + self.GateSize/2 + self.IOSize then continue end
    if gy < node.y - self.GateSize/2 then continue end
    if gy > node.y - self.GateSize/2 + self.GateSize * table.Count(gate.inputs) then continue end

    for inputNum, input in pairs(gate.inputs) do
      local ix, iy = self:NodeInputPos(node, inputNum)

      if gx < ix - self.IOSize/2 then continue end
      if gx > ix + self.IOSize/2 then continue end
      if gy < iy - self.IOSize/2 then continue end
      if gy > iy + self.IOSize/2 then continue end

      return k, inputNum
    end
  end

  return nil
end

function Editor:GetNodeOutputAt(x, y)
  local gx, gy = self:ScrToPos(x, y)

  for k, node in pairs(self.Nodes) do
    local gate = self:GetGate(node)

    if gx < node.x - self.GateSize/2 - self.IOSize then continue end
    if gx > node.x + self.GateSize/2 + self.IOSize then continue end
    if gy < node.y - self.GateSize/2 then continue end
    if gy > node.y + self.GateSize/2 then continue end

    local ix, iy = self:NodeOutputPos(node, 1)

    if gx < ix - self.IOSize/2 then continue end
    if gx > ix + self.IOSize/2 then continue end
    if gy < iy - self.IOSize/2 then continue end
    if gy > iy + self.IOSize/2 then continue end

    return k, 1
  end

  return nil
end

-- DRAWING
function Editor:PaintConnection(nodeFrom, output, nodeTo, input)
  local x1, y1 = self:NodeOutputPos(nodeFrom, output)
  local x2, y2 = self:NodeInputPos(nodeTo, input)

  local sx1, sy1 = self:PosToScr(x1, y1)
  local sx2, sy2 = self:PosToScr(x2, y2)

  surface.SetDrawColor(self.ConnectionColor)
  surface.DrawLine(sx1, sy1, sx2, sy2)
end

function Editor:PaintConnections()
  for k1, node in pairs(self.Nodes) do
    for input, connectedTo in pairs(node.connections) do
      self:PaintConnection(self.Nodes[connectedTo[1]], connectedTo[2], node, input)
    end
  end
end

function Editor:PaintNode(node)
  local gate = self:GetGate(node)

  local amountOfInputs = 0
  if gate.inputs then
    amountOfInputs = table.Count(gate.inputs)
  end
  local amountOfOutputs = 1
  if gate.outputs then
    local amountOfOutputs = table.Count(gate.outputs)
  end

  local x, y = self:PosToScr(node.x, node.y)

  local size = self.Zoom * self.GateSize
  local ioSize = self.Zoom * self.IOSize

  -- Body
  local height = math.max(amountOfInputs, amountOfOutputs, 1)

  surface.SetDrawColor(self.NodeColor)
  surface.DrawRect(x-size/2, y-size/2, size, size * height)

  -- Name
  surface.SetFont("Default")
  surface.SetTextColor(255, 255, 255)
  local tx, ty = surface.GetTextSize(gate.name)
	surface.SetTextPos(x-tx/2, y-ty/2-size/1.2) 
  surface.DrawText(gate.name)
  
  -- Inputs
  surface.SetDrawColor(self.InputColor)
  if gate.inputs then
    for k, input in pairs(gate.inputs) do
      -- This should rely on a function
      surface.DrawRect(x - size/2 - ioSize, y - ioSize/2 + (k-1) * size, ioSize, ioSize)
    end
  end

  -- Output
  surface.SetDrawColor(self.OutputColor)
  if gate.outputs then
    for k, output in pairs(gate.outputs) do
      surface.DrawRect(x + size/2, y - ioSize/2 + (k-1) * size, ioSize, ioSize)
    end
  else 
    surface.DrawRect(x + size/2, y - ioSize/2, ioSize, ioSize)
  end
end

function Editor:PaintNodes()
  for k, node in pairs(self.Nodes) do
    self:PaintNode(node)
  end
end

function Editor:Paint()
  surface.SetDrawColor(self.BackgroundColor)
  surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

  self:PaintNodes()
  self:PaintConnections()

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
    self.Nodes[self.DraggingNode].x = gx
    self.Nodes[self.DraggingNode].y = gy
  end
  -- drawing a connection
  if self.DrawingConnection then
    local x, y = 0, 0
    if self.DrawingFromInput then
      x, y = self:NodeInputPos(self.Nodes[self.DrawingConnectionFrom[1]], self.DrawingConnectionFrom[2])
    elseif self.DrawingFromOutput then
      x, y = self:NodeOutputPos(self.Nodes[self.DrawingConnectionFrom[1]], self.DrawingConnectionFrom[2])
    end
    local sx, sy = self:PosToScr(x, y)
    local mx, my = self:CursorPos()
    surface.SetDrawColor(self.ConnectionColor)
    surface.DrawLine(sx, sy, mx, my)
  end

  local x, y = self:CursorPos()
  self.LastMousePos = {x, y}
end


function Editor:PaintDebug()
  surface.SetFont("Default")
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(10, 10) 
  surface.DrawText(self.Position[1] .. ", " .. self.Position[2])
  surface.SetTextPos(10, 30) 
	surface.DrawText(self.Zoom)
end

--ACTIONS
function Editor:BeginDrawingConnection(x, y)
  local nodeId, inputId = self:GetNodeInputAt(x, y)
  if nodeId then
    --check if something is connected to this input
    node = self.Nodes[nodeId]
    input = node.connections[inputId]

    --Input already connected
    if input then
      local connectedNode, connectedOutput = input[1], input[2]
      node.connections[inputId] = nil
      self.DrawingConnectionFrom = {connectedNode, connectedOutput}
      self.DrawingFromOutput = true
    else 
      --input not connected
      self.DrawingConnectionFrom = {nodeId, inputId}
      self.DrawingFromInput = true
    end
    
    self.DrawingConnection = true
  end

  local nodeId, outputId = self:GetNodeOutputAt(x, y)
  if nodeId then
    self.DrawingConnection = true
    self.DrawingFromOutput = true
    self.DrawingConnectionFrom = {nodeId, outputId}
  end
end

--EVENTS
function Editor:OnMousePressed(code)
	if code == MOUSE_LEFT then
    self.MouseDown = true

    local x, y = self:CursorPos()

    --NODE DRAGGING
    local node = self:GetNodeAt(x, y)
    if node then
      self.DraggingNode = node
    end

    --CONNECTION DRAWING
    self:BeginDrawingConnection(x, y)
  elseif code == MOUSE_RIGHT then
    -- PLANE DRAGGING
		self.DraggingWorld = true
	end
end

function Editor:OnMouseReleased(code)
  --if not self.MouseDown  then return end
  local x, y = self:CursorPos()

	if code == MOUSE_LEFT then
    self.MouseDown = false
    self.DraggingNode = nil

    if self.DrawingConnection then
      self:OnDrawConnectionFinished(x, y)
    end
  elseif code == MOUSE_RIGHT then
    self.DraggingWorld = false
  end
  
end

function Editor:OnDrawConnectionFinished(x, y)
  if self.DrawingFromOutput then
    local nodeId, inputId = self:GetNodeInputAt(x, y)

    if nodeId then
      local node = self.Nodes[nodeId]
      node.connections[inputId] = {self.DrawingConnectionFrom[1], self.DrawingConnectionFrom[2]}
    end

  elseif self.DrawingFromInput then
    local nodeId, outputId = self:GetNodeOutputAt(x, y)

    if nodeId then
      local node = self.Nodes[self.DrawingConnectionFrom[1]]
      node.connections[self.DrawingConnectionFrom[2]] =  {nodeId, outputId}
    end
  end

  self.DrawingConnection = false
  self.DrawingFromInput = false
  self.DrawingFromOutput = false
end

function Editor:OnMouseWheeled(delta)
  self.Zoom = self.Zoom + delta * 0.1
	if self.Zoom < 0.1 then self.Zoom = 0.1 end
	if self.Zoom > 10 then self.Zoom = 10 end
end


vgui.Register("FPGAEditor", Editor, "Panel");