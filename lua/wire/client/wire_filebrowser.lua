-- A file browser panel, used by the sound browser.
-- Can be used for any file type, recommend for huge file numbers.
-- Made by Grocel.

local PANEL = {}

AccessorFunc( PANEL, "m_strRootName", 			"RootName" ) -- name of the root Root
AccessorFunc( PANEL, "m_strRootPath", 			"RootPath" ) -- path of the root Root
AccessorFunc( PANEL, "m_strWildCard", 			"WildCard" ) -- "GAME", "DATA" etc.
AccessorFunc( PANEL, "m_tFilter", 				"FileTyps" ) -- "*.wav", "*.mdl", {"*.vmt", "*.vtf"} etc.

AccessorFunc( PANEL, "m_strOpenPath", 			"OpenPath" ) -- open path
AccessorFunc( PANEL, "m_strOpenFile", 			"OpenFile" ) -- open path+file
AccessorFunc( PANEL, "m_strOpenFilename", 		"OpenFilename" ) -- open file

AccessorFunc( PANEL, "m_nListSpeed", 			"ListSpeed" ) -- how many items to list an once
AccessorFunc( PANEL, "m_nMaxItemsPerPage",		"MaxItemsPerPage" ) -- how may items per page
AccessorFunc( PANEL, "m_nPage", 				"Page" ) -- Page to show

local invalid_chars = {
	["\n"] = "",
	["\r"] = "",
	["\\"] = "/",
	["//"] = "/",
	--["/.svn"] = "", -- Disallow access to .svn folders. (Not needed.)
	--["/.git"] = "", -- Disallow access to .git folders. (Not needed.)
}

local function ConnectPathes(path1, path2)
	local path = ""

	if isstring(path1) and path1 ~= "" then
		path = path1
		if isstring(path2) and path2 ~= "" then
			path = path1.."/"..path2
		end
	else
		if isstring(path2) and path2 ~= "" then
			path = path2
		end
	end

	return path
end

local function PathFilter(Folder, TxtPanel, Root)
	if not isstring(Folder) or Folder == "" then return end

	local ValidFolder = Folder

	--local ValidFolder = string.lower(Folder) -- for .svn and .git filters.
	for k, v in pairs(invalid_chars) do
		for i = 1, #string.Explode(k, ValidFolder) do
			if not string.match(ValidFolder, k) then break end

			ValidFolder = string.gsub(ValidFolder, k, v)
		end
	end

	ValidFolder = string.Trim(ValidFolder)
	--[[
	if string.sub(ValidFolder, 0, 4) == ".svn" then -- Disallow access to .svn folders. (Not needed.)
		ValidFolder = string.sub(ValidFolder, -4)
		if ValidFolder == ".svn" then
			ValidFolder = ""
		end
	end

	if string.sub(ValidFolder, 0, 4) == ".git" then -- Disallow access to .git folders. (Not needed.)
		ValidFolder = string.sub(ValidFolder, -4)
		if ValidFolder == ".git" then
			ValidFolder = ""
		end
	end
	--]]

	ValidFolder = string.Trim(ValidFolder, "/")

	if IsValid(TxtPanel) then
		TxtPanel:SetText(ValidFolder)
	end

	local Dirs = #string.Explode("/", ValidFolder)
	for i = 1, Dirs do
		if not file.IsDir(ConnectPathes(Root, ValidFolder), "GAME") then
			ValidFolder = string.GetPathFromFilename(ValidFolder)
			ValidFolder = string.Trim(ValidFolder, "/")
		end
	end

	ValidFolder = string.Trim(ValidFolder, "/")

	if ValidFolder == "" then return end
	return ValidFolder
end

local function EnableButton(button, bool)
	button:SetEnabled(bool)
	button:SetMouseInputEnabled(bool)
end

local function BuildFileList(path, filter, wildcard)
	local files = {}

	if istable(filter) then
		for k, v in ipairs(filter) do
			table.Add(files, file.Find(ConnectPathes(path, v), wildcard or "GAME"))
		end
	else
		table.Add(files, file.Find(ConnectPathes(path, tostring(filter)), wildcard or "GAME"))
	end

	table.sort(files)

	return files
end

local function NavigateToFolder(self, path)
	if not IsValid(self) then return end

	path = ConnectPathes(self.m_strRootPath, path)

	local root = self.Tree:Root()
	if not IsValid(root) then return end
	if not IsValid(root.ChildNodes) then return end

	local nodes = root.ChildNodes:GetChildren()
	local lastnode = nil

	local nodename = ""

	self.NotUserPressed = true
	local dirs = string.Explode("/", path)
	for k, v in ipairs(dirs) do
		if nodename == "" then
			nodename = string.lower(v)
		else
			nodename = nodename .. "/" .. string.lower(v)
			if not IsValid(lastnode) then continue end
			if not IsValid(lastnode.ChildNodes) then continue end

			nodes = lastnode.ChildNodes:GetChildren()
		end

		local found = false
		for _, node in pairs(nodes) do
			if not IsValid(node) then continue end

			local path = string.lower(node.m_strFolder)
			if nodename == "" then break end

			if path ~= nodename or found then
				node:SetExpanded(false)
				continue
			end

			if k == #dirs then -- just select the last one
				self.Tree:SetSelectedItem(node)
			end

			node:SetExpanded(true)
			lastnode = node
			found = true
		end
	end

	self.NotUserPressed = false
end

local function ShowFolder(self, path)
	if not IsValid(self) then return end

	self.m_strOpenPath = path
	path = ConnectPathes(self.m_strRootPath, path)
	self.oldpage = nil

	self.Files = BuildFileList(path, self.m_tFilter, self.m_strWildCard)

	self.m_nPage = 0
	self.m_nPageCount = math.ceil(#self.Files / self.m_nMaxItemsPerPage)

	self.PageMode = self.m_nPageCount > 1
	self.PageChoosePanel:SetVisible(self.PageMode)

	if self.m_nPageCount <= 0 or not self.PageMode then
		self.m_nPageCount = 1
		self:SetPage(1)
		return
	end

	self.PageChooseNumbers:Clear(true)
	self.PageChooseNumbers.Buttons = {}

	for i=1, self.m_nPageCount do
		self.PageChooseNumbers.Buttons[i] = self.PageChooseNumbers:Add("DButton")
		local button = self.PageChooseNumbers.Buttons[i]

		button:SetWide(self.PageButtonSize)
		button:Dock(LEFT)
		button:SetText(tostring(i))
		button:SetVisible(false)
		button:SetToolTip("Page " .. i .. " of " .. self.m_nPageCount)

		button.DoClick = function(panel)
			self:SetPage(i)
			self:LayoutPages(true)
		end
	end

	self:SetPage(1)
end

--[[---------------------------------------------------------
   Name: Init
-----------------------------------------------------------]]
function PANEL:Init()
	self.TimedpairsName = "wire_filebrowser_items_" .. tostring({})

	self.PageButtonSize = 20

	self:SetListSpeed(6)
	self:SetMaxItemsPerPage(200)

	self.m_nPageCount = 1

	self.m_strOpenPath = nil
	self.m_strOpenFile = nil
	self.m_strOpenFilename = nil

	self:SetDrawBackground(false)

	self.FolderPathPanel = self:Add("DPanel")
	self.FolderPathPanel:DockMargin(0, 0, 0, 3)
	self.FolderPathPanel:SetTall(20)
	self.FolderPathPanel:Dock(TOP)
	self.FolderPathPanel:SetDrawBackground(false)

	self.FolderPathText = self.FolderPathPanel:Add("DTextEntry")
	self.FolderPathText:DockMargin(0, 0, 3, 0)
	self.FolderPathText:Dock(FILL)
	self.FolderPathText.OnEnter = function(panel)
		self:SetOpenPath(panel:GetValue())
	end

	self.RefreshIcon = self.FolderPathPanel:Add("DImageButton") -- The Folder Button.
	self.RefreshIcon:SetImage("icon16/arrow_refresh.png")
	self.RefreshIcon:SetWide(20)
	self.RefreshIcon:Dock(RIGHT)
	self.RefreshIcon:SetToolTip("Refresh")
	self.RefreshIcon:SetStretchToFit(false)
	self.RefreshIcon.DoClick = function()
		self:Refresh()
	end

	self.FolderPathIcon = self.FolderPathPanel:Add("DImageButton") -- The Folder Button.
	self.FolderPathIcon:SetImage("icon16/folder_explore.png")
	self.FolderPathIcon:SetWide(20)
	self.FolderPathIcon:Dock(RIGHT)
	self.FolderPathIcon:SetToolTip("Open Folder")
	self.FolderPathIcon:SetStretchToFit(false)

	self.FolderPathIcon.DoClick = function()
		self.FolderPathText:OnEnter()
	end

	self.NotUserPressed = false
	self.Tree = vgui.Create( "DTree" )
	self.Tree:SetClickOnDragHover(false)
	self.Tree.OnNodeSelected = function( parent, node )
		local path = node.m_strFolder

		if not path then return end
		path = string.sub(path, #self.m_strRootPath+1)
		path = string.Trim(path, "/")

		if not self.NotUserPressed then
			self.FolderPathText:SetText(path)
		end

		if self.m_strOpenPath == path then return end
		ShowFolder(self, path)
	end

	self.PagePanel = vgui.Create("DPanel")
	self.PagePanel:SetDrawBackground(false)

	self.PageChoosePanel = self.PagePanel:Add("DPanel")
	self.PageChoosePanel:DockMargin(0, 0, 0, 0)
	self.PageChoosePanel:SetTall(self.PageButtonSize)
	self.PageChoosePanel:Dock(BOTTOM)
	self.PageChoosePanel:SetDrawBackground(false)
	self.PageChoosePanel:SetVisible(false)

	self.PageLastLeftButton = self.PageChoosePanel:Add("DButton")
	self.PageLastLeftButton:SetWide(self.PageButtonSize)
	self.PageLastLeftButton:Dock(LEFT)
	self.PageLastLeftButton:SetText("<<")
	self.PageLastLeftButton.DoClick = function(panel)
		self:SetPage(1)
	end

	self.PageLastRightButton = self.PageChoosePanel:Add("DButton")
	self.PageLastRightButton:SetWide(self.PageButtonSize)
	self.PageLastRightButton:Dock(RIGHT)
	self.PageLastRightButton:SetText(">>")
	self.PageLastRightButton.DoClick = function(panel)
		self:SetPage(self.m_nPageCount)
	end

	self.PageLeftButton = self.PageChoosePanel:Add("DButton")
	self.PageLeftButton:SetWide(self.PageButtonSize)
	self.PageLeftButton:Dock(LEFT)
	self.PageLeftButton:SetText("<")
	self.PageLeftButton.DoClick = function(panel)
		if self.m_nPage <= 1 or not self.PageMode then
			self.m_nPage = 1
			return
		end

		self:SetPage(self.m_nPage - 1)
	end

	self.PageRightButton = self.PageChoosePanel:Add("DButton")
	self.PageRightButton:SetWide(self.PageButtonSize)
	self.PageRightButton:Dock(RIGHT)
	self.PageRightButton:SetText(">")
	self.PageRightButton.DoClick = function(panel)
		if self.m_nPage >= self.m_nPageCount or not self.PageMode then
			self.m_nPage = self.m_nPageCount
			return
		end

		self:SetPage(self.m_nPage + 1)
	end

	self.PageChooseNumbers = self.PageChoosePanel:Add("DPanel")
	self.PageChooseNumbers:DockMargin(0, 0, 0, 0)
	self.PageChooseNumbers:SetSize(self.PageChoosePanel:GetWide()-60, self.PageChoosePanel:GetTall())
	self.PageChooseNumbers:Center()
	self.PageChooseNumbers:SetDrawBackground(false)

	self.PageLoadingProgress = self.PagePanel:Add("DProgress")
	self.PageLoadingProgress:DockMargin(0, 0, 0, 0)
	self.PageLoadingProgress:SetTall(self.PageButtonSize)
	self.PageLoadingProgress:Dock(BOTTOM)
	self.PageLoadingProgress:SetVisible(false)

	self.PageLoadingLabel = self.PageLoadingProgress:Add("DLabel")
	self.PageLoadingLabel:SizeToContents()
	self.PageLoadingLabel:Center()
	self.PageLoadingLabel:SetText("")
	self.PageLoadingLabel:SetPaintBackground(false)
	self.PageLoadingLabel:SetDark(true)


	self.List = self.PagePanel:Add( "DListView" )
	self.List:Dock( FILL )
	self.List:SetMultiSelect(false)
	local Column = self.List:AddColumn("Name")
	Column:SetMinWidth(150)
	Column:SetWide(200)

	self.List.OnRowSelected = function(parent, id, line)
		local name = line.m_strFilename
		local path = line.m_strPath
		local file = line.m_strFile
		self.m_strOpenFilename = name
		self.m_strOpenFile = file

		self:DoClick(file, path, name, parent, line)
	end

	self.List.DoDoubleClick = function(parent, id, line)
		local name = line.m_strFilename
		local path = line.m_strPath
		local file = line.m_strFile
		self.m_strOpenFilename = name
		self.m_strOpenFile = file

		self:DoDoubleClick(file, path, name, parent, line)
	end

	self.List.OnRowRightClick = function(parent, id, line)
		local name = line.m_strFilename
		local path = line.m_strPath
		local file = line.m_strFile
		self.m_strOpenFilename = name
		self.m_strOpenFile = file

		self:DoRightClick(file, path, name, parent, line)
	end

	self.SplitPanel = self:Add( "DHorizontalDivider" )
	self.SplitPanel:Dock( FILL )
	self.SplitPanel:SetLeft(self.Tree)
	self.SplitPanel:SetRight(self.PagePanel)
	self.SplitPanel:SetLeftWidth(200)
	self.SplitPanel:SetLeftMin(150)
	self.SplitPanel:SetRightMin(300)
	self.SplitPanel:SetDividerWidth(3)
end

function PANEL:Refresh()
	local file = self:GetOpenFile()
	local page = self:GetPage()

	self.bSetup = self:Setup()

	self:SetOpenFile(file)
	self:SetPage(page)
end


function PANEL:UpdatePageToolTips()
	self.PageLeftButton:SetToolTip("Previous Page (" .. self.m_nPage - 1 .. " of " .. self.m_nPageCount .. ")")
	self.PageRightButton:SetToolTip("Next Page (" .. self.m_nPage + 1 .. " of " .. self.m_nPageCount .. ")")

	self.PageLastRightButton:SetToolTip("Last Page (" .. self.m_nPageCount .. " of " .. self.m_nPageCount .. ")")
	self.PageLastLeftButton:SetToolTip("First Page (1 of " .. self.m_nPageCount .. ")")
end

function PANEL:LayoutPages(forcelayout)
	if not self.PageChoosePanel:IsVisible() then
		self.oldpage = nil
		return
	end

	local x, y = self.PageRightButton:GetPos()
	local Wide = x - self.PageLeftButton:GetWide()-40
	if Wide <= 0 or forcelayout then
		self.oldpage = nil
		self:InvalidateLayout()
		return
	end
	if self.oldpage == self.m_nPage and self.oldpage and self.m_nPage then return end
	self.oldpage = self.m_nPage

	if self.m_nPage >= self.m_nPageCount then
		EnableButton(self.PageLeftButton, true)
		EnableButton(self.PageRightButton, false)
		EnableButton(self.PageLastLeftButton, true)
		EnableButton(self.PageLastRightButton, false)
	elseif self.m_nPage <= 1 then
		EnableButton(self.PageLeftButton, false)
		EnableButton(self.PageRightButton, true)
		EnableButton(self.PageLastLeftButton, false)
		EnableButton(self.PageLastRightButton, true)
	else
		EnableButton(self.PageLeftButton, true)
		EnableButton(self.PageRightButton, true)
		EnableButton(self.PageLastLeftButton, true)
		EnableButton(self.PageLastRightButton, true)
	end

	local ButtonCount = math.ceil(math.floor(Wide/self.PageButtonSize)/2)
	local pagepos = math.Clamp(self.m_nPage, ButtonCount, self.m_nPageCount-ButtonCount+1)

	local VisibleButtons = 0
	for i=1, self.m_nPageCount do
		local button = self.PageChooseNumbers.Buttons[i]
		if not IsValid(button) then continue end

		if pagepos < i+ButtonCount and pagepos >= i-ButtonCount+1 then
			button:SetVisible(true)
			EnableButton(button, true)
			VisibleButtons = VisibleButtons + 1
		else
			button:SetVisible(false)
			EnableButton(button, false)
		end

		button.Depressed = false
	end

	local SelectButton = self.PageChooseNumbers.Buttons[self.m_nPage]
	if IsValid(SelectButton) then
		SelectButton.Depressed = true
		SelectButton:SetMouseInputEnabled(false)
	end

	self.PageChooseNumbers:SetWide(VisibleButtons*self.PageButtonSize)
	self.PageChooseNumbers:Center()
end

function PANEL:AddColumns(...)
	local Column = {}
	for k, v in ipairs({...}) do
		Column[k] = self.List:AddColumn(v)
	end
	return Column
end

function PANEL:Think()
	if self.SplitPanel:GetDragging() then
		self.oldpage = nil
		self:InvalidateLayout()
	end

	if not self.bSetup then
		self.bSetup = self:Setup()
	end
end

function PANEL:PerformLayout()
	self:LayoutPages()
	self.Tree:InvalidateLayout()
	self.List:InvalidateLayout()

	local minw = self:GetWide() - self.SplitPanel:GetRightMin() - self.SplitPanel:GetDividerWidth()
	local oldminw = self.SplitPanel:GetLeftWidth(minw)

	if oldminw > minw then
		self.SplitPanel:SetLeftWidth(minw)
	end


	--Fixes scrollbar glitches on resize
	self.Tree:OnMouseWheeled(0)
	self.List:OnMouseWheeled(0)

	if not self.PageLoadingProgress:IsVisible() then return end

	self.PageLoadingLabel:SizeToContents()
	self.PageLoadingLabel:Center()
end

function PANEL:Setup()
	if not self.m_strRootName then return false end
	if not self.m_strRootPath then return false end

	WireLib.TimedpairsStop(self.TimedpairsName)

	self.m_strOpenPath = nil
	self.m_strOpenFile = nil
	self.m_strOpenFilename = nil
	self.oldpage = nil

	self.Tree:Clear(true)
	if IsValid(self.Root) then
		self.Root:Remove()
	end
	self.Root = self.Tree.RootNode:AddFolder( self.m_strRootName, self.m_strRootPath, self.m_strWildCard or "GAME", false)

	return true
end

function PANEL:SetOpenFilename(filename)
	if not isstring(filename) then filename = "" end

	self.m_strOpenFilename = filename
	self.m_strOpenFile = ConnectPathes(self.m_strOpenPath, self.m_strOpenFilename)
end

function PANEL:SetOpenPath(path)
	self.Root:SetExpanded(true)

	path = PathFilter(path, self.FolderPathText, self.m_strRootPath) or ""
	if self.m_strOpenPath == path then return end
	self.oldpage = nil

	NavigateToFolder(self, path)
	self.m_strOpenPath = path
	self.m_strOpenFile = ConnectPathes(self.m_strOpenPath, self.m_strOpenFilename)
end

function PANEL:SetOpenFile(file)
	if not isstring(file) then file = "" end

	self:SetOpenPath(string.GetPathFromFilename(file))
	self:SetOpenFilename(string.GetFileFromFilename("/" .. file))
end

function PANEL:SetPage(page)
	if page < 1 then return end
	if page > self.m_nPageCount then return end
	if page == self.m_nPage then return end

	WireLib.TimedpairsStop(self.TimedpairsName)
	self.List:Clear(true)

	self.m_nPage = page
	self:UpdatePageToolTips()

	local filepage
	if self.PageMode then
		filepage = {}
		for i=1, self.m_nMaxItemsPerPage do
			local index = i + self.m_nMaxItemsPerPage * (page - 1)
			local value = self.Files[index]
			if not value then break end
			filepage[i] = value
		end
	else
		filepage = self.Files
	end

	local Fraction = 0
	local FileCount = #filepage
	local ShowProgress = (FileCount > self.m_nListSpeed * 5)

	self.PageLoadingProgress:SetVisible(ShowProgress)
	if FileCount <= 0 then
		self.PageLoadingProgress:SetVisible(false)

		return
	end

	self.PageLoadingProgress:SetFraction(Fraction)
	self.PageLoadingLabel:SetText("0 of " .. FileCount .. " files found.")
	self.PageLoadingLabel:SizeToContents()
	self.PageLoadingLabel:Center()

	self:InvalidateLayout()

	WireLib.Timedpairs(self.TimedpairsName, filepage, self.m_nListSpeed, function(id, name, self)
		if not IsValid(self) then return false end
		if not IsValid(self.List) then return false end

		local file = ConnectPathes(self.m_strOpenPath, name)
		local args, bcontinue, bbreak = self:LineData(id, file, self.m_strOpenPath, name)

		if bcontinue then return end -- continue
		if bbreak then return false end -- break

		local line = self.List:AddLine(name, unpack(args or {}))
		if not IsValid(line) then return end

		line.m_strPath = self.m_strOpenPath
		line.m_strFilename = name
		line.m_strFile = file

		if self.m_strOpenFile == file then
			self.List:SelectItem(line)
		end

		self:OnLineAdded(id, line, file, self.m_strOpenPath, name)

		Fraction = id / FileCount

		if not IsValid(self.PageLoadingProgress) then return end
		if not ShowProgress then return end

		self.PageLoadingProgress:SetFraction(Fraction)

		self.PageLoadingLabel:SetText(id .. " of " .. FileCount .. " files found.")
		self.PageLoadingLabel:SizeToContents()
		self.PageLoadingLabel:Center()
	end, function(id, name, self)
		if not IsValid(self) then return end
		Fraction = 1

		if not IsValid(self.PageLoadingProgress) then return end
		if not ShowProgress then return end

		self.PageLoadingProgress:SetFraction(Fraction)
		self.PageLoadingLabel:SetText(id .. " of " .. FileCount .. " files found.")
		self.PageLoadingLabel:SizeToContents()
		self.PageLoadingLabel:Center()

		self.PageLoadingProgress:SetVisible(false)
		self:InvalidateLayout()
	end, self)
end

function PANEL:DoClick(file, path, name)
	-- Override
end
function PANEL:DoDoubleClick(file, path, name)
	-- Override
end
function PANEL:DoRightClick(file, path, name)
	-- Override
end

function PANEL:LineData(id, file, path, name)
	return -- to override
end

function PANEL:OnLineAdded(id, line, file, path, name)
	return -- to override
end

vgui.Register("wire_filebrowser", PANEL, "DPanel")
