// A list editor. It allows reading editing and saving lists as *.txt files.
// It uses wire_expression2_browser for it's file browser.
// The files have an easy structure for easy editing. Rows are separated by '\n' and columns by '|'.
// Made by Grocel.

local PANEL = {}

AccessorFunc( PANEL, "m_strRootPath", 		"RootPath" ) // path of the root Root
AccessorFunc( PANEL, "m_strList", 			"List" ) // List file
AccessorFunc( PANEL, "m_strFile", 			"File" ) // sounds listed in list files
AccessorFunc( PANEL, "m_bUnsaved", 			"Unsaved" ) // edited list file Saved?
AccessorFunc( PANEL, "m_strSelectedList", 	"SelectedList" ) // Selected list file

AccessorFunc( PANEL, "m_nListSpeed", 			"ListSpeed" ) // how many items to list an once
AccessorFunc( PANEL, "m_nMaxItems",				"MaxItems" ) // how may items at maximum

local max_char_count = 200 //File length limit

local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
}

local invalid_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["\\"] = "",
	['"'] = "",
}

local function ConnectPathes(path1, path2)
	local path = ""

	if (isstring(path1) and path1 ~= "") then
		path = path1
		if (isstring(path2) and path2 ~= "") then
			path = path1.."/"..path2
		end
	else
		if (isstring(path2) and path2 ~= "") then
			path = path2
		end
	end

	return path
end

//Parse the lines from a given file object
local function ReadLine(filedata)
	if (not filedata) then return end

	local fileline = ""
	local comment = false
	local count = 0

	for i=1, 32 do // skip 32 lines at maximum
		local line = ""
		local fileend = false

		for i=1, max_char_count+56 do // maximum chars per line
			local byte = filedata:ReadByte()
			fileend = not byte

			if (fileend) then break end // file end
			local char = string.char(byte)

			if (invalid_chars[char]) then // replace invalid chars
				char = invalid_chars[char]
			end

			if (char == "\n") then break end // line end
			line = line .. char
		end
		line = string.Trim(line)

		if (not fileend and line == "") then continue end
		fileline = line

		break
	end

	local linetable = string.Explode("|", fileline) or {}

	if (#linetable == 0) then return end

	for k, v in ipairs(linetable) do // cleanup
		local line = linetable[k]

		if (k == 1) then
			line = string.Trim(line, "/")
		end
		line = string.Trim(line)

		linetable[k] = line
	end

	if (#linetable[1] == 0) then return end

	return linetable
end

local function fileName(filepath)
	return string.match(filepath, "[/\\]?([^/\\]*)$")
end

local function SaveTo(self, func, ...)
	if (not IsValid(self)) then return end
	local args = {...}

	local path = self.FileBrowser:GetFileName() or self.m_strList or ""

	Derma_StringRequestNoBlur(
		"Save to New File",
		"",
		string.sub(fileName(path), 0, -5), // remove .txt at the end

		function( strTextOut )
			if (not IsValid(self)) then return end

			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			if (strTextOut == "") then return end

			local filepath = string.GetPathFromFilename(path)
			if (not filepath or filepath == "") then filepath = self.m_strRootPath.."/" end

			local saved = self:SaveList(filepath..strTextOut..".txt")
			if (saved and func) then
				func(self, unpack(args))
			end
		end
	)
	return true
end

//Ask for override: Opens a confirmation if the file name is different box.
local function AsForOverride(self, func, filename, ...)
	if (not IsValid(self)) then return end

	if (not func) then return end
	if (filename == self.m_strList) then func(self, filename, ...) return end
	if (not file.Exists(filename, "DATA")) then func(self, filename, ...) return end

	local args = {...}

	Derma_Query(
		"Overwrite this file?",
		"Save To",
		"Overwrite",

		function()
			if (not IsValid(self)) then return end

			func(self, filename, unpack(args))
		end,

		"Cancel"
	)
end

//Ask for save: Opens a confirmation box.
local function AsForSave(self, func, ...)
	if (not IsValid(self)) then return end

	if (not func) then return end
	if (not self.m_bUnsaved) then func(self, ...) return end

	local args = {...}

	Derma_Query( "Would you like to save the changes?",
		"Unsaved List!",

		"Yes", // Save and resume.
		function()
			if (not IsValid(self)) then return end

			if (not self.m_strList or self.m_strList == "") then
				SaveTo(self, func, unpack(args))
				return
			end

			local saved = self:SaveList(self.m_strList)
			if (saved) then
				func(self, unpack(args))
			end
		end,

		"No", // Don't save and resume.
		function()
			if (not IsValid(self)) then return end
			func(self, unpack(args))
		end,

		"Cancel" // Do nothing.
	)
end


function PANEL:Init()
	self.TimedpairsName = "wire_listeditor_items_" .. tostring({})

	self:SetDrawBackground(false)

	self:SetListSpeed(40)
	self:SetMaxItems(512)
	self:SetUnsaved(false)

	self.TabfileCount = 0
	self.Tabfile = {}

	self.ListsPanel = vgui.Create("DPanel")
	self.ListsPanel:SetDrawBackground(false)

	self.FilesPanel = vgui.Create("DPanel")
	self.FilesPanel:SetDrawBackground(false)

	self.FileBrowser = self.ListsPanel:Add("wire_expression2_browser")
	self.FileBrowser:Dock(FILL)
	self.FileBrowser.OnFileOpen = function(panel, listfile)
		self:OpenList(listfile)
	end
	self.FileBrowser:RemoveRightClick("Open in New Tab") // we don't need tabs.
	self.FileBrowser:AddRightClick(self.FileBrowser.filemenu,4,"Save To..", function()
		self:SaveList(self.FileBrowser:GetFileName())
	end)
	self.FileBrowser.Update:Remove() // it's replaced

	self.Files = self.FilesPanel:Add("DListView")
	self.Files:SetMultiSelect(false)
	self.Files:Dock(FILL)

	local Column = self.Files:AddColumn("No.")
	Column:SetFixedWidth(30)
	Column:SetWide(30)

	self.Files:AddColumn("Name")

	local Column = self.Files:AddColumn("Type")
	Column:SetFixedWidth(70)
	Column:SetWide(70)

	self.Files.OnRowSelected = function(parent, id, line)
		local name = line.m_strFilename
		local data = line.m_tabData
		self.m_strFile = name
		self.m_strSelectedList = self.m_strList

		self:DoClick(name, data, parent, line)
	end

	self.Files.DoDoubleClick = function(parent, id, line)
		local name = line.m_strFilename
		local data = line.m_tabData
		self.m_strFile = name
		self.m_strSelectedList = self.m_strList

		self:DoDoubleClick(name, data, parent, line)
	end

	self.Files.OnRowRightClick = function(parent, id, line)
		local name = line.m_strFilename
		local data = line.m_tabData
		self.m_strFile = name
		self.m_strSelectedList = self.m_strList

		self:DoRightClick(name, data, parent, line)
	end

	self.ListTopPanel = self.FilesPanel:Add("DPanel")
	self.ListTopPanel:SetDrawBackground(false)
	self.ListTopPanel:Dock(TOP)
	self.ListTopPanel:SetTall(20)
	self.ListTopPanel:DockMargin(0, 0, 0, 3)

	self.SaveIcon = self.ListTopPanel:Add("DImageButton")
	self.SaveIcon:SetImage("icon16/table_save.png")
	self.SaveIcon:SetWide(20)
	self.SaveIcon:Dock(LEFT)
	self.SaveIcon:SetToolTip("Save list")
	self.SaveIcon:SetStretchToFit(false)
	self.SaveIcon:DockMargin(0, 0, 0, 0)
	self.SaveIcon.DoClick = function()
		if (not self.m_strList or self.m_strList == "") then
			SaveTo(self)
			return
		end

		self:SaveList(self.m_strList)
	end

	self.SaveToIcon = self.ListTopPanel:Add("DImageButton")
	self.SaveToIcon:SetImage("icon16/disk.png")
	self.SaveToIcon:SetWide(20)
	self.SaveToIcon:Dock(LEFT)
	self.SaveToIcon:SetToolTip("Save To..")
	self.SaveToIcon:SetStretchToFit(false)
	self.SaveToIcon:DockMargin(0, 0, 0, 0)
	self.SaveToIcon.DoClick = function()
		SaveTo(self)
	end

	self.NewIcon = self.ListTopPanel:Add("DImageButton")
	self.NewIcon:SetImage("icon16/table_add.png")
	self.NewIcon:SetWide(20)
	self.NewIcon:Dock(LEFT)
	self.NewIcon:SetToolTip("New list")
	self.NewIcon:SetStretchToFit(false)
	self.NewIcon:DockMargin(10, 0, 0, 0)
	self.NewIcon.DoClick = function()
		self:ClearList()
	end

	self.RefreshIcon = self.ListTopPanel:Add("DImageButton")
	self.RefreshIcon:SetImage("icon16/arrow_refresh.png")
	self.RefreshIcon:SetWide(20)
	self.RefreshIcon:Dock(LEFT)
	self.RefreshIcon:SetToolTip("Refresh and Reload")
	self.RefreshIcon:SetStretchToFit(false)
	self.RefreshIcon:DockMargin(0, 0, 0, 0)
	self.RefreshIcon.DoClick = function()
		self:Refresh()
	end

	self.ListNameLabel = self.ListTopPanel:Add("DLabel")
	self.ListNameLabel:SetText("")
	self.ListNameLabel:SetWide(20)
	self.ListNameLabel:Dock(FILL)
	self.ListNameLabel:DockMargin(12, 0, 0, 0)
	self.ListNameLabel:SetDark(true)

	self.SplitPanel = self:Add( "DHorizontalDivider" )
	self.SplitPanel:Dock( FILL )
	self.SplitPanel:SetLeft(self.ListsPanel)
	self.SplitPanel:SetRight(self.FilesPanel)
	self.SplitPanel:SetLeftWidth(200)
	self.SplitPanel:SetLeftMin(150)
	self.SplitPanel:SetRightMin(300)
	self.SplitPanel:SetDividerWidth(3)

	self:SetRootPath("wirelists")
end

function PANEL:PerformLayout()
	local minw = self:GetWide() - self.SplitPanel:GetRightMin() - self.SplitPanel:GetDividerWidth()
	local oldminw = self.SplitPanel:GetLeftWidth(minw)

	if (oldminw > minw) then
		self.SplitPanel:SetLeftWidth(minw)
	end

	//Fixes scrollbar glitches on resize
	if (IsValid(self.FileBrowser.Folders)) then
		self.FileBrowser.Folders:OnMouseWheeled(0)
	end
	self.Files:OnMouseWheeled(0)
end

function PANEL:UpdateListNameLabel()
	if (not IsValid(self.ListNameLabel)) then return end

	self.ListNameLabel:SetText((self.m_bUnsaved and "*" or "")..(self.m_strList or ""))
end


function PANEL:ClearList()
	AsForSave(self, function(self)
		self:SetList(nil)
		self:SetUnsaved(false)
		self.TabfileCount = 0

		WireLib.TimedpairsStop(self.TimedpairsName)
		self.Files:Clear(true)
		self.Tabfile = {}
	end)
end

function PANEL:Setup()
	if (not self.m_strRootPath) then return false end
	self.m_strSelectedList = nil
	self.m_strFile = nil

	self:ClearList()

	self.FileBrowser:Setup(self.m_strRootPath)

	return true
end

function PANEL:Refresh()
	self.FileBrowser:Refresh()
	self:OpenList(self.m_strList)

	self:InvalidateLayout()
end

function PANEL:Think()
	if (self.SplitPanel:GetDragging()) then
		self:InvalidateLayout()
	end

	if ( not self.bSetup ) then
		self.bSetup = self:Setup()
	end
end

function PANEL:AddItem(...)
	local itemtable = {...}
	local item = itemtable[1]

	if (not isstring(item) or item == "") then return end
	if (self.TabfileCount > self.m_nMaxItems) then return end
	if (#item > max_char_count) then return end
	if (self.Tabfile[item]) then return end

	local itemargs = {}
	local i = 0

	for k, v in ipairs(itemtable) do
		if (k == 1) then continue end

		i = i + 1
		itemargs[i] = v
	end
	self.Tabfile[item] = itemargs

	local line = self.Files:AddLine(self.TabfileCount + 1, ...)
	line.m_strFilename = item
	line.m_tabData = itemargs

	//if (self.m_strFile == item) then
	if (self.m_strSelectedList == self.m_strList and self.m_strFile == item) then
		self.Files:SelectItem(line)
	end

	self.TabfileCount = self.TabfileCount + 1
	self:SetUnsaved(true)
	return line
end

function PANEL:ItemInList(item)
	if (not item) then return false end
	if (self.Tabfile[item]) then return true end

	return false
end

function PANEL:RemoveItem(item)
	if (not item) then return end
	if (not self.Tabfile[item]) then return end
	if (not self.Files.Lines) then return end

	for k, v in ipairs(self.Files.Lines) do
		if (v.m_strFilename == item) then
			self.Files:RemoveLine(v:GetID())
			self.Tabfile[item] = nil
			self:SetUnsaved(true)
			self.TabfileCount = self.TabfileCount - 1

			break
		end
	end
end

function PANEL:OpenList(strfile)
	if (not strfile) then return end
	if (strfile == "") then return end

	AsForSave(self, function(self, strfile)
		local filedata = file.Open(strfile, "rb", "DATA")
		if (not filedata) then return end

		WireLib.TimedpairsStop(self.TimedpairsName)
		self.Files:Clear(true)
		self.Tabfile = {}
		self.TabfileCount = 0

		local counttab={}
		for i=1, self.m_nMaxItems do
			counttab[i] = true
		end

		WireLib.Timedpairs(self.TimedpairsName, counttab, self.m_nListSpeed, function(index, _, self, filedata)
			if (not IsValid(self)) then
				filedata:Close()
				return false
			end

			if (not IsValid(self.Files)) then
				filedata:Close()
				return false
			end

			if (self.TabfileCount >= self.m_nMaxItems) then
				filedata:Close()
				self:SetUnsaved(false)

				return false
			end

			local linetable = ReadLine(filedata)
			if (not linetable) then // do not add to empty lines
				filedata:Close()
				self:SetUnsaved(false)

				return false
			end

			self:AddItem(unpack(linetable))
			self:SetUnsaved(false)
		end, function(index, _, self, filedata)
			filedata:Close()

			if (not IsValid(self)) then return end
			self:SetUnsaved(false)
		end, self, filedata)

		self:SetUnsaved(false)
		self:SetList(strfile)
	end, strfile)
end

function PANEL:SaveList(strfile)
	if (not self.Tabfile) then return end
	if (not strfile) then return end
	if (strfile == "") then return end

	AsForOverride(self, function(self, strfile)
		local filedata = file.Open(strfile, "w", "DATA")
		if (not filedata) then
			Derma_Query( "File could not be saved!",
				"Error!",
				"OK"
			)

			return
		end

		for key, itemtable in SortedPairs(self.Tabfile) do
			local item = key
			for k, supitem in ipairs(itemtable) do
				item = item.." | "..supitem
			end
			filedata:Write(item.."\n")
		end

		filedata:Close()

		self:SetUnsaved(false)
		self:SetList(strfile)

		self:Refresh()
	end, strfile)
end

function PANEL:SetRootPath(path)
	self.m_strRootPath = path

	self.bSetup = self:Setup()
end

function PANEL:SetUnsaved(bool)
	self.m_bUnsaved = bool

	self:UpdateListNameLabel()
end

function PANEL:SetList(listfile)
	self.m_strList = listfile

	self:UpdateListNameLabel()
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

vgui.Register("wire_listeditor", PANEL, "DPanel")
