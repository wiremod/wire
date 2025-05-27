--[[
  Expression 2 Helper for Expression 2
  -HP- (and tomylobo, though he breaks a lot ^^)
  Divran made the original CPU support
  Fasteroid made the "from" column
]] --

E2Helper = {}
local E2Helper = E2Helper -- faster access
E2Helper.Descriptions = {}

include("e2descriptions.lua")

-------------------------------
---- Extension / Mode Switching Support
E2Helper.Modes = {}
E2Helper.CurrentMode = "E2" -- Key for accessing mode.

function E2Helper:RegisterMode(name)
	if self.Modes[name] then
		-- Don't overwrite a previously existing mode if possible
		-- If an addon really wants to do so, they have access to the E2Helper mode table.
		return false
	else
		-- Name is available, return a table to be set up by caller.
		local ModeTable = {
			Descriptions = {}, -- Item descriptions
			Items = {}, -- Items
			-- There should be a ModeSetup function here taking the E2Helper table as an argument.
			-- Optionally, as well, a ModeSwitch function, taking the E2Helper as an argument.
			-- Will be called on switch, before the new mode's ModeSetup, used for teardown if necessary.
		}
		self.Modes[name] = ModeTable
		return ModeTable
	end
end

-- Which tables are we going to use?
local function CurrentDescs()
	return E2Helper.Modes[E2Helper.CurrentMode].Descriptions
end

local function CurrentTable()
	return E2Helper.Modes[E2Helper.CurrentMode].Items
end

function E2Helper:SetMode(key)
	local mode = self.Modes[key or false]
	local curMode = self.Modes[self.CurrentMode]
	if mode then
		if curMode.ModeSwitch then
			curMode.ModeSwitch(self) -- For teardown of previous setup if needed.
		end
		self.CurrentMode = key
		if mode.ModeSetup then
			mode.ModeSetup(self)
		end
		self.Update()
		return true
	end
	return false -- No mode.
end

-------------------------------

local lastmax = 0
local cookie_maxresults, cookie_tooltip, cookie_w, cookie_h
local function cookie_update()
	local current_maxresults = E2Helper.MaxEntry:GetValue()
	if current_maxresults > lastmax then
		lastmax = current_maxresults
		E2Helper.Update()
		return -- return, since E2Helper.Update() already called cookie_update again.
	end

	if current_maxresults ~= cookie_maxresults then
		cookie.Set("e2helper_maxresults", current_maxresults)
		cookie_maxresults = current_maxresults
	end

	local current_tooltip = E2Helper.Tooltip:GetChecked(true) and 1 or 0
	if current_tooltip ~= cookie_tooltip then
		cookie.Set("e2helper_tooltip", current_tooltip)
		cookie_tooltip = current_tooltip
	end

	local current_w, current_h = E2Helper.Frame:GetSize()
	if current_w ~= cookie_w then
		cookie.Set("e2helper_w", current_w)
		cookie_w = current_w
	end

	if current_h ~= cookie_h then
		cookie.Set("e2helper_h", current_h)
		cookie_h = current_h
	end
end

-- returns a function that executes <func>, delayed by <t> seconds
local function delayed(t, func)
	return function()
		timer.Remove("e2helper_delayed")
		timer.Create("e2helper_delayed", t, 1, func)
	end
end

local function getdesc(name, args)
	return CurrentDescs()[string.format("%s(%s)", name, args)] or CurrentDescs()[name]
end

-- Register the E2 mode, this shouldn't need be done twice because it indexes global for its info
local E2Mode = E2Helper:RegisterMode("E2")
if E2Mode then
	local E2ModeMetatable = {
		__index = function(self,key)
			if key == "Items" then return wire_expression2_funcs end
			if key == "Descriptions" then return E2Helper.Descriptions end
			return nil
		end
	}
	E2Mode.Items = nil
	E2Mode.Descriptions = nil
	-- The metatable is needed because storing a ref to wire_expression2_funcs
	-- and then causing e2 to reload (like changing extensions) doesn't update the ref
	-- or something like that, it causes e2helper to access nil values.
	setmetatable(E2Mode,E2ModeMetatable)
	E2Mode.ModeSetup = function(E2HelperPanel)
		E2HelperPanel.FunctionColumn:SetName("Function")
		E2HelperPanel.FunctionColumn:SetWidth(126)
		E2HelperPanel.FromColumn:SetName("From")
		E2HelperPanel.FromColumn:SetWidth(80)
		E2HelperPanel.TakesColumn:SetName("Takes")
		E2HelperPanel.TakesColumn:SetWidth(60)
		E2HelperPanel.ReturnsColumn:SetName("Returns")
		E2HelperPanel.ReturnsColumn:SetWidth(60)
		E2HelperPanel.CostColumn:SetName("Cost")
		E2HelperPanel.CostColumn:SetWidth(40)
	end

end

function E2Helper.Create(reset)

	E2Helper.Frame = vgui.Create("DFrame")
	E2Helper.Frame:SetSize(340, 425)
	E2Helper.Frame:Center()
	E2Helper.Frame:SetSizable(true)
	E2Helper.Frame:SetScreenLock(true)
	E2Helper.Frame:SetDeleteOnClose(false)
	E2Helper.Frame:SetVisible(false)
	E2Helper.Frame:SetTitle("E2Helper")
	E2Helper.Frame._PerformLayout = E2Helper.Frame.PerformLayout
	function E2Helper.Frame:PerformLayout(...)
		local w, h = E2Helper.Frame:GetSize()
		if w < 300 then w = 300 end
		if h < 300 then h = 300 end
		E2Helper.Frame:SetSize(w, h)

		self:_PerformLayout(...)
		E2Helper.Resize()
	end

	-- holds all the lines describing a constant
	E2Helper.constants = {}

	E2Helper.DescriptionEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.DescriptionEntry:SetPos(5, 330)
	E2Helper.DescriptionEntry:SetSize(330, 45)
	E2Helper.DescriptionEntry:SetEditable(true)
	E2Helper.DescriptionEntry:SetMultiline(true)

	E2Helper.ResultFrame = vgui.Create("DListView", E2Helper.Frame)
	E2Helper.ResultFrame:SetPos(5, 60)
	E2Helper.ResultFrame:SetSize(330, 240)
	E2Helper.ResultFrame:SetMultiSelect(false)
	-- Default 5 columns, accessable by index here for more modularity.
	E2Helper.Columns = {
		E2Helper.ResultFrame:AddColumn("Function"),
		E2Helper.ResultFrame:AddColumn("From"),
		E2Helper.ResultFrame:AddColumn("Takes"),
		E2Helper.ResultFrame:AddColumn("Returns"),
		E2Helper.ResultFrame:AddColumn("Cost"),
	}
	E2Helper.Columns[1]:SetWidth(126)
	E2Helper.Columns[2]:SetWidth(80)
	E2Helper.Columns[3]:SetWidth(60)
	E2Helper.Columns[4]:SetWidth(60)
	E2Helper.Columns[5]:SetWidth(40)
	-- Name keys for backwards compatibility
	E2Helper.FunctionColumn = E2Helper.Columns[1]
	E2Helper.FromColumn = E2Helper.Columns[2]
	E2Helper.TakesColumn = E2Helper.Columns[3]
	E2Helper.ReturnsColumn = E2Helper.Columns[4]
	E2Helper.CostColumn = E2Helper.Columns[5]

	function E2Helper.ResultFrame:OnClickLine(line)
		self:ClearSelection()
		self:SelectItem(line)

		local const = E2Helper.constants[line]
		if const then
			E2Helper.FuncEntry:SetText(line:GetValue(1) .. " (" .. const.type .. ")")

			if const.description then
				E2Helper.DescriptionEntry:SetText(const.description)
				E2Helper.DescriptionEntry:SetTextColor(color_black)
			else
				E2Helper.DescriptionEntry:SetText("No description found :(")
				E2Helper.DescriptionEntry:SetTextColor(Color(128, 128, 128))
			end
		else
			E2Helper.FuncEntry:SetText(E2Helper.GetFunctionSyntax(line:GetValue(1), line:GetValue(3), line:GetValue(4)))
			local desc = getdesc(line:GetValue(1), line:GetValue(3))
			if desc then
				E2Helper.DescriptionEntry:SetText(desc)
				E2Helper.DescriptionEntry:SetTextColor(Color(0, 0, 0))
			else
				E2Helper.DescriptionEntry:SetText("No description found :(")
				E2Helper.DescriptionEntry:SetTextColor(Color(128, 128, 128))
			end
		end
	end

	E2Helper.Image = vgui.Create("DImage", E2Helper.Frame)
	E2Helper.Image:SetPos(5, 75)
	E2Helper.Image:SetImage("expression 2/cog.vtf")
	E2Helper.Image:SetImageColor(Color(255, 0, 0, 8))
	E2Helper.Image:SetSize(225, 225)

	E2Helper.ResultLabel = vgui.Create("DLabel", E2Helper.Frame)
	E2Helper.ResultLabel:SetPos(5, 405)
	E2Helper.ResultLabel:SetText("")
	E2Helper.ResultLabel:SizeToContents()

	E2Helper.CredLabel = vgui.Create("DLabel", E2Helper.Frame)
	E2Helper.CredLabel:SetPos(298, 405)
	E2Helper.CredLabel:SetText("By -HP-")
	E2Helper.CredLabel:SizeToContents()
	E2Helper.CredLabel.Resize = { true, true, false, false }

	E2Helper.NameEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.NameEntry:SetPos(5, 32)
	E2Helper.NameEntry:SetWide(83)

	E2Helper.FromEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.FromEntry:SetPos(5+83, 32)
	E2Helper.FromEntry:SetWide(83)

	E2Helper.ParamEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.ParamEntry:SetPos(5+83*2, 32)
	E2Helper.ParamEntry:SetWide(83)

	E2Helper.ReturnEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.ReturnEntry:SetPos(5+83*3, 32)
	E2Helper.ReturnEntry:SetWide(82)

	E2Helper.Tooltip = vgui.Create("DCheckBoxLabel", E2Helper.Frame)
	E2Helper.Tooltip:SetPos(5, 384)
	E2Helper.Tooltip:SetText("Tooltip")
	E2Helper.Tooltip:SetValue(reset and 0 or cookie.GetNumber("e2helper_tooltip", 0))
	E2Helper.Tooltip:SizeToContents()

	E2Helper.FuncEntry = vgui.Create("DTextEntry", E2Helper.Frame)
	E2Helper.FuncEntry:SetText("")
	E2Helper.FuncEntry:SetWidth(330)
	E2Helper.FuncEntry:SetPos(5, 305)

	E2Helper.MaxEntry = vgui.Create("DNumberWang", E2Helper.Frame)
	E2Helper.MaxEntry:SetPos(295, 380)
	E2Helper.MaxEntry:SetWide(40)
	E2Helper.MaxEntry:SetTooltip("E2 is being loaded, please wait...")
	timer.Create("E2Helper.SetMaxEntry", 1, 0, function()
		if e2_function_data_received then
			E2Helper.MaxEntry:SetMax(table.Count(CurrentTable()))
			timer.Remove("E2Helper.SetMaxEntry")
			E2Helper.MaxEntry:SetTooltip(false)
		end
	end)
	E2Helper.MaxEntry:SetValue(reset and 50 or cookie.GetNumber("e2helper_maxresults", 50))
	E2Helper.MaxEntry:SetDecimals(0)

	E2Helper.MaxLabel = vgui.Create("DLabel", E2Helper.Frame)
	E2Helper.MaxLabel:SetPos(233, 384)
	E2Helper.MaxLabel:SetText("Max results:")
	E2Helper.MaxLabel:SizeToContents()

	E2Helper.ModeSelect = vgui.Create("DComboBox", E2Helper.Frame)
	E2Helper.ModeSelect:SetPos(90, 384)
	local modecount = 0
	for k,_ in pairs(E2Helper.Modes) do
		modecount = modecount + 1
		E2Helper.ModeSelect:AddChoice(k)
	end
	if modecount < 2 then
		-- If we don't have enough modes it's pointless to display this I think.
		E2Helper.ModeSelect:Hide()
	else
		E2Helper.ModeSelect:Show()
	end
	function E2Helper.ModeSelect:OnSelect(ind,value,data)
		E2Helper:SetMode(value)
	end

	E2Helper.NameEntry.OnTextChanged = delayed(0.1, E2Helper.Update)
	E2Helper.FromEntry.OnTextChanged = delayed(0.1, E2Helper.Update)
	E2Helper.ParamEntry.OnTextChanged = delayed(0.1, E2Helper.Update)
	E2Helper.ReturnEntry.OnTextChanged = delayed(0.1, E2Helper.Update)
	E2Helper.Tooltip.OnChange = E2Helper.Update
	E2Helper.MaxEntry.OnValueChanged = delayed(1, cookie_update)

	local x, y, w, h
	E2Helper.Originals = {}
	for k, v in pairs(E2Helper) do
		if type(v) == "Panel" then
			x, y = v:GetPos()
			w, h = v:GetSize()
			E2Helper.Originals[k] = { x, y, w, h }
		end
	end

	if not reset then
		E2Helper.Frame:SetSize(cookie.GetNumber("e2helper_w", 280), cookie.GetNumber("e2helper_h", 425))
	else
		cookie_update()
	end
	E2Helper.Resize()
end

function E2Helper.GetFunctionSyntax(func, args, rets)
	if E2Helper.CurrentMode == "E2" then
		local signature = func .. "(" .. args .. ")"
		local ret = E2Lib.generate_signature(signature, rets, wire_expression2_funcs[signature].argnames)
		if rets ~= "" then ret = ret:sub(1, 1):upper() .. ret:sub(2) end
		return ret
	else
		--local args = string.gsub(args, "(%a)", "%1,", string.len( args ) - 1) -- this gsub puts a comma in between each letter
		return func .. " " .. args
	end
end

function E2Helper.Update()

	cookie_update()

	E2Helper.ResultFrame:Clear()
	E2Helper.ModeSelect:SetValue(E2Helper.CurrentMode)

	local search_name, search_from, search_args, search_rets = E2Helper.NameEntry:GetValue():lower(), E2Helper.FromEntry:GetValue():lower(), E2Helper.ParamEntry:GetValue():lower(), E2Helper.ReturnEntry:GetValue():lower()
	local count = 0
	local maxcount = E2Helper.MaxEntry:GetValue()
	local tooltip = E2Helper.Tooltip:GetChecked(true)

	-- add E2 constants
	E2Helper.constants = {}
	if E2Helper.CurrentMode == "E2" then
		for k, v in pairs(wire_expression2_constants) do
			-- constants have no arguments and no cost
			local name, args, rets, cost = k, nil, v.type, 0
			if name:lower():find(search_name, 1, true) and search_args == "" and rets:lower():find(search_rets, 1, true) and string.find("constants",search_from, 1, true) then
				local line = E2Helper.ResultFrame:AddLine(name, v.extension, args, rets, cost)
				E2Helper.constants[line] = v
				count = count + 1
				if count >= maxcount then break end
			end
		end
	end

	if count < maxcount then
		for _, v in pairs(CurrentTable()) do
			if E2Helper.CurrentMode == "E2" then
				local from, signature, rets, cost = v.extension, v[1], v[2], v[4]
				local name, args = string.match(signature, "^([^(]+)%(([^)]*)%)$")

				if signature:sub(1, 3) ~= "op:" and
						name:lower():find(search_name, 1, true) and
						from:lower():find(search_from, 1, true) and
						args:lower():find(search_args, 1, true) and
						rets:lower():find(search_rets, 1, true) then
					local line = E2Helper.ResultFrame:AddLine(name, from, args, rets, cost or 20)
					if tooltip then line:SetTooltip(E2Helper.GetFunctionSyntax(name, args, rets)) end
					count = count + 1
					if count >= maxcount then break end
				end
			else
				local funcname, extension, args, forwhat, functype = unpack(v)
				if funcname:lower():find(search_name, 1, true) and
						extension:lower():find(search_from, 1, true) and
						args:lower():find(search_args, 1, true) and
						forwhat:lower():find(search_rets, 1, true) then
					local line = E2Helper.ResultFrame:AddLine(funcname, extension, args, forwhat, functype)
					if tooltip then line:SetTooltip(funcname .. " " .. args) end
					count = count + 1
					if count >= maxcount then break end
				end
			end
		end
	end

	E2Helper.ResultFrame:SortByColumn(1)
	E2Helper.ResultLabel:SetText(count .. " results")
	E2Helper.ResultLabel:SizeToContents()
end

function E2Helper.Show(searchtext)
	if not E2Helper.Frame then E2Helper.Create(false) end
	E2Helper.Frame:MakePopup()
	E2Helper.Frame:SetVisible(true)
	if searchtext and searchtext ~= E2Helper.NameEntry:GetValue() then
		E2Helper.NameEntry:SetValue(searchtext)
		E2Helper.Update()
		E2Helper.FuncEntry:SetValue("")
		E2Helper.DescriptionEntry:SetValue("")
	else
		E2Helper.NameEntry:RequestFocus()
	end
end

local delayed_cookie_update = delayed(1, cookie_update)

local lastw, lasth
function E2Helper.Resize()
	local w, h = E2Helper.Frame:GetSize()
	if w == lastw and h == lasth then return end

	local orig = E2Helper.Originals
	local changew, changeh = w - orig.Frame[3], h - orig.Frame[4]

	-- Epically messy code:
	E2Helper.CredLabel:SetPos(orig.CredLabel[1] + changew, orig.CredLabel[2] + changeh)
	E2Helper.MaxLabel:SetPos(orig.MaxLabel[1] + changew, orig.MaxLabel[2] + changeh)
	E2Helper.MaxEntry:SetPos(orig.MaxEntry[1] + changew, orig.MaxEntry[2] + changeh)
	E2Helper.ResultLabel:SetPos(orig.ResultLabel[1], orig.ResultLabel[2] + changeh)
	E2Helper.Tooltip:SetPos(orig.Tooltip[1], orig.Tooltip[2] + changeh)
	E2Helper.FuncEntry:SetPos(orig.FuncEntry[1], orig.FuncEntry[2] + changeh)
	E2Helper.FuncEntry:SetSize(orig.FuncEntry[3] + changew, orig.FuncEntry[4])
	E2Helper.DescriptionEntry:SetPos(orig.DescriptionEntry[1], orig.DescriptionEntry[2] + changeh)
	E2Helper.DescriptionEntry:SetSize(orig.DescriptionEntry[3] + changew, orig.DescriptionEntry[4])
	E2Helper.ResultFrame:SetSize(orig.ResultFrame[3] + changew, orig.ResultFrame[4] + changeh)
	E2Helper.ModeSelect:SetPos(orig.ModeSelect[1] + changew, orig.ModeSelect[2] + changeh)

	E2Helper.NameEntry:SetSize(orig.NameEntry[3] + changew * 0.25, orig.NameEntry[4])
	E2Helper.FromEntry:SetPos(orig.FromEntry[1] + changew * 0.25, orig.FromEntry[2])
	E2Helper.FromEntry:SetSize(orig.FromEntry[3] + changew * 0.25, orig.FromEntry[4])
	E2Helper.ParamEntry:SetPos(orig.ParamEntry[1] + changew * 0.5, orig.ParamEntry[2])
	E2Helper.ParamEntry:SetSize(orig.ParamEntry[3] + changew * 0.25, orig.ParamEntry[4])
	E2Helper.ReturnEntry:SetPos(orig.ReturnEntry[1] + changew * 0.75, orig.ReturnEntry[2])
	E2Helper.ReturnEntry:SetSize(orig.ReturnEntry[3] + changew * 0.25, orig.ReturnEntry[4])

	-- Keep the (funky) image overlay centered on  the listview
	local w1, h1 = E2Helper.ResultFrame:GetSize()
	local x1, y1 = E2Helper.ResultFrame:GetPos()

	-- add borders of mysterious dimensions
	x1 = x1 + 15
	w1 = w1 - 30
	y1 = y1 + 30
	h1 = h1 - 45

	-- fix aspect ratio
	if w1 > h1 then
		x1 = x1 + (w1 - h1) / 2
		w1 = h1
	else
		y1 = y1 + (h1 - w1) / 2
		h1 = w1
	end

	-- apply position and size
	E2Helper.Image:SetPos(x1, y1)
	E2Helper.Image:SetSize(w1, h1)

	delayed_cookie_update()

	lastw, lasth = w, h
end

concommand.Add("e2helper", function() E2Helper.Show() end)
concommand.Add("e2helper_reset", function()
	if E2Helper.Frame then
		E2Helper.Frame:SetDeleteOnClose(true)
		E2Helper.Frame:Close()
	end
	E2Helper.Create(true)
	cookie_update()
end)

local PrevCtrlQ
hook.Add("Think", "E2Helper_KeyListener", function()
	if not E2Helper.Frame then return end
	local CtrlQ = input.IsKeyDown(KEY_Q) and (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL))
	if CtrlQ and not PrevCtrlQ and E2Helper.Frame:IsActive() then
		E2Helper.Frame:SetVisible(false)
	end
	PrevCtrlQ = CtrlQ
end)
