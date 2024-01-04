-- Garry has imposed a file extension whitelist for the Steam Workshop which does not permit the dangerous format .txt
-- Therefore, we must store our .txt's in default_data_files.lua, and then extract them when first run

local ignored_dirs = {
	["cpuchip/tests"] = true,
	["gpuchip/tests"] = true,
	["spuchip/tests"] = true
}

local checked_dirs = {
	"cpuchip",
	"gpuchip",
	"spuchip"
}

-- Compress all files in addons/wire/data recursively into 1 json string
local function ReadDir(root)
	if ignored_dirs[root] then return nil end
	local tab = {}
	local files,dirs = file.Find("addons/wire-cpu/data_static/"..root.."*","GAME")
	for _, f in pairs(files) do
		f = root..f
		tab[f] = file.Read("addons/wire-cpu/data_static/"..f, "GAME")
	end
	for _, f in pairs(dirs) do
		f = root..f.."/"
		tab[f] = ReadDir(f)
	end
	return tab
end

-- Uncomment and Rename this file to wire/lua/wire/default_data_files.lua to update it
-- file.Write("cpu_default_data_files.txt", "--"..util.TableToJSON(ReadDir("")))

-- Decompress the json string wire/lua/wire/default_data_files.lua into the corresponding 36+ default data files
local function WriteDir(tab)
	for f, contents in pairs(tab) do
		if isstring(contents) then
			if not file.Exists(f,"DATA") then
				file.Write(f, contents)
			end
		else
			file.CreateDir(f)
			WriteDir(contents)
		end
	end
end

-- Write any missing files to the folder
if CLIENT then
	for _,dir in pairs(checked_dirs) do
		WriteDir(ReadDir(dir..'/'), 3)
	end
end