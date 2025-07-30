-- This script is created to generate default data files from data_static in data. It is mainly used for E2 tests, but can be used for everything
local function RecursivelyGenerateFolder(path)
	local files, dirs = file.Find(path .. "*", "GAME")
	local subpath = string.gsub(path, "data_static/", "")
	file.CreateDir(subpath)

	for _, filename in ipairs(files) do
		local filepath = path .. filename
		file.Write(subpath .. filename, file.Read(filepath, "GAME"))
	end

	for _, dir in ipairs(dirs) do
		RecursivelyGenerateFolder(path .. dir .. "/", "GAME")
	end
end

function WireLib.GenerateDefaultData()
	-- When adding new folders that need to be generated, add them to this list.
	RecursivelyGenerateFolder("data_static/expression2/")
	RecursivelyGenerateFolder("data_static/soundlists/")
end

-- Generate this only once
if not cookie.GetString("wire_data_generated") then
	cookie.Set("wire_data_generated", "true")
	WireLib.GenerateDefaultData()
end

concommand.Add("wire_generate_data_files", WireLib.GenerateDefaultData)
