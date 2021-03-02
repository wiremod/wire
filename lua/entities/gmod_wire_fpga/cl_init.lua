include('shared.lua')

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

function ENT:GetWorldTipBodySize()
	local data = self:GetOverlayData()
	if not data then return 100, 20 end

  local w_total,h_total = surface.GetTextSize(data.name)

  if data.errorMessage then
    local str = data.errorMessage
    local w,h = surface.GetTextSize(str)
    w_total = math.max(w_total, w)
    h_total = h_total + h + 10
  end

  local timebench = data.timebench
  local timebenchPeak = data.timebenchPeak

	-- cpu time text
  local str = string.format("cpu time: %ius",  timebench * 1000000)
  local w,h = surface.GetTextSize(str)
	w_total = math.max(w_total, w)
  h_total = h_total + h + 10
  
  local str = string.format("peak cpu time: %ius", timebenchPeak * 1000000)
	local w,h = surface.GetTextSize(str)
	w_total = math.max(w_total, w)
  h_total = h_total + h + 10
  
	return w_total, h_total
end


function ENT:DrawWorldTipBody(pos)
	local data = self:GetOverlayData()
	if not data then return end

	local name = data.name

  local white = Color(255,255,255,255)
  local error = Color(255,0,0,255)
  local cputime = Color(150,150,255,255)
  local cputimeavg = Color(130,240,130,255)
	local black = Color(0,0,0,255)

	local w_total, yoffset = 0, pos.min.y

	-------------------
	-- Name
	-------------------
	local w,h = surface.GetTextSize(name)
	h = h + pos.edgesize
	h = math.min(h, pos.size.h - (pos.footersize.h))

	render.SetScissorRect(pos.min.x + 16, pos.min.y, pos.max.x - 16, pos.min.y + h, true)
	draw.DrawText(name, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 10, white, TEXT_ALIGN_CENTER)
	render.SetScissorRect(0, 0, ScrW(), ScrH(), false)

  w_total = math.max(w_total, w)
	yoffset = yoffset + h

  -- Error message
  if data.errorMessage then
    local str = "("..data.errorMessage..")"
    draw.DrawText(str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset, error, TEXT_ALIGN_CENTER)
    yoffset = yoffset + 30
  end

  --Line
	surface.SetDrawColor(black)
	surface.DrawLine(pos.min.x, yoffset, pos.max.x, yoffset)

	-------------------
	-- prfcount/benchmarking/etc
	-------------------
  local timebench = data.timebench
  local timebenchPeak = data.timebenchPeak

  -- cpu time text
  local str = string.format("cpu time: %ius", timebench * 1000000)
  draw.DrawText(str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 8, cputimeavg, TEXT_ALIGN_CENTER)
  -- cpu peak time text
  local str = string.format("peak cpu time: %ius", timebenchPeak * 1000000)
	draw.DrawText(str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 8 + 25, cputime, TEXT_ALIGN_CENTER)


  -------------------
	-- inside view
	-------------------
  if LocalPlayer():KeyDown(IN_USE) then
    if self.ViewData then
      self:DrawInsideViewBackground()
      self:DrawInsideView()
    end
  end
end

--------------------------------------------------------------------------------
-- Inside view
--------------------------------------------------------------------------------

--only square for now
--x start, x end, y start, y end
--in relation to screen center
FPGAInsideViewPosition = {
  50,
  850,
  -400,
  400
}

function ENT:DrawInsideViewBackground()
  local x1 = ScrW()/2 + FPGAInsideViewPosition[1]
  local x2 = ScrW()/2 + FPGAInsideViewPosition[2]
  local y1 = ScrH()/2 + FPGAInsideViewPosition[3]
  local y2 = ScrH()/2 + FPGAInsideViewPosition[4]

  draw.NoTexture()
  surface.SetDrawColor(Color(25,25,25,240))

  local poly = {
          {x = x1, 			y = y1,					u = 0, v = 0 },
          {x = x2, 			y = y1,					u = 0, v = 0 },
          {x = x2, 			y = y2,   	    u = 0, v = 0 },
          {x = x1, 			y = y2,					u = 0, v = 0 },
        }

  render.CullMode(MATERIAL_CULLMODE_CCW)
  surface.DrawPoly(poly)

  surface.SetDrawColor(Color(0,0,0,255))

  for i=1,#poly-1 do
    surface.DrawLine(poly[i].x, poly[i].y, poly[i+1].x, poly[i+1].y)
  end
  surface.DrawLine(poly[#poly].x, poly[#poly].y, poly[1].x, poly[1].y)
end

function ENT:DrawInsideView()
  local centerX = ScrW()/2 + (FPGAInsideViewPosition[2] - FPGAInsideViewPosition[1])/2 + FPGAInsideViewPosition[1]
  local centerY = ScrH()/2 + (FPGAInsideViewPosition[4] - FPGAInsideViewPosition[3])/2 + FPGAInsideViewPosition[3]
  local scaleX = (FPGAInsideViewPosition[2] - FPGAInsideViewPosition[1])-20
  local scaleY = (FPGAInsideViewPosition[4] - FPGAInsideViewPosition[3])-20

  local scale = math.min(scaleX, scaleY)

  local nodeSize = FPGANodeSize/self.ViewData.Scale * scale
  
  --to make sure we don't draw outside the edges
  render.SetScissorRect(
    FPGAInsideViewPosition[1] + ScrW()/2 + 1, 
    FPGAInsideViewPosition[3] + ScrH()/2 + 1, 
    FPGAInsideViewPosition[2] + ScrW()/2 - 1, 
    FPGAInsideViewPosition[4] + ScrH()/2 - 1, 
    true
  )

  --edges
  for _, edge in pairs(self.ViewData.Edges) do
    surface.SetDrawColor(FPGATypeColor[edge.type])
    surface.DrawLine(
      centerX + edge.from.x * scale, centerY + edge.from.y * scale, 
      centerX + edge.to.x * scale, centerY + edge.to.y * scale
    )
  end

  --nodes
  surface.SetDrawColor(Color(100, 100, 100, 255))
  for _, node in pairs(self.ViewData.Nodes) do
    surface.DrawRect(centerX + node.x * scale, centerY + node.y * scale, nodeSize, nodeSize * node.size)
  end

  --labels
  surface.SetFont("FPGALabel")
  surface.SetTextColor(Color(255, 255, 255, 255))
  for _, label in pairs(self.ViewData.Labels) do

    local tx, ty = surface.GetTextSize(label.text)
    surface.SetTextPos(centerX + label.x * scale - tx/2, centerY + label.y * scale - ty/2)

    surface.DrawText(label.text)
  end

  render.SetScissorRect(0, 0, ScrW(), ScrH(), false)
end



function ENT:ConstructInsideView(viewData)
  self.ViewData = {}

  -- get bounds
  local b
  if viewData.Nodes[1] then
    b = {viewData.Nodes[1].x, viewData.Nodes[1].x, viewData.Nodes[1].y, viewData.Nodes[1].y}
  else
    b = {0, 1, 0, 1}
  end
  for _, node in pairs(viewData.Nodes) do
    b[1] = math.min(b[1], node.x)
    b[2] = math.max(b[2], node.x + FPGANodeSize)
    b[3] = math.min(b[3], node.y)
    b[4] = math.max(b[4], node.y + node.s * FPGANodeSize)
  end
  borderIsLabel = {false,false,false,false}
  if viewData.Labels then
    for _, label in pairs(viewData.Labels) do
      b[1] = math.min(b[1], label.x)
      b[2] = math.max(b[2], label.x)
      b[3] = math.min(b[3], label.y)
      b[4] = math.max(b[4], label.y)
    end
  end

  local xSize = b[2]-b[1]
  local ySize = b[4]-b[3]
  self.ViewData.Size = {x = xSize, y = ySize}
  self.ViewData.Scale = math.max(math.max(xSize, ySize), 100)
  self.ViewData.Center = {b[1] + xSize/2, b[3] + ySize/2}

  self.ViewData.Nodes = {}
  for _, node in pairs(viewData.Nodes) do
    table.insert(self.ViewData.Nodes, {
      x = (node.x - self.ViewData.Center[1]) / self.ViewData.Scale,
      y = (node.y - self.ViewData.Center[2]) / self.ViewData.Scale,
      size = node.s
    })
  end
  
  self.ViewData.Labels = {}
  if viewData.Labels then
    for _, label in pairs(viewData.Labels) do
      table.insert(self.ViewData.Labels, {
        x = (label.x - self.ViewData.Center[1]) / self.ViewData.Scale,
        y = (label.y - self.ViewData.Center[2]) / self.ViewData.Scale,
        text = label.t
      })
    end
  end

  self.ViewData.Edges = {}
  if viewData.Edges then
    for _, edge in pairs(viewData.Edges) do
      table.insert(self.ViewData.Edges, {
        from = {
          x = (edge.sX - self.ViewData.Center[1]) / self.ViewData.Scale,
          y = (edge.sY - self.ViewData.Center[2]) / self.ViewData.Scale,
        },
        to = {
          x = (edge.eX - self.ViewData.Center[1]) / self.ViewData.Scale,
          y = (edge.eY - self.ViewData.Center[2]) / self.ViewData.Scale,
        },
        type = FPGATypeEnumLookup[edge.t]
      })
    end
  end
end

net.Receive("wire_fpga_view_data", function (len)
  local ent = net.ReadEntity()
  if IsValid(ent) then
    local ok, data = pcall(WireLib.von.deserialize, net.ReadString())
    if ok then
      ent:ConstructInsideView(data)
    end
  end
end)