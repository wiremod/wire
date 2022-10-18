// A sound property browsner. It helps to find all sounds which are defined in sound scripts or by sound.Add().
// Made by Grocel.

local PANEL = {}

local max_char_count = 200 //Name length limit

AccessorFunc( PANEL, "m_strSearchPattern", 		"SearchPattern" ) // Pattern to search for.
AccessorFunc( PANEL, "m_strSelectedSound", 		"SelectedSound" ) // Pattern to search for.
AccessorFunc( PANEL, "m_nListSpeed", 			"ListSpeed" ) // how many items to list an once
AccessorFunc( PANEL, "m_nMaxItems",				"MaxItems" ) // how may items at maximum

local function IsInString(strSource, strPattern)
	if (not strPattern) then return true end
	if (strPattern == "") then return true end

	strSource = string.lower(strSource)
	strPattern = string.lower(strPattern)

	if string.find(strSource, strPattern, 0, true) then return true end

	return false
end

local function GenerateList(self, strPattern)
	if (not IsValid(self)) then return end
	self:ClearList()

	local soundtable = sound.GetTable() or {}
	local soundcount = #soundtable
	self.SearchProgress:SetVisible(true)
	if (soundcount <= 0) then
		self.SearchProgress:SetVisible(false)

		return
	end

	self.SearchProgress:SetFraction(0)
	self.SearchProgressLabel:SetText("Searching... (0 %)")
	self.SearchProgressLabel:SizeToContents()
	self.SearchProgressLabel:Center()

	WireLib.Timedpairs(self.TimedpairsName, soundtable, self.m_nListSpeed, function(k, v, self)
		if (not IsValid(self)) then return false end
		if (not IsValid(self.SoundProperties)) then return false end
		if (not IsValid(self.SearchProgress)) then return false end

		self.SearchProgress:SetFraction(k / soundcount)
		self.SearchProgressLabel:SetText("Searching... ("..math.Round(k / soundcount * 100).." %)")
		self.SearchProgressLabel:SizeToContents()
		self.SearchProgressLabel:Center()

		if (self.TabfileCount >= self.m_nMaxItems) then
			self.SearchProgress:SetFraction(1)

			self.SearchProgressLabel:SetText("Searching... (100 %)")
			self.SearchProgressLabel:SizeToContents()
			self.SearchProgressLabel:Center()

			self.SearchProgress:SetVisible(false)
			self:InvalidateLayout()

			return false
		end

		if (not IsInString(v, strPattern)) then return end

		self:AddItem(k, v)

	end, function(k, v, self)
		if (not IsValid(self)) then return end
		if (not IsValid(self.SoundProperties)) then return end
		if (not IsValid(self.SearchProgress)) then return end

		self.SearchProgress:SetFraction(1)

		self.SearchProgressLabel:SetText("Searching... (100 %)")
		self.SearchProgressLabel:SizeToContents()
		self.SearchProgressLabel:Center()

		self.SearchProgress:SetVisible(false)
		self:InvalidateLayout()
	end, self)
end

function PANEL:Init()
	self.TimedpairsName = "wire_soundpropertylist_items_" .. tostring({})

	self:SetDrawBackground(false)
	self:SetListSpeed(100)
	self:SetMaxItems(400)

	self.SearchPanel = self:Add("DPanel")
	self.SearchPanel:DockMargin(0, 0, 0, 3)
	self.SearchPanel:SetTall(20)
	self.SearchPanel:Dock(TOP)
	self.SearchPanel:SetDrawBackground(false)

	self.SearchText = self.SearchPanel:Add("DTextEntry")
	self.SearchText:DockMargin(0, 0, 3, 0)
	self.SearchText:Dock(FILL)
	self.SearchText.OnChange = function(panel)
		self:SetSearchPattern(panel:GetValue())
	end

	self.RefreshIcon = self.SearchPanel:Add("DImageButton") // The Folder Button.
	self.RefreshIcon:SetImage("icon16/arrow_refresh.png")
	self.RefreshIcon:SetWide(20)
	self.RefreshIcon:Dock(RIGHT)
	self.RefreshIcon:SetToolTip("Refresh")
	self.RefreshIcon:SetStretchToFit(false)
	self.RefreshIcon.DoClick = function()
		self:Refresh()
	end

	self.SearchProgress = self:Add("DProgress")
	self.SearchProgress:DockMargin(0, 0, 0, 0)
	self.SearchProgress:SetTall(20)
	self.SearchProgress:Dock(BOTTOM)
	self.SearchProgress:SetVisible(false)

	self.SearchProgressLabel = self.SearchProgress:Add("DLabel")
	self.SearchProgressLabel:SizeToContents()
	self.SearchProgressLabel:Center()
	self.SearchProgressLabel:SetText("")
	self.SearchProgressLabel:SetPaintBackground(false)
	self.SearchProgressLabel:SetDark(true)


	self.SoundProperties = self:Add("DListView")
	self.SoundProperties:SetMultiSelect(false)
	self.SoundProperties:Dock(FILL)

	local Column = self.SoundProperties:AddColumn("No.")
	Column:SetFixedWidth(30)
	Column:SetWide(30)

	local Column = self.SoundProperties:AddColumn("ID")
	Column:SetFixedWidth(40)
	Column:SetWide(40)

	self.SoundProperties:AddColumn("Name")

	self.SoundProperties.OnRowSelected = function(parent, id, line)
		local name = line.m_strSoundname
		local data = line.m_tabData
		self.m_strSelectedSound = name

		self:DoClick(name, data, parent, line)
	end

	self.SoundProperties.DoDoubleClick = function(parent, id, line)
		local name = line.m_strSoundname
		local data = line.m_tabData
		self.m_strSelectedSound = name

		self:DoDoubleClick(name, data, parent, line)
	end

	self.SoundProperties.OnRowRightClick = function(parent, id, line)
		local name = line.m_strSoundname
		local data = line.m_tabData
		self.m_strSelectedSound = name

		self:DoRightClick(name, data, parent, line)
	end

	self:Refresh()
end

function PANEL:PerformLayout()
	if (not self.SearchProgress:IsVisible()) then return end

	self.SearchProgressLabel:SizeToContents()
	self.SearchProgressLabel:Center()
end

function PANEL:ClearList()
	WireLib.TimedpairsStop(self.TimedpairsName)
	self.SoundProperties:Clear(true)

	self.TabfileCount = 0
end

function PANEL:AddItem(...)
	local itemtable = {...}
	local item = itemtable[2]

	if (not isstring(item) or item == "") then return end
	if (self.TabfileCount > self.m_nMaxItems) then return end
	if (#item > max_char_count) then return end

	local itemargs = {}
	local i = 0

	for k, v in ipairs(itemtable) do
		if (k == 2) then continue end

		i = i + 1
		itemargs[i] = v
	end

	local line = self.SoundProperties:AddLine(self.TabfileCount + 1, ...)
	line.m_strSoundname = item
	line.m_tabData = itemargs

	if (self.m_strSelectedSound == item) then
		self.SoundProperties:SelectItem(line)
	end

	self.TabfileCount = self.TabfileCount + 1
	return line
end

function PANEL:SetSearchPattern(strPattern)
	self.m_strSearchPattern = strPattern or ""
	self:Refresh()
end

function PANEL:SetSelectedSound(strSelectedSound)
	self.m_strSelectedSound = strSelectedSound or ""
	self:Refresh()
end

function PANEL:Refresh()
	GenerateList(self, self.m_strSearchPattern)
end

function PANEL:DoClick(name, data, parent, line)
	-- Override
end
function PANEL:DoDoubleClick(name, data, parent, line)
	-- Override
end
function PANEL:DoRightClick(name, data, parent, line)
	-- Override
end

vgui.Register("wire_soundpropertylist", PANEL, "DPanel")
