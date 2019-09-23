-- Garry has imposed a file extension whitelist for the Steam Workshop which does not permit the dangerous format .txt
-- Therefore, we must store our .txt's in default_data_files.lua, and then extract them when first run

local ignored_dirs = {
	["expression2/tests"] = true,
}

-- Compress all files in addons/wire/data recursively into 1 json string
local function ReadDir(root)
	if ignored_dirs[root] then return nil end
	local tab = {}
	local files,dirs = file.Find("addons/wire/data/"..root.."*","GAME")
	for _, f in pairs(files) do
		f = root..f
		tab[f] = file.Read("addons/wire/data/"..f, "GAME")
	end
	for _, f in pairs(dirs) do
		f = root..f.."/"
		tab[f] = ReadDir(f)
	end
	return tab
end
-- Uncomment and Rename this file to wire/lua/wire/default_data_files.lua to update it
-- file.Write("default_data_files.txt", "//"..util.TableToJSON(ReadDir("")))

-- Decompress the json string wire/lua/wire/default_data_files.lua into the corresponding 36+ default data files
local function WriteDir(tab)
	for f, contents in pairs(tab) do
		if isstring(contents) then
			file.Write(f, contents)
		else
			file.CreateDir(f)
			WriteDir(contents)
		end
	end
end
-- Only expand the files if they aren't present already
if not file.Exists("expression2/_helloworld_.txt", "DATA") then
	local compressed = file.Read("wire/default_data_files.lua","LUA")
	-- The client cannot read lua files sent by the server (for security?), so clientside this'll only work
	-- if the client actually has Wiremod installed, though with workshop autodownload that'll be common
	if compressed ~= nil then
		WriteDir(util.JSONToTable(string.sub(compressed, 3)))
	end
end
