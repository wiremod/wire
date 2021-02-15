local Editor = {}

DefaultValueForType = {
  NORMAL = 0,
  VECTOR2 = nil, --no
  VECTOR = Vector(0, 0, 0),
  VECTOR4 = nil, --no
  ANGLE = Angle(0, 0, 0),
  STRING = "",
  ARRAY = {},
  ENTITY = NULL,
  RANGER = nil,
  WIRELINK = nil
}

TypeColor = {
  NORMAL = Color(190, 190, 255, 255), --Very light blue nearing white
  VECTOR2 = Color(150, 255, 255, 255), --Light blue
  VECTOR = Color(70, 160, 255, 255), --Blue
  VECTOR4 = Color(0, 50, 255, 255), --Dark blue
  ANGLE = Color(100, 200, 100, 255), --Light green
  STRING = Color(250, 160, 90, 255), --Orange
  ARRAY = Color(20, 110, 20, 255), --Dark green
  ENTITY = Color(255, 100, 100, 255), --Dark red
  RANGER = Color(130, 100, 60, 255), --Brown
  WIRELINK = Color(200, 80, 200, 255), --Deep purple
}

function Editor:Init()
  self.Nodes = {}

  self.DraggingWorld = false
  self.DraggingNode = nil
  self.DraggingOffset = {0, 0}

  self.DrawingConnection = false
  self.DrawingFromInput = false
  self.DrawingFromOutput = false
  self.DrawingConnectionFrom = nil

  self.DrawingSelection = nil
  self.SelectedNodes = {}

  self.LastMousePos = {0, 0}
  self.MouseDown = false

  self.SelectedGateInMenu = nil

  self.GateSize = 5
  self.IOSize = 2

  self.BackgroundColor = Color(32, 32, 32, 255)
  self.SelectionColor = Color(220, 220, 100, 255)
  
  self.NodeColor = Color(100, 100, 100, 255)
  self.InputNodeColor = Color(80, 90, 80, 255)
  self.OutputNodeColor = Color(80, 80, 90, 255)
  self.TimedNodeColor = Color(110, 70, 70, 255)
  self.SelectedNodeColor = Color(150, 150, 100, 255)

  self.ZoomHideThreshold = 2
  self.ZoomThreshold = 7

  self.C = {}
  self:InitComponents()

  --MsgC(Color(0, 150, 255), table.ToString(GateActions, "Gate Actions", true))
end

function Editor:GetParent()
  return self.parentpanel
end

surface.CreateFont( "NodeName", {
  font = "Verdana",
  extended = false,
  size = 16,
  weight = 500,
  blursize = 0,
  scanlines = 0,
  antialias = true,
  underline = false,
  italic = false,
  strikeout = false,
  symbol = false,
  rotary = false,
  shadow = false,
  additive = false,
  outline = false,
})
surface.CreateFont( "IO", {
  font = "Verdana",
  extended = false,
  size = 12,
  weight = 500,
  blursize = 0,
  scanlines = 0,
  antialias = true,
  underline = false,
  italic = false,
  strikeout = false,
  symbol = false,
  rotary = false,
  shadow = false,
  additive = false,
  outline = false,
})
surface.CreateFont( "NodeNameBig", {
  font = "Verdana",
  extended = false,
  size = 20,
  weight = 1000,
  blursize = 0,
  scanlines = 0,
  antialias = true,
  underline = false,
  italic = false,
  strikeout = false,
  symbol = false,
  rotary = false,
  shadow = false,
  additive = false,
  outline = false,
})
surface.CreateFont( "IOBig", {
  font = "Verdana",
  extended = false,
  size = 18,
  weight = 200,
  blursize = 0,
  scanlines = 0,
  antialias = true,
  underline = false,
  italic = false,
  strikeout = false,
  symbol = false,
  rotary = false,
  shadow = false,
  additive = false,
  outline = false,
})

-- COMPONENTS
function Editor:InitComponents()
  local this = self

  self.C = {}

	self.C.TopBar = vgui.Create("DPanel", self)
  self.C.TopBar:Dock(TOP)
  self.C.TopBar:SetHeight(36)
  self.C.TopBar:DockPadding(5, 18, 5, 4)
  self.C.TopBar:SetBackgroundColor(Color(176.5, 180, 185, 255))

  local x = 7
  self.C.NameLabel = vgui.Create("DLabel", self.C.TopBar)
  self.C.NameLabel:SetText("Chip Name")
  self.C.NameLabel:SizeToContents()
  self.C.NameLabel:SetTextColor(Color(255,255,255,255))
  self.C.NameLabel:SetPos(x, 4)
  self.C.Name = vgui.Create("DTextEntry", self.C.TopBar)
  self.C.Name:SetEditable(true)
  self.C.Name:SetSize(140, 15)
  self.C.Name:SetPos(x-2, 18)
  --self.C.Name:Dock(LEFT)
  --self.C.Name:DockMargin(0,0,0,0)
  
  self.C.Name.OnLoseFocus = function (pnl)
    if string.len(pnl:GetValue()) == 0 then
    	pnl:SetText("gate")
    end
    this:RequestFocus()
  end
  x = x + 160

  self.C.ExecutionIntervalLabel = vgui.Create("DLabel", self.C.TopBar)
  self.C.ExecutionIntervalLabel:SetText("Execution Interval")
  self.C.ExecutionIntervalLabel:SizeToContents()
  self.C.ExecutionIntervalLabel:SetTextColor(Color(255,255,255,255))
  self.C.ExecutionIntervalLabel:SetPos(x, 4)
  self.C.ExecutionIntervalLabel2 = vgui.Create("DLabel", self.C.TopBar)
  self.C.ExecutionIntervalLabel2:SetText("every               s")
  self.C.ExecutionIntervalLabel2:SizeToContents()
  self.C.ExecutionIntervalLabel2:SetTextColor(Color(255,255,255,255))
  self.C.ExecutionIntervalLabel2:SetPos(x, 18)
  self.C.ExecutionInterval = vgui.Create("DNumberWang", self.C.TopBar)
  self.C.ExecutionInterval:SetInterval(0.01)
  self.C.ExecutionInterval:SetDecimals(3)
  self.C.ExecutionInterval:SetMax(1)
  self.C.ExecutionInterval:SetMin(0.001)
  self.C.ExecutionInterval:SetValue(0.1)
  self.C.ExecutionInterval:SetSize(40, 15)
  self.C.ExecutionInterval:SetPos(x+31, 18)

  self.C.ExecutionInterval.OnLoseFocus = function (pnl)
    this:RequestFocus()
  end
  x = x + 110

  self.C.ExecuteOnLabel = vgui.Create("DLabel", self.C.TopBar)
  self.C.ExecuteOnLabel:SetText("Execute on")
  self.C.ExecuteOnLabel:SizeToContents()
  self.C.ExecuteOnLabel:SetTextColor(Color(255,255,255,255))
  self.C.ExecuteOnLabel:SetPos(x, 4)
  self.C.ExecuteOnInputs = vgui.Create("DCheckBoxLabel", self.C.TopBar)
  self.C.ExecuteOnInputs:SetPos(x, 18)
  self.C.ExecuteOnInputs:SetText("Inputs")
  self.C.ExecuteOnInputs:SetTextColor(Color(240,240,240,255))
  self.C.ExecuteOnInputs:SetValue(true)
  self.C.ExecuteOnInputs:SizeToContents()
  self.C.ExecuteOnTimed = vgui.Create("DCheckBoxLabel", self.C.TopBar)
  self.C.ExecuteOnTimed:SetPos(x+60, 18)
  self.C.ExecuteOnTimed:SetText("Timed")
  self.C.ExecuteOnTimed:SetTextColor(Color(240,240,240,255))
  self.C.ExecuteOnTimed:SetValue(true)
  self.C.ExecuteOnTimed:SizeToContents()
  self.C.ExecuteOnTrigger = vgui.Create("DCheckBoxLabel", self.C.TopBar)
  self.C.ExecuteOnTrigger:SetPos(x+120, 18)
  self.C.ExecuteOnTrigger:SetText("Trigger In")
  self.C.ExecuteOnTrigger:SetTextColor(Color(240,240,240,255))
  self.C.ExecuteOnTrigger:SetValue(false)
  self.C.ExecuteOnTrigger:SizeToContents()



  --Gate spawning
  self.C.Holder = vgui.Create("DPanel", self)
  self.C.Holder:SetWidth(300)
  self.C.Holder:Dock(RIGHT)
  self.C.Holder:SetBackgroundColor(Color(170, 174, 179, 255))

  self.C.Tree = vgui.Create("DTree", self.C.Holder)
  self.C.Tree:Dock(FILL)
  self.C.Tree:DockMargin(2,0,2,2)


  --utility
  local function FillSubTree(editor, tree, node, temp, type, sortByName)
    node.Icon:SetImage("icon16/folder.png")

    local subtree = {}
    for k, v in pairs(temp) do
      subtree[#subtree+1] = {action = k, gate = v, name = v.name, order = v.order}
    end

    if sortByName then
      table.SortByMember(subtree, "name", true)
    else
      table.SortByMember(subtree, "order", true)
    end

    for index=1, #subtree do
      local action, gate = subtree[index].action, subtree[index].gate
      local node2 = node:AddNode(gate.name or "No name found :(")
      node2.name = gate.name
      node2.action = action
      function node2:DoClick()
        --editor:CreateNode(type, self.action)
        editor.SelectedGateInMenu = {type = type, gate = self.action}
      end
      node2.Icon:SetImage("icon16/newspaper.png")
    end
    tree:InvalidateLayout()
  end

  --FPGA gates
  local CategoriesSorted = {}

  for gatetype, gatefuncs in pairs(FPGAGatesSorted) do
    local allowed_gates = {}
    local any_allowed = false
    for k,v in pairs(gatefuncs) do
      if not v.is_banned then
        allowed_gates[k] = v
        any_allowed = true
      end
    end
    if any_allowed then
      CategoriesSorted[#CategoriesSorted+1] = {gatetype = gatetype, gatefuncs = allowed_gates}
    end
  end

  table.sort(CategoriesSorted, function(a, b) return a.gatetype < b.gatetype end)

  local fpgaNode = self.C.Tree:AddNode("FPGA", "icon16/bricks.png")
  function fpgaNode:DoClick()
    self:SetExpanded(not self.m_bExpanded)
  end

  for i=1,#CategoriesSorted do
    local gatetype = CategoriesSorted[i].gatetype
    local gatefuncs = CategoriesSorted[i].gatefuncs

    local node = fpgaNode:AddNode(gatetype)
    node.Icon:SetImage("icon16/folder.png")
    FillSubTree(self, self.C.Tree, node, gatefuncs, "fpga", false)
    function node:DoClick()
      self:SetExpanded(not self.m_bExpanded)
    end
  end

  --CPU gates
  local CategoriesSorted = {}

  for gatetype, gatefuncs in pairs(CPUGatesSorted) do
    local gates = {}
    for k,v in pairs(gatefuncs) do
      gates[k] = v
    end
    CategoriesSorted[#CategoriesSorted+1] = {gatetype = gatetype, gatefuncs = gates}
  end

  table.sort(CategoriesSorted, function(a, b) return a.gatetype < b.gatetype end)

  local cpuNode = self.C.Tree:AddNode("CPU", "icon16/computer.png")
  function cpuNode:DoClick()
    self:SetExpanded(not self.m_bExpanded)
  end

  for i=1,#CategoriesSorted do
    local gatetype = CategoriesSorted[i].gatetype
    local gatefuncs = CategoriesSorted[i].gatefuncs

    local node = cpuNode:AddNode(gatetype)
    node.Icon:SetImage("icon16/folder.png")
    FillSubTree(self, self.C.Tree, node, gatefuncs, "cpu", false)
    function node:DoClick()
      self:SetExpanded(not self.m_bExpanded)
    end
  end

  --WIREMOD gates
  local CategoriesSorted = {}

  for gatetype, gatefuncs in pairs(WireGatesSorted) do
    local allowed_gates = {}
    local any_allowed = false
    for k,v in pairs(gatefuncs) do
      if not v.is_banned and not (k == "string_to_memory" or k == "string_from_memory") then
        allowed_gates[k] = v
        any_allowed = true
      end
    end
    if any_allowed then
      CategoriesSorted[#CategoriesSorted+1] = {gatetype = gatetype, gatefuncs = allowed_gates}
    end
  end

  table.sort(CategoriesSorted, function(a, b) return a.gatetype < b.gatetype end)

  local wiremodNode = self.C.Tree:AddNode("Wire", "icon16/connect.png")
  function wiremodNode:DoClick()
    self:SetExpanded(not self.m_bExpanded)
  end

  for i=1,#CategoriesSorted do
    local gatetype = CategoriesSorted[i].gatetype
    local gatefuncs = CategoriesSorted[i].gatefuncs

    local node = wiremodNode:AddNode(gatetype)
    node.Icon:SetImage("icon16/folder.png")
    FillSubTree(self, self.C.Tree, node, gatefuncs, "wire", true)
    function node:DoClick()
      self:SetExpanded(not self.m_bExpanded)
    end
  end
end


-- INTERACTION
function Editor:GetData() 
  return WireLib.von.serialize({
      Name = self.C.Name:GetValue(),
      Nodes = self.Nodes,
      Position = self.Position,
      Zoom = self.Zoom,
      ExecutionInterval = self.C.ExecutionInterval:GetValue(),
      ExecuteOn = {
        Inputs = self.C.ExecuteOnInputs:GetChecked(),
        Timed = self.C.ExecuteOnTimed:GetChecked(),
        Trigger = self.C.ExecuteOnTrigger:GetChecked()
      }
    }, false)
end

function Editor:SetData(data) 
  local ok, data = pcall(WireLib.von.deserialize, data)
  if not ok then
    self:ClearData()
    self.C.Name:SetValue("corrupt")
    return
  end

  if data.Nodes then self.Nodes = data.Nodes else self.Nodes = {} end

  if data.Name then self.C.Name:SetValue(data.Name) else self.C.Name:SetValue("gate") end

  if data.ExecutionInterval then 
    self.C.ExecutionInterval:SetValue(data.ExecutionInterval)
  else
    self.C.ExecutionInterval:SetValue(0.01)
  end

  if data.ExecuteOn then
    self.C.ExecuteOnInputs:SetValue(data.ExecuteOn.Inputs)
    self.C.ExecuteOnTimed:SetValue(data.ExecuteOn.Timed)
    self.C.ExecuteOnTrigger:SetValue(data.ExecuteOn.Trigger)
  else
    self.C.ExecuteOnInputs:SetValue(true)
    self.C.ExecuteOnTimed:SetValue(true)
    self.C.ExecuteOnTrigger:SetValue(false)
  end

  if data.Position then self.Position = data.Position else self.Position = {0, 0} end
  if data.Zoom then self.Zoom = data.Zoom else self.Zoom = 5 end

  self.InputNameCounter = 0
  self.OutputNameCounter = 0
  for k, node in pairs(self.Nodes) do
    local gate = self:GetGate(node)
    if gate.isInput then self.InputNameCounter = self.InputNameCounter + 1 end
    if gate.isOutput then self.OutputNameCounter = self.OutputNameCounter + 1 end
  end
end

function Editor:ClearData()
  self.C.Name:SetValue("gate")
  self.Nodes = {}
  self.Position = {0, 0}
  self.Zoom = 5
  self.InputNameCounter = 0
  self.OutputNameCounter = 0
end

function Editor:GetName()
  return self.C.Name:GetValue()
end

function Editor:HasNodes()
  return #self.Nodes > 0
end

-- GATES
function Editor:GetGate(node)
  if node.type == "wire" then 
    return GateActions[node.gate]
  elseif node.type == "fpga" then
    return FPGAGateActions[node.gate]
  elseif node.type == "cpu" then
    return CPUGateActions[node.gate]
  end
end

function Editor:GetInputType(gate, inputNum)
  if gate.inputtypes then
    return gate.inputtypes[inputNum] or "NORMAL"
  else
    return "NORMAL"
  end
end

function Editor:GetOutputType(gate, outputNum)
  if gate.outputtypes then
    return gate.outputtypes[outputNum] or "NORMAL"
  else
    return "NORMAL"
  end
end

-- UTILITY
function Editor:PosToScr(x, y)
  return (self:GetWide()-300)/2 - (self.Position[1] - x) * self.Zoom, self:GetTall()/2 - (self.Position[2] - y) * self.Zoom
end

function Editor:ScrToPos(x, y)
  return self.Position[1] - ((self:GetWide()-300)/2 - x) / self.Zoom, self.Position[2] - (self:GetTall()/2 - y) / self.Zoom
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
    local gate = self:GetGate(node)

    local amountOfInputs = 0
    if gate.inputs then
      amountOfInputs = table.Count(gate.inputs)
    end
    local amountOfOutputs = 1
    if gate.outputs then
      amountOfOutputs = table.Count(gate.outputs)
    end

    local height = math.max(amountOfInputs, amountOfOutputs)

    if gx < node.x - self.GateSize/2 then continue end
    if gx > node.x + self.GateSize/2 then continue end
    if gy < node.y - self.GateSize/2 then continue end
    if gy > node.y - self.GateSize/2 + self.GateSize*height then continue end

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

    for inputNum, _ in pairs(gate.inputs) do
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
    if gate.outputs then
      if gy > node.y - self.GateSize/2 + self.GateSize * table.Count(gate.outputs) then continue end
    else
      if gy > node.y + self.GateSize/2 then continue end
    end

    if gate.outputs then
      for outputNum, _ in pairs(gate.outputs) do
        local ix, iy = self:NodeOutputPos(node, outputNum)
  
        if gx < ix - self.IOSize/2 then continue end
        if gx > ix + self.IOSize/2 then continue end
        if gy < iy - self.IOSize/2 then continue end
        if gy > iy + self.IOSize/2 then continue end
  
        return k, outputNum
      end
    else
      local ix, iy = self:NodeOutputPos(node, 1)

      if gx < ix - self.IOSize/2 then continue end
      if gx > ix + self.IOSize/2 then continue end
      if gy < iy - self.IOSize/2 then continue end
      if gy > iy + self.IOSize/2 then continue end

      return k, 1
    end
  end

  return nil
end

-- DRAWING
function Editor:PaintConnection(nodeFrom, output, nodeTo, input, type)
  local x1, y1 = self:NodeOutputPos(nodeFrom, output)
  local x2, y2 = self:NodeInputPos(nodeTo, input)

  local sx1, sy1 = self:PosToScr(x1, y1)
  local sx2, sy2 = self:PosToScr(x2, y2)

  surface.SetDrawColor(TypeColor[type])
  surface.DrawLine(sx1, sy1, sx2, sy2)
end

function Editor:PaintConnections()
  for _, node in pairs(self.Nodes) do
    local gate = self:GetGate(node)
    for inputNum, connectedTo in pairs(node.connections) do
      self:PaintConnection(self.Nodes[connectedTo[1]], connectedTo[2], node, inputNum, self:GetInputType(gate, inputNum))
    end
  end
end

function Editor:PaintInput(x, y, type, name, ioSize)
  surface.SetDrawColor(TypeColor[type])
  surface.DrawRect(x, y, ioSize*2, ioSize)

  if (self.Zoom > self.ZoomHideThreshold) then
    local tx, ty = surface.GetTextSize(name)
    surface.SetTextPos(x-tx-ioSize*0.3, y+ioSize/2-ty/2) 
    surface.DrawText(name)
  end
end

function Editor:PaintOutput(x, y, type, name, ioSize)
  surface.SetDrawColor(TypeColor[type])
  surface.DrawRect(x, y, ioSize*2, ioSize)

  if (self.Zoom > self.ZoomHideThreshold) then
    local tx, ty = surface.GetTextSize(name)
    surface.SetTextPos(x+ioSize*2.3, y+ioSize/2-ty/2) 
    surface.DrawText(name)
  end
end

function Editor:PaintNode(nodeId, node)
  local gate = self:GetGate(node)

  local amountOfInputs = 0
  if gate.inputs then
    amountOfInputs = table.Count(gate.inputs)
  end
  local amountOfOutputs = 1
  if gate.outputs then
    amountOfOutputs = table.Count(gate.outputs)
  end

  local x, y = self:PosToScr(node.x, node.y)

  local size = self.Zoom * self.GateSize
  local ioSize = self.Zoom * self.IOSize
  
  -- Inputs
  if (self.Zoom > self.ZoomThreshold) then
    surface.SetFont("IOBig")
  else
    surface.SetFont("IO")
  end
  surface.SetTextColor(255, 255, 255)

  
  if gate.inputs then
    for inputNum, inputName in pairs(gate.inputs) do
      local nx = x - size/2 - ioSize
      local ny = y - ioSize/2 + (inputNum-1) * size
      
      self:PaintInput(nx, ny, self:GetInputType(gate, inputNum), inputName, ioSize)
    end
  end

  -- Output
  if gate.outputs then
    for outputNum, outputName in pairs(gate.outputs) do
      local nx = x + size/2 - ioSize
      local ny = y - ioSize/2 + (outputNum-1) * size
    
      self:PaintOutput(nx, ny, self:GetOutputType(gate, outputNum), outputName, ioSize)
    end
  else 
    local nx = x + size/2 - ioSize
    local ny = y - ioSize/2
  
    self:PaintOutput(nx, ny, self:GetOutputType(gate, 1), "Out", ioSize)
  end

  -- Body
  local height = math.max(amountOfInputs, amountOfOutputs, 1)

  if self.SelectedNodes[nodeId] then
    surface.SetDrawColor(self.SelectedNodeColor)
  else
    if gate.isInput then
      surface.SetDrawColor(self.InputNodeColor)
    elseif gate.isOutput then
      surface.SetDrawColor(self.OutputNodeColor)
    elseif gate.timed then
      surface.SetDrawColor(self.TimedNodeColor)
    else
      surface.SetDrawColor(self.NodeColor)
    end
  end
  surface.DrawRect(x-size/2, y-size/2, size, size * height)

  -- Name
  if (self.Zoom > self.ZoomThreshold) then
    surface.SetFont("NodeNameBig")
  else
    surface.SetFont("NodeName")
  end
  surface.SetTextColor(255, 255, 255)
  if (self.Zoom > self.ZoomHideThreshold) then
    local tx, ty = surface.GetTextSize(gate.name)
    surface.SetTextPos(x-tx/2, y-ty/2-size/1.2) 
    surface.DrawText(gate.name)
  
    surface.SetTextColor(180, 180, 180)
    -- Input
    if node.ioName then
      local tx, ty = surface.GetTextSize(node.ioName)
      surface.SetTextPos(x-tx/2, y-ty/2+size/1.2) 
      surface.DrawText(node.ioName)
    -- Constant
    elseif node.value then
      local s = tostring(node.value)
      local tx, ty = surface.GetTextSize(s)
      surface.SetTextPos(x-tx/2, y-ty/2+size/1.2) 
      surface.DrawText(s)
    end
  end
end

function Editor:PaintNodes()
  for nodeId, node in pairs(self.Nodes) do
    self:PaintNode(nodeId, node)
  end
end

function Editor:PaintHelp()
  local x, y = self:PosToScr(0, 0)

  surface.SetFont("NodeName")
  surface.SetTextColor(255, 255, 255)

  local helpText = [[Drag gates and draw selections with the right mouse button,
    and drag around the plane with the right mouse button.
    Connect inputs and outputs by right clicking on either, and dragging to the other
     
    'C' creates a gate at the cursor position (select which gate on the right menu)
    'X' deletes the gate under the cursor (or with a selection, deletes all selected gates)
    'E' edits the gate under the cursor (input/output names, constant values)

    'Ctrl + C' copies the selected gates (relative to mouse position)
    'Ctrl + V' pastes the copied gates (relative to mouse position)


    To create inputs and outputs for the FPGA chip, use the gates found in 'FPGA/Input & Output'
  ]]

  for line in helpText:gmatch("([^\n]*)\n?") do
    local tx, ty = surface.GetTextSize(line)
    surface.SetTextPos(x-tx/2, y-ty/2) 
    surface.DrawText(line)
    y = y + ty
  end
end

function Editor:Paint()
  surface.SetDrawColor(self.BackgroundColor)
  surface.DrawRect(0, 36, self:GetWide()-300, self:GetTall()-36)

  self:PaintNodes()
  self:PaintConnections()

  if #self.Nodes == 0 then
    self:PaintHelp()
  end
  
  --self:PaintDebug()

  -- detects if mouse is let go outside of the window
  if not input.IsMouseDown(MOUSE_RIGHT) then
    self.DraggingWorld = nil
  end
  if not input.IsMouseDown(MOUSE_LEFT) then
    self.DraggingNode = nil
    self.DrawingConnection = nil
    self.DrawingSelection = nil
  end

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
    gx = gx + self.DraggingOffset[1]
    gy = gy + self.DraggingOffset[2]

    local cx, cy = self.Nodes[self.DraggingNode].x, self.Nodes[self.DraggingNode].y

    if self.SelectedNodes[self.DraggingNode] and table.Count(self.SelectedNodes) > 0 then
      for selectedNodeId, selectedNode in pairs(self.SelectedNodes) do
        local sox, soy = self.Nodes[selectedNodeId].x - cx, self.Nodes[selectedNodeId].y - cy
        self.Nodes[selectedNodeId].x = gx + sox
        self.Nodes[selectedNodeId].y = gy + soy
      end
    else
      self.SelectedNodes = {}
      self.Nodes[self.DraggingNode].x = gx
      self.Nodes[self.DraggingNode].y = gy
    end
  end
  -- drawing a connection
  if self.DrawingConnection then
    local x, y = 0, 0
    local type = "NORMAL"
    if self.DrawingFromInput then
      x, y = self:NodeInputPos(self.Nodes[self.DrawingConnectionFrom[1]], self.DrawingConnectionFrom[2])
      type = self:GetInputType(self:GetGate(self.Nodes[self.DrawingConnectionFrom[1]]), self.DrawingConnectionFrom[2])
    elseif self.DrawingFromOutput then
      x, y = self:NodeOutputPos(self.Nodes[self.DrawingConnectionFrom[1]], self.DrawingConnectionFrom[2])
      type = self:GetOutputType(self:GetGate(self.Nodes[self.DrawingConnectionFrom[1]]), self.DrawingConnectionFrom[2])
    end
    local sx, sy = self:PosToScr(x, y)
    local mx, my = self:CursorPos()
    surface.SetDrawColor(TypeColor[type])
    surface.DrawLine(sx, sy, mx, my)
  end
  -- selecting
  if self.DrawingSelection then
    local sx, sy = self:PosToScr(self.DrawingSelection[1], self.DrawingSelection[2])
    local mx, my = self:CursorPos()
    
    local x, y = math.min(sx, mx), math.min(sy, my)
    local w, h = math.abs(sx-mx), math.abs(sy-my)

    surface.SetDrawColor(self.SelectionColor)
    surface.DrawOutlinedRect(x, y, w, h)
  end

  local x, y = self:CursorPos()
  self.LastMousePos = {x, y}
end

function Editor:PaintDebug()
  surface.SetFont("Default")
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(10, 50) 
  surface.DrawText(self.Position[1] .. ", " .. self.Position[2])
  surface.SetTextPos(10, 70) 
	surface.DrawText(self.Zoom)
end

--ACTIONS
function Editor:BeginDrawingConnection(nodeId, inputNum, outputNum)
  if inputNum then
    --check if something is connected to this input
    node = self.Nodes[nodeId]
    Input = node.connections[inputNum]

    --Input already connected
    if Input then
      local connectedNode, connectedOutput = Input[1], Input[2]
      node.connections[inputNum] = nil
      self.DrawingConnectionFrom = {connectedNode, connectedOutput}
      self.DrawingFromOutput = true
    else 
      --input not connected
      self.DrawingConnectionFrom = {nodeId, inputNum}
      self.DrawingFromInput = true
    end
    
    self.DrawingConnection = true
  end

  if outputNum then
    self.DrawingConnection = true
    self.DrawingFromOutput = true
    self.DrawingConnectionFrom = {nodeId, outputNum}
  end
end

function Editor:GetInputName()
  self.InputNameCounter = self.InputNameCounter + 1
  return "In" .. self.InputNameCounter
end

function Editor:GetOutputName()
  self.OutputNameCounter = self.OutputNameCounter + 1
  return "Out" .. self.OutputNameCounter
end

function Editor:CreateNode(type, gate, x, y)
  node = {
    type = type,
    gate = gate,
    x = x,
    y = y,
    connections = {}
  }

  local gateInfo = self:GetGate(node)

  if gateInfo.isInput then
    node.ioName = self:GetInputName()
  elseif gateInfo.isOutput then
    node.ioName = self:GetOutputName()
  elseif gateInfo.isConstant then
    local type = self:GetOutputType(gateInfo, 1)
    node.value = DefaultValueForType[type]
  end

  --print("Created " .. table.ToString(node, "node", false))

  table.insert(self.Nodes, node)
end

function Editor:DeleteNode(nodeId)
  --print("Deleted " .. nodeId)
  
  --remove all connections to this node
  for k1, node in pairs(self.Nodes) do
    for inputNum, connection in pairs(node.connections) do
      if connection[1] == nodeId then
        node.connections[inputNum] = nil
      end
    end
  end

  --finally remove node
  self.Nodes[nodeId] = nil
end

function Editor:CopyNodes(nodeIds)
  local nodeIdLookup = {}
  local i = 1
  for nodeId, _ in pairs(nodeIds) do
    nodeIdLookup[nodeId] = i
    i = i + 1
  end

  local nodeAmount = table.Count(nodeIds)
  local copyBuffer = {}
  local copyOffset = {0, 0}
  for nodeId, _ in pairs(nodeIds) do
    local node = self.Nodes[nodeId]
    local gate = self:GetGate(node) 

    local nodeCopy = {
      type = node.type,
      gate = node.gate,
      x = node.x,
      y = node.y,
      connections = {}
    }

    if gate.isInput then
      nodeCopy.ioName = node.ioName
    elseif gate.isOutput then
      nodeCopy.ioName = node.ioName
    elseif gate.isConstant then
      nodeCopy.value = node.value
    end

    for inputNum, connection in pairs(node.connections) do
      if nodeIds[connection[1]] then
        nodeCopy.connections[inputNum] = {nodeIdLookup[connection[1]], connection[2]}
      end
    end

    table.insert(copyBuffer, nodeCopy)

    copyOffset = {copyOffset[1] + node.x / nodeAmount, copyOffset[2] + node.y / nodeAmount}
  end

  self:GetParent():SetCopyData(copyBuffer, copyOffset)
end

function Editor:PasteNodes(x, y)
  local copyData = self:GetParent():GetCopyData()
  local copyBuffer = copyData[1]
  local copyOffset = copyData[2]

  if not copyBuffer then return end

  local nodeIdLookup = {}
  self.SelectedNodes = {}
  local i = #self.Nodes + 1
  for copyNodeId, _ in pairs(copyBuffer) do
    while self.Nodes[i] do
      i = i + 1
    end

    nodeIdLookup[copyNodeId] = i
    self.SelectedNodes[i] = true
    i = i + 1
  end

  for copyNodeId, copyNode in pairs(copyBuffer) do
    local nodeCopy = {
      type = copyNode.type,
      gate = copyNode.gate,
      connections = {}
    }

    local gate = self:GetGate(copyNode)
    if gate.isInput then
      nodeCopy.ioName = copyNode.ioName
    elseif gate.isOutput then
      nodeCopy.ioName = copyNode.ioName
    elseif gate.isConstant then
      nodeCopy.value = copyNode.value
    end

    for inputNum, connection in pairs(copyNode.connections) do
      nodeCopy.connections[inputNum] = {nodeIdLookup[connection[1]], connection[2]}
    end

    nodeCopy.x = (copyNode.x - copyOffset[1]) + x
    nodeCopy.y = (copyNode.y - copyOffset[2]) + y

    self.Nodes[nodeIdLookup[copyNodeId]] = nodeCopy
  end
end

--EVENTS
function Editor:OnMousePressed(code)
  self:RequestFocus() --Fix for weird bug, remove once resolved

	if code == MOUSE_LEFT then
    self.MouseDown = true

    local x, y = self:CursorPos()

    --NODE DRAGGING
    local nodeId = self:GetNodeAt(x, y)
    if nodeId then
      self.DraggingNode = nodeId
      local gx, gy = self:ScrToPos(x, y)
      self.DraggingOffset = {self.Nodes[nodeId].x - gx, self.Nodes[nodeId].y - gy}
    else
      --CONNECTION DRAWING
      local nodeId, inputNum = self:GetNodeInputAt(x, y)
      if nodeId then
        self:BeginDrawingConnection(nodeId, inputNum, nil)
      else
        local nodeId, outputNum = self:GetNodeOutputAt(x, y)
        if nodeId then
          self:BeginDrawingConnection(nodeId, nil, outputNum)
        else
          --SELECTION DRAWING
          local gx, gy = self:ScrToPos(x, y)
          self.DrawingSelection = {gx, gy}
        end
      end
      
    end
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
    elseif self.DrawingSelection then
      self:OnDrawSelectionFinished(x, y)
    end
  elseif code == MOUSE_RIGHT then
    self.DraggingWorld = false
  end
  
end

function Editor:OnDrawSelectionFinished(x, y)
  local gx, gy = self.DrawingSelection[1], self.DrawingSelection[2]
  local mx, my = self:CursorPos()
  local mgx, mgy = self:ScrToPos(mx, my)

  local lx, ly = math.min(gx, mgx), math.min(gy, mgy)
  local ux, uy = math.max(gx, mgx), math.max(gy, mgy)

  self.SelectedNodes = {}
  for nodeId, node in pairs(self.Nodes) do
    if node.x < lx then continue end
    if node.x > ux then continue end
    if node.y < ly then continue end
    if node.y > uy then continue end

    self.SelectedNodes[nodeId] = true
  end

  self.DrawingSelection = nil
end

function Editor:OnDrawConnectionFinished(x, y)
  if self.DrawingFromOutput then
    local nodeId, inputNum = self:GetNodeInputAt(x, y)

    if nodeId then
      local inputNode = self.Nodes[nodeId]
      local outputNode = self.Nodes[self.DrawingConnectionFrom[1]]
      --check type
      local inputType = self:GetInputType(self:GetGate(inputNode), inputNum)
      local outputType = self:GetOutputType(self:GetGate(outputNode), self.DrawingConnectionFrom[2])

      if inputType == outputType and inputNode != outputNode then
        --connect up
        inputNode.connections[inputNum] = {self.DrawingConnectionFrom[1], self.DrawingConnectionFrom[2]}
      end
    end

  elseif self.DrawingFromInput then
    local nodeId, outputNum = self:GetNodeOutputAt(x, y)

    if nodeId then
      local inputNode = self.Nodes[self.DrawingConnectionFrom[1]]
      local outputNode = self.Nodes[nodeId]
      --check type
      local inputType = self:GetInputType(self:GetGate(inputNode), self.DrawingConnectionFrom[2])
      local outputType = self:GetOutputType(self:GetGate(outputNode), outputNum)

      if inputType == outputType and inputNode != outputNode then
        --connect up
        inputNode.connections[self.DrawingConnectionFrom[2]] =  {nodeId, outputNum}
      end
    end
  end

  self.DrawingConnection = false
  self.DrawingFromInput = false
  self.DrawingFromOutput = false
end

function Editor:OnMouseWheeled(delta)
  local sx, sy = self:CursorPos()

  if sx > 0 and sy > 36 and sx < self:GetWide()-300 and sy < self:GetTall()-36 then
    self.Zoom = self.Zoom + delta * 0.1 * self.Zoom
    if self.Zoom < 0.1 then self.Zoom = 0.1 end
    if self.Zoom > 10 then self.Zoom = 10 end
  end
end

function Editor:OnKeyCodePressed(code)
  local x, y = self:CursorPos()
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

  if control then
    if code == KEY_C then
      --Copy
      if table.Count(self.SelectedNodes) > 0 then
        self:CopyNodes(self.SelectedNodes)
      else
        self:GetParent():ClearCopyData()
      end
    elseif code == KEY_V then
      --Paste
      local gx, gy = self:ScrToPos(x, y)
      self:PasteNodes(gx, gy)
    end
  elseif code == KEY_X then
    --Delete
    if table.Count(self.SelectedNodes) > 0 then
      for selectedNodeId, selectedNode in pairs(self.SelectedNodes) do
        self:DeleteNode(selectedNodeId)
      end
      self.SelectedNodes = {}
    else
      local nodeId = self:GetNodeAt(x, y)
      if nodeId then
        self:DeleteNode(nodeId)
      end
    end
  elseif code == KEY_C then
    --Create
    if self.SelectedGateInMenu then
      local gx, gy = self:ScrToPos(x, y)
      self:CreateNode(self.SelectedGateInMenu.type,
                      self.SelectedGateInMenu.gate,
                      gx,
                      gy)
    end
  elseif code == KEY_E and not self.EditingNode then
    --Edit
        local nodeId = self:GetNodeAt(x, y)
    if nodeId then
      local node = self.Nodes[nodeId]
      local gate = self:GetGate(node)

      if gate.isInput or gate.isOutput then
        self.EditingNode = true
        self:OpenIONamingWindow(node, x, y)
      elseif gate.isConstant then
        self.EditingNode = true
        self:OpenConstantSetWindow(node, x, y, gate.outputtypes[1])
      end
    end
  end
end

--EXTRA WINDOWS
function Editor:CreateIONamingWindow()
  self.IONamingWindow = vgui.Create("DFrame", self)
  local pnl = self.IONamingWindow
	pnl:SetSize(200, 55)
	pnl:ShowCloseButton(true)
	pnl:SetDeleteOnClose(false)
	pnl:MakePopup()
  --pnl:SetBackgroundBlur(true)
	pnl:SetVisible(false)
	pnl:SetTitle("Name input/output")
  pnl:SetScreenLock(true)
  do
		local old = pnl.Close
		function pnl.Close()
      self.ForceDrawCursor = false
      self.EditingNode = false
			old(pnl)
		end
  end
  
  self.IONamingNameEntry = vgui.Create("DTextEntry", pnl)
  self.IONamingNameEntry:Dock(BOTTOM)
  self.IONamingNameEntry:SetSize(175, 20)
  self.IONamingNameEntry:RequestFocus()
end

function Editor:OpenIONamingWindow(node, x, y)
  if not self.IONamingWindow then self:CreateIONamingWindow() end
  self.IONamingWindow:SetVisible(true)
	self.IONamingWindow:MakePopup() -- This will move it above the E2 editor if it is behind it.
  self.ForceDrawCursor = true
  
  local px, py = self.parentpanel:GetPos()
  self.IONamingWindow:SetPos(px+x+80, py+y+30)

  self.IONamingNameEntry:SetText(node.ioName)
  self.IONamingNameEntry.OnEnter = function(pnl)
    node.ioName = pnl:GetValue()
    pnl:RequestFocus()
    pnl:GetParent():Close()
  end

  local inputField = self.IONamingNameEntry
  local this = self
  inputField.OnLoseFocus = function (pnl) 
    timer.Simple(0, function () if not pnl:GetParent():HasFocus() and this.EditingNode then pnl:OnEnter() end end)
    pnl:GetParent():MoveToFront()
  end

  self.IONamingWindow.OnFocusChanged = function (pnl, gained)
    if not gained then
      timer.Simple(0, function () if not inputField:HasFocus() and this.EditingNode then inputField:OnEnter() end end)
      pnl:MoveToFront()
    end
  end
end

function Editor:CreateConstantSetWindow()
  self.ConstantSetWindow = vgui.Create("DFrame", self)
  local pnl = self.ConstantSetWindow
	pnl:SetSize(200, 55)
	pnl:ShowCloseButton(true)
	pnl:SetDeleteOnClose(false)
  pnl:MakePopup()
  --pnl:SetBackgroundBlur(true)
	pnl:SetVisible(false)
	pnl:SetTitle("Set constant value")
  pnl:SetScreenLock(true)
  
  self.ConstantSetNormal = vgui.Create("DNumberWang", pnl)
  self.ConstantSetNormal:Dock(BOTTOM)
  self.ConstantSetNormal:SetSize(175, 20)
  self.ConstantSetNormal:SetMinMax(-10^100, 10^100)
  self.ConstantSetNormal:SetVisible(false)
  self.ConstantSetString = vgui.Create("DTextEntry", pnl)
  self.ConstantSetString:Dock(BOTTOM)
  self.ConstantSetString:SetSize(175, 20)
  self.ConstantSetString:SetVisible(false)

  do
		local old = pnl.Close
		function pnl.Close()
      self.ForceDrawCursor = false
      self.EditingNode = false
			old(pnl)
		end
  end
end

local function validateVector(string)
  local x,y,z = string.match(string, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$")
  return tonumber(x) ~= nil and tonumber(y) ~= nil and tonumber(z) ~= nil, x, y, z 
end

function Editor:OpenConstantSetWindow(node, x, y, type)
  if not self.ConstantSetWindow then self:CreateConstantSetWindow() end
  self.ConstantSetNormal:SetVisible(false)
  self.ConstantSetNormal.OnEnter = function () end
  self.ConstantSetString:SetVisible(false)
  self.ConstantSetString.OnEnter = function () end
  self.ConstantSetString:SetValue("")
  self.ConstantSetWindow:SetVisible(true)
  self.ConstantSetWindow:MakePopup() -- This will move it above the FPGA editor if it is behind it.
  self.ForceDrawCursor = true
  
  local px, py = self.parentpanel:GetPos()
  self.ConstantSetWindow:SetPos(px+x+80, py+y+30)

  if type == "NORMAL" then
    self.ConstantSetNormal:SetVisible(true)
    self.ConstantSetNormal:SetValue(node.value)
    self.ConstantSetNormal:RequestFocus()
    local func = function(pnl)
      node.value = pnl:GetValue()
      pnl:SetVisible(false)
      pnl:GetParent():Close()
    end
    self.ConstantSetNormal.OnEnter = func
  elseif type == "STRING" then
    self.ConstantSetString:SetVisible(true)
    self.ConstantSetString:SetText(node.value)
    self.ConstantSetString:RequestFocus()
    local func = function(pnl)
      node.value = pnl:GetValue()
      pnl:SetVisible(false)
      pnl:GetParent():Close()
    end
    self.ConstantSetString.OnEnter = func
  elseif type == "VECTOR" then
    self.ConstantSetString:SetVisible(true)
    self.ConstantSetString:SetText(node.value.x .. ", " .. node.value.y .. ", " .. node.value.z)
    self.ConstantSetString:RequestFocus()
    local func = function(pnl)
      valid, x, y, z = validateVector(pnl:GetValue())
      if valid then
        node.value = Vector(x, y, z)
        pnl:SetVisible(false)
        pnl:GetParent():Close()
      end
    end
    self.ConstantSetString.OnEnter = func
  elseif type == "ANGLE" then
    self.ConstantSetString:SetVisible(true)
    self.ConstantSetString:SetText(node.value.p .. ", " .. node.value.y .. ", " .. node.value.r)
    self.ConstantSetString:RequestFocus()
    local func = function(pnl)
      valid, p, y, r = validateVector(pnl:GetValue())
      if valid then
        node.value = Angle(p, y, r)
        pnl:SetVisible(false)
        pnl:GetParent():Close()
      end
    end
    self.ConstantSetString.OnEnter = func
  end

  local inputField = self.ConstantSetString
  if type == "NORMAL" then
    inputField = self.ConstantSetNormal
  end

  local this = self
  inputField.OnLoseFocus = function (pnl) 
    timer.Simple(0, function () if not pnl:GetParent():HasFocus() and this.EditingNode then pnl:OnEnter() end end)
    pnl:GetParent():MoveToFront()
  end

  self.ConstantSetWindow.OnFocusChanged = function (pnl, gained)
    if not gained then
      timer.Simple(0, function () if not inputField:HasFocus() and this.EditingNode then inputField:OnEnter() end end)
      pnl:MoveToFront()
    end
  end


end

vgui.Register("FPGAEditor", Editor, "Panel");