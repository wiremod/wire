include('shared.lua')

function ENT:GetWorldTipBodySize()
	local data = self:GetOverlayData()
	if not data then return 100, 20 end

  local w_total,h_total = surface.GetTextSize(data.name)

	local timebench = data.timebench

	-- cpu time text
	local str = string.format("cpu time: %ius", timebench * 1000000)

	local w,h = surface.GetTextSize(str)
	w_total = math.max(w_total, w)
	h_total = h_total + h + 10

	return w_total, h_total
end

function ENT:DrawWorldTipBody( pos )
	local data = self:GetOverlayData()
	if not data then return end

	local name = data.name

	local white = Color(255,255,255,255)
	local black = Color(0,0,0,255)

	local w_total, yoffset = 0, pos.min.y

	-------------------
	-- Name
	-------------------
	local w,h = surface.GetTextSize(name)
	h = h + pos.edgesize
	h = math.min(h,pos.size.h - (pos.footersize.h))

	render.SetScissorRect(pos.min.x + 16, pos.min.y, pos.max.x - 16, pos.min.y + h, true)
	draw.DrawText(name, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 10, white, TEXT_ALIGN_CENTER)
	render.SetScissorRect(0, 0, ScrW(), ScrH(), false)

	w_total = math.max(w_total, w)
	yoffset = yoffset + h

	surface.SetDrawColor(black)
	surface.DrawLine(pos.min.x, yoffset, pos.max.x, yoffset)

	-------------------
	-- prfcount/benchmarking/etc
	-------------------
	local timebench = data.timebench

	-- cpu time text
	local str = string.format("cpu time: %ius", timebench * 1000000)
	draw.DrawText(str, "GModWorldtip", pos.min.x + pos.size.w/2, yoffset + 8, white, TEXT_ALIGN_CENTER)
end