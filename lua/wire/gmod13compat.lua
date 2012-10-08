local libs = {
	"http"
}

if VERSION < 150 then
	if not datastream then require("datastream") end
	function datastream.__prepareStream(streamID) end

	-- gmod 12 => use installed lib
	for _,libName in pairs(libs) do
		local lib12Name = libName.."12"

		local lib = _G[libName]
		_G[lib12Name] = lib
	end

	return
end
-- gmod 13 => use compatibility lib
for _,libName in pairs(libs) do
	local lib12Name = libName.."12"

	local lib = _G[libName]
	-- make copies of everything and override some of them
	_G[lib12Name] = lib and table.Copy(lib) or {}
end

function http12.Get(url, headers, callback)
	http.Fetch(url, callback, function() print("Err - http.Fetch") end)
end
if CLIENT then
	if VERSION >= 151 then
		_R.Panel.AddHeader = function() end
	end
end
if SERVER then
	resource.AddFile("materials/gui/silkicons/emoticon_smile.vtf")
	resource.AddFile("materials/gui/silkicons/newspaper.vtf")
	resource.AddFile("materials/gui/silkicons/wrench.vtf")
	resource.AddFile("materials/vgui/spawnmenu/save.vtf")
	
	cam.StartMaterialOverride = render.MaterialOverride
	SetMaterialOverride = render.MaterialOverride
	local fontTable = 
	{
		font = "defaultbold",
		size = 12,
		weight = 700,
		antialias = true,
		additive = false,
	}
	surface.CreateFont("DefaultBold", fontTable)
end
