local function AnswerRequest(accepted, index, initiator, name)
	net.Start("WireExpression2_AnswerRequest")
		net.WriteBool(accepted)
		net.WriteInt(index, 32)
		net.WriteEntity(initiator)
		net.WriteString(name)
	net.SendToServer()
end

local viewRequests = {}

local function ValidateRequest(index)
	if not viewRequests[index] then return false end
	if (
		not IsValid(viewRequests[index].initiator) or
		not IsValid(viewRequests[index].chip) or
		CurTime() > viewRequests[index].expiry
	) then
		viewRequests[index] = nil
		return false
	end
	return true
end

net.Receive("WireExpression2_ViewRequest", function()
	local index, expiry, initiator, name, chip = net.ReadInt(32), net.ReadFloat(), net.ReadEntity(), net.ReadString(), net.ReadEntity()
	viewRequests[index] = {
		initiator = initiator,
		name = name,
		expiry = expiry,
		chip = chip
	}
end)

list.Set("DesktopWindows", "WireExpression2_ViewRequestMenu", {
	title = "View Requests",
	icon = "beer/wiremod/gate_e2", -- Use whatever icon you want here, I just picked my favourite out of the available E2 ones
	init = function(icon, window)
		local container = vgui.Create("DFrame")
		container:SetTitle("Expression 2 View Requests")

		container:SetSize(ScrW() * 0.3, ScrH() * 0.6)
		container:SetSizable(true)
		container:SetMinWidth(ScrW() * 0.1)
		container:SetMinHeight(ScrH() * 0.2)

		container:Center()
		container:MakePopup()

		local reqList = vgui.Create("DListView", container)
		reqList:Dock(FILL)
		reqList:SetMultiSelect(false)

		reqList:AddColumn("ID")
		reqList:AddColumn("Requested By")
		reqList:AddColumn("E2 Name")
		reqList:AddColumn("Expires In")

		for k, v in pairs(viewRequests) do
			if ValidateRequest(k) then
				reqList:AddLine(tostring(k), v.initiator:Nick(), v.name, tostring(math.ceil(v.expiry - CurTime())))
			end
		end

		local frameCounter = -1
		function reqList:Think()
			-- We don't want to do this EVERY frame, in case there are a bunch of requests, so just modulo a counter and refresh on 0
			frameCounter = (frameCounter + 1) % 10 -- Frame dependant can cause some issues with both super high and low FPS, however wont really affect this
			if frameCounter ~= 0 then return end

			local displayed = {}
			for k, line in pairs(self:GetLines()) do
				local index = tonumber(line:GetColumnText(1))
				if not ValidateRequest(index) then
					self:RemoveLine(k)
				else
					line:SetColumnText(4, tostring(math.ceil(viewRequests[index].expiry - CurTime())))
					displayed[index] = true
				end
			end
			for k, v in pairs(viewRequests) do
				if not displayed[k] and ValidateRequest(k) then
					self:AddLine(tostring(k), v.initiator:Nick(), v.name, tostring(math.ceil(v.expiry - CurTime())))
				end
			end
		end

		function reqList:OnRowRightClick(id, line)
			local mnu = DermaMenu()

			local index = tonumber(line:GetColumnText(1))
			if not ValidateRequest(index) then
				self:RemoveLine(id)
				return
			end

			mnu:AddOption("Accept", function()
				local confirm = Derma_Query(
					"Are you SURE you want "..viewRequests[index].initiator:Nick().." to have complete access to the code in your chip '"..viewRequests[index].name.."'?\nThis means they are able to steal and redistribute it, so you should only do this if you are certain you can trust them",
					"Confirm",
					"Yes", function()
						if ValidateRequest(index) then
							AnswerRequest(true, index, viewRequests[index].initiator, viewRequests[index].name)
							self:RemoveLine(id)
							viewRequests[index] = nil
						end
					end,
					"No", function() end
				)
			end)
			mnu:AddOption("Reject", function()
				if ValidateRequest(index) then
					AnswerRequest(false, index, viewRequests[index].initiator, viewRequests[index].name)
					self:RemoveLine(id)
					viewRequests[index] = nil
				end
			end)
			mnu:Open()
		end
	end
})
