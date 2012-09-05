// A Sound Browser for using with the wire sound emitter and the expression gate 2.
// ================================================================================
// Made By Grocel.

local PANEL = {}
local MaxElements = 1800 // If you try to show more then 2000 files at once then the tree will disappear and you cant reopen it, so leave the value at 1800 or below to be safe.
local MaxPerTimerTick = 15 // Set Max count of elements to in to the tree per timertick. If the value is to high it will cause the "Infinite Loop Detected!" Error.

local timername = {} // Timer names must be unique and can be an empty table!
local lastselected = ""

function PANEL:GetFileName(filepath) // Return the filename of the given filepath without "/" or "\" at the beginning.
	local filename = string.Trim(string.Trim(string.Trim(filepath), "/"), "\\")
	return filename
end

function PANEL:FindItemsInTree(pFolders, dir, parent, fileicon, filepart, filecount, MaxFileParts) // Build the folders and files to the tree.
	if !timer.Exists(timername) then
		local TCount = math.Clamp(filecount, 0, MaxElements)
		local TableCount = TCount/MaxPerTimerTick
		local AddedItems = {}
		local Timervalue = -(MaxPerTimerTick - 1)

		if(dir ~= "sound") then
			// One Folder Back:
			local pBackNode = parent:AddNode("..")
			pBackNode.FileDir = dir
			pBackNode.ID = ("Node_ID_BackNode")
			pBackNode.Icon:SetImage("vgui/spawnmenu/folderUp")
			if (lastselected == "Node_ID_BackNode") then // Get the saved ItemID and select its owner.
				self.FolderTree:SetSelectedItem(pBackNode)
			end
		end

		if (TableCount > 0) then
			timer.Create(timername, 0.01, TableCount, function() // The timer is VERY important to prevent the "Infinite Loop Detected!" error on folders with many folders inseide!
				if ((Timervalue < TCount) and (self.SoundBrowserPanel:IsVisible() == true)) then
					Timervalue = Timervalue + MaxPerTimerTick

					for i = 1, MaxPerTimerTick do
						local index = (Timervalue + i) - 1
						local v = pFolders[index + (MaxElements * filepart)]
						if (type(v) == "string") then
							local Filepath = (dir .. "/" .. v)
							local IsDir = file.IsDir(Filepath,"GAME")
							local FileExists = file12.Exists(Filepath,"GAME")
							local NodeID = ("Node_ID_"..index..tostring(IsDir)..Filepath)
							if (!string.match(v, "%.%.") and !AddedItems[Filepath]) then // No allow double foders and folder with ".." in thay names to be shown and check if the folder is a real folder, this prevents some errors.
								if (IsDir) then
									// Folders:
									local pNode = parent:AddNode(v)
									pNode.IsFile = !IsDir
									pNode.FileDir = Filepath
									pNode.ID = NodeID
									pNode.Icon:SetImage("vgui/spawnmenu/folder")
									if (NodeID == lastselected) then // Get the saved ItemID and select its owner.
										self.FolderTree:SetSelectedItem(pNode)
									end
								elseif (FileExists and !IsDir) then
									// Files:
									local pNode = parent:AddNode(self:GetFileName(v))
									pNode.IsFile = !IsDir
									pNode.FileDir = Filepath
									pNode.ID = NodeID
									pNode.Icon:SetImage(fileicon or "vgui/spawnmenu/file")
									if (NodeID == lastselected) then // Get the saved ItemID and select its owner.
										self.FolderTree:SetSelectedItem(pNode)
									end
								end
								AddedItems[Filepath] = true // A list of shown files to prevent showing files that are shown already.
							end
							if (index == TCount) then
								if timer.Exists(timername) then
									timer.Remove(timername)
								end
							end
							if (filepart == MaxFileParts) then
								self:SetStatusBar(filecount % MaxElements, index, IsDir, filepart, filecount, MaxFileParts)
							else
								self:SetStatusBar(TCount, index, IsDir, filepart, filecount, MaxFileParts)
							end
						end
					end
				else
					if timer.Exists(timername) then
						timer.Remove(timername)
					end
				end
			end)
		else
			self:SetStatusBar()
		end
	end
end

local olddir = ""

function PANEL:BuildFileTree(dir, parent, filepart) // Build the file tree.
	if(type(dir) ~= "string" or !IsValid(parent)) then return end

	parent:Clear()
	parent.ChildNodes = nil

	if timer.Exists(timername) then
		timer.Remove(timername)
	end

	local pFolders = self.pFoldersT

	if ((!pFolders) or (olddir ~= dir)) then // Find the files only one time when open a folder. It saves performance.
		self.FilepartNumber = 0

		pFolders = file.FindDir(dir .. "/*","GAME") // Find the folders.
		for i = 1, math.Clamp(table.Count(pFolders), 0, MaxElements) do // Make filepath and names lowercase.
			pFolders[i] = string.lower(pFolders[i])
		end
		table.sort(pFolders)


		local pFiles1 = file.Find(dir .. "/*.wav","GAME") // Find the *.wav-files.
		local pFiles2 = file.Find(dir .. "/*.mp3","GAME") // Find the *.mp3-files.
		table.Add(pFiles1, pFiles2) // Put *.wav and *.mp3-files together.
		for i = 1, math.Clamp(table.Count(pFiles1), 0, MaxElements) do // Make filepath and names lowercase.
			pFiles1[i] = string.lower(pFiles1[i])
		end
		table.sort(pFiles1)

		table.Add(pFolders, pFiles1)
		self.pFoldersT = pFolders

		olddir = dir
	end

	local filecount = table.Count(pFolders)
	local MaxFileParts = math.floor(filecount / MaxElements)

	self:SetShowMode(filecount > MaxElements, filepart, MaxFileParts)

	self:FindItemsInTree(pFolders, dir, parent, "gui/silkicons/sound", filepart, filecount, MaxFileParts) // Build the folders and files to the tree.
end

function PANEL:SetShowMode(bool, filepart, MaxFileParts) // Show the next and previous buttons only, when thay are needed.
	local h = self.SoundBrowserPanel:GetTall()

	if ((self.ShowPreviousButton:IsVisible() == !bool) and (self.ShowNextButton:IsVisible() == !bool)) then
		self.ShowPreviousButton:SetVisible(bool)
		self.ShowNextButton:SetVisible(bool)
	end
	self.FilepartNumber = math.Clamp(self.FilepartNumber, 0, MaxFileParts)

	if (self.ShowPreviousButton:IsVisible() and self.ShowNextButton:IsVisible()) then
		if (filepart >= MaxFileParts) then
			self.ShowPreviousButton:SetEnabled(true)
			self.ShowPreviousButton:SetMouseInputEnabled(true)
			self.ShowNextButton:SetEnabled(false)
			self.ShowNextButton:SetMouseInputEnabled(false)
		elseif (filepart <= 0) then
			self.ShowPreviousButton:SetEnabled(false)
			self.ShowPreviousButton:SetMouseInputEnabled(false)
			self.ShowNextButton:SetEnabled(true)
			self.ShowNextButton:SetMouseInputEnabled(true)
		else
			self.ShowPreviousButton:SetEnabled(true)
			self.ShowPreviousButton:SetMouseInputEnabled(true)
			self.ShowNextButton:SetEnabled(true)
			self.ShowNextButton:SetMouseInputEnabled(true)
		end
	end

	if (bool) then
		self.FolderTree:SetTall(h-247.5)
		self.FolderTree:SetPos(12.5, 90)
	else
		self.FolderTree:SetTall(h-217.5)
		self.FolderTree:SetPos(12.5, 60)
	end

	self.SoundBrowserPanel:InvalidateLayout(true)
end

function PANEL:SetStatusBar(fullvalue, value, IsDir, filepart, filecount, MaxFileParts)
	local w = self.SoundBrowserPanel:GetWide()
	local stop = false

	if ((type(fullvalue) == "number") and (fullvalue ~= 0)) then
		local SValue = math.Clamp(value, 0, fullvalue)
		self.StatusValue = SValue / fullvalue
	elseif (type(fullvalue) == "boolean") then
		stop = fullvalue
		self.StatusValue = 1
	else
		self.StatusValue = 1
	end

	if (filepart and (filecount > MaxElements)) then
		fileparttext = (" (Part " ..(filepart + 1).. " Of " ..(MaxFileParts + 1).. " Open.)")
	else
		fileparttext = ""
	end

	local statustext = ("Ready!".. fileparttext)
	if (self.StatusValue >= 1) then
		if (!stop) then
			statustext = ("Ready!".. fileparttext)
		end
		if (self.StopLoadingButton:IsVisible()) then // Show the Stop Loading buttons only, when files are loading.
			self.StopLoadingButton:SetVisible(false)
			self.FolderPathText:SetPos(32.5, 37.5)
			self.FolderPathText:SetWide(w - 45)
			self.SoundBrowserPanel:InvalidateLayout(true)
		end
	else
		if (IsDir) then
			statustext = ("Loading Folders: " ..value.. " Of " ..fullvalue.. " Loaded." ..fileparttext)
		else
			statustext = ("Loading Files: " ..value.. " Of " ..fullvalue.. " Loaded." ..fileparttext)
		end
		if (!self.StopLoadingButton:IsVisible()) then // Show the Stop Loading buttons only, when files are loading.
			self.StopLoadingButton:SetVisible(true)
			self.FolderPathText:SetPos(52.5, 37.5)
			self.FolderPathText:SetWide(w - 65)
			self.SoundBrowserPanel:InvalidateLayout(true)
		end
	end
	if (stop) then
		statustext = ("Loading Aborted!".. fileparttext)
	end
	self.StatusText = statustext
end

function PANEL:Sendmenu(sound) // Open a sending and setup menu on right click on a sound file or on pressing the "Sent To" button.
	if ((type(sound) == "string") and (sound ~= "")) then
		MenuButtonOptions = DermaMenu()
		if (self.SoundEmitter) then
			MenuButtonOptions:AddOption("Setup Soundemitter", function()
				// Setup the Soundemitter stool with the soundpath.
				LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundemitter stool has been setup with the soundpath." )
				RunConsoleCommand("wire_soundemitter_sound", sound)
				// Pull out the soundemitter stool after setup.
				RunConsoleCommand("tool_wire_soundemitter")
			end)
			MenuButtonOptions:AddOption("Copy to Clipboard", function()
				// Copy the soundpath to Clipboard.
				LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundpath has been copied to Clipboard." )
				SetClipboardText(sound)
			end)
		else
			MenuButtonOptions:AddOption("Copy to Clipboard", function()
				// Copy the soundpath to Clipboard.
				LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundpath has been copied to Clipboard." )
				SetClipboardText(sound)
			end)
			MenuButtonOptions:AddOption("Setup Soundemitter", function()
				// Setup the Soundemitter stool with the soundpath.
				LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundemitter stool has been setup with the soundpath." )
				RunConsoleCommand("wire_soundemitter_sound", sound)
				// Pull out the soundemitter stool after setup.
				RunConsoleCommand("tool_wire_soundemitter")
			end)
		end
		MenuButtonOptions:AddOption("Print to Console", function()
			// Print the soundpath in the Console.
			LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundpath has been printed to the console.")
			LocalPlayer():PrintMessage( HUD_PRINTTALK, sound)
		end)
		MenuButtonOptions:AddOption("Print to Chat", function()
			// Say the the soundpath.
			LocalPlayer():PrintMessage( HUD_PRINTTALK, "The soundpath has been written to the chat.")
			RunConsoleCommand("say", sound)
		end)
		MenuButtonOptions:Open()
	end
end

function PANEL:PlaySound(sound) // Play the given sound, if no sound given then mute a playing sound.
	if ((type(sound) == "string") and (sound ~= "")) then
		RunConsoleCommand("play", sound)
	else
		RunConsoleCommand("play", "common/NULL.WAV") // You can do the same with the concommand "stopsounds", but playing a silent sound will not mute the sound emitters.
	end
end

function PANEL:GetSoundInfors(sound) // Output the infos about the given sound.
	local SoundInfoString = ""
	if ((type(sound) == "string") and (sound ~= "")) then
		local seconds = math.Round(SoundDuration(sound) * 1000) / 1000
		local sizeB = file.Size("sound/"..sound,"GAME") or 0
		local sizeKB = math.Round((sizeB / 1024) * 1000) / 1000
		local format = string.lower(string.GetExtensionFromFilename("sound/"..sound,true))
		local m, s, ms = seconds / 60, seconds % 60, (seconds % 1) * 1000
		local length = (string.format("%01d", m)..":"..string.format("%02d", s).."."..string.format("%03d", ms))
		SoundInfoString = ("Soundfile: "..sound.."\n\rLength: "..length.." ("..seconds.." Seconds)\n\rSize: "..sizeKB.." KB ("..sizeB.." Bytes)\n\rFormat: "..format.."\n\r")
	end
	return SoundInfoString
end

function PANEL:UpdateFolders(Foldername, Panel, Text, filepart) // Make the file tree panel.
	if(!IsValid(Text) or !IsValid(Panel)) then return end

	function self:OnDoubleClick(lastclick, func) // Add double the click support.
		if ((CurTime() - lastclick) < 0.5) then
			func()
		else
			self.LastClick = CurTime()
		end
	end

	local Folder = "sound"
	if ((type(Foldername) ~= "string") or (Foldername == "")) then
		Folder = "sound"
	else
		Folder = ("sound/" ..Foldername)
	end

	if (self.FolderTree) then
		self.FolderTree:Remove()
		self.FolderTree = nil
	end

	self.FolderTree = vgui.Create("DTree") // The File Tree Browser.
	self.FolderTree:SetParent(Panel)
	self.FolderTree:SetPos(12.5, 60)
	local w, h = Panel:GetSize()
	self.FolderTree:SetSize(w-25, h-217.5)
	self:BuildFileTree(Folder, self.FolderTree, filepart or 0)
	self.FolderTree.DoClick = function(tree, node)
		if(node.IsFile) then
			self.SoundPath = string.sub(node.FileDir, 6) // Remove "../sound/" part out of the string.
			Text:SetText(self:GetSoundInfors(self.SoundPath))
			if (self.SoundEmitter) then
				self.EmitterLastSoundPath = self.SoundPath
			else
				self.LastSoundPath = self.SoundPath
			end
			self:OnDoubleClick(self.LastClick, function()
				self:PlaySound(self.SoundPath)
			end)
		else
			self:OnDoubleClick(self.LastClick, function()
				if (node.ID == "Node_ID_BackNode") then
					local bfolder = node.FileDir
					local dirs = string.Explode("/", bfolder)
					local backfolder = string.sub(bfolder, 0, -(string.len(dirs[table.Count(dirs)]) + 1))

					self:OpenFolder(string.sub(backfolder, 6))
				else
					self:OpenFolder(string.sub(node.FileDir, 6))
				end
			end)
		end
		lastselected = node.ID // Save the ID of the selected item.
		return true
	end
	self.FolderTree.DoRightClick = function(tree, node)
		self.FolderTree:SetSelectedItem(node)
		if(node.IsFile) then
			self.SoundPath = string.sub(node.FileDir, 6) // Remove "../sound/" part out of the string.
			Text:SetText(self:GetSoundInfors(self.SoundPath))
			if (self.SoundEmitter) then
				self.EmitterLastSoundPath = self.SoundPath
			else
				self.LastSoundPath = self.SoundPath
			end
			self:Sendmenu(self.SoundPath)
		end
		lastselected = node.ID // Save the ID of the selected item.
		return true
	end
end

function PANEL:OpenFolder(dir)
	self.Foldername = self:GetValidFolder(dir)
	if (self.SoundEmitter) then
		self.EmitterLastFoldername = self.Foldername
	else
		self.LastFoldername = self.Foldername
	end
	self.FilepartNumber = 0
	self:UpdateFolders(self.Foldername, self.SoundBrowserPanel, self.SoundInfoText, self.FilepartNumber)
end


function PANEL:GetEndBounds(Panel) // This is to return position of the down-right corner of the given panel, the position is relativ to the panels parent.
	if(!IsValid(Panel)) then return end
	local x, y, w, h = Panel:GetBounds()
	local EndX, EndY = x + w, y + h
	return EndX, EndY
end

function PANEL:ResizeSoundBrowser(w, h) // Resize the sound browser panel.
	if (self.ShowPreviousButton:IsVisible() and self.ShowNextButton:IsVisible()) then
		local PNBorderButtonSize = (w/400)*187.5

		self.FolderTree:SetSize(w-25, h-247.5)
		self.FolderTree:SetPos(12.5, 90)
		self.ShowPreviousButton:SetPos(12.5, 60)
		self.ShowPreviousButton:SetWide(PNBorderButtonSize)

		local ShowPreviousButtonX, ShowPreviousButtonY = self:GetEndBounds(self.ShowPreviousButton)
		self.ShowNextButton:SetPos(ShowPreviousButtonX, 60)
		self.ShowNextButton:SetWide((w - 12.5) - ShowPreviousButtonX)
	else
		self.FolderTree:SetSize(w-25, h-217.5)
	end

	if (self.StopLoadingButton:IsVisible()) then
		self.FolderPathText:SetWide(w - 65)
	else
		self.FolderPathText:SetWide(w - 45)
	end

	local BorderButtonSize = (w/400)*100
	local EndFoldersX, EndFoldersY = self:GetEndBounds(self.FolderTree)
	self.StatusBar:SetPos(12.5, EndFoldersY + 5)
	self.StatusBar:SetWide(w - 25)
	self.PlayButton:SetPos(12.5, EndFoldersY + 35)
	self.PlayButton:SetWide(BorderButtonSize)

	self.StopButton:SetPos(w - BorderButtonSize - 12.5, EndFoldersY + 35)
	self.StopButton:SetWide(BorderButtonSize)

	local EndPlayButtonX, EndPlayButtonY = self:GetEndBounds(self.PlayButton)
	self.SendButton:SetPos(EndPlayButtonX + 12.5, EndFoldersY + 35)
	self.SendButton:SetWide((w - BorderButtonSize - 37.5) - EndPlayButtonX)

	self.SoundInfoText:SetPos(12.5, EndFoldersY + 72.5)
	self.SoundInfoText:SetWide(w - 25)
end

function PANEL:CreateSoundBrowser(path) // Make the sound browser panel.
	if (type(path) == "string" and path ~= "") then
		self.EmitterLastSoundPath = self.EmitterLastSoundPath or path or self.SoundPath or ""
		self.EmitterLastFoldername = self.EmitterLastFoldername or self:GetValidFolder(path) or self.Foldername or ""

		self.SoundPath = self.EmitterLastSoundPath
		self.Foldername = self.EmitterLastFoldername

		self.SoundEmitter = true
	else
		self.LastSoundPath = self.LastSoundPath or self.SoundPath or ""
		self.LastFoldername = self.LastFoldername or self.Foldername or ""

		self.SoundPath = self.LastSoundPath
		self.Foldername = self.LastFoldername

		self.SoundEmitter = false
	end
	self.FilepartNumber = self.FilepartNumber or 0
	self.LastClick = 0
	self.StatusValue = 0
	self.filecount = 0
	self.MaxFileParts = 0
	self.StatusText = "Ready!"

	self.SoundBrowserPanel = vgui.Create("DFrame") // The Main Frame.
	self.SoundBrowserPanel:SetPos(50,25)
	self.SoundBrowserPanel:SetSize(400, 567.5)
	self.SoundBrowserPanel:SetSizable(true)
	self.SoundBrowserPanel:SetVisible(false)
	self.SoundBrowserPanel:SetDeleteOnClose( false )
	self.SoundBrowserPanel:SetTitle("Sound Browser")
	self.SoundBrowserPanel._PerformLayout = self.SoundBrowserPanel.PerformLayout
	function self.SoundBrowserPanel:PerformLayout(...)
		local w, h = self:GetSize()
		if w < 300 then
			w = 300
			self:SetWide(w)
		end
		if h < 400 then
			h = 400
			self:SetTall(h)
		end

		self:_PerformLayout(...)
		PANEL:ResizeSoundBrowser(w, h)
	end

	self.SoundInfoText = vgui.Create("DTextEntry", self.SoundBrowserPanel) // The Info Box.
	self.SoundInfoText:SetPos(12.5, 482.5)
	self.SoundInfoText:SetTall(72.5)
	self.SoundInfoText:SetWide(375)
	self.SoundInfoText:SetMultiline(true)
	self.SoundInfoText:SetEnterAllowed(true)
	self.SoundInfoText:SetEnabled(false)
	self.SoundInfoText:SetText(self:GetSoundInfors(self.SoundPath))

	self.ShowPreviousButton = vgui.Create("DButton", self.SoundBrowserPanel) // The Show Previous Button Button.
	self.ShowPreviousButton:SetText("Show The Previous " ..MaxElements.. " Files")
	self.ShowPreviousButton:SetPos(12.5, 60)
	self.ShowPreviousButton:SetTall(25)
	self.ShowPreviousButton:SetWide(187.5)
	self.ShowPreviousButton:SetEnabled(false)
	self.ShowPreviousButton:SetMouseInputEnabled(false)
	self.ShowPreviousButton:SetVisible(false)
	self.ShowPreviousButton.DoClick = function()
		self.FilepartNumber = self.FilepartNumber - 1
		self:UpdateFolders(self.Foldername, self.SoundBrowserPanel, self.SoundInfoText, self.FilepartNumber)
	end

	self.ShowNextButton = vgui.Create("DButton", self.SoundBrowserPanel) // The Show Next Button Button.
	self.ShowNextButton:SetText("Show The Next " ..MaxElements.. " Files")
	self.ShowNextButton:SetPos(12.5, 60)
	self.ShowNextButton:SetTall(25)
	self.ShowNextButton:SetWide(187.5)
	self.ShowNextButton:SetEnabled(false)
	self.ShowNextButton:SetMouseInputEnabled(false)
	self.ShowNextButton:SetVisible(false)
	self.ShowNextButton.DoClick = function()
		self.FilepartNumber = self.FilepartNumber + 1
		self:UpdateFolders(self.Foldername, self.SoundBrowserPanel, self.SoundInfoText, self.FilepartNumber)
	end

	self.FolderPathIcon = vgui.Create("DImageButton", self.SoundBrowserPanel) // The Folder Button.
	self.FolderPathIcon:SetImage("gui/silkicons/magnifier")
	self.FolderPathIcon:SetPos(12.5, 37.5)
	self.FolderPathIcon:SetSize(20, 20)
	self.FolderPathIcon.DoClick = function()
		local value = self.FolderPathText:GetValue()
		self:OpenFolder(value)
	end

	self.StopLoadingButton = vgui.Create("DImageButton", self.SoundBrowserPanel) // The Stop Loading Button.
	self.StopLoadingButton:SetImage("gui/silkicons/cross")
	self.StopLoadingButton:SetPos(32.5, 37.5)
	self.StopLoadingButton:SetSize(20, 20)
	self.StopLoadingButton:SetVisible(false)
	self.StopLoadingButton.DoClick = function()
		if timer.Exists(timername) then
			timer.Remove(timername)
		end
		local filecount = table.Count(self.pFoldersT)
		local MaxFileParts = math.floor(filecount / MaxElements)
		self:SetStatusBar(true, nil, nil, self.FilepartNumber, filecount, MaxFileParts)

	end

	self.FolderPathText = vgui.Create("DTextEntry", self.SoundBrowserPanel) // The Folder Textfeld.
	self.FolderPathText:SetPos(32.5, 37.5)
	self.FolderPathText:SetTall(20)
	self.FolderPathText:SetWide(355)
	self.FolderPathText:SetText(self.Foldername)
	self.FolderPathText.OnEnter = function()
		local value = self.FolderPathText:GetValue()
		self:OpenFolder(value)
	end

	self.StatusBar = vgui.Create("DLabel", self.SoundBrowserPanel) // The Loading Bar.
	self.StatusBar:SetPos(12.5, 415)
	self.StatusBar:SetTall(20)
	self.StatusBar:SetWide(375)
	self.StatusBar:SetText("")
	self.SoundBrowserPanel.PaintOver = function()
		local x, y, w, h = self.StatusBar:GetBounds()
		local tw, th = surface.GetTextSize(self.StatusText)
		local Progress = w * self.StatusValue

		surface.SetDrawColor(128, 0, 0, 255)
		surface.DrawRect(x, y, Progress, h)

		surface.SetDrawColor(128, 128, 128, 255)
		surface.DrawOutlinedRect(x, y, w, h)

		surface.SetTextColor(Color(0,0,0,255))
		surface.SetFont("Default")
		surface.SetTextPos(x + (w / 2) - (tw / 2), y + (h / 2) - (th / 2))
		surface.DrawText(self.StatusText)
	end

	self.PlayButton = vgui.Create("DButton", self.SoundBrowserPanel) // The Play Button.
	self.PlayButton:SetText("Play")
	self.PlayButton:SetPos(187.5, 60)
	self.PlayButton:SetTall(25)
	self.PlayButton:SetWide(175)
	self.PlayButton.DoClick = function()
		self:PlaySound(self.SoundPath)
	end

	self.SendButton = vgui.Create("DButton", self.SoundBrowserPanel) // The Send To Button.
	self.SendButton:SetText("Use Soundpath To:")
	self.SendButton:SetPos(137.5, 445)
	self.SendButton:SetTall(25)
	self.SendButton:SetWide(137.5)
	self.SendButton.DoClick = function(btn)
		self:Sendmenu(self.SoundPath)
	end

	self.StopButton = vgui.Create("DButton", self.SoundBrowserPanel)  // The Stop Button.
	self.StopButton:SetText("Stop")
	self.StopButton:SetPos(287.5, 445)
	self.StopButton:SetTall(25)
	self.StopButton:SetWide(100)
	self.StopButton.DoClick = function()
		self:PlaySound() // Mute a playing sound by not giving a sound.
	end

	self:UpdateFolders(self.Foldername, self.SoundBrowserPanel, self.SoundInfoText, self.FilepartNumber)
end

function PANEL:GetValidFolder(Folder) // Filter invalid chars out.
	if (type(Folder) ~= "string" or Folder == "") then return end

	local ValidFolder = string.lower(Folder)
	local invalid_chars = {
		["%.%."] = "", // Disallow access to folders outside the sound folder by typing ".." in the folder browser.
		["\\"] = "/",
		["//"] = "/",
		["/.svn"] = "", // Disallow access to .svn folders.
	}

	for k, v in pairs(invalid_chars) do
		local Finds = table.Count(string.Explode(k, ValidFolder))
		for i = 1, Finds do
			if (string.match(ValidFolder, k)) then
				ValidFolder = string.gsub(ValidFolder, k, v)
			end
		end
	end

	ValidFolder = string.Trim(ValidFolder)
	if (string.sub(ValidFolder, 0, 4) == ".svn") then // Disallow access to .svn folders.
		ValidFolder = string.sub(ValidFolder, -4)
		if (ValidFolder == ".svn") then
			ValidFolder = ""
		end
	end

	ValidFolder = string.Trim(ValidFolder, "/")

	if (IsValid(self.FolderPathText)) then
		self.FolderPathText:SetText(ValidFolder)
	end

	local Dirs = table.Count(string.Explode("/", ValidFolder))
	for i = 1, Dirs do
		if (!file.IsDir("sound/"..ValidFolder,"GAME")) then
			ValidFolder = string.GetPathFromFilename(ValidFolder)
			ValidFolder = string.Trim(ValidFolder, "/")
		end
	end

	ValidFolder = string.Trim(ValidFolder, "/")
	return ValidFolder
end

local function CloseSoundBrowser() // Close the Sound Browser.
	PANEL.SoundBrowserPanel:Close()
	--[[
	if (IsValid(PANEL.SoundBrowserPanel)) then
		//PANEL.SoundBrowserPanel:Close()
		PANEL.SoundBrowserPanel:Remove()
	end
	]]
end

local function OpenSoundBrowser(pl, cmd, args) // Open the Sound Browser.
	if (!IsValid(PANEL.SoundBrowserPanel)) then
		PANEL:CreateSoundBrowser(args[1])
	end

	PANEL.SoundBrowserPanel:MakePopup()
	PANEL.SoundBrowserPanel:SetVisible(true)
end

concommand.Add("wire_sound_browser_open", OpenSoundBrowser)
concommand.Add("+wire_sound_browser_open", OpenSoundBrowser)
concommand.Add("-wire_sound_browser_open", CloseSoundBrowser)
