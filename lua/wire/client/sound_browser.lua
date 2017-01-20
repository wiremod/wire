-- A sound browser for the sound emitter and the expression 2 editor.
-- Made by Grocel.

local max_char_count = 200 --File length limit
local max_char_chat_count = 110 -- chat has a ~128 char limit, varies depending on char wide.

local Disabled_Gray = Color(140, 140, 140, 255)

local SoundBrowserPanel = nil
local TabFileBrowser = nil
local TabSoundPropertyList = nil
local TabFavourites = nil
local SoundInfoTree = nil
local SoundInfoTreeRoot = nil

local SoundObj = nil
local SoundObjNoEffect = nil

local TranslateCHAN = {
	[CHAN_REPLACE] = "CHAN_REPLACE",
	[CHAN_AUTO] = "CHAN_AUTO",
	[CHAN_WEAPON] = "CHAN_WEAPON",
	[CHAN_VOICE] = "CHAN_VOICE",
	[CHAN_ITEM] = "CHAN_ITEM",
	[CHAN_BODY] = "CHAN_BODY",
	[CHAN_STREAM] = "CHAN_STREAM",
	[CHAN_STATIC] = "CHAN_STATIC",
	[CHAN_VOICE2] = "CHAN_VOICE2",
	[CHAN_VOICE_BASE] = "CHAN_VOICE_BASE",
	[CHAN_USER_BASE] = "CHAN_USER_BASE"
}

local function GetValidSoundFilename(strfile)
	strfile = strfile or ""

	-- filter out sound characters: https://developer.valvesoftware.com/wiki/Soundscripts
	strfile = string.gsub(strfile, "^[%*%#%@%>%<%)%}%$%!%?%^]?[%*%#%@%>%<%)%}%$%!%?%^]?", "", 2)
	strfile = "sound/" .. strfile

	return strfile
end

-- Output the infos about the given sound.
local function GetFileInfos(strfile)
	if not isstring(strfile) or strfile == "" then return end

	local nsize = tonumber(file.Size(GetValidSoundFilename(strfile), "GAME") or "-1")
	local strformat = string.lower(string.GetExtensionFromFilename(strfile) or "n/a")

	return nsize, strformat
end

local function FormatSize(nsize)
	if not nsize then return end

	-- Negative filessizes aren't Valid.
	if nsize < 0 then return end

	return string.NiceSize(nsize)
end

local function FormatLength(nduration)
	if not nduration then return end

	-- Negative durations aren't Valid.
	if nduration < 0 then return end

	local nm = math.floor(nduration / 60)
	local ns = math.floor(nduration % 60)
	local nms = (nduration % 1) * 1000
	return string.format("%01d", nm) .. ":" .. string.format("%02d", ns) .. "." .. string.format("%03d", nms)
end

local MountCache = {}
local MountedGames = nil
local function GetMountOfFile(strfile)
	if not strfile then return end

	strfile = GetValidSoundFilename(strfile)
	local exists = file.Exists(strfile, "GAME")
	local isfile = not file.IsDir(strfile, "GAME")

	if not exists or not isfile then
		MountCache[strfile] = nil
		MountedGames = nil
		return
	end

	if MountCache[strfile] then
		return MountCache[strfile]
	end

	if not MountedGames then
		MountedGames = engine.GetGames()
		table.insert(MountedGames, 1, {
			folder = "DOWNLOAD",
			title = "Server Downloads",
		})
		table.insert(MountedGames, 1, {
			folder = "THIRDPARTY",
			title = "Addons and Gamemodes",
		})
		table.insert(MountedGames, 1, {
			folder = "WORKSHOP",
			title = "Workshop",
		})
		table.insert(MountedGames, 1, {
			folder = "garrysmod",
			title = "Garry's Mod",
			depot = 4000,
		})
	end

	local foundingames = {}

	for k, v in pairs(MountedGames) do
		local folder = v.folder
		exists = file.Exists(strfile, folder)
		isfile = not file.IsDir(strfile, folder)

		if exists and isfile then
			table.insert(foundingames, v)
		end
	end

	MountCache[strfile] = foundingames
	return foundingames
end

local function GetInfoTable(strfile)
	local nsize, strformat = GetFileInfos(strfile)
	if not nsize then return end

	local nduration = SoundDuration(strfile) -- Get the duration for the info text only.
	if nduration then
		nduration = math.Round(nduration * 1000) / 1000
	end

	local strduration = FormatLength(nduration, nsize)
	if not strduration then
		nduration = nil
	end

	local strsize = FormatSize(nsize)
	if not strsize then
		nsize = nil
	end

	local T = {}
	local tabproperty = sound.GetProperties(strfile)

	if tabproperty then
		T = tabproperty
	else
		T.Path = strfile
		T.Duration = {strduration or "n/a", nduration and nduration .. " sec"}
		T.Size = {strsize or "n/a", nsize and nsize .. " Bytes"}
		T.Format = strformat
		T.Mount = GetMountOfFile(strfile)
	end

	return T, not tabproperty
end


-- Output the infos about the given sound.
local oldstrfile
local function GenerateInfoTree(strfile, backnode, count)
	if oldstrfile == strfile and strfile then return end
	oldstrfile = strfile

	local SoundData, IsFile = GetInfoTable(strfile)

	if IsValid(SoundInfoTreeRoot) and not IsValid(backnode) then
		SoundInfoTreeRoot:Remove()
	end
	if not SoundData then return end

	local strcount = ""
	if count then
		strcount = " (" .. count .. ")"
	end

	local index
	local node
	local mainnode
	local subnode

	if IsFile then
		if IsValid(backnode) then
			mainnode = backnode:AddNode("Sound File" .. strcount, "icon16/sound.png")
		else
			mainnode = SoundInfoTree:AddNode("Sound File", "icon16/sound.png")
			SoundInfoTreeRoot = mainnode
		end


		do
			index = "Path"
			node = mainnode:AddNode(index, "icon16/sound.png")
			subnode = node:AddNode(SoundData[index], "icon16/page.png")
			subnode.IsSoundNode = true
			subnode.IsDataNode = true
		end
		do
			index = "Duration"
			node = mainnode:AddNode(index, "icon16/time.png")
			for k, v in pairs(SoundData[index]) do
				subnode = node:AddNode(v, "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			index = "Size"
			node = mainnode:AddNode(index, "icon16/disk.png")
			for k, v in pairs(SoundData[index]) do
				subnode = node:AddNode(v, "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			index = "Format"
			node = mainnode:AddNode(index, "icon16/page_white_key.png")
			subnode = node:AddNode(SoundData[index], "icon16/page.png")
			subnode.IsDataNode = true
		end

		do
			index = "Mount"
			if SoundData[index] then
				node = mainnode:AddNode("Mounted Sources", "icon16/plugin.png")
				for k, v in pairs(SoundData[index]) do
					subnode = node:AddNode(v.title or v.folder, "icon16/page.png")
					subnode.IsDataNode = true
				end
			end
		end
	else
		if IsValid(backnode) then
			mainnode = backnode:AddNode("Sound Property" .. strcount, "icon16/table_gear.png")
		else
			mainnode = SoundInfoTree:AddNode("Sound Property", "icon16/table_gear.png")
			SoundInfoTreeRoot = mainnode
		end

		do
			node = mainnode:AddNode("Name", "icon16/sound.png")
			subnode = node:AddNode(SoundData["name"], "icon16/page.png")
			subnode.IsSoundNode = true
			subnode.IsDataNode = true
		end
		do
			local tabchannel = SoundData["channel"] or 0
			if istable(tabchannel) then
				node = mainnode:AddNode("Channel", "icon16/page_white_gear.png")
				for k, v in pairs(tabchannel) do
					subnode = node:AddNode(v, "icon16/page.png")
					subnode.IsDataNode = true
					subnode = node:AddNode(TranslateCHAN[v] or TranslateCHAN[CHAN_USER_BASE], "icon16/page.png")
					subnode.IsDataNode = true
				end
			else
				node = mainnode:AddNode("Channel", "icon16/page_white_gear.png")
				subnode = node:AddNode(tabchannel, "icon16/page.png")
				subnode.IsDataNode = true
				subnode = node:AddNode(TranslateCHAN[tabchannel] or TranslateCHAN[CHAN_USER_BASE], "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			local tablevel = SoundData["level"] or 0
			if istable(tablevel) then
				node = mainnode:AddNode("Level", "icon16/page_white_gear.png")
				for k, v in pairs(tablevel) do
					subnode = node:AddNode(v, "icon16/page.png")
					subnode.IsDataNode = true
					subnode = node:AddNode(v, "icon16/page.png")
					subnode.IsDataNode = true
				end
			else
				node = mainnode:AddNode("Level", "icon16/page_white_gear.png")
				subnode = node:AddNode(tablevel, "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			local tabpitch = SoundData["volume"] or 0
			if istable(tabpitch) then
				node = mainnode:AddNode("Volume", "icon16/page_white_gear.png")
				for k, v in pairs(tabpitch) do
					subnode = node:AddNode(v, "icon16/page.png")
					subnode.IsDataNode = true
				end
			else
				node = mainnode:AddNode("Volume", "icon16/page_white_gear.png")
				subnode = node:AddNode(tabpitch, "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			local tabpitch = SoundData["pitch"] or 0
			if istable(tabpitch) then
				node = mainnode:AddNode("Pitch", "icon16/page_white_gear.png")
				for k, v in pairs(tabpitch) do
					subnode = node:AddNode(v, "icon16/page.png")
					subnode.IsDataNode = true
				end
			else
				node = mainnode:AddNode("Pitch", "icon16/page_white_gear.png")
				subnode = node:AddNode(tabpitch, "icon16/page.png")
				subnode.IsDataNode = true
			end
		end
		do
			local tabsound = SoundData["sound"] or ""
			if istable(tabsound) then
				node = mainnode:AddNode("Sounds", "icon16/table_multiple.png")
			else
				node = mainnode:AddNode("Sound", "icon16/table.png")
			end

			local olddoclick = node.Expander.DoClick
			node.Expander.DoClick = function(panel, ...)
				if panel.HasSubData then
					return olddoclick(panel, ...)
				end

				panel.HasSubData = tabsound ~= nil

				if istable(tabsound) then
					for k, v in pairs(tabsound) do
						GenerateInfoTree(v, node, k)
					end
				else
					GenerateInfoTree(tabsound, node)
				end

				return olddoclick(panel, ...)
			end
			node:SetForceShowExpander(true)
		end
	end

	if IsValid(backnode) then
		return
	end

	if IsValid(SoundInfoTreeRoot) then
		SoundInfoTreeRoot:SetExpanded(true)
	end
end

-- Set the volume of the sound.
local function SetSoundVolume(volume)
	if not SoundObj then return end

	SoundObj:ChangeVolume(tonumber(volume) or 1, 0.1)
end

-- Set the pitch of the sound.
local function SetSoundPitch(pitch)
	if not SoundObj then return end

	SoundObj:ChangePitch(tonumber(pitch) or 100, 0.1)
end

-- Play the given sound, if no sound is given then mute a playing sound.
local function PlaySound(filename, volume, pitch)
	if SoundObj then
		SoundObj:Stop()
		SoundObj = nil
	end

	if not filename or filename == "" then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	util.PrecacheSound(filename)

	SoundObj = CreateSound(ply, filename)
	if SoundObj then
		SoundObj:PlayEx(tonumber(volume) or 1, tonumber(pitch) or 100)
	end
end

-- Play the given sound without effects, if no sound is given then mute a playing sound.
local function PlaySoundNoEffect(filename)
	if SoundObjNoEffect then
		SoundObjNoEffect:Stop()
		SoundObjNoEffect = nil
	end

	if not filename or filename == "" then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	util.PrecacheSound(filename)

	SoundObjNoEffect = CreateSound(ply, filename)
	if SoundObjNoEffect then
		SoundObjNoEffect:PlayEx(1, 100)
	end
end

local function SetupSoundemitter(strSound)
	-- Setup the Soundemitter stool with the soundpath.
	RunConsoleCommand("wire_soundemitter_sound", strSound)

	-- Pull out the soundemitter stool after setup.
	spawnmenu.ActivateTool("wire_soundemitter")
end

local function SetupClipboard(strSound)
	-- Copy the soundpath to Clipboard.
	SetClipboardText(strSound)
end

local function Sendmenu(strSound, soundemitter, nSoundVolume, nSoundPitch) -- Open a sending and setup menu on right click on a sound file.
	if not isstring(strSound) then return end
	if strSound == "" then return end

	local Menu = DermaMenu()
	local MenuItem = nil

	if soundemitter then

		-- Setup soundemitter
			MenuItem = Menu:AddOption("Setup soundemitter", function()
				SetupSoundemitter(strSound)
			end)
			MenuItem:SetImage("icon16/sound.png")

		-- Setup soundemitter and close
			MenuItem = Menu:AddOption("Setup soundemitter and close", function()
				SetupSoundemitter(strSound)
				SoundBrowserPanel:Close()
			end)
			MenuItem:SetImage("icon16/sound.png")

		-- Copy to clipboard
			MenuItem = Menu:AddOption("Copy to clipboard", function()
				SetupClipboard(strSound)
			end)
			MenuItem:SetImage("icon16/page_paste.png")

		-- Copy to clipboard and close
			MenuItem = Menu:AddOption("Copy to clipboard and close", function()
				SetupClipboard(strSound)
				SoundBrowserPanel:Close()
			end)
			MenuItem:SetImage("icon16/page_paste.png")

		else

		-- Copy to clipboard
			MenuItem = Menu:AddOption("Copy to clipboard", function()
				SetupClipboard(strSound)
			end)
			MenuItem:SetImage("icon16/page_paste.png")

		-- Copy to clipboard and close
			MenuItem = Menu:AddOption("Copy to clipboard and close", function()
				SetupClipboard(strSound)
				SoundBrowserPanel:Close()
			end)
			MenuItem:SetImage("icon16/page_paste.png")

		-- Setup soundemitter
			MenuItem = Menu:AddOption("Setup soundemitter", function()
				SetupSoundemitter(strSound)
			end)
			MenuItem:SetImage("icon16/sound.png")

		-- Setup soundemitter and close
			MenuItem = Menu:AddOption("Setup soundemitter and close", function()
				SetupSoundemitter(strSound)
				SoundBrowserPanel:Close()
			end)
			MenuItem:SetImage("icon16/sound.png")

	end

	Menu:AddSpacer()

	if IsValid(TabFavourites) then
		-- Add the soundpath to the favourites.
		if TabFavourites:ItemInList(strSound) then

			-- Remove from favourites
				MenuItem = Menu:AddOption("Remove from favourites", function()
					TabFavourites:RemoveItem(strSound)
				end)
				MenuItem:SetImage("icon16/bin_closed.png")

		else

			--Add to favourites
				MenuItem = Menu:AddOption("Add to favourites", function()
					TabFavourites:AddItem(strSound, sound.GetProperties(strSound) and "property" or "file")
				end)
				MenuItem:SetImage("icon16/star.png")
				local max_item_count = TabFavourites:GetMaxItems()
				local count = TabFavourites.TabfileCount
				if count >= max_item_count then
					MenuItem:SetTextColor(Disabled_Gray) -- custom disabling
					MenuItem.DoClick = function() end

					MenuItem:SetTooltip("The favourites list is Full! It can't hold more than " .. max_item_count .. " items!")
				end

		end
	end

	Menu:AddSpacer()

	-- Print to console
		MenuItem = Menu:AddOption("Print to console", function()
			-- Print the soundpath in the Console/HUD.
			local ply = LocalPlayer()
			if not IsValid(ply) then return end

			ply:PrintMessage( HUD_PRINTTALK, strSound)
		end)
		MenuItem:SetImage("icon16/monitor_go.png")

	-- Print to Chat
		MenuItem = Menu:AddOption("Print to Chat", function()
			-- Say the the soundpath.
			RunConsoleCommand("say", strSound)
		end)
		MenuItem:SetImage("icon16/group_go.png")

		local len = #strSound
		if len > max_char_chat_count then
			MenuItem:SetTextColor(Disabled_Gray) -- custom disabling
			MenuItem.DoClick = function() end

			MenuItem:SetTooltip("The filepath (" .. len .. " chars) is too long to print in chat. It should be shorter than " .. max_char_chat_count .. " chars!")
		end

	Menu:AddSpacer()

	-- Play
		MenuItem = Menu:AddOption("Play", function()
			PlaySound(strSound, nSoundVolume, nSoundPitch, strtype)
			PlaySoundNoEffect()
		end)
		MenuItem:SetImage("icon16/control_play.png")

	-- Play without effects
		MenuItem = Menu:AddOption("Play without effects", function()
			PlaySound()
			PlaySoundNoEffect(strSound, strtype)
		end)
		MenuItem:SetImage("icon16/control_play_blue.png")

	Menu:Open()
end

local function Infomenu(parent, node, soundemitter, nSoundVolume, nSoundPitch)
	if not IsValid(node) then return end
	if not node.IsDataNode then return end

	local strNodeName = node:GetText()
	local IsSoundNode = node.IsSoundNode

	if IsSoundNode then
		Sendmenu(strNodeName, soundemitter, nSoundVolume, nSoundPitch)
		return
	end

	local Menu = DermaMenu()

	-- Copy to clipboard
		MenuItem = Menu:AddOption("Copy to clipboard", function()
			SetupClipboard(strNodeName)
		end)
		MenuItem:SetImage("icon16/page_paste.png")

	-- Print to console
		MenuItem = Menu:AddOption("Print to console", function()
			-- Print the soundpath in the Console/HUD.
			local ply = LocalPlayer()
			if not IsValid(ply) then return end

			ply:PrintMessage( HUD_PRINTTALK, strNodeName)
		end)
		MenuItem:SetImage("icon16/monitor_go.png")

	-- Print to Chat
		MenuItem = Menu:AddOption("Print to Chat", function()
			-- Say the the soundpath.
			RunConsoleCommand("say", strNodeName)
		end)
		MenuItem:SetImage("icon16/group_go.png")

		local len = #strNodeName
		if len > max_char_chat_count then
			MenuItem:SetTextColor(Disabled_Gray) -- custom disabling
			MenuItem.DoClick = function() end

			MenuItem:SetTooltip("The filepath (" .. len .. " chars) is too long to print in chat. It should be shorter than " .. max_char_chat_count .. " chars!")
		end

	Menu:Open()
end

-- Save the file path. It should be cross session.
-- It's used when opening the browser in the e2 editor.
local function SaveFilePath(panel, filename)
	if not IsValid(panel) then return end
	if panel.Soundemitter then return end

	panel:SetCookie("wire_soundfile", filename)
end

-- Open the Sound Browser.
local function CreateSoundBrowser(path, se)
	local soundemitter = false
	if isstring(path) and path ~= "" then
		soundemitter = true

		if tonumber(se) ~= 1 then
			soundemitter = false
		end
	end

	if tonumber(se) == 1 then
		soundemitter = true
	end

	local strSound = ""
	local nSoundVolume = 1
	local nSoundPitch = 100

	if IsValid(SoundBrowserPanel) then SoundBrowserPanel:Remove() end
	if IsValid(TabFileBrowser) then TabFileBrowser:Remove() end
	if IsValid(TabSoundPropertyList) then TabSoundPropertyList:Remove() end
	if IsValid(TabFavourites) then TabFavourites:Remove() end
	if IsValid(SoundInfoTree) then SoundInfoTree:Remove() end
	if IsValid(SoundInfoTreeRoot) then SoundInfoTreeRoot:Remove() end

	SoundBrowserPanel = vgui.Create("DFrame") -- The main frame.
	SoundBrowserPanel:SetPos(50,25)
	SoundBrowserPanel:SetSize(750, 500)

	SoundBrowserPanel:SetMinWidth(700)
	SoundBrowserPanel:SetMinHeight(400)

	SoundBrowserPanel:SetSizable(true)
	SoundBrowserPanel:SetDeleteOnClose( false )
	SoundBrowserPanel:SetTitle("Sound Browser")
	SoundBrowserPanel:SetVisible(false)
	SoundBrowserPanel:SetCookieName( "wire_sound_browser" )
	SoundBrowserPanel:GetParent():SetWorldClicker(true) -- Allow the use of the toolgun while in menu.

	TabFileBrowser = vgui.Create("wire_filebrowser") -- The file tree browser.
	TabSoundPropertyList = vgui.Create("wire_soundpropertylist") -- The sound property browser.
	TabFavourites = vgui.Create("wire_listeditor") -- The favourites manager.

	TabFileBrowser:SetListSpeed(6)
	TabFileBrowser:SetMaxItemsPerPage(200)

	TabSoundPropertyList:SetListSpeed(100)
	TabSoundPropertyList:SetMaxItems(400)

	TabFavourites:SetListSpeed(40)
	TabFavourites:SetMaxItems(512)

	local BrowserTabs = vgui.Create("DPropertySheet") -- The tabs.
	BrowserTabs:DockMargin(5, 5, 5, 5)
	BrowserTabs:AddSheet("File Browser", TabFileBrowser, "icon16/folder.png", false, false, "Browse your sound folder.")
	BrowserTabs:AddSheet("Sound Property Browser", TabSoundPropertyList, "icon16/table_gear.png", false, false, "Browse the sound properties.")
	BrowserTabs:AddSheet("Favourites", TabFavourites, "icon16/star.png", false, false, "View your favourites.")

	SoundInfoTree = vgui.Create("DTree") -- The info tree.
	SoundInfoTree:SetClickOnDragHover(false)
	local oldClicktime = CurTime()
	SoundInfoTree.DoClick = function( parent, node )
		if not IsValid(parent) then return end
		if not IsValid(node) then return end
		parent:SetSelectedItem(node)

		local Clicktime = CurTime()
		if (Clicktime - oldClicktime) > 0.3 then oldClicktime = Clicktime return end
		oldClicktime = Clicktime

		if not node.IsSoundNode then return end

		local filename = node:GetText()
		PlaySound(filename, nSoundVolume, nSoundPitch)
		PlaySoundNoEffect()
	end
	SoundInfoTree.DoRightClick = function( parent, node )
		if not IsValid(parent) then return end
		if not IsValid(node) then return end

		parent:SetSelectedItem(node)
		Infomenu(parent, node, soundemitter, nSoundVolume, nSoundPitch)
	end

	local SplitPanel = SoundBrowserPanel:Add( "DHorizontalDivider" )
	SplitPanel:Dock(FILL)
	SplitPanel:SetLeft(BrowserTabs)
	SplitPanel:SetRight(SoundInfoTree)
	SplitPanel:SetLeftWidth(570)
	SplitPanel:SetLeftMin(500)
	SplitPanel:SetRightMin(150)
	SplitPanel:SetDividerWidth(3)

	TabFileBrowser:SetRootName("sound")
	TabFileBrowser:SetRootPath("sound")
	TabFileBrowser:SetWildCard("GAME")
	TabFileBrowser:SetFileTyps({"*.mp3","*.wav"})

	local Columns = TabFileBrowser:AddColumns("Format", "Size")
	Columns[1]:SetFixedWidth(70)
	Columns[1]:SetWide(70)
	Columns[2]:SetFixedWidth(70)
	Columns[2]:SetWide(70)

	TabFileBrowser.LineData = function(self, id, strfile, ...)
		if #strfile > max_char_count then return nil, true end -- skip and hide to long filenames.

		local nsize, strformat = GetFileInfos(strfile)
		if not nsize then return end

		local strsize = FormatSize(nsize, nduration)
		return {strformat, strsize or "n/a"}
	end

	TabFileBrowser.DoClick = function(parent, filename)
		SaveFilePath(SoundBrowserPanel, filename)

		strSound = filename
		GenerateInfoTree(filename)
	end

	TabFileBrowser.DoDoubleClick = function(parent, filename)
		PlaySound(filename, nSoundVolume, nSoundPitch)
		PlaySoundNoEffect()
		SaveFilePath(SoundBrowserPanel, filename)

		strSound = filename
	end

	TabFileBrowser.DoRightClick = function(parent, filename)
		Sendmenu(filename, SoundBrowserPanel.Soundemitter, nSoundVolume, nSoundPitch)
		SaveFilePath(SoundBrowserPanel, filename)

		strSound = filename
		GenerateInfoTree(filename)
	end


	TabSoundPropertyList.DoClick = function(parent, property)
		SaveFilePath(SoundBrowserPanel, property)

		strSound = property
		GenerateInfoTree(property)
	end

	TabSoundPropertyList.DoDoubleClick = function(parent, property)
		PlaySound(property, nSoundVolume, nSoundPitch)
		PlaySoundNoEffect()
		SaveFilePath(SoundBrowserPanel, property)

		strSound = property
	end

	TabSoundPropertyList.DoRightClick = function(parent, property)
		Sendmenu(property, SoundBrowserPanel.Soundemitter, nSoundVolume, nSoundPitch)
		SaveFilePath(SoundBrowserPanel, property)

		strSound = property
		GenerateInfoTree(property)
	end

	file.CreateDir("soundlists")
	TabFavourites:SetRootPath("soundlists")

	TabFavourites.DoClick = function(parent, item, data)
		if file.Exists("sound/" .. item, "GAME") then
			TabFileBrowser:SetOpenFile(item)
		end

		strSound = item
		GenerateInfoTree(item)
	end

	TabFavourites.DoDoubleClick = function(parent, item, data)
		if file.Exists("sound/" .. item, "GAME") then
			TabFileBrowser:SetOpenFile(item)
		end

		PlaySound(item, nSoundVolume, nSoundPitch)
		PlaySoundNoEffect()
		strSound = item
	end

	TabFavourites.DoRightClick = function(parent, item, data)
		if file.Exists("sound/" .. item, "GAME") then
			TabFileBrowser:SetOpenFile(item)
		end

		Sendmenu(item, SoundBrowserPanel.Soundemitter, nSoundVolume, nSoundPitch)
		strSound = item
		GenerateInfoTree(item)
	end

	local ControlPanel = SoundBrowserPanel:Add("DPanel") -- The bottom part of the frame.
	ControlPanel:DockMargin(0, 5, 0, 0)
	ControlPanel:Dock(BOTTOM)
	ControlPanel:SetTall(60)
	ControlPanel:SetPaintBackground(false)

	local ButtonsPanel = ControlPanel:Add("DPanel") -- The buttons.
	ButtonsPanel:DockMargin(4, 0, 0, 0)
	ButtonsPanel:Dock(RIGHT)
	ButtonsPanel:SetWide(250)
	ButtonsPanel:SetPaintBackground(false)

	local TunePanel = ControlPanel:Add("DPanel") -- The effect Sliders.
	TunePanel:DockMargin(0, 4, 0, 0)
	TunePanel:Dock(LEFT)
	TunePanel:SetWide(350)
	TunePanel:SetPaintBackground(false)

	local TuneVolumeSlider = TunePanel:Add("DNumSlider") -- The volume slider.
	TuneVolumeSlider:DockMargin(2, 0, 0, 0)
	TuneVolumeSlider:Dock(TOP)
	TuneVolumeSlider:SetText("Volume")
	TuneVolumeSlider:SetDecimals(0)
	TuneVolumeSlider:SetMinMax(0, 100)
	TuneVolumeSlider:SetValue(100)
	TuneVolumeSlider.Label:SetWide(40)
	TuneVolumeSlider.OnValueChanged = function(self, val)
		nSoundVolume = val / 100
		SetSoundVolume(nSoundVolume)
	end

	local TunePitchSlider = TunePanel:Add("DNumSlider") -- The pitch slider.
	TunePitchSlider:DockMargin(2, 0, 0, 0)
	TunePitchSlider:Dock(BOTTOM)
	TunePitchSlider:SetText("Pitch")
	TunePitchSlider:SetDecimals(0)
	TunePitchSlider:SetMinMax(0, 255)
	TunePitchSlider:SetValue(100)
	TunePitchSlider.Label:SetWide(40)
	TunePitchSlider.OnValueChanged = function(self, val)
		nSoundPitch = val
		SetSoundPitch(nSoundPitch)
	end

	local PlayStopPanel = ButtonsPanel:Add("DPanel") -- Play and stop.
	PlayStopPanel:DockMargin(0, 0, 0, 2)
	PlayStopPanel:Dock(TOP)
	PlayStopPanel:SetPaintBackground(false)

	local PlayButton = PlayStopPanel:Add("DButton") -- The play button.
	PlayButton:SetText("Play")
	PlayButton:Dock(LEFT)
	PlayButton:SetWide(PlayStopPanel:GetWide() / 2 - 2)
	PlayButton.DoClick = function()
		PlaySound(strSound, nSoundVolume, nSoundPitch)
		PlaySoundNoEffect()
	end

	local StopButton = PlayStopPanel:Add("DButton") -- The stop button.
	StopButton:SetText("Stop")
	StopButton:Dock(RIGHT)
	StopButton:SetWide(PlayButton:GetWide())
	StopButton.DoClick = function()
		PlaySound() -- Mute a playing sound by not giving a sound.
		PlaySoundNoEffect()
	end

	local SoundemitterButton = ButtonsPanel:Add("DButton") -- The soundemitter button. Hidden in E2 mode.
	SoundemitterButton:SetText("Send to soundemitter")
	SoundemitterButton:DockMargin(0, 2, 0, 0)
	SoundemitterButton:Dock(FILL)
	SoundemitterButton:SetVisible(false)
	SoundemitterButton.DoClick = function(btn)
		SetupSoundemitter(strSound)
	end

	local ClipboardButton = ButtonsPanel:Add("DButton") -- The soundemitter button. Hidden in soundemitter mode.
	ClipboardButton:SetText("Copy to clipboard")
	ClipboardButton:DockMargin(0, 2, 0, 0)
	ClipboardButton:Dock(FILL)
	ClipboardButton:SetVisible(false)
	ClipboardButton.DoClick = function(btn)
		SetupClipboard(strSound)
	end

	local oldw = SoundBrowserPanel:GetSize()
	SoundBrowserPanel.PerformLayout = function(self, ...)
		SoundemitterButton:SetVisible(self.Soundemitter)
		ClipboardButton:SetVisible(not self.Soundemitter)

		local w = self:GetWide()
		local rightw = SplitPanel:GetLeftWidth() + w - oldw

		if rightw < SplitPanel:GetLeftMin() then
			rightw = SplitPanel:GetLeftMin()
		end
		SplitPanel:SetLeftWidth(rightw)

		local minw = w - SplitPanel:GetRightMin() + SplitPanel:GetDividerWidth()
		if SplitPanel:GetLeftWidth() > minw then
			SplitPanel:SetLeftWidth(minw)
		end

		PlayStopPanel:SetTall(ControlPanel:GetTall() / 2 - 2)
		PlayButton:SetWide(PlayStopPanel:GetWide() / 2 - 2)
		StopButton:SetWide(PlayButton:GetWide())

		if self.Soundemitter then
			SoundemitterButton:SetTall(PlayStopPanel:GetTall() - 2)
		else
			ClipboardButton:SetTall(PlayStopPanel:GetTall() - 2)
		end

		oldw, oldh = self:GetSize()

		DFrame.PerformLayout(self, ...)
	end

	SoundBrowserPanel.OnClose = function() -- Set effects back and mute when closing.
		nSoundVolume = 1
		nSoundPitch = 100
		TuneVolumeSlider:SetValue(nSoundVolume * 100)
		TunePitchSlider:SetValue(nSoundPitch)
		PlaySound()
		PlaySoundNoEffect()
	end

	SoundBrowserPanel:InvalidateLayout(true)
end

-- Open the Sound Browser.
local function OpenSoundBrowser(pl, cmd, args)
	local path = args[1] -- nil or "" will put the browser in e2 mode else the soundemitter mode is applied.
	local se = args[2]

	if not IsValid(SoundBrowserPanel) then
		CreateSoundBrowser(path, se)
	end

	SoundBrowserPanel:SetVisible(true)
	SoundBrowserPanel:MakePopup()
	SoundBrowserPanel:InvalidateLayout(true)

	if not IsValid(TabFileBrowser) then return end

	-- Replaces the timer, doesn't get paused in singleplayer.
	WireLib.Timedcall(function()
		if not IsValid(SoundBrowserPanel) then return end
		if not IsValid(TabFileBrowser) then return end

		local soundemitter = false
		if isstring(path) and path ~= "" then
			soundemitter = true
		end

		soundemitter = false
		if isstring(path) and path ~= "" then
			soundemitter = true

			if tonumber(se) ~= 1 then
				soundemitter = false
			end
		end

		if tonumber(se) == 1 then
			soundemitter = true
		end

		SoundBrowserPanel.Soundemitter = soundemitter
		SoundBrowserPanel:InvalidateLayout(true)

		if not soundemitter then
			path = SoundBrowserPanel:GetCookie("wire_soundfile", "") -- load last session
		end
		TabFileBrowser:SetOpenFile(path)
	end)
end

concommand.Add("wire_sound_browser_open", OpenSoundBrowser)
