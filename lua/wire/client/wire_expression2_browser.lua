// Made by Shandolum - Shandolum@gmail.com
// Overhauled by Grocel on request from Divran

local PANEL = {}

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

local function GetFileName(name)
	local name = string.Replace(name, ".txt", "")
	return string.Replace(name, "/", "")
end

local function InternalDoClick(self)
	self:GetRoot():SetSelectedItem(self)
	if (self:DoClick()) then return end
	if (self:GetRoot():DoClick(self)) then return end
end

local function InternalDoRightClick(self)
	self:GetRoot():SetSelectedItem(self)
	if(self:DoRightClick()) then return end
	if(self:GetRoot():DoRightClick(self)) then return end
end

local MaxPerTimerTick = 15 // Set Max count of elements to in to the tree per timertick. If the value is to high it will cause the "Infinite Loop Detected!" Error.

local function setTree(dir, parent)
	if (type(dir) ~= "string") or !IsValid(parent) then return end

	parent:Clear(true)
	parent.ChildNodes = nil

	local timername = {} // Timer names must be unique and can be an empty table!
	local files = file.FindDir(dir .. "/*")
	table.sort(files)
	local pFiles = file.Find(dir .. "/*.txt")
	table.sort(pFiles)
	table.Add(files, pFiles)

	if !timer.IsTimer(timername) then
		local TCount = table.Count(files)
		local TableCount = TCount/MaxPerTimerTick
		local AddedItems = {}
		local folders = {}
		local Timervalue = -(MaxPerTimerTick - 1)

		if (TableCount > 0) then
			if !parent.IsFile then
				if IsValid(parent.Icon) then
					parent.Icon:SetImage("gui/silkicons/magnifier")
				end
				if parent.SetExpanded then
					PANEL:AllowExpanding(parent, false)
				end
			end
			timer.Create(timername, 0.01, TableCount, function() // The timer is VERY important to prevent the "Infinite Loop Detected!" error on folders with many folders inseide!
				if (type(dir) ~= "string") or !IsValid(parent) then
					if timer.IsTimer(timername) then
						timer.Destroy(timername)
					end
					return
				end
				if (Timervalue < TCount) then
					Timervalue = Timervalue + MaxPerTimerTick

					for i = 1, MaxPerTimerTick do
						local index = (Timervalue + i) - 1
						local v = files[index]

						if (type(v) == "string") then
							local Filepath = (dir .. "/" .. v)
							local IsFile = !file.IsDir(Filepath)
							local FileExists = file.Exists(Filepath)

							if (!string.match(v, "%.%.") and !AddedItems[Filepath]) then // No allow double foders and folder with ".." in thay names to be shown and check if the folder is a real folder, this prevents some errors.
								if (!IsFile) then
									// Folders:
									local pNode = parent:AddNode(v)
									pNode.IsFile = IsFile
									pNode.FileDir = Filepath
									pNode.Name = v
									pNode.Icon:SetImage("vgui/spawnmenu/folder")
									pNode.InternalDoClick = InternalDoClick
									pNode.InternalDoRightClick = InternalDoRightClick
									PANEL:AllowExpanding(pNode, false)
									pNode.ChildFile = pNode:AddNode("")
									pNode.ChildFile:SetVisible(false)
									pNode.ChildFile:SetMouseInputEnabled(false)
								elseif (FileExists and IsFile) then
									// Files:
									local pNode = parent:AddNode(GetFileName(v))
									pNode.IsFile = IsFile
									pNode.FileDir = Filepath
									pNode.Name = GetFileName(v)
									pNode.Icon:SetImage("vgui/spawnmenu/file")
									pNode.InternalDoClick = InternalDoClick
									pNode.InternalDoRightClick = InternalDoRightClick
								end
								AddedItems[Filepath] = true // A list of shown files to prevent showing files that are shown already.
							end
							if (index == TCount) then
								if !parent.IsFile then
									parent.loaded = true
									if IsValid(parent.Icon) then
										parent.Icon:SetImage("vgui/spawnmenu/folder")
									end
									if parent.SetExpanded then
										PANEL:AllowExpanding(parent, true)
										parent:SetExpanded(true)
									end
								end
								if timer.IsTimer(timername) then
									timer.Destroy(timername)
								end
							end
						end
					end
				else
					if !parent.IsFile then
						parent.loaded = true
						if IsValid(parent.Icon) then
							parent.Icon:SetImage("vgui/spawnmenu/folder")
						end
						if parent.SetExpanded then
							PANEL:AllowExpanding(parent, true)
							parent:SetExpanded(true)
						end
					end
					if timer.IsTimer(timername) then
						timer.Destroy(timername)
					end
				end
			end)
		else
			if !parent.IsFile then
				if IsValid(parent.ChildFile) and IsValid(parent.Expander) then
					parent.ChildFile:Remove()
					parent.Expander:SetVisible(false)
					parent.Expander:SetMouseInputEnabled(false)
					parent:InvalidateLayout(true)
				end
				if !parent.ChildFilesLoaded then
					parent.ChildFilesLoaded = true
				end
			end
		end
	end
end

function PANEL:Init()
	--self.Folders = {}
	self.Update = vgui.Create("DButton", self)
	self.Update:SetSize(self:GetWide(), 20)
	self.Update:SetPos(0,self:GetTall()-20)
	self.Update:SetText("Update")
	self.Update.DoClick = function(button)
		self:UpdateFolders()
	end

	self.panelmenu = {}
	self.filemenu = {}
	self.foldermenu = {}

	self:AddRightClick(self.filemenu, "New File", function()
		Derma_StringRequestNoBlur("New File in \"" .. string.GetPathFromFilename(self.File.FileDir) .. "\"", "Create new file", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu, "Rename to..", function()
		Derma_StringRequestNoBlur("Rename File \"" .. self.File.Name .. "\"", "Rename file " .. self.File.Name, self.File.Name,
 		function(strTextOut)
			// Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Rename("data/" .. self.File.FileDir, "data/" .. string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu, "Delete", function()
		Derma_Query(
			"Delete this file?", "Delete",
			"Delete", function()
				if(file.Exists(self.File.FileDir)) then file.Delete(self.File.FileDir) end
				self:UpdateFolders()
			end,
			"Cancel"
		)
	end)
	self:AddRightClick(self.filemenu, "Copy to..", function()
		Derma_StringRequestNoBlur("Copy File \"" .. self.File.Name .. "\"", "Copy File to...", self.File.Name,
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", file.Read(self.File.FileDir))
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.foldermenu, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File.FileDir .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.panelmenu, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File.FileDir .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
end

function PANEL:OnFileClick(Dir)
	//Override this.
end
function PANEL:OnFolderClick(Dir)
	//Override this.
end


local function OpenFolderNode(node)
	if !IsValid(node) or !IsValid(node.ChildFile) then return end

	node.ChildFile:Remove()
	if !node.ChildFilesLoaded then
		setTree(node.FileDir, node)
		node.ChildFilesLoaded = true
	end
end

function PANEL:AllowExpanding(node, bool)
	if !IsValid(node) or !IsValid(node.Expander) then return end

	if bool then
		node.Expander.DoClick = function()
			node:GetRoot():SetSelectedItem(node)
			node:SetExpanded(!node.m_bExpanded)
			return true
		end
		node.Expander.DoRightClick = function()
			node:GetRoot():SetSelectedItem(node)
			node:SetExpanded(!node.m_bExpanded)
			return true
		end
	else
		node.Expander.DoClick = function()
			node:GetRoot():SetSelectedItem(node)
			node:SetExpanded(false)
			self.File = node
			if node.IsFile then
				self:OnFileClick(node.FileDir)
			else
				OpenFolderNode(node)
				self:OnFolderClick(node.FileDir)
			end
			return true
		end
		node.Expander.DoRightClick = function()
			node:GetRoot():SetSelectedItem(node)
			node:SetExpanded(false)
			self.File = node
			if node.IsFile then
				self:OnFileClick(node.FileDir)
			else
				OpenFolderNode(node)
				self:OnFolderClick(node.FileDir)
			end
			return true
		end
	end
end

function PANEL:UpdateFolders()
	if IsValid(self.Folders) then
		self.Folders:Remove()
		self.Folders = nil
	end

	self.Folders = vgui.Create("DTree", self)
	self.Folders:SetPadding(5)
	self.Folders:SetPos(0,0)
	self.Folders:SetSize(self:GetWide(),self:GetTall()-20)
	setTree(self.startfolder, self.Folders)
	self.Folders.DoClick = function(tree, node)
		self.File = node
		if node.IsFile then
			self:OnFileClick(node.FileDir)
		else
			if node.loaded then
				self:AllowExpanding(node, true)
				node:SetExpanded(!node.m_bExpanded)
			else
				self:AllowExpanding(node, false)
				node:SetExpanded(false)
			end
			OpenFolderNode(node)
			self:OnFolderClick(node.FileDir)
		end
		return true
	end
	self.Folders.DoRightClick = function(tree, node)
		self.File = node
		if node.IsFile then
			self:OnFileClick(node.FileDir)
		else
			if node.loaded then
				self:AllowExpanding(node, true)
				node:SetExpanded(!node.m_bExpanded)
			else
				self:AllowExpanding(node, false)
				node:SetExpanded(false)
			end
			OpenFolderNode(node)
			self:OnFolderClick(node.FileDir)
		end
		return true
	end
	self.DoRightClick = function(self)
		self.File.FileDir = self.startfolder
		self:OpenMenu(self.panelmenu)
		return true
	end
end

function PANEL:PerformLayout()
	if !IsValid(self.Update) or !IsValid(self.Folders) then return end
	local w,h = self:GetSize()
	self.Update:SetPos(0, h-20)
	self.Update:SetSize(w, 20)
	self.Folders:SetSize(w, h-20)
end

function PANEL:OpenMenu(menu)
	if !menu or !IsValid(self.Folders) then return end
	if(table.Count(menu)<1) then return end
	self.Menu = vgui.Create("DMenu", self.Folders)
	for k, v in pairs(menu) do
		self.Menu:AddOption(k,v)
	end
	self.Menu:Open()
end

function PANEL:AddRightClick(menu, name, option)
	if(!menu) then menu = {} end
	if(menu[name]) then return end
	menu[name] = option
end

function PANEL:Setup(folder)
	self.startfolder = folder
	self:UpdateFolders()
end

vgui.Register("wire_expression2_browser", PANEL, "DPanel")
