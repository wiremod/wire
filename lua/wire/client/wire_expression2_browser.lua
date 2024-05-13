-- Made by Shandolum - Shandolum@gmail.com
-- Overhauled by Grocel on request from Divran

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

local function fileName(filepath)
	return string.match(filepath, "[/\\]?([^/\\]*)$")
end

local string_find = string.find
local string_lower = string.lower
function PANEL:Search( str, foldername, fullpath, parentfullpath, first_recursion )
	if not self.SearchFolders[fullpath] then
		self.SearchFolders[fullpath] = (self.SearchFolders[parentfullpath] or self.Folders):AddNode( foldername )

		local files, folders = file.Find( fullpath .. "/*", "DATA" )

		local node = self.SearchFolders[fullpath]
		if fullpath == self.startfolder then self.Root = node end -- get root
		node.Icon:SetImage( "icon16/arrow_refresh.png" )
		node:SetExpanded( true )

		local myresults = 0
		for i=1,#files do
			if string_find( string_lower( files[i] ), str, 1, true ) ~= nil then
				local filenode = node:AddNode( files[i], "icon16/page_white.png" )
				filenode:SetFileName( fullpath .. "/" .. files[i] )
				myresults = myresults + 1
			end

			coroutine.yield()
		end

		if #folders == 0 then
			if myresults == 0 then
				if node ~= self.Root then node:Remove() end
				if first_recursion then
					coroutine.yield( false, myresults )
				else
					return false, myresults
				end
			end

			node.Icon:SetImage( "icon16/folder.png" )
			if first_recursion then
				coroutine.yield( true, myresults )
			else
				return true, myresults
			end
		else
			for i=1,#folders do
				local b, res = self:Search( str, folders[i], fullpath .. "/" .. folders[i], fullpath )
				if b then
					myresults = myresults + res
				end

				coroutine.yield()
			end


			if myresults > 0 then
				node.Icon:SetImage( "icon16/folder.png" )
				if first_recursion then
					coroutine.yield( true, myresults )
				else
					return true, myresults
				end
			else
				if node ~= self.Root then node:Remove() end
				if first_recursion then
					coroutine.yield( false, myresults )
				else
					return false, myresults
				end
			end
		end
	end

	if first_recursion then
		coroutine.yield( false, 0 )
	else
		return false, 0
	end
end

function PANEL:CheckSearchResults( status, bool, count )
	if bool ~= nil and count ~= nil then -- we're done searching
		if count == 0 then
			local node = self.Root:AddNode( "No results" )
			node.Icon:SetImage( "icon16/exclamation.png" )
			self.Root.Icon:SetImage( "icon16/folder.png" )
		end
		timer.Remove( "wire_expression2_search" )
		return true
	elseif not status then -- something went wrong, abort
		timer.Remove( "wire_expression2_search" )
		return true
	end
end

function PANEL:StartSearch( str )
	self:UpdateFolders( true )

	self.SearchFolders = {}

	local crt = coroutine.create( self.Search )
	local status, bool, count = coroutine.resume( crt, self, str, self.startfolder, self.startfolder, "", true )
	self:CheckSearchResults( status, bool, count )

	timer.Create( "wire_expression2_search", 0, 0, function()
		for i=1,100 do -- Load loads of files/folders at a time
			local status, bool, count = coroutine.resume( crt )

			if self:CheckSearchResults( status, bool, count ) then
				return -- exit loop etc
			end
		end
	end )
end

function PANEL:Init()
	self:SetPaintBackground(false)

	self.SearchBox = vgui.Create( "DTextEntry", self )
	self.SearchBox:Dock( TOP )
	self.SearchBox:DockMargin( 0,0,0,0 )
	self.SearchBox:SetPlaceholderText("Search...")

	local clearsearch = vgui.Create( "DImageButton", self.SearchBox )
	clearsearch:SetMaterial( "icon16/cross.png" )
	local src = self.SearchBox
	function clearsearch:DoClick()
		src:SetValue( "" )
		src:OnEnter()
	end
	clearsearch:DockMargin( 2,2,4,2 )
	clearsearch:Dock( RIGHT )
	clearsearch:SetSize( 14, 10 )
	clearsearch:SetVisible( false )

	function self.SearchBox.OnEnter()
		local str = self.SearchBox:GetValue()

		if str ~= "" then
			self:StartSearch( string.Replace( string.lower( str ), " ", "_" ) )

			clearsearch:SetVisible( true )
		else
			timer.Remove( "wire_expression2_search" )
			self:UpdateFolders()
			clearsearch:SetVisible( false )
		end
	end

	self.Update = vgui.Create("DButton", self)
	self.Update:SetTall(20)
	self.Update:Dock(BOTTOM)
	self.Update:DockMargin(0, 0, 0, 0)
	self.Update:SetText("Update")
	self.Update.DoClick = function(button)
		self:UpdateFolders()
	end

	self.Folders = vgui.Create("DTree", self)
	self.Folders:Dock(FILL)
	self.Folders:DockMargin(0, 0, 0, 0)

	self.panelmenu = {}
	self.filemenu = {}
	self.foldermenu = {}
	self.lastClick = CurTime()

	self:AddRightClick(self.filemenu, nil, "Open", function()
		self:OnFileOpen(self.File:GetFileName(), false)
	end)
	self:AddRightClick(self.filemenu, nil, "Open in New Tab", function()
		self:OnFileOpen(self.File:GetFileName(), true)
	end)
	self:AddRightClick(self.filemenu, nil, "*SPACER*")
	self:AddRightClick(self.filemenu, nil, "Rename to..", function()
		local fname = string.StripExtension(fileName(self.File:GetFileName()))
		Derma_StringRequestNoBlur("Rename File \"" .. fname .. "\"", "Rename file " .. fname, fname,
			function(strTextOut)
			-- Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars) .. ".txt"
				local newFileName = string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut
				if file.Exists(newFileName, "DATA") then
					WireLib.AddNotify("File already exists (" .. strTextOut .. ")", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				elseif not file.Rename(self.File:GetFileName(), newFileName) then
					WireLib.AddNotify("Rename was not successful", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				end
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.filemenu, nil, "Copy to..", function()
		local fname = string.StripExtension(fileName(self.File:GetFileName()))
		Derma_StringRequestNoBlur("Copy File \"" .. fname .. "\"", "Copy File to...", fname,
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.Write(string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut .. ".txt", file.Read(self.File:GetFileName()))
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.filemenu, nil, "*SPACER*")
	self:AddRightClick(self.filemenu, nil, "New File", function()
		Derma_StringRequestNoBlur("New File in \"" .. string.GetPathFromFilename(self.File:GetFileName()) .. "\"", "Create new file", "",
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.Write(string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut .. ".txt", "")
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.filemenu, nil, "Delete", function()
		local filePath = self.File:GetFileName()

		Derma_Query("Delete this file?\n\n" .. fileName(filePath), "Delete",
			"Delete", function()
				if (file.Exists(filePath, "DATA")) then
					file.Delete(filePath)
					self:UpdateFolders()
				end
			end,
			"Cancel")
	end)

	self:AddRightClick(self.foldermenu, nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File:GetFolder() .. "\"", "Create new file", "",
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.Write(self.File:GetFolder() .. "/" .. strTextOut .. ".txt", "")
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.foldermenu, nil, "New Folder..", function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File:GetFolder() .. "\"", "Create new folder", "",
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.CreateDir(self.File:GetFolder() .. "/" .. strTextOut)
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.foldermenu, nil, "Rename to..", function()
		--get full path and remove the current folder name
		local fullpath = string.Split(self.File:GetFolder(),"/")
		local oldFolderName = table.remove(fullpath)

		Derma_StringRequestNoBlur("Rename folder \"" .. self.File:GetFolder() .. "\"", "Rename Folder", oldFolderName,
			function(strTextOut)
				-- Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)

				--we are editing the root folder ("expression2" folder node)
				if #fullpath == 0 or #strTextOut == 0 then
					return
				end

				local newFolderPath = table.concat(fullpath,"/") .. "/" .. strTextOut
				if file.Exists(newFolderPath, "DATA") then
					WireLib.AddNotify("Folder already exists (" .. strTextOut .. ")", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				elseif not file.Rename(self.File:GetFolder(), newFolderPath) then
					WireLib.AddNotify("Rename was not successful", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
				end
				self:UpdateFolders()
			end)
	end)

	self:AddRightClick(self.panelmenu, nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File:GetFolder() .. "\"", "Create new file", "",
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.Write(self.File:GetFolder() .. "/" .. strTextOut .. ".txt", "")
				self:UpdateFolders()
			end)
	end)
	self:AddRightClick(self.panelmenu, nil, "New Folder..", function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File:GetFolder() .. "\"", "Create new folder", "",
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				file.CreateDir(self.File:GetFolder() .. "/" .. strTextOut)
				self:UpdateFolders()
			end)
	end)
end

function PANEL:OnFileOpen(filepath, newtab)
	error("Please override wire_expression2_browser:OnFileOpen(filepath, newtab)", 0)
end

function PANEL:UpdateFolders( empty )
	self.Folders:Clear(true)
	if IsValid(self.Root) then
		self.Root:Remove()
	end

	if not empty then
		self.Root = self.Folders.RootNode:AddFolder(self.startfolder, self.startfolder, "DATA", true)
		self.Root:SetExpanded(true)
	end

	self.Folders.DoClick = function(tree, node)
		if self.File == node and CurTime() <= self.lastClick + 0.5 then
			self:OnFileOpen(node:GetFileName())
		elseif self.OpenOnSingleClick then
			self.OpenOnSingleClick:LoadFile(node:GetFileName())
		end
		self.File = node
		self.lastClick = CurTime()
		return true
	end
	self.Folders.DoRightClick = function(tree, node)
		self.File = node
		if node:GetFileName() then
			self:OpenMenu(self.filemenu)
		else
			self:OpenMenu(self.foldermenu)
		end
		return true
	end

	self:OnFolderUpdate(self.startfolder)
end

function PANEL:GetFileName()
	if not IsValid(self.File) then return end

	return self.File:GetFileName()
end

function PANEL:GetFileNode()
	return self.File
end

function PANEL:OpenMenu(menu)
	if not menu or not IsValid(self.Folders) then return end
	if #menu < 1 then return end

	self.Menu = vgui.Create("DMenu", self.Folders)
	for k, v in pairs(menu) do
		local name, option = v[1], v[2]
		if (name == "*SPACER*") then
			self.Menu:AddSpacer()
		else
			self.Menu:AddOption(name, option)
		end
	end
	self.Menu:Open()
end

function PANEL:AddRightClick(menu, pos, name, option)
	if not menu then menu = {} end
	if not pos then pos = #menu + 1 end

	if menu[pos] then
		table.insert(menu, pos, { name, option })
		return
	end

	menu[pos] = { name, option }
end

function PANEL:RemoveRightClick(name)
	for k, v in pairs(self.filemenu) do
		if (v[1] == name) then
			self.filemenu[k] = nil
			break
		end
	end
end


function PANEL:Setup(folder)
	self.startfolder = folder
	self:UpdateFolders()
end

function PANEL:OnFolderUpdate(folder)
	-- override
end

PANEL.Refresh = PANEL.UpdateFolders -- self:Refresh() is common

vgui.Register("wire_expression2_browser", PANEL, "DPanel")
