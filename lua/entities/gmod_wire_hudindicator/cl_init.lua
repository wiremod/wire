include('shared.lua')

local hudindicators = {}
-- Default HUD x/y
local hudx = 22
local hudy = 200
local nextupdate = 0
-- Text Height Constant
local dtextheight = draw.GetFontHeight("Default")
-- So we don't need to calculate this every frame w/ Percent Bar style
local pbarheight = dtextheight + 16
-- Y Offset constants
local offsety = {32, 32, 32, 92 + dtextheight, 60 + dtextheight}
-- Texture IDs for Full/Semi-Circle styles
local fullcircletexid = surface.GetTextureID("hudindicator/hi_fullcircle")
local semicircletexid = surface.GetTextureID("hudindicator/hi_semicircle")

-- Function to check if a registered HUD Indicator:
-- A) belongs to someone other than the calling LocalPlayer()
-- B) is not registered as pod-only
function ENT:ClientCheckRegister()
	local ply = LocalPlayer()
	local plyuid = ply:UniqueID()
	return ply ~= self:GetPlayer() and not self:GetNWBool(plyuid)
end

-- Used by STool for unregister control panel
-- Only allowed to unregister HUD Indicators that aren't yours
-- and for those that aren't pod-only registers
function HUDIndicator_GetCurrentRegistered()
	local registered = {}
	for eindex,_ in pairs(hudindicators) do
		local ent = ents.GetByIndex(eindex)
		if IsValid(ent) then
			if (ent:ClientCheckRegister()) then
				local entry = {}
				entry.EIndex = eindex
				entry.Description = hudindicators[eindex].Description
				table.insert(registered, entry)
			end
		end
	end

	return registered
end

local function DrawHUDIndicators()
	if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end

	local currenty = hudy

	-- Now draw HUD Indicators
	for index, indinfo in SortedPairsByMemberValue(hudindicators, "Description") do
		local ent = Entity(index)

		if IsValid(ent) then
			if not indinfo.HideHUD and indinfo.Ready then
				local txt = indinfo.FullText or ""

				if (indinfo.Style == 0) then -- Basic
					draw.WordBox(8, hudx, currenty, txt, "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
				elseif (indinfo.Style == 1) then -- Gradient
					draw.WordBox(8, hudx, currenty, txt, "Default", indinfo.DisplayColor, indinfo.TextColor)
				elseif (indinfo.Style == 2) then -- Percent Bar
					--surface.SetFont("Default")
					--local pbarwidth, h = surface.GetTextSize(txt)
					--pbarwidth = math.max(pbarwidth + 16, 100) -- The extra 16 pixels is a "buffer" to make it look better
					local startx = hudx
					--local w1 = math.floor(indinfo.Factor * pbarwidth)
					--local w2 = math.ceil(pbarwidth - w1)
					local pbarwidth = indinfo.BoxWidth
					local w1 = indinfo.W1
					local w2 = indinfo.W2
					if (indinfo.Factor > 0) then -- Draw only if we have a factor
						local BColor = indinfo.BColor
						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
						surface.DrawRect(startx, currenty, w1, pbarheight)
						startx = w1 + hudx
					end

					if (indinfo.Factor < 1) then
						local AColor = indinfo.AColor
						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
						surface.DrawRect(startx, currenty, w2, pbarheight)
					end

					-- Center the description (+ value if applicable) on the percent bar
					draw.SimpleText(txt, "Default", hudx + (pbarwidth / 2), currenty + (pbarheight / 2), Color(255, 255, 255, 255), 1, 1)
				elseif (indinfo.Style == 3) then -- Full Circle Gauge
					draw.RoundedBox(8, hudx, currenty, indinfo.BoxWidth, 88 + dtextheight, Color(50, 50, 75, 192))

					surface.SetTexture(fullcircletexid)
					surface.DrawTexturedRect(hudx + 8, currenty + 8, 64, 64)

					local startx = hudx + 40
					local starty = currenty + 40
					surface.SetDrawColor(0, 0, 0, 255)
					surface.DrawLine(startx, starty, startx + indinfo.LineX, starty + indinfo.LineY)

					-- Now the text
					draw.SimpleText(txt, "Default", hudx + (indinfo.BoxWidth / 2), currenty + 72 + (pbarheight / 2), Color(255, 255, 255, 255), 1, 1)
				elseif (indinfo.Style == 4) then -- Semi-Circle Gauge
					draw.RoundedBox(8, hudx, currenty, indinfo.BoxWidth, 56 + dtextheight, Color(50, 50, 75, 192))

					surface.SetTexture(semicircletexid)
					surface.DrawTexturedRect(hudx + 8, currenty + 8, 64, 32)

					local startx = hudx + 40
					local starty = currenty + 39
					surface.SetDrawColor(0, 0, 0, 255)
					surface.DrawLine(startx, starty, startx + indinfo.LineX, starty + indinfo.LineY)

					-- Now the text
					draw.SimpleText(txt, "Default", hudx + (indinfo.BoxWidth / 2), currenty + 40 + (pbarheight / 2), Color(255, 255, 255, 255), 1, 1)
				end

				-- Go to next "line"
				currenty = currenty + offsety[indinfo.Style + 1]
			end
		else
			-- Clear this from the table so we don't check again
			hudindicators[index] = nil
		end
	end
end
hook.Add("HUDPaint", "DrawHUDIndicators", DrawHUDIndicators)

local function HUDFormatDescription( eindex )
	-- This is placed here so we don't have to update
	-- the description more often than is necessary
	local indinfo = hudindicators[eindex]
	if (indinfo.ShowValue == 0) then -- No Value
		hudindicators[eindex].FullText = indinfo.Description
	elseif (indinfo.ShowValue == 1) then -- Percent
		hudindicators[eindex].FullText = indinfo.Description.." ("..string.format("%.1f", ((indinfo.Factor or 0) * 100)).."%)"
	elseif (indinfo.ShowValue == 2) then -- Value
		-- Round to up to 2 places
		hudindicators[eindex].FullText = indinfo.Description.." ("..string.format("%g", math.Round((indinfo.Value or 0) * 100) / 100)..")"
	end

	-- Do any extra processing for certain HUD styles
	-- so we aren't calculating this every frame
	surface.SetFont("Default")
	local textwidth, _ = surface.GetTextSize(hudindicators[eindex].FullText or "")

	if (indinfo.Style == 1) then -- Gradient
		local ent = ents.GetByIndex(eindex)
		if IsValid(ent) then
			local c = ent:GetColor()
			c.a = 160
			hudindicators[eindex].DisplayColor = c

			local textcolor = Color(255, 255, 255, 255)
			if (c.r >= 192 and c.g >= 192 and c.b >= 192) then
				-- Draw dark text for very bright Indicator colors
				textcolor = Color(32, 32, 32, 255)
			end

			hudindicators[eindex].TextColor = textcolor
		end
	elseif (indinfo.Style == 2) then -- Percent Bar
		local pbarwidth = math.max(textwidth + 16, 100) -- The extra 16 pixels is a "buffer" to make it look better
		hudindicators[eindex].BoxWidth = pbarwidth
		hudindicators[eindex].W1 = math.floor((indinfo.Factor or 0) * pbarwidth)
		hudindicators[eindex].W2 = math.ceil(pbarwidth - hudindicators[eindex].W1)
	elseif (indinfo.Style == 3) then -- Full Circle Gauge
		local ang = math.rad(math.fmod((indinfo.Factor or 0) * 360 + (indinfo.FullCircleAngle or 0), 360))
		hudindicators[eindex].LineX = math.cos(ang) * 32
		hudindicators[eindex].LineY = math.sin(ang) * 32
		hudindicators[eindex].BoxWidth = math.max(textwidth + 16, 80)
	elseif (indinfo.Style == 4) then -- Semi-Circle Gauge
		local ang = math.rad((indinfo.Factor or 0) * 180 + 180)
		hudindicators[eindex].LineX = math.cos(ang) * 32
		hudindicators[eindex].LineY = math.sin(ang) * 32
		hudindicators[eindex].BoxWidth = math.max(textwidth + 16, 80)
	end
end

-- Function to ensure that the respective table index is created before any elements are added or modified
-- The HUDIndicatorRegister umsg is *supposed* to arrive (and be processed) before all the others,
-- but for some reason (probably net lag or whatever) it isn't (TheApathetic)
local function CheckHITableElement(eindex)
	if not hudindicators[eindex] then
		hudindicators[eindex] = {}
	end
end

-- UserMessage stuff
local function HUDIndicatorRegister( um )
	local eindex = um:ReadShort()
	CheckHITableElement(eindex)

	hudindicators[eindex].Description = um:ReadString()
	hudindicators[eindex].ShowValue = um:ReadShort()
	local tempstyle = um:ReadShort()
	if hudindicators[eindex].Style ~= tempstyle then
		hudindicators[eindex].Ready = false -- Make sure that everything's ready first before drawing
	end
	hudindicators[eindex].Style = tempstyle

	if not hudindicators[eindex].Factor then -- First-time register
		hudindicators[eindex].Factor = 0
		hudindicators[eindex].Value = 0
		hudindicators[eindex].HideHUD = false
		hudindicators[eindex].BoxWidth = 100
	end
	HUDFormatDescription( eindex )
end
usermessage.Hook("HUDIndicatorRegister", HUDIndicatorRegister)

local function HUDIndicatorUnRegister( um )
	local eindex = um:ReadShort()
	hudindicators[eindex] = nil
end
usermessage.Hook("HUDIndicatorUnRegister", HUDIndicatorUnRegister)

local function HUDIndicatorFactor( um )
	local eindex = um:ReadShort()
	CheckHITableElement(eindex)

	hudindicators[eindex].Factor = um:ReadFloat()
	hudindicators[eindex].Value = um:ReadFloat()
	HUDFormatDescription( eindex )
end
usermessage.Hook("HUDIndicatorFactor", HUDIndicatorFactor)

local function HUDIndicatorHideHUD( um )
	local eindex = um:ReadShort()
	CheckHITableElement(eindex)

	hudindicators[eindex].HideHUD = um:ReadBool()
end
usermessage.Hook("HUDIndicatorHideHUD", HUDIndicatorHideHUD)

local function HUDIndicatorStylePercent( um )
	local eindex = um:ReadShort()
	local ainfo = string.Explode("|", um:ReadString())
	local binfo = string.Explode("|", um:ReadString())
	CheckHITableElement(eindex)

	hudindicators[eindex].AColor = { r = ainfo[1], g = ainfo[2], b = ainfo[3]}
	hudindicators[eindex].BColor = { r = binfo[1], g = binfo[2], b = binfo[3]}
end
usermessage.Hook("HUDIndicatorStylePercent", HUDIndicatorStylePercent)

local function HUDIndicatorStyleFullCircle( um )
	local eindex = um:ReadShort()
	CheckHITableElement(eindex)

	hudindicators[eindex].FullCircleAngle = um:ReadFloat()
	HUDFormatDescription( eindex ) -- So the gauge updates with FullCircleAngle factored in
end
usermessage.Hook("HUDIndicatorStyleFullCircle", HUDIndicatorStyleFullCircle)

-- Check for updates every 1/5 seconds
local function HUDIndicatorCheck()
	if (CurTime() < nextupdate) then return end

	nextupdate = CurTime() + 0.20
	-- Keep x/y within range (the 50 and 100 are arbitrary and may change)
	hudx = math.Clamp(GetConVarNumber("wire_hudindicator_hudx") or 22, 0, ScrW() - 50)
	hudy = math.Clamp(GetConVarNumber("wire_hudindicator_hudy") or 200, 0, ScrH() - 100)

	-- Now check readiness
	for eindex,indinfo in pairs(hudindicators) do
		if not indinfo.Ready then
			if (indinfo.Style == 0) then -- Basic
				hudindicators[eindex].Ready = true -- Don't need to do any additional checks
			elseif (indinfo.Style == 1) then -- Gradient
				hudindicators[eindex].Ready = (indinfo.DisplayColor and indinfo.TextColor)
			elseif (indinfo.Style == 2) then -- Percent Bar
				hudindicators[eindex].Ready = (indinfo.BoxWidth and indinfo.W1 and indinfo.W2 and indinfo.AColor and indinfo.BColor)
			elseif (indinfo.Style == 3) then -- Full Circle Gauge
				hudindicators[eindex].Ready = (indinfo.BoxWidth and indinfo.LineX and indinfo.LineY and indinfo.FullCircleAngle)
			elseif (indinfo.Style == 4) then -- Semi-Circle Gauge
				hudindicators[eindex].Ready = (indinfo.BoxWidth and indinfo.LineX and indinfo.LineY)
			end
		end
	end
end
hook.Add("Think", "WireHUDIndicatorCVarCheck", HUDIndicatorCheck)
