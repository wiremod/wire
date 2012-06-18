local libs = {
	"file",
	"datastream",
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

function file12.Exists(path, useBaseDir)
	return file.Exists(path, useBaseDir and "GAME" or "DATA")
end

function file12.FindInLua(path)
	return file.Find(path, LUA_PATH)
end

function file12.Find(path, useBaseDir)
	return file.Find(path, useBaseDir and "GAME" or "DATA")
end

function file12.FindDir(path, useBaseDir)
	local files,folders = file12.Find(path, useBaseDir and "GAME" or "DATA")
	return folders
end

function file12.IsDir(path, useBaseDir)
	return file.IsDir(path, useBaseDir and "GAME" or "DATA")
end

utilx = util or {}

if SERVER then
	function datastream12.__prepareStream(streamID)
		util.AddNetworkString("ds12_"..streamID)
	end

	function datastream12.Hook(streamID, callback)
		net.Receive("ds12_" .. streamID, function(len, ply)
			local tbl = net.ReadTable()
			callback(ply, streamID, "", glon.encode(tbl), tbl)
		end)
	end
	function datastream12.StreamToClients(player, streamID, data)
		net.Start("ds12_"..streamID)
			net.WriteTable(data)
		net.Send(player)
	end
else
	function datastream12.StreamToServer(streamID, data)
		net.Start("ds12_" .. streamID)
			net.WriteTable(data)
		net.SendToServer()
	end
	function datastream12.Hook(streamID, callback)
		net.Receive("ds12_"..streamID, function(len) callback( streamID, id, nil, net.ReadTable() ) end )
	end
	cam.StartMaterialOverride = render.MaterialOverride
	SetMaterialOverride = render.MaterialOverride
end
