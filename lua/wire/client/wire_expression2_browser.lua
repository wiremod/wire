// made by Shandolum - Shandolum@gmail.com

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
	local name = string.Replace( name, ".txt", "" )
	return string.Replace( name, "/", "" )
end

local function setTree(dir, parent)
	if(dir==nil) then return end
	parent:Clear(true)
	parent.ChildNodes = nil
	local pFolders = file.FindDir(dir .. "/*")
	for k, v in pairs( pFolders ) do
		local pFolder = parent:AddNode( v )
		pFolder.FileDir = dir .. "/" .. v
		pFolder.IsFile = false
		pFolder.Name = v
		setTree( pFolder.FileDir, pFolder )
	end
	local function InternalDoRightClick(self)
		self:GetRoot():SetSelectedItem( self )
		if ( self:DoRightClick() ) then return end
		if ( self:GetRoot():DoRightClick( self ) ) then return end
	end
	local pFiles = file.Find( dir .. "/*.txt" )
	for k, v in pairs( pFiles ) do
		local file = parent:AddNode( GetFileName(v) )
		file.FileDir = dir .. "/" .. v
		file.IsFile = true
		file.Name = GetFileName(v)
		file.Icon:SetImage( "vgui/spawnmenu/file" )
		file.InternalDoRightClick = InternalDoRightClick
	end
end

function PANEL:Init()
	self.Folders = {}
	self.Update = vgui.Create( "DButton" , self )
	self.Update:SetSize( self:GetWide(), 20 )
	self.Update:SetPos( 0,self:GetTall()-20 )
	self.Update:SetText( "Update" )
	self.Update.DoClick = function( button )
		self:UpdateFolders()
	end

	self.panelmenu = {}
	self.filemenu = {}
	self.foldermenu = {}

	self:AddRightClick( self.filemenu, "New File" , function()
		Derma_StringRequestNoBlur( "New File in \"" .. string.GetPathFromFilename(self.File.FileDir) .. "\"", "Create new file", "",
		function( strTextOut )
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write( string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", "" )
			self:UpdateFolders()
		end )
	end)
	self:AddRightClick( self.filemenu, "Rename to.." , function()
		Derma_StringRequestNoBlur( "Rename File \"" .. self.File.Name .. "\"", "Rename file " .. self.File.Name, self.File.Name,
 		function( strTextOut )
			// Renaming starts in the garrysmod folder now, in comparison to other commands that start in the data folder.
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Rename( "data/" .. self.File.FileDir, "data/" .. string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt" )
			self:UpdateFolders()
		end )
	end )
	self:AddRightClick( self.filemenu, "Delete" , function()
		Derma_Query(
			"Delete this file?", "Delete",
			"Delete", function()
				if(file.Exists(self.File.FileDir)) then file.Delete(self.File.FileDir) end
				self:UpdateFolders()
			end,
			"Cancel"
		)
	end )
	self:AddRightClick( self.filemenu, "Copy to.." , function()
		Derma_StringRequestNoBlur( "Copy File \"" .. self.File.Name .. "\"", "Copy File to..." , self.File.Name,
 		function( strTextOut )
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write(string.GetPathFromFilename(self.File.FileDir) .. "/" .. strTextOut .. ".txt", file.Read(self.File.FileDir) )
			self:UpdateFolders()
		end )
	end )
	self:AddRightClick( self.foldermenu, "New File.." , function()
		Derma_StringRequestNoBlur( "New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function( strTextOut )
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write( self.File.FileDir .. "/" .. strTextOut .. ".txt", "" )
			self:UpdateFolders()
		end )
	end )
	self:AddRightClick( self.panelmenu, "New File.." , function()
		Derma_StringRequestNoBlur( "New File in \"" .. self.File.FileDir .. "\"", "Create new file", "",
 		function( strTextOut )
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			file.Write( self.File.FileDir .. "/" .. strTextOut .. ".txt", "" )
			self:UpdateFolders()
		end )
	end )

	function self:OnFileClick( Dir )
		//Override this.
	end
	function self:OnFolderClick( Dir )
		//Override this.
	end
end

function PANEL:UpdateFolders()
	self.Folders = vgui.Create( "DTree" , self)
	self.Folders:SetPadding( 5 )
	self.Folders:SetPos(0,0)
	self.Folders:SetSize(self:GetWide(),self:GetTall()-20)
	setTree( self.startfolder , self.Folders )
	self.Folders.DoClick = function( tree, node )
		self.File = node
		node:SetExpanded( !node.m_bExpanded )
		if(node.IsFile) then self:OnFileClick() else self:OnFolderClick() end
		return true
	end
	self.Folders.DoRightClick = function( tree, node)
		self.File = node
		if(node.IsFile) then self:OpenMenu(self.filemenu) else self:OpenMenu(self.foldermenu) end
		return true
	end
	self.DoRightClick = function(self)
		self.File.FileDir = self.startfolder
		self:OpenMenu(self.panelmenu)
		return true
	end
end

function PANEL:PerformLayout()
	local w,h = self:GetSize()
	self.Update:SetPos( 0, h-20 )
	self.Update:SetSize( w, 20 )
	self.Folders:SetSize( w, h-20 )
end

function PANEL:OpenMenu(menu)
	if(!menu) then return end
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

vgui.Register( "wire_expression2_browser" , PANEL , "DPanel" )
