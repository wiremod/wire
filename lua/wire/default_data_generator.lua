-- This script is created to generate default data files from data_static in data. It is mainly used for E2 tests, but can be used for everything
local function RecursivelyGenerateFolder(path)
	local files, dirs = file.Find(path .. "*", "GAME")
	local subpath = string.sub(path, 13, nil)
	file.CreateDir(subpath)

	for _, filename in ipairs(files) do
		local filepath = path .. filename
		file.Write(subpath .. filename, file.Read(filepath, "GAME"))
	end

	for _, dir in ipairs(dirs) do
		RecursivelyGenerateFolder(path .. dir .. "/")
	end
end

function WireLib.GenerateDefaultData()
	-- When adding new folders that need to be generated, add them to this list
	RecursivelyGenerateFolder("data_static/expression2/")
	RecursivelyGenerateFolder("data_static/fpgachip/")
	RecursivelyGenerateFolder("data_static/cpuchip/")
	RecursivelyGenerateFolder("data_static/gpuchip/")
	RecursivelyGenerateFolder("data_static/spuchip/")
	RecursivelyGenerateFolder("data_static/soundlists/")
end

-- Regenerate data files on every structure update
local DataVersion = 3

if cookie.GetNumber("wire_data_version", 0) < DataVersion then
	cookie.Set("wire_data_version", tostring(DataVersion))
	WireLib.GenerateDefaultData()
end

concommand.Add("wire_generate_data_files", function(ply)
	if SERVER and IsValid(ply) and not ply:IsSuperAdmin() then return end
	WireLib.GenerateDefaultData()
end)
