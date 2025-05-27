local function AnswerRequest(accepted, initiator, chip)
	net.Start("WireExpression2_AnswerRequest")
		net.WriteUInt(accepted, 8)
		net.WriteEntity(initiator)
		net.WriteEntity(chip)
	net.SendToServer()
end

local viewRequests = {}

-- Validates a single request using the initiator and chip (very similar to the server side equivalent in expression2.lua)
local function ValidateRequest(initiator, chip)
	if not viewRequests[initiator] or not viewRequests[initiator][chip] then return false end -- Initiator either has no data in viewRequests or has no request for this chip
	if not IsValid(initiator) then -- Invalid initiator in request table
		viewRequests[initiator] = nil
		return false
	end
	if not IsValid(chip) or chip:GetClass() ~= "gmod_wire_expression2"or CurTime() > viewRequests[initiator][chip].expiry then -- Invalid chip in request table or expired
		viewRequests[initiator][chip] = nil
		return false
	end
	return true
end

net.Receive("WireExpression2_ViewRequest", function()
	local initiator, chip, name, expiry = net.ReadEntity(), net.ReadEntity(), net.ReadString(), net.ReadFloat()
	if not viewRequests[initiator] then viewRequests[initiator] = {} end -- Initialise this user in the viewRequests table if not in there already
	viewRequests[initiator][chip] = { name = name, expiry = expiry }
end)

list.Set("DesktopWindows", "WireExpression2_ViewRequestMenu", {
	title = "View Requests",
	icon = "beer/wiremod/gate_e2", -- Use whatever icon you want here, I just picked my favourite out of the available E2 ones
	onewindow = true,

	init = function(icon, window)
		window:SetTitle("Expression 2 View Requests")

		window:SetSize(ScrW() * 0.3, ScrH() * 0.6)
		window:SetSizable(true)
		window:SetMinWidth(ScrW() * 0.1)
		window:SetMinHeight(ScrH() * 0.2)

		window:Center()

		local reqList = vgui.Create("DListView", window)
		reqList:Dock(FILL)
		reqList:SetMultiSelect(false)

		reqList:AddColumn("ID")
		reqList:AddColumn("Requested By")
		reqList:AddColumn("E2 Name")
		reqList:AddColumn("Expires In")

		for initiator, requests in pairs(viewRequests) do
			for chip, request in pairs(requests) do
				if ValidateRequest(initiator, chip) then
					local line = reqList:AddLine(tostring(chip:EntIndex()), initiator:Nick(), request.name, tostring(math.ceil(request.expiry - CurTime())))
					line.initiator = initiator
					line.chip = chip
				end
			end
		end

		local frameCounter = -1
		function reqList:Think()
			-- We don't want to do this EVERY frame, in case there are a bunch of requests, so just modulo a counter and refresh on 0
			frameCounter = (frameCounter + 1) % 10 -- Frame dependant can cause some issues with both super high and low FPS, however wont really affect this
			if frameCounter ~= 0 then return end

			local displayed = {}
			for k, line in pairs(self:GetLines()) do
				if not ValidateRequest(line.initiator, line.chip) then
					self:RemoveLine(k)
				else
					line:SetColumnText(4, tostring(math.ceil(viewRequests[line.initiator][line.chip].expiry - CurTime())))
					if not displayed[line.initiator] then displayed[line.initiator] = {} end
					displayed[line.initiator][line.chip] = true
				end
			end

			for initiator, requests in pairs(viewRequests) do
				for chip, request in pairs(requests) do
					if (not displayed[initiator] or not displayed[initiator][chip]) and ValidateRequest(initiator, chip) then
						local line = self:AddLine(tostring(chip:EntIndex()), initiator:Nick(), request.name, tostring(math.ceil(request.expiry - CurTime())))
						line.initiator = initiator
						line.chip = chip
					end
				end
			end
		end

		function reqList:OnRowRightClick(id, line)
			local mnu = DermaMenu()

			if not ValidateRequest(line.initiator, line.chip) then
				self:RemoveLine(id)
				return
			end

			mnu:AddOption("Accept Once", function()
				Derma_Query(
					"Are you SURE you want "..line.initiator:Nick().." to have complete access to the code in your chip '"..viewRequests[line.initiator][line.chip].name.."'?\nThis means they are able to steal and redistribute it, so you should only do this if you are certain you can trust them",
					"Confirm",
					"Yes", function()
						if ValidateRequest(line.initiator, line.chip) then
							AnswerRequest(1, line.initiator, line.chip)
							self:RemoveLine(id)
							viewRequests[line.initiator][line.chip] = nil
						end
					end,
					"No", function() end
				)
			end)
			mnu:AddOption("Accept Always", function()
				Derma_Query(
					"Are you SURE you want "..line.initiator:Nick().." to have complete access to the code in your chip '"..viewRequests[line.initiator][line.chip].name.."' for the duration the chip entity exists?\nThis means they are able to steal and redistribute it, as well as view any modifications you make to the chip, so you should only do this if you are certain you can trust them",
					"Confirm",
					"Yes", function()
						if ValidateRequest(line.initiator, line.chip) then
							AnswerRequest(2, line.initiator, line.chip)
							self:RemoveLine(id)
							viewRequests[line.initiator][line.chip] = nil
						end
					end,
					"No", function() end
				)
			end)
			mnu:AddOption("Reject", function()
				if ValidateRequest(line.initiator, line.chip) then
					AnswerRequest(0, line.initiator, line.chip)
					self:RemoveLine(id)
					viewRequests[line.initiator][line.chip] = nil
				end
			end)
			mnu:Open()
		end
	end
})
