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

local cvar = CreateClientConVar( "wire_expression2_browser_sort_style", "0", true, false )
local function sort( t, dir )
	if (cvar:GetInt() == 0) then -- Alphabetical order; a -> z
		table.sort( t )
	elseif (cvar:GetInt() == 1) then -- Alphabetical order; z -> a
		table.sort( t, function( a, b ) return a > b end )
	elseif (cvar:GetInt() == 2) then -- Time order; new -> old
		table.sort( t, function( a, b ) return file.Time( dir .. "/" .. a ) > file.Time( dir .. "/" .. b ) end )
	elseif (cvar:GetInt() == 3) then -- Time order; old -> new
		table.sort( t, function( a, b ) return file.Time( dir .. "/" .. a ) < file.Time( dir .. "/" .. b ) end )
	else
		ErrorNoHalt( "Expression 2 browser: Invalid sort type specified, defaulting to sorting by alphabetical order." )
		table.sort( t ) -- Default to alphabetical order
	end
end

local MaxPerTimerTick = 15 // Set Max count of elements to in to the tree per timertick. If the value is to high it will cause the "Infinite Loop Detected!" Error.

local function setTree(dir, parent)
	if (type(dir) ~= "string") or !IsValid(parent) then return end

	parent:Clear(true)
	parent.ChildNodes = nil

	local timername = {} // Timer names must be unique and can be an empty table!
	local _,files = file.Find(dir .. "/*", "DATA")
	--table.sort(files)
	sort( files, dir )
	local pFiles = file.Find(dir .. "/*.txt", "DATA")
	--table.sort(pFiles)
	sort( pFiles, dir )
	table.Add(files, pFiles)

	if !timer.Exists(timername) then
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
					if timer.Exists(timername) then
						timer.Remove(timername)
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
							local IsFile = not file.IsDir(Filepath, "DATA")
							local FileExists = file.Exists(Filepath, "DATA")

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
								if timer.Exists(timername) then
									timer.Remove(timername)
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
					if timer.Exists(timername) then
						timer.Remove(timername)
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

	self:AddRightClick(self.filemenu,nil,"Open",function()
		self:GetParent():Open( self.File.FileDir )
	end)
	self:AddRightClick(self.filemenu,nil,"Open in New Tab",function()
		self:GetParent():Open( self.File.FileDir, nil, true )
	end)
	self:AddRightClick(self.filemenu,nil,"*SPACER*")
	self:AddRightClick(self.filemenu,nil,"Rename to..", function()
		Derma_StringRequestNoBlur("Rename File \"" .. self.File.Name .. "\"", "Rename file " .. self.File.Name, self.File.Name,
 		function(strTextOut)
			// Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)

			-- The rename function appears to be broken. Using file.Read, file.Delete, and file.Write instead.
			--file.Rename("data/" .. self.File.FileDir, "data/" .. string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt")

			local contents = file.Read( self.File.FileDir )
			file.Delete( self.File.FileDir )
			file.Write( string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", contents )

			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"Copy to..", function()
		Derma_StringRequestNoBlur("Copy File \"" .. self.File.Name .. "\"", "Copy File to...", self.File.Name,
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", file.Read(self.File.FileDir))
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"*SPACER*")
	self:AddRightClick(self.filemenu,nil,"New File", function()
		Derma_StringRequestNoBlur("New File in \"" .. string.GetPathFromFilename(self.File.FileDir) .. "\"", "Create new file", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"Delete", function()
		Derma_Query(
			"Delete this file?", "Delete",
			"Delete", function()
				if(file.Exists(self.File.FileDir, "DATA")) then
					file.Delete(self.File.FileDir)
					self:UpdateFolders()
				end
			end,
			"Cancel"
		)
	end)

	self:AddRightClick(self.foldermenu,nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File.FileDir .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.foldermenu,nil,"New Folder..",function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File.FileDir .. "\"", "Create new folder", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars )
			file.CreateDir( self.File.FileDir .. "/" .. strTextOut )
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.panelmenu,nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File.FileDir .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.panelmenu,nil,"New Folder..",function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File.FileDir .. "\"", "Create new folder", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars )
			file.CreateDir( self.File.FileDir .. "/" .. strTextOut )
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
			self:OpenMenu(self.filemenu)
		else
			self:OpenMenu(self.foldermenu)
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
		local name, option = v[1], v[2]
		if (name == "*SPACER*") then
			self.Menu:AddSpacer()
		else
			self.Menu:AddOption(name,option)
		end
	end
	self.Menu:Open()
end

function PANEL:AddRightClick(menu, pos, name, option)
	if(!menu) then menu = {} end
	if (!pos) then pos = #menu + 1 end
	if(menu[pos]) then
		table.insert(menu,pos,{name,option})
		return
	end
	menu[pos] = {name,option}
end

function PANEL:Setup(folder)
	self.startfolder = folder
	self:UpdateFolders()
end

vgui.Register("wire_expression2_browser", PANEL, "DPanel")
