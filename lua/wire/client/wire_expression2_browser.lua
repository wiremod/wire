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

local function fileName(filepath)
	return string.match(filepath, "[/\\]?([^/\\]*)$")
end

function PANEL:Init()
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
	self.lastClick = -math.huge

	self:AddRightClick(self.filemenu,nil,"Open",function()
		self:OnFileOpen(self.File:GetFileName())
	end)
	self:AddRightClick(self.filemenu,nil,"Open in New Tab",function()
		self:OnFileOpen(self.File:GetFileName(), true)
	end)
	self:AddRightClick(self.filemenu,nil,"*SPACER*")
	self:AddRightClick(self.filemenu,nil,"Rename to..", function()
		local fname = fileName(self.File:GetFileName())
		Derma_StringRequestNoBlur("Rename File \"" .. fname .. "\"", "Rename file " .. fname, fname,
 		function(strTextOut)
			// Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)

			local contents = file.Read(self.File:GetFileName())
			file.Delete(self.File:GetFileName())
			file.Write(string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut .. ".txt", contents)

			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"Copy to..", function()
		local fname = fileName(self.File:GetFileName())
		Derma_StringRequestNoBlur("Copy File \"" .. fname .. "\"", "Copy File to...", fname,
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut .. ".txt", file.Read(self.File:GetFileName()))
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"*SPACER*")
	self:AddRightClick(self.filemenu,nil,"New File", function()
		Derma_StringRequestNoBlur("New File in \"" .. string.GetPathFromFilename(self.File:GetFileName()) .. "\"", "Create new file", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File:GetFileName()) .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.filemenu,nil,"Delete", function()
		Derma_Query(
			"Delete this file?", "Delete",
			"Delete", function()
				if(file.Exists(self.File:GetFileName(), "DATA")) then
					file.Delete(self.File:GetFileName())
					self:UpdateFolders()
				end
			end,
			"Cancel"
		)
	end)

	self:AddRightClick(self.foldermenu,nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File:GetFolder() .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File:GetFolder() .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.foldermenu,nil,"New Folder..",function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File:GetFolder() .. "\"", "Create new folder", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars )
			file.CreateDir( self.File:GetFolder() .. "/" .. strTextOut )
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.panelmenu,nil, "New File..", function()
		Derma_StringRequestNoBlur("New File in \"" .. self.File:GetFolder() .. "\"", "Create new file", "",
 		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(self.File:GetFolder() .. "/" .. strTextOut .. ".txt", "")
			self:UpdateFolders()
		end)
	end)
	self:AddRightClick(self.panelmenu,nil,"New Folder..",function()
		Derma_StringRequestNoBlur("new folder in \"" .. self.File:GetFolder() .. "\"", "Create new folder", "",
		function(strTextOut)
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars )
			file.CreateDir( self.File:GetFolder() .. "/" .. strTextOut )
			self:UpdateFolders()
		end)
	end)
end

function PANEL:OnFileOpen(filepath, newtab)
	error("Please override wire_expression2_browser:OnFileOpen(filepath, newtab)",0)
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
	self.Folders:Root():AddFolder(self.startfolder, self.startfolder, "data", true):SetExpanded(true)
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
